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
import 'package:url_launcher/url_launcher.dart';

import 'package:build4front/core/exceptions/exception_mapper.dart';
import 'package:build4front/core/network/globals.dart' as net;
import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';

import '../bloc/item_details_bloc.dart';

import 'package:build4front/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:build4front/features/cart/presentation/bloc/cart_event.dart';
import 'package:build4front/features/auth/presentation/login/bloc/auth_bloc.dart';
import 'package:build4front/common/widgets/app_toast.dart';
import 'package:build4front/features/catalog/cubit/money.dart';

class ItemDetailsPage extends StatefulWidget {
  final int itemId;
  const ItemDetailsPage({super.key, required this.itemId});

  @override
  State<ItemDetailsPage> createState() => _ItemDetailsPageState();
}

class _ItemDetailsPageState extends State<ItemDetailsPage> {
  bool _downloadAccessLoading = false;
  bool _downloadAccessLoaded = false;
  bool _canDownload = false;
  String? _downloadAccessMessage;
  int? _downloadCheckedItemId;

  int _galleryIndex = 0;
  late final PageController _galleryController;

  @override
  void initState() {
    super.initState();
    _galleryController = PageController();
  }

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  String? _stockStatusLabel(AppLocalizations l10n, int? stock) {
    if (stock == null) return null;
    if (stock <= 0) return l10n.outOfStock;
    if (stock <= 10) return l10n.home_stock_left_label(stock);
    return null;
  }

  String _msg(AppLocalizations l10n, Object error, {String? fallback}) {
    final mapped = ExceptionMapper.toMessage(error).trim();
    if (mapped.isNotEmpty && mapped != 'Something went wrong.') {
      return mapped;
    }
    return fallback ?? 'Something went wrong. Please try again.';
  }

  Future<void> _loadDownloadAccess(int productId) async {
    if (_downloadCheckedItemId == productId &&
        (_downloadAccessLoaded || _downloadAccessLoading)) {
      return;
    }

    final token = net.readAuthToken().trim();
    if (token.isEmpty) return;

    setState(() {
      _downloadAccessLoading = true;
      _downloadCheckedItemId = productId;
    });

    try {
      final api = ItemsApiService();
      final res = await api.getDownloadAccess(productId, token: token);

      if (!mounted) return;
      setState(() {
        _canDownload = res['canDownload'] == true;
        _downloadAccessMessage = res['message']?.toString();
        _downloadAccessLoaded = true;
        _downloadAccessLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _canDownload = false;
        _downloadAccessLoaded = true;
        _downloadAccessLoading = false;
      });
    }
  }

  Future<void> _openExternalLink(BuildContext context, String rawUrl) async {
    final l10n = AppLocalizations.of(context)!;
    final url = rawUrl.trim();

    if (url.isEmpty) {
      AppToast.error(context, 'Missing external URL');
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      AppToast.error(context, 'Invalid external URL');
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;

    if (!ok) {
      AppToast.error(context, 'Could not open link');
    }
  }

  Future<void> _startProtectedDownload(
    BuildContext context,
    int productId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final token = net.readAuthToken().trim();

    if (token.isEmpty) {
      AppToast.error(context, l10n.cart_login_required_message);
      return;
    }

    try {
      final api = ItemsApiService();
      final res = await api.getDownload(productId, token: token);
      final url = (res['downloadUrl'] ?? '').toString().trim();

      if (url.isEmpty) {
        AppToast.error(context, 'Missing download URL');
        return;
      }

      final uri = Uri.tryParse(url);
      if (uri == null) {
        AppToast.error(context, 'Invalid download URL');
        return;
      }

      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;

      if (!ok) {
        AppToast.error(context, 'Could not start download');
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        _msg(l10n, e, fallback: 'Failed to start download. Please try again.'),
      );
    }
  }

  Future<void> _openFullscreenGallery({
    required BuildContext context,
    required List<String> images,
    required int initialIndex,
  }) async {
    if (images.isEmpty) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullscreenGalleryViewer(
          imageUrls: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeState = context.watch<ThemeCubit>().state;
    final spacing = themeState.tokens.spacing;
    final card = themeState.tokens.card;

    final api = ItemsApiService();
    final repo = ItemsRepositoryImpl(api: api);
    final usecase = GetItemDetails(repo);

    final token = net.readAuthToken();

    return BlocProvider(
      create: (_) => ItemDetailsBloc(getItemDetails: usecase)
        ..add(ItemDetailsStarted(widget.itemId, token: token)),
      child: BlocConsumer<ItemDetailsBloc, ItemDetailsState>(
        listener: (context, state) {
          final d = state.details;
          if (d == null) return;

          final auth = context.read<AuthBloc>().state;
          if (!auth.isLoggedIn) return;

          if (d.downloadable) {
            _loadDownloadAccess(d.id);
          }
        },
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

          final galleryImages = d.galleryImageUrls
              .map((e) => net.resolveUrl(e))
              .whereType<String>()
              .where((e) => e.trim().isNotEmpty)
              .toList();

          final primaryImage =
              galleryImages.isNotEmpty ? galleryImages.first : null;

          if (_galleryIndex >= galleryImages.length && galleryImages.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() => _galleryIndex = 0);
            });
          }

          final curPrice = d.displayPrice;
          final oldPrice = d.oldPriceIfDiscounted;

          final bool isUpcoming = d.isUpcoming;
          final bool isExternal = d.isExternalProduct;
          final bool hasExternalUrl = d.hasExternalUrl;
          final bool isDownloadable = d.downloadable;
          final bool canDownloadNow = isDownloadable && _canDownload;

          final int? stock = d.stock;
          final bool isStockTracked = stock != null;
          final bool outOfStock = !isUpcoming && isStockTracked && stock <= 0;
          final bool lowStock =
              !isUpcoming && isStockTracked && stock > 0 && stock <= 10;

          final String? stockStatus = _stockStatusLabel(l10n, stock);

          String? tag;
          if (d.isSaleActiveNow &&
              oldPrice != null &&
              curPrice != null &&
              oldPrice > 0) {
            final pct = ((1 - (curPrice / oldPrice)) * 100).round();
            if (pct > 0) tag = '-$pct%';
          }
          tag ??= d.isSaleActiveNow ? l10n.common_sale_tag : null;

          final bool ctaDisabled = _downloadAccessLoading && isDownloadable
              ? true
              : isExternal
                  ? !hasExternalUrl
                  : canDownloadNow
                      ? false
                      : isUpcoming || outOfStock;

          final String ctaText = isExternal
              ? (((d.buttonText ?? '').trim().isNotEmpty)
                    ? d.buttonText!.trim()
                    : 'Open')
              : canDownloadNow
                  ? 'Download'
                  : isUpcoming
                      ? l10n.home_coming_soon_button
                      : outOfStock
                          ? l10n.outOfStock
                          : l10n.cart_add_button;

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
                ClipRRect(
                  borderRadius: BorderRadius.circular(card.radius),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: galleryImages.isEmpty
                        ? Container(
                            color: c.primary.withOpacity(0.08),
                            child: Icon(
                              Icons.image_outlined,
                              size: 44,
                              color: c.primary,
                            ),
                          )
                        : Stack(
                            children: [
                              PageView.builder(
                                controller: _galleryController,
                                itemCount: galleryImages.length,
                                onPageChanged: (index) {
                                  if (!mounted) return;
                                  setState(() => _galleryIndex = index);
                                },
                                itemBuilder: (context, index) {
                                  return GestureDetector(
                                    onTap: () => _openFullscreenGallery(
                                      context: context,
                                      images: galleryImages,
                                      initialIndex: index,
                                    ),
                                    child: Image.network(
                                      galleryImages[index],
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
                                  );
                                },
                              ),
                              if (galleryImages.length > 1)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: spacing.md,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      galleryImages.length,
                                      (index) {
                                        final selected =
                                            index == _galleryIndex;
                                        return AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 180,
                                          ),
                                          margin: EdgeInsets.symmetric(
                                            horizontal: spacing.xs / 2,
                                          ),
                                          width: selected ? 18 : 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: selected
                                                ? c.primary
                                                : Colors.white.withOpacity(0.75),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              Positioned(
                                top: spacing.md,
                                right: spacing.md,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: spacing.sm,
                                    vertical: spacing.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.45),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.zoom_out_map,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: spacing.xs),
                                      Text(
                                        'Tap to zoom',
                                        style: t.labelSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                SizedBox(height: spacing.lg),
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
                if (isExternal) ...[
                  SizedBox(height: spacing.sm),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.md,
                      vertical: spacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: c.primaryContainer.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: c.primary.withOpacity(0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.open_in_new_rounded,
                          color: c.primary,
                          size: 18,
                        ),
                        SizedBox(width: spacing.sm),
                        Expanded(
                          child: Text(
                            'External product',
                            style: t.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: c.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (isDownloadable && !canDownloadNow) ...[
                  SizedBox(height: spacing.sm),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.md,
                      vertical: spacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: c.secondaryContainer.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: c.secondary.withOpacity(0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.download_rounded,
                          color: c.secondary,
                          size: 18,
                        ),
                        SizedBox(width: spacing.sm),
                        Expanded(
                          child: Text(
                            (_downloadAccessMessage ?? '').trim().isNotEmpty
                                ? _downloadAccessMessage!
                                : 'Available after purchase',
                            style: t.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: c.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (canDownloadNow) ...[
                  SizedBox(height: spacing.sm),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.md,
                      vertical: spacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: c.secondaryContainer.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: c.secondary.withOpacity(0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.file_download_outlined,
                          color: c.secondary,
                          size: 18,
                        ),
                        SizedBox(width: spacing.sm),
                        Expanded(
                          child: Text(
                            'Download ready',
                            style: t.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: c.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (isUpcoming) ...[
                  SizedBox(height: spacing.sm),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.md,
                      vertical: spacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: c.primaryContainer.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: c.primary.withOpacity(0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          color: c.primary,
                          size: 18,
                        ),
                        SizedBox(width: spacing.sm),
                        Expanded(
                          child: Text(
                            l10n.home_coming_soon_button,
                            style: t.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: c.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                        Icon(
                          Icons.warning_amber_rounded,
                          color: c.error,
                          size: 18,
                        ),
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
                                    imageUrl: primaryImage,
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
                            style: t.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: spacing.lg),
                Divider(color: c.outline.withOpacity(0.2)),
                SizedBox(height: spacing.md),
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
                _infoRow(
                  context,
                  label: l10n.common_sku_label,
                  value: d.sku ?? '-',
                ),
                if (!isUpcoming && stockStatus != null)
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
                if (isExternal)
                  _infoRow(
                    context,
                    label: 'Product type',
                    value: 'External product',
                  ),
                if (isDownloadable)
                  _infoRow(
                    context,
                    label: 'Download',
                    value: canDownloadNow
                        ? 'Download ready'
                        : 'Available after purchase',
                  ),
                SizedBox(height: spacing.lg),
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: ctaDisabled
                        ? null
                        : () async {
                            if (isExternal) {
                              await _openExternalLink(
                                context,
                                d.externalUrl ?? '',
                              );
                              return;
                            }

                            if (canDownloadNow) {
                              await _startProtectedDownload(context, d.id);
                              return;
                            }

                            final auth = context.read<AuthBloc>().state;

                            if (!auth.isLoggedIn) {
                              AppToast.error(
                                context,
                                l10n.cart_login_required_message,
                              );
                              return;
                            }

                            if (isUpcoming) {
                              AppToast.error(
                                context,
                                l10n.home_coming_soon_button,
                              );
                              return;
                            }

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

                            AppToast.success(
                              context,
                              l10n.cart_item_added_snackbar,
                            );
                          },
                    child: _downloadAccessLoading && isDownloadable
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(ctaText),
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
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: t.bodyMedium?.copyWith(
                color: c.onSurface.withOpacity(0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullscreenGalleryViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullscreenGalleryViewer({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_FullscreenGalleryViewer> createState() =>
      _FullscreenGalleryViewerState();
}

class _FullscreenGalleryViewerState extends State<_FullscreenGalleryViewer> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.read<ThemeCubit>().state.tokens.spacing;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '${_currentIndex + 1} / ${widget.imageUrls.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              if (!mounted) return;
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 1,
                maxScale: 4.5,
                panEnabled: true,
                child: Center(
                  child: Image.network(
                    widget.imageUrls[index],
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white70,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (widget.imageUrls.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: spacing.xl,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.imageUrls.length, (index) {
                  final selected = index == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: EdgeInsets.symmetric(horizontal: spacing.xs / 2),
                    width: selected ? 18 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white
                          : Colors.white.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}