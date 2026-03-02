import '../entities/user_profile.dart';
import '../repositories/user_profile_repository.dart';

class GetUserById {
  final UserProfileRepository repo;
  GetUserById(this.repo);

  Future<UserProfile> call({
    required String token,
    required int userId,
  }) {
    return repo.getById(token: token, userId: userId);
  }
}