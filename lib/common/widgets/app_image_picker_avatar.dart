import 'dart:io';

import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/core/utils/upload_safe_image_normalizer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

/// Possible shapes for the image picker.
enum AppImageShape { circle, roundedRect }

class AppImagePickerAvatar extends StatefulWidget {
  /// Existing image path (local file) if you already have one.
  final String? initialImagePath;

  /// Called when user picks a new image (returns the file path).
  final ValueChanged<String?> onImageChanged;

  /// Overall size of the avatar (width/height for rect, diameter for circle).
  final double size;

  /// Shape: circle or rounded rectangle.
  final AppImageShape shape;

  /// Optional hero tag if you want hero transitions.
  final String? heroTag;

  /// Whether to show the small camera badge in the corner.
  final bool showCameraBadge;

  /// Icon to show when no image.
  final IconData emptyIcon;

  /// Allow picking from camera.
  final bool enableCamera;

  /// Allow picking from gallery.
  final bool enableGallery;

  const AppImagePickerAvatar({
    super.key,
    this.initialImagePath,
    required this.onImageChanged,
    this.size = 96,
    this.shape = AppImageShape.circle,
    this.heroTag,
    this.showCameraBadge = true,
    this.emptyIcon = Icons.person_outline,
    this.enableCamera = true,
    this.enableGallery = true,
  });

  @override
  State<AppImagePickerAvatar> createState() => _AppImagePickerAvatarState();
}

class _AppImagePickerAvatarState extends State<AppImagePickerAvatar> {
  final ImagePicker _picker = ImagePicker();
  String? _currentPath;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.initialImagePath;
  }

  @override
  void didUpdateWidget(covariant AppImagePickerAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialImagePath != widget.initialImagePath) {
      _currentPath = widget.initialImagePath;
    }
  }

 Future<void> _pick(ImageSource source) async {
  final normalizedPath = await UploadSafeImageNormalizer.pickNormalizedImage(
    picker: _picker,
    source: source,
    imageQuality: 85,
    maxWidth: 800,
    maxHeight: 800,
    preferredName: 'avatar',
  );

  if (normalizedPath != null && normalizedPath.isNotEmpty) {
    setState(() {
      _currentPath = normalizedPath;
    });
    widget.onImageChanged(normalizedPath);
  }
}

  Future<void> _onTap(BuildContext context) async {
    final canCamera = widget.enableCamera;
    final canGallery = widget.enableGallery;

    if (!canCamera && !canGallery) return;

    // Only one source → pick directly
    if (canCamera && !canGallery) {
      await _pick(ImageSource.camera);
      return;
    }
    if (!canCamera && canGallery) {
      await _pick(ImageSource.gallery);
      return;
    }

    // Both allowed → show bottom sheet
    final themeState = context.read<ThemeCubit>().state;
    final colors = themeState.tokens.colors;
    final t = Theme.of(context).textTheme;

    await showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    // you can l10n this label later if you want
                    'Choose photo',
                    style: t.titleMedium?.copyWith(
                      color: colors.label,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              ListTile(
                leading: Icon(
                  Icons.photo_camera_outlined,
                  color: colors.primary,
                ),
                title: Text(
                  'Take a photo',
                  style: t.bodyMedium?.copyWith(color: colors.label),
                ),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _pick(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library_outlined,
                  color: colors.primary,
                ),
                title: Text(
                  'Choose from gallery',
                  style: t.bodyMedium?.copyWith(color: colors.label),
                ),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _pick(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeCubit>().state;
    final colors = themeState.tokens.colors;

    final imageProvider = _currentPath != null
        ? FileImage(File(_currentPath!)) as ImageProvider
        : null;

    final double size = widget.size;
    final double radius = size / 2;

    Widget avatarContent;

    if (widget.shape == AppImageShape.circle) {
      avatarContent = CircleAvatar(
        radius: radius,
        backgroundColor: colors.primary.withOpacity(0.08),
        backgroundImage: imageProvider,
        child: imageProvider == null
            ? Icon(widget.emptyIcon, color: colors.primary, size: radius)
            : null,
      );
    } else {
      // Rounded rectangle
      avatarContent = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(size * 0.3),
          image: imageProvider != null
              ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
              : null,
        ),
        child: imageProvider == null
            ? Icon(widget.emptyIcon, color: colors.primary, size: radius)
            : null,
      );
    }

    if (widget.heroTag != null) {
      avatarContent = Hero(tag: widget.heroTag!, child: avatarContent);
    }

    return GestureDetector(
      onTap: () => _onTap(context),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          avatarContent,
          if (widget.showCameraBadge)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(5),
                child: Icon(
                  Icons.camera_alt_outlined,
                  size: size * 0.18,
                  color: colors.onPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
