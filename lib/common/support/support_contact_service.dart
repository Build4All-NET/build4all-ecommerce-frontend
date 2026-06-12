import 'package:build4front/core/network/globals.dart' as g;
import 'package:dio/dio.dart';

/// Fetches the SUPER_ADMIN support contact (WhatsApp/phone) from the backend.
///
/// The number lives on the SUPER_ADMIN profile — there is no separate screen
/// to manage it. This service only reads the publicly exposed phone number.
class SupportContactService {
  /// Returns the support phone number, or null when none is configured.
  Future<String?> fetchSupportNumber() async {
    final dio = g.appDio;
    if (dio == null) return null;

    final res = await dio.get(
      '/api/public/support/contact',
      options: Options(headers: {'Accept': 'application/json'}),
    );
    final data = res.data;

    if (data is Map) {
      final phone = data['phoneNumber'];
      if (phone is String && phone.trim().isNotEmpty) {
        return phone.trim();
      }
    }
    return null;
  }
}
