import 'package:intl/intl.dart';

/// Extensiones para formateo de moneda
extension NumberExtensions on num {
  /// Convierte céntimos de la BD a euros formateados: 2999 → "29,99 €"
  /// Usar para datos de `products` y del carrito (almacenados en céntimos).
  String get toCurrency {
    final formatter = NumberFormat.currency(
      locale: 'es_ES',
      symbol: '€',
      decimalDigits: 2,
    );
    return formatter.format(this / 100);
  }

  /// Formatea un valor ya en euros: 29.99 → "29,99 €"
  /// Usar para datos de `orders`, `order_items`, `returns` y dashboard
  /// (almacenados en euros en la BD).
  String get toEuroCurrency {
    final formatter = NumberFormat.currency(
      locale: 'es_ES',
      symbol: '€',
      decimalDigits: 2,
    );
    return formatter.format(this);
  }

  /// Formato porcentaje: "-30%"
  String get toPercentage => '-${toInt()}%';
}
