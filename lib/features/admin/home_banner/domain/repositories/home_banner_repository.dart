import '../entities/home_banner.dart';

abstract class HomeBannerRepository {
  Future<List<HomeBanner>> listActivePublic({
    required String token,
  });

  Future<List<HomeBanner>> listForAdmin({
    required String token,
  });

  Future<HomeBanner> createWithImage({
    required Map<String, dynamic> body,
    required String token,
    String? imagePath,
    String? galleryImageUrl,
  });

  Future<HomeBanner> updateWithImage({
    required int id,
    required Map<String, dynamic> body,
    required String token,
    String? imagePath,
    String? galleryImageUrl,
  });

  Future<void> delete({required int id, required String token});
}