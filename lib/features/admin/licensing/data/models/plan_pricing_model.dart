import 'package:build4front/features/admin/licensing/domain/entities/plan_pricing.dart';

/// Used only when the backend response does not provide any currency at all.
/// Numeric prices are never defaulted — a missing price is propagated as
/// null so the UI can render "—" instead of a fake amount.
const String kDefaultCurrency = 'USD';

class PlanPricingModel {
  final double? monthlyPrice;
  final double? yearlyPrice;
  final double? yearlyDiscountedPrice;
  final String currency;
  final int? discountPercent;
  final String? discountLabel;

  const PlanPricingModel({
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.yearlyDiscountedPrice,
    required this.currency,
    required this.discountPercent,
    required this.discountLabel,
  });

  static double? _dNullable(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int? _iNullable(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  factory PlanPricingModel.fromJson(Map<String, dynamic> j) {
    return PlanPricingModel(
      monthlyPrice: _dNullable(j['monthlyPrice']),
      yearlyPrice: _dNullable(j['yearlyPrice']),
      yearlyDiscountedPrice: _dNullable(j['yearlyDiscountedPrice']),
      currency: (j['currency'] ?? kDefaultCurrency).toString(),
      discountPercent: _iNullable(j['discountPercent']),
      discountLabel: j['discountLabel']?.toString(),
    );
  }

  PlanPricing toEntity() => PlanPricing(
        monthlyPrice: monthlyPrice,
        yearlyPrice: yearlyPrice,
        yearlyDiscountedPrice: yearlyDiscountedPrice,
        currency: currency,
        discountPercent: discountPercent,
        discountLabel: discountLabel,
      );
}
