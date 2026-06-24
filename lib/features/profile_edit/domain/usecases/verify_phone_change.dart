import '../repositories/user_profile_repository.dart';

class VerifyPhoneChange {
  final UserProfileRepository repo;
  VerifyPhoneChange(this.repo);

  Future<void> call({
    required String token,
    required int userId,
    required String code,
  }) {
    return repo.verifyPhoneChange(token: token, userId: userId, code: code);
  }
}
