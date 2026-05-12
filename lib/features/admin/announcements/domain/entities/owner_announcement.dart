class OwnerAnnouncement {
  final int id;
  final int ownerProjectLinkId;
  final int ownerId;
  final String title;
  final String message;
  final String announcementType;
  final int? targetId;
  final String? imageUrl;
  final String status;
  final int sentCount;
  final DateTime? createdAt;

  const OwnerAnnouncement({
    required this.id,
    required this.ownerProjectLinkId,
    required this.ownerId,
    required this.title,
    required this.message,
    required this.announcementType,
    required this.targetId,
    required this.imageUrl,
    required this.status,
    required this.sentCount,
    required this.createdAt,
  });
}