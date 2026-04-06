import '../../domain/entities/order_entities.dart';
import '../../domain/repositories/orders_repository.dart';
import '../models/orders_models.dart';
import '../services/orders_api_service.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  final OrdersApiService api;

  OrdersRepositoryImpl({required this.api});

  @override
  Future<List<OrderCard>> getMyOrders() async {
    final raw = await api.getMyOrdersRaw();

    return raw
        .whereType<Map>()
        .map((m) => OrderCardModel.fromJson(m.cast<String, dynamic>()))
        .map((m) => m.toEntity())
        .toList();
  }
}