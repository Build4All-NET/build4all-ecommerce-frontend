import 'package:build4front/core/network/globals.dart' as net;
import 'package:build4front/core/theme/theme_cubit.dart';

import 'package:build4front/features/announcements/data/services/public_announcement_popup_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PublicAnnouncementPopupDialog extends StatefulWidget {
  final List<PublicAnnouncementPopupItem> announcements;
  final void Function(PublicAnnouncementPopupItem item)? onOpenTarget;

  const PublicAnnouncementPopupDialog({
    super.key,
    required this.announcements,
    this.onOpenTarget,
  });

  @override
  State<PublicAnnouncementPopupDialog> createState() =>
      _PublicAnnouncementPopupDialogState();
}

class _PublicAnnouncementPopupDialogState
    extends State<PublicAnnouncementPopupDialog> {
  final PageController _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _fullImageUrl(String? imageUrl) {
    final raw = (imageUrl ?? '').trim();

    if (raw.isEmpty || raw.toLowerCase() == 'null') {
      return '';
    }

    return net.resolveUrl(raw);
  }

  String _mainActionLabel(PublicAnnouncementPopupItem item) {
    final type = item.announcementType.trim().toUpperCase();

    if (type == 'PRODUCT' || type == 'DISCOUNT') {
      return 'Shop Now!';
    }

    if (item.targetId != null && item.targetId! > 0) {
      return 'View Details';
    }

    return 'Got It';
  }

  bool _hasTarget(PublicAnnouncementPopupItem item) {
    return item.targetId != null && item.targetId! > 0;
  }

  void _nextOrClose() {
    final total = widget.announcements.length;

    if (_page < total - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    Navigator.pop(context);
  }

  void _openTargetOrClose(PublicAnnouncementPopupItem item) {
    if (_hasTarget(item) && widget.onOpenTarget != null) {
      widget.onOpenTarget!(item);
      return;
    }

    _nextOrClose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.announcements;

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final current = items[_page];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 390,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 290,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: items.length,
                        onPageChanged: (value) {
                          setState(() {
                            _page = value;
                          });
                        },
                        itemBuilder: (context, index) {
                          final item = items[index];

                          return _PromoVisualPage(
                            item: item,
                            imageUrl: _fullImageUrl(item.imageUrl),
                          );
                        },
                      ),
                    ),

                    _BottomActions(
                      primaryLabel: _mainActionLabel(current),
                      secondaryLabel:
                          items.length > 1 && _page < items.length - 1
                              ? 'Next'
                              : 'Remind Me Later',
                      onPrimary: () => _openTargetOrClose(current),
                      onSecondary: _nextOrClose,
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              top: -14,
              right: -14,
              child: _CloseButton(
                onTap: () => Navigator.pop(context),
              ),
            ),

            if (items.length > 1)
              Positioned(
                bottom: 58,
                left: 0,
                right: 0,
                child: _DotsIndicator(
                  current: _page,
                  total: items.length,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PromoVisualPage extends StatelessWidget {
  final PublicAnnouncementPopupItem item;
  final String imageUrl;

  const _PromoVisualPage({
    required this.item,
    required this.imageUrl,
  });

  String _safeTitle() {
    final title = item.title.trim();

    if (title.isEmpty) {
      return 'Special Announcement';
    }

    return title;
  }

  String _safeMessage() {
    return item.message.trim();
  }

  bool _hasImage() {
    return imageUrl.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final spacing = context.read<ThemeCubit>().state.tokens.spacing;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (_hasImage())
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _FallbackPromoBackground();
            },
          )
        else
          _FallbackPromoBackground(),

        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.24),
                  Colors.black.withOpacity(0.08),
                  Colors.black.withOpacity(0.62),
                ],
              ),
            ),
          ),
        ),

        Positioned(
          left: spacing.md,
          right: spacing.md,
          top: spacing.md,
          child: Column(
            children: [
              Text(
                _safeTitle().toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  height: 1.08,
                ),
              ),
              if (_safeMessage().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _safeMessage(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.94),
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
              ],
            ],
          ),
        ),

        Positioned(
          left: spacing.md,
          bottom: spacing.md + 6,
          child: _MiniChip(
            label: _typeLabel(item.announcementType),
            color: c.primary,
          ),
        ),
      ],
    );
  }

  String _typeLabel(String type) {
    final clean = type.trim().toUpperCase();

    switch (clean) {
      case 'PRODUCT':
        return 'Product';
      case 'DISCOUNT':
        return 'Offer';
      case 'SERVICE':
        return 'Service';
      case 'MAINTENANCE':
        return 'Update';
      default:
        return 'Announcement';
    }
  }
}

class _BottomActions extends StatelessWidget {
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  const _BottomActions({
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return SizedBox(
      height: 56,
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: c.primary,
              child: InkWell(
                onTap: onPrimary,
                child: Center(
                  child: Text(
                    primaryLabel,
                    style: t.bodyMedium?.copyWith(
                      color: c.onPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Material(
              color: c.surfaceVariant.withOpacity(0.65),
              child: InkWell(
                onTap: onSecondary,
                child: Center(
                  child: Text(
                    secondaryLabel,
                    style: t.bodyMedium?.copyWith(
                      color: c.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CloseButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.54),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            Icons.close_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  final int current;
  final int total;

  const _DotsIndicator({
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final selected = index == current;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: selected ? 18 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.white.withOpacity(0.42),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
        ),
      ),
      child: Text(
        label,
        style: t.bodySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FallbackPromoBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            c.primary.withOpacity(0.92),
            c.primary.withOpacity(0.46),
            c.secondary.withOpacity(0.38),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.campaign_outlined,
          color: Colors.white.withOpacity(0.7),
          size: 74,
        ),
      ),
    );
  }
}