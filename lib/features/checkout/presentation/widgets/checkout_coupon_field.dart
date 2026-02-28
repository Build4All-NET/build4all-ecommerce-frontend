import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';

class CheckoutCouponField extends StatefulWidget {
  final String initial;

  /// null = checking / neutral
  /// true = valid
  /// false = invalid
  final bool? isValid;

  /// message shown under field
  final String? message;

  final ValueChanged<String> onChanged;

  const CheckoutCouponField({
    super.key,
    required this.initial,
    required this.onChanged,
    this.isValid,
    this.message,
  });

  @override
  State<CheckoutCouponField> createState() => _CheckoutCouponFieldState();
}

class _CheckoutCouponFieldState extends State<CheckoutCouponField> {
  late final TextEditingController _ctrl;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
  }

  @override
  void didUpdateWidget(covariant CheckoutCouponField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial != widget.initial && _ctrl.text != widget.initial) {
      _ctrl.text = widget.initial;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _emitDebounced(String v) {
    _debounce?.cancel();

    final value = v.trim();

    // ✅ avoid backend spam for tiny inputs
    // - empty: clear coupon immediately
    // - >= 4 chars: check it
    // - else: don’t call backend yet
    if (value.isEmpty) {
      widget.onChanged('');
      return;
    }
    if (value.length < 4) {
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 450), () {
      widget.onChanged(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final c = tokens.colors;
    final spacing = tokens.spacing;
    final t = tokens.typography;

    Color msgColor;
    if (widget.isValid == true) {
      msgColor = c.success;
    } else if (widget.isValid == false) {
      msgColor = c.danger;
    } else {
      msgColor = c.muted;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _ctrl,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: l10n.checkoutCouponHint,
            filled: true,
            fillColor: c.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(tokens.card.radius),
              borderSide: BorderSide(color: c.border.withOpacity(0.25)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(tokens.card.radius),
              borderSide: BorderSide(color: c.border.withOpacity(0.25)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(tokens.card.radius),
              borderSide: BorderSide(color: c.primary, width: 1.4),
            ),
          ),
          onChanged: _emitDebounced,
          onSubmitted: (v) => widget.onChanged(v.trim()),
        ),
        if ((widget.message ?? '').trim().isNotEmpty) ...[
          SizedBox(height: spacing.xs),
          Text(
            widget.message!.trim(),
            style: t.bodySmall.copyWith(color: msgColor),
          ),
        ],
      ],
    );
  }
}