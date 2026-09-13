import 'package:build4front/common/support/whatsapp_launcher.dart';
import 'package:build4front/common/widgets/app_toast.dart';
import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/owner_app_user.dart';

/// Opens the "how do I reach this person" sheet for [user].
///
/// Only ever shown for a user with at least one contact detail — the card
/// itself refuses to open the sheet otherwise, so every row in here is live.
Future<void> showOwnerUserContactSheet(
  BuildContext context,
  OwnerAppUser user,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _OwnerUserContactSheet(user: user),
  );
}

class _OwnerUserContactSheet extends StatelessWidget {
  final OwnerAppUser user;

  const _OwnerUserContactSheet({required this.user});

  Future<void> _launch(
    BuildContext context,
    Future<bool> Function() action,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);

    try {
      final opened = await action();
      if (!context.mounted) return;

      if (!opened) {
        AppToast.error(context, l10n.adminStatisticsContactFailed);
        return;
      }

      navigator.pop();
    } catch (_) {
      if (!context.mounted) return;
      AppToast.error(context, l10n.adminStatisticsContactFailed);
    }
  }

  Future<void> _copy(BuildContext context, String value) async {
    final l10n = AppLocalizations.of(context)!;

    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;

    AppToast.success(context, l10n.adminStatisticsCopied);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final spacing = tokens.spacing;
    final l10n = AppLocalizations.of(context)!;

    final phone = user.phoneNumber.trim();
    final email = user.email.trim();

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        spacing.lg,
        spacing.md,
        spacing.lg,
        spacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            SizedBox(height: spacing.md),
            Text(
              l10n.adminStatisticsContactSheetTitle(user.displayName),
              style: tokens.typography.titleMedium.copyWith(
                color: colors.label,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: spacing.md),

            if (phone.isNotEmpty) ...[
              _ContactRow(
                icon: Icons.chat_outlined,
                title: l10n.adminStatisticsContactWhatsApp,
                subtitle: phone,
                onTap: () => _launch(
                  context,
                  () => openWhatsApp(
                    rawNumber: phone,
                    message: l10n.adminStatisticsWhatsAppMessage(
                      user.displayName,
                    ),
                  ),
                ),
                onCopy: () => _copy(context, phone),
              ),
              SizedBox(height: spacing.sm),
              _ContactRow(
                icon: Icons.call_outlined,
                title: l10n.adminStatisticsContactCall,
                subtitle: phone,
                onTap: () => _launch(
                  context,
                  () => launchUrl(
                    Uri(scheme: 'tel', path: phone),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                onCopy: () => _copy(context, phone),
              ),
              SizedBox(height: spacing.sm),
            ],

            if (email.isNotEmpty)
              _ContactRow(
                icon: Icons.mail_outline_rounded,
                title: l10n.adminStatisticsContactEmail,
                subtitle: email,
                onTap: () => _launch(
                  context,
                  () => launchUrl(
                    Uri(scheme: 'mailto', path: email),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                onCopy: () => _copy(context, email),
              ),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onCopy;

  const _ContactRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final spacing = tokens.spacing;
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.card.radius),
        child: Container(
          padding: EdgeInsets.all(spacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(tokens.card.radius),
            border: Border.all(color: colors.border.withOpacity(0.22)),
          ),
          child: Row(
            children: [
              Icon(icon, color: colors.primary, size: 20),
              SizedBox(width: spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: tokens.typography.bodyMedium.copyWith(
                        color: colors.label,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tokens.typography.bodySmall.copyWith(
                        color: colors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onCopy,
                tooltip: l10n.adminStatisticsCopy,
                icon: Icon(
                  Icons.copy_rounded,
                  size: 18,
                  color: colors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
