/// Current network status used by [SmartOfflineHost].
enum SmartOfflineStatus {
  /// A usable network path is available.
  online,

  /// No usable network path is available.
  offline,

  /// The device reports a connection, but requests are failing.
  flaky,
}
