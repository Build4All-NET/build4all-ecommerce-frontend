import 'dart:io';

import 'package:build4front/common/widgets/app_toast.dart';
import 'package:build4front/common/widgets/primary_button.dart';
import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';

import '../bloc/excel_import_bloc.dart';
import '../bloc/excel_import_event.dart';
import '../bloc/excel_import_state.dart';
import '../widgets/excel_counts_card.dart';
import '../widgets/excel_issues_list.dart';
import '../widgets/excel_file_card.dart';
import '../widgets/excel_replace_card.dart';

class AdminExcelImportScreen extends StatelessWidget {
  const AdminExcelImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;

    return BlocListener<ExcelImportBloc, ExcelImportState>(
      listenWhen: (p, c) =>
          p.errorMessage != c.errorMessage ||
          p.result != c.result ||
          p.templateFilePath != c.templateFilePath,
      listener: (context, state) async {
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          AppToast.error(context, state.errorMessage!);
        }

        if (state.result != null) {
          AppToast.error(context, state.result!.message);
        }

        // ✅ After download: show toast + open file
        if (state.templateFilePath != null &&
            state.templateFilePath!.isNotEmpty) {
          AppToast.error(context, l10n.adminExcelTemplateSavedToast);
          await OpenFilex.open(state.templateFilePath!);
        }
      },
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.surface,
          elevation: 0,
          title: Text(
            l10n.adminExcelImportTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.label,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        body: BlocBuilder<ExcelImportBloc, ExcelImportState>(
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== Header / helper text =====
                  _SectionHeader(
                    title: l10n.adminExcelStep1Title,
                    subtitle: l10n.adminExcelStep1Subtitle,
                    colors: colors,
                  ),
                  const SizedBox(height: 12),

                  // ===== Download template =====
                  PrimaryButton(
                    label: state.downloadingTemplate
                        ? l10n.loadingLabel
                        : l10n.adminExcelDownloadTemplateBtn,
                    isLoading: state.downloadingTemplate,
                    onPressed: () => context
                        .read<ExcelImportBloc>()
                        .add(const ExcelDownloadTemplatePressed()),
                  ),

                  // ===== Saved path info card (no share) =====
                  if (state.templateFilePath != null &&
                      state.templateFilePath!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _InfoCard(
                      title: l10n.adminExcelSavedLocationTitle,
                      body:
                          "${l10n.adminExcelSavedLocationBody}\n${state.templateFilePath!}",
                      actionLabel: l10n.adminExcelOpenTemplateBtn,
                      onAction: () => OpenFilex.open(state.templateFilePath!),
                      colors: colors,
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ===== Step 2 =====
                  _SectionHeader(
                    title: l10n.adminExcelStep2Title,
                    subtitle: l10n.adminExcelStep2Subtitle,
                    colors: colors,
                  ),
                  const SizedBox(height: 12),

                  ExcelFileCard(
                    file: state.file,
                    isPicking: state.picking,
                    onPick: () => context
                        .read<ExcelImportBloc>()
                        .add(const ExcelPickFilePressed()),
                  ),

                  const SizedBox(height: 12),

                  PrimaryButton(
                    label: state.validating
                        ? l10n.loadingLabel
                        : l10n.adminExcelValidateBtn,
                    isLoading: state.validating,
                    onPressed: state.canValidate
                        ? () => context
                            .read<ExcelImportBloc>()
                            .add(const ExcelValidatePressed())
                        : null,
                  ),

                  const SizedBox(height: 12),

                  // ===== Validation results =====
                  if (state.validation != null) ...[
                    ExcelCountsCard(validation: state.validation!),
                    const SizedBox(height: 12),
                    if (state.validation!.errors.isNotEmpty)
                      ExcelIssuesList(
                        title: l10n.adminExcelErrorsTitle,
                        items: state.validation!.errors, isError: true,
                        
                      ),
                    if (state.validation!.warnings.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ExcelIssuesList(
                        title: l10n.adminExcelWarningsTitle,
                        items: state.validation!.warnings,
                        isError: false,
                      ),
                    ],
                    const SizedBox(height: 12),
                    ExcelReplaceCard(
                      replace: state.replace,
                      scope: state.replaceScope,
                      onToggle: (v) => context
                          .read<ExcelImportBloc>()
                          .add(ExcelReplaceToggled(v)),
                      onScopeChanged: (s) => context
                          .read<ExcelImportBloc>()
                          .add(ExcelReplaceScopeChanged(s)),
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: state.importing
                          ? l10n.loadingLabel
                          : l10n.adminExcelImportBtn,
                      isLoading: state.importing,
                      onPressed: state.canImport
                          ? () => context
                              .read<ExcelImportBloc>()
                              .add(const ExcelImportPressed())
                          : null,
                    ),
                  ],

                  const SizedBox(height: 24),

                  Text(
                    l10n.adminExcelProTipBody,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.body,
                        ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ----------------- Small UI helpers (clean, reusable) -----------------

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final dynamic colors;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colors.label,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.body,
              ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;
  final dynamic colors;

  const _InfoCard({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colors.label,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.body,
                  height: 1.3,
                ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: actionLabel,
            onPressed: onAction,
          ),
        ],
      ),
    );
  }
}
