import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' show XFile;

/// Renders a picked [XFile] as an image on every platform.
///
/// `Image.file` throws on web because `dart:io.File` isn't supported there,
/// while [XFile.path] on web is a `blob:` URL that [Image.network] can load
/// directly. Native platforms keep using [Image.file] as before.
class XFileImage extends StatelessWidget {
  final XFile file;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final int? cacheWidth;
  final int? cacheHeight;
  final FilterQuality filterQuality;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const XFileImage(
    this.file, {
    super.key,
    this.width,
    this.height,
    this.fit,
    this.cacheWidth,
    this.cacheHeight,
    this.filterQuality = FilterQuality.low,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(
        file.path,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        filterQuality: filterQuality,
        errorBuilder: errorBuilder,
      );
    }

    return Image.file(
      File(file.path),
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      filterQuality: filterQuality,
      errorBuilder: errorBuilder,
    );
  }
}
