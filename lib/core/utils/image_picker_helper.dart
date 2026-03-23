import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class AppImagePickerHelper {
  AppImagePickerHelper._();

  static final ImagePicker _picker = ImagePicker();

  static const List<String> _problematicIosExtensions = <String>[
    '.heic',
    '.heif',
  ];

  static bool _isProblematicIosImage(XFile file) {
    final path = file.path.toLowerCase();
    return _problematicIosExtensions.any(path.endsWith);
  }

  /// Main single-image picker.
  /// On iOS: pick original without compression/resizing to avoid green/color-shift issues.
  /// On Android: keep light compression if desired.
  static Future<XFile?> pickSingleImage({
    required ImageSource source,
    int androidImageQuality = 85,
    double? androidMaxWidth = 1600,
    double? androidMaxHeight = 1600,
    bool rejectProblematicIosFormats = false,
  }) async {
    try {
      final XFile? file;

      if (!kIsWeb && Platform.isIOS) {
        file = await _picker.pickImage(
          source: source,
          requestFullMetadata: true,
        );
      } else {
        file = await _picker.pickImage(
          source: source,
          imageQuality: androidImageQuality,
          maxWidth: androidMaxWidth,
          maxHeight: androidMaxHeight,
          requestFullMetadata: true,
        );
      }

      if (file == null) return null;

      if (!kIsWeb &&
          Platform.isIOS &&
          rejectProblematicIosFormats &&
          _isProblematicIosImage(file)) {
        throw UnsupportedError(
          'HEIC/HEIF images are not allowed in this flow. Please choose JPG or PNG.',
        );
      }

      return file;
    } catch (e, st) {
      debugPrint('pickSingleImage error: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  /// Multi-image picker.
  /// On iOS: original files only, no resize/compression.
  static Future<List<XFile>> pickMultiImage({
    int androidImageQuality = 85,
    double? androidMaxWidth = 1600,
    double? androidMaxHeight = 1600,
    bool rejectProblematicIosFormats = false,
    int? limit,
  }) async {
    try {
      final List<XFile> files;

      if (!kIsWeb && Platform.isIOS) {
        files = await _picker.pickMultiImage(
          requestFullMetadata: true,
          limit: limit,
        );
      } else {
        files = await _picker.pickMultiImage(
          imageQuality: androidImageQuality,
          maxWidth: androidMaxWidth,
          maxHeight: androidMaxHeight,
          requestFullMetadata: true,
          limit: limit,
        );
      }

      if (!kIsWeb && Platform.isIOS && rejectProblematicIosFormats) {
        final bad = files.where(_isProblematicIosImage).toList();
        if (bad.isNotEmpty) {
          throw UnsupportedError(
            'Some selected files are HEIC/HEIF. Please choose JPG or PNG.',
          );
        }
      }

      return files;
    } catch (e, st) {
      debugPrint('pickMultiImage error: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  static bool isHeicOrHeifPath(String? path) {
    if (path == null) return false;
    final lower = path.toLowerCase();
    return lower.endsWith('.heic') || lower.endsWith('.heif');
  }
}