import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';

class BannerImagePickerField extends StatelessWidget {
  final String? imagePath;
  final String? networkUrl;
  final ValueChanged<String?> onChanged;

  const BannerImagePickerField({
    super.key,
    required this.imagePath,
    required this.onChanged,
    this.networkUrl,
  });

  Future<void> _pick(BuildContext context, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? file;

      if (!kIsWeb && Platform.isIOS) {
        file = await picker.pickImage(
          source: source,
          requestFullMetadata: true,
        );
      } else {
        file = await picker.pickImage(
          source: source,
          imageQuality: 85,
          requestFullMetadata: true,
        );
      }

      if (file != null) {
        onChanged(file.path);
      }
    } catch (e) {
      if (!context.mounted) return;

      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l.adminUploadFailed ?? 'Failed to pick image',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final c = tokens.colors;
    final spacing = tokens.spacing;
    final text = tokens.typography;
    final l = AppLocalizations.of(context)!;

    final hasLocal = imagePath != null && imagePath!.isNotEmpty;
    final hasNetwork = !hasLocal && (networkUrl ?? '').trim().isNotEmpty;

    Widget preview() {
      if (hasLocal) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(tokens.card.radius),
          child: Image.file(
            File(imagePath!),
            height: 140,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        );
      }

      if (hasNetwork) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(tokens.card.radius),
          child: Image.network(
            networkUrl!,
            height: 140,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder(context),
          ),
        );
      }

      return _placeholder(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.adminImageLabel ?? 'Banner image',
          style: text.titleMedium.copyWith(color: c.label),
        ),
        SizedBox(height: spacing.xs),
        preview(),
        SizedBox(height: spacing.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pick(context, ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(l.adminChooseFromGallery ?? 'Gallery'),
              ),
            ),
            SizedBox(width: spacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pick(context, ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(l.adminTakePhoto ?? 'Camera'),
              ),
            ),
          ],
        ),
        if (hasLocal || hasNetwork) ...[
          SizedBox(height: spacing.xs),
          TextButton.icon(
            onPressed: () => onChanged(null),
            icon: Icon(Icons.delete_outline, color: c.danger),
            label: Text(
              l.adminRemoveImage ?? 'Remove image',
              style: text.bodyMedium.copyWith(color: c.danger),
            ),
          ),
        ],
      ],
    );
  }

  Widget _placeholder(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final c = tokens.colors;
    final spacing = tokens.spacing;
    final text = tokens.typography;

    return Container(
      height: 140,
      width: double.infinity,
      alignment: Alignment.center,
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(tokens.card.radius),
        border: Border.all(color: c.border.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_outlined, color: c.muted, size: 28),
          SizedBox(height: spacing.xs),
          Text(
            'No image selected',
            style: text.bodySmall.copyWith(color: c.muted),
          ),
        ],
      ),
    );
  }
}