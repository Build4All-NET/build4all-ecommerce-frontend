import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:build4front/core/exceptions/exception_mapper.dart';

import '../../domain/repositories/admin_orders_repository.dart';
import '../../domain/entities/admin_order_entities.dart';
import 'admin_orders_event.dart';
import 'admin_orders_state.dart';

class AdminOrdersBloc extends Bloc<AdminOrdersEvent, AdminOrdersState> {
  final AdminOrdersRepository repo;

  List<OrderHeaderRow> _all = const [];

  AdminOrdersBloc({required this.repo}) : super(AdminOrdersState.initial()) {
    on<AdminOrdersStarted>(_onLoad);
    on<AdminOrdersRefreshRequested>(_onRefresh);
    on<AdminOrdersStatusChanged>(_onStatusChanged);
  }

  Future<void> _fetchAll(Emitter<AdminOrdersState> emit) async {
    try {
      final list = await repo.getOrders(status: null);
      _all = list;

      emit(
        state.copyWith(
          loading: false,
          orders: _applyStatus(_all, state.statusFilter),
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

  Future<void> _onLoad(
    AdminOrdersStarted event,
    Emitter<AdminOrdersState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearError: true));
    await _fetchAll(emit);
  }

  Future<void> _onRefresh(
    AdminOrdersRefreshRequested event,
    Emitter<AdminOrdersState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearError: true));
    await _fetchAll(emit);
  }

  Future<void> _onStatusChanged(
    AdminOrdersStatusChanged event,
    Emitter<AdminOrdersState> emit,
  ) async {
    emit(
      state.copyWith(
        statusFilter: event.status,
        orders: _applyStatus(_all, event.status),
        loading: false,
        clearError: true,
      ),
    );
  }

  List<OrderHeaderRow> _applyStatus(List<OrderHeaderRow> list, String? st) {
    final s = (st ?? '').trim().toUpperCase();
    if (s.isEmpty) return list;

    return list.where((o) => o.status.toUpperCase() == s).toList();
  }
}