import 'package:equatable/equatable.dart';

abstract class ExcelImportEvent extends Equatable {
  const ExcelImportEvent();
  @override
  List<Object?> get props => [];
}

class ExcelPickFilePressed extends ExcelImportEvent {
  const ExcelPickFilePressed();
}

class ExcelValidatePressed extends ExcelImportEvent {
  const ExcelValidatePressed();
}

class ExcelImportPressed extends ExcelImportEvent {
  const ExcelImportPressed();
}

class ExcelReplaceToggled extends ExcelImportEvent {
  final bool value;
  const ExcelReplaceToggled(this.value);

  @override
  List<Object?> get props => [value];
}

class ExcelReplaceScopeChanged extends ExcelImportEvent {
  final String scope; // TENANT | FULL
  const ExcelReplaceScopeChanged(this.scope);

  @override
  List<Object?> get props => [scope];
}

/// Downloads the blank workbook into app storage.
class ExcelDownloadTemplatePressed extends ExcelImportEvent {
  const ExcelDownloadTemplatePressed();
}

/// Attaches a gallery image to one reviewed product row.
class ExcelProductImageAssigned extends ExcelImportEvent {
  final int row;
  final int imageId;
  final String imageUrl;

  const ExcelProductImageAssigned({
    required this.row,
    required this.imageId,
    required this.imageUrl,
  });

  @override
  List<Object?> get props => [row, imageId, imageUrl];
}

/// Takes the picture back off a row.
class ExcelProductImageCleared extends ExcelImportEvent {
  final int row;

  const ExcelProductImageCleared(this.row);

  @override
  List<Object?> get props => [row];
}
