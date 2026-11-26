import 'smart_connectivity_reachability.dart';

/// Creates the default web reachability checker.
///
/// Browsers block cross-origin probes (CORS), so the default web
/// implementation cannot reliably hit `generate_204`. It reports online and
/// relies on [connectivity_plus] / the browser. Pass a custom
/// [SmartConnectivityReachability] if you probe a same-origin health URL.
SmartConnectivityReachability createDefaultReachability({
  Uri? uri,
  Duration timeout = const Duration(seconds: 3),
  Set<int> successCodes = const {204},
}) {
  return const AlwaysOnlineReachability();
}
