import 'package:intl/intl.dart';

class Formatters {
  static String formatPrice(double price) {
    return NumberFormat.currency(symbol: '\$').format(price);
  }
}
