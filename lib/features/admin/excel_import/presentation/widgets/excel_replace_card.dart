import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ExcelReplaceCard extends StatelessWidget {
  final bool replace;
  final String scope;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onScopeChanged;

  const ExcelReplaceCard({
    super.key,
    required this.replace,
    required this.scope,
    required this.onToggle,
    required this.onScopeChanged,
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
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.adminExcelReplaceTitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.label,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Switch(value: replace, onChanged: onToggle),
            ],
          ),
          Text(
            l10n.adminExcelReplaceHint,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colors.body),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: scope,
            items: [
              DropdownMenuItem(value: 'TENANT', child: Text(l10n.excelReplaceScopeTenantSafe)),
              DropdownMenuItem(value: 'FULL', child: Text(l10n.excelReplaceScopeFullDangerous)),
            ],
            onChanged: replace ? (v) => onScopeChanged(v ?? 'TENANT') : null,
            decoration: InputDecoration(
              labelText: l10n.adminExcelReplaceScopeLabel,
              filled: true,
            ),
          ),
        ],
      ),
    );
  }
}
