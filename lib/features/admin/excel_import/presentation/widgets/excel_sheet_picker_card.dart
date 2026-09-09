import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/sheet_mapping.dart';

/// Which tab of the owner's workbook holds the catalogue.
///
/// Only shown when there is a choice to make. A file exported from a till is one
/// sheet and asking about it would be a step for nothing; a workbook kept by
/// hand carries suppliers, invoices and a cover page beside the products, and
/// only the owner can say which is which.
class ExcelSheetPickerCard extends StatelessWidget {
  final List<SheetMapping> sheets;
  final String? selectedSheetName;
  final ValueChanged<String> onSheetSelected;

  const ExcelSheetPickerCard({
    super.key,
    required this.sheets,
    required this.selectedSheetName,
    required this.onSheetSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (sheets.length < 2) return const SizedBox.shrink();

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
            l10n.excelOwnFileSheetTitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.label,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          for (final sheet in sheets)
            RadioListTile<String>(
              value: sheet.sheetName,
              groupValue: selectedSheetName ?? sheets.first.sheetName,
              onChanged: (name) {
                if (name != null) onSheetSelected(name);
              },
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                sheet.sheetName,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: colors.label),
              ),
              // The row count is what tells a catalogue of 1,247 products apart
              // from a list of twelve suppliers.
              subtitle: Text(
                l10n.excelOwnFileSheetRows(sheet.dataRowCount),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colors.muted),
              ),
            ),
        ],
      ),
    );
  }
}
