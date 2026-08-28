abstract class GalleryEvent {
  const GalleryEvent();
}

/// First load, and the pull-to-refresh path.
class GalleryOpened extends GalleryEvent {
  const GalleryOpened();
}

class GalleryRefreshed extends GalleryEvent {
  const GalleryRefreshed();
}

class GalleryNextPageRequested extends GalleryEvent {
  const GalleryNextPageRequested();
}

/// Opens the file picker and uploads whatever the owner selected.
class GalleryUploadRequested extends GalleryEvent {
  const GalleryUploadRequested();
}

class GalleryImageDeleted extends GalleryEvent {
  final int imageId;

  const GalleryImageDeleted(this.imageId);
}

/// Clears the one-shot banner so it does not reappear on the next rebuild.
class GalleryNoticeCleared extends GalleryEvent {
  const GalleryNoticeCleared();
}
