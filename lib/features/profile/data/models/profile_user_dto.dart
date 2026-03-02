import 'package:build4front/features/auth/domain/entities/user_entity.dart';

class ProfileUserDto {
  final int id;

  /// informational only (do NOT use in requests anymore)
  final int ownerProjectLinkId;

  final String firstName;
  final String lastName;
  final String? email;
  final String? phoneNumber;
  final String? profileImageUrl;
  final bool publicProfile;
  final String? statusName;

  ProfileUserDto({
    required this.id,
    required this.ownerProjectLinkId,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phoneNumber,
    this.profileImageUrl,
    required this.publicProfile,
    this.statusName,
  });

  factory ProfileUserDto.fromMap(Map<String, dynamic> m) {
    final st = m['status'];
    final name = st is Map ? st['name'] as String? : m['status'] as String?;

    final ownerProjectLinkId = (m['ownerProjectLinkId'] as num?)?.toInt() ?? 0;

    final dynamic rawImage = m['profilePictureUrl'] ?? m['profileImageUrl'];

    return ProfileUserDto(
      id: (m['id'] as num).toInt(),
      ownerProjectLinkId: ownerProjectLinkId,
      firstName: '${m['firstName'] ?? ''}',
      lastName: '${m['lastName'] ?? ''}',
      email: m['email'] as String?,
      phoneNumber: m['phoneNumber'] as String?,
      profileImageUrl: rawImage as String?,
      publicProfile:
          (m['publicProfile'] ?? m['isPublicProfile'] ?? false) == true,
      statusName: name,
    );
  }

  UserEntity toEntity() => UserEntity(
        id: id,
        ownerProjectLinkId: ownerProjectLinkId, // keep it on entity, no harm
        username: null,
        firstName: firstName.isEmpty ? null : firstName,
        lastName: lastName.isEmpty ? null : lastName,
        email: email,
        phoneNumber: phoneNumber,
        profilePictureUrl: profileImageUrl,
        isPublicProfile: publicProfile,
        status: statusName,
      );
}