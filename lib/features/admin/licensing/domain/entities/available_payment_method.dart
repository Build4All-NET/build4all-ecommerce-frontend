class AvailablePaymentMethod {
  final int id;
  final String code;          // type code — e.g. STRIPE / CASH
  final String typeName;      // type display name — e.g. "Cash"
  final String displayName;   // method display name — e.g. "Pay at counter"
  final String? providerCode; // optional, e.g. "CASH_LOCAL"

  const AvailablePaymentMethod({
    required this.id,
    required this.code,
    required this.typeName,
    required this.displayName,
    this.providerCode,
  });

  /// The code sent to the backend when the owner chooses this method.
  /// Prefer providerCode (more specific) if present, otherwise type code.
  String get selectionCode =>
      (providerCode != null && providerCode!.isNotEmpty)
          ? providerCode!
          : code;

  bool get isStripe => code.toUpperCase() == 'STRIPE';
}
