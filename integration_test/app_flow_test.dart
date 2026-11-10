// Teste ponta a ponta contra a API REAL do CPTEC (requer internet).
//
//   flutter test integration_test -d linux      (ou -d <id do Android>)
//
// Defina SCREENSHOT_DIR para salvar capturas de cada etapa:
//   flutter test integration_test -d linux --dart-define=SCREENSHOT_DIR=/tmp/prints
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:previsao_tempo_cptec/app.dart';
import 'package:previsao_tempo_cptec/services/cptec_api_service.dart';
import 'package:previsao_tempo_cptec/services/database_service.dart';
import 'package:previsao_tempo_cptec/utils/constants.dart';
import 'package:previsao_tempo_cptec/views/widgets/weather_day_card.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _screenshotDir = String.fromEnvironment('SCREENSHOT_DIR');
final _raiz = GlobalKey();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    Intl.defaultLocale = 'pt_BR';
    await initializeDateFormatting('pt_BR');
  });

  testWidgets('busca, previsão real, gráfico e favoritos', (tester) async {
    DatabaseFactory? factory;
    if (Platform.isLinux || Platform.isWindows) {
      sqfliteFfiInit();
      factory = databaseFactoryFfi;
    }
    final db = DatabaseService(factory: factory, path: inMemoryDatabasePath);
    addTearDown(db.close);

    await tester.pumpWidget(
      RepaintBoundary(
        key: _raiz,
        child: PrevisaoApp(api: CptecApiService(), database: db),
      ),
    );
    await tester.pumpAndSettle();
    await _print(tester, '01_inicio');

    // Busca com acento: o app normaliza antes de chamar a API.
    await tester.enterText(find.byType(TextField), 'São José dos Campos');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    final resultado = find.descendant(
      of: find.byType(ListTile),
      matching: find.text('São José dos Campos'),
    );
    await _esperar(tester, resultado);
    await _print(tester, '02_resultados');

    await tester.tap(resultado);
    await _esperar(tester, find.text(AppConstants.fonteDados));
    await _esperar(tester, find.byType(WeatherDayCard));
    await tester.pumpAndSettle();
    await _print(tester, '03_previsao');

    expect(find.text('São José dos Campos - SP'), findsOneWidget);
    expect(find.textContaining('Atualizado pelo CPTEC em'), findsOneWidget);

    // Favoritar e rolar até os cards.
    await tester.tap(find.byTooltip('Adicionar às favoritas'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remover das favoritas'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await _print(tester, '04_cards');

    // Voltar: cidade aparece nas favoritas.
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Limpar'));
    await tester.pumpAndSettle();
    expect(find.text('Favoritas'), findsOneWidget);
    await _print(tester, '05_favoritas');
  });
}

/// Bombeia frames até o widget aparecer (rede real é assíncrona).
Future<void> _esperar(
  WidgetTester tester,
  Finder finder, {
  Duration limite = const Duration(seconds: 20),
}) async {
  final fim = DateTime.now().add(limite);
  while (DateTime.now().isBefore(fim)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Tempo esgotado esperando por $finder');
}

Future<void> _print(WidgetTester tester, String nome) async {
  if (_screenshotDir.isEmpty) return;
  final boundary =
      _raiz.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    final arquivo = File('$_screenshotDir/$nome.png')
      ..createSync(recursive: true);
    arquivo.writeAsBytesSync(png!.buffer.asUint8List());
  });
}
