import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// App-wide defaults for offline detection and UI.
@immutable
class SmartConnectivityConfig {
  /// Creates offline behavior settings.
  const SmartConnectivityConfig({
    this.showBanner = true,
    this.showDialog = true,
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
    this.flakyMessage = 'Internet interrupted',
    this.onlineMessage = 'Back online',
    this.retryLabel = 'Retry',
    this.dialogTitle = 'No internet connection',
    this.dialogConfirmLabel = 'OK',
    this.dialogActionLabel,
    this.dismissDialogOnAction = false,
    this.checkRealInternet = true,
    this.internetCheckTimeout = const Duration(seconds: 3),
    this.internetCheckInterval = const Duration(seconds: 15),
    this.internetCheckUrl = 'https://www.gstatic.com/generate_204',
    this.bannerBackgroundColor = const Color(0xFF111827),
    this.bannerForegroundColor = const Color(0xFFF9FAFB),
    this.offlineToastBackgroundColor = const Color(0xFF111827),
    this.offlineToastForegroundColor = const Color(0xFFF9FAFB),
    this.onlineToastBackgroundColor = const Color(0xFF22C55E),
    this.onlineToastForegroundColor = const Color(0xFFF9FAFB),
    this.dialogConfirmBackgroundColor = const Color(0xFFFEE2E2),
    this.dialogConfirmForegroundColor = const Color(0xFFDC2626),
    this.dialogActionBackgroundColor = const Color(0xFFF3F4F6),
    this.dialogActionForegroundColor = const Color(0xFF6B7280),
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

  /// Banner / dialog / toast body text while linked but without internet
  /// (Wi‑Fi "!" / captive portal).
  final String flakyMessage;

  /// Top toast text when the network returns.
  final String onlineMessage;

  /// When `true`, probes a real URL after the OS reports a link so Wi‑Fi
  /// without internet is treated as [SmartConnectivityStatus.flaky].
  final bool checkRealInternet;

  /// Timeout for each internet probe.
  final Duration internetCheckTimeout;

  /// How often to re-probe while a link is present (catches internet dropping
  /// without a Wi‑Fi disconnect).
  final Duration internetCheckInterval;

  /// URL used by the default HTTP probe (`generate_204` expected).
  final String internetCheckUrl;

  /// Label on the retry control.
  final String retryLabel;

  /// Title for the default offline dialog.
  final String dialogTitle;

  /// Confirm button label on the default offline dialog.
  final String dialogConfirmLabel;

  /// Optional extra button label on the default offline dialog.
  ///
  /// When set, pass [SmartConnectivityHost.onDialogAction] to run your own
  /// task (open settings, navigate, log analytics, etc.).
  final String? dialogActionLabel;

  /// Whether tapping the custom dialog action closes the dialog.
  ///
  /// Defaults to `false` so the dialog stays up while the user finishes the
  /// custom task.
  final bool dismissDialogOnAction;

  /// Offline banner background.
  final Color bannerBackgroundColor;

  /// Offline banner text / icon color.
  final Color bannerForegroundColor;

  /// Offline toast background.
  final Color offlineToastBackgroundColor;

  /// Offline toast text color.
  final Color offlineToastForegroundColor;

  /// Back-online toast background.
  final Color onlineToastBackgroundColor;

  /// Back-online toast text color.
  final Color onlineToastForegroundColor;

  /// Default dialog OK button background.
  final Color dialogConfirmBackgroundColor;

  /// Default dialog OK button text color.
  final Color dialogConfirmForegroundColor;

  /// Default dialog custom-action button background (lightest grey).
  final Color dialogActionBackgroundColor;

  /// Default dialog custom-action button text color.
  final Color dialogActionForegroundColor;

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
    String? dialogActionLabel,
    bool clearDialogActionLabel = false,
    bool? dismissDialogOnAction,
    bool? checkRealInternet,
    Duration? internetCheckTimeout,
    Duration? internetCheckInterval,
    String? internetCheckUrl,
    Color? bannerBackgroundColor,
    Color? bannerForegroundColor,
    Color? offlineToastBackgroundColor,
    Color? offlineToastForegroundColor,
    Color? onlineToastBackgroundColor,
    Color? onlineToastForegroundColor,
    Color? dialogConfirmBackgroundColor,
    Color? dialogConfirmForegroundColor,
    Color? dialogActionBackgroundColor,
    Color? dialogActionForegroundColor,
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
      dialogActionLabel: clearDialogActionLabel
          ? null
          : (dialogActionLabel ?? this.dialogActionLabel),
      dismissDialogOnAction:
          dismissDialogOnAction ?? this.dismissDialogOnAction,
      checkRealInternet: checkRealInternet ?? this.checkRealInternet,
      internetCheckTimeout:
          internetCheckTimeout ?? this.internetCheckTimeout,
      internetCheckInterval:
          internetCheckInterval ?? this.internetCheckInterval,
      internetCheckUrl: internetCheckUrl ?? this.internetCheckUrl,
      bannerBackgroundColor:
          bannerBackgroundColor ?? this.bannerBackgroundColor,
      bannerForegroundColor:
          bannerForegroundColor ?? this.bannerForegroundColor,
      offlineToastBackgroundColor:
          offlineToastBackgroundColor ?? this.offlineToastBackgroundColor,
      offlineToastForegroundColor:
          offlineToastForegroundColor ?? this.offlineToastForegroundColor,
      onlineToastBackgroundColor:
          onlineToastBackgroundColor ?? this.onlineToastBackgroundColor,
      onlineToastForegroundColor:
          onlineToastForegroundColor ?? this.onlineToastForegroundColor,
      dialogConfirmBackgroundColor:
          dialogConfirmBackgroundColor ?? this.dialogConfirmBackgroundColor,
      dialogConfirmForegroundColor:
          dialogConfirmForegroundColor ?? this.dialogConfirmForegroundColor,
      dialogActionBackgroundColor:
          dialogActionBackgroundColor ?? this.dialogActionBackgroundColor,
      dialogActionForegroundColor:
          dialogActionForegroundColor ?? this.dialogActionForegroundColor,
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
        other.dialogConfirmLabel == dialogConfirmLabel &&
        other.dialogActionLabel == dialogActionLabel &&
        other.dismissDialogOnAction == dismissDialogOnAction &&
        other.checkRealInternet == checkRealInternet &&
        other.internetCheckTimeout == internetCheckTimeout &&
        other.internetCheckInterval == internetCheckInterval &&
        other.internetCheckUrl == internetCheckUrl &&
        other.bannerBackgroundColor == bannerBackgroundColor &&
        other.bannerForegroundColor == bannerForegroundColor &&
        other.offlineToastBackgroundColor == offlineToastBackgroundColor &&
        other.offlineToastForegroundColor == offlineToastForegroundColor &&
        other.onlineToastBackgroundColor == onlineToastBackgroundColor &&
        other.onlineToastForegroundColor == onlineToastForegroundColor &&
        other.dialogConfirmBackgroundColor == dialogConfirmBackgroundColor &&
        other.dialogConfirmForegroundColor == dialogConfirmForegroundColor &&
        other.dialogActionBackgroundColor == dialogActionBackgroundColor &&
        other.dialogActionForegroundColor == dialogActionForegroundColor;
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
    dialogActionLabel,
    dismissDialogOnAction,
    checkRealInternet,
    internetCheckTimeout,
    internetCheckInterval,
    internetCheckUrl,
    bannerBackgroundColor,
    bannerForegroundColor,
    offlineToastBackgroundColor,
    offlineToastForegroundColor,
    onlineToastBackgroundColor,
    onlineToastForegroundColor,
    dialogConfirmBackgroundColor,
    dialogConfirmForegroundColor,
    dialogActionBackgroundColor,
    dialogActionForegroundColor,
  ]);
}
