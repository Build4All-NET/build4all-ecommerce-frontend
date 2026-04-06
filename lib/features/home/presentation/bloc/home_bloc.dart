import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/env.dart';
import '../../../../core/exceptions/exception_mapper.dart';

// items
import '../../../items/domain/entities/item_summary.dart';
import '../../../items/domain/usecases/get_guest_upcoming_items.dart';
import '../../../items/domain/usecases/get_interest_based_items.dart';
import '../../../items/domain/usecases/get_items_by_type.dart';
import '../../../items/domain/usecases/get_new_arrivals_items.dart';
import '../../../items/domain/usecases/get_best_sellers_items.dart';
import '../../../items/domain/usecases/get_discounted_items.dart';

// catalog
import '../../../catalog/domain/entities/item_type.dart';
import '../../../catalog/domain/entities/category.dart';
import '../../../catalog/domain/usecases/get_item_types_by_project.dart';
import '../../../catalog/domain/usecases/get_categories_by_project.dart';

import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetGuestUpcomingItems getGuestUpcomingItems;
  final GetInterestBasedItems getInterestBasedItems;
  final GetItemsByType getItemsByType;
  final GetItemTypesByProject getItemTypesByProject;
  final GetCategoriesByProject getCategoriesByProject;

  final GetNewArrivalsItems getNewArrivalsItems;
  final GetBestSellersItems getBestSellersItems;
  final GetDiscountedItems getDiscountedItems;

  HomeBloc({
    required this.getGuestUpcomingItems,
    required this.getInterestBasedItems,
    required this.getItemsByType,
    required this.getItemTypesByProject,
    required this.getCategoriesByProject,
    required this.getNewArrivalsItems,
    required this.getBestSellersItems,
    required this.getDiscountedItems,
  }) : super(HomeState.initial()) {
    on<HomeStarted>(_onStarted);
    on<HomeRefreshRequested>(_onRefresh);
  }

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    await _loadHome(emit, token: event.token);
  }

  Future<void> _onRefresh(
    HomeRefreshRequested event,
    Emitter<HomeState> emit,
  ) async {
    await _loadHome(emit, token: event.token);
  }

  Set<int> _collectUsedCategoryIds(List<List<ItemSummary>> lists) {
    final set = <int>{};

    for (final list in lists) {
      for (final item in list) {
        final cid = item.categoryId;
        if (cid != null) set.add(cid);
      }
    }

    return set;
  }

  List<ItemSummary> _dedupeInsideSameList(List<ItemSummary> items) {
    final seen = <int>{};
    final out = <ItemSummary>[];

    for (final item in items) {
      if (seen.add(item.id)) {
        out.add(item);
      }
    }

    return out;
  }

  Future<List<ItemSummary>> _safeItems(Future<List<ItemSummary>> future) async {
    try {
      final res = await future;
      return _dedupeInsideSameList(res);
    } catch (_) {
      return <ItemSummary>[];
    }
  }

  Future<List<Category>> _safeCategories(Future<List<Category>> future) async {
    try {
      return await future;
    } catch (_) {
      return <Category>[];
    }
  }

  Future<List<ItemType>> _safeTypes(Future<List<ItemType>> future) async {
    try {
      return await future;
    } catch (_) {
      return <ItemType>[];
    }
  }

  Future<void> _loadHome(Emitter<HomeState> emit, {String? token}) async {
    if (state.isLoading) return;

    emit(
      state.copyWith(
        isLoading: true,
        errorMessage: null,
      ),
    );

    try {
      final projectId = int.tryParse(Env.projectId) ?? 0;

      final popularFuture = _safeItems(
        getGuestUpcomingItems(token: token),
      );

      final flashSaleFuture = _safeItems(
        getDiscountedItems.call(token: token),
      );

      final newArrivalsFuture = _safeItems(
        getNewArrivalsItems.call(days: 14, token: token),
      );

      final bestSellersFuture = _safeItems(
        getBestSellersItems.call(limit: 20, token: token),
      );

      final itemTypesFuture = projectId > 0
          ? _safeTypes(getItemTypesByProject(projectId))
          : Future.value(<ItemType>[]);

      final categoriesFuture = projectId > 0
          ? _safeCategories(getCategoriesByProject(projectId))
          : Future.value(<Category>[]);

      final popularItems = await popularFuture;
      final flashSaleItems = await flashSaleFuture;
      final newArrivalsItems = await newArrivalsFuture;
      final bestSellersItems = await bestSellersFuture;

      final itemTypes = await itemTypesFuture;
      // ignore: unused_local_variable
      final _ = itemTypes;

      final allCategories = await categoriesFuture;

      final recommendedItems = <ItemSummary>[];
      final topRatedItems = <ItemSummary>[];

      List<String> categoryLabels = <String>[];
      List<Category> categoryEntities = <Category>[];

      if (projectId > 0) {
        final usedCategoryIds = _collectUsedCategoryIds([
          popularItems,
          recommendedItems,
          flashSaleItems,
          newArrivalsItems,
          bestSellersItems,
          topRatedItems,
        ]);

        final filteredCategories = usedCategoryIds.isEmpty
            ? allCategories
            : allCategories.where((c) => usedCategoryIds.contains(c.id)).toList();

        categoryLabels = filteredCategories.map((c) => c.name).toList();
        categoryEntities = filteredCategories;
      }

      emit(
        state.copyWith(
          isLoading: false,
          hasLoaded: true,
          errorMessage: null,
          popularItems: popularItems,
          recommendedItems: recommendedItems,
          categories: categoryLabels,
          categoryEntities: categoryEntities,
          flashSaleItems: flashSaleItems,
          newArrivalsItems: newArrivalsItems,
          bestSellersItems: bestSellersItems,
          topRatedItems: topRatedItems,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          hasLoaded: true,
          errorMessage: ExceptionMapper.toMessage(e),
        ),
      );
    }
  }
}