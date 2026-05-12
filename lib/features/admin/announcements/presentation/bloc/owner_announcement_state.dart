import '../../domain/entities/owner_announcement.dart';

class OwnerAnnouncementState {
  final bool loading;
  final bool submitting;
  final bool deleting;
  final List<OwnerAnnouncement> announcements;
  final String? error;
  final String? successMessage;

  const OwnerAnnouncementState({
    required this.loading,
    required this.submitting,
    required this.deleting,
    required this.announcements,
    this.error,
    this.successMessage,
  });

  factory OwnerAnnouncementState.initial() {
    return const OwnerAnnouncementState(
      loading: false,
      submitting: false,
      deleting: false,
      announcements: [],
      error: null,
      successMessage: null,
    );
  }

  OwnerAnnouncementState copyWith({
    bool? loading,
    bool? submitting,
    bool? deleting,
    List<OwnerAnnouncement>? announcements,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return OwnerAnnouncementState(
      loading: loading ?? this.loading,
      submitting: submitting ?? this.submitting,
      deleting: deleting ?? this.deleting,
      announcements: announcements ?? this.announcements,
      error: clearError ? null : error ?? this.error,
      successMessage: clearSuccess
          ? null
          : successMessage ?? this.successMessage,
    );
  }
}