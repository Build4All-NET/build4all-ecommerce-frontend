import 'owner_app_user.dart';

/// The owner's view of their app's audience: a few headline counts and the
/// people those counts describe.
///
/// The counts come from the server rather than being recomputed here, so the
/// tiles and the list below them always agree.
class OwnerUserStatistics {
  final int totalUsers;
  final int activeUsers;
  final int verifiedUsers;
  final int reachableUsers;
  final int withEmail;
  final int withPhone;
  final int newUsersLast7Days;
  final int newUsersLast30Days;
  final int activeLast30Days;
  final List<OwnerAppUser> users;

  const OwnerUserStatistics({
    required this.totalUsers,
    required this.activeUsers,
    required this.verifiedUsers,
    required this.reachableUsers,
    required this.withEmail,
    required this.withPhone,
    required this.newUsersLast7Days,
    required this.newUsersLast30Days,
    required this.activeLast30Days,
    required this.users,
  });

  static const empty = OwnerUserStatistics(
    totalUsers: 0,
    activeUsers: 0,
    verifiedUsers: 0,
    reachableUsers: 0,
    withEmail: 0,
    withPhone: 0,
    newUsersLast7Days: 0,
    newUsersLast30Days: 0,
    activeLast30Days: 0,
    users: <OwnerAppUser>[],
  );

  bool get isEmpty => users.isEmpty;

  /// Users the owner can actually reach, as a 0..1 fraction for the meter.
  double get reachableRate {
    if (totalUsers <= 0) return 0;
    return (reachableUsers / totalUsers).clamp(0, 1).toDouble();
  }

  /// Case-insensitive search over the fields an owner would type: name,
  /// username, email, phone.
  List<OwnerAppUser> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return users;

    return users.where((u) {
      return u.name.toLowerCase().contains(q) ||
          u.username.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.phoneNumber.toLowerCase().contains(q);
    }).toList();
  }
}
