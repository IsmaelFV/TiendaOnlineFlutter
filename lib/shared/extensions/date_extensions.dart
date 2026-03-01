import 'package:intl/intl.dart';

/// Extensiones de formato de fechas en español
extension DateExtensions on DateTime {
  /// Formato: "27 de febrero de 2026"
  String get fullDate {
    final formatter = DateFormat("d 'de' MMMM 'de' yyyy", 'es_ES');
    return formatter.format(this);
  }

  /// Formato: "27 feb 2026"
  String get shortDate {
    final formatter = DateFormat('d MMM yyyy', 'es_ES');
    return formatter.format(this);
  }

  /// Formato: "27/02/2026"
  String get numericDate {
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(this);
  }

  /// Formato: "27/02/2026 14:30"
  String get dateTime {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(this);
  }

  /// Formato relativo: "hace 2 horas", "hace 3 días", etc.
  String get relative {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) return 'hace un momento';
    if (difference.inMinutes < 60) {
      return 'hace ${difference.inMinutes} min';
    }
    if (difference.inHours < 24) {
      return 'hace ${difference.inHours}h';
    }
    if (difference.inDays < 7) {
      return 'hace ${difference.inDays} días';
    }
    if (difference.inDays < 30) {
      return 'hace ${difference.inDays ~/ 7} semanas';
    }
    return shortDate;
  }

  /// ¿Hace menos de X horas?
  bool isWithinHours(int hours) {
    return DateTime.now().difference(this).inHours < hours;
  }
}
