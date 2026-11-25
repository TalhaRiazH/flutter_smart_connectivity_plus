# Changelog

All notable changes to this project are documented in this file.

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
