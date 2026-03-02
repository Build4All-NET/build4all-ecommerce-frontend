import 'package:build4front/features/auth/domain/entities/user_entity.dart';

abstract class UserProfileRepository {
  Future<UserEntity> getProfile({
    required String token,
    required int userId,
  });

  Future<void> setVisibility({
    required String token,
    required bool isPublic,
  });

  Future<void> setStatus({
    required String token,
    required int userId,
    required String status,
    String? password,
  });
}