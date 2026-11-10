import 'package:flutter/foundation.dart';

import 'previsao_dia.dart';

/// Previsão de 4 dias de uma cidade (`/cidade/{id}/previsao.xml`).
@immutable
class Previsao {
  const Previsao({
    required this.cidadeId,
    required this.nome,
    required this.uf,
    required this.dias,
    required this.obtidaEm,
    this.atualizacao,
  });

  /// O XML não traz o código da cidade; ele vem da requisição.
  final int cidadeId;
  final String nome;
  final String uf;

  /// Data de atualização informada pelo CPTEC (`<atualizacao>`).
  final DateTime? atualizacao;
  final List<PrevisaoDia> dias;

  /// Momento em que o app baixou estes dados (usado no modo offline).
  final DateTime obtidaEm;

  factory Previsao.fromJson(Map<String, dynamic> json) {
    final atualizacao = json['atualizacao'] as String?;
    return Previsao(
      cidadeId: json['cidadeId'] as int,
      nome: json['nome'] as String,
      uf: json['uf'] as String,
      atualizacao: atualizacao == null ? null : DateTime.parse(atualizacao),
      obtidaEm: DateTime.parse(json['obtidaEm'] as String),
      dias: (json['dias'] as List<dynamic>)
          .map((e) => PrevisaoDia.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
    'cidadeId': cidadeId,
    'nome': nome,
    'uf': uf,
    'atualizacao': atualizacao?.toIso8601String(),
    'obtidaEm': obtidaEm.toIso8601String(),
    'dias': dias.map((d) => d.toJson()).toList(),
  };
}
