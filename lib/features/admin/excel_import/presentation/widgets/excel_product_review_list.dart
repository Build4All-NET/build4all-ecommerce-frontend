import 'package:flutter/material.dart';

import 'package:build4front/l10n/app_localizations.dart';

import '../../domain/entities/excel_product_preview.dart';
import '../bloc/excel_import_state.dart';

/// The products the file contained, shown back to the owner before anything is
/// created — and where each one gets its picture.
///
/// This is the answer to the thing an Excel file cannot do: the sheet carries
/// names and prices, the gallery carries the photos, and this list is where the
/// owner joins the two.
class ExcelProductReviewList extends StatelessWidget {
  final List<ExcelProductPreview> previews;
  final Map<int, ExcelRowImage> rowImages;
  final void Function(ExcelProductPreview product) onPickImage;
  final void Function(ExcelProductPreview product) onClearImage;

  const ExcelProductReviewList({
    super.key,
    required this.previews,
    required this.rowImages,
    required this.onPickImage,
    required this.onClearImage,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (previews.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          l10n.excelPreviewNoProducts,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return ListView.separated(
      // Nested inside the screen's scroll view: this list must measure itself
      // and leave the scrolling to the page.
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: previews.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final product = previews[index];

        return _ProductRow(
          product: product,
          assigned: rowImages[product.row],
          onPickImage: () => onPickImage(product),
          onClearImage: () => onClearImage(product),
        );
      },
    );
  }
}

class _ProductRow extends StatelessWidget {
  final ExcelProductPreview product;
  final ExcelRowImage? assigned;
  final VoidCallback onPickImage;
  final VoidCallback onClearImage;

  const _ProductRow({
    required this.product,
    required this.assigned,
    required this.onPickImage,
    required this.onClearImage,
  });

  /// What to draw in the thumbnail: the owner's choice first, then whatever link
  /// the file carried.
  String? get _thumbnailUrl {
    if (assigned != null) return assigned!.url;

    final fromFile = product.imageUrl?.trim();
    return (fromFile == null || fromFile.isEmpty) ? null : fromFile;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final hasIssues = !product.valid;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasIssues ? scheme.error : scheme.outlineVariant,
          width: hasIssues ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumbnail(url: _thumbnailUrl, onTap: onPickImage),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(l10n),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    if (product.downloadable || product.virtualProduct) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (product.downloadable)
                            _Badge(
                              icon: Icons.download_outlined,
                              label: l10n.excelPreviewDigital,
                            ),
                          if (product.virtualProduct && !product.downloadable)
                            _Badge(
                              icon: Icons.local_shipping_outlined,
                              label: l10n.excelPreviewNoShipping,
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: onPickImage,
                          icon: const Icon(Icons.photo_library_outlined, size: 18),
                          label: Text(
                            assigned == null
                                ? l10n.excelPreviewChooseImage
                                : l10n.excelPreviewChangeImage,
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        if (assigned != null)
                          TextButton(
                            onPressed: onClearImage,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              visualDensity: VisualDensity.compact,
                              foregroundColor: scheme.error,
                            ),
                            child: Text(l10n.excelPreviewRemoveImage),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (hasIssues) ...[
            const SizedBox(height: 8),
            for (final issue in product.issues)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, size: 16, color: scheme.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        issue,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.error),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// Row number first, because that is what the owner goes back to Excel to fix.
  String _subtitle(AppLocalizations l10n) {
    final parts = <String>[l10n.excelPreviewRow(product.row)];

    if (product.price != null) parts.add(_money(product.price!));
    // A digital product never runs out, so its quantity says nothing.
    if (product.stock != null && !product.downloadable) parts.add('×${product.stock}');
    if (product.itemTypeName != null) parts.add(product.itemTypeName!);
    if (product.sku != null) parts.add(product.sku!);

    return parts.join(' · ');
  }

  static String _money(double value) {
    final rounded = value.toStringAsFixed(2);
    return rounded.endsWith('.00') ? rounded.substring(0, rounded.length - 3) : rounded;
  }
}

class _Thumbnail extends StatelessWidget {
  final String? url;
  final VoidCallback onTap;

  const _Thumbnail({required this.url, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 64,
        height: 64,
        child: url == null
            ? DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        size: 22, color: scheme.outline),
                    const SizedBox(height: 2),
                    Text(
                      l10n.excelPreviewNoImage,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 8, color: scheme.outline),
                    ),
                  ],
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  url!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.broken_image_outlined,
                        size: 20, color: scheme.outline),
                  ),
                ),
              ),
      ),
    );
  }
}

/// A small chip marking what kind of product a row is.
class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Badge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: scheme.onSecondaryContainer),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: scheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
