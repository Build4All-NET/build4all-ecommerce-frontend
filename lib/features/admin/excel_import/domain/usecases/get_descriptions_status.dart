import '../entities/description_job.dart';
import '../repositories/excel_import_repository.dart';

/// Asks whether there are products worth offering to describe.
class GetDescriptionsStatus {
  final ExcelImportRepository repo;

  GetDescriptionsStatus(this.repo);

  Future<DescriptionJob> call() => repo.descriptionsStatus();
}
