import 'package:flutter/foundation.dart';

/// App-wide defaults for offline detection and UI.
@immutable
class SmartConnectivityConfig {
  /// Creates offline behavior settings.
  const SmartConnectivityConfig({
    this.showBanner = true,
    this.showDialog = false,
    this.showOfflineToast = false,
    this.showOnlineToast = true,
    this.showRetryButton = true,
    this.barrierDismissible = true,
    this.autoRetry = true,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
    this.offlineToastDuration = const Duration(seconds: 3),
    this.onlineToastDuration = const Duration(seconds: 2),
    this.offlineMessage = 'No internet connection',
    this.flakyMessage = 'Connection is unstable',
    this.onlineMessage = 'Back online',
    this.retryLabel = 'Retry',
    this.dialogTitle = 'No internet connection',
    this.dialogConfirmLabel = 'OK',
  }) : assert(maxRetries >= 0);

  /// Whether the host shows the persistent offline banner on every screen.
  final bool showBanner;

  /// Whether the host shows an offline dialog when the network drops.
  final bool showDialog;

  /// Whether the host shows a top toast when the network drops.
  final bool showOfflineToast;

  /// Whether the host shows a top toast when the network returns.
  final bool showOnlineToast;

  /// Whether the banner/dialog shows a Retry control when the queue is not empty.
  final bool showRetryButton;

  /// Whether the user can dismiss the offline dialog by tapping outside it.
  final bool barrierDismissible;

  /// Whether queued actions retry when the network returns.
  final bool autoRetry;

  /// How many times a queued action may retry.
  final int maxRetries;

  /// Delay between automatic retries.
  final Duration retryDelay;

  /// How long the offline toast stays visible.
  final Duration offlineToastDuration;

  /// How long the back-online toast stays visible.
  final Duration onlineToastDuration;

  /// Banner / dialog / toast body text while offline.
  final String offlineMessage;

  /// Banner / dialog / toast body text while the connection looks flaky.
  final String flakyMessage;

  /// Top toast text when the network returns.
  final String onlineMessage;

  /// Label on the retry control.
  final String retryLabel;

  /// Title for the default offline dialog.
  final String dialogTitle;

  /// Confirm button label on the default offline dialog.
  final String dialogConfirmLabel;

  /// Returns a copy with the given fields replaced.
  SmartConnectivityConfig copyWith({
    bool? showBanner,
    bool? showDialog,
    bool? showOfflineToast,
    bool? showOnlineToast,
    bool? showRetryButton,
    bool? barrierDismissible,
    bool? autoRetry,
    int? maxRetries,
    Duration? retryDelay,
    Duration? offlineToastDuration,
    Duration? onlineToastDuration,
    String? offlineMessage,
    String? flakyMessage,
    String? onlineMessage,
    String? retryLabel,
    String? dialogTitle,
    String? dialogConfirmLabel,
  }) {
    return SmartConnectivityConfig(
      showBanner: showBanner ?? this.showBanner,
      showDialog: showDialog ?? this.showDialog,
      showOfflineToast: showOfflineToast ?? this.showOfflineToast,
      showOnlineToast: showOnlineToast ?? this.showOnlineToast,
      showRetryButton: showRetryButton ?? this.showRetryButton,
      barrierDismissible: barrierDismissible ?? this.barrierDismissible,
      autoRetry: autoRetry ?? this.autoRetry,
      maxRetries: maxRetries ?? this.maxRetries,
      retryDelay: retryDelay ?? this.retryDelay,
      offlineToastDuration: offlineToastDuration ?? this.offlineToastDuration,
      onlineToastDuration: onlineToastDuration ?? this.onlineToastDuration,
      offlineMessage: offlineMessage ?? this.offlineMessage,
      flakyMessage: flakyMessage ?? this.flakyMessage,
      onlineMessage: onlineMessage ?? this.onlineMessage,
      retryLabel: retryLabel ?? this.retryLabel,
      dialogTitle: dialogTitle ?? this.dialogTitle,
      dialogConfirmLabel: dialogConfirmLabel ?? this.dialogConfirmLabel,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SmartConnectivityConfig &&
        other.showBanner == showBanner &&
        other.showDialog == showDialog &&
        other.showOfflineToast == showOfflineToast &&
        other.showOnlineToast == showOnlineToast &&
        other.showRetryButton == showRetryButton &&
        other.barrierDismissible == barrierDismissible &&
        other.autoRetry == autoRetry &&
        other.maxRetries == maxRetries &&
        other.retryDelay == retryDelay &&
        other.offlineToastDuration == offlineToastDuration &&
        other.onlineToastDuration == onlineToastDuration &&
        other.offlineMessage == offlineMessage &&
        other.flakyMessage == flakyMessage &&
        other.onlineMessage == onlineMessage &&
        other.retryLabel == retryLabel &&
        other.dialogTitle == dialogTitle &&
        other.dialogConfirmLabel == dialogConfirmLabel;
  }

  @override
  int get hashCode => Object.hashAll([
        showBanner,
        showDialog,
        showOfflineToast,
        showOnlineToast,
        showRetryButton,
        barrierDismissible,
        autoRetry,
        maxRetries,
        retryDelay,
        offlineToastDuration,
        onlineToastDuration,
        offlineMessage,
        flakyMessage,
        onlineMessage,
        retryLabel,
        dialogTitle,
        dialogConfirmLabel,
      ]);
}
