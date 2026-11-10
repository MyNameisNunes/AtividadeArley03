import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:previsao_tempo_cptec/controllers/city_search_controller.dart';
import 'package:previsao_tempo_cptec/controllers/weather_controller.dart';
import 'package:previsao_tempo_cptec/models/cidade.dart';
import 'package:previsao_tempo_cptec/models/previsao.dart';
import 'package:previsao_tempo_cptec/models/previsao_dia.dart';
import 'package:previsao_tempo_cptec/services/cptec_api_service.dart';

import '../support/fakes.dart';

const _sjc = Cidade(id: 4963, nome: 'São José dos Campos', uf: 'SP');

CptecApiService _apiOnline() => CptecApiService(
  client: MockClient(
    (req) async => req.url.path.endsWith('previsao.xml')
        ? fixtureResponse('previsao_4963.xml')
        : fixtureResponse('lista_cidades_sjc.xml'),
  ),
);

CptecApiService _apiOffline() => CptecApiService(
  client: MockClient(
    (_) async => throw http.ClientException('Failed host lookup'),
  ),
);

Previsao _previsaoSalva() => Previsao(
  cidadeId: _sjc.id,
  nome: _sjc.nome,
  uf: _sjc.uf,
  atualizacao: DateTime(2026, 11, 9),
  obtidaEm: DateTime(2026, 11, 9, 18),
  dias: [
    PrevisaoDia(
      dia: DateTime(2026, 11, 9),
      tempo: 'cl',
      maxima: 30,
      minima: 20,
    ),
  ],
);

void main() {
  group('WeatherController', () {
    test('online: carrega da API e grava no cache', () async {
      final db = FakeDatabaseService();
      final c = WeatherController(
        cidade: _sjc,
        api: _apiOnline(),
        database: db,
      );

      await c.carregar();

      expect(c.status, WeatherStatus.success);
      expect(c.exibindoCache, isFalse);
      expect(c.aviso, isNull);
      expect(c.previsao!.dias, hasLength(4));
      expect(db.cache[_sjc.id], isNotNull);
    });

    test('offline com cache: exibe dados salvos e aviso', () async {
      final db = FakeDatabaseService()..cache[_sjc.id] = _previsaoSalva();
      final c = WeatherController(
        cidade: _sjc,
        api: _apiOffline(),
        database: db,
      );

      await c.carregar();

      expect(c.status, WeatherStatus.success);
      expect(c.exibindoCache, isTrue);
      expect(c.aviso, contains('Sem conexão'));
      expect(c.previsao!.obtidaEm, DateTime(2026, 11, 9, 18));
    });

    test('offline sem cache: estado de erro', () async {
      final c = WeatherController(
        cidade: _sjc,
        api: _apiOffline(),
        database: FakeDatabaseService(),
      );

      await c.carregar();

      expect(c.status, WeatherStatus.error);
      expect(c.previsao, isNull);
      expect(c.erro, contains('Sem conexão'));
    });

    test('falha no refresh mantém os dados já exibidos', () async {
      var online = true;
      final api = CptecApiService(
        client: MockClient((_) async {
          if (!online) throw http.ClientException('offline');
          return fixtureResponse('previsao_4963.xml');
        }),
      );
      final c = WeatherController(
        cidade: _sjc,
        api: api,
        database: FakeDatabaseService(),
      );

      await c.carregar();
      online = false;
      await c.carregar();

      expect(c.status, WeatherStatus.success);
      expect(c.previsao!.dias, hasLength(4));
      expect(c.aviso, isNotNull);
    });

    test('alternar favorita persiste no banco', () async {
      final db = FakeDatabaseService();
      final c = WeatherController(
        cidade: _sjc,
        api: _apiOnline(),
        database: db,
      );
      await c.carregar();

      await c.alternarFavorita();
      expect(c.favorita, isTrue);
      expect(await db.isFavorita(_sjc.id), isTrue);
    });
  });

  group('CitySearchController', () {
    test('debounce: só busca depois que o usuário para de digitar', () {
      fakeAsync((async) {
        var chamadas = 0;
        final api = CptecApiService(
          client: MockClient((_) async {
            chamadas++;
            return fixtureResponse('lista_cidades_sjc.xml');
          }),
        );
        final c = CitySearchController(
          api: api,
          database: FakeDatabaseService(),
        );

        c.onQueryChanged('São');
        async.elapse(const Duration(milliseconds: 300));
        c.onQueryChanged('São J');
        async.elapse(const Duration(milliseconds: 300));
        c.onQueryChanged('São José');
        expect(chamadas, 0);

        async.elapse(const Duration(milliseconds: 700));
        async.flushMicrotasks();

        expect(chamadas, 1);
        expect(c.status, SearchStatus.success);
        expect(c.resultados.single.nome, 'São José dos Campos');
        c.dispose();
      });
    });

    test('termo curto não dispara busca', () async {
      var chamadas = 0;
      final api = CptecApiService(
        client: MockClient((_) async {
          chamadas++;
          return fixtureResponse('lista_cidades_sjc.xml');
        }),
      );
      final c = CitySearchController(api: api, database: FakeDatabaseService());
      await c.buscar('Sã');
      expect(chamadas, 0);
      expect(c.status, SearchStatus.idle);
    });

    test('nenhum resultado e erro de rede', () async {
      final vazia = CitySearchController(
        api: CptecApiService(
          client: MockClient(
            (_) async => latin1Response('<cidades></cidades>'),
          ),
        ),
        database: FakeDatabaseService(),
      );
      await vazia.buscar('xyzxyz');
      expect(vazia.status, SearchStatus.empty);

      final offline = CitySearchController(
        api: _apiOffline(),
        database: FakeDatabaseService(),
      );
      await offline.buscar('Campinas');
      expect(offline.status, SearchStatus.error);
      expect(offline.erro, isNotNull);
    });

    test('selecionar cidade salva nos recentes', () async {
      final db = FakeDatabaseService();
      final c = CitySearchController(api: _apiOnline(), database: db);
      await c.selecionarCidade(_sjc);
      expect(c.recentes.single.id, _sjc.id);

      await c.alternarFavorita(_sjc);
      expect(c.isFavorita(_sjc.id), isTrue);
      expect(c.recentesNaoFavoritas, isEmpty);
    });
  });
}
