import 'package:flutter/widgets.dart';

import 'smart_offline_config.dart';
import 'smart_offline_controller.dart';

/// Builds a custom offline banner or dialog body.
typedef SmartOfflineWidgetBuilder = Widget Function(
  BuildContext context,
  SmartOfflineController controller,
  SmartOfflineConfig config,
);
