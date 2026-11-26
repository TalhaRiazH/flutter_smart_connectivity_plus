# flutter_smart_connectivity_plus

Offline and flaky-network handling for Flutter.

<p align="center">
  <img src="https://raw.githubusercontent.com/TalhaRiazH/flutter_smart_safe_area_images/main/screenshots/connectivity_demo.gif" alt="Offline banner, dialog, toast, and back online demo" width="320" />
</p>

Banner, dialog, and toast when the network drops — then a green **Back online** strip when it returns. GIFs loop automatically on GitHub and pub.dev.

**Offline.** Dark top banner with light status-bar icons — `No internet connection`.

![Offline banner. Dark strip with No internet connection.](https://raw.githubusercontent.com/TalhaRiazH/flutter_smart_safe_area_images/main/screenshots/connectivity_offline_banner.png)

**Offline dialog.** Card with optional custom action (light grey) and OK.

![Offline dialog. No internet connection with Open settings and OK.](https://raw.githubusercontent.com/TalhaRiazH/flutter_smart_safe_area_images/main/screenshots/connectivity_offline_dialog.png)

**Back online.** Bright green top strip when the network returns.

![Back online. Bright green strip with Back online.](https://raw.githubusercontent.com/TalhaRiazH/flutter_smart_safe_area_images/main/screenshots/connectivity_back_online.png)

`flutter_smart_connectivity_plus` handles the full offline product flow: detect connection loss, show a clear banner / dialog / toast, queue actions by id (in memory or saved across restarts), and replay them when the network returns with a stable idempotency key for your server.

## What problem does this solve?

The phone goes offline. A sync or payment fails. The user taps again. You get random errors, double submits, or silent loss of work.

This package owns that flow with one host for the whole app.

| The phone is… | What happens |
| --- | --- |
| Offline | Banner shows. New work can wait in a queue. |
| Wi‑Fi / cellular on, but no internet (OS “!”) | Treated as flaky — same offline UI; APIs stay blocked. |
| Back online | Queued work retries automatically. |
| Same action tapped twice | One queue entry — same id is not duplicated. |
| App is closed and reopened | Durable actions are restored and replayed. |
| Login expired on replay | Replay pauses; you refresh the session and retry. |

**Step 1 — Add the package**

```bash
flutter pub add flutter_smart_connectivity_plus
```

**Step 2 — Turn it on in `main.dart`**

```dart
import 'package:material_ui/material_ui.dart';
import 'package:flutter_smart_connectivity_plus/flutter_smart_connectivity_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: SmartConnectivityHost.materialBuilder(),
      home: const HomeScreen(),
    );
  }
}
```

That completes setup. Offline handling is now active across your app.

## What more can be done

The steps above are enough for most apps. Use the sections below when you need queuing, a queue that survives restart, session refresh on replay, a submit button, or custom offline UI.

## Wi‑Fi connected but no internet

`connectivity_plus` only sees the link. This package also probes a real URL (`generate_204` by default) so a Wi‑Fi “!” / dead ISP / captive portal becomes **flaky**: offline UI shows and `isOnline` stays `false` so APIs are not fired.

```dart
SmartConnectivityConfig(
  checkRealInternet: true, // default
  internetCheckInterval: Duration(seconds: 15),
  internetCheckTimeout: Duration(seconds: 3),
)
```

## Queue work from any screen

```dart
final offline = SmartConnectivity.of(context);

await offline.runOrEnqueue('sync-profile', () async {
  await api.syncProfile();
});
```

If the device is online, the task runs now. If not, it waits in the queue and runs when the network returns.

This queue lives in memory for the current session. For work that must survive an app restart, use the durable queue below.

## Queue that survives restart

A closure such as `() => api.checkout()` cannot be saved to disk. Durable work is saved as a **type + payload**, and you register one handler per type at app start.

```dart
final controller = SmartConnectivityController(
  queueStore: const SharedPreferencesQueueStore(),
);

controller.registerHandler('sync-profile', (request) async {
  await api.syncProfile(request.payload['userId'] as String);
});

MaterialApp(
  builder: SmartConnectivityHost.materialBuilder(controller: controller),
  home: const HomeScreen(),
);
```

Queue work from any screen:

```dart
await SmartConnectivity.of(context).runOrEnqueueDurable(
  id: 'sync-profile-42',
  type: 'sync-profile',
  payload: {'userId': '42'},
);
```

If the app is killed while offline, the action is restored on the next launch and runs when its handler is registered and the network is back. Use your own storage (SQLite, Hive, secure storage) by implementing `SmartConnectivityQueueStore`.

## Expired login on replay

Queued work can replay hours later, after the session has expired. Refresh it before the queue runs, and tell the package when a request is rejected:

```dart
final controller = SmartConnectivityController(
  queueStore: const SharedPreferencesQueueStore(),
  beforeFlush: () async => auth.refreshIfNeeded(), // return false to pause
  onAuthExpired: () => navigatorKey.currentState?.pushNamed('/login'),
);

controller.registerHandler('sync-profile', (request) async {
  final response = await api.syncProfile(request.payload);
  if (response.statusCode == 401) {
    throw const SmartConnectivityAuthException();
  }
});
```

On `SmartConnectivityAuthException` the replay stops, the action stays queued, and no retry attempt is counted. After the user signs in again, call `controller.retryNow()`.

## Avoid double charges on the server

The queue id stops the same action from being queued twice on the device. It cannot know whether a request already reached your server before the connection dropped. For that, every durable request carries a stable `idempotencyKey` (defaults to the id):

```dart
controller.registerHandler('checkout', (request) async {
  await http.post(
    checkoutUri,
    headers: {'Idempotency-Key': request.idempotencyKey},
    body: jsonEncode(request.payload),
  );
});
```

Your server stores that key and returns the earlier result when it sees it again. `request.isReplay` is `true` when the action was restored after a restart or a previous attempt may already have reached the server.

## Submit button that respects offline

```dart
SmartConnectivitySubmit(
  actionId: 'checkout',
  onPressed: () async => api.checkout(),
  child: const Text('Pay now'),
)
```

## Works on every screen

Set the host once in `MaterialApp.builder`. Navigate anywhere in the app.
When the internet drops, the package still shows your banner / dialog / toast
on top of the current route. When the internet returns:

* offline banner, dialog, and offline toast close automatically
* a top toast says **Back online** (customizable)

## Banner, dialog, toast

```dart
// Defaults already: banner + dialog + back-online strip.
// Opt in to more, or turn defaults off, as you need:
SmartConnectivityHost.materialBuilder(
  config: const SmartConnectivityConfig(
    showOfflineToast: true,  // optional extra offline toast
    // showBanner: false,
    // showDialog: false,
    // showOnlineToast: false,
  ),
)
```

## Custom button on the offline dialog

Hidden by default. Opt in with a label + callback (button is lightest grey):

```dart
SmartConnectivityHost.materialBuilder(
  config: const SmartConnectivityConfig(
    dialogActionLabel: 'Open settings',
    // dismissDialogOnAction: true,
    // dialogActionBackgroundColor: Color(0xFFF3F4F6),
    // dialogActionForegroundColor: Color(0xFF6B7280),
  ),
  onDialogAction: () {
    // your task
  },
)
```

## Edit banner, dialog, and toast

**Option A — tweak the defaults** with config colors / copy  
(`bannerBackgroundColor`, `onlineToastBackgroundColor`, `dialogConfirmBackgroundColor`, messages, labels, …).

**Option B — replace them fully** with your own widgets:

```dart
SmartConnectivityHost.materialBuilder(
  offlineBannerBuilder: (context, controller, config) {
    return YourBanner(message: config.offlineMessage);
  },
  offlineDialogBuilder: (context, controller, config, onDismiss, onAction) {
    return YourDialog(
      title: config.dialogTitle,
      onClose: onDismiss,
      onCustom: onAction,
    );
  },
  offlineToastBuilder: (context, controller, config) {
    return YourToast(message: config.offlineMessage);
  },
  onlineToastBuilder: (context, controller, config) {
    return YourToast(message: config.onlineMessage);
  },
)
```

## Config

Every parameter is optional.

| Parameter | Default | Meaning |
| --- | --- | --- |
| `showBanner` | `true` | Offline top banner (default on) |
| `showDialog` | `true` | Offline dialog (default on) |
| `showOfflineToast` | `false` | Extra offline toast (opt in) |
| `showOnlineToast` | `true` | Back-online strip (default on) |
| `showRetryButton` | `true` | Show Retry when the queue is not empty |
| `barrierDismissible` | `true` | Tap outside to close the dialog |
| `autoRetry` | `true` | Flush the queue when back online |
| `maxRetries` | `3` | Drop a failing action after this many tries |
| `retryDelay` | `2s` | Wait between retries |
| `offlineToastDuration` | `3s` | Offline toast lifetime |
| `onlineToastDuration` | `2s` | Back-online toast lifetime |
| `offlineMessage` | `No internet connection` | Offline copy |
| `flakyMessage` | `Internet interrupted` | Linked but unreachable / dropped mid-use |
| `onlineMessage` | `Back online` | Back-online toast copy |
| `retryLabel` | `Retry` | Retry button label |
| `dialogTitle` | `No internet connection` | Default dialog title |
| `dialogConfirmLabel` | `OK` | Default dialog confirm label |
| `dialogActionLabel` | `null` | Extra dialog button (hidden unless set + `onDialogAction`) |
| `dismissDialogOnAction` | `false` | Close dialog after the custom action |
| `bannerBackgroundColor` | dark | Offline banner background |
| `bannerForegroundColor` | near-white | Offline banner text |
| `offlineToastBackgroundColor` | dark | Offline toast background |
| `offlineToastForegroundColor` | near-white | Offline toast text |
| `onlineToastBackgroundColor` | bright green | Back-online toast background |
| `onlineToastForegroundColor` | near-white | Back-online toast text |
| `dialogConfirmBackgroundColor` | light red | OK button background |
| `dialogConfirmForegroundColor` | red | OK button text |
| `dialogActionBackgroundColor` | lightest grey | Custom action button background |
| `dialogActionForegroundColor` | grey | Custom action button text |

```dart
MaterialApp(
  builder: SmartConnectivityHost.materialBuilder(
    config: const SmartConnectivityConfig(
      showDialog: true,
      offlineMessage: 'No internet. We will retry when you are back.',
      maxRetries: 5,
    ),
  ),
  home: const HomeScreen(),
)
```

## Demo offline without airplane mode

```dart
final controller = SmartConnectivityController(
  statusOverride: SmartConnectivityStatus.online,
);

MaterialApp(
  builder: SmartConnectivityHost.materialBuilder(controller: controller),
  home: const HomeScreen(),
);

// Later:
controller.debugOverrideStatus(SmartConnectivityStatus.offline);
```

## Example app

See the `example/` folder: force offline, queue a sync, then come back online and watch it flush.

## Author

[Talha Riaz](https://www.linkedin.com/in/talha-riaz-7a21a8219/)

## License

MIT
