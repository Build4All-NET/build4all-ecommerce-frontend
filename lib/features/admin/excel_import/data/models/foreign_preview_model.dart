import '../../domain/entities/foreign_preview.dart';
import 'excel_validation_result_model.dart';

/// Reads the preview of an import that has not happened yet.
class ForeignPreviewModel {
  const ForeignPreviewModel._();

  static ForeignPreview fromJson(Map<String, dynamic> json) {
    final products = json['products'];

    return ForeignPreview(
      // The rows come back in the same shape the template's own review screen
      // reads, so both ways in share one parser and one row widget.
      products: products is List
          ? ExcelValidationResultModel.productPreviewsFrom(products)
          : const [],
      skippedRows: json['skippedRows'] is num
          ? (json['skippedRows'] as num).toInt()
          : 0,
    );
  }
}
