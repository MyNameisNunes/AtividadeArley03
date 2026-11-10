import 'package:xml/xml.dart';

import '../models/cidade.dart';
import '../models/previsao.dart';
import '../models/previsao_dia.dart';
import '../utils/date_formatter.dart';
import 'cptec_exception.dart';

/// Converte os XMLs do CPTEC (já decodificados para String) em modelos.
///
/// O parser é tolerante: tags ausentes, vazias ou com o texto "null" viram
/// `null` no modelo em vez de lançar exceção.
class CptecXmlParser {
  const CptecXmlParser();

  /// `<cidades><cidade><nome/><uf/><id/></cidade>...</cidades>`
  List<Cidade> parseCidades(String xml) {
    final raiz = _parse(xml);
    if (raiz.name.local != 'cidades') {
      throw CptecException.dadosInvalidos('raiz <${raiz.name.local}>');
    }

    final cidades = <Cidade>[];
    for (final el in raiz.findElements('cidade')) {
      final id = _int(_text(el, const ['id']));
      final nome = _text(el, const ['nome']);
      final uf = _text(el, const ['uf']);
      if (id == null || nome == null) continue; // registro incompleto
      cidades.add(Cidade(id: id, nome: nome, uf: uf ?? '--'));
    }
    return cidades;
  }

  /// `<cidade><nome/><uf/><atualizacao/><previsao>...</previsao></cidade>`
  ///
  /// A documentação usa `<max>`/`<min>`, mas o serviço atual responde com
  /// `<maxima>`/`<minima>`; ambos os formatos são aceitos.
  Previsao parsePrevisao(
    String xml, {
    required int cidadeId,
    DateTime? obtidaEm,
  }) {
    final raiz = _parse(xml);
    if (raiz.name.local != 'cidade') {
      throw CptecException.dadosInvalidos('raiz <${raiz.name.local}>');
    }

    final nome = _text(raiz, const ['nome']);
    final dias = <PrevisaoDia>[];
    for (final el in raiz.findElements('previsao')) {
      final dia = DateFormatter.parseApiDate(_text(el, const ['dia']));
      if (dia == null) continue; // sem data não há como posicionar o dia
      dias.add(
        PrevisaoDia(
          dia: dia,
          tempo: _text(el, const ['tempo']),
          maxima: _int(_text(el, const ['maxima', 'max'])),
          minima: _int(_text(el, const ['minima', 'min'])),
          iuv: _double(_text(el, const ['iuv'])),
        ),
      );
    }

    // Para códigos inexistentes o CPTEC responde 200 com tudo "null".
    if (nome == null && dias.isEmpty) {
      throw const CptecException(
        CptecErrorType.naoEncontrado,
        'Não há previsão disponível para esta localidade.',
      );
    }

    dias.sort((a, b) => a.dia.compareTo(b.dia));

    return Previsao(
      cidadeId: cidadeId,
      nome: nome ?? 'Localidade $cidadeId',
      uf: _text(raiz, const ['uf']) ?? '--',
      atualizacao: DateFormatter.parseApiDate(
        _text(raiz, const ['atualizacao']),
      ),
      dias: List.unmodifiable(dias),
      obtidaEm: obtidaEm ?? DateTime.now(),
    );
  }

  XmlElement _parse(String xml) {
    try {
      return XmlDocument.parse(xml).rootElement;
    } on XmlException catch (e) {
      throw CptecException.dadosInvalidos(e);
    } on StateError catch (e) {
      // Documento sem elemento raiz.
      throw CptecException.dadosInvalidos(e);
    }
  }

  /// Primeiro texto não vazio entre as tags candidatas.
  static String? _text(XmlElement parent, List<String> tags) {
    for (final tag in tags) {
      final el = parent.getElement(tag);
      if (el == null) continue;
      final texto = el.innerText.trim();
      if (texto.isEmpty || texto.toLowerCase() == 'null') continue;
      return texto;
    }
    return null;
  }

  static int? _int(String? valor) {
    if (valor == null) return null;
    return int.tryParse(valor) ?? _double(valor)?.round();
  }

  static double? _double(String? valor) {
    if (valor == null) return null;
    final numero = double.tryParse(valor.replaceAll(',', '.'));
    if (numero == null || numero.isNaN || numero.isInfinite) return null;
    return numero;
  }
}
