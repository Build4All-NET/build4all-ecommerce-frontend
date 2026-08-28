import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/common/widgets/app_toast.dart';
import 'package:build4front/l10n/app_localizations.dart';

import '../../domain/entities/gallery_image.dart';
import '../../gallery_locator.dart';
import '../bloc/gallery_bloc.dart';
import '../bloc/gallery_event.dart';
import '../bloc/gallery_state.dart';
import 'gallery_empty_state.dart';
import 'gallery_grid.dart';

/// Picks one image out of the gallery, without leaving the screen that asked.
///
/// Uploading is offered here as well as on the gallery screen: an owner who
/// discovers mid-review that a product's picture was never uploaded should not
/// have to abandon the import and start over.
class GalleryPickerSheet {
  const GalleryPickerSheet._();

  /// Returns the chosen image, [GalleryPickerResult.cleared] when the owner
  /// removed the current one, or null when they dismissed the sheet.
  static Future<GalleryPickerResult?> show(
    BuildContext context, {
    required Future<String?> Function() getToken,
    int? selectedId,
    bool allowClear = false,
  }) {
    return showModalBottomSheet<GalleryPickerResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BlocProvider(
        create: (_) => createGalleryBloc(getToken: getToken),
        child: _GalleryPickerView(
          selectedId: selectedId,
          allowClear: allowClear,
        ),
      ),
    );
  }
}

/// What the sheet came back with. A cleared selection has to be distinguishable
/// from a dismissal, which is why this is not just a nullable image.
class GalleryPickerResult {
  final GalleryImage? image;

  const GalleryPickerResult(this.image);

  static const cleared = GalleryPickerResult(null);

  bool get isCleared => image == null;
}

class _GalleryPickerView extends StatelessWidget {
  final int? selectedId;
  final bool allowClear;

  const _GalleryPickerView({this.selectedId, required this.allowClear});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return BlocConsumer<GalleryBloc, GalleryState>(
          listenWhen: (p, c) =>
              p.errorMessage != c.errorMessage ||
              p.lastUploadedCount != c.lastUploadedCount,
          listener: (context, state) {
            if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
              AppToast.error(context, state.errorMessage!);
            }

            final uploaded = state.lastUploadedCount;
            if (uploaded != null) {
              if (uploaded > 0) {
                AppToast.success(context, l10n.galleryUploadedCount(uploaded));
              }
              context.read<GalleryBloc>().add(const GalleryNoticeCleared());
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.galleryPickTitle,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (allowClear)
                        TextButton(
                          onPressed: () => Navigator.of(context)
                              .pop(GalleryPickerResult.cleared),
                          child: Text(l10n.excelPreviewRemoveImage),
                        ),
                      IconButton(
                        tooltip: l10n.galleryUploadButton,
                        onPressed: state.uploading
                            ? null
                            : () => context
                                .read<GalleryBloc>()
                                .add(const GalleryUploadRequested()),
                        icon: state.uploading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.add_photo_alternate_outlined),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(child: _content(context, state, scrollController, l10n)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _content(
    BuildContext context,
    GalleryState state,
    ScrollController scrollController,
    AppLocalizations l10n,
  ) {
    if (state.loading && state.images.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.isEmpty) {
      // The sheet still scrolls so it can be dragged shut on a short screen.
      return ListView(
        controller: scrollController,
        children: [
          const SizedBox(height: 32),
          GalleryEmptyState(
            title: l10n.galleryEmptyTitle,
            message: l10n.galleryPickEmpty,
            action: FilledButton.icon(
              onPressed: state.uploading
                  ? null
                  : () => context
                      .read<GalleryBloc>()
                      .add(const GalleryUploadRequested()),
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(l10n.galleryUploadButton),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: GalleryGrid(
            images: state.images,
            controller: scrollController,
            selectedId: selectedId,
            onTap: (image) =>
                Navigator.of(context).pop(GalleryPickerResult(image)),
          ),
        ),
        if (state.hasMore)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextButton(
              onPressed: state.loadingMore
                  ? null
                  : () => context
                      .read<GalleryBloc>()
                      .add(const GalleryNextPageRequested()),
              child: Text(
                state.loadingMore ? l10n.galleryUploading : l10n.galleryLoadMore,
              ),
            ),
          ),
      ],
    );
  }
}
