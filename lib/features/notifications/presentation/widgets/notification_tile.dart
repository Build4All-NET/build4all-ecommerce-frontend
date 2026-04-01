// lib/features/notifications/presentation/widgets/notification_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:build4front/core/theme/theme_cubit.dart';

import '../../domain/entities/app_notification.dart';

class NotificationTile extends StatelessWidget {
  final AppNotification notif;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NotificationTile({
    super.key,
    required this.notif,
    required this.onTap,
    required this.onDelete,
  });

  String _prettyTime(DateTime dt) {
    final now = DateTime.now();
    final local = dt.toLocal();
    final diff = now.difference(local);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$d/$m/$y';
  }

  IconData _iconForType(String type) {
    switch (type.toUpperCase()) {
      case 'ORDER_CREATED':
        return Icons.shopping_bag_outlined;
      case 'ORDER_ACCEPTED':
        return Icons.task_alt_rounded;
      case 'ORDER_REJECTED':
      case 'ORDER_CANCELED_BY_OWNER':
      case 'ORDER_CANCELED_BY_USER':
        return Icons.cancel_outlined;
      case 'ORDER_STATUS_UPDATED':
        return Icons.local_shipping_outlined;
      case 'LOW_STOCK':
      case 'OUT_OF_STOCK':
        return Icons.inventory_2_outlined;
      default:
        return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final spacing = context.read<ThemeCubit>().state.tokens.spacing;

    final unread = !notif.isRead;
    final title = notif.title.trim().isEmpty ? 'Notification' : notif.title.trim();
    final body = notif.body.trim();

    return Container(
      margin: EdgeInsets.only(bottom: spacing.sm),
      decoration: BoxDecoration(
        color: unread ? c.primary.withOpacity(0.06) : c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.outline.withOpacity(0.12)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(spacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: unread ? c.primary : c.outline.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconForType(notif.notificationType),
                  color: unread ? c.onPrimary : c.onSurface,
                  size: 20,
                ),
              ),
              SizedBox(width: spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: t.bodyMedium?.copyWith(
                        fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    if (body.isNotEmpty) ...[
                      SizedBox(height: spacing.xs),
                      Text(
                        body,
                        style: t.bodySmall?.copyWith(
                          color: c.onSurface.withOpacity(0.78),
                        ),
                      ),
                    ],
                    SizedBox(height: spacing.xs),
                    Text(
                      _prettyTime(notif.createdAt),
                      style: t.bodySmall?.copyWith(
                        color: c.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: spacing.sm),
              Column(
                children: [
                  if (unread)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: c.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  SizedBox(height: spacing.sm),
                  InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: EdgeInsets.all(spacing.xs),
                      child: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: c.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}