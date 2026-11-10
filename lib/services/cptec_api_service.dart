import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/cidade.dart';
import '../models/previsao.dart';
import '../utils/constants.dart';
import '../utils/text_normalizer.dart';
import 'cptec_exception.dart';
import 'cptec_xml_parser.dart';

/// Cliente dos serviços XML do CPTEC/INPE.
class CptecApiService {
  CptecApiService({
    http.Client? client,
    this.parser = const CptecXmlParser(),
    this.baseUrl = AppConstants.cptecBaseUrl,
    this.timeout = AppConstants.requestTimeout,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final CptecXmlParser parser;
  final String baseUrl;
  final Duration timeout;

  /// GET /listaCidades?city={nome}
  ///
  /// O termo é normalizado (sem acentos/apóstrofos) antes do envio.
  Future<List<Cidade>> buscarCidades(String nome) async {
    final termo = TextNormalizer.normalizeQuery(nome);
    if (termo.isEmpty) return const [];

    final uri = Uri.parse('$baseUrl/listaCidades')
        .replace(queryParameters: {'city': termo});
    final xml = await _get(uri);
    return parser.parseCidades(xml);
  }

  /// GET /cidade/{id}/previsao.xml
  Future<Previsao> buscarPrevisao(int cidadeId) async {
    final uri = Uri.parse('$baseUrl/cidade/$cidadeId/previsao.xml');
    final xml = await _get(uri);
    return parser.parsePrevisao(xml, cidadeId: cidadeId);
  }

  Future<String> _get(Uri uri) async {
    final http.Response response;
    try {
      response = await _client.get(uri).timeout(timeout);
    } on TimeoutException catch (e) {
      throw CptecException.timeout(e);
    } on SocketException catch (e) {
      throw CptecException.semConexao(e);
    } on http.ClientException catch (e) {
      throw CptecException.semConexao(e);
    } on HandshakeException catch (e) {
      throw CptecException.semConexao(e);
    }

    if (response.statusCode == 429) {
      throw const CptecException(
        CptecErrorType.servidor,
        'Muitas consultas em pouco tempo. Aguarde um instante e tente de novo.',
      );
    }
    if (response.statusCode != 200) {
      throw CptecException(
        CptecErrorType.servidor,
        'O serviço do CPTEC está indisponível '
        '(HTTP ${response.statusCode}). Tente novamente mais tarde.',
      );
    }

    return decodeBody(response);
  }

  /// O CPTEC responde em ISO-8859-1 (`text/xml;charset=ISO-8859-1`).
  /// `response.body` pode decodificar errado acentos e cedilha, então os
  /// bytes brutos são convertidos com `latin1`. Se algum dia o servidor
  /// declarar UTF-8, isso também é respeitado.
  static String decodeBody(http.Response response) {
    final contentType = response.headers['content-type']?.toLowerCase() ?? '';
    if (contentType.contains('charset=utf-8')) {
      return utf8.decode(response.bodyBytes, allowMalformed: true);
    }
    return latin1.decode(response.bodyBytes);
  }

  void dispose() => _client.close();
}
