import 'package:flutter/material.dart';

import '../../utils/uv_index.dart';

/// Selo do Índice Ultravioleta com a faixa de criticidade.
class UvIndexChip extends StatelessWidget {
  const UvIndexChip({super.key, required this.iuv});

  final double? iuv;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nivel = UvIndexHelper.classify(iuv);

    if (nivel == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wb_sunny_outlined,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'IUV não informado',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      );
    }

    final valor = iuv!.toStringAsFixed(1).replaceAll('.', ',');
    return Semantics(
      label: 'Índice ultravioleta $valor, ${nivel.label}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: nivel.color,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wb_sunny, size: 14, color: nivel.foreground),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'IUV $valor · ${nivel.label}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: nivel.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
