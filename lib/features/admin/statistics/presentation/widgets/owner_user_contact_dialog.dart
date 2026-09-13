import 'package:build4front/common/support/whatsapp_launcher.dart';
import 'package:build4front/common/widgets/app_toast.dart';
import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/owner_app_user.dart';

enum _ContactMethod { email, whatsapp, call }

/// Small "how do I reach this person" popup for [user].
///
/// One tap per option and the phone's own app takes over — mail, WhatsApp or
/// the dialer. Only shown for a user who has at least one contact detail, so
/// every row in here does something.
Future<void> showOwnerUserContactDialog(
  BuildContext context,
  OwnerAppUser user,
) async {
  final l10n = AppLocalizations.of(context)!;

  // The dialog only reports the choice; launching happens against the calling
  // screen's context, which is still around once the popup has closed.
  final choice = await showDialog<_ContactMethod>(
    context: context,
    builder: (_) => _OwnerUserContactDialog(user: user),
  );

  if (choice == null || !context.mounted) return;

  try {
    final opened = await _launch(choice, user, l10n);
    if (!context.mounted || opened) return;

    AppToast.error(context, l10n.adminStatisticsContactFailed);
  } catch (_) {
    if (!context.mounted) return;
    AppToast.error(context, l10n.adminStatisticsContactFailed);
  }
}

Future<bool> _launch(
  _ContactMethod method,
  OwnerAppUser user,
  AppLocalizations l10n,
) {
  switch (method) {
    case _ContactMethod.email:
      return launchUrl(
        Uri(scheme: 'mailto', path: user.email.trim()),
        mode: LaunchMode.externalApplication,
      );
    case _ContactMethod.whatsapp:
      return openWhatsApp(
        rawNumber: user.phoneNumber.trim(),
        message: l10n.adminStatisticsWhatsAppMessage(user.displayName),
      );
    case _ContactMethod.call:
      return launchUrl(
        Uri(scheme: 'tel', path: user.phoneNumber.trim()),
        mode: LaunchMode.externalApplication,
      );
  }
}

class _OwnerUserContactDialog extends StatelessWidget {
  final OwnerAppUser user;

  const _OwnerUserContactDialog({required this.user});

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final spacing = tokens.spacing;
    final l10n = AppLocalizations.of(context)!;

    final phone = user.phoneNumber.trim();
    final email = user.email.trim();

    void choose(_ContactMethod method) =>
        Navigator.of(context).pop(method);

    return AlertDialog(
      backgroundColor: colors.surface,
      title: Text(
        l10n.adminStatisticsContactTitle(user.displayName),
        style: tokens.typography.titleMedium.copyWith(
          color: colors.label,
          fontWeight: FontWeight.w900,
        ),
      ),
      contentPadding: EdgeInsets.fromLTRB(0, spacing.sm, 0, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (email.isNotEmpty)
            _ContactOption(
              icon: Icons.mail_outline_rounded,
              label: l10n.adminStatisticsContactEmail,
              value: email,
              onTap: () => choose(_ContactMethod.email),
            ),
          if (phone.isNotEmpty) ...[
            _ContactOption(
              icon: Icons.chat_outlined,
              label: l10n.adminStatisticsContactWhatsApp,
              value: phone,
              onTap: () => choose(_ContactMethod.whatsapp),
            ),
            _ContactOption(
              icon: Icons.call_outlined,
              label: l10n.adminStatisticsContactCall,
              value: phone,
              onTap: () => choose(_ContactMethod.call),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.closeLabel),
        ),
      ],
    );
  }
}

class _ContactOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _ContactOption({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;

    return ListTile(
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(icon, color: colors.primary, size: 22),
      title: Text(
        label,
        style: tokens.typography.bodyMedium.copyWith(
          color: colors.label,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: tokens.typography.bodySmall.copyWith(color: colors.muted),
      ),
    );
  }
}
