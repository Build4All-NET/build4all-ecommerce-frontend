import 'package:build4front/features/admin/licensing/domain/entities/plan_pricing.dart';

/// Default fallbacks used when the backend omits pricing.
const double kDefaultMonthlyPrice = 100.0;
const double kDefaultYearlyPrice = 1200.0;
const String kDefaultCurrency = 'USD';

class PlanPricingModel {
  final double monthlyPrice;
  final double yearlyPrice;
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

  static double _d(dynamic v, {required double fallback}) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

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
      monthlyPrice: _d(j['monthlyPrice'], fallback: kDefaultMonthlyPrice),
      yearlyPrice: _d(j['yearlyPrice'], fallback: kDefaultYearlyPrice),
      yearlyDiscountedPrice: _dNullable(j['yearlyDiscountedPrice']),
      currency: (j['currency'] ?? kDefaultCurrency).toString(),
      discountPercent: _iNullable(j['discountPercent']),
      discountLabel: j['discountLabel']?.toString(),
    );
  }

  factory PlanPricingModel.defaults() => const PlanPricingModel(
        monthlyPrice: kDefaultMonthlyPrice,
        yearlyPrice: kDefaultYearlyPrice,
        yearlyDiscountedPrice: null,
        currency: kDefaultCurrency,
        discountPercent: null,
        discountLabel: null,
      );

  PlanPricing toEntity() => PlanPricing(
        monthlyPrice: monthlyPrice,
        yearlyPrice: yearlyPrice,
        yearlyDiscountedPrice: yearlyDiscountedPrice,
        currency: currency,
        discountPercent: discountPercent,
        discountLabel: discountLabel,
      );
}
