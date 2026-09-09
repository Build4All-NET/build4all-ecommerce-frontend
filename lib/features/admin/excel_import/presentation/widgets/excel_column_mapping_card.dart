import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/product_field.dart';
import '../../domain/entities/sheet_mapping.dart';

/// What the server made of the owner's file, laid out for them to correct.
///
/// The reading is a proposal, and this is where it stops being one. Each column
/// keeps its own heading and a plain line of why it was read that way, so an
/// owner who disagrees can see what the guess was based on instead of being told
/// to trust it.
class ExcelColumnMappingCard extends StatelessWidget {
  final SheetMapping sheet;
  final void Function(int columnIndex, ProductField field) onFieldChanged;

  const ExcelColumnMappingCard({
    super.key,
    required this.sheet,
    required this.onFieldChanged,
  });

  /// The owner-facing name of a field, in their language.
  static String labelFor(AppLocalizations l10n, ProductField field) {
    switch (field) {
      case ProductField.name:
        return l10n.excelFieldName;
      case ProductField.sku:
        return l10n.excelFieldSku;
      case ProductField.price:
        return l10n.excelFieldPrice;
      case ProductField.stock:
        return l10n.excelFieldStock;
      case ProductField.description:
        return l10n.excelFieldDescription;
      case ProductField.category:
        return l10n.excelFieldCategory;
      case ProductField.imageUrl:
        return l10n.excelFieldImage;
      case ProductField.ignore:
        return l10n.excelFieldIgnore;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;

    final toCheck = sheet.columns.where((c) => c.needsAttention).length;

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
            l10n.excelOwnFileColumnsTitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.label,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.excelOwnFileColumnsSubtitle,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colors.body),
          ),
          const SizedBox(height: 6),

          // Who made the reading, said plainly: an owner checking a guess
          // deserves to know whether a model was involved in it.
          Row(
            children: [
              Icon(
                sheet.aiUsed ? Icons.auto_awesome : Icons.table_chart_outlined,
                size: 14,
                color: colors.muted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  sheet.aiUsed
                      ? l10n.excelOwnFileReadWithAi
                      : l10n.excelOwnFileReadFromData,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colors.muted),
                ),
              ),
            ],
          ),

          if (toCheck > 0) ...[
            const SizedBox(height: 6),
            Text(
              l10n.excelOwnFileNeedsCheck(toCheck),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.danger,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],

          const SizedBox(height: 12),

          for (final column in sheet.columns) ...[
            _ColumnRow(
              column: column,
              onFieldChanged: (field) =>
                  onFieldChanged(column.columnIndex, field),
            ),
            const SizedBox(height: 10),
          ],

          if (!sheet.hasName)
            Text(
              l10n.excelOwnFileNeedsName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.danger,
                    fontWeight: FontWeight.w700,
                  ),
            ),
        ],
      ),
    );
  }
}

class _ColumnRow extends StatelessWidget {
  final ColumnGuess column;
  final ValueChanged<ProductField> onFieldChanged;

  const _ColumnRow({required this.column, required this.onFieldChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;

    final heading = column.header.trim().isEmpty
        ? l10n.excelOwnFileNoHeading
        : column.header.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (column.needsAttention) ...[
              Icon(Icons.help_outline, size: 16, color: colors.danger),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                heading,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.label,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<ProductField>(
          value: column.field,
          isExpanded: true,
          items: [
            for (final field in ProductField.choices)
              DropdownMenuItem(
                value: field,
                child: Text(ExcelColumnMappingCard.labelFor(l10n, field)),
              ),
          ],
          onChanged: (field) {
            if (field != null) onFieldChanged(field);
          },
          decoration: const InputDecoration(filled: true, isDense: true),
        ),
        if (column.reason.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            column.reason,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colors.muted),
          ),
        ],
      ],
    );
  }
}
