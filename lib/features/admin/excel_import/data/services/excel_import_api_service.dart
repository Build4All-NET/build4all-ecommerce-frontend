import 'dart:io';
import 'package:dio/dio.dart';
import 'package:build4front/core/network/globals.dart' as g;

class ExcelImportApiService {
  final Dio _dio;
  final Future<String?> Function() getToken;

  ExcelImportApiService({Dio? dio, required this.getToken})
      : _dio = dio ?? g.dio();

  String _cleanToken(String token) {
    final t = token.trim();
    return t.toLowerCase().startsWith('bearer ') ? t.substring(7).trim() : t;
  }

  Future<Options> _auth() async {
    final token = await getToken();

    return Options(
      headers: {
        if (token != null && token.trim().isNotEmpty)
          'Authorization': 'Bearer ${_cleanToken(token)}',
      },
      contentType: 'multipart/form-data',
      responseType: ResponseType.json,
      receiveDataWhenStatusError: true,
    );
  }

  Map<String, dynamic> _ok(Map<String, dynamic> data, {int? statusCode}) {
    final out = <String, dynamic>{...data};
    out['statusCode'] = statusCode;
    out.putIfAbsent('success', () {
      if (statusCode == null) return true;
      return statusCode >= 200 && statusCode < 300;
    });
    return out;
  }

  Map<String, dynamic> _fail(
    String message, {
    int? statusCode,
    List<String>? errors,
    dynamic raw,
  }) {
    return {
      'success': false,
      'message': message,
      'errors': errors ?? <String>[],
      'statusCode': statusCode,
      if (raw != null) 'raw': raw,
    };
  }

  List<String> _asStringList(dynamic v) {
    if (v == null) return <String>[];
    if (v is List) {
      return v.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    }
    return [v.toString()];
  }

  Map<String, dynamic> _normalizeResponse(Response res) {
    final status = res.statusCode;
    final d = res.data;

    if (d is Map) {
      final m = d.cast<String, dynamic>();

      final success =
          (m['success'] == true) ||
          (status != null && status >= 200 && status < 300 && m['success'] != false);

      final message = (m['message'] ?? m['error'] ?? m['msg'] ?? '').toString();
      final errors = _asStringList(
        m['errors'] ?? m['validationErrors'] ?? m['details'],
      );

      return {
        ...m,
        'success': success,
        if (message.isNotEmpty) 'message': message,
        if (errors.isNotEmpty) 'errors': errors,
        'statusCode': status,
      };
    }

    final text = d?.toString() ?? '';
    final isOk = status != null && status >= 200 && status < 300;

    return isOk
        ? _ok(
            {'message': text.isEmpty ? 'OK' : text, 'success': true},
            statusCode: status,
          )
        : _fail(
            text.isEmpty ? 'Request failed.' : text,
            statusCode: status,
          );
  }

  Map<String, dynamic> _fromDioError(DioException e, {String? fallbackMessage}) {
    final isSocket = e.error is SocketException;

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError ||
        (e.type == DioExceptionType.unknown && isSocket)) {
      return _fail(
        isSocket
            ? 'No internet connection.'
            : "Can't reach the server. Check your internet and try again.",
      );
    }

    if (e.type == DioExceptionType.cancel) {
      return _fail('Request cancelled.');
    }

    final res = e.response;
    if (res != null) {
      final status = res.statusCode;
      if (status != null && status >= 500) {
        return _fail('Server error. Please try later.', statusCode: status);
      }
      return _normalizeResponse(res);
    }

    return _fail(
      fallbackMessage ?? "Can't reach the server. Check your internet and try again.",
    );
  }

  Future<Map<String, dynamic>> validateExcel(File file) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split(Platform.pathSeparator).last,
      ),
    });

    try {
      final res = await _dio.post(
        '/api/admin/import/excel/validate',
        data: form,
        options: await _auth(),
      );

      return _normalizeResponse(res);
    } on DioException catch (e) {
      return _fromDioError(e, fallbackMessage: 'Validation request failed.');
    } catch (e) {
      return _fail('Something went wrong. Please try again.');
    }
  }

  Future<Map<String, dynamic>> importExcel({
    required File file,
    required bool replace,
    required String replaceScope,
  }) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split(Platform.pathSeparator).last,
      ),
    });

    try {
      final res = await _dio.post(
        '/api/admin/import/excel',
        queryParameters: {
          'replace': replace,
          'replaceScope': replaceScope,
        },
        data: form,
        options: await _auth(),
      );

      return _normalizeResponse(res);
    } on DioException catch (e) {
      return _fromDioError(e, fallbackMessage: 'Import request failed.');
    } catch (e) {
      return _fail('Something went wrong. Please try again.');
    }
  }
}