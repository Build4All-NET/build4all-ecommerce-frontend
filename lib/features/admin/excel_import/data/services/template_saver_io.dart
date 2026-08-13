import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Writes the template into app storage and returns where it landed, so the
/// caller can offer to open it.
Future<String?> saveTemplate(Uint8List bytes, String fileName) async {
  final dir = await getApplicationSupportDirectory();

  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  final outFile = File('${dir.path}/$fileName');
  await outFile.writeAsBytes(bytes, flush: true);

  return outFile.path;
}
