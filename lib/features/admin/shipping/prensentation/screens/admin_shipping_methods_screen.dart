import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  bool _showAll = false;

  // prevent repeating same error toast on rebuild
  String? _lastShownError;

  @override
  void initState() {
    super.initState();
    _loadTokenAndData();
  }

  // ----------------- Friendly errors -----------------

  String _friendlyError(Object err) {
    final l = AppLocalizations.of(context)!;

    // If your bloc throws a plain message already
    final msg = err.toString();

    // DioException mapping
    if (err is DioException) {
      // Timeout / connection
      if (err.type == DioExceptionType.connectionTimeout ||
          err.type == DioExceptionType.sendTimeout ||
          err.type == DioExceptionType.receiveTimeout) {
        return l.networkTimeout ?? 'Connection timeout. Try again.';
      }

      if (err.type == DioExceptionType.connectionError) {
        return l.networkNoInternet ??
            'No internet / server unreachable. Check connection.';
      }

      // Server responded with status code
      final res = err.response;
      if (res != null) {
        final status = res.statusCode;

        // Try to read backend structured JSON: {error: "..."} or {message: "..."}
        final data = res.data;
        if (data is Map) {
          final m = data.cast<String, dynamic>();
          final serverErr = (m['error'] ?? m['message'])?.toString();
          if (serverErr != null && serverErr.trim().isNotEmpty) {
            return serverErr;
          }
        }

        if (status == 401) {
          return l.adminSessionExpired ??
              'Session expired. Please login again.';
        }
        if (status == 403) {
          return l.forbiddenLabel ??
              'You don’t have permission to do this.';
        }
        if (status == 404) {
          return l.notFoundLabel ?? 'Not found.';
        }
        if (status != null && status >= 500) {
          return l.serverErrorLabel ??
              'Server error. Please try again later.';
        }

        return 'Request failed (${status ?? 'unknown'}).';
      }

      // fallback
      return l.networkErrorLabel ??
          'Network error. Please try again.';
    }

    // If error contains DioException text anyway, clean it
    if (msg.contains('DioException')) {
      return l.networkErrorLabel ?? 'Network error. Please try again.';
    }

    return msg;
  }

  void _showNoTokenMessage() {
    final l = AppLocalizations.of(context)!;
    AppToast.error(context, l.adminSessionExpired);
  }

  // ----------------- Load / refresh -----------------

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

  // ----------------- Create / Edit / Delete -----------------

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
    AppToast.error(context, l.adminCreated ?? 'Created');
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
    AppToast.error(context, l.adminUpdated ?? 'Updated');
  }

  Future<void> _confirmAndDelete(ShippingMethod method) async {
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

    context.read<ShippingMethodsBloc>().add(
          DeleteShippingMethodEvent(
            id: method.id,
            token: _token!,
          ),
        );

    AppToast.error(context, l.adminDeleted ?? 'Deleted');
  }

  // ----------------- UI -----------------

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

                    // reset last error once we have success state
                    _lastShownError = null;

                    final all = state.methods;
                    final filtered =
                        _showAll ? all : all.where((m) => m.enabled).toList();

                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.all(spacing.lg),
                        children: [
                          AdminShippingFiltersBar(
                            showAll: _showAll,
                            onChangedShowAll: (v) =>
                                setState(() => _showAll = v),
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
                                  onDelete: () => _confirmAndDelete(m),
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
