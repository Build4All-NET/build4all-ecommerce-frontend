import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/picked_excel_file.dart';

class ExcelFileCard extends StatelessWidget {
  final PickedExcelFile? file;
  final bool isPicking;
  final VoidCallback onPick;

  const ExcelFileCard({
    super.key,
    required this.file,
    required this.isPicking,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;

    final name = file == null
        ? l10n.adminExcelNoFile
        : file!.name;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(tokens.card.radius),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.table_chart_outlined, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.adminExcelFileLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.label,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.body,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: isPicking ? null : onPick,
            child: Text(isPicking ? l10n.loadingLabel : l10n.adminExcelPickBtn),
          ),
        ],
      ),
    );
  }
}
