import 'package:flutter/material.dart';

import '../../domain/entities/gallery_image.dart';

/// One square in the gallery grid.
///
/// A failed image still renders as a tile rather than a gap: the owner needs to
/// be able to select or delete a picture whose bytes are unreachable, and an
/// empty space gives them nothing to tap.
class GalleryImageTile extends StatelessWidget {
  final GalleryImage image;
  final bool selected;
  final bool busy;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const GalleryImageTile({
    super.key,
    required this.image,
    this.selected = false,
    this.busy = false,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: busy ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              image.url,
              fit: BoxFit.cover,
              errorBuilder: (_, error, ___) {
                debugPrint('Gallery image failed to load: ${image.url}');
                debugPrint('Error: $error');
                return ColoredBox(
                  color: scheme.surfaceContainerHighest,
                  child: Icon(Icons.broken_image_outlined, color: scheme.outline),
                );
              },
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return ColoredBox(
                  color: scheme.surfaceContainerHighest,
                  child: const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              },
            ),
          ),

          if (selected)
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.primary, width: 3),
                color: scheme.primary.withValues(alpha: 0.18),
              ),
              child: Align(
                alignment: Alignment.center,
                child: Icon(Icons.check_circle, color: scheme.primary, size: 30),
              ),
            ),

          if (busy)
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withValues(alpha: 0.35),
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),

          if (onDelete != null && !busy)
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: Colors.black.withValues(alpha: 0.45),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onDelete,
                  child: const Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(Icons.close, size: 15, color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
