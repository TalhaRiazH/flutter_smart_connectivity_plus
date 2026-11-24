import 'package:flutter/material.dart';

import 'smart_offline_config.dart';
import 'smart_offline_controller.dart';
import 'smart_offline_status.dart';

/// Default alert shown when the network drops.
class SmartOfflineDialog extends StatelessWidget {
  /// Creates the default offline dialog content.
  const SmartOfflineDialog({
    super.key,
    required this.controller,
    required this.config,
    this.onDismiss,
  });

  /// Live offline state and queue.
  final SmartOfflineController controller;

  /// Copy and retry settings.
  final SmartOfflineConfig config;

  /// Called when the user closes the dialog.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final message = controller.status == SmartOfflineStatus.flaky
        ? config.flakyMessage
        : config.offlineMessage;
    final showRetry = config.showRetryButton && controller.queueLength > 0;

    return Material(
      color: Colors.transparent,
      child: AlertDialog(
        title: Text(config.dialogTitle),
        content: Text(message),
        actions: [
          if (showRetry)
            TextButton(
              onPressed: controller.isFlushing
                  ? null
                  : () async {
                      await controller.retryNow();
                      if (controller.isOnline) {
                        onDismiss?.call();
                      }
                    },
              child: Text(config.retryLabel),
            ),
          TextButton(
            onPressed: onDismiss,
            child: Text(config.dialogConfirmLabel),
          ),
        ],
      ),
    );
  }
}
