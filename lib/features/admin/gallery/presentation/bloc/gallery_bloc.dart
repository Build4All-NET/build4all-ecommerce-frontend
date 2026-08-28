import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/exceptions/exception_mapper.dart';
import '../../domain/entities/picked_image.dart';
import '../../domain/usecases/delete_gallery_image.dart';
import '../../domain/usecases/list_gallery_images.dart';
import '../../domain/usecases/upload_gallery_images.dart';
import 'gallery_event.dart';
import 'gallery_state.dart';

class GalleryBloc extends Bloc<GalleryEvent, GalleryState> {
  static const _pageSize = 60;

  final ListGalleryImages listUc;
  final UploadGalleryImages uploadUc;
  final DeleteGalleryImage deleteUc;

  GalleryBloc({
    required this.listUc,
    required this.uploadUc,
    required this.deleteUc,
  }) : super(GalleryState.initial()) {
    on<GalleryOpened>((_, emit) => _load(emit));
    on<GalleryRefreshed>((_, emit) => _load(emit));
    on<GalleryNextPageRequested>(_loadMore);
    on<GalleryUploadRequested>(_upload);
    on<GalleryImageDeleted>(_delete);
    on<GalleryNoticeCleared>((_, emit) => emit(state.copyWith(clearNotice: true)));
  }

  Future<void> _load(Emitter<GalleryState> emit) async {
    emit(state.copyWith(loading: true, clearError: true));

    try {
      final page = await listUc(page: 0, size: _pageSize);
      emit(state.copyWith(
        loading: false,
        images: page.items,
        page: page.page,
        total: page.totalElements,
        hasMore: page.hasMore,
      ));
    } catch (e) {
      emit(state.copyWith(loading: false, errorMessage: ExceptionMapper.toMessage(e)));
    }
  }

  Future<void> _loadMore(
    GalleryNextPageRequested event,
    Emitter<GalleryState> emit,
  ) async {
    if (state.loadingMore || !state.hasMore) return;

    emit(state.copyWith(loadingMore: true, clearError: true));

    try {
      final next = await listUc(page: state.page + 1, size: _pageSize);
      emit(state.copyWith(
        loadingMore: false,
        images: [...state.images, ...next.items],
        page: next.page,
        total: next.totalElements,
        hasMore: next.hasMore,
      ));
    } catch (e) {
      emit(state.copyWith(loadingMore: false, errorMessage: ExceptionMapper.toMessage(e)));
    }
  }

  Future<void> _upload(
    GalleryUploadRequested event,
    Emitter<GalleryState> emit,
  ) async {
    emit(state.copyWith(clearError: true, clearNotice: true));

    List<PickedImage> picked;
    try {
      // withData so the bytes come back on every platform: a browser never
      // exposes a path, and reading one there throws.
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      picked = [
        for (final file in result.files)
          if (file.bytes != null) PickedImage(name: file.name, bytes: file.bytes!),
      ];
    } catch (e) {
      emit(state.copyWith(errorMessage: ExceptionMapper.toMessage(e)));
      return;
    }

    if (picked.isEmpty) return;

    emit(state.copyWith(uploading: true));

    try {
      final result = await uploadUc(picked);

      // The new images are prepended rather than refetched: the list is ordered
      // newest first, so this leaves it exactly as a reload would and keeps the
      // owner's scroll position.
      emit(state.copyWith(
        uploading: false,
        images: [...result.uploaded, ...state.images],
        total: state.total + result.uploaded.length,
        lastUploadedCount: result.uploaded.length,
        lastUploadFailures: result.failed,
      ));
    } catch (e) {
      emit(state.copyWith(uploading: false, errorMessage: ExceptionMapper.toMessage(e)));
    }
  }

  Future<void> _delete(
    GalleryImageDeleted event,
    Emitter<GalleryState> emit,
  ) async {
    emit(state.copyWith(deletingId: event.imageId, clearError: true, clearNotice: true));

    try {
      await deleteUc(event.imageId);

      emit(state.copyWith(
        clearDeletingId: true,
        images: state.images.where((i) => i.id != event.imageId).toList(),
        total: state.total > 0 ? state.total - 1 : 0,
      ));
    } catch (e) {
      emit(state.copyWith(
        clearDeletingId: true,
        errorMessage: ExceptionMapper.toMessage(e),
      ));
    }
  }
}
