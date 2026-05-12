import '../../domain/entities/owner_announcement.dart';

abstract class OwnerAnnouncementEvent {
  const OwnerAnnouncementEvent();
}

class LoadOwnerAnnouncements extends OwnerAnnouncementEvent {
  const LoadOwnerAnnouncements();
}

class CreateOwnerAnnouncementRequested extends OwnerAnnouncementEvent {
  final String title;
  final String message;
  final String announcementType;
  final int? targetId;
  final String? imagePath;

  const CreateOwnerAnnouncementRequested({
    required this.title,
    required this.message,
    required this.announcementType,
    this.targetId,
    this.imagePath,
  });
}

class DeleteOwnerAnnouncementRequested extends OwnerAnnouncementEvent {
  final int announcementId;

  const DeleteOwnerAnnouncementRequested({
    required this.announcementId,
  });
}

class OwnerAnnouncementCreatedLocally extends OwnerAnnouncementEvent {
  final OwnerAnnouncement announcement;

  const OwnerAnnouncementCreatedLocally({
    required this.announcement,
  });
}