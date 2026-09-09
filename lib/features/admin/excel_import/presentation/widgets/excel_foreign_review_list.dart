import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/excel_product_preview.dart';
import '../../domain/entities/foreign_preview.dart';
import '../bloc/excel_import_state.dart';

/// The products the file would create, laid out to be corrected.
///
/// The file carries names, codes and quantities; what it does not carry is a
/// price the owner is happy to sell at, or a picture. This is where both get
/// added -- once, over a list, instead of once per product in a form.
class ExcelForeignReviewList extends StatelessWidget {
  final ForeignPreview preview;
  final List<ExcelProductPreview> visible;
  final Map<int, RowEdit> rowEdits;
  final Map<int, ExcelRowImage> rowImages;

  final bool issuesOnly;
  final String query;

  final String Function(ExcelProductPreview) priceOf;
  final String Function(ExcelProductPreview) stockOf;

  final void Function(int row, String price) onPriceChanged;
  final void Function(int row, String stock) onStockChanged;
  final void Function(ExcelProductPreview product) onPickImage;
  final ValueChanged<bool> onFilterChanged;
  final ValueChanged<String> onQueryChanged;

  const ExcelForeignReviewList({
    super.key,
    required this.preview,
    required this.visible,
    required this.rowEdits,
    required this.rowImages,
    required this.issuesOnly,
    required this.query,
    required this.priceOf,
    required this.stockOf,
    required this.onPriceChanged,
    required this.onStockChanged,
    required this.onPickImage,
    required this.onFilterChanged,
    required this.onQueryChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (preview.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;

    final needingAttention = preview.needingAttention.length;
    final withImage = preview.products
        .where((p) =>
            rowImages.containsKey(p.row) ||
            (p.imageUrl != null && p.imageUrl!.trim().isNotEmpty))
        .length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(tokens.card.radius),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.excelPreviewStepTitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.label,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),

          Text(
            l10n.excelPreviewFound(preview.products.length),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colors.body),
          ),
          if (needingAttention > 0)
            Text(
              l10n.excelPreviewNeedsPrice(needingAttention),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.danger,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          // Rows with no name at all. Said once, as a number: there is nothing
          // in them to show, and nothing the owner can do here about them.
          if (preview.skippedRows > 0)
            Text(
              l10n.excelPreviewSkippedRows(preview.skippedRows),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colors.muted),
            ),
          Text(
            l10n.excelPreviewImagesGiven(withImage, preview.products.length),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colors.muted),
          ),

          const SizedBox(height: 12),

          // On a catalogue of a thousand, the four that need a price are the
          // whole job; finding them by scrolling is not a plan.
          Row(
            children: [
              ChoiceChip(
                label: Text(l10n.excelPreviewShowAll),
                selected: !issuesOnly,
                onSelected: (_) => onFilterChanged(false),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text(l10n.excelPreviewShowIssues),
                selected: issuesOnly,
                onSelected: (_) => onFilterChanged(true),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              hintText: l10n.excelPreviewSearchHint,
              prefixIcon: const Icon(Icons.search, size: 18),
              filled: true,
              isDense: true,
            ),
          ),

          const SizedBox(height: 12),

          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                l10n.excelPreviewNoResults,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colors.muted),
              ),
            )
          else
            // Only the visible rows are built. A thousand products all at once
            // is what freezes the app for the owner this screen is for.
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visible.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final product = visible[index];

                return _ProductRow(
                  product: product,
                  image: rowImages[product.row],
                  price: priceOf(product),
                  stock: stockOf(product),
                  onPriceChanged: (value) => onPriceChanged(product.row, value),
                  onStockChanged: (value) => onStockChanged(product.row, value),
                  onPickImage: () => onPickImage(product),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final ExcelProductPreview product;
  final ExcelRowImage? image;
  final String price;
  final String stock;
  final ValueChanged<String> onPriceChanged;
  final ValueChanged<String> onStockChanged;
  final VoidCallback onPickImage;

  const _ProductRow({
    required this.product,
    required this.image,
    required this.price,
    required this.stock,
    required this.onPriceChanged,
    required this.onStockChanged,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;

    final imageUrl = image?.url ?? product.imageUrl;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(tokens.card.radius),
        border: Border.all(
          color: product.valid ? colors.border : colors.danger,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumbnail(url: imageUrl, onTap: onPickImage),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.label,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (product.sku != null && product.sku!.trim().isNotEmpty)
                      Text(
                        product.sku!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: colors.muted),
                      ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onPickImage,
                icon: const Icon(Icons.image_outlined, size: 16),
                label: Text(l10n.excelPreviewPickImage),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _NumberField(
                  // Keyed by row so the field belongs to this product and not to
                  // whatever the filter puts at this position next.
                  key: ValueKey('price-${product.row}'),
                  label: l10n.excelPreviewPriceLabel,
                  value: price,
                  decimal: true,
                  onChanged: onPriceChanged,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _NumberField(
                  key: ValueKey('stock-${product.row}'),
                  label: l10n.excelPreviewStockLabel,
                  value: stock,
                  decimal: false,
                  onChanged: onStockChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String? url;
  final VoidCallback onTap;

  const _Thumbnail({required this.url, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: (url == null || url!.trim().isEmpty)
            ? Icon(Icons.add_photo_alternate_outlined,
                size: 20, color: colors.muted)
            : Image.network(
                url!,
                fit: BoxFit.cover,
                // A picture the file linked to may be gone or unreachable; the
                // row still has to draw.
                errorBuilder: (_, __, ___) => Icon(
                  Icons.broken_image_outlined,
                  size: 20,
                  color: colors.muted,
                ),
              ),
      ),
    );
  }
}

class _NumberField extends StatefulWidget {
  final String label;
  final String value;
  final bool decimal;
  final ValueChanged<String> onChanged;

  const _NumberField({
    super.key,
    required this.label,
    required this.value,
    required this.decimal,
    required this.onChanged,
  });

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      // A controller, not initialValue: the field is rebuilt on every keystroke
      // as the state updates, and rebuilding it from the value would send the
      // cursor back to the start each time.
      controller: _controller,
      keyboardType: TextInputType.numberWithOptions(decimal: widget.decimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          widget.decimal ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]'),
        ),
      ],
      textInputAction: TextInputAction.next,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        filled: true,
        isDense: true,
      ),
    );
  }
}
