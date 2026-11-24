/// A unit of work that can wait offline and run again later.
typedef SmartOfflineTask = Future<void> Function();

/// Queued work with a stable id so the same action is not run twice.
class SmartOfflineAction {
  /// Creates a queued action.
  SmartOfflineAction({
    required this.id,
    required this.run,
    this.attempts = 0,
  });

  /// Stable id used to avoid duplicate queue entries.
  final String id;

  /// Work to run when online.
  final SmartOfflineTask run;

  /// How many times this action has already been attempted.
  int attempts;
}
