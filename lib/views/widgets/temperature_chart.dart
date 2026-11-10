import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/previsao_dia.dart';
import '../../utils/date_formatter.dart';
import 'temperature_colors.dart';

/// Gráfico de linhas com as temperaturas máximas e mínimas dos dias.
///
/// Valores ausentes viram `FlSpot.nullSpot` (a linha é interrompida no dia
/// sem dado, em vez de quebrar o gráfico).
class TemperatureChart extends StatelessWidget {
  const TemperatureChart({super.key, required this.dias, this.height = 240});

  final List<PrevisaoDia> dias;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final corMax = TemperatureColors.maxima(context);
    final corMin = TemperatureColors.minima(context);

    final valores = <int>[
      for (final d in dias) ...[
        if (d.maxima != null) d.maxima!,
        if (d.minima != null) d.minima!,
      ],
    ];

    if (dias.isEmpty || valores.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'Sem dados de temperatura para exibir no gráfico.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final escala = _Escala.calcular(valores);

    return Column(
      children: [
        SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.only(right: 16, top: 16),
            child: LineChart(
              LineChartData(
                // Folga horizontal para os pontos das pontas não cortarem.
                minX: -0.25,
                maxX: dias.length - 1 + 0.25,
                minY: escala.min,
                maxY: escala.max,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: escala.intervalo,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: theme.colorScheme.outlineVariant,
                    strokeWidth: 1,
                    dashArray: const [4, 4],
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: theme.colorScheme.outline),
                    left: BorderSide(color: theme.colorScheme.outline),
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    axisNameWidget: Text(
                      'Temperatura (°C)',
                      style: theme.textTheme.labelSmall,
                    ),
                    axisNameSize: 20,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: escala.intervalo,
                      getTitlesWidget: (valor, meta) {
                        // Esconde rótulos fora da grade (bordas do eixo).
                        if (valor % escala.intervalo != 0) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            '${valor.toInt()}°',
                            style: theme.textTheme.labelSmall,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 1,
                      getTitlesWidget: (valor, meta) {
                        final indice = valor.round();
                        if (valor != indice.toDouble() ||
                            indice < 0 ||
                            indice >= dias.length) {
                          return const SizedBox.shrink();
                        }
                        final data = dias[indice].dia;
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            '${DateFormatter.weekdayShort(data)}\n'
                            '${DateFormatter.dayMonth(data)}',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItems: (spots) => spots.map((spot) {
                      final ehMaxima = spot.barIndex == 0;
                      return LineTooltipItem(
                        '${ehMaxima ? 'Máx' : 'Mín'}: ${spot.y.toInt()} °C',
                        TextStyle(
                          color: theme.colorScheme.onInverseSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  _linha([
                    for (var i = 0; i < dias.length; i++)
                      _ponto(i, dias[i].maxima),
                  ], corMax),
                  _linha([
                    for (var i = 0; i < dias.length; i++)
                      _ponto(i, dias[i].minima),
                  ], corMin),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 24,
          children: [
            _Legenda(cor: corMax, texto: 'Máxima'),
            _Legenda(cor: corMin, texto: 'Mínima'),
          ],
        ),
      ],
    );
  }

  static FlSpot _ponto(int indice, int? valor) => valor == null
      ? FlSpot.nullSpot
      : FlSpot(indice.toDouble(), valor.toDouble());

  static LineChartBarData _linha(List<FlSpot> pontos, Color cor) {
    return LineChartBarData(
      spots: pontos,
      color: cor,
      barWidth: 3,
      isCurved: true,
      preventCurveOverShooting: true,
      isStrokeCapRound: true,
      dotData: FlDotData(
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: 4.5,
          color: cor,
          strokeWidth: 2,
          strokeColor: Colors.white,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [cor.withValues(alpha: 0.22), cor.withValues(alpha: 0.0)],
        ),
      ),
    );
  }
}

/// Limites e intervalo "redondos" para o eixo Y.
class _Escala {
  const _Escala(this.min, this.max, this.intervalo);

  final double min;
  final double max;
  final double intervalo;

  factory _Escala.calcular(List<int> valores) {
    final menor = valores.reduce(math.min);
    final maior = valores.reduce(math.max);
    final amplitude = maior - menor;
    final intervalo = amplitude <= 8
        ? 2.0
        : amplitude <= 20
        ? 4.0
        : 5.0;
    final min = ((menor - intervalo) / intervalo).floor() * intervalo;
    final max = ((maior + intervalo) / intervalo).ceil() * intervalo;
    return _Escala(min, max, intervalo);
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda({required this.cor, required this.texto});

  final Color cor;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 4,
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(texto, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}
