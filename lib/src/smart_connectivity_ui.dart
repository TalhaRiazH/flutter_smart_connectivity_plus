import 'package:flutter/widgets.dart';

import 'smart_connectivity_config.dart';
import 'smart_connectivity_controller.dart';

/// Builds a custom offline banner or toast.
typedef SmartConnectivityWidgetBuilder = Widget Function(
  BuildContext context,
  SmartConnectivityController controller,
  SmartConnectivityConfig config,
);

/// Builds a fully custom offline dialog.
///
/// Use [onDismiss] to close the package dialog overlay. [onAction] is the
/// optional custom action from [SmartConnectivityHost.onDialogAction].
typedef SmartConnectivityDialogBuilder = Widget Function(
  BuildContext context,
  SmartConnectivityController controller,
  SmartConnectivityConfig config,
  VoidCallback onDismiss,
  VoidCallback? onAction,
);
