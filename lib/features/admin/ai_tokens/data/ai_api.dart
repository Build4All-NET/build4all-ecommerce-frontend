import 'package:build4front/core/network/globals.dart' as g;
import 'package:build4front/features/admin/licensing/data/models/available_payment_method_model.dart';
import 'package:build4front/features/admin/licensing/data/models/upgrade_payment_confirmation_model.dart';
import 'package:build4front/features/admin/licensing/data/models/upgrade_payment_intent_model.dart';
import 'package:dio/dio.dart';

import 'models/ai_token_pack.dart';
import 'models/ai_usage_line.dart';
import 'models/ai_wallet.dart';

/// Owner AI token client. AI purchases reuse the EXISTING payment endpoints
/// (same Stripe/PayPal/MPGS/cash flow) with kind=AI_TOKENS — no new gateway code.
class AiApi {
  Dio get _dio => g.appDio ?? g.dio();

  Map<String, dynamic> _map(dynamic d) =>
      d is Map<String, dynamic> ? d : Map<String, dynamic>.from(d as Map? ?? {});

  List<Map<String, dynamic>> _list(dynamic d) =>
      ((d as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

  Future<AiWallet> getWallet() async {
    final res = await _dio.get('/api/ai/apps/me/wallet');
    return AiWallet.fromJson(_map(res.data));
  }

  Future<List<AiTokenPack>> getPacks() async {
    final res = await _dio.get('/api/ai/apps/me/plans');
    return _list(res.data).map(AiTokenPack.fromJson).toList();
  }

  Future<List<AiUsageLine>> getUsage() async {
    final res = await _dio.get('/api/ai/apps/me/usage');
    return _list(res.data).map(AiUsageLine.fromJson).toList();
  }

  Future<List<AvailablePaymentMethodModel>> paymentMethods() async {
    final res = await _dio.get('/api/licensing/apps/me/payment-methods');
    return _list(res.data).map(AvailablePaymentMethodModel.fromJson).toList();
  }

  /// Reuses POST /api/licensing/apps/me/upgrade/payment-intent with kind=AI_TOKENS.
  Future<UpgradePaymentIntentModel> initiatePurchase({
    required String planCode,
    required String billingCycle,
    required String paymentMethodCode,
  }) async {
    final res = await _dio.post(
      '/api/licensing/apps/me/upgrade/payment-intent',
      data: {
        'planCode': planCode,
        'billingCycle': billingCycle,
        'paymentMethodCode': paymentMethodCode,
        'kind': 'AI_TOKENS',
      },
    );
    return UpgradePaymentIntentModel.fromJson(_map(res.data));
  }

  Future<UpgradePaymentConfirmationModel> confirm(String paymentIntentId) async {
    final res = await _dio.post(
      '/api/licensing/apps/me/upgrade/payment-confirm',
      data: {'paymentIntentId': paymentIntentId},
    );
    return UpgradePaymentConfirmationModel.fromJson(_map(res.data));
  }
}
