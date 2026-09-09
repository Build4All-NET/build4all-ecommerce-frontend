import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/product_field.dart';
import '../../domain/entities/sheet_mapping.dart';

/// What the server made of the owner's file, laid out for them to correct.
///
/// The columns that become products come first and the rest are folded away. A
/// Shopify export carries fourteen columns and eight of them are ours to skip;
/// listing all fourteen the same way buries the four that matter behind a wall
/// of "not imported", and an owner scrolling that wall stops reading.
class ExcelColumnMappingCard extends StatefulWidget {
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

  /// Why a column was read this way, in the owner's language.
  static String reasonFor(AppLocalizations l10n, ColumnGuess column) {
    switch (column.reason) {
      case ColumnGuessReason.agreed:
        return l10n.excelReasonAgreed;
      case ColumnGuessReason.fromValues:
        return l10n.excelReasonFromValues;
      case ColumnGuessReason.fromHeading:
        return l10n.excelReasonFromHeading;
      case ColumnGuessReason.fromAssistant:
        return l10n.excelReasonFromAssistant;
      case ColumnGuessReason.disputed:
        return l10n.excelReasonDisputed(
          labelFor(l10n, column.field),
          labelFor(l10n, column.disputedWith ?? ProductField.ignore),
        );
      case ColumnGuessReason.noMatch:
        return l10n.excelReasonNoMatch;
    }
  }

  @override
  State<ExcelColumnMappingCard> createState() => _ExcelColumnMappingCardState();
}

class _ExcelColumnMappingCardState extends State<ExcelColumnMappingCard> {
  /// Closed to begin with: the skipped columns are there to be checked if the
  /// owner suspects something is missing, not to be read on the way past.
  bool _showSkipped = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;

    final sheet = widget.sheet;
    final imported = sheet.imported;
    final skipped = sheet.skipped;
    final toCheck = sheet.toCheck;

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

          // The line that tells the owner whether they have to do anything at
          // all, before they read a single column.
          Text(
            toCheck.isEmpty
                ? l10n.excelColumnsAllRead
                : l10n.excelOwnFileNeedsCheck(toCheck.length),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: toCheck.isEmpty ? colors.success : colors.danger,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),

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

          const SizedBox(height: 14),
          _GroupLabel(text: l10n.excelColumnsUsed(imported.length)),

          for (final column in imported) ...[
            const SizedBox(height: 10),
            _ColumnRow(column: column, onFieldChanged: widget.onFieldChanged),
          ],

          if (!sheet.hasName) ...[
            const SizedBox(height: 10),
            Text(
              l10n.excelOwnFileNeedsName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.danger,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],

          if (skipped.isNotEmpty) ...[
            const SizedBox(height: 14),
            InkWell(
              onTap: () => setState(() => _showSkipped = !_showSkipped),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      _showSkipped ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: colors.muted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.excelColumnsIgnoredShow(skipped.length),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            if (_showSkipped)
              for (final column in skipped) ...[
                const SizedBox(height: 10),
                _ColumnRow(column: column, onFieldChanged: widget.onFieldChanged),
              ],
          ],
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String text;

  const _GroupLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeCubit>().state.tokens.colors;

    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.muted,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _ColumnRow extends StatelessWidget {
  final ColumnGuess column;
  final void Function(int columnIndex, ProductField field) onFieldChanged;

  const _ColumnRow({required this.column, required this.onFieldChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;

    final heading = column.header.trim().isEmpty
        ? l10n.excelOwnFileNoHeading
        : column.header.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The file's own word on the left, ours on the right: the owner is
        // matching two things, and a column of headings above a column of
        // dropdowns is what that looks like.
        SizedBox(
          width: 120,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (column.needsAttention) ...[
                      Icon(Icons.help_outline, size: 14, color: colors.danger),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        heading,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.label,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
                // Only where the owner might disagree. On a column both signals
                // settled, the reason is noise.
                if (column.needsAttention) ...[
                  const SizedBox(height: 2),
                  Text(
                    ExcelColumnMappingCard.reasonFor(l10n, column),
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: colors.muted),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<ProductField>(
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
              if (field != null) onFieldChanged(column.columnIndex, field);
            },
            decoration: const InputDecoration(filled: true, isDense: true),
          ),
        ),
      ],
    );
  }
}
