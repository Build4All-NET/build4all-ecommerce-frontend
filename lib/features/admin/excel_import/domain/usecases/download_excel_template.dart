import '../repositories/excel_import_repository.dart';

class DownloadExcelTemplate {
  final ExcelImportRepository repo;

  const DownloadExcelTemplate(this.repo);

  Future<List<int>?> call() => repo.downloadTemplate();
}
