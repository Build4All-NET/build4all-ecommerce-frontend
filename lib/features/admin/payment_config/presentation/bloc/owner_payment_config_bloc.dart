import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/exceptions/exception_mapper.dart';
import '../../domain/usecases/get_owner_payment_methods.dart';
import '../../domain/usecases/save_owner_payment_method_config.dart';
import '../../domain/usecases/test_owner_payment_method_config.dart';
import 'owner_payment_config_event.dart';
import 'owner_payment_config_state.dart';

class OwnerPaymentConfigBloc
    extends Bloc<OwnerPaymentConfigEvent, OwnerPaymentConfigState> {
  final GetOwnerPaymentMethods getMethods;
  final SaveOwnerPaymentMethodConfig saveConfig;
  final TestOwnerPaymentMethodConfig testConfig;

  OwnerPaymentConfigBloc({
    required this.getMethods,
    required this.saveConfig,
    required this.testConfig,
  }) : super(OwnerPaymentConfigState.initial()) {
    on<OwnerPaymentConfigLoad>(_onLoad);
    on<OwnerPaymentConfigSave>(_onSave);
    on<OwnerPaymentConfigTest>(_onTest);
    on<OwnerPaymentConfigTestResultCleared>(_onClearTestResult);
  }

  Future<void> _onLoad(
    OwnerPaymentConfigLoad event,
    Emitter<OwnerPaymentConfigState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));

    try {
      final items = await getMethods();
      emit(state.copyWith(
        loading: false,
        items: items,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: ExceptionMapper.toMessage(e),
      ));
    }
  }

  Future<void> _onSave(
    OwnerPaymentConfigSave event,
    Emitter<OwnerPaymentConfigState> emit,
  ) async {
    final code = event.methodName.toUpperCase();
    final nextSaving = {...state.savingCodes, code};

    emit(state.copyWith(
      savingCodes: nextSaving,
      error: null,
    ));

    try {
      await saveConfig(
        methodName: event.methodName,
        enabled: event.enabled,
        configValues: event.configValues,
      );

      final updated = state.items.map((it) {
        if (it.name.toUpperCase() != code) return it;

        return it.copyWith(
          projectEnabled: event.enabled,
          configValues: event.enabled
              ? Map<String, dynamic>.from(event.configValues)
              : it.configValues,
        );
      }).toList();

      final afterSaving = {...state.savingCodes}..remove(code);

      emit(state.copyWith(
        items: updated,
        savingCodes: afterSaving,
      ));
    } catch (e) {
      final afterSaving = {...state.savingCodes}..remove(code);

      emit(state.copyWith(
        savingCodes: afterSaving,
        error: ExceptionMapper.toMessage(e),
      ));
    }
  }

  Future<void> _onTest(
    OwnerPaymentConfigTest event,
    Emitter<OwnerPaymentConfigState> emit,
  ) async {
    final code = event.methodName.toUpperCase();
    final nextTesting = {...state.testingCodes, code};
    final results = {...state.testResults}..remove(code);

    emit(state.copyWith(
      testingCodes: nextTesting,
      testResults: results,
    ));

    TestOutcome outcome;
    try {
      final r = await testConfig(
        methodName: event.methodName,
        configValues: event.configValues,
      );
      outcome = TestOutcome(ok: r.ok, error: r.error);
    } catch (e) {
      outcome = TestOutcome(ok: false, error: ExceptionMapper.toMessage(e));
    }

    final afterTesting = {...state.testingCodes}..remove(code);
    emit(state.copyWith(
      testingCodes: afterTesting,
      testResults: {...state.testResults, code: outcome},
    ));
  }

  Future<void> _onClearTestResult(
    OwnerPaymentConfigTestResultCleared event,
    Emitter<OwnerPaymentConfigState> emit,
  ) async {
    final code = event.methodName.toUpperCase();
    if (!state.testResults.containsKey(code)) return;
    final next = {...state.testResults}..remove(code);
    emit(state.copyWith(testResults: next));
  }
}