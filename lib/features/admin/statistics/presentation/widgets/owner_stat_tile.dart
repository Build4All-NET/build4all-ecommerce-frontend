import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// One headline number on the statistics screen.
///
/// Deliberately plain: the value carries the weight, the label and icon stay
/// muted so a row of these reads as one block rather than six competing cards.
class OwnerStatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  /// Tints the icon when a number deserves a nudge (e.g. new signups).
  final Color? accent;

  const OwnerStatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final spacing = tokens.spacing;

    final iconColor = accent ?? colors.muted;

    return Container(
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(tokens.card.radius),
        border: Border.all(color: colors.border.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 18),
          SizedBox(height: spacing.sm),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tokens.typography.titleMedium.copyWith(
              color: colors.label,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: spacing.xs),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: tokens.typography.bodySmall.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
  }
}
