import 'package:flutter/material.dart';

import '../../domain/entities/gallery_image.dart';
import 'gallery_image_tile.dart';

/// The grid of gallery images, shared by the full screen and the picker sheet so
/// the owner recognises the same surface in both places.
class GalleryGrid extends StatelessWidget {
  final List<GalleryImage> images;
  final int? selectedId;
  final int? busyId;
  final EdgeInsets padding;
  final ScrollController? controller;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final void Function(GalleryImage image)? onTap;
  final void Function(GalleryImage image)? onDelete;

  const GalleryGrid({
    super.key,
    required this.images,
    this.selectedId,
    this.busyId,
    this.padding = const EdgeInsets.all(16),
    this.controller,
    this.shrinkWrap = false,
    this.physics,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: images.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        // A max extent rather than a fixed column count, so a phone shows three
        // across and a tablet or the web build fills its width instead of
        // stretching three tiles over it.
        maxCrossAxisExtent: 140,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final image = images[index];

        return GalleryImageTile(
          image: image,
          selected: selectedId == image.id,
          busy: busyId == image.id,
          onTap: onTap == null ? null : () => onTap!(image),
          onDelete: onDelete == null ? null : () => onDelete!(image),
        );
      },
    );
  }
}
