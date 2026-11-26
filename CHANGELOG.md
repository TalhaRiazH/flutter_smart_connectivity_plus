# Changelog

All notable changes to this project are documented in this file.

## 0.2.1

* Detect Wi‑Fi / cellular with no real internet (OS “!”) via an HTTP reachability probe and treat it as flaky so offline UI shows and APIs stay blocked.
* Add `checkRealInternet`, `internetCheckUrl`, `internetCheckTimeout`, `internetCheckInterval`, and `SmartConnectivityReachability`.

## 0.2.0

* Add a durable queue that survives app restart: `registerHandler`, `enqueueDurable`, `runOrEnqueueDurable`, and `SmartConnectivityQueueStore` with `SharedPreferencesQueueStore`.
* Add `beforeFlush` to refresh an expired session before replay, and `SmartConnectivityAuthException` + `onAuthExpired` to pause replay without losing the action.
* Pass a stable `idempotencyKey` and `isReplay` to every durable handler so servers can ignore duplicates.
* Add `onActionDropped` when an action exceeds `maxRetries`.
* Document session vs durable queue behavior in the README.

## 0.1.7

* Migrate UI imports to `material_ui` (Flutter 3.44+) and bump `connectivity_plus` to ^7.3.2 for full pub points.

## 0.1.6

* Add a clear “setup complete” note after Step 2 and a “What more can be done” section for optional features.

## 0.1.5

* Flatten setup steps in the README so Step 1 / Step 2 are not TOC headings.

## 0.1.4

* Clarify the README to describe the package on its own, without comparing to others.

## 0.1.3

* Default UI: offline banner, dialog, and back-online strip on; offline toast off.
* Optional dialog action button (`dialogActionLabel` + `onDialogAction`), lightest grey by default.
* Config colors for banner, toasts, and dialog buttons.
* Full replace via `offlineBannerBuilder`, `offlineDialogBuilder`, `offlineToastBuilder`, `onlineToastBuilder`.
* README demo GIF plus offline / dialog / back-online screenshots.

## 0.1.2

* Default offline copy is now `No internet connection`.
* Redesign the offline dialog card with a light-red confirm button.
* Keep status-bar icons light/white while the dark offline banner is visible.
* Make offline and back-online toasts match the top banner strip layout.
* Use a bright green strip for the back-online toast.
* Fix offline toast filling the whole screen when shown from the overlay.
* Improve the example app with one-tap previews for each UI surface.

## 0.1.1

* Add LinkedIn profile link under the author name in the README.

## 0.1.0

* Add `SmartConnectivityHost` for app-wide offline detection and banner UI.
* Optionally show an offline dialog with `showDialog: true`.
* Show top toasts for offline and automatic "Back online" when the network returns.
* Auto-close banner, dialog, and offline toast on every screen when online again.
* Allow custom banner, dialog, and toast widgets via builders.
* Queue actions by stable id with `runOrEnqueue`, `enqueue`, `flush`, and `retryNow`.
* Prevent duplicate queue entries for the same id.
* Add `SmartConnectivity.of` / `maybeOf` accessors and `SmartConnectivitySubmit`.
* Support demo/test overrides with `debugOverrideStatus`.
* Ship an example app that forces offline and shows queue retry.
