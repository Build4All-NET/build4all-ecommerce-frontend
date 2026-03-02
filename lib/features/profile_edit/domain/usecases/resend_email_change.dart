import '../repositories/user_profile_repository.dart';

class ResendEmailChange {
  final UserProfileRepository repo;
  ResendEmailChange(this.repo);

  Future<void> call({
    required String token,
    required int userId,
  }) {
    return repo.resendEmailChange(token: token, userId: userId);
  }
}