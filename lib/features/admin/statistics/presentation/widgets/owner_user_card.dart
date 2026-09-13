import 'package:build4front/core/theme/app_theme_tokens.dart';
import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/owner_app_user.dart';

/// One app user in the owner's list: who they are, how to reach them, and a
/// tap target that opens the contact sheet.
class OwnerUserCard extends StatelessWidget {
  final OwnerAppUser user;
  final VoidCallback onTap;

  const OwnerUserCard({
    super.key,
    required this.user,
    required this.onTap,
  });

  static String _fmtDate(DateTime? date) {
    if (date == null) return '';
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final spacing = tokens.spacing;
    final l10n = AppLocalizations.of(context)!;

    final canContact = user.canBeContacted;

    // The contact line is the reason this screen exists, so it gets the
    // strong colour when it's there and a plain "no way to reach them" when
    // it isn't.
    final contactLine = <String>[
      if (user.hasPhone) user.phoneNumber.trim(),
      if (user.hasEmail) user.email.trim(),
    ].join('  •  ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canContact ? onTap : null,
        borderRadius: BorderRadius.circular(tokens.card.radius),
        child: Container(
          padding: EdgeInsets.all(spacing.md),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(tokens.card.radius),
            border: Border.all(color: colors.border.withOpacity(0.22)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(user: user),
              SizedBox(width: spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tokens.typography.bodyMedium.copyWith(
                              color: colors.label,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (user.verified) ...[
                          SizedBox(width: spacing.xs),
                          Icon(
                            Icons.verified_rounded,
                            size: 15,
                            color: colors.success,
                          ),
                        ],
                        if (!user.isActive) ...[
                          SizedBox(width: spacing.xs),
                          _Badge(
                            label: l10n.adminStatisticsInactiveBadge,
                            color: colors.muted,
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: spacing.xs),
                    Text(
                      canContact
                          ? contactLine
                          : l10n.adminStatisticsNoContactDetails,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tokens.typography.bodySmall.copyWith(
                        color: canContact ? colors.body : colors.muted,
                        fontStyle:
                            canContact ? FontStyle.normal : FontStyle.italic,
                      ),
                    ),
                    if (user.createdAt != null) ...[
                      SizedBox(height: spacing.xs),
                      Text(
                        l10n.adminStatisticsJoinedOn(_fmtDate(user.createdAt)),
                        style: tokens.typography.bodySmall.copyWith(
                          color: colors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (canContact)
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 20,
                  color: colors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final OwnerAppUser user;

  const _Avatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;

    final url = user.profileImageUrl.trim();

    return Container(
      width: 44,
      height: 44,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.primary.withOpacity(0.12),
        border: Border.all(color: colors.border.withOpacity(0.22)),
      ),
      child: url.isEmpty
          ? _initial(tokens, colors)
          : Image.network(
              url,
              fit: BoxFit.cover,
              // A broken avatar shouldn't cost the row its identity.
              errorBuilder: (_, __, ___) => _initial(tokens, colors),
            ),
    );
  }

  Widget _initial(AppThemeTokens tokens, ColorTokens colors) {
    return Center(
      child: Text(
        user.initial,
        style: tokens.typography.titleMedium.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: tokens.typography.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    );
  }
}
