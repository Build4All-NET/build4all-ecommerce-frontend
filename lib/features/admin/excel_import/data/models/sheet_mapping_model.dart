import '../../domain/entities/product_field.dart';
import '../../domain/entities/sheet_mapping.dart';

/// Reads what the server made of the owner's file.
///
/// Deliberately forgiving. This response describes a file nobody wrote to a
/// spec, and one column the app cannot make sense of should cost that column,
/// not the whole reading -- the owner can still fix it on the review screen.
class SheetMappingModel {
  const SheetMappingModel._();

  static List<SheetMapping> listFromJson(dynamic json) {
    if (json is! List) return const [];

    return json
        .whereType<Map>()
        .map((sheet) => _sheetFrom(sheet.cast<String, dynamic>()))
        .toList();
  }

  static SheetMapping _sheetFrom(Map<String, dynamic> json) {
    final rawColumns = json['columns'];

    return SheetMapping(
      sheetName: (json['sheetName'] ?? '').toString(),
      dataRowCount: _int(json['dataRowCount']),
      aiUsed: json['aiUsed'] == true,
      columns: rawColumns is List
          ? rawColumns
              .whereType<Map>()
              .map((column) => _columnFrom(column.cast<String, dynamic>()))
              .toList()
          : const [],
    );
  }

  static ColumnGuess _columnFrom(Map<String, dynamic> json) {
    return ColumnGuess(
      columnIndex: _int(json['columnIndex']),
      header: (json['header'] ?? '').toString(),
      field: ProductField.fromWire(json['field']?.toString()),
      confidence: _double(json['confidence']),
      reason: ColumnGuessReason.fromWire(json['reason']?.toString()),
      disputedWith: json['disputedWith'] == null
          ? null
          : ProductField.fromWire(json['disputedWith'].toString()),
    );
  }

  static int _int(dynamic value) => value is num ? value.toInt() : 0;

  static double _double(dynamic value) => value is num ? value.toDouble() : 0;
}
