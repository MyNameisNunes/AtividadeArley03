import 'package:flutter/material.dart';

import 'constants.dart';

/// Faixas do Índice Ultravioleta (escala da OMS, adotada pelo CPTEC/INPE).
enum UvLevel {
  baixo('Baixo', Color(0xFF2E7D32), Colors.white),
  moderado('Moderado', Color(0xFFF9A825), Colors.black),
  alto('Alto', Color(0xFFEF6C00), Colors.black),
  muitoAlto('Muito Alto', Color(0xFFC62828), Colors.white),
  extremo('Extremo', Color(0xFF6A1B9A), Colors.white);

  const UvLevel(this.label, this.color, this.foreground);

  final String label;
  final Color color;

  /// Cor de texto com contraste adequado sobre [color].
  final Color foreground;
}

class UvIndexHelper {
  UvIndexHelper._();

  /// Indica se o valor do IUV deve ser exibido.
  static bool isAvailable(double? iuv) {
    if (iuv == null || iuv.isNaN || iuv < 0) return false;
    if (AppConstants.tratarIuvZeroComoIndisponivel && iuv == 0) return false;
    return true;
  }

  /// Classifica o IUV: 0–2 Baixo, 3–5 Moderado, 6–7 Alto,
  /// 8–10 Muito Alto, 11+ Extremo. Retorna null quando indisponível.
  static UvLevel? classify(double? iuv) {
    if (!isAvailable(iuv)) return null;
    final valor = iuv!.round();
    if (valor <= 2) return UvLevel.baixo;
    if (valor <= 5) return UvLevel.moderado;
    if (valor <= 7) return UvLevel.alto;
    if (valor <= 10) return UvLevel.muitoAlto;
    return UvLevel.extremo;
  }
}
