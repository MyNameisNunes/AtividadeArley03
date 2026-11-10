import 'package:flutter/material.dart';

import '../../models/previsao.dart';
import '../../utils/constants.dart';
import '../../utils/date_formatter.dart';

/// Cabeçalho da previsão: cidade, UF, data de atualização e fonte.
class ForecastHeader extends StatelessWidget {
  const ForecastHeader({super.key, required this.previsao});

  final Previsao previsao;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final atualizacao = previsao.atualizacao;

    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, color: scheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    previsao.nome,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    previsao.uf,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _Info(
              icone: Icons.update,
              texto: atualizacao == null
                  ? 'Data de atualização não informada'
                  : 'Atualizado pelo CPTEC em ${DateFormatter.date(atualizacao)}',
            ),
            const SizedBox(height: 4),
            _Info(
              icone: Icons.download_done,
              texto:
                  'Consultado em ${DateFormatter.dateTime(previsao.obtidaEm)}',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.satellite_alt, size: 16, color: scheme.primary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      AppConstants.fonteDados,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cor = theme.colorScheme.onPrimaryContainer;
    return Row(
      children: [
        Icon(icone, size: 16, color: cor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            style: theme.textTheme.bodyMedium?.copyWith(color: cor),
          ),
        ),
      ],
    );
  }
}
