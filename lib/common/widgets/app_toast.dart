// lib/common/widgets/app_toast.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/theme_cubit.dart';
import '../../core/exceptions/exception_mapper.dart'; // ✅ ADD

class AppToast {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final themeState = context.read<ThemeCubit>().state;
    final colors = themeState.tokens.colors;

    final bg = isError ? colors.error : colors.primary;
    final fg = colors.onPrimary;

    // ✅ clean message even if someone passed ugly string
    final clean = ExceptionMapper.toMessage(message);

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(clean, style: TextStyle(color: fg)),
          backgroundColor: bg,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ✅ NEW: pass raw error object (DioException/AppException/anything)
  static void error(BuildContext context, Object error) {
    final clean = ExceptionMapper.toMessage(error);
    show(context, clean);
  }
}