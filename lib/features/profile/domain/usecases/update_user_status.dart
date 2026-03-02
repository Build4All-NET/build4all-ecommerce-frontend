import '../repositories/user_profile_repository.dart';

class UpdateUserStatus {
  final UserProfileRepository repo;
  UpdateUserStatus(this.repo);

  Future<void> call({
    required String token,
    required int userId,
    required String status,
    String? password,
  }) =>
      repo.setStatus(
        token: token,
        userId: userId,
        status: status,
        password: password,
      );
}