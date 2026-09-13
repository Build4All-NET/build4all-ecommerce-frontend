import '../../domain/entities/owner_user_statistics.dart';
import '../../domain/repositories/owner_statistics_repository.dart';

import '../models/owner_user_statistics_model.dart';
import '../services/owner_statistics_api_service.dart';

class OwnerStatisticsRepositoryImpl implements OwnerStatisticsRepository {
  final OwnerStatisticsApiService api;

  const OwnerStatisticsRepositoryImpl({required this.api});

  @override
  Future<OwnerUserStatistics> getStatistics() async {
    final json = await api.getStatisticsJson();
    return OwnerUserStatisticsModel.fromJson(json);
  }
}
