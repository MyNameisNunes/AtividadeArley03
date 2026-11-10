import 'package:flutter/material.dart';

/// Cores de temperatura usadas nos cards e no gráfico, com contraste
/// adequado em tema claro e escuro.
class TemperatureColors {
  TemperatureColors._();

  static bool _escuro(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color maxima(BuildContext context) =>
      _escuro(context) ? const Color(0xFFFF8A65) : const Color(0xFFBF360C);

  static Color minima(BuildContext context) =>
      _escuro(context) ? const Color(0xFF64B5F6) : const Color(0xFF1565C0);
}
