import 'package:flutter/widgets.dart';

import 'smart_offline_controller.dart';
import 'smart_offline_scope.dart';

/// Convenience accessors for the [SmartOfflineController] above a widget.
abstract final class SmartOffline {
  /// The controller above [context]. Throws if no host is present.
  static SmartOfflineController of(BuildContext context) {
    return SmartOfflineScope.of(context).controller;
  }

  /// The controller above [context], or `null` when there is no host.
  static SmartOfflineController? maybeOf(BuildContext context) {
    return SmartOfflineScope.maybeOf(context)?.controller;
  }
}
