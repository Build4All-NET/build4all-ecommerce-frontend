// lib/common/widgets/app_toast.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/exceptions/exception_mapper.dart';
import '../../core/theme/theme_cubit.dart';

enum AppToastType { success, error, info }

class AppToast {
  static OverlayEntry? _currentToast;
  static Timer? _timer;

  static void _show(
    BuildContext context,
    Object message, {
    required AppToastType type,
  }) {
    final themeState = context.read<ThemeCubit>().state;
    final colors = themeState.tokens.colors;

    final clean = ExceptionMapper.toMessage(message).trim();
    if (clean.isEmpty) return;

    Color bg;
    Color fg;

    switch (type) {
      case AppToastType.error:
        bg = colors.error;
        fg = colors.onPrimary;
        break;
      case AppToastType.success:
        bg = colors.primary;
        fg = colors.onPrimary;
        break;
      case AppToastType.info:
        bg = colors.primary;
        fg = colors.onPrimary;
        break;
    }

    _removeCurrentToast();

    final overlay = Overlay.of(context, rootOverlay: true);
    if (overlay == null) return;

    final mediaQuery = MediaQuery.of(context);

    _currentToast = OverlayEntry(
      builder: (_) => Positioned(
        left: 16,
        right: 16,
        bottom: mediaQuery.padding.bottom + 16,
        child: _ToastOverlayCard(
          message: clean,
          backgroundColor: bg,
          foregroundColor: fg,
        ),
      ),
    );

    overlay.insert(_currentToast!);

    _timer = Timer(const Duration(seconds: 3), _removeCurrentToast);
  }

  static void success(BuildContext context, Object message) {
    _show(context, message, type: AppToastType.success);
  }

  static void error(BuildContext context, Object error) {
    _show(context, error, type: AppToastType.error);
  }

  static void info(BuildContext context, Object message) {
    _show(context, message, type: AppToastType.info);
  }

  static void _removeCurrentToast() {
    _timer?.cancel();
    _timer = null;
    _currentToast?.remove();
    _currentToast = null;
  }
}

class _ToastOverlayCard extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final Color foregroundColor;

  const _ToastOverlayCard({
    required this.message,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  State<_ToastOverlayCard> createState() => _ToastOverlayCardState();
}

class _ToastOverlayCardState extends State<_ToastOverlayCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
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
    return IgnorePointer(
      ignoring: true,
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  widget.message,
                  style: TextStyle(
                    color: widget.foregroundColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}