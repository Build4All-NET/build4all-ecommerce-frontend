import 'package:build4front/core/exceptions/exception_mapper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_my_orders.dart';
import 'orders_event.dart';
import 'orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final GetMyOrders getMyOrders;

  OrdersBloc({required this.getMyOrders}) : super(OrdersState.initial()) {
    on<OrdersStarted>(_onLoad);
    on<OrdersRefreshRequested>(_onLoad);
    on<OrdersFilterChanged>(_onFilterChanged);
  }

  Future<void> _onLoad(OrdersEvent event, Emitter<OrdersState> emit) async {
    emit(state.copyWith(loading: true, error: null));

    try {
      final list = await getMyOrders();
      emit(state.copyWith(
        loading: false,
        orders: list,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: ExceptionMapper.toMessage(e),
      ));
    }
  }

  void _onFilterChanged(OrdersFilterChanged event, Emitter<OrdersState> emit) {
    emit(state.copyWith(filter: event.filter, error: null));
  }
}