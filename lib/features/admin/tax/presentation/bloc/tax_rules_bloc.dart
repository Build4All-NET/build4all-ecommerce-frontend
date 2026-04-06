import 'package:build4front/core/exceptions/exception_mapper.dart';
import 'package:build4front/features/admin/tax/domain/usecase/create_tax_rule.dart';
import 'package:build4front/features/admin/tax/domain/usecase/delete_tax_rule.dart';
import 'package:build4front/features/admin/tax/domain/usecase/list_tax_rules.dart';
import 'package:build4front/features/admin/tax/domain/usecase/update_tax_rule.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'tax_rules_event.dart';
import 'tax_rules_state.dart';

class TaxRulesBloc extends Bloc<TaxRulesEvent, TaxRulesState> {
  final ListTaxRules listRules;
  final CreateTaxRule createRule;
  final UpdateTaxRule updateRule;
  final DeleteTaxRule deleteRule;

  TaxRulesBloc({
    required this.listRules,
    required this.createRule,
    required this.updateRule,
    required this.deleteRule,
  }) : super(TaxRulesState.initial()) {
    on<LoadTaxRules>(_onLoad);
    on<CreateTaxRuleEvent>(_onCreate);
    on<UpdateTaxRuleEvent>(_onUpdate);
    on<DeleteTaxRuleEvent>(_onDelete);
    on<LocalReplaceRules>((e, emit) {
      emit(state.copyWith(rules: e.rules, clearError: true));
    });
  }

  Future<void> _onLoad(
    LoadTaxRules e,
    Emitter<TaxRulesState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final rules = await listRules(authToken: e.token);
      emit(state.copyWith(
        loading: false,
        rules: rules,
        clearError: true,
      ));
    } catch (err) {
      emit(state.copyWith(
        loading: false,
        error: ExceptionMapper.toMessage(err),
      ));
    }
  }

  Future<void> _onCreate(
    CreateTaxRuleEvent e,
    Emitter<TaxRulesState> emit,
  ) async {
    emit(state.copyWith(submitting: true, clearError: true));
    try {
      await createRule(body: e.body, authToken: e.token);
      final rules = await listRules(authToken: e.token);
      emit(state.copyWith(
        submitting: false,
        rules: rules,
        clearError: true,
      ));
    } catch (err) {
      emit(state.copyWith(
        submitting: false,
        error: ExceptionMapper.toMessage(err),
      ));
    }
  }

  Future<void> _onUpdate(
    UpdateTaxRuleEvent e,
    Emitter<TaxRulesState> emit,
  ) async {
    emit(state.copyWith(submitting: true, clearError: true));
    try {
      await updateRule(id: e.id, body: e.body, authToken: e.token);
      final rules = await listRules(authToken: e.token);
      emit(state.copyWith(
        submitting: false,
        rules: rules,
        clearError: true,
      ));
    } catch (err) {
      emit(state.copyWith(
        submitting: false,
        error: ExceptionMapper.toMessage(err),
      ));
    }
  }

  Future<void> _onDelete(
    DeleteTaxRuleEvent e,
    Emitter<TaxRulesState> emit,
  ) async {
    emit(state.copyWith(submitting: true, clearError: true));
    try {
      await deleteRule(id: e.id, authToken: e.token);
      final rules = await listRules(authToken: e.token);
      emit(state.copyWith(
        submitting: false,
        rules: rules,
        clearError: true,
      ));
    } catch (err) {
      emit(state.copyWith(
        submitting: false,
        error: ExceptionMapper.toMessage(err),
      ));
    }
  }
}