import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/weather_controller.dart';
import '../../models/cidade.dart';
import '../../models/previsao.dart';
import '../../services/cptec_api_service.dart';
import '../../services/database_service.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/forecast_header.dart';
import '../widgets/stale_data_banner.dart';
import '../widgets/temperature_chart.dart';
import '../widgets/weather_day_card.dart';

/// Previsão de 4 dias de uma cidade.
class ForecastPage extends StatelessWidget {
  const ForecastPage({super.key, required this.cidade});

  final Cidade cidade;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => WeatherController(
        cidade: cidade,
        api: ctx.read<CptecApiService>(),
        database: ctx.read<DatabaseService>(),
      )..carregar(),
      child: const _ForecastView(),
    );
  }
}

class _ForecastView extends StatelessWidget {
  const _ForecastView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WeatherController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(controller.cidade.nomeComUf),
        actions: [
          IconButton(
            tooltip: controller.favorita
                ? 'Remover das favoritas'
                : 'Adicionar às favoritas',
            icon: Icon(
              controller.favorita ? Icons.star : Icons.star_border,
              color: controller.favorita ? Colors.amber.shade700 : null,
            ),
            onPressed: () => _alternarFavorita(context, controller),
          ),
          IconButton(
            tooltip: 'Atualizar',
            onPressed: controller.atualizando ? null : controller.carregar,
            icon: controller.atualizando
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.carregar,
        child: LayoutBuilder(
          builder: (context, constraints) =>
              _corpo(context, controller, constraints),
        ),
      ),
    );
  }

  Future<void> _alternarFavorita(
    BuildContext context,
    WeatherController controller,
  ) async {
    await controller.alternarFavorita();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            controller.favorita
                ? '${controller.cidade.nome} adicionada às favoritas'
                : '${controller.cidade.nome} removida das favoritas',
          ),
        ),
      );
  }

  Widget _corpo(
    BuildContext context,
    WeatherController controller,
    BoxConstraints constraints,
  ) {
    final previsao = controller.previsao;

    // Estados sem dados: ListView para permitir o pull-to-refresh.
    if (previsao == null) {
      final Widget conteudo = controller.status == WeatherStatus.error
          ? ErrorStateWidget(
              title: 'Não foi possível carregar a previsão',
              message: controller.erro ?? 'Erro desconhecido.',
              onRetry: controller.carregar,
            )
          : const Center(child: CircularProgressIndicator());
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: conteudo,
          ),
        ],
      );
    }

    // Centraliza o conteúdo em telas largas (tablet/desktop).
    final lateral = math.max(16.0, (constraints.maxWidth - 720) / 2);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(lateral, 8, lateral, 24),
      children: [
        ForecastHeader(previsao: previsao),
        if (controller.aviso != null)
          StaleDataBanner(
            mensagem: controller.aviso!,
            obtidaEm: previsao.obtidaEm,
            carregando: controller.atualizando,
            onRetry: controller.carregar,
          )
        else if (controller.exibindoCache && controller.atualizando)
          const _AtualizandoCache(),
        ..._conteudoPrevisao(context, previsao),
      ],
    );
  }

  List<Widget> _conteudoPrevisao(BuildContext context, Previsao previsao) {
    if (previsao.dias.isEmpty) {
      return const [
        EmptyStateWidget(
          icon: Icons.event_busy,
          title: 'Sem previsão',
          message: 'O CPTEC não retornou dias de previsão para esta cidade.',
        ),
      ];
    }
    return [
      const _TituloSecao('Temperaturas'),
      Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
          child: TemperatureChart(dias: previsao.dias),
        ),
      ),
      _TituloSecao('Previsão para ${previsao.dias.length} dias'),
      for (final dia in previsao.dias) WeatherDayCard(dia: dia),
    ];
  }
}

class _AtualizandoCache extends StatelessWidget {
  const _AtualizandoCache();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LinearProgressIndicator(),
          const SizedBox(height: 6),
          Text(
            'Exibindo dados salvos enquanto buscamos a previsão atualizada…',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TituloSecao extends StatelessWidget {
  const _TituloSecao(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 4),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
