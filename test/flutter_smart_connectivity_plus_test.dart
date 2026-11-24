import 'package:flutter/material.dart';
import 'package:flutter_smart_connectivity_plus/flutter_smart_connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('default config keeps banner and auto-retry on', () {
    const config = SmartOfflineConfig();
    expect(config.showBanner, isTrue);
    expect(config.autoRetry, isTrue);
    expect(config.maxRetries, 3);
    expect(config, equals(const SmartOfflineConfig()));
  });

  test('enqueue dedupes by id', () async {
    final controller = SmartOfflineController(
      statusOverride: SmartOfflineStatus.offline,
      config: const SmartOfflineConfig(autoRetry: false),
    );
    await controller.start();

    controller.enqueue(
      SmartOfflineAction(id: 'sync', run: () async {}),
    );
    controller.enqueue(
      SmartOfflineAction(id: 'sync', run: () async {}),
    );

    expect(controller.queueLength, 1);
    controller.dispose();
  });

  test('runOrEnqueue queues while offline and runs while online', () async {
    final controller = SmartOfflineController(
      statusOverride: SmartOfflineStatus.offline,
      config: const SmartOfflineConfig(autoRetry: false),
    );
    await controller.start();

    var ran = 0;
    final queued = await controller.runOrEnqueue('job', () async {
      ran += 1;
    });
    expect(queued, isFalse);
    expect(controller.queueLength, 1);
    expect(ran, 0);

    controller.debugOverrideStatus(SmartOfflineStatus.online);
    final ranNow = await controller.runOrEnqueue('other', () async {
      ran += 1;
    });
    expect(ranNow, isTrue);
    expect(ran, 1);
    controller.dispose();
  });

  test('flush runs queued work when online', () async {
    final controller = SmartOfflineController(
      statusOverride: SmartOfflineStatus.offline,
      config: const SmartOfflineConfig(autoRetry: false),
    );
    await controller.start();

    var ran = 0;
    controller.enqueue(
      SmartOfflineAction(
        id: 'a',
        run: () async {
          ran += 1;
        },
      ),
    );

    controller.debugOverrideStatus(SmartOfflineStatus.online);
    await controller.flush();

    expect(ran, 1);
    expect(controller.queueLength, 0);
    controller.dispose();
  });

  test('maxRetries drops a failing action', () async {
    final controller = SmartOfflineController(
      statusOverride: SmartOfflineStatus.online,
      config: const SmartOfflineConfig(
        autoRetry: false,
        maxRetries: 1,
        retryDelay: Duration.zero,
      ),
    );
    await controller.start();

    controller.enqueue(
      SmartOfflineAction(
        id: 'fail',
        run: () async {
          throw StateError('nope');
        },
      ),
    );

    await controller.flush();
    expect(controller.queueLength, 0);
    controller.dispose();
  });

  test('remove and clearQueue update the queue', () async {
    final controller = SmartOfflineController(
      statusOverride: SmartOfflineStatus.offline,
      config: const SmartOfflineConfig(autoRetry: false),
    );
    await controller.start();

    controller.enqueue(SmartOfflineAction(id: 'one', run: () async {}));
    controller.enqueue(SmartOfflineAction(id: 'two', run: () async {}));
    controller.remove('one');
    expect(controller.queueLength, 1);
    controller.clearQueue();
    expect(controller.queueLength, 0);
    controller.dispose();
  });

  testWidgets('host shows banner when offline', (tester) async {
    final controller = SmartOfflineController(
      statusOverride: SmartOfflineStatus.offline,
    );

    await tester.pumpWidget(
      MaterialApp(
        builder: SmartOfflineHost.materialBuilder(controller: controller),
        home: const Scaffold(body: Text('home')),
      ),
    );
    await tester.pump();

    expect(find.text('You are offline'), findsOneWidget);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('submit does not double-enqueue the same id', (tester) async {
    final controller = SmartOfflineController(
      statusOverride: SmartOfflineStatus.offline,
      config: const SmartOfflineConfig(autoRetry: false),
    );

    await tester.pumpWidget(
      MaterialApp(
        builder: SmartOfflineHost.materialBuilder(controller: controller),
        home: Scaffold(
          body: SmartOfflineSubmit(
            actionId: 'pay',
            onPressed: () async {},
            child: const Text('Pay'),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(controller.queueLength, 1);
  });

  testWidgets('host shows dialog when showDialog is true', (tester) async {
    final controller = SmartOfflineController(
      statusOverride: SmartOfflineStatus.online,
    );

    await tester.pumpWidget(
      MaterialApp(
        builder: SmartOfflineHost.materialBuilder(
          controller: controller,
          config: const SmartOfflineConfig(showDialog: true),
        ),
        home: const Scaffold(body: Text('home')),
      ),
    );
    await tester.pump();

    controller.debugOverrideStatus(SmartOfflineStatus.offline);
    await tester.pump();
    await tester.pump();

    expect(find.text('No internet connection'), findsOneWidget);
    expect(find.text('You are offline'), findsWidgets);
  });

  testWidgets('shows back-online toast and closes offline dialog',
      (tester) async {
    final controller = SmartOfflineController(
      statusOverride: SmartOfflineStatus.online,
    );

    await tester.pumpWidget(
      MaterialApp(
        builder: SmartOfflineHost.materialBuilder(
          controller: controller,
          config: const SmartOfflineConfig(
            showDialog: true,
            showOnlineToast: true,
            onlineToastDuration: Duration(seconds: 5),
          ),
        ),
        home: const Scaffold(body: Text('home')),
      ),
    );
    await tester.pump();

    controller.debugOverrideStatus(SmartOfflineStatus.offline);
    await tester.pump();
    await tester.pump();
    expect(find.text('No internet connection'), findsOneWidget);

    controller.debugOverrideStatus(SmartOfflineStatus.online);
    await tester.pump();
    await tester.pump();

    expect(find.text('No internet connection'), findsNothing);
    expect(find.text('Back online'), findsOneWidget);
  });

  testWidgets('host uses a custom banner builder', (tester) async {
    final controller = SmartOfflineController(
      statusOverride: SmartOfflineStatus.offline,
    );

    await tester.pumpWidget(
      MaterialApp(
        builder: SmartOfflineHost.materialBuilder(
          controller: controller,
          offlineBannerBuilder: (context, offlineController, config) {
            return const ColoredBox(
              color: Colors.orange,
              child: SizedBox(
                height: 40,
                child: Center(child: Text('my-banner')),
              ),
            );
          },
        ),
        home: const Scaffold(body: Text('home')),
      ),
    );
    await tester.pump();

    expect(find.text('my-banner'), findsOneWidget);
    expect(find.text('You are offline'), findsNothing);
  });

  testWidgets('SmartOffline.of returns the host controller', (tester) async {
    final controller = SmartOfflineController(
      statusOverride: SmartOfflineStatus.online,
    );

    await tester.pumpWidget(
      MaterialApp(
        builder: SmartOfflineHost.materialBuilder(controller: controller),
        home: Builder(
          builder: (context) {
            return Text(SmartOffline.of(context).isOnline ? 'up' : 'down');
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.text('up'), findsOneWidget);
  });
}
