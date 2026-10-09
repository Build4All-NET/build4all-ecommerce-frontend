import 'dart:convert';

import 'package:build4front/core/network/globals.dart' as net;
import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/features/admin/excel_import/presentation/bloc/excel_import_state.dart';
import 'package:build4front/features/admin/excel_import/presentation/widgets/excel_source_card.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A store without AI is offered the Build4All template and nothing else:
/// reading a file from another system and photographing products are both AI
/// features, and must not even be listed.
void main() {
  late AppLocalizations l10n;

  /// The server's answer to the AI status check the options ask on mount. The
  /// options follow the server, not whatever the app last remembered.
  void serverSays({required bool aiEnabled}) {
    net.appServerRoot = 'http://ai.test';
    net.appDio = Dio(BaseOptions(baseUrl: net.appServerRoot))
      ..httpClientAdapter = _StatusAdapter(aiEnabled);
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    net.aiEnabled = false;
  });

  tearDown(() {
    net.appDio = null;
    net.aiEnabled = false;
  });

  Future<void> pump(
    WidgetTester tester, {
    ValueChanged<ExcelImportSource>? onChanged,
  }) async {
    await tester.pumpWidget(
      BlocProvider<ThemeCubit>(
        create: (_) => ThemeCubit(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                l10n = AppLocalizations.of(context)!;
                return ExcelSourceCard(
                  source: null,
                  onChanged: onChanged ?? (_) {},
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('offers only the template when the store has no AI', (tester) async {
    serverSays(aiEnabled: false);

    await pump(tester);

    expect(find.text(l10n.excelSourceTemplate), findsOneWidget);
    expect(find.text(l10n.excelSourceOwnFile), findsNothing);
    expect(find.text(l10n.excelSourcePhotos), findsNothing);
  });

  testWidgets('also offers the own file and photographing when the store has AI', (tester) async {
    serverSays(aiEnabled: true);

    await pump(tester);

    expect(find.text(l10n.excelSourceTemplate), findsOneWidget);
    expect(find.text(l10n.excelSourceOwnFile), findsOneWidget);
    expect(find.text(l10n.excelSourcePhotos), findsOneWidget);
  });

  testWidgets('drops the AI options again when the store loses AI', (tester) async {
    serverSays(aiEnabled: true);
    await pump(tester);
    expect(find.text(l10n.excelSourceOwnFile), findsOneWidget);

    net.aiEnabled = false;
    await tester.pump();

    expect(find.text(l10n.excelSourceTemplate), findsOneWidget);
    expect(find.text(l10n.excelSourceOwnFile), findsNothing);
    expect(find.text(l10n.excelSourcePhotos), findsNothing);
  });

  testWidgets('the template can still be chosen without AI', (tester) async {
    serverSays(aiEnabled: false);
    ExcelImportSource? chosen;
    await pump(tester, onChanged: (source) => chosen = source);

    await tester.tap(find.text(l10n.excelSourceTemplate));

    expect(chosen, ExcelImportSource.template);
  });
}

/// Answers the public AI status check, and nothing else.
class _StatusAdapter implements HttpClientAdapter {
  _StatusAdapter(this.aiEnabled);

  final bool aiEnabled;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    expect(options.path, '/api/public/ai/status');

    return ResponseBody.fromString(
      jsonEncode({'aiEnabled': aiEnabled}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
