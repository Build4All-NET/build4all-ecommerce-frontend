import '../entities/home_banner.dart';
import '../repositories/home_banner_repository.dart';

class UpdateHomeBanner {
  final HomeBannerRepository repo;
  UpdateHomeBanner(this.repo);

  Future<HomeBanner> call({
    required int id,
    required Map<String, dynamic> body,
    required String token,
    String? imagePath,
  }) {
    return repo.updateWithImage(
      id: id,
      body: body,
      token: token,
      imagePath: imagePath,
    );
  }
}