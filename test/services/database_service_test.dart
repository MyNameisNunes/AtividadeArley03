import 'package:flutter_test/flutter_test.dart';
import 'package:previsao_tempo_cptec/models/cidade.dart';
import 'package:previsao_tempo_cptec/models/previsao.dart';
import 'package:previsao_tempo_cptec/models/previsao_dia.dart';
import 'package:previsao_tempo_cptec/services/database_service.dart';
import 'package:previsao_tempo_cptec/utils/constants.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseService db;

  setUpAll(sqfliteFfiInit);

  setUp(() {
    db = DatabaseService(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
  });

  tearDown(() => db.close());

  const sjc = Cidade(id: 4963, nome: 'São José dos Campos', uf: 'SP');
  const sp = Cidade(id: 244, nome: 'São Paulo', uf: 'SP');

  Previsao previsaoDe(Cidade c) => Previsao(
    cidadeId: c.id,
    nome: c.nome,
    uf: c.uf,
    atualizacao: DateTime(2026, 11, 10),
    obtidaEm: DateTime(2026, 11, 10, 9, 30),
    dias: [
      PrevisaoDia(
        dia: DateTime(2026, 11, 10),
        tempo: 'pn',
        maxima: 21,
        minima: 14,
        iuv: 9.5,
      ),
      PrevisaoDia(dia: DateTime(2026, 11, 11), tempo: 'c'),
    ],
  );

  test('recentes ficam ordenados do mais novo para o mais antigo', () async {
    await db.registrarAcesso(sjc, quando: DateTime(2026, 11, 10, 8));
    await db.registrarAcesso(sp, quando: DateTime(2026, 11, 10, 9));
    expect((await db.listarRecentes()).map((c) => c.id), [244, 4963]);

    // Consultar de novo move para o topo, sem duplicar.
    await db.registrarAcesso(sjc, quando: DateTime(2026, 11, 10, 10));
    final recentes = await db.listarRecentes();
    expect(recentes.map((c) => c.id), [4963, 244]);
    expect(recentes.first.nome, 'São José dos Campos');
  });

  test('histórico é limitado a ${AppConstants.maxRecentes} cidades', () async {
    final base = DateTime(2026, 1, 1);
    for (var i = 1; i <= AppConstants.maxRecentes + 3; i++) {
      await db.registrarAcesso(
        Cidade(id: i, nome: 'Cidade $i', uf: 'MG'),
        quando: base.add(Duration(minutes: i)),
      );
    }
    final recentes = await db.listarRecentes(limite: 100);
    expect(recentes, hasLength(AppConstants.maxRecentes));
    expect(recentes.first.id, AppConstants.maxRecentes + 3);
  });

  test('favorita é preservada ao registrar novo acesso', () async {
    await db.definirFavorita(sjc, true);
    expect(await db.isFavorita(sjc.id), isTrue);

    await db.registrarAcesso(sjc);
    expect(await db.isFavorita(sjc.id), isTrue);
    expect((await db.listarFavoritas()).single.nome, sjc.nome);

    await db.definirFavorita(sjc, false);
    expect(await db.isFavorita(sjc.id), isFalse);
    expect(await db.listarFavoritas(), isEmpty);
  });

  test('remover dos recentes mantém a cidade se for favorita', () async {
    await db.registrarAcesso(sjc);
    await db.registrarAcesso(sp);
    await db.definirFavorita(sjc, true);

    await db.removerRecente(sjc.id);
    await db.removerRecente(sp.id);

    expect(await db.listarRecentes(), isEmpty);
    expect((await db.listarFavoritas()).map((c) => c.id), [sjc.id]);
  });

  test('cache de previsão: salvar e ler de volta', () async {
    await db.registrarAcesso(sjc);
    await db.salvarPrevisao(previsaoDe(sjc));

    final lida = await db.obterPrevisaoSalva(sjc.id);
    expect(lida, isNotNull);
    expect(lida!.nome, 'São José dos Campos');
    expect(lida.atualizacao, DateTime(2026, 11, 10));
    expect(lida.obtidaEm, DateTime(2026, 11, 10, 9, 30));
    expect(lida.dias, hasLength(2));
    expect(lida.dias.first.iuv, 9.5);
    expect(lida.dias.last.maxima, isNull);
  });

  test('cache é apagado quando a cidade sai do histórico', () async {
    await db.registrarAcesso(sp);
    await db.salvarPrevisao(previsaoDe(sp));
    await db.removerRecente(sp.id);
    expect(await db.obterPrevisaoSalva(sp.id), isNull);
  });

  test('previsão inexistente retorna null', () async {
    expect(await db.obterPrevisaoSalva(123), isNull);
  });
}
