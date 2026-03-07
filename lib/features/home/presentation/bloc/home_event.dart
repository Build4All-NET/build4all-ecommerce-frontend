import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class HomeStarted extends HomeEvent {
  final String? token;

  const HomeStarted({this.token});

  @override
  List<Object?> get props => [token];
}

class HomeRefreshRequested extends HomeEvent {
  final String? token;

  const HomeRefreshRequested({this.token});

  @override
  List<Object?> get props => [token];
}

class HomeSearchChanged extends HomeEvent {
  final String query;

  const HomeSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class HomeCategorySelected extends HomeEvent {
  final int categoryId;

  const HomeCategorySelected(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}