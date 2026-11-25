import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'smart_connectivity_banner.dart';
import 'smart_connectivity_config.dart';
import 'smart_connectivity_controller.dart';
import 'smart_connectivity_dialog.dart';
import 'smart_connectivity_queue_store.dart';
import 'smart_connectivity_scope.dart';
import 'smart_connectivity_status.dart';
import 'smart_connectivity_toast.dart';
import 'smart_connectivity_ui.dart';

/// App-level host that watches connectivity on every screen.
///
/// Put this once in [MaterialApp.builder]. When the network drops it can show
/// a banner, dialog, and/or top toast — including custom widgets. When the
/// network returns, offline UI closes and an optional "back online" toast
/// slides in from the top.
class SmartConnectivityHost extends StatefulWidget {
  /// Creates an app-level offline host.
  const SmartConnectivityHost({
    super.key,
    this.config = const SmartConnectivityConfig(),
    this.controller,
    this.offlineBannerBuilder,
    this.offlineDialogBuilder,
    this.offlineToastBuilder,
    this.onlineToastBuilder,
    this.onDialogAction,
    this.queueStore,
    this.beforeFlush,
    this.onAuthExpired,
    this.onActionDropped,
    required this.child,
  });

  /// Defaults for banners, dialogs, toasts, and retries.
  final SmartConnectivityConfig config;

  /// Optional controller for tests and demos. Owned by the host when null.
  final SmartConnectivityController? controller;

  /// Fully custom offline banner. When null, [SmartConnectivityBanner] is used.
  final SmartConnectivityWidgetBuilder? offlineBannerBuilder;

  /// Fully custom offline dialog. When null, [SmartConnectivityDialog] is used.
  ///
  /// Receives [onDismiss] / [onAction] so your widget can close the overlay or
  /// run the same custom action as the default dialog button.
  final SmartConnectivityDialogBuilder? offlineDialogBuilder;

  /// Fully custom offline toast. When null, [SmartConnectivityToast] is used.
  final SmartConnectivityWidgetBuilder? offlineToastBuilder;

  /// Fully custom back-online toast. When null, [SmartConnectivityToast] is used.
  final SmartConnectivityWidgetBuilder? onlineToastBuilder;

  /// Runs when the user taps the optional dialog action button.
  ///
  /// Set [SmartConnectivityConfig.dialogActionLabel] to show the button.
  final VoidCallback? onDialogAction;

  /// Where durable actions are saved. Use [SharedPreferencesQueueStore] so
  /// they survive an app restart. Ignored when [controller] is passed.
  final SmartConnectivityQueueStore? queueStore;

  /// Runs once before each queue replay, for example to refresh an expired
  /// session. Return `false` to pause. Ignored when [controller] is passed.
  final SmartConnectivityBeforeFlush? beforeFlush;

  /// Runs when a handler throws [SmartConnectivityAuthException].
  /// Ignored when [controller] is passed.
  final VoidCallback? onAuthExpired;

  /// Runs when an action is dropped after too many failures.
  /// Ignored when [controller] is passed.
  final SmartConnectivityActionDropped? onActionDropped;

  /// The rest of the app.
  final Widget child;

  /// Convenience builder for [MaterialApp.builder].
  static TransitionBuilder materialBuilder({
    SmartConnectivityConfig config = const SmartConnectivityConfig(),
    SmartConnectivityController? controller,
    SmartConnectivityWidgetBuilder? offlineBannerBuilder,
    SmartConnectivityDialogBuilder? offlineDialogBuilder,
    SmartConnectivityWidgetBuilder? offlineToastBuilder,
    SmartConnectivityWidgetBuilder? onlineToastBuilder,
    VoidCallback? onDialogAction,
    SmartConnectivityQueueStore? queueStore,
    SmartConnectivityBeforeFlush? beforeFlush,
    VoidCallback? onAuthExpired,
    SmartConnectivityActionDropped? onActionDropped,
  }) {
    return (context, child) {
      return SmartConnectivityHost(
        config: config,
        controller: controller,
        offlineBannerBuilder: offlineBannerBuilder,
        offlineDialogBuilder: offlineDialogBuilder,
        offlineToastBuilder: offlineToastBuilder,
        onlineToastBuilder: onlineToastBuilder,
        onDialogAction: onDialogAction,
        queueStore: queueStore,
        beforeFlush: beforeFlush,
        onAuthExpired: onAuthExpired,
        onActionDropped: onActionDropped,
        child: child ?? const SizedBox.shrink(),
      );
    };
  }

  @override
  State<SmartConnectivityHost> createState() => _SmartConnectivityHostState();
}

class _SmartConnectivityHostState extends State<SmartConnectivityHost> {
  late SmartConnectivityController _controller;
  late final bool _ownsController;
  final GlobalKey<OverlayState> _overlayKey = GlobalKey<OverlayState>();
  OverlayEntry? _dialogEntry;
  OverlayEntry? _toastEntry;
  OverlayEntry? _appEntry;
  bool _offlineNotified = false;
  bool _hadOffline = false;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        SmartConnectivityController(
          config: widget.config,
          queueStore: widget.queueStore,
          beforeFlush: widget.beforeFlush,
          onAuthExpired: widget.onAuthExpired,
          onActionDropped: widget.onActionDropped,
        );
    _controller.updateConfig(widget.config);
    _hadOffline = _controller.status != SmartConnectivityStatus.online;
    _controller.addListener(_onChange);
    _controller.start();
    _appEntry = OverlayEntry(builder: _buildAppLayer);
  }

  @override
  void didUpdateWidget(SmartConnectivityHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _controller.updateConfig(widget.config);
    }
    _appEntry?.markNeedsBuild();
  }

  void _onChange() {
    if (!mounted) return;
    final offline = _controller.status != SmartConnectivityStatus.online;
    _appEntry?.markNeedsBuild();

    if (offline) {
      _hadOffline = true;
      _syncOfflineUi();
      return;
    }

    // Back online: close every offline surface, then toast from the top.
    final shouldCelebrate = _hadOffline;
    _hadOffline = false;
    _offlineNotified = false;
    _removeDialog();
    _removeToast();
    if (shouldCelebrate && widget.config.showOnlineToast) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_controller.status != SmartConnectivityStatus.online) return;
        _showOnlineToast();
      });
    }
  }

  void _syncOfflineUi() {
    if (widget.config.showDialog && !_offlineNotified && _dialogEntry == null) {
      _offlineNotified = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _dialogEntry != null) return;
        if (_controller.status == SmartConnectivityStatus.online) return;
        _insertDialog();
      });
    }

    if (widget.config.showOfflineToast && _toastEntry == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _toastEntry != null) return;
        if (_controller.status == SmartConnectivityStatus.online) return;
        _showOfflineToast();
      });
    }
  }

  void _insertDialog() {
    final overlay = _overlayKey.currentState;
    if (overlay == null) return;

    final builder = widget.offlineDialogBuilder;
    _dialogEntry = OverlayEntry(
      builder: (overlayContext) {
        return ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            if (_controller.status == SmartConnectivityStatus.online) {
              return const SizedBox.shrink();
            }
            final dialog =
                builder?.call(
                  context,
                  _controller,
                  widget.config,
                  _removeDialog,
                  widget.onDialogAction,
                ) ??
                SmartConnectivityDialog(
                  controller: _controller,
                  config: widget.config,
                  onDismiss: _removeDialog,
                  onAction: widget.onDialogAction,
                );
            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: widget.config.barrierDismissible
                        ? _removeDialog
                        : null,
                    child: const ColoredBox(color: Color(0x80000000)),
                  ),
                ),
                Center(child: dialog),
              ],
            );
          },
        );
      },
    );
    overlay.insert(_dialogEntry!);
  }

  void _showOfflineToast() {
    final message = _controller.status == SmartConnectivityStatus.flaky
        ? widget.config.flakyMessage
        : widget.config.offlineMessage;
    _showToast(
      duration: widget.config.offlineToastDuration,
      builder: (context) {
        return widget.offlineToastBuilder?.call(
              context,
              _controller,
              widget.config,
            ) ??
            SmartConnectivityToast(
              message: message,
              backgroundColor: widget.config.offlineToastBackgroundColor,
              foregroundColor: widget.config.offlineToastForegroundColor,
            );
      },
    );
  }

  void _showOnlineToast() {
    _showToast(
      duration: widget.config.onlineToastDuration,
      builder: (context) {
        return widget.onlineToastBuilder?.call(
              context,
              _controller,
              widget.config,
            ) ??
            SmartConnectivityToast(
              message: widget.config.onlineMessage,
              backgroundColor: widget.config.onlineToastBackgroundColor,
              foregroundColor: widget.config.onlineToastForegroundColor,
            );
      },
    );
  }

  void _showToast({
    required Duration duration,
    required WidgetBuilder builder,
  }) {
    final overlay = _overlayKey.currentState;
    if (overlay == null) return;
    _removeToast();
    _toastEntry = OverlayEntry(
      builder: (context) {
        return IgnorePointer(
          child: AnimatedSlide(
            offset: Offset.zero,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: builder(context),
          ),
        );
      },
    );
    overlay.insert(_toastEntry!);
    _toastTimer?.cancel();
    _toastTimer = Timer(duration, _removeToast);
  }

  void _removeDialog() {
    _dialogEntry?.remove();
    _dialogEntry = null;
  }

  void _removeToast() {
    _toastTimer?.cancel();
    _toastTimer = null;
    _toastEntry?.remove();
    _toastEntry = null;
  }

  Widget _buildAppLayer(BuildContext context) {
    final showBanner =
        widget.config.showBanner &&
        _controller.status != SmartConnectivityStatus.online;

    Widget? banner;
    if (showBanner) {
      banner =
          widget.offlineBannerBuilder?.call(
            context,
            _controller,
            widget.config,
          ) ??
          SmartConnectivityBanner(
            controller: _controller,
            config: widget.config,
          );
    }

    return SmartConnectivityScope(
      controller: _controller,
      config: widget.config,
      child: Column(
        children: [
          ?banner,
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _removeDialog();
    _removeToast();
    _appEntry?.remove();
    _appEntry = null;
    _controller.removeListener(_onChange);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Overlay(key: _overlayKey, initialEntries: [?_appEntry]);
  }
}
