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

  final String? badgeLabel; // current price
  final String? oldPriceLabel; // old price (strikethrough)
  final String? tagLabel; // discount tag

  final String? metaLabel; // stock/date/etc
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

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final themeState = context.read<ThemeCubit>().state;
    final cardTokens = themeState.tokens.card;
    final spacing = themeState.tokens.spacing;

    String? resolvedImageUrl;
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      resolvedImageUrl = net.resolveUrl(imageUrl!);
    }

    final hasCta = (ctaLabel ?? '').trim().isNotEmpty;
    final showOld = (oldPriceLabel ?? '').trim().isNotEmpty;
    final showMeta = (metaLabel ?? '').trim().isNotEmpty;
    final showSubtitle = (subtitle ?? '').trim().isNotEmpty;

    final bool ctaDisabled = hasCta && onCtaPressed == null;

    Widget card = LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final bool boundedH =
            constraints.hasBoundedHeight && constraints.maxHeight.isFinite;

        final bool compact = maxW <= 230;
        final bool veryCompact = maxW <= 210;

        final double contentPad = veryCompact
            ? cardTokens.padding * 0.72
            : (compact ? cardTokens.padding * 0.82 : cardTokens.padding);

        final double ctaH = veryCompact ? 34 : (compact ? 36 : 40);
        final double aiBtnH = veryCompact ? 34 : (compact ? 36 : 40);

        final double gapXS = veryCompact ? (spacing.xs * 0.6) : spacing.xs;
        final double gapSM = veryCompact
            ? (spacing.sm * 0.65)
            : (compact ? (spacing.sm * 0.85) : spacing.sm);

        final double imgH = boundedH
            ? (constraints.maxHeight * (veryCompact ? 0.32 : 0.34))
                .clamp(92.0, 135.0)
            : (veryCompact ? 92.0 : (compact ? 105.0 : 125.0));

        final ButtonStyle ctaStyle = ButtonStyle(
          padding: MaterialStateProperty.all(EdgeInsets.zero),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(cardTokens.radius / 1.5),
            ),
          ),
          elevation: MaterialStateProperty.all(0),
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled)) {
              return c.surfaceVariant.withOpacity(0.85);
            }
            return c.primary;
          }),
          foregroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled)) {
              return c.onSurface.withOpacity(0.45);
            }
            return c.onPrimary;
          }),
        );

        Widget contentColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: t.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            if (showSubtitle) ...[
              SizedBox(height: gapXS),
              Text(
                subtitle!.trim(),
                style: t.bodySmall?.copyWith(
                  color: c.onSurface.withOpacity(0.75),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            if (showOld) ...[
              SizedBox(height: gapXS),
              Text(
                oldPriceLabel!.trim(),
                style: t.bodySmall?.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: c.onSurface.withOpacity(0.55),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            if (showMeta) ...[
              SizedBox(height: gapSM),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.info_outline,
                      size: veryCompact ? 12 : 14,
                      color: c.onSurface.withOpacity(0.6),
                    ),
                  ),
                  SizedBox(width: gapXS),
                  Expanded(
                    child: Text(
                      metaLabel!.trim(),
                      style: t.bodySmall?.copyWith(
                        color: c.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            if (boundedH) const Spacer(),

            ValueListenableBuilder<bool>(
              valueListenable: net.aiEnabledNotifier,
              builder: (_, enabled, __) {
                final canShow = enabled && itemId != null;
                if (!canShow) return const SizedBox.shrink();

                return Padding(
                  padding: EdgeInsets.only(
                    top: boundedH ? 0 : gapSM,
                    bottom: hasCta ? gapXS : 0,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: aiBtnH,
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
                              create: (_) => AiChatBloc(useCase: usecase),
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
                        side: BorderSide(color: c.primary.withOpacity(0.35)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            cardTokens.radius / 1.5,
                          ),
                        ),
                      ),
                      icon: Icon(
                        Icons.auto_awesome,
                        size: veryCompact ? 16 : 18,
                      ),
                      label: Text(
                        "Ask AI",
                        style: t.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              },
            ),

            if (hasCta)
              SizedBox(
                width: double.infinity,
                height: ctaH,
                child: ElevatedButton(
                  onPressed: onCtaPressed,
                  style: ctaStyle,
                  child: Text(
                    ctaLabel!.trim(),
                    style: t.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: ctaDisabled
                          ? c.onSurface.withOpacity(0.45)
                          : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
              ),
          ],
        );

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
                    ? Border.all(color: c.outline.withOpacity(0.18))
                    : null,
                boxShadow: cardTokens.showShadow
                    ? [
                        BoxShadow(
                          color: c.shadow.withOpacity(0.04),
                          blurRadius: cardTokens.elevation * 2,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(cardTokens.radius),
                    ),
                    child: SizedBox(
                      height: imgH,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (resolvedImageUrl != null &&
                              resolvedImageUrl!.isNotEmpty)
                            Container(
                              color: c.surface,
                              child: Image.network(
                                resolvedImageUrl!,
                                fit: imageFit,
                                errorBuilder: (_, __, ___) {
                                  return Container(
                                    color: c.surface,
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      color: c.error,
                                      size: 30,
                                    ),
                                  );
                                },
                              ),
                            )
                          else
                            Container(
                              color: c.surface,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.image_outlined,
                                color: c.primary.withOpacity(0.9),
                                size: 30,
                              ),
                            ),
                          if ((tagLabel ?? '').trim().isNotEmpty)
                            Positioned(
                              top: spacing.xs,
                              left: spacing.xs,
                              child: _PillTag(text: tagLabel!.trim()),
                            ),
                          if ((badgeLabel ?? '').trim().isNotEmpty)
                            Positioned(
                              top: spacing.xs,
                              right: spacing.xs,
                              child: _PillTag(text: badgeLabel!.trim()),
                            ),
                        ],
                      ),
                    ),
                  ),

                  if (boundedH)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(contentPad),
                        child: contentColumn,
                      ),
                    )
                  else
                    Padding(
                      padding: EdgeInsets.all(contentPad),
                      child: contentColumn,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (width != null && width != double.infinity) {
      card = SizedBox(width: width, child: card);
    }

    return card;
  }
}

class _PillTag extends StatelessWidget {
  final String text;
  const _PillTag({required this.text});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.onSurface.withOpacity(0.08)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}