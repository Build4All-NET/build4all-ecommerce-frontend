import '../../domain/entities/owner_user_statistics.dart';

import 'owner_app_user_model.dart';

class OwnerUserStatisticsModel extends OwnerUserStatistics {
  const OwnerUserStatisticsModel({
    required super.totalUsers,
    required super.activeUsers,
    required super.verifiedUsers,
    required super.reachableUsers,
    required super.withEmail,
    required super.withPhone,
    required super.newUsersLast7Days,
    required super.newUsersLast30Days,
    required super.activeLast30Days,
    required super.users,
  });

  factory OwnerUserStatisticsModel.fromJson(Map<String, dynamic> json) {
    final rawUsers = json['users'];

    final users = rawUsers is List
        ? rawUsers
            .whereType<Map>()
            .map((e) => OwnerAppUserModel.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <OwnerAppUserModel>[];

    return OwnerUserStatisticsModel(
      totalUsers: _int(json['totalUsers'], fallback: users.length),
      activeUsers: _int(json['activeUsers']),
      verifiedUsers: _int(json['verifiedUsers']),
      reachableUsers: _int(json['reachableUsers']),
      withEmail: _int(json['withEmail']),
      withPhone: _int(json['withPhone']),
      newUsersLast7Days: _int(json['newUsersLast7Days']),
      newUsersLast30Days: _int(json['newUsersLast30Days']),
      activeLast30Days: _int(json['activeLast30Days']),
      users: users,
    );
  }

  static int _int(dynamic v, {int fallback = 0}) {
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? fallback;
  }
}
