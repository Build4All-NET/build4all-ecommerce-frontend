enum SubscriptionStatus { ACTIVE, EXPIRED, SUSPENDED, CANCELED }

SubscriptionStatus subscriptionStatusFromString(String? v) {
  switch ((v ?? '').toUpperCase().trim()) {
    case 'ACTIVE':
      return SubscriptionStatus.ACTIVE;
    case 'EXPIRED':
      return SubscriptionStatus.EXPIRED;
    case 'SUSPENDED':
      return SubscriptionStatus.SUSPENDED;
    case 'CANCELED':
      return SubscriptionStatus.CANCELED;
    default:
      return SubscriptionStatus.EXPIRED;
  }
}
