import 'package:build4front/core/config/env.dart';

import '../../domain/entities/gallery_image.dart';
import '../../domain/entities/gallery_page.dart';
import '../../domain/entities/gallery_upload_result.dart';
import '../../domain/entities/picked_image.dart';
import '../../domain/repositories/gallery_repository.dart';
import '../models/gallery_image_model.dart';
import '../services/gallery_api_service.dart';

class GalleryRepositoryImpl implements GalleryRepository {
  final GalleryApiService api;

  const GalleryRepositoryImpl({required this.api});

  @override
  Future<GalleryPage> list({required int page, required int size}) async {
    final res = await api.list(page: page, size: size);

    if (res['success'] != true) {
      throw Exception(res['message']?.toString() ?? 'Could not load the gallery.');
    }

    return GalleryPage(
      items: _parseItems(res['items']),
      page: _asInt(res['page']) ?? page,
      totalElements: _asInt(res['totalElements']) ?? 0,
      hasMore: res['hasMore'] == true,
    );
  }

  @override
  Future<GalleryUploadResult> upload(List<PickedImage> images) async {
    final res = await api.upload(images);

    final uploaded = _parseItems(res['items']);
    final failed = _parseStrings(res['failed']);

    // Nothing stored and nothing explained means the request itself failed.
    if (uploaded.isEmpty && failed.isEmpty) {
      throw Exception(res['message']?.toString() ?? 'Could not upload the images.');
    }

    return GalleryUploadResult(uploaded: uploaded, failed: failed);
  }

  @override
  Future<void> delete(int imageId) async {
    final res = await api.delete(imageId);

    if (res['success'] != true) {
      throw Exception(res['message']?.toString() ?? 'Could not remove the image.');
    }
  }

  List<GalleryImage> _parseItems(dynamic raw) {
    if (raw is! List) return const [];

    final out = <GalleryImage>[];
    for (final entry in raw) {
      if (entry is! Map) continue;

      final parsed = GalleryImageModel.fromJson(entry.cast<String, dynamic>());
      if (parsed == null) continue;

      out.add(GalleryImage(
        id: parsed.id,
        url: absoluteUrl(parsed.url),
        fileName: parsed.fileName,
        sizeBytes: parsed.sizeBytes,
      ));
    }
    return out;
  }

  static List<String> _parseStrings(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  /// R2 hands back a full address; local storage hands back a server path. Both
  /// are resolved here so nothing downstream has to know which one it is holding.
  static String absoluteUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return '${Env.apiBaseUrl}$trimmed';
  }
}
