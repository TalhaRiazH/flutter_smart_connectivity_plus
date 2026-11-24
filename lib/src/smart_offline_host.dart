import 'dart:async';

import 'package:flutter/material.dart';

import 'smart_offline_banner.dart';
import 'smart_offline_config.dart';
import 'smart_offline_controller.dart';
import 'smart_offline_dialog.dart';
import 'smart_offline_scope.dart';
import 'smart_offline_status.dart';
import 'smart_offline_toast.dart';
import 'smart_offline_ui.dart';

/// App-level host that watches connectivity on every screen.
///
/// Put this once in [MaterialApp.builder]. When the network drops it can show
/// a banner, dialog, and/or top toast — including custom widgets. When the
/// network returns, offline UI closes and an optional "back online" toast
/// slides in from the top.
class SmartOfflineHost extends StatefulWidget {
  /// Creates an app-level offline host.
  const SmartOfflineHost({
    super.key,
    this.config = const SmartOfflineConfig(),
    this.controller,
    this.offlineBannerBuilder,
    this.offlineDialogBuilder,
    this.offlineToastBuilder,
    this.onlineToastBuilder,
    required this.child,
  });

  /// Defaults for banners, dialogs, toasts, and retries.
  final SmartOfflineConfig config;

  /// Optional controller for tests and demos. Owned by the host when null.
  final SmartOfflineController? controller;

  /// Custom UI shown when internet is gone (banner). When null, [SmartOfflineBanner] is used.
  final SmartOfflineWidgetBuilder? offlineBannerBuilder;

  /// Custom UI shown when internet is gone (dialog). When null, [SmartOfflineDialog] is used.
  final SmartOfflineWidgetBuilder? offlineDialogBuilder;

  /// Custom top toast while offline.
  final SmartOfflineWidgetBuilder? offlineToastBuilder;

  /// Custom top toast when back online.
  final SmartOfflineWidgetBuilder? onlineToastBuilder;

  /// The rest of the app.
  final Widget child;

  /// Convenience builder for [MaterialApp.builder].
  static TransitionBuilder materialBuilder({
    SmartOfflineConfig config = const SmartOfflineConfig(),
    SmartOfflineController? controller,
    SmartOfflineWidgetBuilder? offlineBannerBuilder,
    SmartOfflineWidgetBuilder? offlineDialogBuilder,
    SmartOfflineWidgetBuilder? offlineToastBuilder,
    SmartOfflineWidgetBuilder? onlineToastBuilder,
  }) {
    return (context, child) {
      return SmartOfflineHost(
        config: config,
        controller: controller,
        offlineBannerBuilder: offlineBannerBuilder,
        offlineDialogBuilder: offlineDialogBuilder,
        offlineToastBuilder: offlineToastBuilder,
        onlineToastBuilder: onlineToastBuilder,
        child: child ?? const SizedBox.shrink(),
      );
    };
  }

  @override
  State<SmartOfflineHost> createState() => _SmartOfflineHostState();
}

class _SmartOfflineHostState extends State<SmartOfflineHost> {
  late SmartOfflineController _controller;
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
        widget.controller ?? SmartOfflineController(config: widget.config);
    _controller.updateConfig(widget.config);
    _hadOffline = _controller.status != SmartOfflineStatus.online;
    _controller.addListener(_onChange);
    _controller.start();
    _appEntry = OverlayEntry(builder: _buildAppLayer);
  }

  @override
  void didUpdateWidget(SmartOfflineHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _controller.updateConfig(widget.config);
    }
    _appEntry?.markNeedsBuild();
  }

  void _onChange() {
    if (!mounted) return;
    final offline = _controller.status != SmartOfflineStatus.online;
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
        if (_controller.status != SmartOfflineStatus.online) return;
        _showOnlineToast();
      });
    }
  }

  void _syncOfflineUi() {
    if (widget.config.showDialog && !_offlineNotified && _dialogEntry == null) {
      _offlineNotified = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _dialogEntry != null) return;
        if (_controller.status == SmartOfflineStatus.online) return;
        _insertDialog();
      });
    }

    if (widget.config.showOfflineToast && _toastEntry == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _toastEntry != null) return;
        if (_controller.status == SmartOfflineStatus.online) return;
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
            if (_controller.status == SmartOfflineStatus.online) {
              return const SizedBox.shrink();
            }
            final dialog = builder?.call(
                  context,
                  _controller,
                  widget.config,
                ) ??
                SmartOfflineDialog(
                  controller: _controller,
                  config: widget.config,
                  onDismiss: _removeDialog,
                );
            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap:
                        widget.config.barrierDismissible ? _removeDialog : null,
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
    final message = _controller.status == SmartOfflineStatus.flaky
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
            SmartOfflineToast(
              message: message,
              backgroundColor: const Color(0xFF7F1D1D),
              icon: Icons.wifi_off_rounded,
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
            SmartOfflineToast(
              message: widget.config.onlineMessage,
              backgroundColor: const Color(0xFF065F46),
              icon: Icons.wifi_rounded,
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
    final showBanner = widget.config.showBanner &&
        _controller.status != SmartOfflineStatus.online;

    Widget? banner;
    if (showBanner) {
      banner = widget.offlineBannerBuilder?.call(
            context,
            _controller,
            widget.config,
          ) ??
          SmartOfflineBanner(
            controller: _controller,
            config: widget.config,
          );
    }

    return SmartOfflineScope(
      controller: _controller,
      config: widget.config,
      child: Column(
        children: [
          if (banner != null) banner,
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
    return Overlay(
      key: _overlayKey,
      initialEntries: [
        if (_appEntry != null) _appEntry!,
      ],
    );
  }
}
