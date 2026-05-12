import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/features/admin/announcements/domain/entities/owner_announcement.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OwnerAnnouncementCard extends StatelessWidget {
  final OwnerAnnouncement announcement;
  final bool deleting;
  final VoidCallback onDelete;

  const OwnerAnnouncementCard({
    super.key,
    required this.announcement,
    required this.deleting,
    required this.onDelete,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return '—';

    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$year-$month-$day $hour:$minute';
  }

  IconData _iconForType(String type) {
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

  String _labelForType(AppLocalizations l10n, String type) {
    switch (type.trim().toUpperCase()) {
      case 'PRODUCT':
        return l10n.adminAnnouncementsTypeProduct;
      case 'DISCOUNT':
        return l10n.adminAnnouncementsTypeDiscount;
      case 'SERVICE':
        return l10n.adminAnnouncementsTypeService;
      case 'MAINTENANCE':
        return l10n.adminAnnouncementsTypeMaintenance;
      case 'GENERAL':
      default:
        return l10n.adminAnnouncementsTypeGeneral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final text = Theme.of(context).textTheme;

    final typeLabel = _labelForType(l10n, announcement.announcementType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border.withOpacity(.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(.10),
              shape: BoxShape.circle,
              border: Border.all(color: colors.primary.withOpacity(.16)),
            ),
            child: Icon(
              _iconForType(announcement.announcementType),
              color: colors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  announcement.title.trim().isEmpty
                      ? l10n.adminAnnouncementsTitle
                      : announcement.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyLarge?.copyWith(
                    color: colors.label,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  announcement.message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(
                    color: colors.body,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Chip(
                      label: typeLabel,
                      colors: colors,
                    ),
                    _Chip(
                      label: l10n.adminAnnouncementsSentToUsers(
                        announcement.sentCount,
                      ),
                      colors: colors,
                    ),
                    if (announcement.targetId != null)
                      _Chip(
                        label: '#${announcement.targetId}',
                        colors: colors,
                      ),
                    _Chip(
                      label: _formatDate(announcement.createdAt),
                      colors: colors,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          IconButton(
            onPressed: deleting ? null : onDelete,
            icon: deleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.delete_outline_rounded, color: colors.error),
            tooltip: l10n.adminAnnouncementsDelete,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final dynamic colors;

  const _Chip({
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border.withOpacity(.16)),
      ),
      child: Text(
        label,
        style: text.bodySmall?.copyWith(
          color: colors.body,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}