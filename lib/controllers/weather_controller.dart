import 'package:flutter/foundation.dart';

import '../models/cidade.dart';
import '../models/previsao.dart';
import '../services/cptec_api_service.dart';
import '../services/cptec_exception.dart';
import '../services/database_service.dart';

enum WeatherStatus { loading, success, error }

/// Estado da tela de previsão de uma cidade.
///
/// Estratégia de carregamento:
/// 1. Mostra imediatamente a última previsão salva (se houver);
/// 2. Busca a previsão atual na API e atualiza o cache;
/// 3. Se a rede falhar, mantém os dados salvos e exibe um aviso com a data
///    em que foram obtidos; sem cache, exibe o estado de erro.
class WeatherController extends ChangeNotifier {
  WeatherController({
    required this.cidade,
    required CptecApiService api,
    required DatabaseService database,
  }) : _api = api,
       _db = database;

  final Cidade cidade;
  final CptecApiService _api;
  final DatabaseService _db;

  WeatherStatus _status = WeatherStatus.loading;
  Previsao? _previsao;
  bool _exibindoCache = false;
  bool _atualizando = false;
  bool _favorita = false;
  String? _erro;
  String? _aviso;
  bool _cacheVerificado = false;
  bool _disposed = false;

  WeatherStatus get status => _status;
  Previsao? get previsao => _previsao;

  /// Os dados na tela vieram do armazenamento local, não da rede.
  bool get exibindoCache => _exibindoCache;

  /// Há uma requisição em andamento com dados já na tela.
  bool get atualizando => _atualizando;
  bool get favorita => _favorita;

  /// Mensagem do estado de erro (sem dados para mostrar).
  String? get erro => _erro;

  /// Mensagem do banner quando a atualização falhou mas há dados na tela.
  String? get aviso => _aviso;

  Future<void> carregar() async {
    if (_atualizando) return;

    if (!_cacheVerificado) {
      _cacheVerificado = true;
      await _carregarDadosLocais();
    }

    _atualizando = true;
    _erro = null;
    if (_previsao == null) _status = WeatherStatus.loading;
    _notify();

    try {
      final previsao = await _api.buscarPrevisao(cidade.id);
      _previsao = previsao;
      _exibindoCache = false;
      _aviso = null;
      _status = WeatherStatus.success;
      await _salvarCache(previsao);
    } on CptecException catch (e) {
      _falhou(e.message);
    } catch (e) {
      debugPrint('Erro inesperado ao carregar previsão: $e');
      _falhou('Não foi possível carregar a previsão.');
    } finally {
      _atualizando = false;
      _notify();
    }
  }

  Future<void> alternarFavorita() async {
    final novo = !_favorita;
    _favorita = novo;
    _notify();
    try {
      await _db.definirFavorita(cidade, novo);
    } catch (e) {
      debugPrint('Falha ao salvar favorita: $e');
      _favorita = !novo;
      _notify();
    }
  }

  void _falhou(String mensagem) {
    if (_previsao != null) {
      // Mantém o que está na tela (cache ou consulta anterior).
      _aviso = mensagem;
      _status = WeatherStatus.success;
    } else {
      _erro = mensagem;
      _status = WeatherStatus.error;
    }
  }

  Future<void> _carregarDadosLocais() async {
    try {
      _favorita = await _db.isFavorita(cidade.id);
      final salva = await _db.obterPrevisaoSalva(cidade.id);
      if (salva != null && salva.dias.isNotEmpty) {
        _previsao = salva;
        _exibindoCache = true;
        _status = WeatherStatus.success;
      }
    } catch (e) {
      debugPrint('Falha ao ler cache local: $e');
    }
  }

  Future<void> _salvarCache(Previsao previsao) async {
    try {
      await _db.salvarPrevisao(previsao);
    } catch (e) {
      debugPrint('Falha ao salvar cache: $e');
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
