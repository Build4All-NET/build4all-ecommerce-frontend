import 'package:equatable/equatable.dart';

import 'product_field.dart';

/// Why a column was read the way it was.
///
/// A code rather than a sentence: the server does not know the owner's language,
/// and the wording belongs where the rest of the app's wording lives.
enum ColumnGuessReason {
  agreed('AGREED'),
  fromValues('FROM_VALUES'),
  fromHeading('FROM_HEADING'),
  fromAssistant('FROM_ASSISTANT'),
  disputed('DISPUTED'),
  noMatch('NO_MATCH');

  final String wireName;

  const ColumnGuessReason(this.wireName);

  static ColumnGuessReason fromWire(String? value) {
    if (value == null) return ColumnGuessReason.noMatch;

    final normalized = value.trim().toUpperCase();
    for (final reason in ColumnGuessReason.values) {
      if (reason.wireName == normalized) return reason;
    }
    return ColumnGuessReason.noMatch;
  }
}

/// How the server read one column of the owner's file.
class ColumnGuess extends Equatable {
  /// Zero-based position in the sheet.
  final int columnIndex;

  /// The heading as written in the file. Empty when the file has none.
  final String header;

  final ProductField field;

  /// 0..1. Shown so a shaky guess reads as a question, not a decision taken.
  final double confidence;

  /// Why, as a code the app puts into words, so the owner reads it in their own
  /// language rather than in the server's.
  final ColumnGuessReason reason;

  /// When the assistant and the values disagree, what the values made of the
  /// column -- shown alongside so the owner can see both readings.
  final ProductField? disputedWith;

  const ColumnGuess({
    required this.columnIndex,
    required this.header,
    required this.field,
    required this.confidence,
    required this.reason,
    this.disputedWith,
  });

  ColumnGuess copyWith({ProductField? field}) => ColumnGuess(
        columnIndex: columnIndex,
        header: header,
        field: field ?? this.field,
        confidence: confidence,
        reason: reason,
        disputedWith: disputedWith,
      );

  /// True when the server was not sure enough for the owner to skip past it.
  bool get needsAttention =>
      field != ProductField.ignore && confidence < certainEnough;

  /// True when this column becomes part of a product.
  bool get isImported => field != ProductField.ignore;

  /// Below this the guess is shown as something to check rather than to accept.
  static const double certainEnough = 0.8;

  @override
  List<Object?> get props =>
      [columnIndex, header, field, confidence, reason, disputedWith];
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

  /// The columns that become part of a product -- what the owner is really
  /// reviewing.
  List<ColumnGuess> get imported => columns.where((c) => c.isImported).toList();

  /// The columns the catalogue has no home for. Kept out of the way: a Shopify
  /// export carries fourteen columns and eight of them are ours to skip, and
  /// scrolling past eight identical "not imported" lines is how an owner stops
  /// reading the four that matter.
  List<ColumnGuess> get skipped => columns.where((c) => !c.isImported).toList();

  /// The ones the server was unsure about -- the only ones worth stopping on.
  List<ColumnGuess> get toCheck =>
      columns.where((c) => c.needsAttention).toList();

  /// The payload the import call needs: column index to field name.
  Map<int, String> get wireColumns => {
        for (final column in columns)
          if (column.field != ProductField.ignore)
            column.columnIndex: column.field.wireName,
      };

  @override
  List<Object?> get props => [sheetName, dataRowCount, columns, aiUsed];
}
