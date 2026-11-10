import 'package:flutter/material.dart';

/// Condição de tempo já interpretada a partir da sigla do CPTEC.
@immutable
class WeatherCondition {
  const WeatherCondition({
    required this.code,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String code;
  final String description;
  final IconData icon;
  final Color color;
}

/// Dicionário das siglas da tag `<tempo>` do CPTEC/INPE.
///
/// Inclui a tabela oficial de condições do CPTEC e as siglas citadas na
/// especificação do trabalho (ex.: `en`). Siglas desconhecidas recebem um
/// fallback amigável em vez de quebrar a interface.
class WeatherConditionHelper {
  WeatherConditionHelper._();

  // Paleta usada nos ícones.
  static const Color _sol = Color(0xFFF9A825);
  static const Color _solNuvem = Color(0xFFFFB300);
  static const Color _nuvem = Color(0xFF78909C);
  static const Color _encoberto = Color(0xFF546E7A);
  static const Color _chuva = Color(0xFF1E88E5);
  static const Color _chuvaFraca = Color(0xFF42A5F5);
  static const Color _tempestade = Color(0xFF5E35B1);
  static const Color _frio = Color(0xFF4FC3F7);
  static const Color _neutro = Color(0xFF9E9E9E);

  // dart format off
  static const Map<String, WeatherCondition> _conditions = {
    // Céu limpo / sol
    'cl': WeatherCondition(code: 'cl', description: 'Céu Claro', icon: Icons.wb_sunny, color: _sol),
    'ps': WeatherCondition(code: 'ps', description: 'Predomínio de Sol', icon: Icons.light_mode, color: _sol),
    'pn': WeatherCondition(code: 'pn', description: 'Parcialmente Nublado', icon: Icons.filter_drama, color: _solNuvem),
    'vn': WeatherCondition(code: 'vn', description: 'Variação de Nebulosidade', icon: Icons.filter_drama, color: _solNuvem),

    // Nebulosidade
    'n': WeatherCondition(code: 'n', description: 'Nublado', icon: Icons.cloud_queue, color: _nuvem),
    'e': WeatherCondition(code: 'e', description: 'Encoberto', icon: Icons.cloud, color: _encoberto),
    'en': WeatherCondition(code: 'en', description: 'Encoberto', icon: Icons.cloud, color: _encoberto),
    'nv': WeatherCondition(code: 'nv', description: 'Nevoeiro', icon: Icons.foggy, color: _nuvem),

    // Chuva
    'c': WeatherCondition(code: 'c', description: 'Chuva', icon: Icons.umbrella, color: _chuva),
    'ch': WeatherCondition(code: 'ch', description: 'Chuvoso', icon: Icons.umbrella, color: _chuva),
    'ci': WeatherCondition(code: 'ci', description: 'Chuvas Isoladas', icon: Icons.water_drop, color: _chuvaFraca),
    'ec': WeatherCondition(code: 'ec', description: 'Encoberto com Chuvas Isoladas', icon: Icons.water_drop, color: _chuvaFraca),
    'cv': WeatherCondition(code: 'cv', description: 'Chuvisco', icon: Icons.grain, color: _chuvaFraca),
    'cm': WeatherCondition(code: 'cm', description: 'Chuva pela Manhã', icon: Icons.umbrella, color: _chuva),
    'ct': WeatherCondition(code: 'ct', description: 'Chuva a Tarde', icon: Icons.umbrella, color: _chuva),
    'cn': WeatherCondition(code: 'cn', description: 'Chuva a Noite', icon: Icons.umbrella, color: _chuva),

    // Pancadas
    'pc': WeatherCondition(code: 'pc', description: 'Pancadas de Chuva', icon: Icons.umbrella, color: _chuva),
    'pm': WeatherCondition(code: 'pm', description: 'Pancadas de Chuva pela Manhã', icon: Icons.umbrella, color: _chuva),
    'pt': WeatherCondition(code: 'pt', description: 'Pancadas de Chuva a Tarde', icon: Icons.umbrella, color: _chuva),
    'pnt': WeatherCondition(code: 'pnt', description: 'Pancadas de Chuva a Noite', icon: Icons.umbrella, color: _chuva),
    'np': WeatherCondition(code: 'np', description: 'Nublado e Pancadas de Chuva', icon: Icons.umbrella, color: _chuva),
    'npm': WeatherCondition(code: 'npm', description: 'Nublado com Pancadas pela Manhã', icon: Icons.umbrella, color: _chuva),
    'npt': WeatherCondition(code: 'npt', description: 'Nublado com Pancadas a Tarde', icon: Icons.umbrella, color: _chuva),
    'npn': WeatherCondition(code: 'npn', description: 'Nublado com Pancadas a Noite', icon: Icons.umbrella, color: _chuva),

    // Possibilidade de chuva
    'psc': WeatherCondition(code: 'psc', description: 'Possibilidade de Chuva', icon: Icons.water_drop_outlined, color: _chuvaFraca),
    'pcm': WeatherCondition(code: 'pcm', description: 'Possibilidade de Chuva pela Manhã', icon: Icons.water_drop_outlined, color: _chuvaFraca),
    'pct': WeatherCondition(code: 'pct', description: 'Possibilidade de Chuva a Tarde', icon: Icons.water_drop_outlined, color: _chuvaFraca),
    'pcn': WeatherCondition(code: 'pcn', description: 'Possibilidade de Chuva a Noite', icon: Icons.water_drop_outlined, color: _chuvaFraca),
    'pp': WeatherCondition(code: 'pp', description: 'Possibilidade de Pancadas de Chuva', icon: Icons.water_drop_outlined, color: _chuvaFraca),
    'ppm': WeatherCondition(code: 'ppm', description: 'Possibilidade de Pancadas de Chuva pela Manhã', icon: Icons.water_drop_outlined, color: _chuvaFraca),
    'ppt': WeatherCondition(code: 'ppt', description: 'Possibilidade de Pancadas de Chuva a Tarde', icon: Icons.water_drop_outlined, color: _chuvaFraca),
    'ppn': WeatherCondition(code: 'ppn', description: 'Possibilidade de Pancadas de Chuva a Noite', icon: Icons.water_drop_outlined, color: _chuvaFraca),
    'npp': WeatherCondition(code: 'npp', description: 'Nublado com Possibilidade de Chuva', icon: Icons.water_drop_outlined, color: _chuvaFraca),
    'ncm': WeatherCondition(code: 'ncm', description: 'Nublado com Possibilidade de Chuva pela Manhã', icon: Icons.water_drop_outlined, color: _chuvaFraca),
    'nct': WeatherCondition(code: 'nct', description: 'Nublado com Possibilidade de Chuva a Tarde', icon: Icons.water_drop_outlined, color: _chuvaFraca),
    'ncn': WeatherCondition(code: 'ncn', description: 'Nublado com Possibilidade de Chuva a Noite', icon: Icons.water_drop_outlined, color: _chuvaFraca),

    // Severo / frio
    't': WeatherCondition(code: 't', description: 'Tempestade', icon: Icons.thunderstorm, color: _tempestade),
    'in': WeatherCondition(code: 'in', description: 'Instável', icon: Icons.thunderstorm_outlined, color: _tempestade),
    'g': WeatherCondition(code: 'g', description: 'Geada', icon: Icons.ac_unit, color: _frio),
    'ne': WeatherCondition(code: 'ne', description: 'Neve', icon: Icons.cloudy_snowing, color: _frio),

    // Sem definição
    'nd': WeatherCondition(code: 'nd', description: 'Não Definido', icon: Icons.help_outline, color: _neutro),
  };
  // dart format on

  /// Todas as siglas conhecidas (útil para testes e documentação).
  static Iterable<String> get knownCodes => _conditions.keys;

  /// Retorna a condição para a sigla; nunca lança exceção.
  static WeatherCondition fromCode(String? code) {
    final sigla = code?.trim().toLowerCase() ?? '';
    if (sigla.isEmpty || sigla == 'null') {
      return const WeatherCondition(
        code: '',
        description: 'Condição não informada',
        icon: Icons.help_outline,
        color: _neutro,
      );
    }
    return _conditions[sigla] ??
        WeatherCondition(
          code: sigla,
          description: 'Condição não identificada ($sigla)',
          icon: Icons.help_outline,
          color: _neutro,
        );
  }

  static String description(String? code) => fromCode(code).description;

  static IconData icon(String? code) => fromCode(code).icon;
}
