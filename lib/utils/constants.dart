/// Constantes globais do aplicativo.
class AppConstants {
  AppConstants._();

  static const String appTitle = 'Previsão do Tempo';

  /// Base dos serviços XML do CPTEC/INPE.
  ///
  /// A documentação cita `http://`, mas o servidor responde `301` para
  /// `https://`. Usar HTTPS direto evita o redirecionamento e o bloqueio de
  /// tráfego em texto puro (cleartext) que o Android aplica por padrão.
  static const String cptecBaseUrl = 'https://servicos.cptec.inpe.br/XML';

  /// Texto de atribuição obrigatório.
  static const String fonteDados = 'Fonte de dados: CPTEC/INPE';

  static const Duration requestTimeout = Duration(seconds: 15);
  static const Duration searchDebounce = Duration(milliseconds: 600);

  /// Quantidade mínima de caracteres para disparar a busca de cidades.
  static const int minSearchLength = 3;

  /// Quantidade máxima de cidades mantidas no histórico de recentes.
  static const int maxRecentes = 10;

  static const String databaseName = 'previsao_cptec.db';
  static const int databaseVersion = 1;

  /// O CPTEC devolve `<iuv>0.0</iuv>` quando não há previsão de índice UV
  /// para a localidade (um IUV diário de 0 não ocorre no Brasil). Com esta
  /// flag ativa, valores <= 0 são exibidos como "não informado".
  static const bool tratarIuvZeroComoIndisponivel = true;
}
