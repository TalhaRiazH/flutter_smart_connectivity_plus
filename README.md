# flutter_smart_connectivity_plus

Offline and flaky-network handling for Flutter.

Other packages tell you if the phone is online. This one handles the product flow: detect offline, show a clear banner, queue actions, and retry safely when the network returns — without running the same action twice.

## What problem does this solve?

The phone goes offline. A sync or payment fails. The user taps again. You get random errors, double submits, or silent loss of work.

`flutter_smart_connectivity_plus` is meant to own that flow with one host for the whole app.

| The phone is… | What happens |
| --- | --- |
| Offline | Banner shows. New work can wait in a queue. |
| Back online | Queued work retries automatically. |
| Same action tapped twice | One queue entry — same id is not duplicated. |

## Setup in 2 steps

### Step 1 — Add the package

```bash
flutter pub add flutter_smart_connectivity_plus
```

### Step 2 — Turn it on in `main.dart`

```dart
import 'package:flutter/material.dart';
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

## Queue work from any screen

```dart
final offline = SmartConnectivity.of(context);

await offline.runOrEnqueue('sync-profile', () async {
  await api.syncProfile();
});
```

If the device is online, the task runs now. If not, it waits in the queue and runs when the network returns.

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
SmartConnectivityHost.materialBuilder(
  config: const SmartConnectivityConfig(
    showBanner: true,        // persistent strip on every screen
    showDialog: true,        // alert when the network drops
    showOfflineToast: true,  // top toast when offline
    showOnlineToast: true,   // top toast when back online
    onlineMessage: 'Back online',
  ),
)
```

## Custom banner, dialog, or toast

Pass your own widgets. The host still decides when to show and hide them.

```dart
SmartConnectivityHost.materialBuilder(
  config: const SmartConnectivityConfig(
    showBanner: true,
    showDialog: true,
    showOnlineToast: true,
  ),
  offlineBannerBuilder: (context, controller, config) {
    return YourBanner(message: config.offlineMessage);
  },
  offlineDialogBuilder: (context, controller, config) {
    return YourDialog(message: config.offlineMessage);
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
| `showBanner` | `true` | Persistent strip on every screen |
| `showDialog` | `false` | Dialog when the network drops |
| `showOfflineToast` | `false` | Top toast when offline |
| `showOnlineToast` | `true` | Top toast when back online |
| `showRetryButton` | `true` | Show Retry when the queue is not empty |
| `barrierDismissible` | `true` | Tap outside to close the dialog |
| `autoRetry` | `true` | Flush the queue when back online |
| `maxRetries` | `3` | Drop a failing action after this many tries |
| `retryDelay` | `2s` | Wait between retries |
| `offlineToastDuration` | `3s` | Offline toast lifetime |
| `onlineToastDuration` | `2s` | Back-online toast lifetime |
| `offlineMessage` | `No internet connection` | Offline copy |
| `flakyMessage` | `Connection is unstable` | Flaky copy |
| `onlineMessage` | `Back online` | Back-online toast copy |
| `retryLabel` | `Retry` | Retry button label |
| `dialogTitle` | `No internet connection` | Default dialog title |
| `dialogConfirmLabel` | `OK` | Default dialog confirm label |

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

Talha Riaz  
[LinkedIn](https://www.linkedin.com/in/talha-riaz-7a21a8219/)

## License

MIT
