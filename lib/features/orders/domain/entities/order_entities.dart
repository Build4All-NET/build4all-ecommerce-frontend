class PaymentSummary {
  final double orderTotal;
  final double paidAmount;
  final double remainingAmount;
  final bool fullyPaid;
  final String paymentState; // UNPAID / PARTIAL / PAID ...

  const PaymentSummary({
    required this.orderTotal,
    required this.paidAmount,
    required this.remainingAmount,
    required this.fullyPaid,
    required this.paymentState,
  });
}

class OrderCard {
  final int orderId;
  final DateTime? orderDate;

  final String orderStatus;
  final String? orderStatusUi;

  final int itemsCount;
  final int linesCount;

  final double totalPrice;

  final String? previewItemName;
  final String? previewImageUrl;

  final bool fullyPaid;
  final PaymentSummary? payment;

  // ✅ NEW
  final String? orderCode;
  final int? orderSeq;

  const OrderCard({
    required this.orderId,
    required this.orderStatus,
    required this.totalPrice,
    required this.itemsCount,
    required this.linesCount,
    required this.fullyPaid,
    this.payment,
    this.orderDate,
    this.orderStatusUi,
    this.previewItemName,
    this.previewImageUrl,

    // ✅ NEW
    this.orderCode,
    this.orderSeq,
  });
}