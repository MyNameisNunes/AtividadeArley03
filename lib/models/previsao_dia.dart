import 'package:flutter/foundation.dart';

import '../utils/uv_index.dart';

/// Previsão de um dia (`<previsao>` dentro do XML de previsão).
///
/// Todos os indicadores são anuláveis: o CPTEC pode devolver tags vazias ou
/// com o texto literal "null", e isso não deve quebrar a interface.
@immutable
class PrevisaoDia {
  const PrevisaoDia({
    required this.dia,
    this.tempo,
    this.maxima,
    this.minima,
    this.iuv,
  });

  final DateTime dia;

  /// Sigla da condição (ex.: "pn"). Veja `WeatherConditionHelper`.
  final String? tempo;
  final int? maxima;
  final int? minima;
  final double? iuv;

  bool get temIuv => UvIndexHelper.isAvailable(iuv);

  factory PrevisaoDia.fromJson(Map<String, dynamic> json) {
    return PrevisaoDia(
      dia: DateTime.parse(json['dia'] as String),
      tempo: json['tempo'] as String?,
      maxima: (json['maxima'] as num?)?.toInt(),
      minima: (json['minima'] as num?)?.toInt(),
      iuv: (json['iuv'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'dia': dia.toIso8601String(),
    'tempo': tempo,
    'maxima': maxima,
    'minima': minima,
    'iuv': iuv,
  };
}
