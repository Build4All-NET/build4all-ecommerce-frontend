import '../../domain/entities/order_entities.dart';

DateTime? _tryParseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String && v.trim().isNotEmpty) return DateTime.tryParse(v.trim());
  return null;
}

int _toInt(dynamic v, {int fallback = 0}) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim()) ?? fallback;
  return fallback;
}

double _toDouble(dynamic v, {double fallback = 0}) {
  if (v == null) return fallback;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.trim()) ?? fallback;
  return fallback;
}

Map<String, dynamic>? _asMap(dynamic v) {
  if (v is Map) return v.cast<String, dynamic>();
  return null;
}

String _normStatusRaw(String v) {
  final t = v.trim();
  if (t.isEmpty) return '';
  // handle "Cancel Requested" => "CANCEL_REQUESTED"
  return t.toUpperCase().replaceAll(' ', '_');
}

class PaymentSummaryModel {
  final double orderTotal;
  final double paidAmount;
  final double remainingAmount;
  final bool fullyPaid;
  final String paymentState;

  const PaymentSummaryModel({
    required this.orderTotal,
    required this.paidAmount,
    required this.remainingAmount,
    required this.fullyPaid,
    required this.paymentState,
  });

  factory PaymentSummaryModel.fromJson(Map<String, dynamic> json) {
    return PaymentSummaryModel(
      orderTotal: _toDouble(json['orderTotal']),
      paidAmount: _toDouble(json['paidAmount']),
      remainingAmount: _toDouble(json['remainingAmount']),
      fullyPaid: json['fullyPaid'] == true,
      paymentState: (json['paymentState'] ?? '').toString(),
    );
  }

  PaymentSummary toEntity() => PaymentSummary(
        orderTotal: orderTotal,
        paidAmount: paidAmount,
        remainingAmount: remainingAmount,
        fullyPaid: fullyPaid,
        paymentState: paymentState,
      );
}

class OrderCardModel {
  final int orderId;
  final double totalPrice;
  final int linesCount;
  final int itemsCount;
  final String orderStatus;
  final String? orderStatusUi;
  final DateTime? orderDate;
  final String? previewItemName;
  final String? previewImageUrl;
  final bool fullyPaid;
  final PaymentSummaryModel? payment;

  // ✅ NEW
  final String? orderCode;
  final int? orderSeq;

  const OrderCardModel({
    required this.orderId,
    required this.totalPrice,
    required this.linesCount,
    required this.itemsCount,
    required this.orderStatus,
    this.orderStatusUi,
    this.orderDate,
    this.previewItemName,
    this.previewImageUrl,
    required this.fullyPaid,
    this.payment,

    // ✅ NEW
    this.orderCode,
    this.orderSeq,
  });

  factory OrderCardModel.fromJson(Map<String, dynamic> json) {
    final pay = (json['payment'] as Map?)?.cast<String, dynamic>();

    return OrderCardModel(
      orderId: _toInt(json['orderId']),
      totalPrice: _toDouble(json['totalPrice']),
      linesCount: _toInt(json['linesCount']),
      itemsCount: _toInt(json['itemsCount']),
      orderStatus: (json['orderStatus'] ?? '').toString(),
      orderStatusUi: json['orderStatusUi']?.toString(),
      orderDate: _tryParseDate(json['orderDate']),
      previewItemName: json['previewItemName']?.toString(),
      previewImageUrl: json['previewImageUrl']?.toString(),
      fullyPaid: json['fullyPaid'] == true,
      payment: pay == null ? null : PaymentSummaryModel.fromJson(pay),

      // ✅ NEW
      orderCode: json['orderCode']?.toString(),
      orderSeq: json['orderSeq'] == null ? null : _toInt(json['orderSeq']),
    );
  }

  OrderCard toEntity() => OrderCard(
        orderId: orderId,
        totalPrice: totalPrice,
        linesCount: linesCount,
        itemsCount: itemsCount,
        orderStatus: orderStatus,
        orderStatusUi: orderStatusUi,
        orderDate: orderDate,
        previewItemName: previewItemName,
        previewImageUrl: previewImageUrl,
        fullyPaid: fullyPaid,
        payment: payment?.toEntity(),

        // ✅ NEW
        orderCode: orderCode,
        orderSeq: orderSeq,
      );
}

