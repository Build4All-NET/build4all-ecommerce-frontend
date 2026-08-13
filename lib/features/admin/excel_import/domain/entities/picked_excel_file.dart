import 'dart:typed_data';

/// A spreadsheet the user picked, carried as bytes rather than a path.
///
/// The browser gives no filesystem path for a picked file — reading
/// `PlatformFile.path` on web throws — so the whole import flow works from
/// bytes, which every platform provides.
class PickedExcelFile {
  final String name;
  final Uint8List bytes;

  const PickedExcelFile({required this.name, required this.bytes});

  int get sizeInBytes => bytes.length;
}
