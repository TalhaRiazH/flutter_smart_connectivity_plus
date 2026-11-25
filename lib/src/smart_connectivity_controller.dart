import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'smart_connectivity_action.dart';
import 'smart_connectivity_config.dart';
import 'smart_connectivity_queue_store.dart';
import 'smart_connectivity_status.dart';

/// Runs before the queue replays. Return `false` to pause the flush, for
/// example when a session refresh failed.
typedef SmartConnectivityBeforeFlush = Future<bool> Function();

/// Called when a queued action is dropped after too many failures.
typedef SmartConnectivityActionDropped =
    void Function(SmartConnectivityAction action, Object error);

/// Tracks connectivity and a queue of actions waiting for a good network.
///
/// Two kinds of queued work:
/// * Session actions (`runOrEnqueue`, `enqueue` with `run`) stay in memory.
/// * Durable actions (`enqueueDurable`) are saved to [queueStore] and replay
///   after an app restart through a handler from [registerHandler].
class SmartConnectivityController extends ChangeNotifier {
  /// Creates a controller with [config].
  ///
  /// Pass [connectivity] in tests. Pass [statusOverride] to force a status
  /// without reading the device network (example / widget tests).
  ///
  /// Pass [queueStore] (for example [SharedPreferencesQueueStore]) so durable
  /// actions survive an app restart. [beforeFlush] runs once before each
  /// replay, so you can refresh an expired session. [onAuthExpired] runs when
  /// a handler throws [SmartConnectivityAuthException].
  SmartConnectivityController({
    SmartConnectivityConfig config = const SmartConnectivityConfig(),
    Connectivity? connectivity,
    SmartConnectivityStatus? statusOverride,
    SmartConnectivityQueueStore? queueStore,
    this.beforeFlush,
    this.onAuthExpired,
    this.onActionDropped,
  }) : _config = config, // ignore: prefer_initializing_formals
       _connectivity = connectivity ?? Connectivity(),
       _statusOverride = statusOverride,
       _status = statusOverride ?? SmartConnectivityStatus.online,
       queueStore = queueStore ?? MemorySmartConnectivityQueueStore();

  final Connectivity _connectivity;
  SmartConnectivityConfig _config;
  SmartConnectivityStatus _status;
  SmartConnectivityStatus? _statusOverride;
  final List<SmartConnectivityAction> _queue = [];
  final Map<String, SmartConnectivityHandler> _handlers = {};
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _flushing = false;
  bool _restored = false;
  Future<void>? _restoring;

  /// Where durable actions are saved.
  final SmartConnectivityQueueStore queueStore;

  /// Runs once before each queue replay. Return `false` to pause.
  SmartConnectivityBeforeFlush? beforeFlush;

  /// Runs when a handler throws [SmartConnectivityAuthException].
  VoidCallback? onAuthExpired;

  /// Runs when an action is dropped after [SmartConnectivityConfig.maxRetries].
  SmartConnectivityActionDropped? onActionDropped;

  /// Current offline settings.
  SmartConnectivityConfig get config => _config;

  /// Latest known network status.
  SmartConnectivityStatus get status => _status;

  /// Whether the app can send network requests right now.
  bool get isOnline => _status == SmartConnectivityStatus.online;

  /// Whether a flush is currently running.
  bool get isFlushing => _flushing;

  /// Actions waiting for a good connection.
  List<SmartConnectivityAction> get queue => List.unmodifiable(_queue);

  /// Number of actions waiting in the queue.
  int get queueLength => _queue.length;

  /// Starts listening for connectivity changes and restores saved actions.
  Future<void> start() async {
    await restoreQueue();
    if (_statusOverride != null) {
      _status = _statusOverride!;
      notifyListeners();
      if (isOnline && _config.autoRetry) unawaited(flush());
      return;
    }
    await _refreshFromConnectivity();
    await _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _applyConnectivity(results);
    });
    if (isOnline && _config.autoRetry) unawaited(flush());
  }

  /// Loads durable actions from [queueStore]. Safe to call more than once.
  Future<void> restoreQueue() {
    if (_restored) return Future<void>.value();
    return _restoring ??= _loadFromStore();
  }

  Future<void> _loadFromStore() async {
    final entries = await queueStore.load();
    for (final entry in entries) {
      final SmartConnectivityAction action;
      try {
        action = SmartConnectivityAction.fromJson(entry);
      } catch (_) {
        continue;
      }
      if (_queue.any((item) => item.id == action.id)) continue;
      _queue.add(action);
    }
    _restored = true;
    if (entries.isNotEmpty) notifyListeners();
  }

  /// Stops listeners.
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  /// Replaces [config] at runtime.
  void updateConfig(SmartConnectivityConfig config) {
    if (_config == config) return;
    _config = config;
    notifyListeners();
  }

  /// Forces [status] for demos and tests. Pass `null` to follow the device again.
  void debugOverrideStatus(SmartConnectivityStatus? status) {
    _statusOverride = status;
    if (status == null) {
      unawaited(_refreshFromConnectivity());
      return;
    }
    if (_status == status) return;
    _status = status;
    notifyListeners();
    if (isOnline && _config.autoRetry) {
      unawaited(flush());
    }
  }

  /// Marks the connection as [SmartConnectivityStatus.flaky] for tests or probes.
  void markFlaky() {
    if (_status == SmartConnectivityStatus.flaky) return;
    _status = SmartConnectivityStatus.flaky;
    _statusOverride ??= SmartConnectivityStatus.flaky;
    notifyListeners();
  }

  /// Registers the [handler] that runs durable actions of [type].
  ///
  /// Register handlers at app start. Saved actions of [type] wait in the
  /// queue until their handler is registered.
  void registerHandler(String type, SmartConnectivityHandler handler) {
    _handlers[type] = handler;
    if (isOnline &&
        _config.autoRetry &&
        _queue.any((item) => item.type == type)) {
      unawaited(flush());
    }
  }

  /// Removes the handler for [type]. Its saved actions stay queued.
  void unregisterHandler(String type) => _handlers.remove(type);

  /// Whether a handler is registered for [type].
  bool hasHandler(String type) => _handlers.containsKey(type);

  /// Runs [task] now when online. Otherwise queues it under [id].
  ///
  /// The queued task lives in memory only. Use [runOrEnqueueDurable] for work
  /// that must survive an app restart.
  ///
  /// Returns `true` when the task ran immediately.
  Future<bool> runOrEnqueue(String id, SmartConnectivityTask task) async {
    if (isOnline) {
      await task();
      return true;
    }
    enqueue(SmartConnectivityAction(id: id, run: task));
    return false;
  }

  /// Runs the [type] handler now when online. Otherwise saves the action so it
  /// replays later, even after an app restart.
  ///
  /// When the immediate run fails, the action is saved and retried. Returns
  /// `true` when the handler ran successfully right away.
  Future<bool> runOrEnqueueDurable({
    required String id,
    required String type,
    Map<String, Object?>? payload,
    String? idempotencyKey,
  }) async {
    final handler = _handlers[type];
    if (handler == null) {
      throw StateError('No handler registered for "$type".');
    }
    final action = SmartConnectivityAction(
      id: id,
      type: type,
      payload: payload,
      idempotencyKey: idempotencyKey,
    );
    if (!isOnline) {
      enqueue(action);
      return false;
    }
    try {
      await handler(_requestFor(action));
      return true;
    } on SmartConnectivityAuthException {
      enqueue(action, flushNow: false);
      onAuthExpired?.call();
      return false;
    } catch (_) {
      action.attempts += 1;
      action.inFlight = true;
      enqueue(action, flushNow: false);
      return false;
    }
  }

  /// Saves a durable action of [type] so it replays later, even after an app
  /// restart. Nothing is added if an action with the same [id] is waiting.
  void enqueueDurable({
    required String id,
    required String type,
    Map<String, Object?>? payload,
    String? idempotencyKey,
  }) {
    enqueue(
      SmartConnectivityAction(
        id: id,
        type: type,
        payload: payload,
        idempotencyKey: idempotencyKey,
      ),
    );
  }

  /// Queues [action] if an entry with the same id is not already waiting.
  void enqueue(SmartConnectivityAction action, {bool flushNow = true}) {
    if (_queue.any((item) => item.id == action.id)) return;
    _queue.add(action);
    notifyListeners();
    if (action.isDurable) unawaited(_persist());
    if (flushNow && isOnline && _config.autoRetry) {
      unawaited(flush());
    }
  }

  /// Drops the queued action with [id], if any.
  void remove(String id) {
    final before = _queue.length;
    _queue.removeWhere((item) => item.id == id);
    if (_queue.length != before) {
      notifyListeners();
      unawaited(_persist());
    }
  }

  /// Clears every queued action.
  void clearQueue() {
    if (_queue.isEmpty) return;
    _queue.clear();
    notifyListeners();
    unawaited(_persist());
  }

  /// Manually retries the queue (banner Retry, or after a session refresh).
  Future<void> retryNow() => flush();

  /// Runs queued actions while online, up to [SmartConnectivityConfig.maxRetries].
  ///
  /// Durable actions whose handler is not registered yet are skipped and stay
  /// queued.
  Future<void> flush() async {
    if (_flushing || !isOnline) return;
    _flushing = true;
    notifyListeners();
    try {
      await restoreQueue();
      if (!_queue.any(_canRun)) return;
      final gate = beforeFlush;
      if (gate != null && !await gate()) return;

      var index = 0;
      while (index < _queue.length && isOnline) {
        final action = _queue[index];
        if (!_canRun(action)) {
          index += 1;
          continue;
        }
        if (action.isDurable) {
          action.inFlight = true;
          await _persist();
        }
        try {
          if (action.isDurable) {
            await _handlers[action.type]!(_requestFor(action));
          } else {
            await action.run!();
          }
          _queue.remove(action);
          notifyListeners();
          if (action.isDurable) await _persist();
        } on SmartConnectivityAuthException {
          onAuthExpired?.call();
          return;
        } catch (error) {
          action.attempts += 1;
          if (action.attempts > _config.maxRetries) {
            _queue.remove(action);
            notifyListeners();
            if (action.isDurable) await _persist();
            onActionDropped?.call(action, error);
            continue;
          }
          if (action.isDurable) await _persist();
          await Future<void>.delayed(_config.retryDelay);
          if (!isOnline) break;
        }
      }
    } finally {
      _flushing = false;
      notifyListeners();
    }
  }

  bool _canRun(SmartConnectivityAction action) =>
      !action.isDurable || _handlers.containsKey(action.type);

  SmartConnectivityRequest _requestFor(SmartConnectivityAction action) {
    return SmartConnectivityRequest(
      id: action.id,
      type: action.type!,
      payload: action.payload,
      idempotencyKey: action.idempotencyKey,
      attempt: action.attempts + 1,
      isReplay: action.restored || action.attempts > 0 || action.inFlight,
    );
  }

  Future<void> _persist() {
    final entries = _queue
        .where((item) => item.isDurable)
        .map((item) => item.toJson())
        .toList();
    return queueStore.save(entries);
  }

  Future<void> _refreshFromConnectivity() async {
    if (_statusOverride != null) {
      _status = _statusOverride!;
      notifyListeners();
      return;
    }
    final results = await _connectivity.checkConnectivity();
    _applyConnectivity(results);
  }

  void _applyConnectivity(List<ConnectivityResult> results) {
    if (_statusOverride != null) return;
    final offline =
        results.isEmpty ||
        results.every((result) => result == ConnectivityResult.none);
    final next = offline
        ? SmartConnectivityStatus.offline
        : SmartConnectivityStatus.online;
    if (next == _status) return;
    _status = next;
    notifyListeners();
    if (isOnline && _config.autoRetry) {
      unawaited(flush());
    }
  }
}
