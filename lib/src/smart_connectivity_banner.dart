import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'smart_connectivity_config.dart';
import 'smart_connectivity_controller.dart';
import 'smart_connectivity_status.dart';

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
    final background = config.bannerBackgroundColor;
    final foreground = config.bannerForegroundColor;
    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: background,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemStatusBarContrastEnforced: false,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Material(
        color: background,
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
                    style: TextStyle(
                      color: foreground,
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
