import 'package:flutter/widgets.dart';

import 'smart_connectivity_config.dart';
import 'smart_connectivity_controller.dart';

/// Builds a custom offline banner or dialog body.
typedef SmartConnectivityWidgetBuilder = Widget Function(
  BuildContext context,
  SmartConnectivityController controller,
  SmartConnectivityConfig config,
);
