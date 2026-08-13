import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart' show XFile;

/// Builds the multipart part for a picked file on every platform.
///
/// `MultipartFile.fromFile` needs a real filesystem path, which the browser
/// never provides — [XFile.path] there is a `blob:` URL and the upload fails.
/// [XFile.readAsBytes] works everywhere, so the bytes are read up front and the
/// original filename is carried across explicitly.
Future<MultipartFile> multipartFromXFile(XFile file) async {
  return MultipartFile.fromBytes(
    await file.readAsBytes(),
    filename: file.name,
  );
}
