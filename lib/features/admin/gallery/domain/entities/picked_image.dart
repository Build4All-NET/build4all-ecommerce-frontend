import 'dart:typed_data';

/// A file the owner chose, held as bytes so the same code path works on the web,
/// where a picked file has no path at all.
class PickedImage {
  final String name;
  final Uint8List bytes;

  const PickedImage({required this.name, required this.bytes});
}
