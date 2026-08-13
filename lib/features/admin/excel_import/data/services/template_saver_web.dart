import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

const _xlsxMimeType =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

/// Hands the template to the browser as a download.
///
/// Returns null: a browser download lands wherever the browser puts it, so
/// there is no path to show or reopen — unlike the io implementation.
Future<String?> saveTemplate(Uint8List bytes, String fileName) async {
  final blob = web.Blob(
    <JSUint8Array>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: _xlsxMimeType),
  );

  final url = web.URL.createObjectURL(blob);

  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = fileName;
  anchor.click();

  web.URL.revokeObjectURL(url);

  return null;
}
