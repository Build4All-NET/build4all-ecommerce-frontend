import 'package:build4front/core/exceptions/exception_mapper.dart';
import 'package:build4front/features/items/domain/entities/item_details.dart';
import 'package:build4front/features/items/domain/usecases/get_item_details.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'item_details_event.dart';
part 'item_details_state.dart';

class ItemDetailsBloc extends Bloc<ItemDetailsEvent, ItemDetailsState> {
  final GetItemDetails getItemDetails;

  ItemDetailsBloc({required this.getItemDetails})
      : super(const ItemDetailsState()) {
    on<ItemDetailsStarted>(_onStarted);
  }

  Future<void> _onStarted(
    ItemDetailsStarted event,
    Emitter<ItemDetailsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final details = await getItemDetails(event.itemId, token: event.token);
      emit(state.copyWith(
        isLoading: false,
        details: details,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: ExceptionMapper.toMessage(e),
      ));
    }
  }
}