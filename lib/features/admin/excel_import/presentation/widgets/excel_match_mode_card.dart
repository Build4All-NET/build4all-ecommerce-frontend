import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/excel_import_state.dart';

/// What happens to products whose code is already in the catalogue.
///
/// The question exists because re-importing is the normal case, not the
/// exception: an owner whose catalogue lives on another system exports it again
/// every time prices or stock move. Both answers keep the product they already
/// have -- the choice is only whether this file overwrites it.
class ExcelMatchModeCard extends StatelessWidget {
  final String matchMode;
  final ValueChanged<String> onChanged;

  const ExcelMatchModeCard({
    super.key,
    required this.matchMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(tokens.card.radius),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.excelMatchTitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.label,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.excelMatchExplain,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colors.body),
          ),
          const SizedBox(height: 6),
          RadioListTile<String>(
            value: ExcelImportState.matchModeUpdate,
            groupValue: matchMode,
            onChanged: (mode) => onChanged(mode ?? ExcelImportState.matchModeUpdate),
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              l10n.excelMatchUpdate,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colors.label),
            ),
          ),
          RadioListTile<String>(
            value: ExcelImportState.matchModeKeep,
            groupValue: matchMode,
            onChanged: (mode) => onChanged(mode ?? ExcelImportState.matchModeUpdate),
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              l10n.excelMatchKeep,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colors.label),
            ),
          ),
        ],
      ),
    );
  }
}
