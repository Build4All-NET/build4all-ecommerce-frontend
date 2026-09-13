import '../entities/owner_user_statistics.dart';
import '../repositories/owner_statistics_repository.dart';

class GetOwnerUserStatistics {
  final OwnerStatisticsRepository repository;

  const GetOwnerUserStatistics(this.repository);

  Future<OwnerUserStatistics> call() => repository.getStatistics();
}
