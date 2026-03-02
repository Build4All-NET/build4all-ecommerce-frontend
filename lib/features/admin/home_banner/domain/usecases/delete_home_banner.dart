import '../repositories/home_banner_repository.dart';

class DeleteHomeBanner {
  final HomeBannerRepository repo;
  DeleteHomeBanner(this.repo);

  Future<void> call({required int id, required String token}) {
    return repo.delete(id: id, token: token);
  }
}