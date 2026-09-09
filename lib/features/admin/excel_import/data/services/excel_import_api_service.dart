import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:build4front/core/network/globals.dart' as g;

import '../../domain/entities/picked_excel_file.dart';

class ExcelImportApiService {
  final Dio _dio;
  final Future<String?> Function() getToken;

  ExcelImportApiService({Dio? dio, required this.getToken})
      : _dio = dio ?? g.dio();

  String _cleanToken(String token) {
    final t = token.trim();
    return t.toLowerCase().startsWith('bearer ') ? t.substring(7).trim() : t;
  }

  /// How long an import is given to answer.
  ///
  /// The shared client allows a minute, which is right for a screen waiting on
  /// a list and wrong here: writing a catalogue of a thousand products is one
  /// request that legitimately takes minutes, and cutting it off leaves the
  /// owner staring at a timeout while the server finishes the work anyway.
  static const Duration _importTimeout = Duration(minutes: 10);

  Future<Options> _auth({Duration? receiveTimeout}) async {
    final token = await getToken();

    return Options(
      headers: {
        if (token != null && token.trim().isNotEmpty)
          'Authorization': 'Bearer ${_cleanToken(token)}',
      },
      contentType: 'multipart/form-data',
      responseType: ResponseType.json,
      receiveDataWhenStatusError: true,
      sendTimeout: receiveTimeout,
      receiveTimeout: receiveTimeout,
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
    // dart:io's SocketException cannot be referenced from a web build. Dio
    // reports the same "network is down" condition as connectionError on every
    // platform, and anything else without a response still falls through to the
    // unreachable-server message at the end of this method.
    final isNetworkDown = e.type == DioExceptionType.connectionError;

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        isNetworkDown) {
      return _fail(
        isNetworkDown
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

  Future<Map<String, dynamic>> validateExcel(PickedExcelFile file) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes, filename: file.name),
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
    required PickedExcelFile file,
    required bool replace,
    required String replaceScope,
    Map<int, int> imageAssignments = const {},
  }) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes, filename: file.name),
    });

    try {
      final res = await _dio.post(
        '/api/admin/import/excel',
        queryParameters: {
          'replace': replace,
          'replaceScope': replaceScope,
          // Sent as one JSON object keyed by row so the whole import — file and
          // picture choices together — stays a single request.
          if (imageAssignments.isNotEmpty)
            'imageAssignments': jsonEncode(
              imageAssignments.map((row, id) => MapEntry(row.toString(), id)),
            ),
        },
        data: form,
        options: await _auth(receiveTimeout: _importTimeout),
      );

      return _normalizeResponse(res);
    } on DioException catch (e) {
      return _fromDioError(e, fallbackMessage: 'Import request failed.');
    } catch (e) {
      return _fail('Something went wrong. Please try again.');
    }
  }

  /// Asks the server what the owner's own file appears to contain.
  ///
  /// The way in for an owner arriving from another system: they upload the
  /// export as it came instead of retyping it into our template. Nothing is
  /// created by this call -- the answer is a proposal for them to confirm.
  Future<Map<String, dynamic>> suggestMapping(PickedExcelFile file) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes, filename: file.name),
    });

    try {
      final res = await _dio.post(
        '/api/admin/import/excel/suggest-mapping',
        data: form,
        options: await _auth(receiveTimeout: _importTimeout),
      );

      // The endpoint answers with a bare list of sheets, which _normalizeResponse
      // is not shaped for; wrap it so callers see the usual success envelope.
      final status = res.statusCode;
      final ok = status != null && status >= 200 && status < 300;

      return ok
          ? {'success': true, 'sheets': res.data, 'statusCode': status}
          : _normalizeResponse(res);
    } on DioException catch (e) {
      return _fromDioError(e, fallbackMessage: 'Could not read the file.');
    } catch (e) {
      return _fail('Something went wrong. Please try again.');
    }
  }

  /// What importing the owner's own file would create, without creating it.
  Future<Map<String, dynamic>> previewForeign({
    required PickedExcelFile file,
    required String sheetName,
    required Map<int, String> columns,
    String? categoryName,
  }) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes, filename: file.name),
    });

    try {
      final res = await _dio.post(
        '/api/admin/import/excel/foreign/preview',
        queryParameters: {
          'sheetName': sheetName,
          'columns': jsonEncode(
            columns.map((column, field) => MapEntry(column.toString(), field)),
          ),
          if (categoryName != null && categoryName.trim().isNotEmpty)
            'categoryName': categoryName.trim(),
        },
        data: form,
        options: await _auth(receiveTimeout: _importTimeout),
      );

      return _normalizeResponse(res);
    } on DioException catch (e) {
      return _fromDioError(e, fallbackMessage: 'Could not read the products.');
    } catch (e) {
      return _fail('Something went wrong. Please try again.');
    }
  }

  /// Imports the owner's own file, read the way they confirmed.
  ///
  /// The column choices are sent rather than guessed again so what is written is
  /// what the owner saw and agreed to.
  Future<Map<String, dynamic>> importForeign({
    required PickedExcelFile file,
    required String sheetName,
    required Map<int, String> columns,
    String? categoryName,
    required String matchMode,
    Map<int, Map<String, Object>> rowEdits = const {},
    Map<int, int> imageAssignments = const {},
  }) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes, filename: file.name),
    });

    try {
      final res = await _dio.post(
        '/api/admin/import/excel/foreign',
        queryParameters: {
          'sheetName': sheetName,
          'columns': jsonEncode(
            columns.map((column, field) => MapEntry(column.toString(), field)),
          ),
          if (categoryName != null && categoryName.trim().isNotEmpty)
            'categoryName': categoryName.trim(),
          'matchMode': matchMode,
          // What the owner typed while looking at each product, keyed by its row.
          if (rowEdits.isNotEmpty)
            'rowEdits': jsonEncode(
              rowEdits.map((row, edit) => MapEntry(row.toString(), edit)),
            ),
          if (imageAssignments.isNotEmpty)
            'imageAssignments': jsonEncode(
              imageAssignments.map((row, id) => MapEntry(row.toString(), id)),
            ),
        },
        data: form,
        options: await _auth(receiveTimeout: _importTimeout),
      );

      return _normalizeResponse(res);
    } on DioException catch (e) {
      return _fromDioError(e, fallbackMessage: 'Import request failed.');
    } catch (e) {
      return _fail('Something went wrong. Please try again.');
    }
  }

  /// How many products have nothing written about them, and whether the
  /// assistant is already writing.
  Future<Map<String, dynamic>> descriptionsStatus() async {
    try {
      final res = await _dio.get(
        '/api/admin/ai/product-descriptions',
        options: await _auth(),
      );

      return _normalizeResponse(res);
    } on DioException catch (e) {
      return _fromDioError(e, fallbackMessage: 'Could not check descriptions.');
    } catch (e) {
      return _fail('Something went wrong. Please try again.');
    }
  }

  /// Starts writing them.
  ///
  /// Answers at once: the work outlives the request by minutes, and its progress
  /// is read back from [descriptionsStatus].
  Future<Map<String, dynamic>> startDescriptions() async {
    try {
      final res = await _dio.post(
        '/api/admin/ai/product-descriptions',
        options: await _auth(),
      );

      return _normalizeResponse(res);
    } on DioException catch (e) {
      return _fromDioError(e, fallbackMessage: 'Could not start writing.');
    } catch (e) {
      return _fail('Something went wrong. Please try again.');
    }
  }

  /// Fetches the blank workbook from the backend.
  ///
  /// The template used to ship inside the app, which meant a change to the
  /// importer's columns needed an app release to reach owners. Serving it from
  /// the same place that parses it removes that gap.
  Future<List<int>?> downloadTemplate() async {
    try {
      final token = await getToken();

      final res = await _dio.get<List<int>>(
        '/api/admin/import/excel/template',
        options: Options(
          headers: {
            if (token != null && token.trim().isNotEmpty)
              'Authorization': 'Bearer ${_cleanToken(token)}',
          },
          responseType: ResponseType.bytes,
        ),
      );

      final bytes = res.data;
      return (bytes == null || bytes.isEmpty) ? null : bytes;
    } catch (_) {
      // Null means "fall back to the copy bundled with the app" rather than
      // leaving the owner with no template at all.
      return null;
    }
  }
}
