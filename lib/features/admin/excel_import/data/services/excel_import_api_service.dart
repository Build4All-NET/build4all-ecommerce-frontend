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

  Options _auth(String token) => Options(
        headers: {'Authorization': 'Bearer ${_cleanToken(token)}'},
        contentType: 'multipart/form-data',
        responseType: ResponseType.json,
        // ✅ CRITICAL: stop Dio from throwing on 4xx/5xx so we can show backend errors
        validateStatus: (_) => true,
      );

  Map<String, dynamic> _ok(Map<String, dynamic> data, {int? statusCode}) {
    final out = <String, dynamic>{...data};
    out['statusCode'] = statusCode;
    // if backend forgets success, infer from status
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

    // backend returns JSON map (ideal)
    final d = res.data;
    if (d is Map) {
      final m = d.cast<String, dynamic>();

      // normalize common keys
      final success = (m['success'] == true) || (status != null && status >= 200 && status < 300 && m['success'] != false);
      final message = (m['message'] ?? m['error'] ?? m['msg'] ?? '').toString();
      final errors = _asStringList(m['errors'] ?? m['validationErrors'] ?? m['details']);

      return {
        ...m,
        'success': success,
        if (message.isNotEmpty) 'message': message,
        if (errors.isNotEmpty) 'errors': errors,
        'statusCode': status,
      };
    }

    // backend returns text
    final text = d?.toString() ?? '';
    final isOk = status != null && status >= 200 && status < 300;

    return isOk
        ? _ok({'message': text.isEmpty ? 'OK' : text, 'success': true}, statusCode: status)
        : _fail(
            text.isEmpty ? 'Request failed.' : text,
            statusCode: status,
          );
  }

  Map<String, dynamic> _fromDioError(DioException e, {String? fallbackMessage}) {
    final res = e.response;
    if (res != null) {
      // ✅ even errors come with payload sometimes — normalize it
      return _normalizeResponse(res);
    }

    // pure network error (no response)
    final msg = fallbackMessage ??
        (e.message?.isNotEmpty == true ? e.message! : 'Network error. Please try again.');
    return _fail(msg, statusCode: null);
  }

  Future<Map<String, dynamic>> validateExcel(File file) async {
    final token = await getToken();
    if (token == null || token.trim().isEmpty) {
      return _fail('No token found. Please login again.', statusCode: 401);
    }

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
        options: _auth(token),
      );

      return _normalizeResponse(res);
    } on DioException catch (e) {
      return _fromDioError(e, fallbackMessage: 'Validation request failed.');
    } catch (e) {
      return _fail('Unexpected error during validation: $e');
    }
  }

  Future<Map<String, dynamic>> importExcel({
    required File file,
    required bool replace,
    required String replaceScope, // TENANT | FULL
  }) async {
    final token = await getToken();
    if (token == null || token.trim().isEmpty) {
      return _fail('No token found. Please login again.', statusCode: 401);
    }

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
        options: _auth(token),
      );

      return _normalizeResponse(res);
    } on DioException catch (e) {
      return _fromDioError(e, fallbackMessage: 'Import request failed.');
    } catch (e) {
      return _fail('Unexpected error during import: $e');
    }
  }
}