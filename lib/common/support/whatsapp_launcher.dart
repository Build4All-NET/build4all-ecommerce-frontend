import 'package:url_launcher/url_launcher.dart';

/// Opens a WhatsApp chat with [rawNumber], optionally pre-filling [message].
///
/// Returns true when an external app/browser was launched successfully.
Future<bool> openWhatsApp({
  required String rawNumber,
  String? message,
}) async {
  // Keep digits only (wa.me requires the number without "+" or separators).
  final digits = rawNumber.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return false;

  final query = (message != null && message.trim().isNotEmpty)
      ? '?text=${Uri.encodeComponent(message.trim())}'
      : '';

  final uri = Uri.parse('https://wa.me/$digits$query');

  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
