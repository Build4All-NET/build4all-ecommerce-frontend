import 'package:build4front/features/ai_feature/data/repositories/ai_chat_repository_impl.dart';
import 'package:build4front/features/ai_feature/data/services/ai_chat_remote_datasource.dart';
import 'package:build4front/features/ai_feature/domain/usecases/chat_item_usecase.dart';
import 'package:build4front/features/ai_feature/presentation/bloc/ai_chat_bloc.dart';
import 'package:build4front/features/ai_feature/presentation/screens/ai_item_chat_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/network/globals.dart' as net;
import 'package:build4front/core/theme/theme_cubit.dart';

class ItemCard extends StatelessWidget {
  final int? itemId;

  final String title;
  final String? subtitle;
  final String? imageUrl;

  final String? badgeLabel;
  final String? oldPriceLabel;
  final String? tagLabel;

  final String? metaLabel;
  final double? width;
  final VoidCallback? onTap;

  final String? ctaLabel;
  final VoidCallback? onCtaPressed;

  final BoxFit imageFit;

  const ItemCard({
    super.key,
    this.itemId,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.badgeLabel,
    this.oldPriceLabel,
    this.tagLabel,
    this.metaLabel,
    this.width,
    this.onTap,
    this.ctaLabel,
    this.onCtaPressed,
    this.imageFit = BoxFit.cover,
  });

  bool _hasText(String? value) => (value ?? '').trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final themeState = context.read<ThemeCubit>().state;
    final cardTokens = themeState.tokens.card;

    String? resolvedImageUrl;
    if (_hasText(imageUrl)) {
      resolvedImageUrl = net.resolveUrl(imageUrl!.trim());
    }

    final card = LayoutBuilder(
      builder: (context, constraints) {
        final isProductCard = imageFit == BoxFit.contain;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(cardTokens.radius),
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(cardTokens.radius),
                border: cardTokens.showBorder
                    ? Border.all(color: c.outline.withOpacity(0.12))
                    : null,
                boxShadow: cardTokens.showShadow
                    ? [
                        BoxShadow(
                          color: c.shadow.withOpacity(0.05),
                          blurRadius: cardTokens.elevation * 2.2,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: isProductCard
                  ? _ProductCardBody(
                      itemId: itemId,
                      title: title,
                      subtitle: subtitle,
                      resolvedImageUrl: resolvedImageUrl,
                      badgeLabel: badgeLabel,
                      oldPriceLabel: oldPriceLabel,
                      tagLabel: tagLabel,
                      ctaLabel: ctaLabel,
                      onCtaPressed: onCtaPressed,
                    )
                  : _GenericCardBody(
                      itemId: itemId,
                      title: title,
                      subtitle: subtitle,
                      resolvedImageUrl: resolvedImageUrl,
                      badgeLabel: badgeLabel,
                      oldPriceLabel: oldPriceLabel,
                      tagLabel: tagLabel,
                      metaLabel: metaLabel,
                      ctaLabel: ctaLabel,
                      onCtaPressed: onCtaPressed,
                      imageFit: imageFit,
                    ),
            ),
          ),
        );
      },
    );

    if (width != null) {
      return SizedBox(width: width, child: card);
    }

    return card;
  }
}

class _ProductCardBody extends StatelessWidget {
  final int? itemId;
  final String title;
  final String? subtitle;
  final String? resolvedImageUrl;
  final String? badgeLabel;
  final String? oldPriceLabel;
  final String? tagLabel;
  final String? ctaLabel;
  final VoidCallback? onCtaPressed;

  const _ProductCardBody({
    required this.itemId,
    required this.title,
    required this.subtitle,
    required this.resolvedImageUrl,
    required this.badgeLabel,
    required this.oldPriceLabel,
    required this.tagLabel,
    required this.ctaLabel,
    required this.onCtaPressed,
  });

  bool _hasText(String? value) => (value ?? '').trim().isNotEmpty;

  double _titleFont(double h, double w) {
    if (w < 150 || h < 105) return 12.3;
    if (w < 170 || h < 125) return 13.0;
    if (w < 190 || h < 145) return 13.8;
    return 15.0;
  }

  double _subtitleFont(double h, double w) {
    if (w < 150 || h < 105) return 10.0;
    if (w < 170 || h < 125) return 10.6;
    if (w < 190 || h < 145) return 11.0;
    return 11.6;
  }

  double _priceFont(double h, double w) {
    if (w < 150 || h < 105) return 11.8;
    if (w < 170 || h < 125) return 12.4;
    if (w < 190 || h < 145) return 13.0;
    return 14.0;
  }

  double _bubbleFont(double w) {
    if (w < 150) return 11.0;
    if (w < 170) return 11.6;
    if (w < 190) return 12.2;
    return 13.0;
  }

  EdgeInsets _bubblePadding(double w) {
    if (w < 150) {
      return const EdgeInsets.symmetric(horizontal: 10, vertical: 7);
    }
    if (w < 190) {
      return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    }
    return const EdgeInsets.symmetric(horizontal: 14, vertical: 9);
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final themeState = context.read<ThemeCubit>().state;
    final spacing = themeState.tokens.spacing;
    final cardTokens = themeState.tokens.card;

    final hasSubtitle = _hasText(subtitle);
    final hasPrice = _hasText(badgeLabel);
    final hasOldPrice = _hasText(oldPriceLabel);
    final hasCta = _hasText(ctaLabel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(cardTokens.radius),
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final imageW = constraints.maxWidth;
                final bubbleFont = _bubbleFont(imageW);
                final bubblePadding = _bubblePadding(imageW);

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: c.surfaceVariant.withOpacity(0.10),
                      child: resolvedImageUrl != null &&
                              resolvedImageUrl!.isNotEmpty
                          ? Image.network(
                              resolvedImageUrl!,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (_, __, ___) => _imagePlaceholder(),
                            )
                          : _imagePlaceholder(),
                    ),
                    if (_hasText(tagLabel))
                      Positioned(
                        top: spacing.xs,
                        left: spacing.xs,
                        child: _DiscountBadge(text: tagLabel!.trim()),
                      ),
                    if (hasPrice)
                      Positioned(
                        top: spacing.xs,
                        right: spacing.xs,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: imageW * 0.52,
                          ),
                          padding: bubblePadding,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badgeLabel!.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.labelLarge?.copyWith(
                              fontSize: bubbleFont,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final h = constraints.maxHeight;
                final w = constraints.maxWidth;

                final ultraCompact = h < 105;
                final compact = h < 132;

                final titleLines = ultraCompact ? 2 : 3;
                final subtitleLines = ultraCompact ? 1 : 2;
                final showSubtitleNow = hasSubtitle;
                final showOldPriceNow = hasOldPrice;
                final buttonHeight =
                    ultraCompact ? 34.0 : (compact ? 36.0 : 40.0);

                final titleFont = _titleFont(h, w);
                final subtitleFont = _subtitleFont(h, w);
                final priceFont = _priceFont(h, w);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: titleLines,
                      overflow: TextOverflow.ellipsis,
                      style: t.titleMedium?.copyWith(
                        fontSize: titleFont,
                        fontWeight: FontWeight.w800,
                        height: 1.12,
                      ),
                    ),
                    if (showSubtitleNow) ...[
                      SizedBox(height: compact ? 4 : 6),
                      Text(
                        subtitle!.trim(),
                        maxLines: subtitleLines,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall?.copyWith(
                          fontSize: subtitleFont,
                          color: c.onSurface.withOpacity(0.68),
                          height: 1.18,
                        ),
                      ),
                    ],
                    if (showOldPriceNow) ...[
                      SizedBox(height: compact ? 6 : 8),
                      Text(
                        oldPriceLabel!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodyMedium?.copyWith(
                          fontSize: priceFont - 0.8,
                          decoration: TextDecoration.lineThrough,
                          color: c.onSurface.withOpacity(0.45),
                          fontWeight: FontWeight.w500,
                          height: 1.1,
                        ),
                      ),
                    ],
                    const Spacer(),
                    // AI button for product cards — shown when AI is enabled
                    if (itemId != null && !ultraCompact)
                      ValueListenableBuilder<bool>(
                        valueListenable: net.aiEnabledNotifier,
                        builder: (_, enabled, __) {
                          if (!enabled) return const SizedBox.shrink();
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: hasCta ? 8.0 : 0,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              height: compact ? 34.0 : 36.0,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) {
                                      final remote = AiChatRemoteDataSource();
                                      final repo =
                                          AiChatRepositoryImpl(remote);
                                      final usecase = ChatItemUseCase(repo);
                                      return BlocProvider(
                                        create: (_) =>
                                            AiChatBloc(useCase: usecase),
                                        child: AiItemChatSheet(
                                          itemId: itemId!,
                                          title: title,
                                          imageUrl: resolvedImageUrl,
                                        ),
                                      );
                                    },
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  side: BorderSide(
                                    color: c.primary.withOpacity(0.35),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      cardTokens.radius / 1.4,
                                    ),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.auto_awesome,
                                  size: 16,
                                ),
                                label: Text(
                                  'Ask AI',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.labelMedium?.copyWith(
                                    fontSize: 12.2,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    if (hasCta)
                      SizedBox(
                        width: double.infinity,
                        height: buttonHeight,
                        child: ElevatedButton(
                          onPressed: onCtaPressed,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            backgroundColor: c.primary,
                            foregroundColor: c.onPrimary,
                            disabledBackgroundColor:
                                c.surfaceVariant.withOpacity(0.95),
                            disabledForegroundColor:
                                c.onSurface.withOpacity(0.45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                cardTokens.radius / 1.4,
                              ),
                            ),
                          ),
                          child: Text(
                            ctaLabel!.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.labelLarge?.copyWith(
                              fontSize: compact ? 12.6 : 13.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      alignment: Alignment.center,
      child: Image.asset(
        'assets/branding/product_placeholder.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class _GenericCardBody extends StatelessWidget {
  final int? itemId;
  final String title;
  final String? subtitle;
  final String? resolvedImageUrl;
  final String? badgeLabel;
  final String? oldPriceLabel;
  final String? tagLabel;
  final String? metaLabel;
  final String? ctaLabel;
  final VoidCallback? onCtaPressed;
  final BoxFit imageFit;

  const _GenericCardBody({
    required this.itemId,
    required this.title,
    required this.subtitle,
    required this.resolvedImageUrl,
    required this.badgeLabel,
    required this.oldPriceLabel,
    required this.tagLabel,
    required this.metaLabel,
    required this.ctaLabel,
    required this.onCtaPressed,
    required this.imageFit,
  });

  bool _hasText(String? value) => (value ?? '').trim().isNotEmpty;

  double _titleFont(double h, double w) {
    if (w < 150 || h < 120) return 12.4;
    if (w < 170 || h < 140) return 13.0;
    if (w < 200 || h < 165) return 13.6;
    return 14.4;
  }

  double _bodyFont(double h, double w) {
    if (w < 150 || h < 120) return 10.2;
    if (w < 170 || h < 140) return 10.8;
    if (w < 200 || h < 165) return 11.2;
    return 11.8;
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final themeState = context.read<ThemeCubit>().state;
    final spacing = themeState.tokens.spacing;
    final cardTokens = themeState.tokens.card;

    final hasSubtitle = _hasText(subtitle);
    final hasPrice = _hasText(badgeLabel);
    final hasOldPrice = _hasText(oldPriceLabel);
    final hasMeta = _hasText(metaLabel);
    final hasCta = _hasText(ctaLabel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(cardTokens.radius),
          ),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: c.surfaceVariant.withOpacity(0.14),
                  child: resolvedImageUrl != null &&
                          resolvedImageUrl!.isNotEmpty
                      ? Image.network(
                          resolvedImageUrl!,
                          fit: imageFit,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (_, __, ___) => _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                ),
                if (_hasText(tagLabel))
                  Positioned(
                    top: spacing.xs,
                    left: spacing.xs,
                    child: _DiscountBadge(text: tagLabel!.trim()),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final h = constraints.maxHeight;
                final w = constraints.maxWidth;

                final compact = h < 140;
                final showMetaNow = hasMeta && !compact;
                final showAiNow = itemId != null && h > 168;
                final buttonHeight = compact ? 36.0 : 40.0;

                final titleFont = _titleFont(h, w);
                final bodyFont = _bodyFont(h, w);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: compact ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: t.titleSmall?.copyWith(
                        fontSize: titleFont,
                        fontWeight: FontWeight.w800,
                        height: 1.14,
                      ),
                    ),
                    if (hasSubtitle) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!.trim(),
                        maxLines: compact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall?.copyWith(
                          fontSize: bodyFont,
                          color: c.onSurface.withOpacity(0.68),
                          height: 1.18,
                        ),
                      ),
                    ],
                    if (hasPrice) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 2,
                        children: [
                          Text(
                            badgeLabel!.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.titleSmall?.copyWith(
                              fontSize: titleFont,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          if (hasOldPrice)
                            Text(
                              oldPriceLabel!.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodySmall?.copyWith(
                                fontSize: bodyFont,
                                decoration: TextDecoration.lineThrough,
                                color: c.onSurface.withOpacity(0.48),
                                height: 1.1,
                              ),
                            ),
                        ],
                      ),
                    ],
                    if (showMetaNow) ...[
                      const SizedBox(height: 8),
                      Text(
                        metaLabel!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall?.copyWith(
                          fontSize: bodyFont,
                          color: c.onSurface.withOpacity(0.62),
                          height: 1.18,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (showAiNow)
                      ValueListenableBuilder<bool>(
                        valueListenable: net.aiEnabledNotifier,
                        builder: (_, enabled, __) {
                          if (!enabled) return const SizedBox.shrink();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: SizedBox(
                              width: double.infinity,
                              height: 36,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) {
                                      final remote = AiChatRemoteDataSource();
                                      final repo = AiChatRepositoryImpl(remote);
                                      final usecase = ChatItemUseCase(repo);

                                      return BlocProvider(
                                        create: (_) =>
                                            AiChatBloc(useCase: usecase),
                                        child: AiItemChatSheet(
                                          itemId: itemId!,
                                          title: title,
                                          imageUrl: resolvedImageUrl,
                                        ),
                                      );
                                    },
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  side: BorderSide(
                                    color: c.primary.withOpacity(0.35),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      cardTokens.radius / 1.4,
                                    ),
                                  ),
                                ),
                                icon: const Icon(Icons.auto_awesome, size: 16),
                                label: Text(
                                  'Ask AI',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.labelMedium?.copyWith(
                                    fontSize: 12.2,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    if (hasCta)
                      SizedBox(
                        width: double.infinity,
                        height: buttonHeight,
                        child: ElevatedButton(
                          onPressed: onCtaPressed,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            backgroundColor: c.primary,
                            foregroundColor: c.onPrimary,
                            disabledBackgroundColor:
                                c.surfaceVariant.withOpacity(0.95),
                            disabledForegroundColor:
                                c.onSurface.withOpacity(0.45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                cardTokens.radius / 1.4,
                              ),
                            ),
                          ),
                          child: Text(
                            ctaLabel!.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.labelLarge?.copyWith(
                              fontSize: compact ? 12.6 : 13.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      alignment: Alignment.center,
      child: Image.asset(
        'assets/branding/product_placeholder.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class _DiscountBadge extends StatelessWidget {
  final String text;

  const _DiscountBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: c.primary.withOpacity(0.93),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: t.labelSmall?.copyWith(
          color: c.onPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
