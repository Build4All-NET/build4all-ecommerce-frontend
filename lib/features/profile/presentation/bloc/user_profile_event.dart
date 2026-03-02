abstract class UserProfileEvent {
  const UserProfileEvent();
}

class LoadUserProfile extends UserProfileEvent {
  final String token;
  final int userId;
  

  const LoadUserProfile(this.token, this.userId);
}




class ToggleVisibilityPressed extends UserProfileEvent {
  final String token;
  final bool newValue;
  const ToggleVisibilityPressed(this.token, this.newValue);
}

class UpdateStatusPressed extends UserProfileEvent {
  final String token;
  final int userId;
  final String status;
  final String? password;

  const UpdateStatusPressed(
    this.token,
    this.userId,
    this.status, {
    this.password,
  });
}