import '../../domain/entities/home_banner.dart';
import '../../domain/repositories/home_banner_repository.dart';
import '../models/home_banner_model.dart';
import '../services/home_banner_api_service.dart';

class HomeBannerRepositoryImpl implements HomeBannerRepository {
  final HomeBannerApiService api;

  HomeBannerRepositoryImpl(this.api);

  @override
  Future<List<HomeBanner>> listActivePublic({
    required String token,
  }) async {
    final list = await api.listActivePublic(authToken: token);
    return list.map((e) => HomeBannerModel.fromJson(e)).toList();
  }

  @override
  Future<List<HomeBanner>> listForAdmin({
    required String token,
  }) async {
    final list = await api.listForAdmin(authToken: token);
    return list.map((e) => HomeBannerModel.fromJson(e)).toList();
  }

  @override
  Future<HomeBanner> createWithImage({
    required Map<String, dynamic> body,
    required String token,
    required String imagePath,
  }) async {
    final json = await api.createWithImage(
      body: body,
      authToken: token,
      imagePath: imagePath,
    );
    return HomeBannerModel.fromJson(json);
  }

  @override
  Future<HomeBanner> updateWithImage({
    required int id,
    required Map<String, dynamic> body,
    required String token,
    String? imagePath,
  }) async {
    final json = await api.updateWithImage(
      id: id,
      body: body,
      authToken: token,
      imagePath: imagePath,
    );
    return HomeBannerModel.fromJson(json);
  }

  @override
  Future<void> delete({required int id, required String token}) {
    return api.delete(id: id, authToken: token);
  }
}