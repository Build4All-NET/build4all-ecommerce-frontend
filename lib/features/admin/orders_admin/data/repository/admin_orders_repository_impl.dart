import '../../domain/entities/admin_order_entities.dart';
import '../../domain/repositories/admin_orders_repository.dart';
import '../models/admin_orders_models.dart';
import '../services/admin_orders_api_service.dart';

class AdminOrdersRepositoryImpl implements AdminOrdersRepository {
  final AdminOrdersApiService api;

  AdminOrdersRepositoryImpl({required this.api});

  @override
  Future<List<OrderHeaderRow>> getOrders({String? status}) async {
    final raw = await api.getOrdersRaw(status: status);

    return raw
        .whereType<Map>()
        .map((m) => OrderHeaderRowModel.fromJson(m.cast<String, dynamic>()))
        .map((m) => m.toEntity())
        .toList();
  }

  @override
  Future<OrderDetailsResponse> getOrderDetails({required int orderId}) async {
    final raw = await api.getOrderDetailsRaw(orderId: orderId);
    return OrderDetailsResponseModel.fromJson(raw).toEntity();
  }

  @override
  Future<void> updateOrderStatus({
    required int orderId,
    required String status,
  }) async {
    await api.updateOrderStatusRaw(orderId: orderId, status: status);
  }

  @override
  Future<void> markCashPaid({required int orderId}) async {
    await api.markCashPaidRaw(orderId: orderId);
  }

  @override
  Future<void> resetCashToUnpaid({required int orderId}) async {
    await api.resetCashToUnpaidRaw(orderId: orderId);
  }

  @override
  Future<void> editOrder({
    required int orderId,
    required Map<String, dynamic> body,
  }) async {
    await api.editOrderRaw(orderId: orderId, body: body);
  }

  @override
  Future<void> reopenOrder({required int orderId}) async {
    await api.reopenOrderRaw(orderId: orderId);
  }
}