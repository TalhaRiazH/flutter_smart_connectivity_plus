import 'package:flutter/material.dart';

/// Top toast used for offline and back-online messages.
class SmartConnectivityToast extends StatelessWidget {
  /// Creates a top toast.
  const SmartConnectivityToast({
    super.key,
    required this.message,
    this.backgroundColor = const Color(0xFF111827),
    this.foregroundColor = const Color(0xFFF9FAFB),
    this.icon,
  });

  /// Toast text.
  final String message;

  /// Toast background.
  final Color backgroundColor;

  /// Toast text/icon color.
  final Color foregroundColor;

  /// Optional leading icon.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: backgroundColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: foregroundColor, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      message,
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
      ),
    );
  }
}
