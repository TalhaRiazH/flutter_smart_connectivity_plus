import 'package:flutter/widgets.dart';

import 'smart_connectivity_controller.dart';
import 'smart_connectivity_scope.dart';

/// Convenience accessors for the [SmartConnectivityController] above a widget.
abstract final class SmartConnectivity {
  /// The controller above [context]. Throws if no host is present.
  static SmartConnectivityController of(BuildContext context) {
    return SmartConnectivityScope.of(context).controller;
  }

  /// The controller above [context], or `null` when there is no host.
  static SmartConnectivityController? maybeOf(BuildContext context) {
    return SmartConnectivityScope.maybeOf(context)?.controller;
  }
}
