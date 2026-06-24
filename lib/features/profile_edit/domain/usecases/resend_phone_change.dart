import '../repositories/user_profile_repository.dart';

class ResendPhoneChange {
  final UserProfileRepository repo;
  ResendPhoneChange(this.repo);

  Future<void> call({
    required String token,
    required int userId,
  }) {
    return repo.resendPhoneChange(token: token, userId: userId);
  }
}
