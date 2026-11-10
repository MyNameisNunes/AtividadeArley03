import 'package:flutter/foundation.dart';

/// Município retornado pela busca do CPTEC (`/listaCidades`).
@immutable
class Cidade {
  const Cidade({
    required this.id,
    required this.nome,
    required this.uf,
    this.favorita = false,
    this.ultimoAcesso,
  });

  /// Código da localidade no CPTEC, usado na URL da previsão.
  final int id;
  final String nome;
  final String uf;

  /// Campos de persistência local.
  final bool favorita;
  final DateTime? ultimoAcesso;

  String get nomeComUf => '$nome - $uf';

  Cidade copyWith({bool? favorita, DateTime? ultimoAcesso}) {
    return Cidade(
      id: id,
      nome: nome,
      uf: uf,
      favorita: favorita ?? this.favorita,
      ultimoAcesso: ultimoAcesso ?? this.ultimoAcesso,
    );
  }

  /// Linha da tabela `cidades` (SQLite).
  factory Cidade.fromMap(Map<String, Object?> map) {
    final acesso = map['ultimo_acesso'] as int?;
    return Cidade(
      id: map['id'] as int,
      nome: map['nome'] as String,
      uf: map['uf'] as String,
      favorita: (map['favorita'] as int? ?? 0) == 1,
      ultimoAcesso: acesso == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(acesso),
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'nome': nome,
    'uf': uf,
    'favorita': favorita ? 1 : 0,
    'ultimo_acesso': ultimoAcesso?.millisecondsSinceEpoch,
  };

  @override
  bool operator ==(Object other) => other is Cidade && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Cidade($id, $nomeComUf)';
}
