class PlanPricing {
  final double monthlyPrice;
  final double yearlyPrice;
  final double? yearlyDiscountedPrice;
  final String currency;
  final int? discountPercent;
  final String? discountLabel;

  const PlanPricing({
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.yearlyDiscountedPrice,
    required this.currency,
    required this.discountPercent,
    required this.discountLabel,
  });

  bool get hasYearlyDiscount =>
      yearlyDiscountedPrice != null && yearlyDiscountedPrice! < yearlyPrice;

  double get effectiveYearlyPrice =>
      yearlyDiscountedPrice ?? yearlyPrice;

  PlanPricing copyWith({
    double? monthlyPrice,
    double? yearlyPrice,
    double? yearlyDiscountedPrice,
    String? currency,
    int? discountPercent,
    String? discountLabel,
  }) {
    return PlanPricing(
      monthlyPrice: monthlyPrice ?? this.monthlyPrice,
      yearlyPrice: yearlyPrice ?? this.yearlyPrice,
      yearlyDiscountedPrice:
          yearlyDiscountedPrice ?? this.yearlyDiscountedPrice,
      currency: currency ?? this.currency,
      discountPercent: discountPercent ?? this.discountPercent,
      discountLabel: discountLabel ?? this.discountLabel,
    );
  }
}
