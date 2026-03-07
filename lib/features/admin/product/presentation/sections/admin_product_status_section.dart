import 'package:flutter/material.dart';
import 'package:build4front/l10n/app_localizations.dart';

class ItemStatusOptionUi {
  final int id;
  final String code;
  final String name;

  const ItemStatusOptionUi({
    required this.id,
    required this.code,
    required this.name,
  });
}

class AdminProductStatusSection extends StatelessWidget {
  final dynamic tokens;
  final AppLocalizations l;
  final List<ItemStatusOptionUi> statuses;
  final String? selectedStatusCode;
  final bool loadingStatuses;
  final ValueChanged<String?> onChanged;
  final String? errorText;

  const AdminProductStatusSection({
    super.key,
    required this.tokens,
    required this.l,
    required this.statuses,
    required this.selectedStatusCode,
    required this.loadingStatuses,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = tokens.spacing;
    final c = tokens.colors;
    final text = tokens.typography;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(tokens.card.radius),
        border: Border.all(color: c.border.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: c.label.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined, size: 18, color: c.primary),
              SizedBox(width: spacing.xs),
              Text(
                l.adminProductStatusSectionTitle,
                style: text.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.xs),
          Text(
            l.adminProductStatusSectionSubtitle,
            style: text.bodySmall.copyWith(color: c.muted),
          ),
          SizedBox(height: spacing.sm),

          Text(
            l.adminProductStatusLabel,
            style: text.titleMedium,
          ),
          SizedBox(height: spacing.xs),

          if (loadingStatuses)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(),
              ),
            )
          else if (statuses.isEmpty)
            Text(
              l.adminProductStatusUnavailable,
              style: text.bodyMedium.copyWith(color: c.danger),
            )
          else
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.sm,
                vertical: spacing.xs,
              ),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(tokens.card.radius),
                border: Border.all(color: c.border.withOpacity(0.4)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedStatusCode,
                  isExpanded: true,
                  items: statuses
                      .map(
                        (s) => DropdownMenuItem<String>(
                          value: s.code,
                          child: Text(s.name),
                        ),
                      )
                      .toList(),
                  onChanged: onChanged,
                ),
              ),
            ),

          if (errorText != null && errorText!.trim().isNotEmpty) ...[
            SizedBox(height: spacing.sm),
            Text(
              errorText!,
              style: text.bodySmall.copyWith(color: c.danger),
            ),
          ],
        ],
      ),
    );
  }
}