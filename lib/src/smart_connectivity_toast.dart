import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

/// Top strip used for offline and back-online messages.
///
/// Matches the layout of [SmartConnectivityBanner]: full-width bar under the
/// status bar only — never a full-screen overlay.
class SmartConnectivityToast extends StatelessWidget {
  /// Creates a top strip toast.
  const SmartConnectivityToast({
    super.key,
    required this.message,
    this.backgroundColor = const Color(0xFF111827),
    this.foregroundColor = const Color(0xFFF9FAFB),
    this.icon,
  });

  /// Toast text.
  final String message;

  /// Strip background.
  final Color backgroundColor;

  /// Text/icon color.
  final Color foregroundColor;

  /// Optional leading icon.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: backgroundColor,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemStatusBarContrastEnforced: false,
    );

    final strip = AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Material(
        color: backgroundColor,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: foregroundColor, size: 18),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    message,
                    textAlign:
                        icon == null ? TextAlign.center : TextAlign.start,
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Overlay entries expand to the full screen by default. Pin the strip to
    // the top so it never paints a full-screen color block.
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width,
        child: strip,
      ),
    );
  }
}
