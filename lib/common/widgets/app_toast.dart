import 'dart:async';
import 'package:flutter/material.dart';

enum ToastType { success, error, info, warning }

class AppToast {
  static OverlayEntry? _currentToast;
  static Timer? _timer;

  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;

    _removeCurrentToast();

    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    Color bg;
    Color fg = Colors.white;
    IconData icon;

    switch (type) {
      case ToastType.success:
        bg = const Color(0xFF16A34A);
        icon = Icons.check_circle_rounded;
        break;
      case ToastType.error:
        bg = const Color(0xFFDC2626);
        icon = Icons.error_rounded;
        break;
      case ToastType.warning:
        bg = const Color(0xFFF59E0B);
        icon = Icons.warning_rounded;
        break;
      case ToastType.info:
      default:
        bg = const Color(0xFF2563EB);
        icon = Icons.info_rounded;
        break;
    }

    _currentToast = OverlayEntry(
      builder: (context) => Positioned(
        top: mediaQuery.padding.top + 12,
        left: 16,
        right: 16,
        child: _TopToast(
          message: trimmed,
          backgroundColor: bg,
          foregroundColor: fg,
          icon: icon,
        ),
      ),
    );

    overlay.insert(_currentToast!);

    _timer = Timer(duration, () {
      _removeCurrentToast();
    });
  }

  static void success(BuildContext context, String message) {
    show(context, message, type: ToastType.success);
  }

  static void error(BuildContext context, String message) {
    show(context, message, type: ToastType.error);
  }

  static void info(BuildContext context, String message) {
    show(context, message, type: ToastType.info);
  }

  static void warning(BuildContext context, String message) {
    show(context, message, type: ToastType.warning);
  }

  static void _removeCurrentToast() {
    _timer?.cancel();
    _timer = null;
    _currentToast?.remove();
    _currentToast = null;
  }
}

class _TopToast extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;

  const _TopToast({
    required this.message,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
  });

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(widget.icon, color: widget.foregroundColor, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: textTheme.bodyMedium?.copyWith(
                        color: widget.foregroundColor,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
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