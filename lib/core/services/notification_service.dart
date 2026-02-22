import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class NotificationService {
  static void showError(BuildContext context, String message) {
    _showNotification(
      context,
      message: message,
      type: NotificationType.error,
      title: 'Oops!',
    );
  }

  static void showSuccess(BuildContext context, String message) {
    _showNotification(
      context,
      message: message,
      type: NotificationType.success,
      title: 'Success!',
    );
  }

  static void showInfo(BuildContext context, String message) {
    _showNotification(
      context,
      message: message,
      type: NotificationType.info,
      title: 'Info',
    );
  }

  static void _showNotification(
    BuildContext context, {
    required String message,
    required NotificationType type,
    required String title,
  }) {
    // Find the nearest overlay to display the notification
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _NotificationOverlay(
        message: message,
        type: type,
        title: title,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    overlay.insert(overlayEntry);
  }
}

enum NotificationType { success, error, info }

class _NotificationOverlay extends StatefulWidget {
  final String message;
  final NotificationType type;
  final String title;
  final VoidCallback onDismiss;

  const _NotificationOverlay({
    required this.message,
    required this.type,
    required this.title,
    required this.onDismiss,
  });

  @override
  State<_NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<_NotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();

    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _animationController.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getColors(widget.type);

    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 16,
      right: 16,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: colors['backgroundColor'],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors['borderColor']!, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: colors['shadowColor']!.withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors['iconBgColor'],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      colors['icon'],
                      color: colors['iconColor'],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.nunito(
                            color: colors['textColor'],
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.message,
                          style: GoogleFonts.nunito(
                            color: colors['textColor'],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      _animationController.reverse().then((_) {
                        widget.onDismiss();
                      });
                    },
                    child: Icon(
                      Icons.close,
                      color: colors['textColor'],
                      size: 18,
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

  Map<String, dynamic> _getColors(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return {
          'backgroundColor': const Color(0xFFE8F5E9),
          'borderColor': const Color(0xFFC8E6C9),
          'iconBgColor': const Color(0xFFC8E6C9),
          'icon': Icons.check_circle_outline,
          'iconColor': const Color(0xFF2E7D32),
          'textColor': const Color(0xFF2E7D32),
          'shadowColor': const Color(0xFF2E7D32),
        };
      case NotificationType.error:
        return {
          'backgroundColor': const Color(0xFFFFEAEA),
          'borderColor': const Color(0xFFFFC0C0),
          'iconBgColor': const Color(0xFFFFDADA),
          'icon': Icons.error_outline,
          'iconColor': const Color(0xFFD32F2F),
          'textColor': const Color(0xFFD32F2F),
          'shadowColor': const Color(0xFFD32F2F),
        };
      case NotificationType.info:
        return {
          'backgroundColor': const Color(0xFFE3F2FD),
          'borderColor': const Color(0xFFBBDEFB),
          'iconBgColor': const Color(0xFFBBDEFB),
          'icon': Icons.info_outline,
          'iconColor': const Color(0xFF1565C0),
          'textColor': const Color(0xFF1565C0),
          'shadowColor': const Color(0xFF1565C0),
        };
    }
  }
}
