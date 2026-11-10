import 'package:intl/intl.dart';

/// Formatação de datas em pt_BR.
///
/// Requer `initializeDateFormatting('pt_BR')` antes do primeiro uso
/// (feito em `main`).
class DateFormatter {
  DateFormatter._();

  static const String _locale = 'pt_BR';

  /// Converte "2026-11-10" em DateTime. Retorna null para valores vazios,
  /// "null" ou fora do formato.
  static DateTime? parseApiDate(String? value) {
    if (value == null) return null;
    final texto = value.trim();
    if (texto.isEmpty || texto.toLowerCase() == 'null') return null;
    final data = DateTime.tryParse(texto);
    if (data == null) return null;
    return DateTime(data.year, data.month, data.day);
  }

  /// 10/11/2026
  static String date(DateTime data) =>
      DateFormat('dd/MM/yyyy', _locale).format(data);

  /// 10/11
  static String dayMonth(DateTime data) =>
      DateFormat('dd/MM', _locale).format(data);

  /// 10/11/2026 às 14:05
  static String dateTime(DateTime data) =>
      "${date(data)} às ${DateFormat('HH:mm', _locale).format(data)}";

  /// Ter
  static String weekdayShort(DateTime data) =>
      _capitalize(DateFormat.E(_locale).format(data).replaceAll('.', ''));

  /// Terça-feira
  static String weekdayLong(DateTime data) =>
      _capitalize(DateFormat.EEEE(_locale).format(data));

  /// "Hoje", "Amanhã" ou o dia da semana por extenso.
  static String relativeDay(DateTime data, {DateTime? agora}) {
    final hoje = _soData(agora ?? DateTime.now());
    final diferenca = _soData(data).difference(hoje).inDays;
    if (diferenca == 0) return 'Hoje';
    if (diferenca == 1) return 'Amanhã';
    if (diferenca == -1) return 'Ontem';
    return weekdayLong(data);
  }

  static DateTime _soData(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
