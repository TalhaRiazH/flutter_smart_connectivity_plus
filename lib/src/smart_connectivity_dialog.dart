import 'package:material_ui/material_ui.dart';

import 'smart_connectivity_config.dart';
import 'smart_connectivity_controller.dart';
import 'smart_connectivity_status.dart';

/// Default card shown when the network drops.
class SmartConnectivityDialog extends StatelessWidget {
  /// Creates the default offline dialog content.
  const SmartConnectivityDialog({
    super.key,
    required this.controller,
    required this.config,
    this.onDismiss,
    this.onAction,
  });

  /// Live offline state and queue.
  final SmartConnectivityController controller;

  /// Copy and retry settings.
  final SmartConnectivityConfig config;

  /// Called when the user closes the dialog.
  final VoidCallback? onDismiss;

  /// Optional custom action from [SmartConnectivityHost.onDialogAction].
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = controller.status == SmartConnectivityStatus.flaky
        ? config.flakyMessage
        : config.offlineMessage;
    final showRetry = config.showRetryButton && controller.queueLength > 0;
    final actionLabel = config.dialogActionLabel;
    final showAction =
        actionLabel != null && actionLabel.isNotEmpty && onAction != null;
    final isFlaky = controller.status == SmartConnectivityStatus.flaky;

    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isFlaky
                          ? const Color(0xFFFFF7ED)
                          : const Color(0xFFFEF2F2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFlaky
                          ? Icons
                              .signal_wifi_statusbar_connected_no_internet_4_rounded
                          : Icons.wifi_off_rounded,
                      size: 30,
                      color: isFlaky
                          ? const Color(0xFFEA580C)
                          : const Color(0xFFDC2626),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    config.dialogTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (message != config.dialogTitle) ...[
                    const SizedBox(height: 10),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                  if (controller.queueLength > 0) ...[
                    const SizedBox(height: 14),
                    Text(
                      '${controller.queueLength} action'
                      '${controller.queueLength == 1 ? '' : 's'} waiting',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (showAction) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          onAction?.call();
                          if (config.dismissDialogOnAction) {
                            onDismiss?.call();
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: config.dialogActionBackgroundColor,
                          foregroundColor: config.dialogActionForegroundColor,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          actionLabel,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onDismiss,
                      style: FilledButton.styleFrom(
                        backgroundColor: config.dialogConfirmBackgroundColor,
                        foregroundColor: config.dialogConfirmForegroundColor,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        config.dialogConfirmLabel,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  if (showRetry) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: controller.isFlushing
                            ? null
                            : () async {
                                await controller.retryNow();
                                if (controller.isOnline) {
                                  onDismiss?.call();
                                }
                              },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFFECACA)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(config.retryLabel),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
