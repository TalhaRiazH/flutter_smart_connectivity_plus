import 'smart_connectivity_reachability_impl.dart'
    if (dart.library.html) 'smart_connectivity_reachability_web.dart';

/// Checks whether the device can actually reach the internet.
///
/// [connectivity_plus] only reports link status (Wi‑Fi / cellular). A network
/// can be "connected" with no usable internet (ISP down, captive portal, the
/// Android Wi‑Fi "!" icon). Implementations of this class probe a known URL.
abstract class SmartConnectivityReachability {
  /// Creates a reachability checker.
  const SmartConnectivityReachability();

  /// Default HTTP probe against Google's `generate_204` endpoint.
  factory SmartConnectivityReachability.http({
    Uri? uri,
    Duration timeout = const Duration(seconds: 3),
    Set<int> successCodes = const {204},
  }) {
    return createDefaultReachability(
      uri: uri,
      timeout: timeout,
      successCodes: successCodes,
    );
  }

  /// Returns `true` when a real internet path is available.
  Future<bool> hasInternetAccess();
}

/// Always reports internet as available (tests / demos).
class AlwaysOnlineReachability extends SmartConnectivityReachability {
  /// Creates a checker that always succeeds.
  const AlwaysOnlineReachability();

  @override
  Future<bool> hasInternetAccess() async => true;
}

/// Always reports no internet (tests).
class AlwaysOfflineReachability extends SmartConnectivityReachability {
  /// Creates a checker that always fails.
  const AlwaysOfflineReachability();

  @override
  Future<bool> hasInternetAccess() async => false;
}

/// Callable reachability for tests.
class FunctionReachability extends SmartConnectivityReachability {
  /// Creates a checker that delegates to [check].
  const FunctionReachability(this.check);

  /// Probe implementation.
  final Future<bool> Function() check;

  @override
  Future<bool> hasInternetAccess() => check();
}
