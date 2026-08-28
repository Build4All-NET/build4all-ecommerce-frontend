import '../../domain/entities/gallery_image.dart';

class GalleryState {
  final List<GalleryImage> images;
  final int page;
  final int total;
  final bool hasMore;

  final bool loading;
  final bool loadingMore;
  final bool uploading;
  final int? deletingId;

  final String? errorMessage;

  /// Shown once after an upload: how many landed, and what did not.
  final int? lastUploadedCount;
  final List<String> lastUploadFailures;

  const GalleryState({
    this.images = const [],
    this.page = 0,
    this.total = 0,
    this.hasMore = false,
    this.loading = false,
    this.loadingMore = false,
    this.uploading = false,
    this.deletingId,
    this.errorMessage,
    this.lastUploadedCount,
    this.lastUploadFailures = const [],
  });

  factory GalleryState.initial() => const GalleryState(loading: true);

  bool get isEmpty => images.isEmpty && !loading;

  GalleryState copyWith({
    List<GalleryImage>? images,
    int? page,
    int? total,
    bool? hasMore,
    bool? loading,
    bool? loadingMore,
    bool? uploading,
    int? deletingId,
    bool clearDeletingId = false,
    String? errorMessage,
    bool clearError = false,
    int? lastUploadedCount,
    List<String>? lastUploadFailures,
    bool clearNotice = false,
  }) {
    return GalleryState(
      images: images ?? this.images,
      page: page ?? this.page,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      uploading: uploading ?? this.uploading,
      deletingId: clearDeletingId ? null : (deletingId ?? this.deletingId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastUploadedCount:
          clearNotice ? null : (lastUploadedCount ?? this.lastUploadedCount),
      lastUploadFailures:
          clearNotice ? const [] : (lastUploadFailures ?? this.lastUploadFailures),
    );
  }
}
