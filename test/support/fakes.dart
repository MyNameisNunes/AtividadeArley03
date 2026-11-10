import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:previsao_tempo_cptec/models/cidade.dart';
import 'package:previsao_tempo_cptec/models/previsao.dart';
import 'package:previsao_tempo_cptec/services/database_service.dart';

/// Lê um fixture como bytes brutos (ISO-8859-1, como o servidor envia).
List<int> fixtureBytes(String nome) =>
    File('test/fixtures/$nome').readAsBytesSync();

/// Resposta HTTP no formato do CPTEC: corpo em latin1 + charset no header.
http.Response latin1Response(String xml, {int status = 200}) {
  return http.Response.bytes(
    latin1.encode(xml),
    status,
    headers: {'content-type': 'text/xml;charset=ISO-8859-1'},
  );
}

http.Response fixtureResponse(String nome) => http.Response.bytes(
  fixtureBytes(nome),
  200,
  headers: {'content-type': 'text/xml;charset=ISO-8859-1'},
);

/// Banco em memória sem SQLite, para testes de widget (o sqflite real faz
/// I/O assíncrono que não avança dentro do FakeAsync do `testWidgets`).
class FakeDatabaseService extends DatabaseService {
  final Map<int, Cidade> cidades = {};
  final Map<int, Previsao> cache = {};

  @override
  Future<void> registrarAcesso(Cidade cidade, {DateTime? quando}) async {
    cidades[cidade.id] = Cidade(
      id: cidade.id,
      nome: cidade.nome,
      uf: cidade.uf,
      favorita: cidades[cidade.id]?.favorita ?? false,
      ultimoAcesso: quando ?? DateTime.now(),
    );
  }

  @override
  Future<List<Cidade>> listarRecentes({int limite = 10}) async {
    final lista = cidades.values.where((c) => c.ultimoAcesso != null).toList()
      ..sort((a, b) => b.ultimoAcesso!.compareTo(a.ultimoAcesso!));
    return lista.take(limite).toList();
  }

  @override
  Future<List<Cidade>> listarFavoritas() async =>
      cidades.values.where((c) => c.favorita).toList();

  @override
  Future<bool> isFavorita(int cidadeId) async =>
      cidades[cidadeId]?.favorita ?? false;

  @override
  Future<void> definirFavorita(Cidade cidade, bool favorita) async {
    final atual = cidades[cidade.id] ?? cidade;
    cidades[cidade.id] = atual.copyWith(favorita: favorita);
  }

  @override
  Future<void> removerRecente(int cidadeId) async {
    final atual = cidades[cidadeId];
    if (atual == null) return;
    if (atual.favorita) {
      cidades[cidadeId] = Cidade(
        id: atual.id,
        nome: atual.nome,
        uf: atual.uf,
        favorita: true,
      );
    } else {
      cidades.remove(cidadeId);
    }
  }

  @override
  Future<void> salvarPrevisao(Previsao previsao) async =>
      cache[previsao.cidadeId] = previsao;

  @override
  Future<Previsao?> obterPrevisaoSalva(int cidadeId) async => cache[cidadeId];

  @override
  Future<void> close() async {}
}
