import 'package:build4front/features/admin/excel_import/presentation/bloc/excel_import_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// With no AI the template is the only way to import, so it is already chosen
/// when the screen opens. With AI the owner is still asked.
void main() {
  final initial = ExcelImportState.initial();

  test('the template is chosen for a store without AI', () {
    expect(initial.effectiveSource(aiEnabled: false), ExcelImportSource.template);
  });

  test('nothing is chosen for a store with AI, so the owner is asked', () {
    expect(initial.effectiveSource(aiEnabled: true), isNull);
  });

  test('a source the owner picked is kept', () {
    final picked = initial.copyWith(source: ExcelImportSource.photos);

    expect(picked.effectiveSource(aiEnabled: true), ExcelImportSource.photos);
    expect(picked.effectiveSource(aiEnabled: false), ExcelImportSource.photos);
  });
}
