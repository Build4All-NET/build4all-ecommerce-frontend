import 'package:build4front/features/admin/licensing/domain/entities/available_payment_method.dart';

class AvailablePaymentMethodModel {
  final int id;
  final String code;
  final String typeName;
  final String displayName;
  final String? providerCode;

  const AvailablePaymentMethodModel({
    required this.id,
    required this.code,
    required this.typeName,
    required this.displayName,
    this.providerCode,
  });

  static int _i(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  factory AvailablePaymentMethodModel.fromJson(Map<String, dynamic> j) {
    return AvailablePaymentMethodModel(
      id: _i(j['id']),
      code: (j['code'] ?? '').toString().toUpperCase(),
      typeName: (j['typeName'] ?? j['type'] ?? '').toString(),
      displayName: (j['displayName'] ?? j['name'] ?? '').toString(),
      providerCode: j['providerCode']?.toString(),
    );
  }

  AvailablePaymentMethod toEntity() => AvailablePaymentMethod(
        id: id,
        code: code,
        typeName: typeName,
        displayName: displayName,
        providerCode: providerCode,
      );
}
