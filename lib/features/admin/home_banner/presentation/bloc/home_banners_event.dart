abstract class HomeBannersEvent {}

class LoadAdminBanners extends HomeBannersEvent {
  final String token;
  LoadAdminBanners({required this.token});
}

class CreateBannerEvent extends HomeBannersEvent {
  final Map<String, dynamic> body;
  final String imagePath;
  final String token;

  CreateBannerEvent({
    required this.body,
    required this.imagePath,
    required this.token,
  });
}

class UpdateBannerEvent extends HomeBannersEvent {
  final int id;
  final Map<String, dynamic> body;
  final String? imagePath;
  final String token;

  UpdateBannerEvent({
    required this.id,
    required this.body,
    required this.token,
    this.imagePath,
  });
}

class DeleteBannerEvent extends HomeBannersEvent {
  final int id;
  final String token;

  DeleteBannerEvent({
    required this.id,
    required this.token,
  });
}