class PlanPricing {
  /// Monthly price in [currency] units. `null` when the backend has no
  /// active `license_plan_pricing` row for (planCode, MONTHLY).
  final double? monthlyPrice;

  /// Yearly list price. `null` when no active YEARLY pricing row exists.
  final double? yearlyPrice;

  /// Discounted yearly price (overrides [yearlyPrice] when present).
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
      yearlyDiscountedPrice != null &&
      yearlyPrice != null &&
      yearlyDiscountedPrice! < yearlyPrice!;

  /// Yearly price the user actually pays. `null` if neither a discounted
  /// nor a list yearly price is configured.
  double? get effectiveYearlyPrice => yearlyDiscountedPrice ?? yearlyPrice;

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
