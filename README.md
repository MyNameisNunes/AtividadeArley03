# Previsão do Tempo CPTEC/INPE

Aplicativo Flutter que pesquisa municípios brasileiros na API pública do
CPTEC/INPE, interpreta as respostas em XML (ISO-8859-1) e exibe a previsão de
4 dias com cards, gráfico de temperaturas e índice UV. Cidades consultadas,
favoritas e a última previsão de cada uma ficam salvas em SQLite para uso
offline.

> Fonte de dados: CPTEC/INPE

## Como executar

```bash
flutter pub get
flutter run                 # Android/iOS (emulador ou aparelho)
flutter run -d linux        # desktop Linux (SQLite via FFI, precisa de libsqlite3)
```

> Web não é suportado: o servidor do CPTEC não envia cabeçalhos CORS e o
> `sqflite` não roda no navegador.

### Testes

```bash
flutter test                                  # 54 testes de unidade e widget (offline)
flutter test integration_test -d linux        # E2E contra a API real (precisa de internet)
```

O E2E aceita `--dart-define=SCREENSHOT_DIR=/caminho` para salvar capturas de
cada etapa.

## Funcionalidades

| Requisito | Onde |
|---|---|
| Busca com debounce (600 ms) e botão, loading, lista e "nenhuma cidade" | `views/search/search_page.dart`, `controllers/city_search_controller.dart` |
| Favoritas e recentes (SQLite), deslizar para remover do histórico | `services/database_service.dart` |
| Cabeçalho: cidade, UF, data de atualização, "Fonte de dados: CPTEC/INPE" | `views/widgets/forecast_header.dart` |
| Pull-to-refresh e botão de atualizar na AppBar | `views/forecast/forecast_page.dart` |
| Cards dos 4 dias: data, ícone, condição, mín/máx, IUV com criticidade | `views/widgets/weather_day_card.dart`, `uv_index_chip.dart` |
| Gráfico de máximas (laranja) e mínimas (azul) com `fl_chart` | `views/widgets/temperature_chart.dart` |
| Erro de rede com "Tentar novamente" e fallback para o cache offline | `controllers/weather_controller.dart`, `views/widgets/stale_data_banner.dart` |
| Siglas de tempo para descrição e ícone, com fallback | `utils/weather_codes.dart` (`WeatherConditionHelper`) |

## Arquitetura

```text
lib/
├── main.dart                 # inicializa intl pt_BR e a factory do SQLite
├── app.dart                  # MaterialApp, tema claro/escuro, Provider dos serviços
├── models/                   # Cidade, Previsao, PrevisaoDia
├── services/
│   ├── cptec_api_service.dart    # HTTP + decode latin1 + mapeamento de erros
│   ├── cptec_xml_parser.dart     # XML → modelos (tolerante a tags vazias/"null")
│   ├── cptec_exception.dart      # erros tipados com mensagem para o usuário
│   └── database_service.dart     # sqflite: cidades + cache de previsões
├── controllers/              # ChangeNotifier (CitySearchController, WeatherController)
├── views/
│   ├── search/               # tela de pesquisa + favoritas/recentes
│   ├── forecast/             # tela da previsão
│   └── widgets/              # TemperatureChart, WeatherDayCard, ErrorStateWidget...
└── utils/                    # constantes, siglas, IUV, datas, normalização de texto
```

Gerência de estado: `provider` + `ChangeNotifier`. Os serviços são injetados
na raiz, o que permite substituí-los por fakes nos testes.

### Fluxo offline

1. Ao abrir uma cidade, a última previsão salva aparece na hora (se existir).
2. Em paralelo, a API é consultada. Em caso de sucesso, a tela e o cache são atualizados.
3. Se a rede falhar, os dados salvos continuam na tela com um aviso
   ("Exibindo dados salvos em …") e o botão "Tentar novamente". Sem cache, aparece
   a tela de erro.

## Particularidades da API do CPTEC (verificadas na API real)

- **HTTPS**: a URL `http://` documentada responde `301` para `https://`. O app usa
  HTTPS direto, o que também evita o bloqueio de cleartext do Android.
- **Codificação**: as respostas vêm em `ISO-8859-1`. O corpo é lido com
  `latin1.decode(response.bodyBytes)`.
- **Tags de temperatura**: o serviço atual usa `<maxima>`/`<minima>`, e a
  documentação usa `<max>`/`<min>`. O parser aceita as duas formas.
- **IUV**: hoje o CPTEC devolve `<iuv>0.0</iuv>` para todas as cidades, o que
  significa "sem dado" (IUV diário 0 não ocorre no Brasil). Valores ≤ 0 aparecem
  como "IUV não informado". Para mudar isso, altere
  `AppConstants.tratarIuvZeroComoIndisponivel`.
- **Código inexistente**: a API responde `200` com o texto `null` em todas as tags.
  O parser trata isso como "previsão indisponível".
- **Busca**: o termo é enviado sem acentos e sem apóstrofos. O CPTEC grava
  "Olho dÁgua", então `olho d'agua` só funciona como `olho dagua`.
- **Rate limit**: 150 requisições por janela. HTTP 429 gera uma mensagem específica.
