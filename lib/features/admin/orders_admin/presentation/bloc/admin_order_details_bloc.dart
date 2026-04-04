import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:build4front/core/exceptions/exception_mapper.dart';

import '../../domain/repositories/admin_orders_repository.dart';
import '../../domain/usecases/get_admin_order_details.dart';
import 'admin_order_details_event.dart';
import 'admin_order_details_state.dart';

class AdminOrderDetailsBloc
    extends Bloc<AdminOrderDetailsEvent, AdminOrderDetailsState> {
  final GetAdminOrderDetails getDetails;
  final AdminOrdersRepository repo;

  AdminOrderDetailsBloc({required this.getDetails, required this.repo})
      : super(AdminOrderDetailsState.initial()) {
    on<AdminOrderDetailsStarted>(_onLoad);
    on<AdminOrderStatusUpdateRequested>(_onUpdateStatus);
    on<AdminOrderMarkCashPaidRequested>(_onMarkCashPaid);
    on<AdminOrderResetCashUnpaidRequested>(_onResetCash);
    on<AdminOrderReopenRequested>(_onReopen);
    on<AdminOrderEditRequested>(_onEditOrder);
  }

  Future<void> _onLoad(
    AdminOrderDetailsStarted event,
    Emitter<AdminOrderDetailsState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearError: true, clearMessage: true));

    try {
      final res = await getDetails(orderId: event.orderId);
      emit(
        state.copyWith(
          loading: false,
          data: res,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          loading: false,
          error: ExceptionMapper.toMessage(e),
        ),
      );
    }
  }

  Future<void> _onUpdateStatus(
    AdminOrderStatusUpdateRequested event,
    Emitter<AdminOrderDetailsState> emit,
  ) async {
    emit(state.copyWith(updating: true, clearError: true, clearMessage: true));

    try {
      await repo.updateOrderStatus(
        orderId: event.orderId,
        status: event.status,
      );

      final res = await getDetails(orderId: event.orderId);
      emit(
        state.copyWith(
          updating: false,
          data: res,
          clearError: true,
          message: 'Status updated',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          updating: false,
          error: ExceptionMapper.toMessage(e),
        ),
      );
    }
  }

  Future<void> _onMarkCashPaid(
    AdminOrderMarkCashPaidRequested event,
    Emitter<AdminOrderDetailsState> emit,
  ) async {
    emit(state.copyWith(updating: true, clearError: true, clearMessage: true));

    try {
      await repo.markCashPaid(orderId: event.orderId);
      final res = await getDetails(orderId: event.orderId);

      emit(
        state.copyWith(
          updating: false,
          data: res,
          message: 'Cash marked as paid',
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          updating: false,
          error: ExceptionMapper.toMessage(e),
        ),
      );
    }
  }

  Future<void> _onResetCash(
    AdminOrderResetCashUnpaidRequested event,
    Emitter<AdminOrderDetailsState> emit,
  ) async {
    emit(state.copyWith(updating: true, clearError: true, clearMessage: true));

    try {
      await repo.resetCashToUnpaid(orderId: event.orderId);
      final res = await getDetails(orderId: event.orderId);

      emit(
        state.copyWith(
          updating: false,
          data: res,
          message: 'Cash reset to unpaid',
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          updating: false,
          error: ExceptionMapper.toMessage(e),
        ),
      );
    }
  }

  Future<void> _onReopen(
    AdminOrderReopenRequested event,
    Emitter<AdminOrderDetailsState> emit,
  ) async {
    emit(state.copyWith(updating: true, clearError: true, clearMessage: true));

    try {
      await repo.reopenOrder(orderId: event.orderId);
      final res = await getDetails(orderId: event.orderId);

      emit(
        state.copyWith(
          updating: false,
          data: res,
          message: 'Order reopened',
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          updating: false,
          error: ExceptionMapper.toMessage(e),
        ),
      );
    }
  }

  Future<void> _onEditOrder(
    AdminOrderEditRequested event,
    Emitter<AdminOrderDetailsState> emit,
  ) async {
    emit(state.copyWith(updating: true, clearError: true, clearMessage: true));

    try {
      await repo.editOrder(orderId: event.orderId, body: event.body);
      final res = await getDetails(orderId: event.orderId);

      emit(
        state.copyWith(
          updating: false,
          data: res,
          message: 'Order updated',
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          updating: false,
          error: ExceptionMapper.toMessage(e),
        ),
      );
    }
  }
}