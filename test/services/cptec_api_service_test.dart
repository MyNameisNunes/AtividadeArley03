import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:previsao_tempo_cptec/services/cptec_api_service.dart';
import 'package:previsao_tempo_cptec/services/cptec_exception.dart';

import '../support/fakes.dart';

void main() {
  group('CptecApiService', () {
    test(
      'decodifica latin1 dos bytes (acentos e cedilha preservados)',
      () async {
        final api = CptecApiService(
          client: MockClient(
            (_) async => latin1Response(
              '<cidades><cidade><nome>Açailândia</nome><uf>MA</uf>'
              '<id>10</id></cidade></cidades>',
            ),
          ),
        );

        final cidades = await api.buscarCidades('acailandia');
        expect(cidades.single.nome, 'Açailândia');
      },
    );

    test('decodifica a resposta real do fixture', () async {
      final api = CptecApiService(
        client: MockClient((_) async => fixtureResponse('previsao_4963.xml')),
      );
      final previsao = await api.buscarPrevisao(4963);
      expect(previsao.nome, 'São José dos Campos');
      expect(previsao.cidadeId, 4963);
    });

    test('monta as URLs esperadas, sem acentos na busca', () async {
      final urls = <Uri>[];
      final api = CptecApiService(
        client: MockClient((req) async {
          urls.add(req.url);
          return req.url.path.endsWith('previsao.xml')
              ? fixtureResponse('previsao_4963.xml')
              : latin1Response('<cidades></cidades>');
        }),
      );

      await api.buscarCidades("  São José d'Ouro ");
      await api.buscarPrevisao(4963);

      expect(urls[0].host, 'servicos.cptec.inpe.br');
      expect(urls[0].path, '/XML/listaCidades');
      expect(urls[0].queryParameters['city'], 'Sao Jose dOuro');
      expect(
        urls[1].toString(),
        'https://servicos.cptec.inpe.br/XML/cidade/4963/previsao.xml',
      );
    });

    test('busca vazia não faz requisição', () async {
      var chamadas = 0;
      final api = CptecApiService(
        client: MockClient((_) async {
          chamadas++;
          return latin1Response('<cidades></cidades>');
        }),
      );
      expect(await api.buscarCidades('   '), isEmpty);
      expect(chamadas, 0);
    });

    test('falha de rede vira CptecException.semConexao', () async {
      final api = CptecApiService(
        client: MockClient(
          (_) async => throw http.ClientException('Failed host lookup'),
        ),
      );
      await expectLater(
        api.buscarPrevisao(1),
        throwsA(
          isA<CptecException>()
              .having((e) => e.type, 'type', CptecErrorType.semConexao)
              .having((e) => e.isConnectivity, 'isConnectivity', isTrue),
        ),
      );
    });

    test('SocketException vira semConexao', () async {
      final api = CptecApiService(
        client: MockClient((_) async => throw const SocketException('offline')),
      );
      await expectLater(
        api.buscarCidades('rio'),
        throwsA(
          isA<CptecException>().having(
            (e) => e.type,
            'type',
            CptecErrorType.semConexao,
          ),
        ),
      );
    });

    test('timeout vira CptecException.timeout', () async {
      final api = CptecApiService(
        timeout: const Duration(milliseconds: 20),
        client: MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          return latin1Response('<cidades></cidades>');
        }),
      );
      await expectLater(
        api.buscarCidades('rio'),
        throwsA(
          isA<CptecException>().having(
            (e) => e.type,
            'type',
            CptecErrorType.timeout,
          ),
        ),
      );
    });

    test('HTTP de erro vira CptecException.servidor', () async {
      for (final status in [500, 429]) {
        final api = CptecApiService(
          client: MockClient(
            (_) async => latin1Response('erro', status: status),
          ),
        );
        await expectLater(
          api.buscarCidades('rio'),
          throwsA(
            isA<CptecException>().having(
              (e) => e.type,
              'type',
              CptecErrorType.servidor,
            ),
          ),
        );
      }
    });

    test('respeita charset UTF-8 se o servidor declarar', () {
      final resposta = http.Response.bytes(
        utf8.encode('<a>São</a>'),
        200,
        headers: {'content-type': 'text/xml; charset=UTF-8'},
      );
      expect(CptecApiService.decodeBody(resposta), '<a>São</a>');
    });

    test('sem charset declarado, assume ISO-8859-1', () {
      final resposta = http.Response.bytes([0x53, 0xE3, 0x6F], 200);
      expect(CptecApiService.decodeBody(resposta), 'São');
    });
  });
}
