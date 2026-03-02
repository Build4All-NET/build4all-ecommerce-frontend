import 'package:build4front/features/auth/domain/entities/user_entity.dart';
import '../repositories/user_profile_repository.dart';

class GetUserProfile {
  final UserProfileRepository repo;
  GetUserProfile(this.repo);

  Future<UserEntity> call({
    required String token,
    required int userId,
  }) =>
      repo.getProfile(token: token, userId: userId);
}