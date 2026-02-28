// lib/features/checkout/data/services/checkout_api_service.dart
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
    final res = await _fetch.fetch(
      HttpMethod.post,
      '/api/shipping/available-methods',
      data: body,
    );
    return (res.data as List? ?? []);
  }

  Future<Map<String, dynamic>> previewTax(Map<String, dynamic> body) async {
    final res = await _fetch.fetch(
      HttpMethod.post,
      '/api/tax/preview',
      data: body,
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<List<dynamic>> getEnabledPaymentMethods() async {
    final res = await _fetch.fetch(
      HttpMethod.get,
      '/api/payment-methods/enabled',
    );
    return (res.data as List? ?? []);
  }

  /// NEW: backend orchestrated checkout
  /// POST /api/orders/checkout
 Future<Map<String, dynamic>> checkout(Map<String, dynamic> body) async {
    try {
      final res = await _fetch.fetch(
        HttpMethod.post,
        '/api/orders/checkout',
        data: body,
      );

      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final raw = e.response?.data;

      // Try to coerce response into Map
      Map<String, dynamic>? data;
      if (raw is Map) {
        data = Map<String, dynamic>.from(raw as Map);
      }

      if (status == 409 && data != null) {
        throw CheckoutBlockedFailure(
          message: (data['error'] ?? 'Checkout blocked').toString(),
          blockingErrors: (data['blockingErrors'] as List? ?? [])
              .map((x) => x.toString())
              .toList(),
          lineErrors: (data['lineErrors'] as List? ?? [])
              .whereType<Map>()
              .map((x) => Map<String, dynamic>.from(x))
              .toList(),
        );
      }

      // fallback: show backend message if exists
      final backendMsg = (data?['error'] ?? data?['message'])?.toString();
      if (backendMsg != null && backendMsg.trim().isNotEmpty) {
        throw Exception(backendMsg);
      }

      rethrow;
    } catch (e) {
      rethrow;
    }
  }


  /// NEW: quote total BEFORE checkout (no order created)
  /// Backend should call quoteCheckoutFromCart()
  /// Suggested path: POST /api/orders/checkout/quote-from-cart
  Future<Map<String, dynamic>> quoteFromCart(Map<String, dynamic> body) async {
    try {
      final res = await _fetch.fetch(
        HttpMethod.post,
        '/api/orders/checkout/quote', 
        data: body,
      );
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      final raw = e.response?.data;

      Map<String, dynamic>? data;
      if (raw is Map) data = Map<String, dynamic>.from(raw);

      final msg = (data?['error'] ?? data?['message'])?.toString();
      if (msg != null && msg.trim().isNotEmpty) throw Exception(msg);

      rethrow;
    }
  }

  /// Prefill checkout shipping form (most recent order)
  /// GET /api/orders/myorders/last-shipping-address
  Future<Map<String, dynamic>> getMyLastShippingAddress() async {
    final res = await _fetch.fetch(
      HttpMethod.get,
      '/api/orders/myorders/last-shipping-address',
    );

    // backend returns Map with null values allowed
    if (res.data is Map) {
      return Map<String, dynamic>.from(res.data as Map);
    }
    return <String, dynamic>{};
  }

  /// ⚠️ Legacy endpoint (OLD flow: create intent from mobile).
  /// If your backend moved fully to orchestrator, you can delete this safely.
  /// Keeping it here does NOT hurt as long as it is not used by the bloc.
  /*
  Future<Map<String, dynamic>> createIntent({
    required double price,
    required String currency,
    required String stripeAccountId,
    Map<String, dynamic>? metadata,
  }) async {
    final data = <String, dynamic>{
      'price': price,
      'currency': currency,
      'stripeAccountId': stripeAccountId,
      if (metadata != null) 'metadata': metadata,
    };

    final res = await _fetch.fetch(
      HttpMethod.post,
      '/api/payments/create-intent',
      data: data,
    );

    return Map<String, dynamic>.from(res.data as Map);
  }
  */
}
