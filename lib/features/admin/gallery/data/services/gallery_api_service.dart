import 'package:dio/dio.dart';
import 'package:build4front/core/network/globals.dart' as g;

import '../../domain/entities/picked_image.dart';

/// Talks to the owner gallery endpoints.
///
/// Errors come back as a normalised map rather than as thrown exceptions so the
/// bloc has one shape to read, matching how the Excel import service already
/// behaves on this screen's sibling.
class GalleryApiService {
  final Dio _dio;
  final Future<String?> Function() getToken;

  GalleryApiService({Dio? dio, required this.getToken}) : _dio = dio ?? g.dio();

  static const _basePath = '/api/admin/gallery/images';

  String _cleanToken(String token) {
    final t = token.trim();
    return t.toLowerCase().startsWith('bearer ') ? t.substring(7).trim() : t;
  }

  Future<Options> _auth({String? contentType}) async {
    final token = await getToken();

    return Options(
      headers: {
        if (token != null && token.trim().isNotEmpty)
          'Authorization': 'Bearer ${_cleanToken(token)}',
      },
      contentType: contentType,
      responseType: ResponseType.json,
      receiveDataWhenStatusError: true,
    );
  }

  Future<Map<String, dynamic>> list({required int page, required int size}) async {
    try {
      final res = await _dio.get(
        _basePath,
        queryParameters: {'page': page, 'size': size},
        options: await _auth(),
      );

      return _normalize(res);
    } on DioException catch (e) {
      return _fromDioError(e);
    } catch (_) {
      return _fail('Something went wrong. Please try again.');
    }
  }

  Future<Map<String, dynamic>> upload(List<PickedImage> images) async {
    try {
      final form = FormData();

      // Repeated 'files' parts rather than one array field: that is what a
      // Spring List<MultipartFile> binds to.
      for (final image in images) {
        form.files.add(MapEntry(
          'files',
          MultipartFile.fromBytes(image.bytes, filename: image.name),
        ));
      }

      final res = await _dio.post(
        _basePath,
        data: form,
        options: await _auth(contentType: 'multipart/form-data'),
      );

      return _normalize(res);
    } on DioException catch (e) {
      return _fromDioError(e, fallbackMessage: 'Upload failed.');
    } catch (_) {
      return _fail('Something went wrong. Please try again.');
    }
  }

  Future<Map<String, dynamic>> delete(int imageId) async {
    try {
      final res = await _dio.delete('$_basePath/$imageId', options: await _auth());
      return _normalize(res);
    } on DioException catch (e) {
      return _fromDioError(e, fallbackMessage: 'Could not remove the image.');
    } catch (_) {
      return _fail('Something went wrong. Please try again.');
    }
  }

  // ---------------- response shaping ----------------

  Map<String, dynamic> _normalize(Response res) {
    final status = res.statusCode;
    final data = res.data;

    if (data is Map) {
      final m = data.cast<String, dynamic>();
      final ok = (m['success'] == true) ||
          (status != null && status >= 200 && status < 300 && m['success'] != false);

      return {...m, 'success': ok, 'statusCode': status};
    }

    final isOk = status != null && status >= 200 && status < 300;
    return isOk
        ? {'success': true, 'statusCode': status}
        : _fail(data?.toString() ?? 'Request failed.', statusCode: status);
  }

  Map<String, dynamic> _fromDioError(DioException e, {String? fallbackMessage}) {
    final isNetworkDown = e.type == DioExceptionType.connectionError;

    if (isNetworkDown ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return _fail(isNetworkDown
          ? 'No internet connection.'
          : "Can't reach the server. Check your internet and try again.");
    }

    final res = e.response;
    if (res != null) {
      final status = res.statusCode;
      if (status != null && status >= 500) {
        return _fail('Server error. Please try later.', statusCode: status);
      }
      return _normalize(res);
    }

    return _fail(fallbackMessage ?? 'Request failed.');
  }

  Map<String, dynamic> _fail(String message, {int? statusCode}) => {
        'success': false,
        'message': message,
        'statusCode': statusCode,
      };
}
