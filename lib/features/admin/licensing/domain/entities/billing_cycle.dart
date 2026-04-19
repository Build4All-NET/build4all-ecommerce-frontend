enum BillingCycle { MONTHLY, YEARLY }

BillingCycle billingCycleFromString(String? v) {
  switch ((v ?? '').toUpperCase()) {
    case 'YEARLY':
    case 'ANNUAL':
      return BillingCycle.YEARLY;
    case 'MONTHLY':
    default:
      return BillingCycle.MONTHLY;
  }
}

String billingCycleToString(BillingCycle c) {
  switch (c) {
    case BillingCycle.MONTHLY:
      return 'MONTHLY';
    case BillingCycle.YEARLY:
      return 'YEARLY';
  }
}
