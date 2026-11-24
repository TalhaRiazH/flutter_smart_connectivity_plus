/// Offline and flaky-network handling for Flutter.
///
/// Detect connection loss, show a clear UI, queue actions, and retry safely
/// when the network returns.
///
/// ```dart
/// MaterialApp(
///   builder: SmartOfflineHost.materialBuilder(),
///   home: const HomeScreen(),
/// )
/// ```
library;

export 'src/smart_offline.dart';
export 'src/smart_offline_action.dart';
export 'src/smart_offline_banner.dart';
export 'src/smart_offline_config.dart';
export 'src/smart_offline_controller.dart';
export 'src/smart_offline_dialog.dart';
export 'src/smart_offline_host.dart';
export 'src/smart_offline_scope.dart';
export 'src/smart_offline_status.dart';
export 'src/smart_offline_submit.dart';
export 'src/smart_offline_toast.dart';
export 'src/smart_offline_ui.dart';
