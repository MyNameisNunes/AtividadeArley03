enum CptecErrorType {
  semConexao,
  timeout,
  servidor,
  dadosInvalidos,
  naoEncontrado,
}

/// Erro de alto nível da integração com o CPTEC, com mensagem pronta para
/// ser exibida ao usuário.
class CptecException implements Exception {
  const CptecException(this.type, this.message, {this.cause});

  const CptecException.semConexao([Object? cause])
    : this(
        CptecErrorType.semConexao,
        'Sem conexão com a internet. Verifique sua rede e tente novamente.',
        cause: cause,
      );

  const CptecException.timeout([Object? cause])
    : this(
        CptecErrorType.timeout,
        'O servidor do CPTEC demorou demais para responder.',
        cause: cause,
      );

  const CptecException.dadosInvalidos([Object? cause])
    : this(
        CptecErrorType.dadosInvalidos,
        'O CPTEC retornou dados em um formato inesperado.',
        cause: cause,
      );

  final CptecErrorType type;
  final String message;
  final Object? cause;

  /// Falhas em que faz sentido recorrer ao cache local.
  bool get isConnectivity =>
      type == CptecErrorType.semConexao || type == CptecErrorType.timeout;

  @override
  String toString() =>
      'CptecException($type): $message'
      '${cause == null ? '' : ' | causa: $cause'}';
}
