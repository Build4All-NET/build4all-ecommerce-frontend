import 'package:build4front/common/widgets/primary_button.dart';
import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/description_job.dart';

/// The offer to write the descriptions a catalogue arrived without.
///
/// Shown after the import, never before it. The products are already live and
/// selling; this is an improvement the owner may want, not a step they owe.
class ExcelDescriptionsCard extends StatelessWidget {
  final DescriptionJob job;
  final VoidCallback onWrite;

  const ExcelDescriptionsCard({
    super.key,
    required this.job,
    required this.onWrite,
  });

  @override
  Widget build(BuildContext context) {
    // No assistant available at all: no card rather than one explaining why it
    // cannot help. Having nothing to write is different -- that gets said.
    if (!job.worthOffering) return const SizedBox.shrink();

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
            l10n.excelDescriptionsTitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.label,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            job.running
                ? l10n.excelDescriptionsRunning(job.written, job.total)
                : job.nothingToWrite
                    ? l10n.excelDescriptionsAllHave
                    : l10n.excelDescriptionsCount(job.missing),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: job.nothingToWrite ? colors.success : colors.body,
                ),
          ),

          // Why there is nothing to do, since "already has one" invites the
          // question of where it came from.
          if (job.nothingToWrite && job.written == 0) ...[
            const SizedBox(height: 4),
            Text(
              l10n.excelDescriptionsFromFile,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colors.muted),
            ),
          ],

          if (job.running) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(
              // Indeterminate until the first batch lands, so the bar never sits
              // at zero looking stuck.
              value: job.total == 0 ? null : job.written / job.total,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.excelDescriptionsHint,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colors.muted),
            ),
          ] else ...[
            if (job.written > 0) ...[
              const SizedBox(height: 6),
              Text(
                l10n.excelDescriptionsDone(job.written),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colors.success),
              ),
            ],
            if (job.message != null && job.message!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                job.message!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colors.muted),
              ),
            ],
            // No button when there is nothing for it to do: one that reports
            // "0 written" teaches the owner the feature does not work.
            if (!job.nothingToWrite) ...[
              const SizedBox(height: 12),
              PrimaryButton(
                label: l10n.excelDescriptionsWriteBtn,
                onPressed: onWrite,
              ),
            ],
          ],
        ],
      ),
    );
  }
}
