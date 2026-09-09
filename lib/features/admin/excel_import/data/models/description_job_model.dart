import '../../domain/entities/description_job.dart';

/// Reads the description job's state from the server.
///
/// The status endpoint answers with the counts alongside a nested job; the
/// running job is flattened here so the UI has one object to draw from.
class DescriptionJobModel {
  const DescriptionJobModel._();

  static DescriptionJob fromJson(Map<String, dynamic> json) {
    final job = json['job'];
    final nested = job is Map ? job.cast<String, dynamic>() : const <String, dynamic>{};

    return DescriptionJob(
      available: json['available'] == true,
      missing: _int(json['missing']),
      running: nested['running'] == true,
      total: _int(nested['total']),
      written: _int(nested['written']),
      failed: _int(nested['failed']),
      message: nested['message']?.toString(),
    );
  }

  /// The start endpoint answers with the job alone, so the counts the status
  /// endpoint carries are taken from what the caller already knew.
  static DescriptionJob fromStartJson(Map<String, dynamic> json, DescriptionJob previous) {
    return DescriptionJob(
      available: previous.available,
      missing: previous.missing,
      running: json['running'] == true,
      total: _int(json['total']),
      written: _int(json['written']),
      failed: _int(json['failed']),
      message: json['message']?.toString(),
    );
  }

  static int _int(dynamic value) => value is num ? value.toInt() : 0;
}
