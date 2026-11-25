/// A unit of work that can wait offline and run again later.
///
/// Closures live in memory only. Use [SmartConnectivityHandler] with
/// `enqueueDurable` for work that must survive an app restart.
typedef SmartConnectivityTask = Future<void> Function();

/// Runs a durable queued action of one `type`.
///
/// Send [SmartConnectivityRequest.idempotencyKey] to your server (for example
/// as an `Idempotency-Key` header) so a replayed request is not applied twice.
typedef SmartConnectivityHandler =
    Future<void> Function(SmartConnectivityRequest request);

/// Throw from a handler when the login/session has expired.
///
/// The controller stops the flush, keeps the action, does not count an
/// attempt, and calls `onAuthExpired`. Refresh the session, then call
/// `retryNow()`.
class SmartConnectivityAuthException implements Exception {
  /// Creates an auth-expired signal with an optional [message].
  const SmartConnectivityAuthException([this.message]);

  /// Optional detail for logs.
  final String? message;

  @override
  String toString() => message == null
      ? 'SmartConnectivityAuthException'
      : 'SmartConnectivityAuthException: $message';
}

/// Data passed to a [SmartConnectivityHandler] for one durable action.
class SmartConnectivityRequest {
  /// Creates a request for a durable action.
  const SmartConnectivityRequest({
    required this.id,
    required this.type,
    required this.payload,
    required this.idempotencyKey,
    required this.attempt,
    required this.isReplay,
  });

  /// Queue id of the action.
  final String id;

  /// Handler type registered with `registerHandler`.
  final String type;

  /// JSON-safe data saved with the action.
  final Map<String, Object?> payload;

  /// Stable key to send to your server so it can ignore duplicates.
  final String idempotencyKey;

  /// Attempt number, starting at 1.
  final int attempt;

  /// Whether this run may repeat an earlier one: restored after an app
  /// restart, or a previous attempt may already have reached the server.
  final bool isReplay;
}

/// Queued work with a stable id so the same action is not queued twice.
///
/// A session action has [run] and lives in memory. A durable action has
/// [type] + [payload], is saved to the queue store, and runs through the
/// handler registered for [type].
class SmartConnectivityAction {
  /// Creates a queued action.
  SmartConnectivityAction({
    required this.id,
    this.run,
    this.type,
    Map<String, Object?>? payload,
    String? idempotencyKey,
    DateTime? createdAt,
    this.attempts = 0,
    this.inFlight = false,
    this.restored = false,
  }) : assert(run != null || type != null, 'Provide run or type'),
       payload = payload ?? const {},
       idempotencyKey = idempotencyKey ?? id,
       createdAt = createdAt ?? DateTime.now();

  /// Rebuilds a durable action saved with [toJson].
  factory SmartConnectivityAction.fromJson(Map<String, Object?> json) {
    final payload = json['payload'];
    return SmartConnectivityAction(
      id: json['id']! as String,
      type: json['type']! as String,
      payload: payload is Map ? Map<String, Object?>.from(payload) : null,
      idempotencyKey: json['idempotencyKey'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      inFlight: json['inFlight'] as bool? ?? false,
      restored: true,
    );
  }

  /// Stable id used to avoid duplicate queue entries.
  final String id;

  /// In-memory work for session actions. Null for durable actions.
  final SmartConnectivityTask? run;

  /// Handler type for durable actions. Null for session actions.
  final String? type;

  /// JSON-safe data for durable actions.
  final Map<String, Object?> payload;

  /// Key to send to your server so duplicates are ignored. Defaults to [id].
  final String idempotencyKey;

  /// When the action was first queued.
  final DateTime createdAt;

  /// How many times this action has already failed.
  int attempts;

  /// Whether a run started and has not finished yet.
  bool inFlight;

  /// Whether the action was loaded from the store after a restart.
  final bool restored;

  /// Whether the action is saved to the queue store.
  bool get isDurable => type != null;

  /// JSON for the queue store. Only durable actions are saved.
  Map<String, Object?> toJson() => {
    'id': id,
    'type': type,
    'payload': payload,
    'idempotencyKey': idempotencyKey,
    'createdAt': createdAt.toIso8601String(),
    'attempts': attempts,
    'inFlight': inFlight,
  };
}
