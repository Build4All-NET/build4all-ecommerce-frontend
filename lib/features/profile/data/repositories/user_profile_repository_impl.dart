import 'package:build4front/features/auth/domain/entities/user_entity.dart';
import 'package:build4front/features/profile/domain/repositories/user_profile_repository.dart';

import '../models/profile_user_dto.dart';
import '../services/user_profile_service.dart' as svc;

class UserProfileRepositoryImpl implements UserProfileRepository {
  final svc.UserProfileService service;

  UserProfileRepositoryImpl(this.service);

  @override
  Future<UserEntity> getProfile({
    required String token,
    required int userId,
  }) async {
    final map = await service.fetchProfileMap(
      token: token,
      userId: userId,
    );
    final dto = ProfileUserDto.fromMap(map);
    return dto.toEntity();
  }

  @override
  Future<void> setVisibility({
    required String token,
    required bool isPublic,
  }) {
    return service.updateVisibility(
      token: token,
      isPublic: isPublic,
    );
  }

  @override
  Future<void> setStatus({
    required String token,
    required int userId,
    required String status,
    String? password,
  }) {
    return service.updateStatus(
      token: token,
      userId: userId,
      status: status,
      password: password,
    );
  }
}