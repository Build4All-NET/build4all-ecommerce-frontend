import 'package:equatable/equatable.dart';

import '../../../items/domain/entities/item_summary.dart';
import '../../../catalog/domain/entities/category.dart';

class HomeState extends Equatable {
  final bool isLoading;
  final bool hasLoaded;
  final String? errorMessage;

  final List<ItemSummary> popularItems;
  final List<ItemSummary> recommendedItems;

  final List<String> categories;
  final List<Category> categoryEntities;

  final List<ItemSummary> flashSaleItems;
  final List<ItemSummary> newArrivalsItems;
  final List<ItemSummary> bestSellersItems;
  final List<ItemSummary> topRatedItems;

  const HomeState({
    required this.isLoading,
    required this.hasLoaded,
    required this.errorMessage,
    required this.popularItems,
    required this.recommendedItems,
    required this.categories,
    required this.categoryEntities,
    required this.flashSaleItems,
    required this.newArrivalsItems,
    required this.bestSellersItems,
    required this.topRatedItems,
  });

  factory HomeState.initial() => const HomeState(
        isLoading: false,
        hasLoaded: false,
        errorMessage: null,
        popularItems: <ItemSummary>[],
        recommendedItems: <ItemSummary>[],
        categories: <String>[],
        categoryEntities: <Category>[],
        flashSaleItems: <ItemSummary>[],
        newArrivalsItems: <ItemSummary>[],
        bestSellersItems: <ItemSummary>[],
        topRatedItems: <ItemSummary>[],
      );

  static const Object _unset = Object();

  HomeState copyWith({
    bool? isLoading,
    bool? hasLoaded,
    Object? errorMessage = _unset,
    List<ItemSummary>? popularItems,
    List<ItemSummary>? recommendedItems,
    List<String>? categories,
    List<Category>? categoryEntities,
    List<ItemSummary>? flashSaleItems,
    List<ItemSummary>? newArrivalsItems,
    List<ItemSummary>? bestSellersItems,
    List<ItemSummary>? topRatedItems,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      popularItems: popularItems ?? this.popularItems,
      recommendedItems: recommendedItems ?? this.recommendedItems,
      categories: categories ?? this.categories,
      categoryEntities: categoryEntities ?? this.categoryEntities,
      flashSaleItems: flashSaleItems ?? this.flashSaleItems,
      newArrivalsItems: newArrivalsItems ?? this.newArrivalsItems,
      bestSellersItems: bestSellersItems ?? this.bestSellersItems,
      topRatedItems: topRatedItems ?? this.topRatedItems,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        hasLoaded,
        errorMessage,
        popularItems,
        recommendedItems,
        categories,
        categoryEntities,
        flashSaleItems,
        newArrivalsItems,
        bestSellersItems,
        topRatedItems,
      ];
}