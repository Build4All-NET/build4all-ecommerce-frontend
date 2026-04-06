import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/exceptions/exception_mapper.dart';
import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:build4front/features/auth/data/services/admin_token_store.dart';

import 'package:build4front/common/widgets/app_toast.dart';

import '../../data/services/shipping_api_service.dart';
import '../../data/repositories/shipping_repository_impl.dart';

import '../../domain/entities/shipping_method.dart';
import '../../domain/usecases/list_shipping_methods.dart';
import '../../domain/usecases/create_shipping_method.dart';
import '../../domain/usecases/update_shipping_method.dart';
import '../../domain/usecases/delete_shipping_method.dart';

import '../bloc/shipping_methods_bloc.dart';
import '../bloc/shipping_methods_event.dart';
import '../bloc/shipping_methods_state.dart';

import '../widgets/shipping_method_form_sheet.dart';
import '../widgets/admin_shipping_filters_bar.dart';
import '../widgets/admin_shipping_empty_state.dart';
import '../widgets/admin_shipping_method_card.dart';

class AdminShippingMethodsScreen extends StatelessWidget {
  final int ownerProjectId;

  const AdminShippingMethodsScreen({super.key, required this.ownerProjectId});

  @override
  Widget build(BuildContext context) {
    final repo = ShippingRepositoryImpl(ShippingApiService());

    return BlocProvider(
      create: (_) => ShippingMethodsBloc(
        listMethods: ListShippingMethods(repo),
        createMethod: CreateShippingMethod(repo),
        updateMethod: UpdateShippingMethod(repo),
        deleteMethod: DeleteShippingMethod(repo),
      ),
      child: _AdminShippingMethodsView(ownerProjectId: ownerProjectId),
    );
  }
}

class _AdminShippingMethodsView extends StatefulWidget {
  final int ownerProjectId;

  const _AdminShippingMethodsView({required this.ownerProjectId});

  @override
  State<_AdminShippingMethodsView> createState() =>
      _AdminShippingMethodsViewState();
}

class _AdminShippingMethodsViewState extends State<_AdminShippingMethodsView> {
  final _store = AdminTokenStore();

  String? _token;
  bool _loadingToken = true;

  ShippingMethodsFilter _filter = ShippingMethodsFilter.enabledOnly;

  String? _lastShownError;

  @override
  void initState() {
    super.initState();
    _loadTokenAndData();
  }

  String _friendlyError(Object err) {
    return ExceptionMapper.toMessage(err);
  }

  void _showNoTokenMessage() {
    final l = AppLocalizations.of(context)!;
    AppToast.error(context, l.adminSessionExpired);
  }

  Future<void> _loadTokenAndData() async {
    final t = await _store.getToken();
    if (!mounted) return;

    setState(() {
      _token = t;
      _loadingToken = false;
    });

    if (t != null && t.isNotEmpty) {
      context.read<ShippingMethodsBloc>().add(
            LoadShippingMethods(token: t),
          );
    }
  }

  Future<void> _refresh() async {
    if (_token == null || _token!.isEmpty) {
      _showNoTokenMessage();
      return;
    }

    context.read<ShippingMethodsBloc>().add(
          LoadShippingMethods(token: _token!),
        );
  }

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

    final body = await _showProSheet<Map<String, dynamic>>(
      ShippingMethodFormSheet(ownerProjectId: widget.ownerProjectId),
    );

    if (body == null) return;

    context.read<ShippingMethodsBloc>().add(
          CreateShippingMethodEvent(
            body: body,
            token: _token!,
          ),
        );

    final l = AppLocalizations.of(context)!;
    AppToast.success(context, l.adminCreated ?? 'Created');
  }

  Future<void> _openEditSheet(ShippingMethod method) async {
    if (_loadingToken) return;

    if (_token == null || _token!.isEmpty) {
      _showNoTokenMessage();
      return;
    }

    final body = await _showProSheet<Map<String, dynamic>>(
      ShippingMethodFormSheet(
        ownerProjectId: widget.ownerProjectId,
        initial: method,
      ),
    );

    if (body == null) return;

    context.read<ShippingMethodsBloc>().add(
          UpdateShippingMethodEvent(
            id: method.id,
            body: body,
            token: _token!,
          ),
        );

    final l = AppLocalizations.of(context)!;
    AppToast.success(context, l.adminUpdated ?? 'Updated');
  }

  Future<void> _confirmAndDisable(ShippingMethod method) async {
    if (_loadingToken) return;

    if (_token == null || _token!.isEmpty) {
      _showNoTokenMessage();
      return;
    }

    if (!method.enabled) return;

    final l = AppLocalizations.of(context)!;
    final tokens = context.read<ThemeCubit>().state.tokens;
    final c = tokens.colors;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.adminDisable),
        content: Text(l.adminDisableShippingMethodMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.adminCancel ?? 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: c.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.adminDisable),
          ),
        ],
      ),
    );

    if (ok != true) return;

    context.read<ShippingMethodsBloc>().add(
          DeleteShippingMethodEvent(
            id: method.id,
            token: _token!,
          ),
        );

    AppToast.success(context, l.adminShippingMethodDisabled);
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
          l.adminShippingTitle ?? 'Shipping Methods',
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
            tooltip: l.adminShippingAdd ?? 'Add method',
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
              : BlocBuilder<ShippingMethodsBloc, ShippingMethodsState>(
                  builder: (context, state) {
                    if (state.loading) {
                      return Center(
                        child: CircularProgressIndicator(color: c.primary),
                      );
                    }

                    if (state.error != null) {
                      final friendly = _friendlyError(state.error!);

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_lastShownError != friendly) {
                          _lastShownError = friendly;
                          AppToast.error(context, friendly);
                        }
                      });

                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(spacing.lg),
                          child: Text(
                            friendly,
                            style: text.bodyMedium.copyWith(color: c.danger),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    _lastShownError = null;

                    final all = state.methods;

                    final filtered = switch (_filter) {
                      ShippingMethodsFilter.enabledOnly =>
                        all.where((m) => m.enabled).toList(),
                      ShippingMethodsFilter.disabledOnly =>
                        all.where((m) => !m.enabled).toList(),
                      ShippingMethodsFilter.all => all,
                    };

                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.all(spacing.lg),
                        children: [
                          AdminShippingFiltersBar(
                            filter: _filter,
                            onChanged: (value) => setState(() => _filter = value),
                          ),
                          SizedBox(height: spacing.md),
                          if (filtered.isEmpty)
                            AdminShippingEmptyState(onAdd: _openCreateSheet)
                          else
                            ...filtered.map(
                              (m) => Padding(
                                padding: EdgeInsets.only(bottom: spacing.sm),
                                child: AdminShippingMethodCard(
                                  method: m,
                                  onEdit: () => _openEditSheet(m),
                                  onDisable: () => _confirmAndDisable(m),
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