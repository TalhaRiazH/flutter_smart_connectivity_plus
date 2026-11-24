import 'package:flutter/widgets.dart';

import 'smart_connectivity_config.dart';
import 'smart_connectivity_controller.dart';

/// Exposes the offline controller and config below [SmartConnectivityHost].
class SmartConnectivityScope extends InheritedWidget {
  /// Creates a scope for [controller] and [config].
  const SmartConnectivityScope({
    super.key,
    required this.controller,
    required this.config,
    required super.child,
  });

  /// Live offline state and queue.
  final SmartConnectivityController controller;

  /// App-wide offline settings.
  final SmartConnectivityConfig config;

  /// The scope above [context], or `null` when there is no host.
  static SmartConnectivityScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SmartConnectivityScope>();
  }

  /// The scope above [context]. Throws if no host is present.
  static SmartConnectivityScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'No SmartConnectivityHost found above this context.');
    return scope!;
  }

  @override
  bool updateShouldNotify(SmartConnectivityScope oldWidget) {
    return controller != oldWidget.controller || config != oldWidget.config;
  }
}
