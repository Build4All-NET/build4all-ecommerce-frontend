import '../entities/owner_announcement.dart';
import '../repositories/owner_announcement_repository.dart';

class GetOwnerAnnouncements {
  final OwnerAnnouncementRepository repository;

  GetOwnerAnnouncements(this.repository);

  Future<List<OwnerAnnouncement>> call() {
    return repository.getAnnouncements();
  }
}