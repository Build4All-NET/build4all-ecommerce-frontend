import '../entities/owner_user_statistics.dart';

abstract class OwnerStatisticsRepository {
  /// Audience counts plus the contactable user list for the signed-in owner.
  Future<OwnerUserStatistics> getStatistics();
}
