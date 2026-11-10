/// Normalização de texto usada antes de montar a URL de busca do CPTEC.
class TextNormalizer {
  TextNormalizer._();

  static const String _comAcento =
      'ÀÁÂÃÄÅàáâãäåÈÉÊËèéêëÌÍÎÏìíîïÒÓÔÕÖòóôõöÙÚÛÜùúûüÇçÑñÝýÿ';
  static const String _semAcento =
      'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuCcNnYyy';

  static final Map<String, String> _mapa = {
    for (var i = 0; i < _comAcento.length; i++) _comAcento[i]: _semAcento[i],
  };

  /// Remove acentos e cedilha: "São João" -> "Sao Joao".
  static String removeDiacritics(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_mapa[char] ?? char);
    }
    return buffer.toString();
  }

  /// Prepara o termo digitado para a API de busca:
  /// - remove acentos (o servidor trabalha em ISO-8859-1);
  /// - remove apóstrofos (o CPTEC grava "Olho dÁgua", sem apóstrofo);
  /// - colapsa espaços repetidos e apara as bordas.
  static String normalizeQuery(String input) {
    return removeDiacritics(input)
        .replaceAll(RegExp(r"['’`´]"), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
