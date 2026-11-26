import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'smart_connectivity_action.dart';
import 'smart_connectivity_config.dart';
import 'smart_connectivity_queue_store.dart';
import 'smart_connectivity_reachability.dart';
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
///
/// When [SmartConnectivityConfig.checkRealInternet] is `true`, a link from
/// [connectivity_plus] is verified with [reachability] so Wi‑Fi without
/// internet (the OS "!" icon) becomes [SmartConnectivityStatus.flaky].
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
  ///
  /// Pass [reachability] to customize or mock the real-internet probe.
  ///
  /// [checkConnectivity] / [onConnectivityChanged] override the platform
  /// [Connectivity] APIs (useful in unit tests).
  SmartConnectivityController({
    SmartConnectivityConfig config = const SmartConnectivityConfig(),
    Connectivity? connectivity,
    Future<List<ConnectivityResult>> Function()? checkConnectivity,
    Stream<List<ConnectivityResult>>? onConnectivityChanged,
    SmartConnectivityStatus? statusOverride,
    SmartConnectivityQueueStore? queueStore,
    SmartConnectivityReachability? reachability,
    this.beforeFlush,
    this.onAuthExpired,
    this.onActionDropped,
  }) : _config = config,
       _connectivity = connectivity,
       _checkConnectivityOverride = checkConnectivity,
       _onConnectivityChangedOverride = onConnectivityChanged,
       _statusOverride = statusOverride,
       _status = statusOverride ?? SmartConnectivityStatus.online,
       _injectedReachability = reachability,
       queueStore = queueStore ?? MemorySmartConnectivityQueueStore();

  Connectivity? _connectivity;
  final Future<List<ConnectivityResult>> Function()?
  _checkConnectivityOverride;
  final Stream<List<ConnectivityResult>>? _onConnectivityChangedOverride;
  SmartConnectivityConfig _config;
  SmartConnectivityStatus _status;
  SmartConnectivityStatus? _statusOverride;
  final SmartConnectivityReachability? _injectedReachability;
  SmartConnectivityReachability? _defaultReachability;
  final List<SmartConnectivityAction> _queue = [];
  final Map<String, SmartConnectivityHandler> _handlers = {};
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _probeTimer;
  int _probeGeneration = 0;
  bool _linkUp = false;
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

  SmartConnectivityReachability get _effectiveReachability {
    final injected = _injectedReachability;
    if (injected != null) return injected;
    return _defaultReachability ??= SmartConnectivityReachability.http(
      uri: Uri.parse(_config.internetCheckUrl),
      timeout: _config.internetCheckTimeout,
    );
  }

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
    _subscription = _connectivityStream().listen((results) {
      unawaited(_applyConnectivity(results));
    });
    if (isOnline && _config.autoRetry) unawaited(flush());
  }

  Connectivity get _platformConnectivity =>
      _connectivity ??= Connectivity();

  Future<List<ConnectivityResult>> _readConnectivity() {
    final override = _checkConnectivityOverride;
    if (override != null) return override();
    return _platformConnectivity.checkConnectivity();
  }

  Stream<List<ConnectivityResult>> _connectivityStream() {
    return _onConnectivityChangedOverride ??
        _platformConnectivity.onConnectivityChanged;
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
    _probeTimer?.cancel();
    super.dispose();
  }

  /// Replaces [config] at runtime.
  void updateConfig(SmartConnectivityConfig config) {
    if (_config == config) return;
    _config = config;
    // Rebuild the default probe with the new URL / timeout next time.
    _defaultReachability = null;
    _syncProbeTimer();
    notifyListeners();
  }

  /// Forces [status] for demos and tests. Pass `null` to follow the device again.
  void debugOverrideStatus(SmartConnectivityStatus? status) {
    _statusOverride = status;
    _probeTimer?.cancel();
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

  /// Re-runs the real-internet probe now (for a Retry button while flaky).
  Future<void> checkInternetNow() async {
    if (_statusOverride != null) return;
    if (!_linkUp) {
      await _refreshFromConnectivity();
      return;
    }
    await _probeInternet();
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
  Future<void> retryNow() async {
    if (!isOnline && _linkUp && _config.checkRealInternet) {
      await checkInternetNow();
    }
    await flush();
  }

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
    final results = await _readConnectivity();
    await _applyConnectivity(results);
  }

  Future<void> _applyConnectivity(List<ConnectivityResult> results) async {
    if (_statusOverride != null) return;
    final offline =
        results.isEmpty ||
        results.every((result) => result == ConnectivityResult.none);
    _linkUp = !offline;
    _syncProbeTimer();

    if (offline) {
      _setStatus(SmartConnectivityStatus.offline);
      return;
    }

    if (!_config.checkRealInternet) {
      _setStatus(SmartConnectivityStatus.online);
      return;
    }

    await _probeInternet();
  }

  Future<void> _probeInternet() async {
    if (_statusOverride != null || !_linkUp) return;
    if (!_config.checkRealInternet) {
      _setStatus(SmartConnectivityStatus.online);
      return;
    }

    final generation = ++_probeGeneration;
    final ok = await _effectiveReachability.hasInternetAccess();
    if (generation != _probeGeneration || _statusOverride != null) return;
    if (!_linkUp) return;

    _setStatus(
      ok ? SmartConnectivityStatus.online : SmartConnectivityStatus.flaky,
    );
  }

  void _setStatus(SmartConnectivityStatus next) {
    if (next == _status) return;
    _status = next;
    notifyListeners();
    if (isOnline && _config.autoRetry) {
      unawaited(flush());
    }
  }

  void _syncProbeTimer() {
    _probeTimer?.cancel();
    _probeTimer = null;
    if (_statusOverride != null) return;
    if (!_linkUp || !_config.checkRealInternet) return;
    final interval = _config.internetCheckInterval;
    if (interval <= Duration.zero) return;
    _probeTimer = Timer.periodic(interval, (_) {
      unawaited(_probeInternet());
    });
  }
}
