import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'smart_connectivity_config.dart';
import 'smart_connectivity_controller.dart';
import 'smart_connectivity_status.dart';

const Color _bannerColor = Color(0xFF111827);

/// Light status-bar icons so clock / battery stay visible on the dark banner.
const SystemUiOverlayStyle _bannerOverlayStyle = SystemUiOverlayStyle(
  statusBarColor: _bannerColor,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemStatusBarContrastEnforced: false,
);

/// Top banner shown while the app is offline or flaky.
class SmartConnectivityBanner extends StatelessWidget {
  /// Creates a banner bound to [controller].
  const SmartConnectivityBanner({
    super.key,
    required this.controller,
    required this.config,
  });

  /// Live offline state and queue.
  final SmartConnectivityController controller;

  /// Copy and retry settings.
  final SmartConnectivityConfig config;

  @override
  Widget build(BuildContext context) {
    if (!config.showBanner ||
        controller.status == SmartConnectivityStatus.online) {
      return const SizedBox.shrink();
    }

    final message = controller.status == SmartConnectivityStatus.flaky
        ? config.flakyMessage
        : config.offlineMessage;
    final showRetry = config.showRetryButton && controller.queueLength > 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _bannerOverlayStyle,
      child: Material(
        color: _bannerColor,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    message,
                    textAlign: showRetry ? TextAlign.start : TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFF9FAFB),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (showRetry) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: controller.isFlushing
                        ? null
                        : () => controller.retryNow(),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF67E8F9),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(config.retryLabel),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
