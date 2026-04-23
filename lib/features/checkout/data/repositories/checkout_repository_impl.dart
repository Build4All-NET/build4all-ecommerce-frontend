// lib/features/checkout/data/repositories/checkout_repository_impl.dart

import 'package:build4front/features/checkout/domain/entities/checkout_entities.dart';
import 'package:build4front/features/checkout/domain/repositories/checkout_repository.dart';

import 'package:build4front/features/checkout/data/models/checkout_models.dart';
import 'package:build4front/features/checkout/data/models/checkout_summary_model.dart';
import 'package:build4front/features/checkout/data/services/checkout_api_service.dart';

class CheckoutRepositoryImpl implements CheckoutRepository {
  final CheckoutApiService api;
  CheckoutRepositoryImpl(this.api);

  @override
  Future<CheckoutCart> getMyCart() async {
    final json = await api.getMyCart();
    final model = CheckoutCartModel.fromJson(json);

    return CheckoutCart(
      cartId: model.cartId,
      status: model.status,
      totalPrice: model.totalPrice,
      currencySymbol: model.currencySymbol,
      items: model.items
          .map(
            (i) => CheckoutCartItem(
              cartItemId: i.cartItemId,
              itemId: i.itemId,
              itemName: i.itemName,
              imageUrl: i.imageUrl,
              quantity: i.quantity,
              unitPrice: i.unitPrice,
              lineTotal: i.lineTotal,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<CheckoutSummaryModel> quoteFromCart({
    required int currencyId,
    String? couponCode,
    required int? shippingMethodId,
    required String shippingMethodName,
    required ShippingAddress shippingAddress,
  }) async {
    final body = <String, dynamic>{
      'currencyId': currencyId,

      // backend expects CheckoutRequest.shippingAddress
      'shippingAddress': {
        ..._addressToJson(shippingAddress),
        'shippingMethodId': shippingMethodId,
        'shippingMethodName': shippingMethodName,
      },
    };

    final c = (couponCode ?? '').trim();
    if (c.isNotEmpty) body['couponCode'] = c;

    final json = await api.quoteFromCart(body);
    return CheckoutSummaryModel.fromJson(json);
  }

 Map<String, dynamic> _addressToJson(ShippingAddress a) => {
        'countryId': a.countryId,
        'regionId': a.regionId,
        'city': a.city,
        'postalCode': a.postalCode,

        //  NEW fields
        'addressLine': a.addressLine,
        'phone': a.phone,
        'fullName': a.fullName,
        'notes': a.notes,
      };

  Map<String, dynamic> _lineToJson(CartLine l) => {
        'itemId': l.itemId,
        'quantity': l.quantity,
        'unitPrice': l.unitPrice,
      };

  @override
  Future<List<ShippingQuote>> getShippingQuotes({
    required int ownerProjectId,
    required ShippingAddress address,
    required List<CartLine> lines,
  }) async {
    final body = {
      'ownerProjectId': ownerProjectId,
      'address': _addressToJson(address),
      'lines': lines.map(_lineToJson).toList(),
    };

    final list = await api.getShippingQuotes(body);

    return list
        .whereType<Map>()
        .map((e) => ShippingQuoteModel.fromJson(Map<String, dynamic>.from(e)))
        .map(
          (m) => ShippingQuote(
            methodId: m.methodId,
            methodName: m.methodName,
            price: m.price,
            currencySymbol: m.currencySymbol,
          ),
        )
        .toList();
  }

    @override
  Future<ShippingAddress> getMyLastShippingAddress() async {
    final json = await api.getMyLastShippingAddress();

    // If backend returns empty map -> no previous address
    if (json.isEmpty) return const ShippingAddress();

    // IMPORTANT: you need fromJson in ShippingAddress entity
    return ShippingAddress.fromJson(json);
  }


  @override
  Future<TaxPreview> previewTax({
    required int ownerProjectId,
    required ShippingAddress address,
    required List<CartLine> lines,
    required double shippingTotal,
  }) async {
    final body = {
      'ownerProjectId': ownerProjectId,
      'address': _addressToJson(address),
      'lines': lines.map(_lineToJson).toList(),
      'shippingTotal': shippingTotal,
    };

    final json = await api.previewTax(body);
    final model = TaxPreviewModel.fromJson(json);

    return TaxPreview(
      itemsTaxTotal: model.itemsTaxTotal,
      shippingTaxTotal: model.shippingTaxTotal,
      totalTax: model.totalTax,
    );
  }

  @override
  Future<List<PaymentMethod>> getEnabledPaymentMethods() async {
    final list = await api.getEnabledPaymentMethods();

    final models = list
        .whereType<Map>()
        .map((e) => PaymentMethodModel.fromJson(Map<String, dynamic>.from(e)))
        .where((m) => m.enabled)
        .toList();

    return models
        .map(
          (m) => PaymentMethod(
            id: m.id,
            code: m.code,
            name: m.name,
            configMap: m.configMap,
          ),
        )
        .toList();
  }

  @override
  Future<CheckoutSummaryModel> checkout({
    required int ownerProjectId,
    required int currencyId,
    required String paymentMethod,
    String? couponCode,
    String? stripePaymentId,
    String? destinationAccountId,
    required int shippingMethodId,
    required String shippingMethodName,
    required ShippingAddress shippingAddress,
    required List<CartLine> lines,
  }) async {
    /// This body matches backend checkout request.
    /// If your backend expects different keys, adjust them here ONLY
    /// (keep bloc/usecases stable).
    final body = <String, dynamic>{
      'ownerProjectId': ownerProjectId,
      'currencyId': currencyId,
      'paymentMethod': paymentMethod,

      // shipping + address
      'shippingMethodId': shippingMethodId,
      'shippingAddress': {
        ..._addressToJson(shippingAddress),
        'shippingMethodId': shippingMethodId,
        'shippingMethodName': shippingMethodName,
      },

      'lines': lines.map(_lineToJson).toList(),
    };

    final c = (couponCode ?? '').trim();
    if (c.isNotEmpty) body['couponCode'] = c;

    // Legacy: only if backend still supports "stripePaymentId" in request
    final s = (stripePaymentId ?? '').trim();
    if (s.isNotEmpty) body['stripePaymentId'] = s;

    // Stripe Connect: destination account (acct_...)
    final dest = (destinationAccountId ?? '').trim();
    if (dest.isNotEmpty) body['destinationAccountId'] = dest;

    final json = await api.checkout(body);
    return CheckoutSummaryModel.fromJson(json);
  }

  Map<String, dynamic> _buildCheckoutBody({
    required int ownerProjectId,
    required int currencyId,
    required String paymentMethod,
    String? couponCode,
    required int shippingMethodId,
    required String shippingMethodName,
    required ShippingAddress shippingAddress,
    required List<CartLine> lines,
    String? destinationAccountId,
  }) {
    final body = <String, dynamic>{
      'ownerProjectId': ownerProjectId,
      'currencyId': currencyId,
      'paymentMethod': paymentMethod,
      'shippingMethodId': shippingMethodId,
      'shippingAddress': {
        ..._addressToJson(shippingAddress),
        'shippingMethodId': shippingMethodId,
        'shippingMethodName': shippingMethodName,
      },
      'lines': lines.map(_lineToJson).toList(),
    };
    final c = (couponCode ?? '').trim();
    if (c.isNotEmpty) body['couponCode'] = c;
    final dest = (destinationAccountId ?? '').trim();
    if (dest.isNotEmpty) body['destinationAccountId'] = dest;
    return body;
  }

  @override
  Future<CheckoutSummaryModel> prepareStripePayment({
    required int ownerProjectId,
    required int currencyId,
    required String paymentMethod,
    String? couponCode,
    required int shippingMethodId,
    required String shippingMethodName,
    required ShippingAddress shippingAddress,
    required List<CartLine> lines,
    String? destinationAccountId,
  }) async {
    final body = _buildCheckoutBody(
      ownerProjectId: ownerProjectId,
      currencyId: currencyId,
      paymentMethod: paymentMethod,
      couponCode: couponCode,
      shippingMethodId: shippingMethodId,
      shippingMethodName: shippingMethodName,
      shippingAddress: shippingAddress,
      lines: lines,
      destinationAccountId: destinationAccountId,
    );
    final json = await api.prepareCheckoutPayment(body);
    return CheckoutSummaryModel.fromJson(json);
  }

  @override
  Future<CheckoutSummaryModel> finalizeStripeCheckout({
    required String paymentIntentId,
    required int ownerProjectId,
    required int currencyId,
    required String paymentMethod,
    String? couponCode,
    required int shippingMethodId,
    required String shippingMethodName,
    required ShippingAddress shippingAddress,
    required List<CartLine> lines,
    String? destinationAccountId,
  }) async {
    final body = _buildCheckoutBody(
      ownerProjectId: ownerProjectId,
      currencyId: currencyId,
      paymentMethod: paymentMethod,
      couponCode: couponCode,
      shippingMethodId: shippingMethodId,
      shippingMethodName: shippingMethodName,
      shippingAddress: shippingAddress,
      lines: lines,
      destinationAccountId: destinationAccountId,
    );
    final json = await api.finalizeCheckoutPayment(
      paymentIntentId: paymentIntentId,
      checkoutBody: body,
    );
    return CheckoutSummaryModel.fromJson(json);
  }

  @override
  Future<void> abandonStripeCheckout({
    required String paymentIntentId,
    required int ownerProjectId,
    required int currencyId,
    required String paymentMethod,
    String? couponCode,
    required int shippingMethodId,
    required String shippingMethodName,
    required ShippingAddress shippingAddress,
    required List<CartLine> lines,
    String? destinationAccountId,
  }) async {
    final body = _buildCheckoutBody(
      ownerProjectId: ownerProjectId,
      currencyId: currencyId,
      paymentMethod: paymentMethod,
      couponCode: couponCode,
      shippingMethodId: shippingMethodId,
      shippingMethodName: shippingMethodName,
      shippingAddress: shippingAddress,
      lines: lines,
      destinationAccountId: destinationAccountId,
    );
    await api.abandonCheckoutPayment(
      paymentIntentId: paymentIntentId,
      checkoutBody: body,
    );
  }

  @override
  Future<void> confirmPayment({required int orderId}) async {
    await api.confirmPayment(orderId: orderId);
  }
}
