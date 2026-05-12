import 'package:bloc/bloc.dart';

import '../../domain/usecases/create_owner_announcement.dart';
import '../../domain/usecases/delete_owner_announcement.dart';
import '../../domain/usecases/get_owner_announcements.dart';
import 'owner_announcement_event.dart';
import 'owner_announcement_state.dart';

class OwnerAnnouncementBloc
    extends Bloc<OwnerAnnouncementEvent, OwnerAnnouncementState> {
  final GetOwnerAnnouncements getAnnouncementsUc;
  final CreateOwnerAnnouncement createAnnouncementUc;
  final DeleteOwnerAnnouncement deleteAnnouncementUc;

  OwnerAnnouncementBloc({
    required this.getAnnouncementsUc,
    required this.createAnnouncementUc,
    required this.deleteAnnouncementUc,
  }) : super(OwnerAnnouncementState.initial()) {
    on<LoadOwnerAnnouncements>(_onLoad);
    on<CreateOwnerAnnouncementRequested>(_onCreate);
    on<DeleteOwnerAnnouncementRequested>(_onDelete);
    on<OwnerAnnouncementCreatedLocally>(_onCreatedLocally);
  }

  Future<void> _onLoad(
    LoadOwnerAnnouncements event,
    Emitter<OwnerAnnouncementState> emit,
  ) async {
    emit(
      state.copyWith(
        loading: true,
        clearError: true,
        clearSuccess: true,
      ),
    );

    try {
      final announcements = await getAnnouncementsUc();

      emit(
        state.copyWith(
          loading: false,
          announcements: announcements,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          loading: false,
          error: _cleanError(e),
        ),
      );
    }
  }

  Future<void> _onCreate(
  CreateOwnerAnnouncementRequested event,
  Emitter<OwnerAnnouncementState> emit,
) async {
  emit(
    state.copyWith(
      submitting: true,
      clearError: true,
      clearSuccess: true,
    ),
  );

  try {
    final created = await createAnnouncementUc(
      title: event.title,
      message: event.message,
      announcementType: event.announcementType,
      targetId: event.targetId,
      imagePath: event.imagePath,
    );

    final updated = [created, ...state.announcements];

    emit(
      state.copyWith(
        submitting: false,
        announcements: updated,
        successMessage: 'created',
        clearError: true,
      ),
    );
  } catch (e) {
    emit(
      state.copyWith(
        submitting: false,
        error: _cleanError(e),
      ),
    );
  }
}

  Future<void> _onDelete(
    DeleteOwnerAnnouncementRequested event,
    Emitter<OwnerAnnouncementState> emit,
  ) async {
    emit(
      state.copyWith(
        deleting: true,
        clearError: true,
        clearSuccess: true,
      ),
    );

    try {
      await deleteAnnouncementUc(event.announcementId);

      final updated = state.announcements
          .where((item) => item.id != event.announcementId)
          .toList();

      emit(
        state.copyWith(
          deleting: false,
          announcements: updated,
          successMessage: 'deleted',
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          deleting: false,
          error: _cleanError(e),
        ),
      );
    }
  }

  void _onCreatedLocally(
    OwnerAnnouncementCreatedLocally event,
    Emitter<OwnerAnnouncementState> emit,
  ) {
    emit(
      state.copyWith(
        announcements: [event.announcement, ...state.announcements],
      ),
    );
  }

  String _cleanError(Object e) {
    return e.toString().replaceFirst('Exception: ', '').trim();
  }
}