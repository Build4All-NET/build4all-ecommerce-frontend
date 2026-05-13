import 'package:build4front/core/network/globals.dart' as net;
import 'package:build4front/core/theme/theme_cubit.dart';

import 'package:build4front/features/announcements/data/services/public_announcement_popup_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PublicAnnouncementPopupDialog extends StatefulWidget {
  final List<PublicAnnouncementPopupItem> announcements;

  /// Called when announcement has targetId and user taps View product/details.
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

  String _typeLabel(String type) {
    final clean = type.trim().toUpperCase();

    switch (clean) {
      case 'PRODUCT':
        return 'Product update';
      case 'DISCOUNT':
        return 'Special offer';
      case 'SERVICE':
        return 'Service update';
      case 'MAINTENANCE':
        return 'Maintenance';
      case 'GENERAL':
      default:
        return 'Announcement';
    }
  }

  IconData _typeIcon(String type) {
    switch (type.trim().toUpperCase()) {
      case 'PRODUCT':
        return Icons.shopping_bag_outlined;
      case 'DISCOUNT':
        return Icons.local_offer_outlined;
      case 'SERVICE':
        return Icons.miscellaneous_services_outlined;
      case 'MAINTENANCE':
        return Icons.build_outlined;
      case 'GENERAL':
      default:
        return Icons.campaign_outlined;
    }
  }

  void _goNext() {
    if (_page < widget.announcements.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    Navigator.pop(context);
  }

  void _goPrevious() {
    if (_page <= 0) return;

    _pageController.previousPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final spacing = context.read<ThemeCubit>().state.tokens.spacing;
    final items = widget.announcements;

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final current = items[_page];
    final total = items.length;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 440,
          maxHeight: 680,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: c.outline.withOpacity(0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TopBar(
                  title: _typeLabel(current.announcementType),
                  icon: _typeIcon(current.announcementType),
                  page: _page,
                  total: total,
                  onClose: () => Navigator.pop(context),
                ),

                Flexible(
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

                      return _AnnouncementPage(
                        item: item,
                        imageUrl: _fullImageUrl(item.imageUrl),
                        typeLabel: _typeLabel(item.announcementType),
                        typeIcon: _typeIcon(item.announcementType),
                        onOpenTarget: widget.onOpenTarget,
                      );
                    },
                  ),
                ),

                Padding(
                  padding: EdgeInsets.fromLTRB(
                    spacing.md,
                    spacing.sm,
                    spacing.md,
                    spacing.md,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (total > 1) ...[
                        _DotsIndicator(
                          current: _page,
                          total: total,
                        ),
                        SizedBox(height: spacing.md),
                      ],

                      Row(
                        children: [
                          if (total > 1)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _page <= 0 ? null : _goPrevious,
                                icon: const Icon(Icons.chevron_left_rounded),
                                label: const Text('Previous'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          if (total > 1) SizedBox(width: spacing.sm),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _goNext,
                              icon: Icon(
                                _page < total - 1
                                    ? Icons.chevron_right_rounded
                                    : Icons.check_rounded,
                              ),
                              label: Text(
                                _page < total - 1 ? 'Next' : 'Got it',
                              ),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final IconData icon;
  final int page;
  final int total;
  final VoidCallback onClose;

  const _TopBar({
    required this.title,
    required this.icon,
    required this.page,
    required this.total,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final spacing = context.read<ThemeCubit>().state.tokens.spacing;

    return Container(
      padding: EdgeInsets.fromLTRB(
        spacing.md,
        spacing.md,
        spacing.sm,
        spacing.sm,
      ),
      decoration: BoxDecoration(
        color: c.primary.withOpacity(0.055),
        border: Border(
          bottom: BorderSide(
            color: c.outline.withOpacity(0.08),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.primary.withOpacity(0.13),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: c.primary,
              size: 22,
            ),
          ),
          SizedBox(width: spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: c.onSurface,
                  ),
                ),
                if (total > 1)
                  Text(
                    '${page + 1} of $total',
                    style: t.bodySmall?.copyWith(
                      color: c.onSurface.withOpacity(0.62),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            style: IconButton.styleFrom(
              backgroundColor: c.surface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementPage extends StatelessWidget {
  final PublicAnnouncementPopupItem item;
  final String imageUrl;
  final String typeLabel;
  final IconData typeIcon;
  final void Function(PublicAnnouncementPopupItem item)? onOpenTarget;

  const _AnnouncementPage({
    required this.item,
    required this.imageUrl,
    required this.typeLabel,
    required this.typeIcon,
    this.onOpenTarget,
  });

  bool get _hasTarget {
    return item.targetId != null && item.targetId! > 0;
  }

  String get _targetButtonLabel {
    final type = item.announcementType.trim().toUpperCase();

    if (type == 'PRODUCT' || type == 'DISCOUNT') {
      return 'View product';
    }

    return 'View details';
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final spacing = context.read<ThemeCubit>().state.tokens.spacing;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        spacing.md,
        spacing.md,
        spacing.md,
        spacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty) ...[
            AspectRatio(
              aspectRatio: 16 / 10,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _ImageFallback(icon: typeIcon);
                      },
                    ),

                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.38),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: _TypeChip(
                        label: typeLabel,
                        icon: typeIcon,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: spacing.md),
          ] else ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(spacing.lg),
              decoration: BoxDecoration(
                color: c.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: c.primary.withOpacity(0.12),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    typeIcon,
                    size: 44,
                    color: c.primary,
                  ),
                  SizedBox(height: spacing.sm),
                  _TypeChip(
                    label: typeLabel,
                    icon: typeIcon,
                    dark: false,
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing.md),
          ],

          Text(
            item.title.trim().isEmpty ? 'Announcement' : item.title.trim(),
            style: t.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: c.onSurface,
              height: 1.15,
            ),
          ),

          SizedBox(height: spacing.sm),

          Text(
            item.message.trim(),
            style: t.bodyMedium?.copyWith(
              color: c.onSurface.withOpacity(0.78),
              height: 1.42,
              fontWeight: FontWeight.w500,
            ),
          ),

          if (_hasTarget) ...[
            SizedBox(height: spacing.lg),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenTarget == null
                    ? null
                    : () {
                        onOpenTarget!(item);
                      },
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(_targetButtonLabel),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 13,
                    horizontal: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(
                    color: c.primary.withOpacity(0.35),
                  ),
                  foregroundColor: c.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool dark;

  const _TypeChip({
    required this.label,
    required this.icon,
    this.dark = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final bg = dark ? Colors.black.withOpacity(0.52) : c.surface;
    final fg = dark ? Colors.white : c.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color:
              dark ? Colors.white.withOpacity(0.18) : c.primary.withOpacity(0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: t.bodySmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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
    final c = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final selected = index == current;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: selected ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: selected ? c.primary : c.outline.withOpacity(0.32),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final IconData icon;

  const _ImageFallback({
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.outline.withOpacity(0.10),
      ),
      child: Icon(
        icon,
        size: 42,
        color: c.onSurface.withOpacity(0.42),
      ),
    );
  }
}