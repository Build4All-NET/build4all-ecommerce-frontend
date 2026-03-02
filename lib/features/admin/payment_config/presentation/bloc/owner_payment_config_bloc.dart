import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_owner_payment_methods.dart';
import '../../domain/usecases/save_owner_payment_method_config.dart';
import 'owner_payment_config_event.dart';
import 'owner_payment_config_state.dart';

class OwnerPaymentConfigBloc
    extends Bloc<OwnerPaymentConfigEvent, OwnerPaymentConfigState> {
  final GetOwnerPaymentMethods getMethods;
  final SaveOwnerPaymentMethodConfig saveConfig;

  OwnerPaymentConfigBloc({
    required this.getMethods,
    required this.saveConfig,
  }) : super(OwnerPaymentConfigState.initial()) {
    on<OwnerPaymentConfigLoad>(_onLoad);
    on<OwnerPaymentConfigSave>(_onSave);
  }

  Future<void> _onLoad(
    OwnerPaymentConfigLoad event,
    Emitter<OwnerPaymentConfigState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final items = await getMethods();
      emit(state.copyWith(loading: false, items: items, error: null));
    } catch (e) {
      emit(state.copyWith(loading: false, error: _prettyError(e)));
    }
  }

  Future<void> _onSave(
    OwnerPaymentConfigSave event,
    Emitter<OwnerPaymentConfigState> emit,
  ) async {
    final code = event.methodName.toUpperCase();
    final nextSaving = {...state.savingCodes, code};
    emit(state.copyWith(savingCodes: nextSaving, error: null));

    try {
      await saveConfig(
        methodName: event.methodName,
        enabled: event.enabled,
        configValues: event.configValues,
      );

      // optimistic UI update
      final updated = state.items.map((it) {
        if (it.name.toUpperCase() != code) return it;

        return it.copyWith(
          projectEnabled: event.enabled,
          configValues: event.enabled
              ? Map<String, dynamic>.from(event.configValues)
              : it.configValues, // keep old values when disabling
        );
      }).toList();

      final afterSaving = {...state.savingCodes}..remove(code);
      emit(state.copyWith(items: updated, savingCodes: afterSaving));
    } catch (e) {
      final afterSaving = {...state.savingCodes}..remove(code);
      emit(state.copyWith(savingCodes: afterSaving, error: _prettyError(e)));
    }
  }

  String _prettyError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final msg = data['error'] ?? data['message'];
        if (msg != null) return msg.toString();
      }
      return e.message ?? 'Request failed';
    }
    return e.toString();
  }
}