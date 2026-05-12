import '../entities/owner_announcement.dart';

abstract class OwnerAnnouncementRepository {
  Future<OwnerAnnouncement> createAnnouncement({
    required String title,
    required String message,
    required String announcementType,
    int? targetId,
    String? imagePath,
  });

  Future<List<OwnerAnnouncement>> getAnnouncements();

  Future<void> deleteAnnouncement(int announcementId);
}