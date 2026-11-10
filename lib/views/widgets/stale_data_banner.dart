import 'package:flutter/material.dart';

import '../../utils/date_formatter.dart';

/// Aviso exibido quando a atualização falhou e a tela mostra dados salvos.
class StaleDataBanner extends StatelessWidget {
  const StaleDataBanner({
    super.key,
    required this.mensagem,
    required this.obtidaEm,
    required this.onRetry,
    this.carregando = false,
  });

  final String mensagem;
  final DateTime obtidaEm;
  final VoidCallback onRetry;
  final bool carregando;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.cloud_off, color: scheme.onErrorContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mensagem,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Exibindo dados salvos em '
                        '${DateFormatter.dateTime(obtidaEm)}.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: carregando ? null : onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: scheme.onErrorContainer,
                ),
                icon: carregando
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
