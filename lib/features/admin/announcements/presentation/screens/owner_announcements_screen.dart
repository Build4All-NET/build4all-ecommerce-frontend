import 'package:build4front/common/widgets/app_toast.dart';
import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/features/admin/announcements/presentation/bloc/owner_announcement_bloc.dart';
import 'package:build4front/features/admin/announcements/presentation/bloc/owner_announcement_event.dart';
import 'package:build4front/features/admin/announcements/presentation/bloc/owner_announcement_state.dart';
import 'package:build4front/features/admin/announcements/presentation/widgets/owner_announcement_card.dart';
import 'package:build4front/features/admin/announcements/presentation/widgets/owner_announcement_empty_state.dart';
import 'package:build4front/features/admin/announcements/presentation/widgets/owner_announcement_form.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OwnerAnnouncementsScreen extends StatefulWidget {
  const OwnerAnnouncementsScreen({super.key});

  @override
  State<OwnerAnnouncementsScreen> createState() => _OwnerAnnouncementsScreenState();
}

class _OwnerAnnouncementsScreenState extends State<OwnerAnnouncementsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<OwnerAnnouncementBloc>().add(const LoadOwnerAnnouncements());
  }

  Future<void> _confirmDelete(int id) async {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.read<ThemeCubit>().state.tokens;
    final colors = tokens.colors;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text(l10n.adminAnnouncementsDeleteTitle),
          content: Text(l10n.adminAnnouncementsDeleteMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.adminAnnouncementsCancel),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text(l10n.adminAnnouncementsDelete),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      context.read<OwnerAnnouncementBloc>().add(
            DeleteOwnerAnnouncementRequested(
              announcementId: id,
            ),
          );
    }
  }

  void _handleStateMessages(
    BuildContext context,
    OwnerAnnouncementState state,
  ) {
    final l10n = AppLocalizations.of(context)!;

    if (state.error != null && state.error!.trim().isNotEmpty) {
      AppToast.error(context, state.error!);
      return;
    }

    if (state.successMessage == 'created') {
      AppToast.success(context, l10n.adminAnnouncementsCreatedSuccess);
      return;
    }

    if (state.successMessage == 'deleted') {
      AppToast.success(context, l10n.adminAnnouncementsDeletedSuccess);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final spacing = tokens.spacing;

    return BlocConsumer<OwnerAnnouncementBloc, OwnerAnnouncementState>(
      listenWhen: (previous, current) {
        return previous.error != current.error ||
            previous.successMessage != current.successMessage;
      },
      listener: _handleStateMessages,
      builder: (context, state) {
        return Scaffold(
          backgroundColor: colors.background,
          appBar: AppBar(
            backgroundColor: colors.surface,
            elevation: 0,
            title: Text(
              l10n.adminAnnouncementsTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.label,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            actions: [
              IconButton(
                onPressed: state.loading
                    ? null
                    : () {
                        context
                            .read<OwnerAnnouncementBloc>()
                            .add(const LoadOwnerAnnouncements());
                      },
                icon: Icon(Icons.refresh_rounded, color: colors.body),
                tooltip: l10n.refreshLabel,
              ),
            ],
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                context
                    .read<OwnerAnnouncementBloc>()
                    .add(const LoadOwnerAnnouncements());
              },
              child: ListView(
                padding: EdgeInsets.all(spacing.md),
                children: [
                OwnerAnnouncementForm(
  submitting: state.submitting,
  onSubmit: ({
    required title,
    required message,
    required announcementType,
    targetId,
    imagePath,
  }) {
    context.read<OwnerAnnouncementBloc>().add(
          CreateOwnerAnnouncementRequested(
            title: title,
            message: message,
            announcementType: announcementType,
            targetId: targetId,
            imagePath: imagePath,
          ),
        );
  },
),
                  SizedBox(height: spacing.lg),

                  if (state.loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (state.announcements.isEmpty)
                    const OwnerAnnouncementEmptyState()
                  else
                    ...state.announcements.map(
                      (item) => OwnerAnnouncementCard(
                        announcement: item,
                        deleting: state.deleting,
                        onDelete: () => _confirmDelete(item.id),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}