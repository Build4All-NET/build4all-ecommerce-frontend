import '../entities/description_job.dart';
import '../repositories/excel_import_repository.dart';

/// Sets the assistant writing the descriptions the catalogue arrived without.
class WriteMissingDescriptions {
  final ExcelImportRepository repo;

  WriteMissingDescriptions(this.repo);

  Future<DescriptionJob> call(DescriptionJob current) => repo.startDescriptions(current);
}
