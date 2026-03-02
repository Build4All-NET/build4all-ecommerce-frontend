import '../entities/home_banner.dart';
import '../repositories/home_banner_repository.dart';

class CreateHomeBanner {
  final HomeBannerRepository repo;
  CreateHomeBanner(this.repo);

  Future<HomeBanner> call({
    required Map<String, dynamic> body,
    required String token,
    required String imagePath,
  }) {
    return repo.createWithImage(body: body, token: token, imagePath: imagePath);
  }
}