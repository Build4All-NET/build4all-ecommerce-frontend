import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:build4front/features/auth/data/services/admin_token_store.dart';

import 'package:build4front/common/widgets/app_toast.dart';

import 'package:build4front/features/admin/tax/domain/usecase/create_tax_rule.dart';
import 'package:build4front/features/admin/tax/domain/usecase/delete_tax_rule.dart';
import 'package:build4front/features/admin/tax/domain/usecase/list_tax_rules.dart';
import 'package:build4front/features/admin/tax/domain/usecase/update_tax_rule.dart';

import '../../data/services/tax_api_service.dart';
import '../../data/repositories/tax_repository_impl.dart';

import '../../domain/entities/tax_rule.dart';
import '../bloc/tax_rules_bloc.dart';
import '../bloc/tax_rules_event.dart';
import '../bloc/tax_rules_state.dart';
import '../widgets/tax_rule_form_sheet.dart';

import '../widgets/admin_tax_rule_card.dart';
import '../widgets/admin_tax_empty_state.dart';
import '../widgets/admin_tax_filters_bar.dart';

class AdminTaxRulesScreen extends StatelessWidget {
  /// ✅ Keep temporarily ONLY because your TaxRuleFormSheet still expects it.
  /// Once we update the sheet, we can remove this completely.
  final int ownerProjectId;

  const AdminTaxRulesScreen({super.key, required this.ownerProjectId});

  @override
  Widget build(BuildContext context) {
    final repo = TaxRepositoryImpl(TaxApiService());

    return BlocProvider(
      create: (_) => TaxRulesBloc(
        listRules: ListTaxRules(repo),
        createRule: CreateTaxRule(repo),
        updateRule: UpdateTaxRule(repo),
        deleteRule: DeleteTaxRule(repo),
      ),
      child: _AdminTaxRulesView(ownerProjectId: ownerProjectId),
    );
  }
}

class _AdminTaxRulesView extends StatefulWidget {
  final int ownerProjectId;
  const _AdminTaxRulesView({required this.ownerProjectId});

  @override
  State<_AdminTaxRulesView> createState() => _AdminTaxRulesViewState();
}

class _AdminTaxRulesViewState extends State<_AdminTaxRulesView> {
  final _store = AdminTokenStore();

  String? _token;
  bool _loadingToken = true;

  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _loadTokenAndRules();
  }

  Future<void> _loadTokenAndRules() async {
    final t = await _store.getToken();
    if (!mounted) return;

    setState(() {
      _token = t;
      _loadingToken = false;
    });

    if (t != null && t.isNotEmpty) {
      context.read<TaxRulesBloc>().add(
            LoadTaxRules(token: t), // ✅ token-only
          );
    }
  }

  void _showNoTokenMessage() {
    final l = AppLocalizations.of(context)!;
    AppToast.error(context, l.adminSessionExpired);
  }

  Future<void> _refresh() async {
    if (_token == null || _token!.isEmpty) {
      _showNoTokenMessage();
      return;
    }

    context.read<TaxRulesBloc>().add(
          LoadTaxRules(token: _token!), // ✅ token-only
        );
  }

  // ✅ PRO bottom sheet wrapper (no overflow when keyboard opens)
  Future<T?> _showProSheet<T>(Widget sheet) async {
    final tokens = context.read<ThemeCubit>().state.tokens;
    final radius = tokens.card.radius;
    final surface = tokens.colors.surface;

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
      ),
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        final h = MediaQuery.of(ctx).size.height;

        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SizedBox(
            height: h * 0.90,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: sheet,
            ),
          ),
        );
      },
    );
  }

  Future<void> _openCreateSheet() async {
    if (_loadingToken) return;

    if (_token == null || _token!.isEmpty) {
      _showNoTokenMessage();
      return;
    }

    // ✅ Keep ownerProjectId only if your sheet needs it.
    final body = await _showProSheet<Map<String, dynamic>>(
      TaxRuleFormSheet(ownerProjectId: widget.ownerProjectId),
    );

    if (body == null) return;

    context.read<TaxRulesBloc>().add(
          CreateTaxRuleEvent(
            body: body,
            token: _token!,
          ),
        );

    final l = AppLocalizations.of(context)!;
    AppToast.error(context, l.adminCreated ?? 'Created');
  }

  Future<void> _openEditSheet(TaxRule rule) async {
    if (_loadingToken) return;

    if (_token == null || _token!.isEmpty) {
      _showNoTokenMessage();
      return;
    }

    final body = await _showProSheet<Map<String, dynamic>>(
      TaxRuleFormSheet(ownerProjectId: widget.ownerProjectId, initial: rule),
    );

    if (body == null) return;

    context.read<TaxRulesBloc>().add(
          UpdateTaxRuleEvent(
            id: rule.id,
            body: body,
            token: _token!,
          ),
        );

    final l = AppLocalizations.of(context)!;
    AppToast.error(context, l.adminUpdated ?? 'Updated');
  }

  Future<void> _confirmAndDelete(TaxRule rule) async {
    if (_loadingToken) return;

    if (_token == null || _token!.isEmpty) {
      _showNoTokenMessage();
      return;
    }

    final l = AppLocalizations.of(context)!;
    final tokens = context.read<ThemeCubit>().state.tokens;
    final c = tokens.colors;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.adminDelete ?? 'Delete'),
        content: Text(
          l.adminConfirmDelete ?? 'Are you sure you want to delete this item?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.adminCancel ?? 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: c.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.adminDelete ?? 'Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    context.read<TaxRulesBloc>().add(
          DeleteTaxRuleEvent(
            id: rule.id,
            token: _token!,
          ),
        );

    AppToast.error(context, l.adminDeleted ?? 'Deleted');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final c = tokens.colors;
    final spacing = tokens.spacing;
    final text = tokens.typography;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        title: Text(
          l.adminTaxRulesTitle,
          style: text.titleMedium.copyWith(
            color: c.label,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: Icon(Icons.refresh, color: c.body),
            tooltip: l.refreshLabel ?? 'Refresh',
          ),
          IconButton(
            onPressed: (_loadingToken || _token == null || _token!.isEmpty)
                ? null
                : _openCreateSheet,
            icon: Icon(Icons.add, color: c.primary),
            tooltip: l.adminTaxAddRule,
          ),
        ],
      ),
      body: _loadingToken
          ? Center(child: CircularProgressIndicator(color: c.primary))
          : (_token == null || _token!.isEmpty)
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(spacing.lg),
                    child: Text(
                      l.adminSessionExpired,
                      style: text.bodyMedium.copyWith(color: c.danger),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : BlocBuilder<TaxRulesBloc, TaxRulesState>(
                  builder: (context, state) {
                    if (state.loading) {
                      return Center(
                        child: CircularProgressIndicator(color: c.primary),
                      );
                    }

                    if (state.error != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        AppToast.error(context, state.error!);
                      });

                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(spacing.lg),
                          child: Text(
                            state.error!,
                            style: text.bodyMedium.copyWith(color: c.danger),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    final all = state.rules;
                    final filtered =
                        _showAll ? all : all.where((r) => r.enabled).toList();

                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.all(spacing.lg),
                        children: [
                          AdminTaxFiltersBar(
                            showAll: _showAll,
                            onChangedShowAll: (v) =>
                                setState(() => _showAll = v),
                          ),
                          SizedBox(height: spacing.md),
                          if (filtered.isEmpty)
                            AdminTaxEmptyState(onAdd: _openCreateSheet)
                          else
                            ...filtered.map(
                              (r) => Padding(
                                padding: EdgeInsets.only(bottom: spacing.sm),
                                child: AdminTaxRuleCard(
                                  rule: r,
                                  onEdit: () => _openEditSheet(r),
                                  onDelete: () => _confirmAndDelete(r),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
