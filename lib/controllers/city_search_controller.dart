import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/cidade.dart';
import '../services/cptec_api_service.dart';
import '../services/cptec_exception.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../utils/text_normalizer.dart';

enum SearchStatus { idle, loading, success, empty, error }

/// Estado da tela de pesquisa: resultados da API + cidades salvas.
///
/// (Nome com prefixo para não colidir com `SearchController` do Material.)
class CitySearchController extends ChangeNotifier {
  CitySearchController({
    required CptecApiService api,
    required DatabaseService database,
    Duration debounce = AppConstants.searchDebounce,
  }) : _api = api,
       _db = database,
       _debounceDuration = debounce;

  final CptecApiService _api;
  final DatabaseService _db;
  final Duration _debounceDuration;

  SearchStatus _status = SearchStatus.idle;
  List<Cidade> _resultados = const [];
  List<Cidade> _recentes = const [];
  List<Cidade> _favoritas = const [];
  String? _erro;
  String _termo = '';

  Timer? _debounce;

  /// Incrementado a cada busca; respostas antigas são descartadas para que
  /// uma requisição lenta não sobrescreva uma mais recente.
  int _requisicaoAtual = 0;
  bool _disposed = false;

  SearchStatus get status => _status;
  List<Cidade> get resultados => _resultados;
  List<Cidade> get recentes => _recentes;
  List<Cidade> get favoritas => _favoritas;
  String? get erro => _erro;
  String get termo => _termo;

  /// Recentes que não aparecem na seção de favoritas.
  List<Cidade> get recentesNaoFavoritas =>
      _recentes.where((c) => !isFavorita(c.id)).toList();

  bool isFavorita(int cidadeId) => _favoritas.any((c) => c.id == cidadeId);

  /// Chamado a cada tecla: aguarda o usuário parar de digitar.
  void onQueryChanged(String texto) {
    _debounce?.cancel();
    final termo = TextNormalizer.normalizeQuery(texto);
    if (termo.length < AppConstants.minSearchLength) {
      _cancelarBusca(termo);
      return;
    }
    _debounce = Timer(_debounceDuration, () => buscar(texto));
  }

  /// Busca imediata (botão, tecla Enter ou "Tentar novamente").
  Future<void> buscar(String texto) async {
    _debounce?.cancel();
    final termo = TextNormalizer.normalizeQuery(texto);
    if (termo.length < AppConstants.minSearchLength) {
      _cancelarBusca(termo);
      return;
    }

    final requisicao = ++_requisicaoAtual;
    _termo = termo;
    _status = SearchStatus.loading;
    _erro = null;
    _notify();

    try {
      final cidades = await _api.buscarCidades(termo);
      if (requisicao != _requisicaoAtual) return;
      _resultados = cidades;
      _status = cidades.isEmpty ? SearchStatus.empty : SearchStatus.success;
    } on CptecException catch (e) {
      if (requisicao != _requisicaoAtual) return;
      _resultados = const [];
      _erro = e.message;
      _status = SearchStatus.error;
    }
    _notify();
  }

  Future<void> tentarNovamente() => buscar(_termo);

  /// Volta para a lista de salvas (campo vazio/curto).
  void limpar() {
    _debounce?.cancel();
    _cancelarBusca('');
  }

  void _cancelarBusca(String termo) {
    _requisicaoAtual++;
    _termo = termo;
    _resultados = const [];
    _erro = null;
    if (_status != SearchStatus.idle) {
      _status = SearchStatus.idle;
      _notify();
    }
  }

  // ---------------------------------------------------------------------------
  // Persistência
  // ---------------------------------------------------------------------------

  Future<void> carregarSalvas() async {
    try {
      final resultados = await Future.wait([
        _db.listarRecentes(),
        _db.listarFavoritas(),
      ]);
      _recentes = resultados[0];
      _favoritas = resultados[1];
    } catch (e) {
      debugPrint('Falha ao carregar cidades salvas: $e');
    }
    _notify();
  }

  /// Registra a cidade como consultada (antes de abrir a previsão).
  Future<void> selecionarCidade(Cidade cidade) async {
    try {
      await _db.registrarAcesso(cidade);
    } catch (e) {
      debugPrint('Falha ao salvar cidade recente: $e');
    }
    await carregarSalvas();
  }

  Future<void> alternarFavorita(Cidade cidade) async {
    try {
      await _db.definirFavorita(cidade, !isFavorita(cidade.id));
    } catch (e) {
      debugPrint('Falha ao atualizar favorita: $e');
    }
    await carregarSalvas();
  }

  Future<void> removerRecente(Cidade cidade) async {
    try {
      await _db.removerRecente(cidade.id);
    } catch (e) {
      debugPrint('Falha ao remover recente: $e');
    }
    await carregarSalvas();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    super.dispose();
  }
}
