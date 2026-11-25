import 'package:material_ui/material_ui.dart';
import 'package:flutter_smart_connectivity_plus/flutter_smart_connectivity_plus.dart';

final SmartConnectivityController demoController = SmartConnectivityController(
  statusOverride: SmartConnectivityStatus.online,
  queueStore: const SharedPreferencesQueueStore(),
);

int durableSyncCount = 0;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  demoController.registerHandler('sync-profile', (request) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!demoController.isOnline) throw StateError('Still offline');
    durableSyncCount += 1;
  });
  runApp(const OfflineDemoApp());
}

class OfflineDemoApp extends StatefulWidget {
  const OfflineDemoApp({super.key});

  @override
  State<OfflineDemoApp> createState() => _OfflineDemoAppState();
}

class _OfflineDemoAppState extends State<OfflineDemoApp> {
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  // Same widgets/copy as the published package — only toggle which surface shows.
  SmartConnectivityConfig _config = const SmartConnectivityConfig(
    showBanner: false,
    showDialog: false,
    showOfflineToast: false,
    showOnlineToast: false,
    offlineToastDuration: Duration(seconds: 4),
    onlineToastDuration: Duration(seconds: 4),
  );

  /// Hides the demo chrome so dialog screenshots stay clean.
  bool _hideDemoChrome = false;

  SmartConnectivityConfig _previewConfig({
    bool banner = false,
    bool dialog = false,
    bool offlineToast = false,
    bool onlineToast = false,
  }) {
    return SmartConnectivityConfig(
      showBanner: banner,
      showDialog: dialog,
      showOfflineToast: offlineToast,
      showOnlineToast: onlineToast,
      offlineToastDuration: const Duration(seconds: 4),
      onlineToastDuration: const Duration(seconds: 4),
      dialogActionLabel: dialog ? 'Open settings' : null,
    );
  }

  Future<void> _resetOnline() async {
    demoController.debugOverrideStatus(SmartConnectivityStatus.online);
    await Future<void>.delayed(const Duration(milliseconds: 80));
  }

  Future<void> _previewOffline({
    bool banner = false,
    bool dialog = false,
    bool toast = false,
  }) async {
    await _resetOnline();
    final next = _previewConfig(
      banner: banner,
      dialog: dialog,
      offlineToast: toast,
    );
    setState(() {
      _config = next;
      // Dialog-only: blank white page behind the card for screenshots.
      _hideDemoChrome = dialog && !banner && !toast;
    });
    demoController.updateConfig(next);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    demoController.debugOverrideStatus(SmartConnectivityStatus.offline);
  }

  Future<void> _previewBackOnline() async {
    await _resetOnline();
    final next = _previewConfig(onlineToast: true);
    setState(() => _config = next);
    demoController.updateConfig(next);
    demoController.debugOverrideStatus(SmartConnectivityStatus.offline);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    demoController.debugOverrideStatus(SmartConnectivityStatus.online);
  }

  Future<void> _previewAllOffline() async {
    await _previewOffline(banner: true, dialog: true, toast: true);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messengerKey,
      title: 'flutter_smart_connectivity_plus',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0E7490)),
        useMaterial3: true,
      ),
      builder: SmartConnectivityHost.materialBuilder(
        controller: demoController,
        config: _config,
        onDialogAction: () {
          _messengerKey.currentState?.showSnackBar(
            const SnackBar(content: Text('Custom dialog action tapped')),
          );
        },
      ),
      home: HomeScreen(
        hideDemoChrome: _hideDemoChrome,
        onPreviewOfflineBanner: () => _previewOffline(banner: true),
        onPreviewOfflineDialog: () => _previewOffline(dialog: true),
        onPreviewOfflineToast: () => _previewOffline(toast: true),
        onPreviewAllOffline: _previewAllOffline,
        onPreviewBackOnline: _previewBackOnline,
        onResetOnline: () async {
          await _resetOnline();
          final next = _previewConfig();
          setState(() {
            _config = next;
            _hideDemoChrome = false;
          });
          demoController.updateConfig(next);
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.hideDemoChrome,
    required this.onPreviewOfflineBanner,
    required this.onPreviewOfflineDialog,
    required this.onPreviewOfflineToast,
    required this.onPreviewAllOffline,
    required this.onPreviewBackOnline,
    required this.onResetOnline,
  });

  final bool hideDemoChrome;
  final Future<void> Function() onPreviewOfflineBanner;
  final Future<void> Function() onPreviewOfflineDialog;
  final Future<void> Function() onPreviewOfflineToast;
  final Future<void> Function() onPreviewAllOffline;
  final Future<void> Function() onPreviewBackOnline;
  final Future<void> Function() onResetOnline;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _syncCount = 0;
  String _lastResult = 'No sync yet';

  @override
  void initState() {
    super.initState();
    demoController.addListener(_onController);
  }

  @override
  void dispose() {
    demoController.removeListener(_onController);
    super.dispose();
  }

  void _onController() {
    if (mounted) setState(() {});
  }

  Future<void> _fakeSync() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!demoController.isOnline) {
      throw StateError('Still offline');
    }
    _syncCount += 1;
    _lastResult = 'Sync #$_syncCount completed';
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final status = demoController.status.name;
    final queue = demoController.queueLength;
    final theme = Theme.of(context);

    if (widget.hideDemoChrome) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: SizedBox.expand(),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Smart Connectivity')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          Text('Status: $status', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Queue: $queue action(s)'),
          const SizedBox(height: 8),
          Text(_lastResult),
          const SizedBox(height: 8),
          Text('Durable syncs completed: $durableSyncCount'),
          const SizedBox(height: 20),
          Text('Preview UI', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Uses the real package defaults: banner/toast/dialog '
            '“No internet connection”, online “Back online”.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.tonal(
            onPressed: widget.onPreviewOfflineBanner,
            child: const Text('Offline banner'),
          ),
          const SizedBox(height: 10),
          FilledButton.tonal(
            onPressed: widget.onPreviewOfflineDialog,
            child: const Text('Offline dialog'),
          ),
          const SizedBox(height: 10),
          FilledButton.tonal(
            onPressed: widget.onPreviewOfflineToast,
            child: const Text('Offline toast'),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: widget.onPreviewAllOffline,
            child: const Text('All offline UI'),
          ),
          const SizedBox(height: 10),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
            ),
            onPressed: widget.onPreviewBackOnline,
            child: const Text('Back online toast'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: widget.onResetOnline,
            child: const Text('Reset to online'),
          ),
          const SizedBox(height: 28),
          Text('Also try', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SecondScreen()),
              );
            },
            child: const Text('Open another screen'),
          ),
          const SizedBox(height: 12),
          SmartConnectivitySubmit(
            actionId: 'sync-profile',
            onPressed: _fakeSync,
            child: const Text('Sync profile'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () => demoController.runOrEnqueueDurable(
              id: 'sync-profile-demo',
              type: 'sync-profile',
              payload: {'userId': 'demo'},
            ),
            child: const Text('Durable sync (survives restart)'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => demoController.retryNow(),
            child: const Text('Retry queue now'),
          ),
        ],
      ),
    );
  }
}

class SecondScreen extends StatelessWidget {
  const SecondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Second screen')),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'Trigger offline UI from the home screen, then open this route — '
          'the host still shows banner/dialog/toast on top.',
        ),
      ),
    );
  }
}
