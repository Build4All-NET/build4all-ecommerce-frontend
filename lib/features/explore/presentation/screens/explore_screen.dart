// lib/features/explore/presentation/screens/explore_screen.dart

import 'dart:async';
import 'dart:math' as math;

import 'package:build4front/core/network/globals.dart' as authState;
import 'package:build4front/features/itemsDetails/presentation/screens/item_details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/config/app_config.dart';
import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';

import 'package:build4front/features/home/presentation/bloc/home_bloc.dart';
import 'package:build4front/features/home/presentation/bloc/home_state.dart';
import 'package:build4front/features/home/presentation/bloc/home_event.dart';

import 'package:build4front/features/items/domain/entities/item_summary.dart';
import 'package:build4front/common/widgets/app_search_field.dart';
import 'package:build4front/common/widgets/ItemCard.dart';

// currency formatter (dynamic currency, not hardcoded $)
import 'package:build4front/features/catalog/cubit/money.dart';

// Auth + Cart + Toast
import 'package:build4front/features/auth/presentation/login/bloc/auth_bloc.dart';
import 'package:build4front/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:build4front/features/cart/presentation/bloc/cart_event.dart';
import 'package:build4front/common/widgets/app_toast.dart';

enum ExploreSortOption { relevance, priceLowHigh, priceHighLow, dateSoonest }

class ExploreScreen extends StatefulWidget {
  final AppConfig appConfig;

  final String? initialQuery;
  final String? initialCategoryLabel;
  final String? initialSectionId;
  final int? initialCategoryId;

  const ExploreScreen({
    super.key,
    required this.appConfig,
    this.initialQuery,
    this.initialCategoryLabel,
    this.initialSectionId,
    this.initialCategoryId,
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late String _searchQuery;
  String? _selectedCategoryLabel;
  int? _selectedCategoryId;
  ExploreSortOption _sortOption = ExploreSortOption.relevance;

  // pagination (3 rows × 2 cols = 6 items per page)
  static const int _rowsPerPage = 3;
  static const int _itemsPerPage = _rowsPerPage * 2;
  int _page = 1;

  // typing debounce
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchQuery = (widget.initialQuery ?? '').trim();
    _selectedCategoryLabel = widget.initialCategoryLabel;
    _selectedCategoryId = widget.initialCategoryId;
    _sortOption = ExploreSortOption.relevance;

    final homeBloc = context.read<HomeBloc>();
    if (!homeBloc.state.hasLoaded && !homeBloc.state.isLoading) {
      final raw = (authState.token ?? '').trim();
      final token = raw.isEmpty ? null : raw;

      homeBloc.add(HomeStarted(token: token));
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _resetToFirstPage() {
    _page = 1;
  }

  void _onSearchChangedDebounced(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = value.trim();
        _resetToFirstPage();
      });
    });
  }

  List<ItemSummary> _mergeUniqueById(List<List<ItemSummary>> lists) {
  final seen = <int>{};
  final out = <ItemSummary>[];

  for (final list in lists) {
    for (final item in list) {
      if (seen.add(item.id)) {
        out.add(item);
      }
    }
  }
  return out;
}

  // detect if app has ANY items (all sections)
  bool _hasAnyItems(HomeState s) {
    return s.recommendedItems.isNotEmpty ||
        s.popularItems.isNotEmpty ||
        s.flashSaleItems.isNotEmpty ||
        s.newArrivalsItems.isNotEmpty ||
        s.bestSellersItems.isNotEmpty ||
        s.topRatedItems.isNotEmpty;
  }

  // category ids that actually appear in a given item list
  Set<int> _categoryIdsFromItems(List<ItemSummary> items) {
    final set = <int>{};
    for (final it in items) {
      final cid = it.categoryId;
      if (cid != null) set.add(cid);
    }
    return set;
  }

  // ✅ NEW: out of stock helper (correct place)
  bool _isOutOfStock(ItemSummary item) {
    if (item.kind != ItemKind.product) return false;
    final s = item.stock;
    if (s == null) return false;
    return s <= 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeState = context.watch<ThemeCubit>().state;
    final spacing = themeState.tokens.spacing;

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, homeState) {
            if (homeState.isLoading && !homeState.hasLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            final baseItems = _baseItemsForExplore(homeState);

            // categories should be based on items that exist (base dataset)
            final availableCategoryIds = _categoryIdsFromItems(baseItems);

            // derive categories (entities) that have items
            final catsWithItems = homeState.categoryEntities
                .where((c) => availableCategoryIds.contains(c.id))
                .toList();

            final categoryNames = catsWithItems.map((c) => c.name).toList();

            // if initialCategoryId/Label points to category that has no items -> treat as "All"
            final rawSelectedLabel = _selectedCategoryLabel ??
                _labelForCategoryId(homeState, _selectedCategoryId);

            final effectiveSelectedLabel = (rawSelectedLabel != null &&
                    categoryNames.contains(rawSelectedLabel))
                ? rawSelectedLabel
                : null;

            final effectiveSelectedCategoryId =
                (availableCategoryIds.contains(_selectedCategoryId))
                    ? _selectedCategoryId
                    : null;

            final filtered = _buildFilteredAndSortedItems(
              baseItems,
              effectiveCategoryId: effectiveSelectedCategoryId,
            );

            // pagination math
            final totalItems = filtered.length;
            final totalPages =
                totalItems == 0 ? 1 : ((totalItems / _itemsPerPage).ceil());

            // clamp page
            final safePage = _page.clamp(1, totalPages);

            final start = (safePage - 1) * _itemsPerPage;
            final end = math.min(start + _itemsPerPage, totalItems);
            final pageItems = (totalItems == 0 || start >= totalItems)
                ? <ItemSummary>[]
                : filtered.sublist(start, end);

            // show category chips only when items exist
            final showCategories = _hasAnyItems(homeState) &&
                baseItems.isNotEmpty &&
                categoryNames.isNotEmpty;

            return RefreshIndicator(
              onRefresh: () async {
                final raw = (authState.token ?? '').trim();
                final token = raw.isEmpty ? null : raw;

                context
                    .read<HomeBloc>()
                    .add(HomeRefreshRequested(token: token));

                setState(() => _resetToFirstPage());
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxW = constraints.maxWidth;
                  final contentMaxWidth = maxW > 900 ? 900.0 : maxW;

                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentMaxWidth),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          spacing.lg,
                          spacing.lg,
                          spacing.lg,
                          spacing.xl,
                        ),
                        children: [
                          // Search
                          AppSearchField(
                            hintText: l10n.explore_search_hint,
                            initialValue:
                                _searchQuery.isEmpty ? null : _searchQuery,
                            onChanged: _onSearchChangedDebounced,
                            onSubmitted: (value) {
                              setState(() {
                                _searchQuery = value.trim();
                                _resetToFirstPage();
                              });
                            },
                          ),
                          SizedBox(height: spacing.md),

                          // Category chips (ONLY if items exist)
                          if (showCategories) ...[
                            _ExploreCategoryChips(
                              categories: categoryNames,
                              selectedCategoryLabel: effectiveSelectedLabel,
                              onCategorySelected: (label) {
                                int? foundId;

                                if (label != null && label.trim().isNotEmpty) {
                                  // IMPORTANT: search only in catsWithItems
                                  for (final cat in catsWithItems) {
                                    if (cat.name == label) {
                                      foundId = cat.id;
                                      break;
                                    }
                                  }
                                }

                                setState(() {
                                  _selectedCategoryLabel = label;
                                  _selectedCategoryId = foundId;
                                  _resetToFirstPage();
                                });
                              },
                            ),
                            SizedBox(height: spacing.sm),
                          ] else ...[
                            SizedBox(height: spacing.sm),
                          ],

                          // Results + Sort
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.explore_results_label(totalItems),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _SortDropdown(
                                current: _sortOption,
                                onChanged: (opt) {
                                  setState(() {
                                    _sortOption = opt;
                                    _resetToFirstPage();
                                  });
                                },
                              ),
                            ],
                          ),

                          SizedBox(height: spacing.md),

                          if (filtered.isEmpty)
                            _EmptyExploreState(
                              message: l10n.explore_empty_message,
                            )
                          else ...[
                            // Grid
                            _ExploreItemsGrid(
                              items: pageItems,
                              pricingFor: _pricingFor,
                              subtitleFor: _subtitleFor,
                              metaFor: _metaLabelFor,
                              ctaLabelFor: _ctaLabelFor,
                              isOutOfStock: _isOutOfStock, // ✅ pass helper
                              onTapItem: (id) => _openDetails(context, id),
                              onCtaPressed: (item) =>
                                  _handleCtaPressed(context, item),
                            ),

                            SizedBox(height: spacing.lg),

                            // Pagination bar ‹ 1 2 3 ›
                            _PaginationBar(
                              currentPage: safePage,
                              totalPages: totalPages,
                              onPageChanged: (p) {
                                setState(() => _page = p);
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  String? _labelForCategoryId(HomeState homeState, int? id) {
    if (id == null) return null;
    for (final cat in homeState.categoryEntities) {
      if (cat.id == id) return cat.name;
    }
    return null;
  }

  List<ItemSummary> _baseItemsForExplore(HomeState homeState) {
  final sid = (widget.initialSectionId ?? '').trim();

  // For section-specific explore, keep section behavior
  if (sid == 'flash_sale') {
    return homeState.flashSaleItems.isNotEmpty
        ? homeState.flashSaleItems
        : homeState.popularItems;
  }
  if (sid == 'new_arrivals') {
    return homeState.newArrivalsItems.isNotEmpty
        ? homeState.newArrivalsItems
        : homeState.popularItems;
  }
  if (sid == 'best_sellers') {
    return homeState.bestSellersItems.isNotEmpty
        ? homeState.bestSellersItems
        : homeState.popularItems;
  }
  if (sid == 'top_rated') {
    return homeState.topRatedItems.isNotEmpty
        ? homeState.topRatedItems
        : homeState.popularItems;
  }

  // ✅ Default Explore = ALL available items from all sections (deduped)
  final merged = _mergeUniqueById([
    homeState.recommendedItems,
    homeState.popularItems,
    homeState.flashSaleItems,
    homeState.newArrivalsItems,
    homeState.bestSellersItems,
    homeState.topRatedItems,
  ]);

  return merged;
}
  List<ItemSummary> _buildFilteredAndSortedItems(
    List<ItemSummary> base, {
    required int? effectiveCategoryId,
  }) {
    List<ItemSummary> result = base;

    // search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((item) {
        final title = item.title.toLowerCase();
        final subtitle = (item.subtitle ?? '').toLowerCase();
        final location = (item.location ?? '').toLowerCase();
        return title.contains(query) ||
            subtitle.contains(query) ||
            location.contains(query);
      }).toList();
    }

    // categoryId filter
    if (effectiveCategoryId != null) {
      result = result
          .where((item) => item.categoryId == effectiveCategoryId)
          .toList();
    }

    // sort
    result = List<ItemSummary>.from(result);

    switch (_sortOption) {
      case ExploreSortOption.relevance:
        break;

      case ExploreSortOption.priceLowHigh:
        result.sort((a, b) {
          final ap = (_currentPrice(a) ?? double.infinity).toDouble();
          final bp = (_currentPrice(b) ?? double.infinity).toDouble();
          return ap.compareTo(bp);
        });
        break;

      case ExploreSortOption.priceHighLow:
        result.sort((a, b) {
          final ap = (_currentPrice(a) ?? -1).toDouble();
          final bp = (_currentPrice(b) ?? -1).toDouble();
          return bp.compareTo(ap);
        });
        break;

      case ExploreSortOption.dateSoonest:
        result.sort((a, b) {
          final ad = a.start;
          final bd = b.start;
          if (ad == null && bd == null) return 0;
          if (ad == null) return 1;
          if (bd == null) return -1;
          return ad.compareTo(bd);
        });
        break;
    }

    return result;
  }

  void _openDetails(BuildContext context, int itemId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ItemDetailsPage(itemId: itemId)),
    );
  }

  String _ctaLabelFor(BuildContext context, ItemSummary item) {
    final l10n = AppLocalizations.of(context)!;

    switch (item.kind) {
      case ItemKind.product:
        // ✅ Out of stock label
        if (_isOutOfStock(item)) return l10n.outOfStock;
        return l10n.cart_add_button;

      case ItemKind.activity:
        return l10n.home_book_now_button;

      default:
        return l10n.home_view_details_button;
    }
  }

  String? _subtitleFor(ItemSummary item) {
    switch (item.kind) {
      case ItemKind.activity:
        return item.location;
      case ItemKind.product:
        return item.subtitle;
      default:
        return item.subtitle ?? item.location;
    }
  }

  String? _metaLabelFor(ItemSummary item) {
    final l10n = AppLocalizations.of(context)!;

    switch (item.kind) {
      case ItemKind.activity:
        if (item.start == null) return null;
        final dt = item.start!.toLocal();
        final y = dt.year.toString().padLeft(4, '0');
        final m = dt.month.toString().padLeft(2, '0');
        final d = dt.day.toString().padLeft(2, '0');
        final hh = dt.hour.toString().padLeft(2, '0');
        final mm = dt.minute.toString().padLeft(2, '0');
        return '$d/$m/$y  $hh:$mm';

      case ItemKind.product:
        // ✅ show Out of stock instead of Stock: 0
        if (_isOutOfStock(item)) return l10n.outOfStock;
        if (item.stock == null) return null;
        return l10n.home_stock_label(item.stock!);

      default:
        return null;
    }
  }

  void _handleCtaPressed(BuildContext context, ItemSummary item) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthBloc>().state;

    if (!auth.isLoggedIn) {
      AppToast.show(context, l10n.cart_login_required_message, isError: true);
      return;
    }

    if (item.kind == ItemKind.product) {
      // ✅ HARD GUARD (even if UI bug)
      if (_isOutOfStock(item)) {
        AppToast.show(context, l10n.outOfStock, isError: true);
        return;
      }

      context.read<CartBloc>().add(
            CartAddItemRequested(itemId: item.id, quantity: 1),
          );
      AppToast.show(context, l10n.cart_item_added_snackbar);
      return;
    }

    _openDetails(context, item.id);
  }

  // pricing (sale window)
  bool _isSaleActiveNow(ItemSummary item) {
    final now = DateTime.now();
    final start = item.saleStart;
    final end = item.saleEnd;

    if (start == null && end == null) return item.onSale;
    if (start != null && end == null) return !now.isBefore(start);
    if (start == null && end != null) return !now.isAfter(end);

    return !now.isBefore(start!) && !now.isAfter(end!);
  }

  num? _currentPrice(ItemSummary item) {
    final saleActive = item.onSale && _isSaleActiveNow(item);
    return saleActive
        ? (item.effectivePrice ?? item.salePrice ?? item.price)
        : item.price;
  }

  // uses money(context, amount) so currency is dynamic
  _PricingView _pricingFor(BuildContext context, ItemSummary item) {
    final saleActive = item.onSale && _isSaleActiveNow(item);
    final current = _currentPrice(item);

    final currentLabel =
        current != null ? money(context, current.toDouble()) : null;

    String? oldLabel;
    if (saleActive && item.price != null && current != null) {
      final base = item.price!.toDouble();
      final cur = current.toDouble();
      if (base > cur) oldLabel = money(context, base);
    }

    String? tagLabel;
    if (saleActive && item.price != null && current != null) {
      final base = item.price!.toDouble();
      final cur = current.toDouble();
      if (base > 0) {
        final percent = ((1 - (cur / base)) * 100).round();
        tagLabel = percent > 0 ? '-$percent%' : 'SALE';
      }
    }

    return _PricingView(
      currentLabel: currentLabel,
      oldLabel: oldLabel,
      tagLabel: tagLabel,
    );
  }
}

// =========================
// UI pieces
// =========================

class _PricingView {
  final String? currentLabel;
  final String? oldLabel;
  final String? tagLabel;

  const _PricingView({
    required this.currentLabel,
    required this.oldLabel,
    required this.tagLabel,
  });
}

class _ExploreCategoryChips extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategoryLabel;
  final ValueChanged<String?> onCategorySelected;

  const _ExploreCategoryChips({
    super.key,
    required this.categories,
    required this.selectedCategoryLabel,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final spacing = context.read<ThemeCubit>().state.tokens.spacing;

    final List<String?> allCats = [null, ...categories];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: allCats.length,
        separatorBuilder: (_, __) => SizedBox(width: spacing.sm),
        itemBuilder: (context, index) {
          final cat = allCats[index];
          final bool isSelected =
              (cat == null && selectedCategoryLabel == null) ||
                  (cat != null && cat == selectedCategoryLabel);

          final label =
              cat ?? AppLocalizations.of(context)!.explore_category_all;

          return GestureDetector(
            onTap: () => onCategorySelected(cat),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.md,
                vertical: spacing.xs + 2,
              ),
              decoration: BoxDecoration(
                color: isSelected ? c.primary : c.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? c.primary : c.outline.withOpacity(0.3),
                ),
              ),
              child: Text(
                label,
                style: t.bodyMedium?.copyWith(
                  color: isSelected ? c.onPrimary : c.onSurface,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final ExploreSortOption current;
  final ValueChanged<ExploreSortOption> onChanged;

  const _SortDropdown({
    super.key,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final spacing = context.read<ThemeCubit>().state.tokens.spacing;

    String labelFor(ExploreSortOption opt) {
      switch (opt) {
        case ExploreSortOption.relevance:
          return l.explore_sort_relevance;
        case ExploreSortOption.priceLowHigh:
          return l.explore_sort_price_low_high;
        case ExploreSortOption.priceHighLow:
          return l.explore_sort_price_high_low;
        case ExploreSortOption.dateSoonest:
          return l.explore_sort_date_soonest;
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: spacing.sm),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.outline.withOpacity(0.4)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ExploreSortOption>(
          value: current,
          isDense: true,
          icon: Icon(
            Icons.expand_more_rounded,
            size: 20,
            color: c.onSurface.withOpacity(0.8),
          ),
          style: t.bodyMedium,
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
          items: ExploreSortOption.values.map((opt) {
            return DropdownMenuItem<ExploreSortOption>(
              value: opt,
              child: Text(labelFor(opt), overflow: TextOverflow.ellipsis),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ExploreItemsGrid extends StatelessWidget {
  final List<ItemSummary> items;

  final _PricingView Function(BuildContext, ItemSummary) pricingFor;
  final String? Function(ItemSummary) subtitleFor;
  final String? Function(ItemSummary) metaFor;

  final String Function(BuildContext, ItemSummary) ctaLabelFor;
  final bool Function(ItemSummary) isOutOfStock; // ✅ NEW

  final void Function(int itemId) onTapItem;
  final void Function(ItemSummary) onCtaPressed;

  const _ExploreItemsGrid({
    super.key,
    required this.items,
    required this.pricingFor,
    required this.subtitleFor,
    required this.metaFor,
    required this.ctaLabelFor,
    required this.isOutOfStock,
    required this.onTapItem,
    required this.onCtaPressed,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.read<ThemeCubit>().state.tokens.spacing;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final double aspect = w <= 420 ? 0.52 : (w <= 700 ? 0.60 : 0.70);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: spacing.md,
            crossAxisSpacing: spacing.md,
            childAspectRatio: aspect,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];

            return Builder(
              builder: (ctx) {
                final pricing = pricingFor(ctx, item);

                final bool out = isOutOfStock(item);

                return ItemCard(
                  itemId: item.id,
                  width: double.infinity,
                  imageFit: item.kind == ItemKind.product
                      ? BoxFit.contain
                      : BoxFit.cover,
                  title: item.title,
                  subtitle: subtitleFor(item),
                  imageUrl: item.imageUrl,
                  badgeLabel: pricing.currentLabel,
                  oldPriceLabel: pricing.oldLabel,
                  tagLabel: pricing.tagLabel,
                  metaLabel: metaFor(item),
                  ctaLabel: ctaLabelFor(ctx, item),
                  onTap: () => onTapItem(item.id),

                  // ✅ KEY: null => disabled button
                  onCtaPressed: out ? null : () => onCtaPressed(item),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final spacing = context.read<ThemeCubit>().state.tokens.spacing;

    List<int> pagesToShow() {
      if (totalPages <= 5) {
        return List.generate(totalPages, (i) => i + 1);
      }
      final set = <int>{
        1,
        totalPages,
        currentPage - 1,
        currentPage,
        currentPage + 1,
      };
      final list = set.where((p) => p >= 1 && p <= totalPages).toList()..sort();
      return list;
    }

    final pages = pagesToShow();

    Widget pageButton(int p) {
      final selected = p == currentPage;
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onPageChanged(p),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.md,
            vertical: spacing.xs + 2,
          ),
          decoration: BoxDecoration(
            color: selected ? c.primary : c.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? c.primary : c.outline.withOpacity(0.25),
            ),
          ),
          child: Text(
            '$p',
            style: t.bodyMedium?.copyWith(
              color: selected ? c.onPrimary : c.onSurface,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Prev',
          onPressed:
              currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        SizedBox(width: spacing.xs),
        ..._withEllipsis(
          pages,
          (p) => Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing.xs),
            child: pageButton(p),
          ),
          spacing: spacing,
        ),
        SizedBox(width: spacing.xs),
        IconButton(
          tooltip: 'Next',
          onPressed: currentPage < totalPages
              ? () => onPageChanged(currentPage + 1)
              : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }

  static List<Widget> _withEllipsis(
    List<int> pages,
    Widget Function(int) buildPage, {
    required dynamic spacing,
  }) {
    final widgets = <Widget>[];
    for (var i = 0; i < pages.length; i++) {
      widgets.add(buildPage(pages[i]));

      if (i < pages.length - 1) {
        final gap = pages[i + 1] - pages[i];
        if (gap > 1) {
          widgets.add(
            Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing.xs),
              child: const Text('…'),
            ),
          );
        }
      }
    }
    return widgets;
  }
}

class _EmptyExploreState extends StatelessWidget {
  final String message;
  const _EmptyExploreState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final spacing = context.read<ThemeCubit>().state.tokens.spacing;

    return Container(
      margin: EdgeInsets.only(top: spacing.lg),
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.search_off_rounded, color: c.primary),
          SizedBox(width: spacing.sm),
          Expanded(child: Text(message, style: t.bodyMedium)),
        ],
      ),
    );
  }
}
