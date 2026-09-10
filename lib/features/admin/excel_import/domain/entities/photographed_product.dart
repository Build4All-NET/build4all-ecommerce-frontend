import 'package:equatable/equatable.dart';

/// One product as it came off the camera: a picture, and what the assistant made
/// of it.
///
/// Everything here except the price came from the photograph. The name is a
/// guess and the owner's to correct; the picture is already theirs, stored in
/// their gallery the moment they took it.
class PhotographedProduct extends Equatable {
  /// Which photograph this is in the batch, and how a correction finds its way
  /// back to the right one.
  final int photoIndex;

  /// The picture's id in the gallery, which is how it becomes the product's
  /// image when the products are created.
  final int? mediaId;

  final String? imageUrl;

  /// What the assistant thinks it is. Empty when it would not say, which is a
  /// product the owner names themselves rather than one we guessed at.
  final String name;

  final String? category;

  const PhotographedProduct({
    required this.photoIndex,
    required this.mediaId,
    required this.imageUrl,
    required this.name,
    required this.category,
  });

  bool get needsName => name.trim().isEmpty;

  @override
  List<Object?> get props => [photoIndex, mediaId, imageUrl, name, category];
}
