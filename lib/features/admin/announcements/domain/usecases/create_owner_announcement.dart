import '../entities/owner_announcement.dart';
import '../repositories/owner_announcement_repository.dart';

class CreateOwnerAnnouncement {
  final OwnerAnnouncementRepository repository;

  CreateOwnerAnnouncement(this.repository);

  Future<OwnerAnnouncement> call({
    required String title,
    required String message,
    required String announcementType,
    int? targetId,
    String? imagePath,
  }) {
    return repository.createAnnouncement(
      title: title,
      message: message,
      announcementType: announcementType,
      targetId: targetId,
      imagePath: imagePath,
    );
  }
}