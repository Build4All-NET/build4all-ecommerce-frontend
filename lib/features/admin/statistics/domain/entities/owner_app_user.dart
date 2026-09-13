/// One person who installed the owner's app, as the statistics screen shows
/// them: who they are, and how the owner can reach them.
class OwnerAppUser {
  final int id;
  final String name;
  final String username;
  final String email;
  final String phoneNumber;
  final String status;
  final bool verified;
  final String profileImageUrl;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  const OwnerAppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.status,
    required this.verified,
    required this.profileImageUrl,
    required this.createdAt,
    required this.lastLogin,
  });

  bool get hasEmail => email.trim().isNotEmpty;

  bool get hasPhone => phoneNumber.trim().isNotEmpty;

  /// False when there is nothing to tap — the card then says so instead of
  /// opening a sheet with no actions in it.
  bool get canBeContacted => hasEmail || hasPhone;

  bool get isActive => status.trim().toUpperCase() == 'ACTIVE';

  /// Falls back through username and then email so a row never renders blank.
  String get displayName {
    final n = name.trim();
    if (n.isNotEmpty) return n;

    final u = username.trim();
    if (u.isNotEmpty) return u;

    final e = email.trim();
    if (e.isNotEmpty) return e;

    return '#$id';
  }

  /// First letter of the display name, for the avatar placeholder.
  String get initial {
    final source = displayName.trim();
    if (source.isEmpty) return '?';
    return source.substring(0, 1).toUpperCase();
  }
}
