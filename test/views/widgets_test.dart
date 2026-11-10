import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:previsao_tempo_cptec/app.dart';
import 'package:previsao_tempo_cptec/models/cidade.dart';
import 'package:previsao_tempo_cptec/models/previsao.dart';
import 'package:previsao_tempo_cptec/models/previsao_dia.dart';
import 'package:previsao_tempo_cptec/services/cptec_api_service.dart';
import 'package:previsao_tempo_cptec/utils/constants.dart';
import 'package:previsao_tempo_cptec/views/widgets/error_state_widget.dart';
import 'package:previsao_tempo_cptec/views/widgets/stale_data_banner.dart';
import 'package:previsao_tempo_cptec/views/widgets/temperature_chart.dart';
import 'package:previsao_tempo_cptec/views/widgets/weather_day_card.dart';

import '../support/fakes.dart';

/// Largura de celular (432 dp) para pegar overflow horizontal, com altura
/// suficiente para o ListView construir todos os cards.
void usarTelaDeCelular(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 7200);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
}

Widget _emApp(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  group('WeatherDayCard', () {
    testWidgets('exibe data, condição, temperaturas e IUV', (tester) async {
      await tester.pumpWidget(
        _emApp(
          WeatherDayCard(
            agora: DateTime(2026, 11, 10, 12),
            dia: PrevisaoDia(
              dia: DateTime(2026, 11, 11),
              tempo: 'c',
              maxima: 28,
              minima: 18,
              iuv: 11.0,
            ),
          ),
        ),
      );

      expect(find.text('Amanhã'), findsOneWidget);
      expect(find.text('Qua, 11/11/2026'), findsOneWidget);
      expect(find.text('Chuva'), findsOneWidget);
      expect(find.text('28 °C'), findsOneWidget);
      expect(find.text('18 °C'), findsOneWidget);
      expect(find.text('IUV 11,0 · Extremo'), findsOneWidget);
      expect(find.byIcon(Icons.umbrella), findsOneWidget);
    });

    testWidgets('valores ausentes não quebram o card', (tester) async {
      await tester.pumpWidget(
        _emApp(
          WeatherDayCard(
            dia: PrevisaoDia(
              dia: DateTime(2026, 11, 13),
              tempo: 'xx',
              iuv: 0.0,
            ),
          ),
        ),
      );

      expect(find.text('--'), findsNWidgets(2));
      expect(find.text('IUV não informado'), findsOneWidget);
      expect(find.text('Condição não identificada (xx)'), findsOneWidget);
    });
  });

  group('TemperatureChart', () {
    testWidgets('plota duas linhas (máx/mín) com 4 pontos', (tester) async {
      final dias = [
        for (var i = 0; i < 4; i++)
          PrevisaoDia(
            dia: DateTime(2026, 11, 10 + i),
            maxima: 25 + i,
            minima: 15 + i,
          ),
      ];
      await tester.pumpWidget(_emApp(TemperatureChart(dias: dias)));
      await tester.pumpAndSettle();

      final chart = tester.widget<LineChart>(find.byType(LineChart));
      expect(chart.data.lineBarsData, hasLength(2));
      expect(chart.data.lineBarsData[0].spots.map((s) => s.y), [
        25,
        26,
        27,
        28,
      ]);
      expect(chart.data.lineBarsData[1].spots.map((s) => s.y), [
        15,
        16,
        17,
        18,
      ]);
      expect(find.text('Máxima'), findsOneWidget);
      expect(find.text('Mínima'), findsOneWidget);
    });

    testWidgets('sem temperaturas mostra mensagem', (tester) async {
      await tester.pumpWidget(
        _emApp(
          TemperatureChart(dias: [PrevisaoDia(dia: DateTime(2026, 11, 10))]),
        ),
      );
      expect(find.byType(LineChart), findsNothing);
      expect(find.textContaining('Sem dados de temperatura'), findsOneWidget);
    });
  });

  group('Fluxo do app', () {
    Future<void> abrirSjc(WidgetTester tester) async {
      await tester.enterText(find.byType(TextField), 'sao jose');
      await tester.pump(
        AppConstants.searchDebounce + const Duration(milliseconds: 50),
      );
      await tester.pumpAndSettle();
      expect(find.text('São José dos Campos'), findsOneWidget);

      await tester.tap(find.text('São José dos Campos'));
      await tester.pumpAndSettle();
    }

    testWidgets('buscar cidade, abrir previsão e salvar nos recentes', (
      tester,
    ) async {
      usarTelaDeCelular(tester);

      final db = FakeDatabaseService();
      final api = CptecApiService(
        client: MockClient(
          (req) async => req.url.path.endsWith('previsao.xml')
              ? fixtureResponse('previsao_4963.xml')
              : fixtureResponse('lista_cidades_sjc.xml'),
        ),
      );
      await tester.pumpWidget(PrevisaoApp(api: api, database: db));
      await tester.pumpAndSettle();

      expect(find.text('Pesquise um município'), findsOneWidget);

      await abrirSjc(tester);

      expect(find.text('São José dos Campos - SP'), findsOneWidget); // AppBar
      expect(find.text(AppConstants.fonteDados), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.byType(WeatherDayCard), findsNWidgets(4));
      expect(db.cache[4963], isNotNull);

      // Volta e a cidade aparece nos recentes.
      await tester.tap(find.byTooltip('Voltar')); // app em pt_BR
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Limpar'));
      await tester.pumpAndSettle();
      expect(find.text('Consultadas recentemente'), findsOneWidget);
      expect(find.text('São José dos Campos'), findsOneWidget);
    });

    testWidgets('offline sem cache mostra erro com "Tentar novamente"', (
      tester,
    ) async {
      usarTelaDeCelular(tester);
      var online = true;
      final api = CptecApiService(
        client: MockClient((req) async {
          if (req.url.path.endsWith('previsao.xml') && !online) {
            throw http.ClientException('Failed host lookup');
          }
          return req.url.path.endsWith('previsao.xml')
              ? fixtureResponse('previsao_4963.xml')
              : fixtureResponse('lista_cidades_sjc.xml');
        }),
      );
      online = false;
      await tester.pumpWidget(
        PrevisaoApp(api: api, database: FakeDatabaseService()),
      );

      await abrirSjc(tester);

      expect(find.byType(ErrorStateWidget), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);

      online = true;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(find.byType(ErrorStateWidget), findsNothing);
      expect(find.text(AppConstants.fonteDados), findsOneWidget);
    });

    testWidgets('offline com cache mostra dados salvos e banner', (
      tester,
    ) async {
      usarTelaDeCelular(tester);
      final db = FakeDatabaseService()
        ..cache[4963] = Previsao(
          cidadeId: 4963,
          nome: 'São José dos Campos',
          uf: 'SP',
          atualizacao: DateTime(2026, 11, 9),
          obtidaEm: DateTime(2026, 11, 9, 18, 0),
          dias: [
            PrevisaoDia(
              dia: DateTime(2026, 11, 9),
              tempo: 'cl',
              maxima: 30,
              minima: 20,
            ),
          ],
        );
      final api = CptecApiService(
        client: MockClient((req) async {
          if (req.url.path.endsWith('previsao.xml')) {
            throw http.ClientException('Failed host lookup');
          }
          return fixtureResponse('lista_cidades_sjc.xml');
        }),
      );
      await tester.pumpWidget(PrevisaoApp(api: api, database: db));

      await abrirSjc(tester);

      expect(find.byType(StaleDataBanner), findsOneWidget);
      expect(
        find.textContaining('Exibindo dados salvos em 09/11/2026 às 18:00'),
        findsOneWidget,
      );
      expect(find.byType(WeatherDayCard), findsOneWidget);
    });
  });

  test('Cidade.nomeComUf', () {
    expect(
      const Cidade(id: 1, nome: 'Natal', uf: 'RN').nomeComUf,
      'Natal - RN',
    );
  });
}
