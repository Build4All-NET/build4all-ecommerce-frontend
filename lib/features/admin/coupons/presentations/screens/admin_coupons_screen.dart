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
            if (text.isNotEmpty) AppToast.show(context, text);
          }

          if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
            AppToast.show(context, state.errorMessage!, isError: true);
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
                      ? 'Always active'
                      : '${_fmt(coupon.startsAt)} → ${_fmt(coupon.expiresAt)}';

                  return Container(
                    padding: EdgeInsets.all(spacing.md),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: c.outline.withOpacity(0.12)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    coupon.code,
                                    style: t.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: spacing.sm),
                                  if (!coupon.active)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: spacing.xs,
                                        vertical: spacing.xs / 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: c.error.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        l10n.coupons_inactive_badge,
                                        style: t.labelSmall?.copyWith(
                                          color: c.error,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: spacing.xs),
                              if (coupon.description != null &&
                                  coupon.description!.isNotEmpty)
                                Text(
                                  coupon.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.bodySmall?.copyWith(
                                    color: c.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              SizedBox(height: spacing.xs),
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
                            ],
                          ),
                        ),
                        SizedBox(width: spacing.sm),
                        IconButton(
                          icon: const Icon(Icons.edit_rounded),
                          onPressed: () => _openFormSheet(context, coupon: coupon),
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
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: Text(l10n.cancel),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    child: Text(l10n.delete),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              context.read<CouponBloc>().add(
                                CouponDeleteRequested(couponId: coupon.id),
                              );
                            }
                          },
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