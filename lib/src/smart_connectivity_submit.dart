import 'package:material_ui/material_ui.dart';

import 'smart_connectivity.dart';
import 'smart_connectivity_action.dart';

/// A button that runs [onPressed] now when online, or queues it while offline.
///
/// Uses [actionId] so the same action is not queued twice.
class SmartConnectivitySubmit extends StatelessWidget {
  /// Creates a submit control bound to a stable [actionId].
  const SmartConnectivitySubmit({
    super.key,
    required this.actionId,
    required this.onPressed,
    required this.child,
    this.style,
  });

  /// Stable id used by the offline queue.
  final String actionId;

  /// Work to run when online (or later when the network returns).
  final SmartConnectivityTask onPressed;

  /// Button label / content.
  final Widget child;

  /// Optional button style.
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final controller = SmartConnectivity.maybeOf(context);

    return AnimatedBuilder(
      animation: controller ?? const _IdleListenable(),
      builder: (context, _) {
        final offline = controller != null && !controller.isOnline;
        final queued =
            controller?.queue.any((item) => item.id == actionId) ?? false;

        return FilledButton(
          style: style,
          onPressed: () async {
            final offlineController = SmartConnectivity.of(context);
            await offlineController.runOrEnqueue(actionId, onPressed);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              child,
              if (offline || queued) ...[
                const SizedBox(width: 8),
                Text(
                  queued ? '(queued)' : '(offline)',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _IdleListenable extends Listenable {
  const _IdleListenable();

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}
