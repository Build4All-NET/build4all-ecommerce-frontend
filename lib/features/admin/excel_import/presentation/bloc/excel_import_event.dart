import 'package:equatable/equatable.dart';

import '../../domain/entities/product_field.dart';
import 'excel_import_state.dart';

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

/// Switches between filling in our template and bringing a file from elsewhere.
class ExcelSourceChanged extends ExcelImportEvent {
  final ExcelImportSource source;
  const ExcelSourceChanged(this.source);

  @override
  List<Object?> get props => [source];
}

/// Asks the server what the owner's own file appears to contain.
class ExcelReadOwnFilePressed extends ExcelImportEvent {
  const ExcelReadOwnFilePressed();
}

/// Picks which sheet of the file holds the products.
class ExcelSheetSelected extends ExcelImportEvent {
  final String sheetName;
  const ExcelSheetSelected(this.sheetName);

  @override
  List<Object?> get props => [sheetName];
}

/// Corrects what one column was read as.
class ExcelColumnFieldChanged extends ExcelImportEvent {
  final int columnIndex;
  final ProductField field;

  const ExcelColumnFieldChanged({required this.columnIndex, required this.field});

  @override
  List<Object?> get props => [columnIndex, field];
}

/// Names the group products fall under when the file carries no category column.
class ExcelForeignCategoryChanged extends ExcelImportEvent {
  final String categoryName;
  const ExcelForeignCategoryChanged(this.categoryName);

  @override
  List<Object?> get props => [categoryName];
}

/// Chooses what happens to products whose code the owner already has.
class ExcelMatchModeChanged extends ExcelImportEvent {
  final String matchMode; // ADD_AND_UPDATE | ADD_ONLY
  const ExcelMatchModeChanged(this.matchMode);

  @override
  List<Object?> get props => [matchMode];
}

/// Imports the owner's own file, the way they confirmed it.
class ExcelForeignImportPressed extends ExcelImportEvent {
  const ExcelForeignImportPressed();
}

/// Asks whether there are products worth offering to describe.
class ExcelDescriptionsChecked extends ExcelImportEvent {
  const ExcelDescriptionsChecked();
}

/// Sets the assistant writing the descriptions the catalogue arrived without.
class ExcelWriteDescriptionsPressed extends ExcelImportEvent {
  const ExcelWriteDescriptionsPressed();
}

/// Asks what the import would create, before it creates it.
class ExcelPreviewForeignPressed extends ExcelImportEvent {
  const ExcelPreviewForeignPressed();
}

/// Corrects the price of one product on the review list.
class ExcelRowPriceChanged extends ExcelImportEvent {
  final int row;
  final String price;

  const ExcelRowPriceChanged({required this.row, required this.price});

  @override
  List<Object?> get props => [row, price];
}

/// Corrects the quantity of one product on the review list.
class ExcelRowStockChanged extends ExcelImportEvent {
  final int row;
  final String stock;

  const ExcelRowStockChanged({required this.row, required this.stock});

  @override
  List<Object?> get props => [row, stock];
}

/// Narrows the review list to the products with something missing.
class ExcelPreviewFilterChanged extends ExcelImportEvent {
  final bool issuesOnly;
  const ExcelPreviewFilterChanged(this.issuesOnly);

  @override
  List<Object?> get props => [issuesOnly];
}

/// Narrows the review list by name or code.
class ExcelPreviewSearchChanged extends ExcelImportEvent {
  final String query;
  const ExcelPreviewSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}
