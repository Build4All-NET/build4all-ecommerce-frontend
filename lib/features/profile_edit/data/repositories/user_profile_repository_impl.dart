// lib/features/profile_edit/data/repositories/user_profile_repository_impl.dart
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../models/user_profile_model.dart';
import '../services/user_profile_api_service.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  final UserProfileApiService api;
  UserProfileRepositoryImpl(this.api);

  bool _looksLikeUserPayload(Map<String, dynamic> json) {
    return json.containsKey('id') ||
        json.containsKey('userId') ||
        json.containsKey('firstName') ||
        json.containsKey('lastName') ||
        json.containsKey('username');
  }

  @override
  Future<UserProfile> getById({
    required String token,
    required int userId,
  }) async {
    final json = await api.getUserById(token: token, userId: userId);
    return UserProfileModel.fromJson(json);
  }

  @override
  Future<UserProfile> updateProfile({
    required String token,
    required int userId,
    required String firstName,
    required String lastName,
    String? username,
    String? email,
    bool? isPublicProfile,
    String? imageFilePath,
    bool imageRemoved = false,
  }) async {
    final json = await api.updateProfile(
      token: token,
      userId: userId,
      firstName: firstName,
      lastName: lastName,
      username: username,
      email: email,
      isPublicProfile: isPublicProfile,
      imageFilePath: imageFilePath,
      imageRemoved: imageRemoved,
    );

    Map<String, dynamic>? userJson;

    if (json['user'] is Map) {
      userJson = (json['user'] as Map).cast<String, dynamic>();
    } else if (json['data'] is Map) {
      final dataMap = (json['data'] as Map).cast<String, dynamic>();
      if (_looksLikeUserPayload(dataMap)) userJson = dataMap;
    } else if (_looksLikeUserPayload(json)) {
      userJson = json;
    }

    if (userJson != null) {
      final merged = <String, dynamic>{
        ...userJson,
        'emailVerificationRequired': json['emailVerificationRequired'],
        'pendingEmail': json['pendingEmail'],
      };
      return UserProfileModel.fromJson(merged);
    }

    return getById(token: token, userId: userId);
  }

  @override
  Future<void> verifyEmailChange({
    required String token,
    required int userId,
    required String code,
  }) {
    return api.verifyEmailChange(token: token, userId: userId, code: code);
  }

  @override
  Future<void> resendEmailChange({
    required String token,
    required int userId,
  }) {
    return api.resendEmailChange(token: token, userId: userId);
  }

  @override
  Future<void> deleteUser({
    required String token,
    required int userId,
    required String password,
  }) {
    return api.deleteUser(token: token, userId: userId, password: password);
  }
}