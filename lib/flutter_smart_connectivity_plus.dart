/// Offline and flaky-network handling for Flutter.
///
/// Detect connection loss, show a clear UI, queue actions, and retry safely
/// when the network returns.
///
/// ```dart
/// MaterialApp(
///   builder: SmartConnectivityHost.materialBuilder(),
///   home: const HomeScreen(),
/// )
/// ```
library;

export 'src/smart_connectivity.dart';
export 'src/smart_connectivity_action.dart';
export 'src/smart_connectivity_banner.dart';
export 'src/smart_connectivity_config.dart';
export 'src/smart_connectivity_controller.dart';
export 'src/smart_connectivity_dialog.dart';
export 'src/smart_connectivity_host.dart';
export 'src/smart_connectivity_queue_store.dart';
export 'src/smart_connectivity_reachability.dart';
export 'src/smart_connectivity_scope.dart';
export 'src/smart_connectivity_status.dart';
export 'src/smart_connectivity_submit.dart';
export 'src/smart_connectivity_toast.dart';
export 'src/smart_connectivity_ui.dart';
