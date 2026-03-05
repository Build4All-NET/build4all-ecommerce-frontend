import 'package:build4front/features/ai_feature/data/repositories/ai_chat_repository_impl.dart';
import 'package:build4front/features/ai_feature/data/services/ai_chat_remote_datasource.dart';
import 'package:build4front/features/ai_feature/domain/usecases/chat_item_usecase.dart';
import 'package:build4front/features/ai_feature/presentation/bloc/ai_chat_bloc.dart';
import 'package:build4front/features/ai_feature/presentation/screens/ai_item_chat_sheet.dart';
import 'package:build4front/features/ai_feature/presentation/widgets/ai_enabled_gate.dart';

import 'package:build4front/features/items/data/repositories/items_repository_impl.dart';
import 'package:build4front/features/items/data/services/items_api_service.dart';
import 'package:build4front/features/items/domain/usecases/get_item_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/network/globals.dart' as net;
import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';

import '../bloc/item_details_bloc.dart';

import 'package:build4front/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:build4front/features/cart/presentation/bloc/cart_event.dart';
import 'package:build4front/features/auth/presentation/login/bloc/auth_bloc.dart';
import 'package:build4front/common/widgets/app_toast.dart';

// ✅ dynamic currency formatter
import 'package:build4front/features/catalog/cubit/money.dart';

class ItemDetailsPage extends StatelessWidget {
  final int itemId;
  const ItemDetailsPage({super.key, required this.itemId});

  // ✅ Stock UX:
  // - stock <= 0  => Out of stock
  // - 1..10       => "Only X left"
  // - > 10        => null (hide, no numbers)
  // - null        => null (not tracked)
  String? _stockStatusLabel(AppLocalizations l10n, int? stock) {
    if (stock == null) return null;
    if (stock <= 0) return l10n.outOfStock;

    // ✅ requires l10n key: home_stock_left_label(count)
    if (stock <= 10) return l10n.home_stock_left_label(stock);

    // ✅ hide when plenty
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeState = context.watch<ThemeCubit>().state;
    final spacing = themeState.tokens.spacing;
    final card = themeState.tokens.card;

    // ✅ self-contained wiring (keep as-is)
    final api = ItemsApiService();
    final repo = ItemsRepositoryImpl(api: api);
    final usecase = GetItemDetails(repo);

    final token = net.readAuthToken();

    return BlocProvider(
      create: (_) => ItemDetailsBloc(getItemDetails: usecase)
        ..add(ItemDetailsStarted(itemId, token: token)),
      child: BlocBuilder<ItemDetailsBloc, ItemDetailsState>(
        builder: (context, state) {
          if (state.isLoading && state.details == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (state.error != null && state.details == null) {
            return Scaffold(
              appBar: AppBar(title: Text(l10n.home_view_details_button)),
              body: Padding(
                padding: EdgeInsets.all(spacing.lg),
                child: Text(
                  state.error!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            );
          }

          final d = state.details;
          if (d == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final c = Theme.of(context).colorScheme;
          final t = Theme.of(context).textTheme;

          final image = (d.imageUrl ?? '').trim().isNotEmpty
              ? net.resolveUrl(d.imageUrl!)
              : null;

          final curPrice = d.displayPrice;
          final oldPrice = d.oldPriceIfDiscounted;

          // ✅ STOCK GUARD (no raw numbers shown)
          final int? stock = d.stock;
          final bool isStockTracked = stock != null;
          final bool outOfStock = isStockTracked && stock! <= 0;
          final bool lowStock =
              isStockTracked && stock! > 0 && stock! <= 10;

          final String? stockStatus = _stockStatusLabel(l10n, stock);

          // sale tag
          String? tag;
          if (d.isSaleActiveNow &&
              oldPrice != null &&
              curPrice != null &&
              oldPrice > 0) {
            final pct = ((1 - (curPrice / oldPrice)) * 100).round();
            if (pct > 0) tag = '-$pct%';
          }
          tag ??= d.isSaleActiveNow ? l10n.common_sale_tag : null;

          return Scaffold(
            appBar: AppBar(title: Text(d.name)),
            body: ListView(
              padding: EdgeInsets.fromLTRB(
                spacing.lg,
                spacing.lg,
                spacing.lg,
                spacing.xl,
              ),
              children: [
                // IMAGE
                ClipRRect(
                  borderRadius: BorderRadius.circular(card.radius),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: image == null
                        ? Container(
                            color: c.primary.withOpacity(0.08),
                            child: Icon(
                              Icons.image_outlined,
                              size: 44,
                              color: c.primary,
                            ),
                          )
                        : Image.network(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: c.errorContainer.withOpacity(0.2),
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: c.error,
                                size: 44,
                              ),
                            ),
                          ),
                  ),
                ),

                SizedBox(height: spacing.lg),

                // TITLE + PRICE
                Text(
                  d.name,
                  style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: spacing.sm),

                Row(
                  children: [
                    if (curPrice != null)
                      Text(
                        money(context, curPrice.toDouble()),
                        style: t.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (oldPrice != null) ...[
                      SizedBox(width: spacing.sm),
                      Text(
                        money(context, oldPrice.toDouble()),
                        style: t.bodyMedium?.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: c.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],

                    // ✅ low stock pill near price (ONLY for 1..10)
                    if (lowStock && stockStatus != null) ...[
                      SizedBox(width: spacing.sm),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: spacing.sm,
                          vertical: spacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: c.tertiaryContainer.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: c.tertiary.withOpacity(0.25),
                          ),
                        ),
                        child: Text(
                          stockStatus,
                          style: t.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],

                    const Spacer(),

                    if (tag != null)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: spacing.sm,
                          vertical: spacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: c.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: c.primary.withOpacity(0.35),
                          ),
                        ),
                        child: Text(
                          tag,
                          style: t.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),

                // ✅ out-of-stock banner only when stock tracked and <= 0
                if (outOfStock) ...[
                  SizedBox(height: spacing.sm),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.md,
                      vertical: spacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: c.errorContainer.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.error.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: c.error, size: 18),
                        SizedBox(width: spacing.sm),
                        Expanded(
                          child: Text(
                            l10n.outOfStock,
                            style: t.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: c.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: spacing.md),

                // ✅ ASK AI BUTTON (Details)
                AiEnabledGate(
                  minRefreshInterval: const Duration(seconds: 10),
                  whenEnabled: (ctx) {
                    return Padding(
                      padding: EdgeInsets.only(top: spacing.xs),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showModalBottomSheet(
                              context: ctx,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) {
                                final remote = AiChatRemoteDataSource();
                                final repo = AiChatRepositoryImpl(remote);
                                final usecase = ChatItemUseCase(repo);

                                return BlocProvider(
                                  create: (_) => AiChatBloc(useCase: usecase),
                                  child: AiItemChatSheet(
                                    itemId: d.id,
                                    title: d.name,
                                    imageUrl: image,
                                  ),
                                );
                              },
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: c.primary.withOpacity(0.35)),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(card.radius / 1.5),
                            ),
                          ),
                          icon: const Icon(Icons.auto_awesome, size: 18),
                          label: Text(
                            l10n.ai_ask_button,
                            style:
                                t.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: spacing.lg),
                Divider(color: c.outline.withOpacity(0.2)),
                SizedBox(height: spacing.md),

                // DESCRIPTION
                Text(
                  l10n.common_description_title,
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: spacing.xs),
                Text(
                  (d.description ?? '').trim().isEmpty ? '-' : d.description!,
                  style: t.bodyMedium?.copyWith(
                    color: c.onSurface.withOpacity(0.8),
                  ),
                ),

                SizedBox(height: spacing.lg),

                // QUICK INFO
                _infoRow(context,
                    label: l10n.common_sku_label, value: d.sku ?? '-'),

                // ✅ STOCK row only when meaningful (OutOfStock or Only X left)
                if (stockStatus != null)
                  _infoRow(
                    context,
                    label: l10n.common_stock_label_plain,
                    value: stockStatus,
                  ),

                _infoRow(
                  context,
                  label: l10n.common_tax_label,
                  value: d.taxable
                      ? (d.taxClass ?? l10n.common_yes)
                      : l10n.common_no,
                ),

                SizedBox(height: spacing.lg),

                // ATTRIBUTES
                Text(
                  l10n.common_attributes_title,
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: spacing.sm),

                if (d.attributes.isEmpty)
                  Text(
                    '-',
                    style: t.bodyMedium?.copyWith(
                      color: c.onSurface.withOpacity(0.7),
                    ),
                  )
                else
                  Wrap(
                    spacing: spacing.sm,
                    runSpacing: spacing.sm,
                    children: d.attributes.map((a) {
                      return Chip(
                        label: Text('${a.code}: ${a.value}'),
                        backgroundColor: c.surface,
                        side: BorderSide(color: c.outline.withOpacity(0.25)),
                      );
                    }).toList(),
                  ),

                SizedBox(height: spacing.xl),

                // ✅ CTA (Add to cart) — disabled when out of stock
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: outOfStock
                        ? null
                        : () {
                            final auth = context.read<AuthBloc>().state;

                            if (!auth.isLoggedIn) {
                              AppToast.error(
                                context,
                                l10n.cart_login_required_message,
                                
                              );
                              return;
                            }

                            // ✅ extra safety
                            if (outOfStock) {
                              AppToast.error(
                                context,
                                l10n.outOfStock,
                                
                              );
                              return;
                            }

                            context.read<CartBloc>().add(
                                  CartAddItemRequested(
                                    itemId: d.id,
                                    quantity: 1,
                                  ),
                                );

                            AppToast.error(
                              context,
                              l10n.cart_item_added_snackbar,
                            );
                          },
                    child: Text(
                      outOfStock ? l10n.outOfStock : l10n.cart_add_button,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final spacing = context.read<ThemeCubit>().state.tokens.spacing;

    return Container(
      margin: EdgeInsets.only(bottom: spacing.sm),
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.outline.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          Text(
            value,
            style: t.bodyMedium?.copyWith(color: c.onSurface.withOpacity(0.75)),
          ),
        ],
      ),
    );
  }
}