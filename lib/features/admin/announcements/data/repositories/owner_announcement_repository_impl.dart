import '../../domain/entities/owner_announcement.dart';
import '../../domain/repositories/owner_announcement_repository.dart';
import '../models/owner_announcement_model.dart';
import '../services/owner_announcement_api_service.dart';

class OwnerAnnouncementRepositoryImpl implements OwnerAnnouncementRepository {
  final OwnerAnnouncementApiService api;

  OwnerAnnouncementRepositoryImpl({
    required this.api,
  });

  @override
  Future<OwnerAnnouncement> createAnnouncement({
    required String title,
    required String message,
    required String announcementType,
    int? targetId,
    String? imagePath,
  }) async {
    final response = await api.createAnnouncement(
      title: title,
      message: message,
      announcementType: announcementType,
      targetId: targetId,
      imagePath: imagePath,
    );

    if (response['success'] == false) {
      throw Exception(
        (response['message'] ?? 'Failed to create announcement').toString(),
      );
    }

    final data = response['data'];

    if (data is! Map) {
      throw Exception('Invalid announcement response');
    }

    return OwnerAnnouncementModel.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  @override
  Future<List<OwnerAnnouncement>> getAnnouncements() async {
    final list = await api.getAnnouncements();

    return list
        .map((json) => OwnerAnnouncementModel.fromJson(json))
        .toList();
  }

  @override
  Future<void> deleteAnnouncement(int announcementId) async {
    await api.deleteAnnouncement(announcementId);
  }
}