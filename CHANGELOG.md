# Changelog

All notable changes to this project are documented in this file.

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
