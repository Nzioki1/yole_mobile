import 'package:intl/intl.dart';

class Formatters {
  static String currency(num amount, {String locale = 'en_US'}) {
    final f = NumberFormat.currency(locale: locale, symbol: '');
    return f.format(amount);
  }
}