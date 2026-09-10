import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/excel_import_state.dart';

/// The one question the import screen opens with.
///
/// Owners arrive from two different places -- one already has their catalogue in
/// another system, the other has nothing written down -- and the steps that
/// follow are not the same. Asking once, up front, keeps each of them from
/// reading past instructions that are not theirs.
class ExcelSourceCard extends StatelessWidget {
  final ExcelImportSource source;
  final ValueChanged<ExcelImportSource> onChanged;

  const ExcelSourceCard({
    super.key,
    required this.source,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.excelSourceTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colors.label,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        _SourceOption(
          title: l10n.excelSourceOwnFile,
          subtitle: l10n.excelSourceOwnFileHint,
          selected: source == ExcelImportSource.ownFile,
          onTap: () => onChanged(ExcelImportSource.ownFile),
        ),
        const SizedBox(height: 8),
        // For the shop that has nothing written down anywhere.
        _SourceOption(
          title: l10n.excelSourcePhotos,
          subtitle: l10n.excelSourcePhotosHint,
          selected: source == ExcelImportSource.photos,
          onTap: () => onChanged(ExcelImportSource.photos),
        ),
        const SizedBox(height: 8),
        _SourceOption(
          title: l10n.excelSourceTemplate,
          subtitle: l10n.excelSourceTemplateHint,
          selected: source == ExcelImportSource.template,
          onTap: () => onChanged(ExcelImportSource.template),
        ),
      ],
    );
  }
}

class _SourceOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _SourceOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(tokens.card.radius),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(tokens.card.radius),
          border: Border.all(
            color: selected ? colors.primary : colors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? colors.primary : colors.body,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.label,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: colors.body),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
