import 'package:flutter/material.dart';
import 'package:flutter_smart_connectivity_plus/flutter_smart_connectivity_plus.dart';

final SmartOfflineController demoController = SmartOfflineController(
  statusOverride: SmartOfflineStatus.online,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OfflineDemoApp());
}

class OfflineDemoApp extends StatelessWidget {
  const OfflineDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'flutter_smart_connectivity_plus',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0E7490)),
        useMaterial3: true,
      ),
      builder: SmartOfflineHost.materialBuilder(
        controller: demoController,
        config: const SmartOfflineConfig(
          showBanner: true,
          showDialog: true,
          showOfflineToast: true,
          showOnlineToast: true,
          offlineMessage: 'You are offline. Actions will wait in the queue.',
          onlineMessage: 'Back online',
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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

    return Scaffold(
      appBar: AppBar(title: const Text('Smart Offline')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          Text(
            'Status: $status',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text('Queue: $queue action(s)'),
          const SizedBox(height: 8),
          Text(_lastResult),
          const SizedBox(height: 24),
          const Text(
            'Works on every screen. Force offline, push another page, then '
            'come back online — dialog/banner close and a top toast says '
            'Back online.',
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Force offline'),
            value: demoController.status == SmartOfflineStatus.offline,
            onChanged: (offline) {
              demoController.debugOverrideStatus(
                offline
                    ? SmartOfflineStatus.offline
                    : SmartOfflineStatus.online,
              );
            },
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SecondScreen(),
                ),
              );
            },
            child: const Text('Open another screen'),
          ),
          const SizedBox(height: 12),
          SmartOfflineSubmit(
            actionId: 'sync-profile',
            onPressed: _fakeSync,
            child: const Text('Sync profile'),
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
          'Go offline from the previous screen or here — the host still '
          'shows banner/dialog/toast on top of this route.',
        ),
      ),
    );
  }
}
