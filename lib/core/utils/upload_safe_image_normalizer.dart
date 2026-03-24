import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class UploadSafeImageNormalizer {
  UploadSafeImageNormalizer._();

  static Future<String?> pickNormalizedImage({
    required ImagePicker picker,
    required ImageSource source,
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
    String preferredName = 'image',
  }) async {
    final picked = await picker.pickImage(
      source: source,
      imageQuality: _shouldNormalize ? 100 : imageQuality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );

    if (picked == null) return null;

    return normalizeImagePath(
      picked.path,
      preferredName: preferredName,
    );
  }

  static Future<String> normalizeImagePath(
    String path, {
    String preferredName = 'image',
  }) async {
    final safePath = path.trim();
    if (safePath.isEmpty || !_shouldNormalize) return safePath;

    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/${preferredName}_${DateTime.now().microsecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        safePath,
        targetPath,
        format: CompressFormat.jpeg,
        quality: 95,
        minWidth: 1920,
        minHeight: 1920,
        autoCorrectionAngle: true,
        keepExif: false,
      );

      final normalizedPath = result?.path?.trim();
      if (normalizedPath != null && normalizedPath.isNotEmpty) {
        return normalizedPath;
      }
    } catch (_) {
      // Fallback to the original image path if native normalization fails.
    }

    return safePath;
  }

  static bool get _shouldNormalize => !kIsWeb && Platform.isIOS;
}