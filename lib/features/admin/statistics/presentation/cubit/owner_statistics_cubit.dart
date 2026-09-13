import 'package:build4front/core/exceptions/exception_mapper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/owner_app_user.dart';
import '../../domain/entities/owner_user_statistics.dart';
import '../../domain/usecases/get_owner_user_statistics.dart';

enum OwnerStatisticsStatus { initial, loading, loaded, error }

class OwnerStatisticsState {
  final OwnerStatisticsStatus status;
  final OwnerUserStatistics statistics;
  final String query;
  final String? error;

  /// True while a pull-to-refresh runs over content that is already on screen,
  /// so the list stays visible instead of flashing back to a spinner.
  final bool refreshing;

  const OwnerStatisticsState({
    required this.status,
    required this.statistics,
    required this.query,
    required this.error,
    required this.refreshing,
  });

  const OwnerStatisticsState.initial()
      : status = OwnerStatisticsStatus.initial,
        statistics = OwnerUserStatistics.empty,
        query = '',
        error = null,
        refreshing = false;

  List<OwnerAppUser> get visibleUsers => statistics.search(query);

  OwnerStatisticsState copyWith({
    OwnerStatisticsStatus? status,
    OwnerUserStatistics? statistics,
    String? query,
    String? error,
    bool clearError = false,
    bool? refreshing,
  }) {
    return OwnerStatisticsState(
      status: status ?? this.status,
      statistics: statistics ?? this.statistics,
      query: query ?? this.query,
      error: clearError ? null : (error ?? this.error),
      refreshing: refreshing ?? this.refreshing,
    );
  }
}

class OwnerStatisticsCubit extends Cubit<OwnerStatisticsState> {
  final GetOwnerUserStatistics getStatistics;

  OwnerStatisticsCubit({required this.getStatistics})
      : super(const OwnerStatisticsState.initial());

  Future<void> load({bool refresh = false}) async {
    if (refresh) {
      emit(state.copyWith(refreshing: true, clearError: true));
    } else {
      emit(state.copyWith(
        status: OwnerStatisticsStatus.loading,
        clearError: true,
      ));
    }

    try {
      final statistics = await getStatistics();

      emit(state.copyWith(
        status: OwnerStatisticsStatus.loaded,
        statistics: statistics,
        refreshing: false,
        clearError: true,
      ));
    } catch (e) {
      // A failed refresh keeps the rows the owner is already looking at; a
      // failed first load has nothing to fall back on, so it shows the error.
      final keepContent =
          refresh && state.status == OwnerStatisticsStatus.loaded;

      emit(state.copyWith(
        status: keepContent
            ? OwnerStatisticsStatus.loaded
            : OwnerStatisticsStatus.error,
        error: ExceptionMapper.toMessage(e),
        refreshing: false,
      ));
    }
  }

  void search(String query) {
    if (query == state.query) return;
    emit(state.copyWith(query: query));
  }

  void clearError() {
    if (state.error == null) return;
    emit(state.copyWith(clearError: true));
  }
}
