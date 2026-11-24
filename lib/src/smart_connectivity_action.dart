/// A unit of work that can wait offline and run again later.
typedef SmartConnectivityTask = Future<void> Function();

/// Queued work with a stable id so the same action is not run twice.
class SmartConnectivityAction {
  /// Creates a queued action.
  SmartConnectivityAction({
    required this.id,
    required this.run,
    this.attempts = 0,
  });

  /// Stable id used to avoid duplicate queue entries.
  final String id;

  /// Work to run when online.
  final SmartConnectivityTask run;

  /// How many times this action has already been attempted.
  int attempts;
}
