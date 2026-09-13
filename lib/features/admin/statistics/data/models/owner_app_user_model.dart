import 'package:build4front/core/network/globals.dart' as g;

import '../../domain/entities/owner_app_user.dart';

class OwnerAppUserModel extends OwnerAppUser {
  const OwnerAppUserModel({
    required super.id,
    required super.name,
    required super.username,
    required super.email,
    required super.phoneNumber,
    required super.status,
    required super.verified,
    required super.profileImageUrl,
    required super.createdAt,
    required super.lastLogin,
  });

  factory OwnerAppUserModel.fromJson(Map<String, dynamic> json) {
    final rawImage = _str(json['profileImageUrl']);

    return OwnerAppUserModel(
      id: _int(json['id']),
      name: _str(json['name']),
      username: _str(json['username']),
      email: _str(json['email']),
      phoneNumber: _str(json['phoneNumber']),
      status: _str(json['status']),
      verified: _bool(json['verified']),
      // Server sends a path like "/uploads/..."; make it openable as-is.
      profileImageUrl: rawImage.isEmpty ? '' : g.resolveUrl(rawImage),
      createdAt: _date(json['createdAt']),
      lastLogin: _date(json['lastLogin']),
    );
  }

  static int _int(dynamic v) {
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static String _str(dynamic v) => v?.toString().trim() ?? '';

  static bool _bool(dynamic v) {
    if (v is bool) return v;
    final s = v?.toString().trim().toLowerCase() ?? '';
    return s == 'true' || s == '1';
  }

  static DateTime? _date(dynamic v) {
    final s = v?.toString().trim() ?? '';
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }
}
