import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OwnerAnnouncementEmptyState extends StatelessWidget {
  const OwnerAnnouncementEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final text = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border.withOpacity(.18)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: colors.primary.withOpacity(.10),
            child: Icon(
              Icons.campaign_outlined,
              color: colors.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.adminAnnouncementsEmptyTitle,
            textAlign: TextAlign.center,
            style: text.titleMedium?.copyWith(
              color: colors.label,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.adminAnnouncementsEmptyMessage,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(
              color: colors.body,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}