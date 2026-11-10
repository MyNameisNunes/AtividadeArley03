import 'package:flutter/material.dart';

import '../../models/previsao_dia.dart';
import '../../utils/date_formatter.dart';
import '../../utils/weather_codes.dart';
import 'temperature_colors.dart';
import 'uv_index_chip.dart';

/// Card de um dia da previsão.
class WeatherDayCard extends StatelessWidget {
  const WeatherDayCard({super.key, required this.dia, this.agora});

  final PrevisaoDia dia;

  /// Referência para "Hoje"/"Amanhã" (injetável nos testes).
  final DateTime? agora;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final condicao = WeatherConditionHelper.fromCode(dia.tempo);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: condicao.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                condicao.icon,
                color: condicao.color,
                size: 32,
                semanticLabel: condicao.description,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormatter.relativeDay(dia.dia, agora: agora),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${DateFormatter.weekdayShort(dia.dia)}, '
                    '${DateFormatter.date(dia.dia)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(condicao.description, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  UvIndexChip(iuv: dia.iuv),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _Temperatura(
                  rotulo: 'Máx',
                  valor: dia.maxima,
                  icone: Icons.arrow_upward,
                  cor: TemperatureColors.maxima(context),
                ),
                const SizedBox(height: 8),
                _Temperatura(
                  rotulo: 'Mín',
                  valor: dia.minima,
                  icone: Icons.arrow_downward,
                  cor: TemperatureColors.minima(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Temperatura extends StatelessWidget {
  const _Temperatura({
    required this.rotulo,
    required this.valor,
    required this.icone,
    required this.cor,
  });

  final String rotulo;
  final int? valor;
  final IconData icone;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final texto = valor == null ? '--' : '$valor °C';
    return Semantics(
      label: valor == null
          ? '$rotulo não informada'
          : '${rotulo == 'Máx' ? 'Máxima' : 'Mínima'} de $valor graus',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 16, color: cor),
          const SizedBox(width: 2),
          Text(
            texto,
            style: theme.textTheme.titleMedium?.copyWith(
              color: cor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
