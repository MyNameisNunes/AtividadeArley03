import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/city_search_controller.dart';
import '../../models/cidade.dart';
import '../../services/cptec_api_service.dart';
import '../../services/database_service.dart';
import '../../utils/constants.dart';
import '../../utils/date_formatter.dart';
import '../forecast/forecast_page.dart';
import '../widgets/error_state_widget.dart';

/// Tela inicial: busca de municípios + cidades favoritas e recentes.
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => CitySearchController(
        api: ctx.read<CptecApiService>(),
        database: ctx.read<DatabaseService>(),
      )..carregarSalvas(),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final _texto = TextEditingController();
  final _foco = FocusNode();

  @override
  void dispose() {
    _texto.dispose();
    _foco.dispose();
    super.dispose();
  }

  Future<void> _abrirPrevisao(Cidade cidade) async {
    final controller = context.read<CitySearchController>();
    _foco.unfocus();
    await controller.selecionarCidade(cidade);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ForecastPage(cidade: cidade)),
    );
    // A favorita pode ter mudado na tela de previsão.
    await controller.carregarSalvas();
  }

  void _limpar() {
    _texto.clear();
    context.read<CitySearchController>().limpar();
    _foco.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CitySearchController>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: _CampoBusca(
                    controller: _texto,
                    focusNode: _foco,
                    onChanged: controller.onQueryChanged,
                    onSubmit: () => controller.buscar(_texto.text),
                    onClear: _limpar,
                  ),
                ),
                Expanded(child: _corpo(controller)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _corpo(CitySearchController controller) {
    switch (controller.status) {
      case SearchStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case SearchStatus.error:
        return ErrorStateWidget(
          title: 'Não foi possível buscar',
          message: controller.erro ?? 'Erro desconhecido.',
          onRetry: controller.tentarNovamente,
        );

      case SearchStatus.empty:
        return EmptyStateWidget(
          title: 'Nenhuma cidade encontrada',
          message:
              'Não encontramos municípios para “${controller.termo}”. '
              'Confira a grafia e tente novamente.',
        );

      case SearchStatus.success:
        return _ListaResultados(
          cidades: controller.resultados,
          isFavorita: controller.isFavorita,
          onTap: _abrirPrevisao,
          onFavoritar: controller.alternarFavorita,
        );

      case SearchStatus.idle:
        return _CidadesSalvas(
          controller: controller,
          onTap: _abrirPrevisao,
          termoCurto: controller.termo.isNotEmpty,
        );
    }
  }
}

class _CampoBusca extends StatelessWidget {
  const _CampoBusca({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmit,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, valor, _) => TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.search,
              textCapitalization: TextCapitalization.words,
              autocorrect: false,
              onChanged: onChanged,
              onSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                hintText: 'Nome do município',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: valor.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpar',
                        icon: const Icon(Icons.close),
                        onPressed: onClear,
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: onSubmit,
          style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
          child: const Text('Buscar'),
        ),
      ],
    );
  }
}

class _ListaResultados extends StatelessWidget {
  const _ListaResultados({
    required this.cidades,
    required this.isFavorita,
    required this.onTap,
    required this.onFavoritar,
  });

  final List<Cidade> cidades;
  final bool Function(int id) isFavorita;
  final ValueChanged<Cidade> onTap;
  final ValueChanged<Cidade> onFavoritar;

  @override
  Widget build(BuildContext context) {
    final total = cidades.length;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: total + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return _TituloSecao(
            icone: Icons.list,
            texto: total == 1
                ? '1 município encontrado'
                : '$total municípios encontrados',
          );
        }
        final cidade = cidades[i - 1];
        return _CidadeTile(
          cidade: cidade,
          favorita: isFavorita(cidade.id),
          onTap: () => onTap(cidade),
          onFavoritar: () => onFavoritar(cidade),
        );
      },
    );
  }
}

class _CidadesSalvas extends StatelessWidget {
  const _CidadesSalvas({
    required this.controller,
    required this.onTap,
    required this.termoCurto,
  });

  final CitySearchController controller;
  final ValueChanged<Cidade> onTap;
  final bool termoCurto;

  @override
  Widget build(BuildContext context) {
    final favoritas = controller.favoritas;
    final recentes = controller.recentesNaoFavoritas;
    final theme = Theme.of(context);

    final dica = termoCurto
        ? Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Digite ao menos ${AppConstants.minSearchLength} letras para buscar.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        : null;

    if (favoritas.isEmpty && recentes.isEmpty) {
      return Column(
        children: [
          if (dica != null) dica,
          const Expanded(
            child: EmptyStateWidget(
              icon: Icons.travel_explore,
              title: 'Pesquise um município',
              message:
                  'Digite o nome de uma cidade brasileira para ver a '
                  'previsão do tempo dos próximos 4 dias. As cidades '
                  'consultadas ficam salvas aqui, inclusive para uso offline.',
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        if (dica != null) dica,
        if (favoritas.isNotEmpty) ...[
          const _TituloSecao(icone: Icons.star, texto: 'Favoritas'),
          for (final cidade in favoritas)
            _CidadeTile(
              cidade: cidade,
              favorita: true,
              onTap: () => onTap(cidade),
              onFavoritar: () => controller.alternarFavorita(cidade),
            ),
        ],
        if (recentes.isNotEmpty) ...[
          const _TituloSecao(
            icone: Icons.history,
            texto: 'Consultadas recentemente',
          ),
          for (final cidade in recentes)
            Dismissible(
              key: ValueKey('recente-${cidade.id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                color: theme.colorScheme.errorContainer,
                child: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
              onDismissed: (_) {
                controller.removerRecente(cidade);
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text('${cidade.nome} removida do histórico'),
                    ),
                  );
              },
              child: _CidadeTile(
                cidade: cidade,
                favorita: false,
                subtitulo: cidade.ultimoAcesso == null
                    ? null
                    : 'Consultada em ${DateFormatter.dateTime(cidade.ultimoAcesso!)}',
                onTap: () => onTap(cidade),
                onFavoritar: () => controller.alternarFavorita(cidade),
              ),
            ),
        ],
      ],
    );
  }
}

class _CidadeTile extends StatelessWidget {
  const _CidadeTile({
    required this.cidade,
    required this.favorita,
    required this.onTap,
    required this.onFavoritar,
    this.subtitulo,
  });

  final Cidade cidade;
  final bool favorita;
  final String? subtitulo;
  final VoidCallback onTap;
  final VoidCallback onFavoritar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: scheme.secondaryContainer,
          foregroundColor: scheme.onSecondaryContainer,
          child: Text(
            cidade.uf,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
        title: Text(cidade.nome),
        subtitle: Text(subtitulo ?? 'UF: ${cidade.uf}'),
        trailing: IconButton(
          tooltip: favorita
              ? 'Remover das favoritas'
              : 'Adicionar às favoritas',
          icon: Icon(
            favorita ? Icons.star : Icons.star_border,
            color: favorita ? Colors.amber.shade700 : null,
          ),
          onPressed: onFavoritar,
        ),
      ),
    );
  }
}

class _TituloSecao extends StatelessWidget {
  const _TituloSecao({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4, left: 4),
      child: Row(
        children: [
          Icon(icone, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            texto,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
