import 'package:flutter/widgets.dart';

import 'smart_offline_config.dart';
import 'smart_offline_controller.dart';

/// Exposes the offline controller and config below [SmartOfflineHost].
class SmartOfflineScope extends InheritedWidget {
  /// Creates a scope for [controller] and [config].
  const SmartOfflineScope({
    super.key,
    required this.controller,
    required this.config,
    required super.child,
  });

  /// Live offline state and queue.
  final SmartOfflineController controller;

  /// App-wide offline settings.
  final SmartOfflineConfig config;

  /// The scope above [context], or `null` when there is no host.
  static SmartOfflineScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SmartOfflineScope>();
  }

  /// The scope above [context]. Throws if no host is present.
  static SmartOfflineScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'No SmartOfflineHost found above this context.');
    return scope!;
  }

  @override
  bool updateShouldNotify(SmartOfflineScope oldWidget) {
    return controller != oldWidget.controller || config != oldWidget.config;
  }
}
