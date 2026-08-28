import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/common/widgets/app_toast.dart';
import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';

import '../../domain/entities/gallery_image.dart';
import '../bloc/gallery_bloc.dart';
import '../bloc/gallery_event.dart';
import '../bloc/gallery_state.dart';
import '../widgets/gallery_empty_state.dart';
import '../widgets/gallery_grid.dart';

/// The owner's picture library.
///
/// Its whole reason for existing is bulk: the owner uploads everything they have
/// in one pass, and every other screen — the Excel import above all — then only
/// has to let them point at one.
class AdminGalleryScreen extends StatefulWidget {
  const AdminGalleryScreen({super.key});

  @override
  State<AdminGalleryScreen> createState() => _AdminGalleryScreenState();
}

class _AdminGalleryScreenState extends State<AdminGalleryScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;

    final remaining = _scroll.position.maxScrollExtent - _scroll.position.pixels;
    if (remaining < 400) {
      context.read<GalleryBloc>().add(const GalleryNextPageRequested());
    }
  }

  Future<void> _confirmDelete(GalleryImage image) async {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<GalleryBloc>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.galleryDeleteTitle),
        content: Text(l10n.galleryDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.galleryCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.galleryDeleteConfirm),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      bloc.add(GalleryImageDeleted(image.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.watch<ThemeCubit>().state.tokens.colors;

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
          if (state.lastUploadFailures.isNotEmpty) {
            AppToast.error(
              context,
              l10n.gallerySomeFailed(state.lastUploadFailures.length),
            );
          }
          context.read<GalleryBloc>().add(const GalleryNoticeCleared());
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: colors.background,
          appBar: AppBar(
            backgroundColor: colors.surface,
            elevation: 0,
            title: Text(
              l10n.adminGalleryTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.label,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            bottom: state.images.isEmpty
                ? null
                : PreferredSize(
                    preferredSize: const Size.fromHeight(28),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 8),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          l10n.galleryImageCount(state.total),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colors.label.withValues(alpha: 0.7),
                              ),
                        ),
                      ),
                    ),
                  ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: state.uploading
                ? null
                : () => context.read<GalleryBloc>().add(const GalleryUploadRequested()),
            icon: state.uploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_photo_alternate_outlined),
            label: Text(
              state.uploading ? l10n.galleryUploading : l10n.galleryUploadButton,
            ),
          ),
          body: _body(context, state, l10n),
        );
      },
    );
  }

  Widget _body(BuildContext context, GalleryState state, AppLocalizations l10n) {
    if (state.loading && state.images.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.isEmpty) {
      return GalleryEmptyState(
        title: l10n.galleryEmptyTitle,
        message: l10n.galleryEmptyMessage,
        action: FilledButton.icon(
          onPressed: state.uploading
              ? null
              : () => context.read<GalleryBloc>().add(const GalleryUploadRequested()),
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text(l10n.galleryUploadButton),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => context.read<GalleryBloc>().add(const GalleryRefreshed()),
      child: Column(
        children: [
          Expanded(
            child: GalleryGrid(
              images: state.images,
              busyId: state.deletingId,
              controller: _scroll,
              // Space for the extended FAB, so the last row is never trapped
              // underneath it.
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              onDelete: _confirmDelete,
            ),
          ),
          if (state.loadingMore)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }
}
