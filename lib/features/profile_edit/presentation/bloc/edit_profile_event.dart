abstract class EditProfileEvent {}

class LoadEditProfile extends EditProfileEvent {
  final String token;
  final int userId;

  LoadEditProfile({required this.token, required this.userId});
}

class SaveEditProfile extends EditProfileEvent {
  final String token;
  final int userId;

  final String firstName;
  final String lastName;
  final String? username;
  final String? email;
  final bool isPublicProfile;

  final String? imageFilePath;
  final bool imageRemoved;

  SaveEditProfile({
    required this.token,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.isPublicProfile,
    this.username,
    this.email,
    this.imageFilePath,
    this.imageRemoved = false,
  });
}

class DeleteAccount extends EditProfileEvent {
  final String token;
  final int userId;
  final String password;

  DeleteAccount({required this.token, required this.userId, required this.password});
}