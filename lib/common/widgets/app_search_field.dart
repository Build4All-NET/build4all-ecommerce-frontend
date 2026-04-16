// lib/common/widgets/app_search_field.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';

class AppSearchField extends StatefulWidget {
  final String hintText;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Optional external controller.
  /// If provided, we will NOT create our own.
  final TextEditingController? controller;

  /// Optional initial value (used when no external controller provided).
  final String? initialValue;

  /// UX options
  final bool autofocus;
  final bool enabled;
  final bool showClearButton;
  final TextInputAction textInputAction;
  final FocusNode? focusNode;

  const AppSearchField({
    super.key,
    required this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.initialValue,
    this.autofocus = false,
    this.enabled = true,
    this.showClearButton = true,
    this.textInputAction = TextInputAction.search,
    this.focusNode,
  });

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  TextEditingController? _internalController;

  TextEditingController get _effectiveController {
    if (widget.controller != null) return widget.controller!;
    _internalController ??= TextEditingController(
      text: widget.initialValue ?? '',
    );
    return _internalController!;
  }

  @override
  void didUpdateWidget(covariant AppSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If we use an internal controller and initialValue changed (rare but possible),
    // update the text only when it makes sense.
    if (widget.controller == null &&
        oldWidget.initialValue != widget.initialValue &&
        _internalController != null) {
      final next = widget.initialValue ?? '';
      if (_internalController!.text != next) {
        _internalController!.text = next;
      }
    }
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  void _clearAndNotify() {
    final ctrl = _effectiveController;
    ctrl.clear();

    // keep cursor / focus feeling natural
    widget.onChanged?.call('');

    // keep focus if user is typing
    widget.focusNode?.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final c = theme.colorScheme;
    final t = theme.textTheme;

    final tokens = context.read<ThemeCubit>().state.tokens;
    final searchTokens = tokens.search;
    final spacing = tokens.spacing;

    final verticalPadding = searchTokens.dense ? spacing.xs : spacing.sm;

    final ctrl = _effectiveController;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: ctrl,
      builder: (_, value, __) {
        final hasText = value.text.trim().isNotEmpty;

        return TextField(
          controller: ctrl,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          enabled: widget.enabled,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          textInputAction: widget.textInputAction,
          style: t.bodyMedium,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.search_rounded),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),

            // ✅ Clear button
            suffixIcon: (widget.showClearButton && hasText && widget.enabled)
                ? IconButton(
                    tooltip: l10n.commonClear,
                    onPressed: _clearAndNotify,
                    icon: const Icon(Icons.close_rounded),
                  )
                : null,

            filled: true,
            fillColor: c.surface,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              vertical: verticalPadding,
              horizontal: spacing.md,
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(searchTokens.radius),
              borderSide: BorderSide(
                color: c.outline.withOpacity(0.2),
                width: searchTokens.borderWidth,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(searchTokens.radius),
              borderSide: BorderSide(
                color: c.outline.withOpacity(0.2),
                width: searchTokens.borderWidth,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(searchTokens.radius),
              borderSide: BorderSide(
                color: c.primary,
                width: searchTokens.borderWidth + 0.3,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(searchTokens.radius),
              borderSide: BorderSide(
                color: c.outline.withOpacity(0.12),
                width: searchTokens.borderWidth,
              ),
            ),
          ),
        );
      },
    );
  }
}
