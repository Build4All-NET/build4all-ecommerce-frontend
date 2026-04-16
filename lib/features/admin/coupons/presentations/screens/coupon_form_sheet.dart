import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';

import 'package:build4front/common/widgets/app_text_field.dart';
import 'package:build4front/common/widgets/primary_button.dart';

import '../bloc/coupon_bloc.dart';
import '../bloc/coupon_state.dart';
import '../bloc/coupon_event.dart';
import '../../domain/entities/coupon.dart';

class CouponFormSheet extends StatefulWidget {
  final Coupon? existing;

  const CouponFormSheet({super.key, this.existing});

  @override
  State<CouponFormSheet> createState() => _CouponFormSheetState();
}

class _CouponFormSheetState extends State<CouponFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codeCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _valueCtrl;
  late TextEditingController _maxUsesCtrl;
  late TextEditingController _minOrderCtrl;
  late TextEditingController _maxDiscountCtrl;

  CouponDiscountType _type = CouponDiscountType.percent;
  bool _active = true;

  DateTime? _startsAt;
  DateTime? _expiresAt;
  String? _dateError;

  String? _codeError;
  String? _submitError;

  bool get _isPercent => _type == CouponDiscountType.percent;
  bool get _isFreeShipping => _type == CouponDiscountType.freeShipping;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;

    _codeCtrl = TextEditingController(text: c?.code ?? '');
    _descCtrl = TextEditingController(text: c?.description ?? '');
    _valueCtrl = TextEditingController(
      text: c != null ? c.discountValue.toString() : '',
    );
    _maxUsesCtrl = TextEditingController(text: c?.maxUses?.toString() ?? '');
    _minOrderCtrl = TextEditingController(
      text: c?.minOrderAmount?.toString() ?? '',
    );
    _maxDiscountCtrl = TextEditingController(
      text: c?.maxDiscountAmount?.toString() ?? '',
    );

    _type = c?.discountType ?? CouponDiscountType.percent;
    _active = c?.active ?? true;
    _startsAt = c?.startsAt;
    _expiresAt = c?.expiresAt;

    if (_type != CouponDiscountType.percent) {
      _maxDiscountCtrl.text = '';
    }

    if (_type == CouponDiscountType.freeShipping) {
      _valueCtrl.text = '';
    }

    _codeCtrl.addListener(_clearLocalErrorsOnEdit);

    _validateDates();
  }

  @override
  void dispose() {
    _codeCtrl.removeListener(_clearLocalErrorsOnEdit);
    _codeCtrl.dispose();
    _descCtrl.dispose();
    _valueCtrl.dispose();
    _maxUsesCtrl.dispose();
    _minOrderCtrl.dispose();
    _maxDiscountCtrl.dispose();
    super.dispose();
  }

  void _clearLocalErrorsOnEdit() {
    if (_codeError != null || _submitError != null) {
      setState(() {
        _codeError = null;
        _submitError = null;
      });
    }
  }

  bool _looksLikeDuplicateCouponError(String msg) {
    final s = msg.trim().toLowerCase();
    return (s.contains('coupon') &&
            (s.contains('already exists') ||
                s.contains('already exist') ||
                s.contains('duplicate') ||
                s.contains('unique'))) ||
        s.contains('duplicate key') ||
        s.contains('unique constraint');
  }

  bool _isDuplicateCodeLocally(String code) {
    final normalized = code.trim().toUpperCase();
    final currentId = widget.existing?.id;

    final coupons = context.read<CouponBloc>().state.coupons;

    return coupons.any(
      (c) => c.id != currentId && c.code.trim().toUpperCase() == normalized,
    );
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  Future<DateTime?> _pickDateTime(DateTime? initial) async {
    final now = DateTime.now();
    final base = initial ?? now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (pickedDate == null) return null;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (pickedTime == null) return null;

    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  bool _validateDates() {
    if (_startsAt != null &&
        _expiresAt != null &&
        _startsAt!.isAfter(_expiresAt!)) {
      _dateError = 'Valid From must be before Valid To';
      return false;
    }
    _dateError = null;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final spacing = tokens.spacing;
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;

    return BlocConsumer<CouponBloc, CouponState>(
      listenWhen: (prev, curr) =>
          prev.errorMessage != curr.errorMessage ||
          prev.lastMessage != curr.lastMessage ||
          prev.isSaving != curr.isSaving,
      listener: (context, state) {
        final err = (state.errorMessage ?? '').trim();

        if (err.isNotEmpty) {
          if (_looksLikeDuplicateCouponError(err)) {
            setState(() {
              _codeError = err;
              _submitError = null;
            });
            _formKey.currentState?.validate();
          } else {
            setState(() {
              _submitError = err;
            });
          }
          return;
        }

        if (!state.isSaving && state.lastMessage == 'coupon_saved' && mounted) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final isSaving = state.isSaving;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            spacing.lg,
            spacing.lg,
            spacing.lg,
            MediaQuery.of(context).viewInsets.bottom + spacing.lg,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.existing == null
                        ? l10n.coupons_add
                        : l10n.coupons_edit,
                    style: t.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: spacing.lg),

                  AppTextField(
                    label: l10n.coupons_code,
                    controller: _codeCtrl,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return l10n.coupons_code_required;
                      }
                      if (_codeError != null && _codeError!.trim().isNotEmpty) {
                        return _codeError;
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: spacing.md),

                  AppTextField(
                    label: l10n.coupons_description,
                    controller: _descCtrl,
                    maxLines: 2,
                  ),
                  SizedBox(height: spacing.md),

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<CouponDiscountType>(
                          value: _type,
                          decoration: InputDecoration(
                            labelText: l10n.coupons_type,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: CouponDiscountType.percent,
                              child: Text(l10n.coupons_type_percent),
                            ),
                            DropdownMenuItem(
                              value: CouponDiscountType.fixed,
                              child: Text(l10n.coupons_type_fixed),
                            ),
                            DropdownMenuItem(
                              value: CouponDiscountType.freeShipping,
                              child: Text(l10n.coupons_type_free_shipping),
                            ),
                          ],
                          onChanged: (val) {
                            if (val == null) return;

                            setState(() {
                              _type = val;

                              if (_type != CouponDiscountType.percent) {
                                _maxDiscountCtrl.text = '';
                              }

                              if (_type == CouponDiscountType.freeShipping) {
                                _valueCtrl.text = '';
                              }
                            });
                          },
                        ),
                      ),
                      SizedBox(width: spacing.md),
                      Expanded(
                        flex: 2,
                        child: AppTextField(
                          label: _type == CouponDiscountType.percent
                              ? l10n.coupons_value_percent
                              : l10n.coupons_value_amount,
                          controller: _valueCtrl,
                          enabled: !_isFreeShipping,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            if (_isFreeShipping) return null;

                            if (v == null || v.trim().isEmpty) {
                              return l10n.coupons_value_required;
                            }
                            final parsed = num.tryParse(v.trim());
                            if (parsed == null || parsed <= 0) {
                              return l10n.coupons_value_invalid;
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.md),

                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: l10n.coupons_max_uses,
                          controller: _maxUsesCtrl,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      SizedBox(width: spacing.md),
                      Expanded(
                        child: AppTextField(
                          label: l10n.coupons_min_order_amount,
                          controller: _minOrderCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.md),

                  AppTextField(
                    label: l10n.coupons_max_discount_amount,
                    controller: _maxDiscountCtrl,
                    enabled: _isPercent,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  SizedBox(height: spacing.md),

                  Text(
                    'Validity',
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: spacing.sm),

                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await _pickDateTime(_startsAt);
                            if (picked == null) return;
                            setState(() {
                              _startsAt = picked;
                              _validateDates();
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(spacing.md),
                            decoration: BoxDecoration(
                              color: c.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: c.outline.withOpacity(0.18),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.couponValidFrom, style: t.labelMedium),
                                SizedBox(height: spacing.xs),
                                Text(_fmt(_startsAt), style: t.bodyMedium),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: spacing.sm),
                      IconButton(
                        tooltip: l10n.commonClear,
                        onPressed: () => setState(() {
                          _startsAt = null;
                          _validateDates();
                        }),
                        icon: const Icon(Icons.clear),
                      ),
                    ],
                  ),

                  SizedBox(height: spacing.sm),

                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await _pickDateTime(_expiresAt);
                            if (picked == null) return;
                            setState(() {
                              _expiresAt = picked;
                              _validateDates();
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(spacing.md),
                            decoration: BoxDecoration(
                              color: c.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: c.outline.withOpacity(0.18),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.couponValidTo, style: t.labelMedium),
                                SizedBox(height: spacing.xs),
                                Text(_fmt(_expiresAt), style: t.bodyMedium),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: spacing.sm),
                      IconButton(
                        tooltip: l10n.commonClear,
                        onPressed: () => setState(() {
                          _expiresAt = null;
                          _validateDates();
                        }),
                        icon: const Icon(Icons.clear),
                      ),
                    ],
                  ),

                  if (_dateError != null) ...[
                    SizedBox(height: spacing.sm),
                    Text(
                      _dateError!,
                      style: t.bodySmall?.copyWith(color: c.error),
                    ),
                  ],

                  SizedBox(height: spacing.md),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.coupons_active, style: t.bodyMedium),
                      Switch(
                        value: _active,
                        onChanged: (v) => setState(() => _active = v),
                      ),
                    ],
                  ),

                  if (_submitError != null && _submitError!.trim().isNotEmpty) ...[
                    SizedBox(height: spacing.sm),
                    Text(
                      _submitError!,
                      style: t.bodySmall?.copyWith(color: c.error),
                    ),
                  ],

                  SizedBox(height: spacing.lg),

                  PrimaryButton(
                    label: l10n.common_save,
                    isLoading: isSaving,
                    onPressed: isSaving ? null : _onSubmit,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onSubmit() {
    setState(() {
      _codeError = null;
      _submitError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    if (!_validateDates()) {
      setState(() {});
      return;
    }

    final existing = widget.existing;
    final bloc = context.read<CouponBloc>();

    final normalizedCode = _codeCtrl.text.trim().toUpperCase();

    if (_isDuplicateCodeLocally(normalizedCode)) {
      setState(() {
        _codeError = 'Coupon code already exists.';
      });
      _formKey.currentState!.validate();
      return;
    }

    double? parseDouble(String? v) =>
        (v == null || v.trim().isEmpty) ? null : double.tryParse(v.trim());

    int? parseInt(String? v) =>
        (v == null || v.trim().isEmpty) ? null : int.tryParse(v.trim());

    final safeOwnerProjectId = existing?.ownerProjectId ?? 0;
    final maxDiscount = _isPercent ? parseDouble(_maxDiscountCtrl.text) : null;
    final discountValue =
        _isFreeShipping ? 0.0 : double.parse(_valueCtrl.text.trim());

    final coupon = Coupon(
      id: existing?.id ?? 0,
      ownerProjectId: safeOwnerProjectId,
      code: normalizedCode,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      discountType: _type,
      discountValue: discountValue,
      maxUses: parseInt(_maxUsesCtrl.text),
      usedCount: existing?.usedCount ?? 0,
      remainingUses: existing?.remainingUses,
      minOrderAmount: parseDouble(_minOrderCtrl.text),
      maxDiscountAmount: maxDiscount,
      startsAt: _startsAt,
      expiresAt: _expiresAt,
      active: _active,
      started: existing?.started ?? true,
      expired: existing?.expired ?? false,
      usageLimitReached: existing?.usageLimitReached ?? false,
      currentlyValid: existing?.currentlyValid ?? false,
      status: existing?.status ?? 'ACTIVE',
    );

    bloc.add(CouponSaveRequested(coupon: coupon));
  }
}