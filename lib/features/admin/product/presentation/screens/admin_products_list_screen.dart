import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:build4front/features/auth/data/services/admin_token_store.dart';
import 'package:build4front/common/widgets/app_toast.dart';

import '../../data/repositories/product_repository_impl.dart';
import '../../data/services/product_api_service.dart';
import '../../domain/usecases/get_products.dart';
import '../../domain/entities/product.dart';

import '../bloc/list/product_list_bloc.dart';
import '../bloc/list/product_list_event.dart';
import '../bloc/list/product_list_state.dart';

import '../widgets/admin_product_card.dart';
import 'admin_create_product_screen.dart';

// ✅ currency fetch + cache
import 'package:build4front/features/catalog/data/services/currency_api_service.dart';
import 'package:build4front/features/catalog/utils/currency_symbol_cache.dart';

class AdminProductsListScreen extends StatelessWidget {
  final int ownerProjectId;

  const AdminProductsListScreen({super.key, required this.ownerProjectId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProductListBloc>(
      create: (_) => ProductListBloc(
        getProducts: GetProducts(
          ProductRepositoryImpl(
            api: ProductApiService(),
            getToken: AdminTokenStore().getToken,
          ),
        ),
      )..add(LoadProductsForOwner()),
      child: _AdminProductsListView(ownerProjectId: ownerProjectId),
    );
  }
}

class _AdminProductsListView extends StatefulWidget {
  final int ownerProjectId;
  const _AdminProductsListView({required this.ownerProjectId});

  @override
  State<_AdminProductsListView> createState() => _AdminProductsListViewState();
}

class _AdminProductsListViewState extends State<_AdminProductsListView> {
  String _searchQuery = '';
  String _typeFilter = 'ALL';

  // ✅ Currency symbol cache (ONE place only)
  late final CurrencySymbolCache _currencyCache = CurrencySymbolCache(
    api: CurrencyApiService(),
    getToken: AdminTokenStore().getToken,
  );

  Map<int, String> _symbolByCurrencyId = {};
  bool _warmingCurrency = false;
  bool _warmScheduled = false;

  Future<void> _warmCurrencySymbols(List<Product> products) async {
    if (_warmingCurrency) return;

    final ids = products.map((p) => p.currencyId).whereType<int>().toSet();
    final missing = ids.where((id) => !_symbolByCurrencyId.containsKey(id)).toList();

    if (missing.isEmpty) return;

    setState(() => _warmingCurrency = true);
    try {
      await _currencyCache.warmUp(missing);
      if (!mounted) return;

      setState(() {
        _symbolByCurrencyId = Map<int, String>.from(_currencyCache.snapshot);
      });
    } finally {
      if (mounted) setState(() => _warmingCurrency = false);
    }
  }

  void _maybeWarmUp(List<Product> products) {
    if (_warmScheduled || _warmingCurrency) return;

    final ids = products.map((p) => p.currencyId).whereType<int>().toSet();
    final missing = ids.where((id) => !_symbolByCurrencyId.containsKey(id)).toList();

    if (missing.isEmpty) return;

    _warmScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _warmScheduled = false;
      if (!mounted) return;
      await _warmCurrencySymbols(products);
    });
  }

  String _friendlyDeleteErrorFromResponse(
    AppLocalizations l10n,
    DioException e,
  ) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    // structured backend format (recommended):
    // { code: "PRODUCT_IN_CART", error: "PRODUCT_IN_CART" }
    String? code;
    String? err;

    if (data is Map) {
      code = data['code']?.toString();
      err = data['error']?.toString();
    } else if (data is String) {
      err = data;
    }

    final errLower = (err ?? '').toLowerCase();

    // ✅ Most important cases: product is referenced in cart/order
    final isCart =
        code == 'PRODUCT_IN_CART' || errLower.contains('cart_items') || errLower.contains('cart');
    final isOrders =
        code == 'PRODUCT_IN_ORDERS' || errLower.contains('order_items') || errLower.contains('order');

    if (status == 409 || status == 500) {
      if (isCart) return l10n.adminProductDeleteBlockedCart;
      if (isOrders) return l10n.adminProductDeleteBlockedOrders;
      return l10n.adminProductDeleteBlockedGeneric;
    }

    if (status == 401) return l10n.errSessionExpired;
    if (status == 403) return l10n.errForbidden;
    if (status == 404) return l10n.errNotFound;

    return l10n.adminProductDeleteFailed;
  }

  Future<void> _confirmDelete(BuildContext context, Product product) async {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.read<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final text = tokens.typography;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminProductDeleteDialogTitle),
        content: Text(
          l10n.adminProductDeleteDialogBody(product.name),
          style: text.bodyMedium.copyWith(color: colors.label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.commonDelete,
              style: TextStyle(color: colors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final token = await AdminTokenStore().getToken();
      if (token == null || token.isEmpty) {
        throw DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 401,
            data: {'error': 'SESSION_EXPIRED'},
          ),
          type: DioExceptionType.badResponse,
        );
      }

      final api = ProductApiService();
      await api.delete(id: product.id, authToken: token);

      if (!context.mounted) return;

      Navigator.of(context).pop(); // close loader

      context.read<ProductListBloc>().add(
            LoadProductsForOwner(),
          );

      AppToast.error(context, l10n.adminProductDeleteSuccess);
    } catch (e) {
      if (!context.mounted) return;

      Navigator.of(context).pop(); // close loader

      final l10n = AppLocalizations.of(context)!;

      String msg = l10n.adminProductDeleteFailed;

      if (e is DioException) {
        msg = _friendlyDeleteErrorFromResponse(l10n, e);
      }

      AppToast.error(context, msg);
    }
  }

  String _norm(String v) => v.trim().toLowerCase();

String _normSku(String? v) {
  final raw = (v ?? '').trim().toLowerCase();

  // Optional: remove common SKU prefix so searching "k" doesn't match "SKU-*"
  // Examples removed: "sku-", "sku_", "sku ", "sku:"
  return raw.replaceFirst(RegExp(r'^sku[\s\-_:#]*'), '');
}

bool _matchesSearch(Product p, String query) {
  final q = _norm(query);
  if (q.isEmpty) return true;

  final name = _norm(p.name);
  final sku = _normSku(p.sku);

  //  If user typed only 1 char, be strict (starts with)
  if (q.length == 1) {
    return name.startsWith(q) || sku.startsWith(q);
  }

  //  For longer queries, allow contains
  return name.contains(q) || sku.contains(q);
}

List<Product> _applyFilters(ProductListState state) {
  var list = state.products;

  if (_searchQuery.trim().isNotEmpty) {
    list = list.where((p) => _matchesSearch(p, _searchQuery)).toList();
  }

  if (_typeFilter != 'ALL') {
    list = list
        .where((p) => (p.productType).toUpperCase() == _typeFilter)
        .toList();
  }

  return list;
}
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final spacing = tokens.spacing;
    final text = tokens.typography;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Text(
          l10n.adminProductsTitle,
          style: text.titleMedium.copyWith(
            color: colors.label,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final changed = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => AdminCreateProductScreen(
                ownerProjectId: widget.ownerProjectId,
              ),
            ),
          );

          if (changed == true && context.mounted) {
            context.read<ProductListBloc>().add(
                  LoadProductsForOwner(),
                );
          }
        },
        backgroundColor: colors.primary,
        child: Icon(Icons.add, color: colors.onPrimary),
      ),
      body: Padding(
        padding: EdgeInsets.all(spacing.md),
        child: BlocBuilder<ProductListBloc, ProductListState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.error != null) {
              return Center(
                child: Text(
                  l10n.adminProductsLoadFailed(state.error!),
                  style: text.bodyMedium.copyWith(color: colors.danger),
                  textAlign: TextAlign.center,
                ),
              );
            }

            if (state.products.isEmpty) {
              return Center(
                child: Text(
                  l10n.adminProductsEmpty,
                  style: text.bodyMedium.copyWith(color: colors.body),
                ),
              );
            }

            // ✅ Warm currency symbols once (only missing ids)
            _maybeWarmUp(state.products);

            final filtered = _applyFilters(state);
            final width = MediaQuery.of(context).size.width;
            final crossAxisCount = width >= 1100
                ? 5
                : width >= 900
                    ? 4
                    : width >= 600
                        ? 3
                        : 2;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AdminProductsHeaderBar(
                  tokens: tokens,
                  l10n: l10n,
                  totalCount: state.products.length,
                  filteredCount: filtered.length,
                  searchQuery: _searchQuery,
                  onSearchChanged: (val) => setState(() => _searchQuery = val),
                  typeFilter: _typeFilter,
                  onTypeFilterChanged: (val) => setState(() => _typeFilter = val),
                ),
                SizedBox(height: spacing.md),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.70,
                      crossAxisSpacing: spacing.md,
                      mainAxisSpacing: spacing.md,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final product = filtered[index];

                      final sym =
                          product.currencyId != null ? _symbolByCurrencyId[product.currencyId!] : null;

                      final bool showCurrencyLoading = _warmingCurrency &&
                          product.currencyId != null &&
                          ((sym ?? '').trim().isEmpty);

                      return AdminProductCard(
                        product: product,
                        currencySymbol: sym,
                        currencyLoading: showCurrencyLoading,
                        onEdit: () async {
                          final changed = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => AdminCreateProductScreen(
                                ownerProjectId: widget.ownerProjectId,
                                categoryId: product.categoryId,
                                itemTypeId: product.itemTypeId,
                                currencyId: product.currencyId,
                                initialProduct: product,
                              ),
                            ),
                          );

                          if (changed == true && context.mounted) {
                            context.read<ProductListBloc>().add(
                                  LoadProductsForOwner(),
                                );
                          }
                        },
                        onDelete: () => _confirmDelete(context, product),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AdminProductsHeaderBar extends StatelessWidget {
  final dynamic tokens;
  final AppLocalizations l10n;
  final int totalCount;
  final int filteredCount;

  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  /// 'ALL', 'SIMPLE', 'VARIABLE', 'GROUPED', 'EXTERNAL'
  final String typeFilter;
  final ValueChanged<String> onTypeFilterChanged;

  const _AdminProductsHeaderBar({
    required this.tokens,
    required this.l10n,
    required this.totalCount,
    required this.filteredCount,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.typeFilter,
    required this.onTypeFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = tokens.colors;
    final spacing = tokens.spacing;
    final text = tokens.typography;

    return Container(
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(tokens.card.radius),
        border: Border.all(color: c.border.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: c.label.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: c.primary),
              SizedBox(width: spacing.sm),
              Text(
                l10n.adminProductsTitle,
                style: text.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: c.label,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.sm,
                  vertical: spacing.xs,
                ),
                decoration: BoxDecoration(
                  color: c.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  l10n.adminProductsCountPill(filteredCount, totalCount),
                  style: text.bodySmall.copyWith(color: c.primary),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.md),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: l10n.adminProductsSearchHint,
                  ),
                  onChanged: onSearchChanged,
                ),
              ),
              SizedBox(width: spacing.md),
              Expanded(
                flex: 2,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.sm,
                    vertical: spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: c.background,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: c.border.withOpacity(0.4)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: typeFilter,
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(
                          value: 'ALL',
                          child: Text(l10n.adminProductsFilterAll),
                        ),
                        DropdownMenuItem(
                          value: 'SIMPLE',
                          child: Text(l10n.adminProductTypeSimple),
                        ),
                        DropdownMenuItem(
                          value: 'VARIABLE',
                          child: Text(l10n.adminProductTypeVariable),
                        ),
                        DropdownMenuItem(
                          value: 'GROUPED',
                          child: Text(l10n.adminProductTypeGrouped),
                        ),
                        DropdownMenuItem(
                          value: 'EXTERNAL',
                          child: Text(l10n.adminProductTypeExternal),
                        ),
                      ],
                      onChanged: (val) {
                        if (val == null) return;
                        onTypeFilterChanged(val);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}