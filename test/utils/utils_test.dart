import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:previsao_tempo_cptec/utils/date_formatter.dart';
import 'package:previsao_tempo_cptec/utils/text_normalizer.dart';
import 'package:previsao_tempo_cptec/utils/uv_index.dart';
import 'package:previsao_tempo_cptec/utils/weather_codes.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  group('TextNormalizer', () {
    test('remove acentos e cedilha', () {
      expect(
        TextNormalizer.removeDiacritics('São José dos Campos'),
        'Sao Jose dos Campos',
      );
      expect(
        TextNormalizer.removeDiacritics('Ijuí, Açailândia'),
        'Ijui, Acailandia',
      );
      expect(TextNormalizer.removeDiacritics('ÂNGELO ÔNIBUS'), 'ANGELO ONIBUS');
    });

    test('normalizeQuery remove apóstrofos e espaços extras', () {
      expect(TextNormalizer.normalizeQuery("  Olho d'Água  "), 'Olho dAgua');
      expect(TextNormalizer.normalizeQuery('Olho d’Água'), 'Olho dAgua');
      expect(TextNormalizer.normalizeQuery('são   paulo'), 'sao paulo');
    });
  });

  group('WeatherConditionHelper', () {
    test('mapeia as siglas exigidas pela especificação', () {
      const esperado = {
        'ci': 'Chuvas Isoladas',
        'c': 'Chuva',
        'pn': 'Parcialmente Nublado',
        'en': 'Encoberto',
        'ps': 'Predomínio de Sol',
        'e': 'Encoberto',
        'n': 'Nublado',
        'cl': 'Céu Claro',
        't': 'Tempestade',
        'cv': 'Chuvisco',
        'g': 'Geada',
        'cm': 'Chuva pela Manhã',
        'cn': 'Chuva a Noite',
        'pt': 'Pancadas de Chuva a Tarde',
      };
      esperado.forEach((sigla, descricao) {
        expect(
          WeatherConditionHelper.description(sigla),
          descricao,
          reason: sigla,
        );
      });
      expect(
        WeatherConditionHelper.description('ec'),
        startsWith('Encoberto com Chuvas'),
      );
    });

    test('ignora caixa e espaços', () {
      expect(
        WeatherConditionHelper.description(' PN '),
        'Parcialmente Nublado',
      );
    });

    test('retorna ícone do Material para cada sigla', () {
      expect(WeatherConditionHelper.icon('cl'), Icons.wb_sunny);
      expect(WeatherConditionHelper.icon('t'), Icons.thunderstorm);
    });

    test('fallback amigável para sigla desconhecida ou ausente', () {
      final desconhecida = WeatherConditionHelper.fromCode('zz');
      expect(desconhecida.description, 'Condição não identificada (zz)');
      expect(desconhecida.icon, Icons.help_outline);

      expect(
        WeatherConditionHelper.description(null),
        'Condição não informada',
      );
      expect(WeatherConditionHelper.description(''), 'Condição não informada');
      expect(
        WeatherConditionHelper.description('null'),
        'Condição não informada',
      );
    });
  });

  group('UvIndexHelper', () {
    test('classifica pelas faixas da OMS', () {
      expect(UvIndexHelper.classify(1.0), UvLevel.baixo);
      expect(UvIndexHelper.classify(2.4), UvLevel.baixo);
      expect(UvIndexHelper.classify(3.0), UvLevel.moderado);
      expect(UvIndexHelper.classify(5.0), UvLevel.moderado);
      expect(UvIndexHelper.classify(6.0), UvLevel.alto);
      expect(UvIndexHelper.classify(7.4), UvLevel.alto);
      expect(UvIndexHelper.classify(8.0), UvLevel.muitoAlto);
      expect(UvIndexHelper.classify(10.0), UvLevel.muitoAlto);
      expect(UvIndexHelper.classify(11.0), UvLevel.extremo);
      expect(UvIndexHelper.classify(14.0), UvLevel.extremo);
    });

    test('nulo, negativo e 0.0 (sem dado no CPTEC) são indisponíveis', () {
      expect(UvIndexHelper.classify(null), isNull);
      expect(UvIndexHelper.classify(-1), isNull);
      expect(UvIndexHelper.classify(0.0), isNull);
      expect(UvIndexHelper.isAvailable(0.0), isFalse);
    });
  });

  group('DateFormatter', () {
    final data = DateTime(2026, 11, 11); // quarta-feira

    test('converte data da API e rejeita valores inválidos', () {
      expect(DateFormatter.parseApiDate('2026-11-11'), data);
      expect(DateFormatter.parseApiDate(' 2026-11-11 '), data);
      expect(DateFormatter.parseApiDate('null'), isNull);
      expect(DateFormatter.parseApiDate(''), isNull);
      expect(DateFormatter.parseApiDate('ontem'), isNull);
      expect(DateFormatter.parseApiDate(null), isNull);
    });

    test('formata em pt_BR', () {
      expect(DateFormatter.date(data), '11/11/2026');
      expect(DateFormatter.dayMonth(data), '11/11');
      expect(DateFormatter.weekdayShort(data), 'Qua');
      expect(DateFormatter.weekdayLong(data), 'Quarta-feira');
      expect(
        DateFormatter.dateTime(DateTime(2026, 11, 10, 9, 5)),
        '10/11/2026 às 09:05',
      );
    });

    test('rótulos relativos', () {
      final agora = DateTime(2026, 11, 10, 22, 30);
      expect(
        DateFormatter.relativeDay(DateTime(2026, 11, 10), agora: agora),
        'Hoje',
      );
      expect(DateFormatter.relativeDay(data, agora: agora), 'Amanhã');
      expect(
        DateFormatter.relativeDay(DateTime(2026, 11, 12), agora: agora),
        'Quinta-feira',
      );
    });
  });
}
