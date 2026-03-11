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

import 'package:build4front/features/catalog/data/services/currency_api_service.dart';
import 'package:build4front/features/catalog/utils/currency_symbol_cache.dart';

class AdminProductsListScreen extends StatelessWidget {
  final int ownerProjectId;

  const AdminProductsListScreen({
    super.key,
    required this.ownerProjectId,
  });

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
      )..add(LoadProductsForOwner(ownerProjectId: ownerProjectId)),
      child: _AdminProductsListView(ownerProjectId: ownerProjectId),
    );
  }
}

class _AdminProductsListView extends StatefulWidget {
  final int ownerProjectId;

  const _AdminProductsListView({
    required this.ownerProjectId,
  });

  @override
  State<_AdminProductsListView> createState() => _AdminProductsListViewState();
}

class _AdminProductsListViewState extends State<_AdminProductsListView> {
  String _searchQuery = '';
  String _typeFilter = 'ALL';
  String _statusFilter = 'ALL';
  String _stockFilter = 'ALL';

  late final CurrencySymbolCache _currencyCache = CurrencySymbolCache(
    api: CurrencyApiService(),
    getToken: AdminTokenStore().getToken,
  );

  Map<int, String> _symbolByCurrencyId = {};
  bool _warmingCurrency = false;
  bool _warmScheduled = false;

  Future<void> _reload() async {
    context.read<ProductListBloc>().add(
          LoadProductsForOwner(ownerProjectId: widget.ownerProjectId),
        );
  }

  Future<void> _warmCurrencySymbols(List<Product> products) async {
    if (_warmingCurrency) return;

    final ids = products.map((p) => p.currencyId).whereType<int>().toSet();
    final missing =
        ids.where((id) => !_symbolByCurrencyId.containsKey(id)).toList();

    if (missing.isEmpty) return;

    setState(() => _warmingCurrency = true);
    try {
      await _currencyCache.warmUp(missing);
      if (!mounted) return;

      setState(() {
        _symbolByCurrencyId = Map<int, String>.from(_currencyCache.snapshot);
      });
    } finally {
      if (mounted) {
        setState(() => _warmingCurrency = false);
      }
    }
  }

  void _maybeWarmUp(List<Product> products) {
    if (_warmScheduled || _warmingCurrency) return;

    final ids = products.map((p) => p.currencyId).whereType<int>().toSet();
    final missing =
        ids.where((id) => !_symbolByCurrencyId.containsKey(id)).toList();

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

    String? code;
    String? err;

    if (data is Map) {
      code = data['code']?.toString();
      err = (data['error'] ?? data['message'])?.toString();
    } else if (data is String) {
      err = data;
    }

    final errLower = (err ?? '').toLowerCase();
    final codeUpper = (code ?? '').toUpperCase();

    final isCart = codeUpper == 'PRODUCT_DELETE_BLOCKED_CART' ||
        codeUpper == 'PRODUCT_IN_CART' ||
        errLower.contains('cart_items') ||
        errLower.contains('cart');

    final isOrders = codeUpper == 'PRODUCT_DELETE_BLOCKED_ORDERS' ||
        codeUpper == 'PRODUCT_IN_ORDERS' ||
        errLower.contains('order_items') ||
        errLower.contains('order');

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

      Navigator.of(context).pop();
      await _reload();

      AppToast.success(context, l10n.adminProductDeleteSuccess);
    } catch (e) {
      if (!context.mounted) return;

      Navigator.of(context).pop();

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
    return raw.replaceFirst(RegExp(r'^sku[\s\-_:#]*'), '');
  }

  String _statusCodeOf(Product p) {
    final raw = (p.statusCode ?? '').trim().toUpperCase();
    if (raw.isNotEmpty) return raw;

    final legacy = (p.statusName ?? '').trim().toUpperCase();
    if (legacy.isNotEmpty) return legacy;

    return 'UNKNOWN';
  }

  String _statusLabelOf(Product p) {
    final rawName = (p.statusName ?? '').trim();
    if (rawName.isNotEmpty) return rawName;

    switch (_statusCodeOf(p)) {
      case 'DRAFT':
        return 'Draft';
      case 'UPCOMING':
        return 'Upcoming';
      case 'PUBLISHED':
        return 'Published';
      case 'ARCHIVED':
        return 'Archived';
      default:
        return 'Unknown';
    }
  }

  String _stockCodeOf(Product p) {
    final stock = p.safeStock;
    if (stock <= 0) return 'OUT_OF_STOCK';
    if (stock <= 5) return 'LOW_STOCK';
    return 'IN_STOCK';
  }

  String _stockLabelOf(Product p) {
    switch (_stockCodeOf(p)) {
      case 'OUT_OF_STOCK':
        return 'Out of stock';
      case 'LOW_STOCK':
        return 'Low stock';
      case 'IN_STOCK':
      default:
        return 'In stock';
    }
  }

  bool _matchesSearch(Product p, String query) {
    final q = _norm(query);
    if (q.isEmpty) return true;

    final name = _norm(p.name);
    final sku = _normSku(p.sku);
    final status = _norm(_statusLabelOf(p));
    final stock = _norm(_stockLabelOf(p));

    if (q.length == 1) {
      return name.startsWith(q) ||
          sku.startsWith(q) ||
          status.startsWith(q) ||
          stock.startsWith(q);
    }

    return name.contains(q) ||
        sku.contains(q) ||
        status.contains(q) ||
        stock.contains(q);
  }

  bool _matchesStatusFilter(Product p) {
    if (_statusFilter == 'ALL') return true;
    return _statusCodeOf(p) == _statusFilter;
  }

  bool _matchesStockFilter(Product p) {
    if (_stockFilter == 'ALL') return true;
    return _stockCodeOf(p) == _stockFilter;
  }

  List<Product> _applyFilters(ProductListState state) {
    var list = [...state.products];

    if (_searchQuery.trim().isNotEmpty) {
      list = list.where((p) => _matchesSearch(p, _searchQuery)).toList();
    }

    if (_typeFilter != 'ALL') {
      list = list
          .where((p) => p.productType.toUpperCase() == _typeFilter)
          .toList();
    }

    if (_statusFilter != 'ALL') {
      list = list.where(_matchesStatusFilter).toList();
    }

    if (_stockFilter != 'ALL') {
      list = list.where(_matchesStockFilter).toList();
    }

    return list;
  }

  Map<String, int> _buildStatusCounts(List<Product> products) {
    int draft = 0;
    int upcoming = 0;
    int published = 0;
    int archived = 0;

    for (final p in products) {
      switch (_statusCodeOf(p)) {
        case 'DRAFT':
          draft++;
          break;
        case 'UPCOMING':
          upcoming++;
          break;
        case 'PUBLISHED':
          published++;
          break;
        case 'ARCHIVED':
          archived++;
          break;
      }
    }

    return {
      'DRAFT': draft,
      'UPCOMING': upcoming,
      'PUBLISHED': published,
      'ARCHIVED': archived,
    };
  }

  Map<String, int> _buildStockCounts(List<Product> products) {
    int inStock = 0;
    int lowStock = 0;
    int outOfStock = 0;

    for (final p in products) {
      switch (_stockCodeOf(p)) {
        case 'OUT_OF_STOCK':
          outOfStock++;
          break;
        case 'LOW_STOCK':
          lowStock++;
          break;
        case 'IN_STOCK':
          inStock++;
          break;
      }
    }

    return {
      'IN_STOCK': inStock,
      'LOW_STOCK': lowStock,
      'OUT_OF_STOCK': outOfStock,
    };
  }

  int _crossAxisCount(double width) {
    if (width < 700) return 2;
    if (width < 1000) return 3;
    if (width < 1400) return 4;
    return 5;
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
        surfaceTintColor: Colors.transparent,
        elevation: 0,
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
            await _reload();
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

            _maybeWarmUp(state.products);

            final filtered = _applyFilters(state);
            final width = MediaQuery.of(context).size.width;
            final crossAxisCount = _crossAxisCount(width);
            final statusCounts = _buildStatusCounts(state.products);
            final stockCounts = _buildStockCounts(state.products);

            final cardExtent = width < 380
                ? 208.0
                : width < 700
                    ? 216.0
                    : 240.0;

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
                  onTypeFilterChanged: (val) =>
                      setState(() => _typeFilter = val),
                  statusFilter: _statusFilter,
                  onStatusFilterChanged: (val) =>
                      setState(() => _statusFilter = val),
                  stockFilter: _stockFilter,
                  onStockFilterChanged: (val) =>
                      setState(() => _stockFilter = val),
                  statusCounts: statusCounts,
                  stockCounts: stockCounts,
                ),
                SizedBox(height: spacing.md),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No products match the current filters.',
                            style: text.bodyMedium.copyWith(
                              color: colors.body,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _reload,
                          child: GridView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: spacing.md,
                              mainAxisSpacing: spacing.md,
                              mainAxisExtent: cardExtent,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final product = filtered[index];

                              final sym = product.currencyId != null
                                  ? _symbolByCurrencyId[product.currencyId!]
                                  : null;

                              final bool showCurrencyLoading =
                                  _warmingCurrency &&
                                      product.currencyId != null &&
                                      ((sym ?? '').trim().isEmpty);

                              return AdminProductCard(
                                product: product,
                                currencySymbol: sym,
                                currencyLoading: showCurrencyLoading,
                                onEdit: () async {
                                  final changed =
                                      await Navigator.of(context).push<bool>(
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
                                    await _reload();
                                  }
                                },
                                onDelete: () => _confirmDelete(context, product),
                              );
                            },
                          ),
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
  final String typeFilter;
  final ValueChanged<String> onTypeFilterChanged;
  final String statusFilter;
  final ValueChanged<String> onStatusFilterChanged;
  final String stockFilter;
  final ValueChanged<String> onStockFilterChanged;
  final Map<String, int> statusCounts;
  final Map<String, int> stockCounts;

  const _AdminProductsHeaderBar({
    required this.tokens,
    required this.l10n,
    required this.totalCount,
    required this.filteredCount,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onTypeFilterChanged,
    required this.typeFilter,
    required this.onStatusFilterChanged,
    required this.statusFilter,
    required this.onStockFilterChanged,
    required this.stockFilter,
    required this.statusCounts,
    required this.stockCounts,
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
                  style: text.bodySmall.copyWith(
                    color: c.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.sm),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _SummaryPill(
                  tokens: tokens,
                  label: 'Draft',
                  count: statusCounts['DRAFT'] ?? 0,
                ),
                SizedBox(width: spacing.sm),
                _SummaryPill(
                  tokens: tokens,
                  label: 'Upcoming',
                  count: statusCounts['UPCOMING'] ?? 0,
                ),
                SizedBox(width: spacing.sm),
                _SummaryPill(
                  tokens: tokens,
                  label: 'Published',
                  count: statusCounts['PUBLISHED'] ?? 0,
                ),
                SizedBox(width: spacing.sm),
                _SummaryPill(
                  tokens: tokens,
                  label: 'Archived',
                  count: statusCounts['ARCHIVED'] ?? 0,
                ),
                SizedBox(width: spacing.sm),
                _SummaryPill(
                  tokens: tokens,
                  label: 'Out',
                  count: stockCounts['OUT_OF_STOCK'] ?? 0,
                ),
                SizedBox(width: spacing.sm),
                _SummaryPill(
                  tokens: tokens,
                  label: 'Low',
                  count: stockCounts['LOW_STOCK'] ?? 0,
                ),
                SizedBox(width: spacing.sm),
                _SummaryPill(
                  tokens: tokens,
                  label: 'In',
                  count: stockCounts['IN_STOCK'] ?? 0,
                ),
              ],
            ),
          ),
          SizedBox(height: spacing.md),
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.adminProductsSearchHint,
            ),
            onChanged: onSearchChanged,
          ),
          SizedBox(height: spacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: 150,
                  child: _CompactFilterDropdown(
                    tokens: tokens,
                    label: 'Type',
                    value: typeFilter,
                    items: const [
                      _FilterItem(value: 'ALL', label: 'All'),
                      _FilterItem(value: 'SIMPLE', label: 'Simple'),
                      _FilterItem(value: 'VARIABLE', label: 'Variable'),
                      _FilterItem(value: 'GROUPED', label: 'Grouped'),
                      _FilterItem(value: 'EXTERNAL', label: 'External'),
                    ],
                    onChanged: onTypeFilterChanged,
                  ),
                ),
                SizedBox(width: spacing.sm),
                SizedBox(
                  width: 150,
                  child: _CompactFilterDropdown(
                    tokens: tokens,
                    label: 'Status',
                    value: statusFilter,
                    items: const [
                      _FilterItem(value: 'ALL', label: 'All'),
                      _FilterItem(value: 'DRAFT', label: 'Draft'),
                      _FilterItem(value: 'UPCOMING', label: 'Upcoming'),
                      _FilterItem(value: 'PUBLISHED', label: 'Published'),
                      _FilterItem(value: 'ARCHIVED', label: 'Archived'),
                    ],
                    onChanged: onStatusFilterChanged,
                  ),
                ),
                SizedBox(width: spacing.sm),
                SizedBox(
                  width: 150,
                  child: _CompactFilterDropdown(
                    tokens: tokens,
                    label: 'Stock',
                    value: stockFilter,
                    items: const [
                      _FilterItem(value: 'ALL', label: 'All'),
                      _FilterItem(value: 'IN_STOCK', label: 'In stock'),
                      _FilterItem(value: 'LOW_STOCK', label: 'Low stock'),
                      _FilterItem(value: 'OUT_OF_STOCK', label: 'Out of stock'),
                    ],
                    onChanged: onStockFilterChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final dynamic tokens;
  final String label;
  final int count;

  const _SummaryPill({
    required this.tokens,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final c = tokens.colors;
    final spacing = tokens.spacing;
    final text = tokens.typography;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.sm,
        vertical: spacing.xs,
      ),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: c.border.withOpacity(0.4)),
      ),
      child: Text(
        '$label • $count',
        style: text.bodySmall.copyWith(
          color: c.label,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CompactFilterDropdown extends StatelessWidget {
  final dynamic tokens;
  final String label;
  final String value;
  final List<_FilterItem> items;
  final ValueChanged<String> onChanged;

  const _CompactFilterDropdown({
    required this.tokens,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = tokens.colors;
    final spacing = tokens.spacing;
    final text = tokens.typography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: spacing.xs, bottom: spacing.xs),
          child: Text(
            label,
            style: text.bodySmall.copyWith(
              color: c.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          height: 44,
          padding: EdgeInsets.symmetric(horizontal: spacing.sm),
          decoration: BoxDecoration(
            color: c.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.border.withOpacity(0.4)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item.value,
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyMedium.copyWith(color: c.label),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val == null) return;
                onChanged(val);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterItem {
  final String value;
  final String label;

  const _FilterItem({
    required this.value,
    required this.label,
  });
}