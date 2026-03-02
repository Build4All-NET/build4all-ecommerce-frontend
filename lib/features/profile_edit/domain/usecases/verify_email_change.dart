import '../repositories/user_profile_repository.dart';

class VerifyEmailChange {
  final UserProfileRepository repo;
  VerifyEmailChange(this.repo);

  Future<void> call({
    required String token,
    required int userId,
    required String code,
  }) {
    return repo.verifyEmailChange(token: token, userId: userId, code: code);
  }
}