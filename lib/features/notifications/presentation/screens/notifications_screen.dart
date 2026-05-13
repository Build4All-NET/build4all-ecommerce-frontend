// lib/features/notifications/presentation/screens/notifications_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';

import 'package:build4front/common/widgets/app_toast.dart';
import 'package:build4front/features/itemsDetails/presentation/screens/item_details_page.dart';

import '../bloc/notifications_bloc.dart';
import '../bloc/notifications_event.dart';
import '../bloc/notifications_state.dart';
import '../widgets/notification_tile.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Map<String, dynamic> _payloadMap(dynamic notif) {
    try {
      final raw = (notif.payloadJson ?? '').toString().trim();

      if (raw.isEmpty || raw.toLowerCase() == 'null') {
        return <String, dynamic>{};
      }

      final decoded = jsonDecode(raw);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  bool _isAnnouncement(dynamic notif) {
    final type = (notif.notificationType ?? '')
        .toString()
        .trim()
        .toUpperCase();

    final payload = _payloadMap(notif);
    final event = (payload['event'] ?? '').toString().trim().toUpperCase();

    return type == 'ANNOUNCEMENT' ||
        type == 'OWNER_ANNOUNCEMENT' ||
        type == 'USER_ANNOUNCEMENT' ||
        type.contains('ANNOUNCEMENT') ||
        event == 'ANNOUNCEMENT';
  }

  int? _targetIdFromNotification(dynamic notif) {
    final payload = _payloadMap(notif);

    final value = payload['targetId'] ??
        payload['target_id'] ??
        payload['itemId'] ??
        payload['item_id'] ??
        payload['productId'] ??
        payload['product_id'];

    if (value == null) {
      return null;
    }

    if (value is int) {
      return value > 0 ? value : null;
    }

    if (value is num) {
      final parsed = value.toInt();
      return parsed > 0 ? parsed : null;
    }

    final parsed = int.tryParse(value.toString());

    if (parsed == null || parsed <= 0) {
      return null;
    }

    return parsed;
  }

  String _announcementType(dynamic notif) {
    final payload = _payloadMap(notif);

    return (payload['announcementType'] ??
            payload['announcement_type'] ??
            payload['type'] ??
            '')
        .toString()
        .trim()
        .toUpperCase();
  }

  bool _shouldOpenItemDetails(dynamic notif) {
    if (!_isAnnouncement(notif)) {
      return false;
    }

    final targetId = _targetIdFromNotification(notif);

    if (targetId == null) {
      return false;
    }

    final type = _announcementType(notif);

    // PRODUCT and DISCOUNT are item/product related.
    // If type is empty but targetId exists, we still open details safely.
    return type.isEmpty ||
        type == 'PRODUCT' ||
        type == 'DISCOUNT' ||
        type == 'ITEM';
  }

  void _handleNotificationTap(BuildContext context, dynamic notif) {
    context.read<NotificationsBloc>().add(
          NotificationReadRequested(notif.id),
        );

    if (!_shouldOpenItemDetails(notif)) {
      return;
    }

    final targetId = _targetIdFromNotification(notif);

    if (targetId == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ItemDetailsPage(itemId: targetId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final spacing = context.watch<ThemeCubit>().state.tokens.spacing;

    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<NotificationsBloc, NotificationsState>(
          builder: (context, state) {
            final unread = state.unreadCount;

            return Row(
              children: [
                Text(l10n.notifications_title),
                if (unread > 0) ...[
                  SizedBox(width: spacing.sm),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.sm,
                      vertical: spacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: c.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: c.primary.withOpacity(0.25),
                      ),
                    ),
                    child: Text(
                      '$unread',
                      style: t.bodySmall?.copyWith(
                        color: c.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<NotificationsBloc, NotificationsState>(
          listenWhen: (p, n) => (n.lastActionMessage ?? '').trim().isNotEmpty,
          listener: (context, state) {
            if ((state.lastActionMessage ?? '').trim().isNotEmpty) {
              AppToast.error(context, state.lastActionMessage!);
            }
          },
          builder: (context, state) {
            if (state.isLoading && !state.hasLoaded) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<NotificationsBloc>().add(
                      const NotificationsRefreshRequested(),
                    );
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxW = constraints.maxWidth;
                  final contentMaxWidth = maxW > 900 ? 900.0 : maxW;

                  if (state.items.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: spacing.xl),
                        Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: spacing.lg,
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.inbox_rounded,
                                  size: 48,
                                  color: c.onSurface.withOpacity(0.35),
                                ),
                                SizedBox(height: spacing.md),
                                Text(
                                  l10n.notifications_empty_title,
                                  style: t.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: spacing.xs),
                                Text(
                                  l10n.notifications_empty_subtitle,
                                  style: t.bodySmall?.copyWith(
                                    color: c.onSurface.withOpacity(0.7),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if ((state.error ?? '').trim().isNotEmpty) ...[
                                  SizedBox(height: spacing.md),
                                  Text(
                                    state.error!,
                                    style: t.bodySmall?.copyWith(
                                      color: c.error,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                SizedBox(height: spacing.lg),
                                FilledButton(
                                  onPressed: () {
                                    context.read<NotificationsBloc>().add(
                                          const NotificationsStarted(),
                                        );
                                  },
                                  child: Text(l10n.notifications_retry),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: contentMaxWidth,
                      ),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          spacing.lg,
                          spacing.lg,
                          spacing.lg,
                          spacing.xl,
                        ),
                        itemCount: state.items.length +
                            ((state.error ?? '').trim().isNotEmpty ? 1 : 0),
                        itemBuilder: (context, index) {
                          if ((state.error ?? '').trim().isNotEmpty &&
                              index == 0) {
                            return Container(
                              margin: EdgeInsets.only(bottom: spacing.md),
                              padding: EdgeInsets.all(spacing.md),
                              decoration: BoxDecoration(
                                color: c.error.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: c.error.withOpacity(0.25),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: c.error,
                                  ),
                                  SizedBox(width: spacing.sm),
                                  Expanded(
                                    child: Text(
                                      state.error!,
                                      style: t.bodySmall?.copyWith(
                                        color: c.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final realIndex =
                              ((state.error ?? '').trim().isNotEmpty)
                                  ? index - 1
                                  : index;

                          final notif = state.items[realIndex];

                          return NotificationTile(
                            notif: notif,
                            onTap: () {
                              _handleNotificationTap(context, notif);
                            },
                            onDelete: () {
                              context.read<NotificationsBloc>().add(
                                    NotificationDeleteRequested(notif.id),
                                  );
                            },
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}