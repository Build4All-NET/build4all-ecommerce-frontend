import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';

import 'package:build4front/common/widgets/app_toast.dart';

import '../bloc/coupon_bloc.dart';
import '../bloc/coupon_event.dart';
import '../bloc/coupon_state.dart';
import 'coupon_form_sheet.dart';
import '../../domain/entities/coupon.dart';

class AdminCouponsScreen extends StatefulWidget {
  const AdminCouponsScreen({super.key});

  @override
  State<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends State<AdminCouponsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CouponBloc>().add(const CouponsStarted());
    });
  }

  String _fmt(DateTime? d) {
    if (d == null) return '—';
    final s = d.toIso8601String().replaceFirst('T', ' ');
    return s.length >= 16 ? s.substring(0, 16) : s;
  }

  String _statusLabel(BuildContext context, Coupon coupon) {
    final l10n = AppLocalizations.of(context)!;

    switch (coupon.status.toUpperCase()) {
      case 'INACTIVE':
        return l10n.coupons_inactive_badge;
      case 'SCHEDULED':
        return l10n.couponsStatusScheduled;
      case 'EXPIRED':
        return l10n.couponsStatusExpired;
      case 'USAGE_LIMIT_REACHED':
        return l10n.couponsStatusLimitReached;
      case 'ACTIVE':
      default:
        return l10n.coupons_active;
    }
  }

  Color _statusBg(ColorScheme c, Coupon coupon) {
    switch (coupon.status.toUpperCase()) {
      case 'INACTIVE':
        return c.error.withOpacity(0.10);
      case 'SCHEDULED':
        return c.primary.withOpacity(0.10);
      case 'EXPIRED':
        return c.error.withOpacity(0.10);
      case 'USAGE_LIMIT_REACHED':
        return Colors.orange.withOpacity(0.12);
      case 'ACTIVE':
      default:
        return Colors.green.withOpacity(0.12);
    }
  }

  Color _statusFg(ColorScheme c, Coupon coupon) {
    switch (coupon.status.toUpperCase()) {
      case 'INACTIVE':
        return c.error;
      case 'SCHEDULED':
        return c.primary;
      case 'EXPIRED':
        return c.error;
      case 'USAGE_LIMIT_REACHED':
        return Colors.orange.shade800;
      case 'ACTIVE':
      default:
        return Colors.green.shade700;
    }
  }

  String _usageText(Coupon coupon) {
    if (coupon.maxUses == null) {
      return '${coupon.usedCount} / ∞';
    }
    return '${coupon.usedCount} / ${coupon.maxUses}';
  }

  String _remainingText(BuildContext context, Coupon coupon) {
    if (coupon.remainingUses == null) {
      return AppLocalizations.of(context)!.couponsUsageUnlimited;
    }
    return coupon.remainingUses.toString();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final spacing = tokens.spacing;
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.coupons_title)),
      body: BlocConsumer<CouponBloc, CouponState>(
        listener: (context, state) {
          if (state.lastMessage != null) {
            String text = '';
            switch (state.lastMessage) {
              case 'coupon_saved':
                text = l10n.coupons_saved;
                break;
              case 'coupon_deleted':
                text = l10n.coupons_deleted;
                break;
            }
            if (text.isNotEmpty) {
              AppToast.info(context, text);
            }
          }

          if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
            AppToast.error(context, state.errorMessage!);
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.coupons.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.coupons.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(spacing.lg),
                child: Text(
                  l10n.coupons_empty,
                  style: t.bodyLarge?.copyWith(
                    color: c.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<CouponBloc>().add(const CouponsRefreshed());
            },
            child: Padding(
              padding: EdgeInsets.all(spacing.md),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: state.coupons.length,
                separatorBuilder: (_, __) => SizedBox(height: spacing.sm),
                itemBuilder: (context, index) {
                  final coupon = state.coupons[index];

                  final typeLabel = switch (coupon.discountType) {
                    CouponDiscountType.percent => l10n.coupons_type_percent,
                    CouponDiscountType.fixed => l10n.coupons_type_fixed,
                    CouponDiscountType.freeShipping =>
                      l10n.coupons_type_free_shipping,
                  };

                  final valueLabel = switch (coupon.discountType) {
                    CouponDiscountType.percent =>
                      '${coupon.discountValue.toStringAsFixed(0)} %',
                    CouponDiscountType.fixed =>
                      coupon.discountValue.toStringAsFixed(2),
                    CouponDiscountType.freeShipping => '—',
                  };

                  final validity = (coupon.startsAt == null && coupon.expiresAt == null)
                      ? l10n.couponsValidityAlwaysActive
                      : '${_fmt(coupon.startsAt)} → ${_fmt(coupon.expiresAt)}';

                  return Container(
                    padding: EdgeInsets.all(spacing.md),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: c.outline.withOpacity(0.12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                coupon.code,
                                style: t.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: spacing.sm,
                                vertical: spacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: _statusBg(c, coupon),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _statusLabel(context, coupon),
                                style: t.labelSmall?.copyWith(
                                  color: _statusFg(c, coupon),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            SizedBox(width: spacing.xs),
                            IconButton(
                              icon: const Icon(Icons.edit_rounded),
                              onPressed: () =>
                                  _openFormSheet(context, coupon: coupon),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(l10n.coupons_delete_title),
                                    content: Text(
                                      l10n.coupons_delete_confirm(coupon.code),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(false),
                                        child: Text(l10n.cancel),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(true),
                                        child: Text(l10n.delete),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  context.read<CouponBloc>().add(
                                        CouponDeleteRequested(
                                          couponId: coupon.id,
                                        ),
                                      );
                                }
                              },
                            ),
                          ],
                        ),

                        if (coupon.description != null &&
                            coupon.description!.isNotEmpty) ...[
                          SizedBox(height: spacing.xs),
                          Text(
                            coupon.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodySmall?.copyWith(
                              color: c.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],

                        SizedBox(height: spacing.sm),

                        Text(
                          '$typeLabel • $valueLabel',
                          style: t.bodySmall?.copyWith(
                            color: c.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        SizedBox(height: spacing.xs),

                        Text(
                          validity,
                          style: t.bodySmall?.copyWith(
                            color: c.onSurface.withOpacity(0.65),
                          ),
                        ),

                        SizedBox(height: spacing.md),

                        Wrap(
                          spacing: spacing.sm,
                          runSpacing: spacing.sm,
                          children: [
                            _InfoChip(
                              label: l10n.couponsChipUsed,
                              value: _usageText(coupon),
                            ),
                            _InfoChip(
                              label: l10n.adminRemaining,
                              value: _remainingText(context, coupon),
                            ),
                            _InfoChip(
                              label: l10n.couponsChipStarted,
                              value: coupon.started ? l10n.commonYes : l10n.commonNo,
                            ),
                            _InfoChip(
                              label: l10n.couponsChipExpired,
                              value: coupon.expired ? l10n.commonYes : l10n.commonNo,
                            ),
                            _InfoChip(
                              label: l10n.couponsChipValidNow,
                              value: coupon.currentlyValid ? l10n.commonYes : l10n.commonNo,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openFormSheet(context),
        label: Text(l10n.coupons_add),
        icon: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _openFormSheet(BuildContext context, {Coupon? coupon}) {
    final bloc = context.read<CouponBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return BlocProvider.value(
          value: bloc,
          child: CouponFormSheet(existing: coupon),
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final spacing = tokens.spacing;
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.sm,
        vertical: spacing.xs,
      ),
      decoration: BoxDecoration(
        color: c.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.outline.withOpacity(0.10)),
      ),
      child: RichText(
        text: TextSpan(
          style: t.bodySmall?.copyWith(color: c.onSurface),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}