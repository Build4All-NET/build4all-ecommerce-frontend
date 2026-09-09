import 'package:equatable/equatable.dart';

import 'product_field.dart';

/// How the server read one column of the owner's file.
class ColumnGuess extends Equatable {
  /// Zero-based position in the sheet.
  final int columnIndex;

  /// The heading as written in the file. Empty when the file has none.
  final String header;

  final ProductField field;

  /// 0..1. Shown so a shaky guess reads as a question, not a decision taken.
  final double confidence;

  /// One short line of why, in the owner's terms, so a wrong guess can be argued with.
  final String reason;

  const ColumnGuess({
    required this.columnIndex,
    required this.header,
    required this.field,
    required this.confidence,
    required this.reason,
  });

  ColumnGuess copyWith({ProductField? field}) => ColumnGuess(
        columnIndex: columnIndex,
        header: header,
        field: field ?? this.field,
        confidence: confidence,
        reason: reason,
      );

  /// True when the server was not sure enough for the owner to skip past it.
  bool get needsAttention =>
      field != ProductField.ignore && confidence < certainEnough;

  /// Below this the guess is shown as something to check rather than to accept.
  static const double certainEnough = 0.8;

  @override
  List<Object?> get props => [columnIndex, header, field, confidence, reason];
}

/// One sheet of the owner's file as the server read it.
class SheetMapping extends Equatable {
  final String sheetName;

  /// How many products the sheet appears to hold, so the owner can tell the
  /// catalogue apart from the list of suppliers.
  final int dataRowCount;

  final List<ColumnGuess> columns;

  /// Whether the assistant was consulted. Shown plainly: an owner reviewing a
  /// guess deserves to know who made it.
  final bool aiUsed;

  const SheetMapping({
    required this.sheetName,
    required this.dataRowCount,
    required this.columns,
    required this.aiUsed,
  });

  SheetMapping copyWithColumn(int columnIndex, ProductField field) {
    return SheetMapping(
      sheetName: sheetName,
      dataRowCount: dataRowCount,
      columns: [
        for (final column in columns)
          if (column.columnIndex == columnIndex)
            column.copyWith(field: field)
          // A field can only describe one column, so choosing it here takes it
          // off whichever column held it before.
          else if (field != ProductField.ignore && column.field == field)
            column.copyWith(field: ProductField.ignore)
          else
            column,
      ],
      aiUsed: aiUsed,
    );
  }

  /// The one column without which no product can be created.
  bool get hasName => columns.any((c) => c.field == ProductField.name);

  /// The payload the import call needs: column index to field name.
  Map<int, String> get wireColumns => {
        for (final column in columns)
          if (column.field != ProductField.ignore)
            column.columnIndex: column.field.wireName,
      };

  @override
  List<Object?> get props => [sheetName, dataRowCount, columns, aiUsed];
}
