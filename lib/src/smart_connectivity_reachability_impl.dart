import 'dart:async';
import 'dart:io';

import 'smart_connectivity_reachability.dart';

/// Creates the default IO HTTP probe.
SmartConnectivityReachability createDefaultReachability({
  Uri? uri,
  Duration timeout = const Duration(seconds: 3),
  Set<int> successCodes = const {204},
}) {
  return HttpConnectivityReachability(
    uri: uri ?? Uri.parse('https://www.gstatic.com/generate_204'),
    timeout: timeout,
    successCodes: successCodes,
  );
}

/// Probes a URL with [HttpClient] (mobile / desktop).
///
/// Uses Google's `generate_204` by default: a real internet path returns
/// HTTP 204. Captive portals typically return 200 HTML or a redirect.
class HttpConnectivityReachability extends SmartConnectivityReachability {
  /// Creates an HTTP reachability probe.
  HttpConnectivityReachability({
    Uri? uri,
    this.timeout = const Duration(seconds: 3),
    this.successCodes = const {204},
  }) : uri = uri ?? Uri.parse('https://www.gstatic.com/generate_204');

  /// Endpoint that should return a success status when the internet works.
  final Uri uri;

  /// Max wait for connect + response headers.
  final Duration timeout;

  /// HTTP status codes treated as "internet is up".
  final Set<int> successCodes;

  @override
  Future<bool> hasInternetAccess() async {
    final client = HttpClient()
      ..connectionTimeout = timeout
      ..idleTimeout = timeout;
    try {
      final request = await client.getUrl(uri).timeout(timeout);
      request.followRedirects = false;
      final response = await request.close().timeout(timeout);
      // Drain so the connection can close cleanly.
      await response.drain<void>().timeout(timeout);
      return successCodes.contains(response.statusCode);
    } on Object {
      return false;
    } finally {
      client.close(force: true);
    }
  }
}
