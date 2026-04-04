import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:build4front/core/exceptions/exception_mapper.dart';
import 'package:build4front/features/catalog/domain/entities/currency.dart';
import 'package:build4front/features/catalog/domain/usecases/get_currency_by_id.dart';

class CurrencyState {
  final bool loading;
  final Currency? currency;
  final String? error;

  const CurrencyState({this.loading = false, this.currency, this.error});

  CurrencyState copyWith({bool? loading, Currency? currency, String? error}) {
    return CurrencyState(
      loading: loading ?? this.loading,
      currency: currency ?? this.currency,
      error: error,
    );
  }
}

class CurrencyCubit extends Cubit<CurrencyState> {
  final GetCurrencyById getCurrencyById;

  CurrencyCubit({required this.getCurrencyById}) : super(const CurrencyState());

  Future<void> load(int currencyId) async {
    if (currencyId <= 0) return;
    if (state.currency?.id == currencyId) return;

    emit(state.copyWith(loading: true, error: null));

    try {
      final c = await getCurrencyById(currencyId);
      emit(
        state.copyWith(
          loading: false,
          currency: c,
          error: null,
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

  String get symbol => (state.currency?.symbol ?? '').trim();
}