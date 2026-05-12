import 'dart:io';

import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class OwnerAnnouncementForm extends StatefulWidget {
  final bool submitting;
  final void Function({
    required String title,
    required String message,
    required String announcementType,
    int? targetId,
    String? imagePath,
  }) onSubmit;

  const OwnerAnnouncementForm({
    super.key,
    required this.submitting,
    required this.onSubmit,
  });

  @override
  State<OwnerAnnouncementForm> createState() => _OwnerAnnouncementFormState();
}

class _OwnerAnnouncementFormState extends State<OwnerAnnouncementForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _targetIdCtrl = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  String _type = 'GENERAL';
  File? _imageFile;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    _targetIdCtrl.dispose();
    super.dispose();
  }

  List<_AnnouncementTypeOption> _types(AppLocalizations l10n) {
    return [
      _AnnouncementTypeOption('GENERAL', l10n.adminAnnouncementsTypeGeneral),
      _AnnouncementTypeOption('PRODUCT', l10n.adminAnnouncementsTypeProduct),
      _AnnouncementTypeOption('DISCOUNT', l10n.adminAnnouncementsTypeDiscount),
      _AnnouncementTypeOption('SERVICE', l10n.adminAnnouncementsTypeService),
      _AnnouncementTypeOption('MAINTENANCE', l10n.adminAnnouncementsTypeMaintenance),
    ];
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );

    if (picked == null) return;

    setState(() {
      _imageFile = File(picked.path);
    });
  }

  void _submit(AppLocalizations l10n) {
    if (!_formKey.currentState!.validate()) return;

    final rawTarget = _targetIdCtrl.text.trim();
    final targetId = rawTarget.isEmpty ? null : int.tryParse(rawTarget);

    widget.onSubmit(
      title: _titleCtrl.text.trim(),
      message: _messageCtrl.text.trim(),
      announcementType: _type,
      targetId: targetId,
      imagePath: _imageFile?.path,
    );

    _titleCtrl.clear();
    _messageCtrl.clear();
    _targetIdCtrl.clear();

    setState(() {
      _type = 'GENERAL';
      _imageFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final spacing = tokens.spacing;
    final text = Theme.of(context).textTheme;

    final types = _types(l10n);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border.withOpacity(.18)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.campaign_outlined,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.adminAnnouncementsNotifyAllTitle,
                        style: text.titleMedium?.copyWith(
                          color: colors.label,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.adminAnnouncementsNotifyAllDescription,
                        style: text.bodySmall?.copyWith(
                          color: colors.body,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.lg),

            TextFormField(
              controller: _titleCtrl,
              enabled: !widget.submitting,
              decoration: InputDecoration(
                labelText: l10n.adminAnnouncementsTitleLabel,
                hintText: l10n.adminAnnouncementsTitleHint,
                border: const OutlineInputBorder(),
              ),
            ),
            SizedBox(height: spacing.md),

            TextFormField(
              controller: _messageCtrl,
              enabled: !widget.submitting,
              minLines: 4,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: l10n.adminAnnouncementsMessageLabel,
                hintText: l10n.adminAnnouncementsMessageHint,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return l10n.adminAnnouncementsMessageRequired;
                }
                return null;
              },
            ),
            SizedBox(height: spacing.md),

            DropdownButtonFormField<String>(
              value: _type,
              decoration: InputDecoration(
                labelText: l10n.adminAnnouncementsTypeLabel,
                border: const OutlineInputBorder(),
              ),
              items: types
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item.value,
                      child: Text(item.label),
                    ),
                  )
                  .toList(),
              onChanged: widget.submitting
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() => _type = value);
                    },
            ),
            SizedBox(height: spacing.md),

            TextFormField(
              controller: _targetIdCtrl,
              enabled: !widget.submitting,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.adminAnnouncementsTargetIdLabel,
                hintText: l10n.adminAnnouncementsTargetIdHint,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                final raw = (value ?? '').trim();

                if (raw.isEmpty) return null;

                if (int.tryParse(raw) == null) {
                  return l10n.adminAnnouncementsTargetIdInvalid;
                }

                return null;
              },
            ),
            SizedBox(height: spacing.md),

            OutlinedButton.icon(
              onPressed: widget.submitting ? null : _pickImage,
              icon: const Icon(Icons.image_outlined),
              label: Text(l10n.chooseImage),
            ),

            if (_imageFile != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  _imageFile!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              TextButton.icon(
                onPressed: widget.submitting
                    ? null
                    : () {
                        setState(() => _imageFile = null);
                      },
                icon: const Icon(Icons.close_rounded),
                label: Text(l10n.removeImage),
              ),
            ],

            SizedBox(height: spacing.lg),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.submitting ? null : () => _submit(l10n),
                icon: widget.submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  widget.submitting
                      ? l10n.adminAnnouncementsSendingButton
                      : l10n.adminAnnouncementsSendButton,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementTypeOption {
  final String value;
  final String label;

  const _AnnouncementTypeOption(this.value, this.label);
}