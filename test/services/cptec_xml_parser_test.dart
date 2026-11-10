import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:previsao_tempo_cptec/services/cptec_exception.dart';
import 'package:previsao_tempo_cptec/services/cptec_xml_parser.dart';

import '../support/fakes.dart';

void main() {
  const parser = CptecXmlParser();

  group('parseCidades', () {
    test('lê o fixture real (latin1) com acentuação correta', () {
      final xml = latin1.decode(fixtureBytes('lista_cidades_sjc.xml'));
      final cidades = parser.parseCidades(xml);

      expect(cidades, hasLength(1));
      expect(cidades.single.nome, 'São José dos Campos');
      expect(cidades.single.uf, 'SP');
      expect(cidades.single.id, 4963);
    });

    test('lista vazia quando nada é encontrado', () {
      const xml =
          "<?xml version='1.0' encoding='ISO-8859-1'?><cidades></cidades>";
      expect(parser.parseCidades(xml), isEmpty);
    });

    test('ignora registros sem id ou nome', () {
      const xml =
          '<cidades>'
          '<cidade><nome>Válida</nome><uf>MG</uf><id>1</id></cidade>'
          '<cidade><nome>Sem id</nome><uf>MG</uf><id></id></cidade>'
          '<cidade><nome>null</nome><uf>MG</uf><id>3</id></cidade>'
          '</cidades>';
      final cidades = parser.parseCidades(xml);
      expect(cidades.map((c) => c.id), [1]);
    });

    test('XML malformado gera erro tipado', () {
      expect(
        () => parser.parseCidades('<cidades><cidade>'),
        throwsA(
          isA<CptecException>().having(
            (e) => e.type,
            'type',
            CptecErrorType.dadosInvalidos,
          ),
        ),
      );
      expect(
        () => parser.parseCidades('<html>erro</html>'),
        throwsA(isA<CptecException>()),
      );
    });
  });

  group('parsePrevisao', () {
    test('lê o fixture real com as tags <maxima>/<minima>', () {
      final xml = latin1.decode(fixtureBytes('previsao_4963.xml'));
      final previsao = parser.parsePrevisao(xml, cidadeId: 4963);

      expect(previsao.nome, 'São José dos Campos');
      expect(previsao.uf, 'SP');
      expect(previsao.atualizacao, isNotNull);
      expect(previsao.dias, hasLength(4));
      for (final dia in previsao.dias) {
        expect(dia.maxima, isNotNull);
        expect(dia.minima, isNotNull);
        expect(dia.tempo, isNotEmpty);
      }
    });

    test('aceita o formato documentado <max>/<min>', () {
      const xml =
          '<cidade><nome>São José dos Campos</nome><uf>SP</uf>'
          '<atualizacao>2026-11-10</atualizacao>'
          '<previsao><dia>2026-11-11</dia><tempo>c</tempo>'
          '<max>28</max><min>18</min><iuv>11.0</iuv></previsao>'
          '</cidade>';
      final dia = parser.parsePrevisao(xml, cidadeId: 1).dias.single;

      expect(dia.dia, DateTime(2026, 11, 11));
      expect(dia.tempo, 'c');
      expect(dia.maxima, 28);
      expect(dia.minima, 18);
      expect(dia.iuv, 11.0);
    });

    test('tags vazias, ausentes ou "null" viram null sem quebrar', () {
      const xml =
          '<cidade><nome>Teste</nome><uf>RJ</uf>'
          '<atualizacao></atualizacao>'
          '<previsao><dia>2026-11-11</dia><tempo></tempo>'
          '<maxima>null</maxima><minima>abc</minima><iuv/></previsao>'
          '<previsao><dia>2026-11-12</dia><tempo>pn</tempo>'
          '<maxima>30</maxima></previsao>'
          '</cidade>';
      final previsao = parser.parsePrevisao(xml, cidadeId: 1);

      expect(previsao.atualizacao, isNull);
      expect(previsao.dias, hasLength(2));
      final primeiro = previsao.dias.first;
      expect(primeiro.tempo, isNull);
      expect(primeiro.maxima, isNull);
      expect(primeiro.minima, isNull);
      expect(primeiro.iuv, isNull);
      expect(primeiro.temIuv, isFalse);
      expect(previsao.dias.last.minima, isNull);
      expect(previsao.dias.last.iuv, isNull);
    });

    test('aceita decimais com vírgula e ordena os dias', () {
      const xml =
          '<cidade><nome>X</nome><uf>SP</uf>'
          '<previsao><dia>2026-11-12</dia><maxima>25.6</maxima><iuv>7,5</iuv></previsao>'
          '<previsao><dia>2026-11-11</dia><maxima>20</maxima></previsao>'
          '</cidade>';
      final dias = parser.parsePrevisao(xml, cidadeId: 1).dias;

      expect(dias.first.dia, DateTime(2026, 11, 11));
      expect(dias.last.maxima, 26);
      expect(dias.last.iuv, 7.5);
    });

    test(
      'código inexistente (CPTEC devolve tudo "null") gera naoEncontrado',
      () {
        const xml =
            '<cidade><nome>null</nome><uf>null</uf>'
            '<atualizacao>null</atualizacao>'
            '<previsao><dia>null</dia><tempo>null</tempo><maxima>null</maxima>'
            '<minima>null</minima><iuv>0.0</iuv></previsao></cidade>';
        expect(
          () => parser.parsePrevisao(xml, cidadeId: 999999),
          throwsA(
            isA<CptecException>().having(
              (e) => e.type,
              'type',
              CptecErrorType.naoEncontrado,
            ),
          ),
        );
      },
    );
  });
}
