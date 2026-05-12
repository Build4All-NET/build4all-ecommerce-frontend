import '../repositories/owner_announcement_repository.dart';

class DeleteOwnerAnnouncement {
  final OwnerAnnouncementRepository repository;

  DeleteOwnerAnnouncement(this.repository);

  Future<void> call(int announcementId) {
    return repository.deleteAnnouncement(announcementId);
  }
}