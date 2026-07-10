import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../config/theme.dart';
import '../../main.dart';

enum SnackBarType { success, error, warning, info }

enum NotificationStyle { snackbar, toast }

class CustomSnackBar {
  static OverlayEntry? _overlayEntry;

  static void show({
    required BuildContext? context,
    required String message,
    SnackBarType type = SnackBarType.info,
    NotificationStyle style = NotificationStyle.snackbar,
    Duration duration = const Duration(seconds: 5),
  }) {
    if (style == NotificationStyle.toast) {
      _showToast(message, type, duration);
    } else if (context != null) {
      _showSnackBar(context, message, type, duration);
    }
  }

  static void _showSnackBar(
    BuildContext context,
    String message,
    SnackBarType type,
    Duration duration,
  ) {
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

  static void _showToast(
    String message,
    SnackBarType type,
    Duration duration,
  ) {
    _hideToast();

    // Pastikan navigatorKey dan overlay tersedia
    if (navigatorKey.currentState == null ||
        navigatorKey.currentState!.overlay == null) {
      debugPrint(
          '❌ Tidak bisa menampilkan toast: navigatorKey atau overlay tidak tersedia');
      return;
    }

    final overlay = navigatorKey.currentState!.overlay!;
    final context = navigatorKey.currentContext!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color backgroundColor;
    IconData iconData;
    Color iconColor;

    switch (type) {
      case SnackBarType.success:
        backgroundColor = isDark
            ? Colors.green.shade800.withValues(alpha: 0.9)
            : Colors.green.shade500.withValues(alpha: 0.95);
        iconData = Icons.check_circle_rounded;
        iconColor = Colors.white;
        break;
      case SnackBarType.error:
        backgroundColor = isDark
            ? Colors.red.shade800.withValues(alpha: 0.9)
            : Colors.red.shade500.withValues(alpha: 0.95);
        iconData = Icons.error_rounded;
        iconColor = Colors.white;
        break;
      case SnackBarType.warning:
        backgroundColor = isDark
            ? Colors.orange.shade800.withValues(alpha: 0.9)
            : Colors.orange.shade500.withValues(alpha: 0.95);
        iconData = Icons.warning_rounded;
        iconColor = Colors.white;
        break;
      case SnackBarType.info:
        backgroundColor = isDark
            ? TirtaTheme.primaryBlue.withValues(alpha: 0.95)
            : TirtaTheme.skyBlue.withValues(alpha: 0.95);
        iconData = Icons.info_rounded;
        iconColor = Colors.white;
        break;
    }

    _overlayEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: 0,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: _ToastWidget(
            message: message,
            backgroundColor: backgroundColor,
            iconData: iconData,
            iconColor: iconColor,
            duration: duration,
            onClose: () => _hideToast(),
          ),
        ),
      ),
    );

    SchedulerBinding.instance.addPostFrameCallback((_) {
      overlay.insert(_overlayEntry!);
    });

    Future.delayed(duration, () {
      _hideToast();
    });
  }

  static void _hideToast() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final IconData iconData;
  final Color iconColor;
  final Duration duration;
  final VoidCallback onClose;

  const _ToastWidget({
    required this.message,
    required this.backgroundColor,
    required this.iconData,
    required this.iconColor,
    required this.duration,
    required this.onClose,
  });

  @override
  State<_ToastWidget> createState() => __ToastWidgetState();
}

class __ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleClose() {
    _animationController.reverse().then((_) {
      widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: widget.backgroundColor.withValues(alpha: 0.25),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(widget.iconData, color: widget.iconColor, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _handleClose,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
