import 'package:flutter_bloc/flutter_bloc.dart';

import 'data/repositories/gallery_repository_impl.dart';
import 'data/services/gallery_api_service.dart';
import 'domain/usecases/delete_gallery_image.dart';
import 'domain/usecases/list_gallery_images.dart';
import 'domain/usecases/upload_gallery_images.dart';
import 'presentation/bloc/gallery_bloc.dart';
import 'presentation/bloc/gallery_event.dart';

/// Builds the gallery bloc with its dependencies.
///
/// Kept in one place because the gallery is opened from two directions — its own
/// screen and the picker the Excel import raises — and the two must not drift
/// into assembling it differently.
GalleryBloc createGalleryBloc({
  required Future<String?> Function() getToken,
  bool loadImmediately = true,
}) {
  final repo = GalleryRepositoryImpl(
    api: GalleryApiService(getToken: getToken),
  );

  final bloc = GalleryBloc(
    listUc: ListGalleryImages(repo),
    uploadUc: UploadGalleryImages(repo),
    deleteUc: DeleteGalleryImage(repo),
  );

  if (loadImmediately) {
    bloc.add(const GalleryOpened());
  }

  return bloc;
}
