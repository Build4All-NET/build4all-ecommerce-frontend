import 'dart:typed_data';

/// A photograph the owner just took, held as bytes.
///
/// Bytes rather than a path, for the same reason the file picker asks for them:
/// on the web there is no path to read, and the camera is one of the places an
/// owner is most likely to be using a phone browser.
class PickedPhoto {
  final String name;
  final Uint8List bytes;

  const PickedPhoto({required this.name, required this.bytes});
}
