import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'smart_connectivity_action.dart';
import 'smart_connectivity_config.dart';
import 'smart_connectivity_status.dart';

/// Tracks connectivity and a queue of actions waiting for a good network.
class SmartConnectivityController extends ChangeNotifier {
  /// Creates a controller with [config].
  ///
  /// Pass [connectivity] in tests. Pass [statusOverride] to force a status
  /// without reading the device network (example / widget tests).
  SmartConnectivityController({
    SmartConnectivityConfig config = const SmartConnectivityConfig(),
    Connectivity? connectivity,
    SmartConnectivityStatus? statusOverride,
  })  : _config = config,
        _connectivity = connectivity ?? Connectivity(),
        _statusOverride = statusOverride,
        _status = statusOverride ?? SmartConnectivityStatus.online;

  final Connectivity _connectivity;
  SmartConnectivityConfig _config;
  SmartConnectivityStatus _status;
  SmartConnectivityStatus? _statusOverride;
  final List<SmartConnectivityAction> _queue = [];
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _flushing = false;

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

  /// Starts listening for connectivity changes.
  Future<void> start() async {
    if (_statusOverride != null) {
      _status = _statusOverride!;
      notifyListeners();
      return;
    }
    await _refreshFromConnectivity();
    await _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _applyConnectivity(results);
    });
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

  /// Runs [task] now when online. Otherwise queues it under [id].
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

  /// Queues [action] if an entry with the same id is not already waiting.
  void enqueue(SmartConnectivityAction action) {
    if (_queue.any((item) => item.id == action.id)) return;
    _queue.add(action);
    notifyListeners();
    if (isOnline && _config.autoRetry) {
      unawaited(flush());
    }
  }

  /// Drops the queued action with [id], if any.
  void remove(String id) {
    final before = _queue.length;
    _queue.removeWhere((item) => item.id == id);
    if (_queue.length != before) notifyListeners();
  }

  /// Clears every queued action.
  void clearQueue() {
    if (_queue.isEmpty) return;
    _queue.clear();
    notifyListeners();
  }

  /// Manually retries the queue (banner Retry).
  Future<void> retryNow() => flush();

  /// Runs queued actions while online, up to [SmartConnectivityConfig.maxRetries].
  Future<void> flush() async {
    if (_flushing || !isOnline) return;
    _flushing = true;
    notifyListeners();
    try {
      while (_queue.isNotEmpty && isOnline) {
        final action = _queue.first;
        try {
          await action.run();
          _queue.removeAt(0);
          notifyListeners();
        } catch (_) {
          action.attempts += 1;
          if (action.attempts > _config.maxRetries) {
            _queue.removeAt(0);
            notifyListeners();
            continue;
          }
          await Future<void>.delayed(_config.retryDelay);
          if (!isOnline) break;
        }
      }
    } finally {
      _flushing = false;
      notifyListeners();
    }
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
    final offline = results.isEmpty ||
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
