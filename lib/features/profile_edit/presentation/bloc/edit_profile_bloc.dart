// lib/features/profile_edit/presentation/bloc/edit_profile_bloc.dart
import 'package:build4front/core/exceptions/exception_mapper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_user_by_id.dart';
import '../../domain/usecases/update_user_profile.dart';
import '../../domain/usecases/delete_user.dart';
import '../../domain/usecases/verify_email_change.dart';
import '../../domain/usecases/resend_email_change.dart';

import 'edit_profile_event.dart';
import 'edit_profile_state.dart';

class EditProfileBloc extends Bloc<EditProfileEvent, EditProfileState> {
  final GetUserById getUserById;
  final UpdateUserProfile updateUserProfile;
  final DeleteUser deleteUser;

  final VerifyEmailChange verifyEmailChange;
  final ResendEmailChange resendEmailChange;

  EditProfileBloc({
    required this.getUserById,
    required this.updateUserProfile,
    required this.deleteUser,
    required this.verifyEmailChange,
    required this.resendEmailChange,
  }) : super(EditProfileState.initial) {
    on<LoadEditProfile>(_onLoad);
    on<SaveEditProfile>(_onSave);
    on<DeleteAccount>(_onDelete);
  }

  Future<void> _onLoad(
    LoadEditProfile e,
    Emitter<EditProfileState> emit,
  ) async {
    emit(
      state.copyWith(
        loading: true,
        error: null,
        success: null,
        didDelete: false,
      ),
    );

    try {
      final user = await getUserById(token: e.token, userId: e.userId);
      emit(
        state.copyWith(
          loading: false,
          user: user,
          error: null,
        ),
      );
    } catch (err) {
      emit(
        state.copyWith(
          loading: false,
          error: ExceptionMapper.toMessage(err),
        ),
      );
    }
  }

  Future<void> _onSave(
    SaveEditProfile e,
    Emitter<EditProfileState> emit,
  ) async {
    emit(
      state.copyWith(
        saving: true,
        error: null,
        success: null,
        didDelete: false,
      ),
    );

    try {
      final updated = await updateUserProfile(
        token: e.token,
        userId: e.userId,
        firstName: e.firstName,
        lastName: e.lastName,
        username: e.username,
        email: e.email,
        isPublicProfile: e.isPublicProfile,
        imageFilePath: e.imageFilePath,
        imageRemoved: e.imageRemoved,
      );

      emit(
        state.copyWith(
          saving: false,
          user: updated,
          success: null,
          error: null,
        ),
      );
    } catch (err) {
      emit(
        state.copyWith(
          saving: false,
          error: ExceptionMapper.toMessage(err),
        ),
      );
    }
  }

  Future<void> verifyEmailChangeDirect({
    required String token,
    required int userId,
    required String code,
  }) async {
    await verifyEmailChange(token: token, userId: userId, code: code);
  }

  Future<void> resendEmailChangeDirect({
    required String token,
    required int userId,
  }) async {
    await resendEmailChange(token: token, userId: userId);
  }

  Future<void> _onDelete(
    DeleteAccount e,
    Emitter<EditProfileState> emit,
  ) async {
    emit(
      state.copyWith(
        deleting: true,
        error: null,
        success: null,
        didDelete: false,
      ),
    );

    try {
      await deleteUser(token: e.token, userId: e.userId, password: e.password);
      emit(
        state.copyWith(
          deleting: false,
          didDelete: true,
          success: null,
          error: null,
        ),
      );
    } catch (err) {
      emit(
        state.copyWith(
          deleting: false,
          error: ExceptionMapper.toMessage(err),
        ),
      );
    }
  }
}