import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/photographed_product.dart';

/// Photographing a shop into a catalogue.
///
/// Two jobs, kept apart on purpose. Taking pictures is the first, and it is
/// deliberately just a button pressed once per thing on the shelf -- no form, no
/// questions. Everything the assistant made of them is the second, below, where
/// the owner corrects a name and puts in the one thing no photograph can tell
/// us: what they want for it.
class ExcelPhotoCaptureCard extends StatelessWidget {
  final List<PhotographedProduct> photos;
  final List<PhotographedProduct> needingName;
  final bool reading;

  final String Function(PhotographedProduct) priceOf;
  final String Function(PhotographedProduct) stockOf;
  final String Function(PhotographedProduct) descriptionOf;

  final VoidCallback onTakePhoto;
  final VoidCallback onPickFromGallery;
  final void Function(int photoIndex, String name) onNameChanged;
  final void Function(int photoIndex, String price) onPriceChanged;
  final void Function(int photoIndex, String stock) onStockChanged;
  final void Function(int photoIndex, String description) onDescriptionChanged;
  final void Function(int photoIndex) onRemove;

  const ExcelPhotoCaptureCard({
    super.key,
    required this.photos,
    required this.needingName,
    required this.reading,
    required this.priceOf,
    required this.stockOf,
    required this.descriptionOf,
    required this.onTakePhoto,
    required this.onPickFromGallery,
    required this.onNameChanged,
    required this.onPriceChanged,
    required this.onStockChanged,
    required this.onDescriptionChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: reading ? null : onTakePhoto,
                icon: const Icon(Icons.photo_camera_outlined, size: 18),
                label: Text(photos.isEmpty
                    ? l10n.excelPhotosTakeBtn
                    : l10n.excelPhotosAddMore),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: reading ? null : onPickFromGallery,
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: Text(l10n.excelPhotosPickBtn),
              ),
            ),
          ],
        ),

        if (reading) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.excelPhotosReading,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colors.body),
              ),
            ],
          ),
        ],

        if (photos.isEmpty && !reading) ...[
          const SizedBox(height: 10),
          Text(
            l10n.excelPhotosEmpty,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colors.muted),
          ),
        ],

        // The one thing that stands between the owner and the button: a product
        // with no name cannot be created, and only they can supply it.
        if (needingName.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            l10n.excelPhotosNeedNames(needingName.length),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.danger,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],

        for (final photo in photos) ...[
          const SizedBox(height: 10),
          _PhotoRow(
            photo: photo,
            price: priceOf(photo),
            stock: stockOf(photo),
            description: descriptionOf(photo),
            onNameChanged: (value) => onNameChanged(photo.photoIndex, value),
            onPriceChanged: (value) => onPriceChanged(photo.photoIndex, value),
            onStockChanged: (value) => onStockChanged(photo.photoIndex, value),
            onDescriptionChanged: (value) =>
                onDescriptionChanged(photo.photoIndex, value),
            onRemove: () => onRemove(photo.photoIndex),
          ),
        ],
      ],
    );
  }
}

class _PhotoRow extends StatelessWidget {
  final PhotographedProduct photo;
  final String price;
  final String stock;
  final String description;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onPriceChanged;
  final ValueChanged<String> onStockChanged;
  final ValueChanged<String> onDescriptionChanged;
  final VoidCallback onRemove;

  const _PhotoRow({
    required this.photo,
    required this.price,
    required this.stock,
    required this.description,
    required this.onNameChanged,
    required this.onPriceChanged,
    required this.onStockChanged,
    required this.onDescriptionChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(tokens.card.radius),
        border: Border.all(
          color: photo.needsName ? colors.danger : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: (photo.imageUrl == null || photo.imageUrl!.isEmpty)
                      ? Container(color: colors.background)
                      : Image.network(
                          photo.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.broken_image_outlined,
                            size: 20,
                            color: colors.muted,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TextField(
                  key: ValueKey('photo-name-${photo.photoIndex}'),
                  label: l10n.excelPhotosNameLabel,
                  // What the assistant read, already in the field: correcting a
                  // word beats typing a name from nothing.
                  value: photo.name,
                  hint: photo.needsName ? l10n.excelPhotosNameMissing : null,
                  onChanged: onNameChanged,
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 18),
                tooltip: l10n.excelPhotosRemove,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TextField(
                  key: ValueKey('photo-price-${photo.photoIndex}'),
                  label: l10n.excelPreviewPriceLabel,
                  value: price,
                  numeric: true,
                  onChanged: onPriceChanged,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TextField(
                  key: ValueKey('photo-stock-${photo.photoIndex}'),
                  label: l10n.excelPreviewStockLabel,
                  value: stock,
                  numeric: true,
                  onChanged: onStockChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _TextField(
            key: ValueKey('photo-description-${photo.photoIndex}'),
            label: l10n.excelPreviewDescriptionLabel,
            value: description,
            lines: 2,
            onChanged: onDescriptionChanged,
          ),
        ],
      ),
    );
  }
}

class _TextField extends StatefulWidget {
  final String label;
  final String? hint;
  final String value;
  final bool numeric;
  final int lines;
  final ValueChanged<String> onChanged;

  const _TextField({
    super.key,
    required this.label,
    this.hint,
    required this.value,
    this.numeric = false,
    this.lines = 1,
    required this.onChanged,
  });

  @override
  State<_TextField> createState() => _TextFieldState();
}

class _TextFieldState extends State<_TextField> {
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
      // A controller, not initialValue: the field is rebuilt as the owner types
      // and rebuilding it from the value would send the cursor to the start.
      controller: _controller,
      keyboardType: widget.numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      minLines: widget.lines,
      maxLines: widget.lines,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        filled: true,
        isDense: true,
      ),
    );
  }
}
