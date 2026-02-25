import '../../domain/entities/user_profile.dart';

class EditProfileState {
  final bool loading;
  final bool saving;
  final bool deleting;
  final bool didDelete;
  final UserProfile? user;
  final String? error;
  final String? success;

  const EditProfileState({
    this.loading = false,
    this.saving = false,
    this.deleting = false,
    this.didDelete = false,
    this.user,
    this.error,
    this.success,
  });

  EditProfileState copyWith({
    bool? loading,
    bool? saving,
    bool? deleting,
    bool? didDelete,
    UserProfile? user,
    String? error,
    String? success,
  }) {
    return EditProfileState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      deleting: deleting ?? this.deleting,
      didDelete: didDelete ?? this.didDelete,
      user: user ?? this.user,
      error: error,
      success: success,
    );
  }

  static const initial = EditProfileState();
}