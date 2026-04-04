import 'package:build4front/core/exceptions/exception_mapper.dart';
import 'package:build4front/features/admin/orders_admin/data/models/cash_mark_paid_result_model.dart';
import 'package:dio/dio.dart';

import  'package:build4front/features/admin/orders_admin/data/models/cash_mark_paid_result_model.dart';
import 'package:dio/dio.dart';

import '../../domain/entities/admin_order_entities.dart';
import '../../domain/repositories/admin_orders_repository.dart';
import '../models/admin_orders_models.dart';
import '../services/admin_orders_api_service.dart';

class AdminOrdersRepositoryImpl implements AdminOrdersRepository {
  final AdminOrdersApiService api;

  AdminOrdersRepositoryImpl({required this.api});

  Never _throwNice(DioException e, {String fallback = 'Request failed'}) {
    final msg = ExceptionMapper.toMessage(e).trim();
    throw Exception(msg.isEmpty ? fallback : msg);
  }

  String _cleanUnknown(Object e, {String fallback = 'Request failed'}) {
    final msg = ExceptionMapper.toMessage(e).trim();
    return msg.isEmpty ? fallback : msg;
  }

  @override
  Future<List<OrderHeaderRow>> getOrders({String? status}) async {
    try {
      final raw = await api.getOrdersRaw(status: status);
      return raw
          .whereType<Map>()
          .map((m) => OrderHeaderRowModel.fromJson(m.cast<String, dynamic>()))
          .map((m) => m.toEntity())
          .toList();
    } on DioException catch (e) {
      _throwNice(e, fallback: 'Failed to load orders');
    } catch (e) {
      throw Exception(_cleanUnknown(e, fallback: 'Failed to load orders'));
    }
  }

  @override
  Future<OrderDetailsResponse> getOrderDetails({required int orderId}) async {
    try {
      final raw = await api.getOrderDetailsRaw(orderId: orderId);
      return OrderDetailsResponseModel.fromJson(raw).toEntity();
    } on DioException catch (e) {
      _throwNice(e, fallback: 'Failed to load order details');
    } catch (e) {
      throw Exception(
        _cleanUnknown(e, fallback: 'Failed to load order details'),
      );
    }
  }

  @override
  Future<void> updateOrderStatus({
    required int orderId,
    required String status,
  }) async {
    try {
      await api.updateOrderStatusRaw(orderId: orderId, status: status);
    } on DioException catch (e) {
      _throwNice(e, fallback: 'Failed to update order status');
    } catch (e) {
      throw Exception(
        _cleanUnknown(e, fallback: 'Failed to update order status'),
      );
    }
  }

  @override
  Future<void> markCashPaid({required int orderId}) async {
    try {
      await api.markCashPaidRaw(orderId: orderId);
    } on DioException catch (e) {
      _throwNice(e, fallback: 'Failed to mark cash as paid');
    } catch (e) {
      throw Exception(
        _cleanUnknown(e, fallback: 'Failed to mark cash as paid'),
      );
    }
  }

  @override
  Future<void> resetCashToUnpaid({required int orderId}) async {
    try {
      await api.resetCashToUnpaidRaw(orderId: orderId);
    } on DioException catch (e) {
      _throwNice(e, fallback: 'Failed to reset cash to unpaid');
    } catch (e) {
      throw Exception(
        _cleanUnknown(e, fallback: 'Failed to reset cash to unpaid'),
      );
    }
  }

  @override
  Future<void> editOrder({
    required int orderId,
    required Map<String, dynamic> body,
  }) async {
    try {
      await api.editOrderRaw(orderId: orderId, body: body);
    } on DioException catch (e) {
      _throwNice(e, fallback: 'Failed to edit order');
    } catch (e) {
      throw Exception(_cleanUnknown(e, fallback: 'Failed to edit order'));
    }
  }

  @override
  Future<void> reopenOrder({required int orderId}) async {
    try {
      await api.reopenOrderRaw(orderId: orderId);
    } on DioException catch (e) {
      _throwNice(e, fallback: 'Failed to reopen order');
    } catch (e) {
      throw Exception(_cleanUnknown(e, fallback: 'Failed to reopen order'));
    }
  }
}