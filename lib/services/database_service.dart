import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/cidade.dart';
import '../models/previsao.dart';
import '../utils/constants.dart';

/// Persistência local (SQLite): cidades recentes/favoritas e cache das
/// previsões para uso offline.
///
/// Tabelas:
/// - `cidades`: id, nome, uf, favorita (0/1), ultimo_acesso (epoch ms)
/// - `previsoes_cache`: cidade_id, dados (JSON da Previsao), salvo_em
class DatabaseService {
  /// [factory] permite usar o sqflite FFI (desktop/testes);
  /// [path] permite banco em memória nos testes.
  /// Sem [factory], usa o sqflite nativo (resolvido só na abertura).
  DatabaseService({DatabaseFactory? factory, String? path})
    : _factory = factory,
      _path = path;

  final DatabaseFactory? _factory;
  final String? _path;
  Future<Database>? _database;

  Future<Database> get database => _database ??= _open();

  Future<Database> _open() async {
    final factory = _factory ?? databaseFactory;
    final caminho =
        _path ??
        p.join(await factory.getDatabasesPath(), AppConstants.databaseName);
    return factory.openDatabase(
      caminho,
      options: OpenDatabaseOptions(
        version: AppConstants.databaseVersion,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE cidades (
              id INTEGER PRIMARY KEY,
              nome TEXT NOT NULL,
              uf TEXT NOT NULL,
              favorita INTEGER NOT NULL DEFAULT 0,
              ultimo_acesso INTEGER
            )
          ''');
          await db.execute('''
            CREATE TABLE previsoes_cache (
              cidade_id INTEGER PRIMARY KEY,
              dados TEXT NOT NULL,
              salvo_em INTEGER NOT NULL
            )
          ''');
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Cidades
  // ---------------------------------------------------------------------------

  /// Marca a cidade como consultada agora (entra/sobe na lista de recentes).
  /// Preserva o status de favorita se a cidade já existir.
  Future<void> registrarAcesso(Cidade cidade, {DateTime? quando}) async {
    final db = await database;
    final agora = (quando ?? DateTime.now()).millisecondsSinceEpoch;
    await db.transaction((txn) async {
      // Update + insert em vez de UPSERT: o SQLite de Android < 11 não
      // suporta "ON CONFLICT DO UPDATE".
      final alteradas = await txn.update(
        'cidades',
        {'nome': cidade.nome, 'uf': cidade.uf, 'ultimo_acesso': agora},
        where: 'id = ?',
        whereArgs: [cidade.id],
      );
      if (alteradas == 0) {
        await txn.insert('cidades', {
          'id': cidade.id,
          'nome': cidade.nome,
          'uf': cidade.uf,
          'favorita': 0,
          'ultimo_acesso': agora,
        });
      }
      await _limitarRecentes(txn);
    });
  }

  Future<List<Cidade>> listarRecentes({
    int limite = AppConstants.maxRecentes,
  }) async {
    final db = await database;
    final linhas = await db.query(
      'cidades',
      where: 'ultimo_acesso IS NOT NULL',
      orderBy: 'ultimo_acesso DESC',
      limit: limite,
    );
    return linhas.map(Cidade.fromMap).toList();
  }

  Future<List<Cidade>> listarFavoritas() async {
    final db = await database;
    final linhas = await db.query(
      'cidades',
      where: 'favorita = 1',
      orderBy: 'nome COLLATE NOCASE',
    );
    return linhas.map(Cidade.fromMap).toList();
  }

  Future<bool> isFavorita(int cidadeId) async {
    final db = await database;
    final linhas = await db.query(
      'cidades',
      columns: ['favorita'],
      where: 'id = ?',
      whereArgs: [cidadeId],
    );
    return linhas.isNotEmpty && linhas.first['favorita'] == 1;
  }

  /// Define o status de favorita, criando o registro se necessário.
  Future<void> definirFavorita(Cidade cidade, bool favorita) async {
    final db = await database;
    await db.transaction((txn) async {
      final alteradas = await txn.update(
        'cidades',
        {'favorita': favorita ? 1 : 0},
        where: 'id = ?',
        whereArgs: [cidade.id],
      );
      if (alteradas == 0 && favorita) {
        await txn.insert('cidades', {
          'id': cidade.id,
          'nome': cidade.nome,
          'uf': cidade.uf,
          'favorita': 1,
          'ultimo_acesso': null,
        });
      }
      await _removerOrfaos(txn);
    });
  }

  /// Remove a cidade do histórico (continua salva se for favorita).
  Future<void> removerRecente(int cidadeId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'cidades',
        {'ultimo_acesso': null},
        where: 'id = ?',
        whereArgs: [cidadeId],
      );
      await _removerOrfaos(txn);
    });
  }

  Future<void> _limitarRecentes(Transaction txn) async {
    await txn.rawUpdate(
      '''
      UPDATE cidades SET ultimo_acesso = NULL
      WHERE ultimo_acesso IS NOT NULL AND id NOT IN (
        SELECT id FROM cidades WHERE ultimo_acesso IS NOT NULL
        ORDER BY ultimo_acesso DESC LIMIT ?
      )
      ''',
      [AppConstants.maxRecentes],
    );
    await _removerOrfaos(txn);
  }

  /// Apaga cidades que não são nem recentes nem favoritas, e o cache delas.
  Future<void> _removerOrfaos(Transaction txn) async {
    await txn.delete(
      'cidades',
      where: 'favorita = 0 AND ultimo_acesso IS NULL',
    );
    await txn.rawDelete(
      'DELETE FROM previsoes_cache WHERE cidade_id NOT IN (SELECT id FROM cidades)',
    );
  }

  // ---------------------------------------------------------------------------
  // Cache de previsões
  // ---------------------------------------------------------------------------

  Future<void> salvarPrevisao(Previsao previsao) async {
    final db = await database;
    await db.insert('previsoes_cache', {
      'cidade_id': previsao.cidadeId,
      'dados': jsonEncode(previsao.toJson()),
      'salvo_em': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Última previsão salva para a cidade, ou null. Um registro corrompido é
  /// descartado em vez de propagar erro.
  Future<Previsao?> obterPrevisaoSalva(int cidadeId) async {
    final db = await database;
    final linhas = await db.query(
      'previsoes_cache',
      where: 'cidade_id = ?',
      whereArgs: [cidadeId],
    );
    if (linhas.isEmpty) return null;
    try {
      final json = jsonDecode(linhas.first['dados'] as String);
      return Previsao.fromJson(json as Map<String, dynamic>);
    } catch (_) {
      await db.delete(
        'previsoes_cache',
        where: 'cidade_id = ?',
        whereArgs: [cidadeId],
      );
      return null;
    }
  }

  Future<void> close() async {
    final pendente = _database;
    _database = null;
    if (pendente != null) await (await pendente).close();
  }
}
