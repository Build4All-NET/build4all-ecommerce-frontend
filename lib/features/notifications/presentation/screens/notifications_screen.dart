// lib/features/notifications/presentation/screens/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';

import 'package:build4front/common/widgets/app_toast.dart';
import '../bloc/notifications_bloc.dart';
import '../bloc/notifications_event.dart';
import '../bloc/notifications_state.dart';
import '../widgets/notification_tile.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

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
                      border: Border.all(color: c.primary.withOpacity(0.25)),
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
              return const Center(child: CircularProgressIndicator());
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

                  if ((state.items).isEmpty) {
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
                      constraints: BoxConstraints(maxWidth: contentMaxWidth),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          spacing.lg,
                          spacing.lg,
                          spacing.lg,
                          spacing.xl,
                        ),
                        itemCount:
                            state.items.length +
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
                              context.read<NotificationsBloc>().add(
                                NotificationReadRequested(notif.id),
                              );
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
