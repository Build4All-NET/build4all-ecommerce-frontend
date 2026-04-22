import 'package:build4front/core/exceptions/app_exception.dart';
import 'package:build4front/core/exceptions/auth_exception.dart';
import 'package:build4front/core/exceptions/network_exception.dart';
import 'package:build4front/core/network/api_fetch.dart';
import 'package:build4front/core/network/api_methods.dart';
import 'package:build4front/features/checkout/domain/errors/checkout_blocked_failure.dart';
import 'package:dio/dio.dart';

class CheckoutApiService {
  final ApiFetch _fetch = ApiFetch();

  Future<Map<String, dynamic>> getMyCart() async {
    final res = await _fetch.fetch(HttpMethod.get, '/api/cart');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<List<dynamic>> getShippingQuotes(Map<String, dynamic> body) async {
    try {
      final res = await _fetch.fetch(
        HttpMethod.post,
        '/api/shipping/available-methods',
        data: body,
      );
      return (res.data as List? ?? []);
    } on CheckoutBlockedFailure {
      rethrow;
    } on AppException catch (e) {
      _rethrowFromAppException(e);
    } on DioException catch (e) {
      _throwCheckoutError(
        status: e.response?.statusCode,
        raw: e.response?.data,
      );
    }
  }

  Future<Map<String, dynamic>> previewTax(Map<String, dynamic> body) async {
    try {
      final res = await _fetch.fetch(
        HttpMethod.post,
        '/api/tax/preview',
        data: body,
      );
      return Map<String, dynamic>.from(res.data as Map);
    } on CheckoutBlockedFailure {
      rethrow;
    } on AppException catch (e) {
      _rethrowFromAppException(e);
    } on DioException catch (e) {
      _throwCheckoutError(
        status: e.response?.statusCode,
        raw: e.response?.data,
      );
    }
  }

  Future<List<dynamic>> getEnabledPaymentMethods() async {
    final res = await _fetch.fetch(
      HttpMethod.get,
      '/api/payment-methods/enabled',
    );
    return (res.data as List? ?? []);
  }

  Map<String, dynamic>? _asMap(dynamic raw) {
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }

  String? _extractMessage(dynamic raw) {
    if (raw == null) return null;

    if (raw is String) {
      final s = raw.trim();
      return s.isEmpty ? null : s;
    }

    final data = _asMap(raw);
    if (data == null) return null;

    final msg = (data['message'] ??
            data['error'] ??
            data['detail'] ??
            data['msg'])
        ?.toString()
        .trim();

    return (msg == null || msg.isEmpty) ? null : msg;
  }

  String? _extractCode(dynamic raw) {
    final data = _asMap(raw);
    if (data == null) return null;

    final code = data['code']?.toString().trim();
    if (code == null || code.isEmpty) return null;
    return code;
  }

  Never _throwCheckoutError({
    required int? status,
    required dynamic raw,
    String? fallbackMessage,
    String? fallbackCode,
    Object? original,
  }) {
    final data = _asMap(raw);

    if (status == 409 && data != null) {
      throw CheckoutBlockedFailure(
        message: (data['error'] ?? data['message'] ?? 'Checkout blocked')
            .toString(),
        blockingErrors: (data['blockingErrors'] as List? ?? [])
            .map((x) => x.toString())
            .toList(),
        lineErrors: (data['lineErrors'] as List? ?? [])
            .whereType<Map>()
            .map((x) => Map<String, dynamic>.from(x))
            .toList(),
      );
    }

    final backendMsg = _extractMessage(raw) ?? fallbackMessage;
    final backendCode = _extractCode(raw) ?? fallbackCode;

    if (status == 401 || status == 403) {
      throw AuthException(
        backendMsg ?? 'Session expired. Please log in again.',
        code: backendCode,
        original: original,
      );
    }

    if (status != null) {
      throw ServerException(
        backendMsg ?? _statusFallback(status),
        statusCode: status,
        code: backendCode,
        original: original,
      );
    }

    throw AppException(
      backendMsg ?? 'Something went wrong. Please try again.',
      code: backendCode,
      original: original,
    );
  }

  Never _rethrowFromAppException(AppException e) {
    final orig = e.original;

    if (orig is DioException) {
      _throwCheckoutError(
        status: orig.response?.statusCode,
        raw: orig.response?.data,
        fallbackMessage: e.message,
        fallbackCode: e.code,
        original: orig,
      );
    }

    _throwCheckoutError(
      status: null,
      raw: null,
      fallbackMessage: e.message,
      fallbackCode: e.code,
      original: orig ?? e,
    );
  }

  String _statusFallback(int status) {
    switch (status) {
      case 400:
      case 422:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Session expired. Please log in again.';
      case 403:
        return 'You don’t have permission to do this.';
      case 404:
        return 'Not found.';
      case 409:
        return 'Conflict. This already exists or can’t be done now.';
      default:
        if (status >= 500) return 'Server error. Please try later.';
        return 'Request failed.';
    }
  }

  /// POST /api/orders/checkout
  Future<Map<String, dynamic>> checkout(Map<String, dynamic> body) async {
    try {
      final res = await _fetch.fetch(
        HttpMethod.post,
        '/api/orders/checkout',
        data: body,
      );

      return Map<String, dynamic>.from(res.data as Map);
    } on CheckoutBlockedFailure {
      rethrow;
    } on AppException catch (e) {
      _rethrowFromAppException(e);
    } on DioException catch (e) {
      _throwCheckoutError(
        status: e.response?.statusCode,
        raw: e.response?.data,
        original: e,
      );
    }
  }

  /// POST /api/orders/checkout/quote
  Future<Map<String, dynamic>> quoteFromCart(Map<String, dynamic> body) async {
    try {
      final res = await _fetch.fetch(
        HttpMethod.post,
        '/api/orders/checkout/quote',
        data: body,
      );
      return Map<String, dynamic>.from(res.data as Map);
    } on CheckoutBlockedFailure {
      rethrow;
    } on AppException catch (e) {
      _rethrowFromAppException(e);
    } on DioException catch (e) {
      _throwCheckoutError(
        status: e.response?.statusCode,
        raw: e.response?.data,
        original: e,
      );
    }
  }

  /// POST /api/orders/{orderId}/confirm-payment
  ///
  /// Called after the Stripe PaymentSheet / PayPal approval reports
  /// success. The backend verifies with the provider and flips the
  /// local payment transaction to PAID so the order reads as paid.
  Future<void> confirmPayment({required int orderId}) async {
    try {
      await _fetch.fetch(
        HttpMethod.post,
        '/api/orders/$orderId/confirm-payment',
      );
    } on CheckoutBlockedFailure {
      rethrow;
    } on AppException catch (e) {
      _rethrowFromAppException(e);
    } on DioException catch (e) {
      _throwCheckoutError(
        status: e.response?.statusCode,
        raw: e.response?.data,
        original: e,
      );
    }
  }

  /// GET /api/orders/myorders/last-shipping-address
  Future<Map<String, dynamic>> getMyLastShippingAddress() async {
    final res = await _fetch.fetch(
      HttpMethod.get,
      '/api/orders/myorders/last-shipping-address',
    );

    if (res.data is Map) {
      return Map<String, dynamic>.from(res.data as Map);
    }
    return <String, dynamic>{};
  }
}