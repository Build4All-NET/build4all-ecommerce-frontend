import '../repositories/user_profile_repository.dart';

class RequestPhoneChange {
  final UserProfileRepository repo;
  RequestPhoneChange(this.repo);

  Future<void> call({
    required String token,
    required int userId,
    required String newPhone,
  }) {
    return repo.requestPhoneChange(
      token: token,
      userId: userId,
      newPhone: newPhone,
    );
  }
}
