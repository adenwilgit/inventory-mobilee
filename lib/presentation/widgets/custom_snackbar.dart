import 'package:flutter/material.dart';

enum SnackBarType { success, error, warning, info }

class CustomSnackBar {
  static void show({
    required BuildContext context,
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color backgroundColor;
    IconData iconData;
    Color iconColor;

    switch (type) {
      case SnackBarType.success:
        backgroundColor = Colors.green.shade600;
        iconData = Icons.check_circle_rounded;
        iconColor = Colors.white;
        break;
      case SnackBarType.error:
        backgroundColor = Colors.red.shade600;
        iconData = Icons.error_rounded;
        iconColor = Colors.white;
        break;
      case SnackBarType.warning:
        backgroundColor = Colors.orange.shade600;
        iconData = Icons.warning_rounded;
        iconColor = Colors.white;
        break;
      case SnackBarType.info:
        backgroundColor = isDark ? Colors.blue.shade700 : Colors.blue.shade600;
        iconData = Icons.info_rounded;
        iconColor = Colors.white;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(iconData, color: iconColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
        elevation: 8,
        duration: duration,
      ),
    );
  }
}
