import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';

// ─────────────────────────────────────────────────────────────
//  TIPO DE PRENDA — determina qué medidas pedir
// ─────────────────────────────────────────────────────────────

enum _GarmentType { tops, bottoms, fullBody, footwear }

_GarmentType _detectGarmentType(String? categoryName) {
  if (categoryName == null || categoryName.isEmpty) return _GarmentType.tops;
  final c = categoryName.toLowerCase();

  const footwearKw = [
    'bota',
    'botas',
    'zapato',
    'zapatos',
    'zapatilla',
    'zapatillas',
    'sneaker',
    'sneakers',
    'sandalia',
    'sandalias',
    'mocasin',
    'mocasín',
    'calzado',
    'shoe',
    'shoes',
    'boot',
    'boots',
    'loafer',
    'slipper',
    'heel',
    'tacón',
    'tacones',
    'botín',
    'botines',
  ];
  for (final kw in footwearKw) {
    if (c.contains(kw)) return _GarmentType.footwear;
  }

  const bottomKw = [
    'pantalón',
    'pantalon',
    'pantalones',
    'vaquero',
    'vaqueros',
    'jean',
    'jeans',
    'falda',
    'faldas',
    'short',
    'shorts',
    'bermuda',
    'bermudas',
    'leggin',
    'leggings',
    'jogger',
    'joggers',
    'chino',
    'chinos',
    'cargo',
  ];
  for (final kw in bottomKw) {
    if (c.contains(kw)) return _GarmentType.bottoms;
  }

  const fullBodyKw = [
    'vestido',
    'vestidos',
    'mono',
    'monos',
    'jumpsuit',
    'body',
    'bodies',
    'enterizo',
    'overall',
    'overalls',
    'traje',
    'suit',
  ];
  for (final kw in fullBodyKw) {
    if (c.contains(kw)) return _GarmentType.fullBody;
  }

  return _GarmentType.tops;
}

// ─────────────────────────────────────────────────────────────
//  TABLAS DE MEDIDAS — ROPA (en cm, rango [min, max])
// ─────────────────────────────────────────────────────────────

const _kMaleTopSizes = <String, Map<String, List<double>>>{
  'XS': {
    'pecho': [84, 88],
    'cintura': [70, 74],
    'cadera': [88, 92],
    'altura': [165, 172],
  },
  'S': {
    'pecho': [88, 92],
    'cintura': [74, 78],
    'cadera': [92, 96],
    'altura': [168, 176],
  },
  'M': {
    'pecho': [92, 98],
    'cintura': [78, 84],
    'cadera': [96, 100],
    'altura': [172, 180],
  },
  'L': {
    'pecho': [98, 104],
    'cintura': [84, 90],
    'cadera': [100, 106],
    'altura': [176, 184],
  },
  'XL': {
    'pecho': [104, 110],
    'cintura': [90, 96],
    'cadera': [106, 112],
    'altura': [180, 188],
  },
  'XXL': {
    'pecho': [110, 118],
    'cintura': [96, 104],
    'cadera': [112, 118],
    'altura': [182, 192],
  },
};

const _kFemaleTopSizes = <String, Map<String, List<double>>>{
  'XS': {
    'pecho': [78, 82],
    'cintura': [58, 62],
    'cadera': [84, 88],
    'altura': [155, 162],
  },
  'S': {
    'pecho': [82, 86],
    'cintura': [62, 66],
    'cadera': [88, 92],
    'altura': [158, 166],
  },
  'M': {
    'pecho': [86, 92],
    'cintura': [66, 72],
    'cadera': [92, 98],
    'altura': [162, 170],
  },
  'L': {
    'pecho': [92, 98],
    'cintura': [72, 78],
    'cadera': [98, 104],
    'altura': [166, 174],
  },
  'XL': {
    'pecho': [98, 106],
    'cintura': [78, 86],
    'cadera': [104, 112],
    'altura': [168, 178],
  },
  'XXL': {
    'pecho': [106, 114],
    'cintura': [86, 94],
    'cadera': [112, 120],
    'altura': [170, 182],
  },
};

/// Mapeo numérico → letra (ropa casual) para hombre
const _kMaleNumericToLetter = <String, String>{
  '36': 'XS',
  '38': 'S',
  '40': 'M',
  '42': 'L',
  '44': 'XL',
  '46': 'XXL',
};

/// Mapeo numérico → letra (ropa casual) para mujer
const _kFemaleNumericToLetter = <String, String>{
  '34': 'XS',
  '36': 'S',
  '38': 'M',
  '40': 'L',
  '42': 'XL',
  '44': 'XXL',
};

// ─────────────────────────────────────────────────────────────
//  TABLAS DE CALZADO EUROPEO (longitud del pie en cm)
// ─────────────────────────────────────────────────────────────

const _kShoeUnisexSizes = <String, Map<String, List<double>>>{
  '35': {
    'pie_largo': [21.5, 22.0],
    'pie_ancho': [8.3, 8.6],
  },
  '36': {
    'pie_largo': [22.0, 22.5],
    'pie_ancho': [8.5, 8.8],
  },
  '37': {
    'pie_largo': [22.5, 23.5],
    'pie_ancho': [8.7, 9.0],
  },
  '38': {
    'pie_largo': [23.5, 24.0],
    'pie_ancho': [8.9, 9.2],
  },
  '39': {
    'pie_largo': [24.0, 24.5],
    'pie_ancho': [9.1, 9.4],
  },
  '40': {
    'pie_largo': [24.5, 25.5],
    'pie_ancho': [9.3, 9.7],
  },
  '41': {
    'pie_largo': [25.5, 26.0],
    'pie_ancho': [9.5, 9.9],
  },
  '42': {
    'pie_largo': [26.0, 27.0],
    'pie_ancho': [9.8, 10.2],
  },
  '43': {
    'pie_largo': [27.0, 27.5],
    'pie_ancho': [10.0, 10.4],
  },
  '44': {
    'pie_largo': [27.5, 28.5],
    'pie_ancho': [10.3, 10.7],
  },
  '45': {
    'pie_largo': [28.5, 29.0],
    'pie_ancho': [10.5, 10.9],
  },
  '46': {
    'pie_largo': [29.0, 30.0],
    'pie_ancho': [10.8, 11.2],
  },
};

// ─────────────────────────────────────────────────────────────
//  TABLAS DE PANTALONES EUROPEOS (cintura/cadera/entrepierna)
// ─────────────────────────────────────────────────────────────

const _kMaleBottomSizes = <String, Map<String, List<double>>>{
  'XS': {
    'cintura': [70, 74],
    'cadera': [88, 92],
    'entrepierna': [76, 78],
  },
  'S': {
    'cintura': [74, 78],
    'cadera': [92, 96],
    'entrepierna': [78, 80],
  },
  'M': {
    'cintura': [78, 84],
    'cadera': [96, 100],
    'entrepierna': [80, 82],
  },
  'L': {
    'cintura': [84, 90],
    'cadera': [100, 106],
    'entrepierna': [81, 83],
  },
  'XL': {
    'cintura': [90, 96],
    'cadera': [106, 112],
    'entrepierna': [82, 84],
  },
  'XXL': {
    'cintura': [96, 104],
    'cadera': [112, 118],
    'entrepierna': [82, 85],
  },
};

const _kFemaleBottomSizes = <String, Map<String, List<double>>>{
  'XS': {
    'cintura': [58, 62],
    'cadera': [84, 88],
    'entrepierna': [72, 74],
  },
  'S': {
    'cintura': [62, 66],
    'cadera': [88, 92],
    'entrepierna': [74, 76],
  },
  'M': {
    'cintura': [66, 72],
    'cadera': [92, 98],
    'entrepierna': [76, 78],
  },
  'L': {
    'cintura': [72, 78],
    'cadera': [98, 104],
    'entrepierna': [77, 79],
  },
  'XL': {
    'cintura': [78, 86],
    'cadera': [104, 112],
    'entrepierna': [78, 80],
  },
  'XXL': {
    'cintura': [86, 94],
    'cadera': [112, 120],
    'entrepierna': [78, 81],
  },
};

const _kMaleBottomNumToLetter = <String, String>{
  '38': 'XS',
  '40': 'S',
  '42': 'M',
  '44': 'L',
  '46': 'XL',
  '48': 'XXL',
};
const _kFemaleBottomNumToLetter = <String, String>{
  '34': 'XS',
  '36': 'S',
  '38': 'M',
  '40': 'L',
  '42': 'XL',
  '44': 'XXL',
};

// ─────── Constantes SharedPreferences ───────
const _kPrefGender = 'sr_gender';
const _kPrefAltura = 'sr_altura';
const _kPrefPecho = 'sr_pecho';
const _kPrefCintura = 'sr_cintura';
const _kPrefCadera = 'sr_cadera';
const _kPrefPieLargo = 'sr_pie_largo';
const _kPrefPieAncho = 'sr_pie_ancho';
const _kPrefEntrepierna = 'sr_entrepierna';
const _kPrefFit = 'sr_fit';

// ─────────────────────────────────────────────────────────────
//  MODELO DE RESULTADO
// ─────────────────────────────────────────────────────────────

class SizeRecommendation {
  final String size;
  final int confidence; // 0-100
  final Map<String, double> scores; // puntuación por medida

  const SizeRecommendation({
    required this.size,
    required this.confidence,
    required this.scores,
  });
}

// ─────────────────────────────────────────────────────────────
//  WIDGET PRINCIPAL — Bottom Sheet con Wizard 4 pasos
// ─────────────────────────────────────────────────────────────

class SizeRecommenderSheet extends StatefulWidget {
  final List<String> productSizes;
  final Map<String, dynamic>? sizeMeasurements;
  final ValueChanged<String> onSelectSize;
  final String? categoryName;

  const SizeRecommenderSheet({
    super.key,
    required this.productSizes,
    this.sizeMeasurements,
    required this.onSelectSize,
    this.categoryName,
  });

  /// Abre el bottom sheet desde cualquier contexto.
  static Future<void> show(
    BuildContext context, {
    required List<String> productSizes,
    Map<String, dynamic>? sizeMeasurements,
    required ValueChanged<String> onSelectSize,
    String? categoryName,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SizeRecommenderSheet(
        productSizes: productSizes,
        sizeMeasurements: sizeMeasurements,
        onSelectSize: onSelectSize,
        categoryName: categoryName,
      ),
    );
  }

  @override
  State<SizeRecommenderSheet> createState() => _SizeRecommenderSheetState();
}

class _SizeRecommenderSheetState extends State<SizeRecommenderSheet>
    with TickerProviderStateMixin {
  int _step = 0; // 0=género, 1=medidas, 2=preferencia ajuste, 3=resultado
  String _gender = ''; // 'hombre' | 'mujer'
  String _fitPreference = 'normal'; // 'ajustado' | 'normal' | 'holgado'

  /// Pasos del wizard — dependen del tipo de producto.
  /// Calzado omite género y preferencia de ajuste.
  List<String> get _steps {
    if (_productType == _GarmentType.footwear) {
      return ['medidas', 'resultado'];
    }
    return ['genero', 'medidas', 'ajuste', 'resultado'];
  }

  String get _currentStepKey => _steps[_step.clamp(0, _steps.length - 1)];
  int get _totalSteps => _steps.length;

  final _alturaCtrl = TextEditingController();
  final _pechoCtrl = TextEditingController();
  final _cinturaCtrl = TextEditingController();
  final _caderaCtrl = TextEditingController();
  final _pieLargoCtrl = TextEditingController();
  final _pieAnchoCtrl = TextEditingController();
  final _entrepiernaCtrl = TextEditingController();

  late final AnimationController _stepCtrl;
  SizeRecommendation? _recommendation;

  _GarmentType get _productType => _detectGarmentType(widget.categoryName);

  /// Las medidas disponibles según el producto o tabla estándar.
  List<String> get _availableMeasures {
    // Si el producto tiene medidas custom, usarlas
    if (widget.sizeMeasurements != null &&
        widget.sizeMeasurements!.isNotEmpty) {
      for (final entry in widget.sizeMeasurements!.entries) {
        if (entry.value is Map) {
          return (entry.value as Map).keys.cast<String>().toList();
        }
      }
    }
    // Según tipo de producto
    return switch (_productType) {
      _GarmentType.footwear => ['pie_largo', 'pie_ancho'],
      _GarmentType.bottoms => ['cintura', 'cadera', 'entrepierna'],
      _GarmentType.fullBody => ['pecho', 'cintura', 'cadera', 'altura'],
      _GarmentType.tops => ['pecho', 'cintura', 'altura'],
    };
  }

  TextEditingController _ctrlFor(String measure) {
    return switch (measure) {
      'altura' => _alturaCtrl,
      'pecho' => _pechoCtrl,
      'cintura' => _cinturaCtrl,
      'cadera' => _caderaCtrl,
      'pie_largo' => _pieLargoCtrl,
      'pie_ancho' => _pieAnchoCtrl,
      'entrepierna' => _entrepiernaCtrl,
      _ => _alturaCtrl,
    };
  }

  String _labelFor(String measure) {
    const labels = {
      'altura': 'Altura',
      'pecho': 'Contorno de pecho',
      'cintura': 'Contorno de cintura',
      'cadera': 'Contorno de cadera',
      'hombros': 'Hombros',
      'largo_manga': 'Largo manga',
      'largo_pierna': 'Largo pierna',
      'pie_largo': 'Longitud del pie',
      'pie_ancho': 'Anchura del pie',
      'entrepierna': 'Entrepierna',
    };
    return labels[measure] ?? measure.replaceAll('_', ' ').capitalize();
  }

  IconData _iconFor(String measure) {
    const icons = {
      'altura': Icons.height_rounded,
      'pecho': Icons.accessibility_new_rounded,
      'cintura': Icons.straighten_rounded,
      'cadera': Icons.man_rounded,
      'hombros': Icons.accessibility_rounded,
      'largo_manga': Icons.back_hand_outlined,
      'largo_pierna': Icons.do_not_step_outlined,
      'pie_largo': Icons.social_distance_rounded,
      'pie_ancho': Icons.swap_horiz_rounded,
      'entrepierna': Icons.straighten_rounded,
    };
    return icons[measure] ?? Icons.straighten_rounded;
  }

  @override
  void initState() {
    super.initState();
    _stepCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _gender = prefs.getString(_kPrefGender) ?? '';
      final h = prefs.getDouble(_kPrefAltura);
      final p = prefs.getDouble(_kPrefPecho);
      final c = prefs.getDouble(_kPrefCintura);
      final ca = prefs.getDouble(_kPrefCadera);
      final pl = prefs.getDouble(_kPrefPieLargo);
      final pa = prefs.getDouble(_kPrefPieAncho);
      final ep = prefs.getDouble(_kPrefEntrepierna);
      if (h != null) _alturaCtrl.text = h.toStringAsFixed(0);
      if (p != null) _pechoCtrl.text = p.toStringAsFixed(0);
      if (c != null) _cinturaCtrl.text = c.toStringAsFixed(0);
      if (ca != null) _caderaCtrl.text = ca.toStringAsFixed(0);
      if (pl != null) _pieLargoCtrl.text = pl.toStringAsFixed(1);
      if (pa != null) _pieAnchoCtrl.text = pa.toStringAsFixed(1);
      if (ep != null) _entrepiernaCtrl.text = ep.toStringAsFixed(0);
      _fitPreference = prefs.getString(_kPrefFit) ?? 'normal';
    });
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefGender, _gender);
    if (_alturaCtrl.text.isNotEmpty) {
      await prefs.setDouble(
        _kPrefAltura,
        double.tryParse(_alturaCtrl.text) ?? 0,
      );
    }
    if (_pechoCtrl.text.isNotEmpty) {
      await prefs.setDouble(_kPrefPecho, double.tryParse(_pechoCtrl.text) ?? 0);
    }
    if (_cinturaCtrl.text.isNotEmpty) {
      await prefs.setDouble(
        _kPrefCintura,
        double.tryParse(_cinturaCtrl.text) ?? 0,
      );
    }
    if (_caderaCtrl.text.isNotEmpty) {
      await prefs.setDouble(
        _kPrefCadera,
        double.tryParse(_caderaCtrl.text) ?? 0,
      );
    }
    if (_pieLargoCtrl.text.isNotEmpty) {
      await prefs.setDouble(
        _kPrefPieLargo,
        double.tryParse(_pieLargoCtrl.text) ?? 0,
      );
    }
    if (_pieAnchoCtrl.text.isNotEmpty) {
      await prefs.setDouble(
        _kPrefPieAncho,
        double.tryParse(_pieAnchoCtrl.text) ?? 0,
      );
    }
    if (_entrepiernaCtrl.text.isNotEmpty) {
      await prefs.setDouble(
        _kPrefEntrepierna,
        double.tryParse(_entrepiernaCtrl.text) ?? 0,
      );
    }
    await prefs.setString(_kPrefFit, _fitPreference);
  }

  @override
  void dispose() {
    _stepCtrl.dispose();
    _alturaCtrl.dispose();
    _pechoCtrl.dispose();
    _cinturaCtrl.dispose();
    _caderaCtrl.dispose();
    _pieLargoCtrl.dispose();
    _pieAnchoCtrl.dispose();
    _entrepiernaCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    HapticFeedback.selectionClick();
    _stepCtrl.forward(from: 0);
    setState(() {
      _step++;
      if (_currentStepKey == 'resultado') _computeRecommendation();
    });
  }

  void _prevStep() {
    HapticFeedback.selectionClick();
    _stepCtrl.forward(from: 0);
    setState(() => _step = (_step - 1).clamp(0, _steps.length - 1));
  }

  // ─────────────────────────────────────────────────────────────
  //  LÓGICA DE RECOMENDACIÓN
  // ─────────────────────────────────────────────────────────────

  void _computeRecommendation() {
    _saveProfile();

    final userMeasures = <String, double>{};
    for (final m in _availableMeasures) {
      final val = double.tryParse(_ctrlFor(m).text);
      if (val != null && val > 0) userMeasures[m] = val;
    }

    if (userMeasures.isEmpty) return;

    // Obtener tabla de referencia
    Map<String, Map<String, List<double>>> referenceTable;

    if (widget.sizeMeasurements != null &&
        widget.sizeMeasurements!.isNotEmpty) {
      // Usar medidas específicas del producto
      referenceTable = _parseProductMeasurements(widget.sizeMeasurements!);
    } else {
      // Usar tablas estándar según tipo de producto
      Map<String, Map<String, List<double>>> standardTable;
      if (_productType == _GarmentType.footwear) {
        standardTable = _kShoeUnisexSizes;
      } else if (_productType == _GarmentType.bottoms) {
        standardTable = _gender == 'mujer'
            ? _kFemaleBottomSizes
            : _kMaleBottomSizes;
      } else {
        standardTable = _gender == 'mujer' ? _kFemaleTopSizes : _kMaleTopSizes;
      }
      referenceTable = _filterToProductSizes(standardTable);
    }

    if (referenceTable.isEmpty) return;

    // Calcular score de cada talla
    String bestSize = '';
    int bestScore = -1;
    final allScores = <String, Map<String, double>>{};

    for (final entry in referenceTable.entries) {
      final sizeName = entry.key;
      final ranges = entry.value;
      final scores = <String, double>{};
      double totalScore = 0;
      int count = 0;

      for (final m in userMeasures.keys) {
        final range = ranges[m];
        if (range == null || range.length < 2) continue;

        double min = range[0];
        double max = range[1];

        // Ajustar según preferencia de ajuste
        if (_fitPreference == 'ajustado') {
          min -= 2;
          max -= 2;
        } else if (_fitPreference == 'holgado') {
          min += 2;
          max += 2;
        }

        final val = userMeasures[m]!;
        final mid = (min + max) / 2;
        final halfRange = (max - min) / 2;

        double score;
        if (val >= min && val <= max) {
          // Dentro del rango → 70-100 según cercanía al centro
          final dist = (val - mid).abs();
          score = 100 - (dist / halfRange * 30).clamp(0, 30);
        } else {
          // Fuera del rango → penalización proporcional
          final dist = val < min ? (min - val) : (val - max);
          score = math.max(0, 70 - (dist / halfRange * 50));
        }

        scores[m] = score;
        totalScore += score;
        count++;
      }

      final avgScore = count > 0 ? (totalScore / count).round() : 0;
      allScores[sizeName] = scores;

      if (avgScore > bestScore) {
        bestScore = avgScore;
        bestSize = sizeName;
      }
    }

    if (bestSize.isNotEmpty) {
      setState(() {
        _recommendation = SizeRecommendation(
          size: bestSize,
          confidence: bestScore,
          scores: allScores[bestSize] ?? {},
        );
      });
    }
  }

  /// Parsea sizeMeasurements del producto.
  /// Formato esperado: {"S": {"pecho": [86, 90], "cintura": [70, 74]}, ...}
  Map<String, Map<String, List<double>>> _parseProductMeasurements(
    Map<String, dynamic> raw,
  ) {
    final result = <String, Map<String, List<double>>>{};
    for (final sizeEntry in raw.entries) {
      if (sizeEntry.value is! Map) continue;
      final sizeKey = sizeEntry.key;
      // Solo incluir tallas que el producto tiene
      if (!widget.productSizes.contains(sizeKey)) continue;
      final measures = <String, List<double>>{};
      for (final mEntry in (sizeEntry.value as Map).entries) {
        if (mEntry.value is List && (mEntry.value as List).length >= 2) {
          measures[mEntry.key as String] = [
            (mEntry.value[0] as num).toDouble(),
            (mEntry.value[1] as num).toDouble(),
          ];
        }
      }
      if (measures.isNotEmpty) result[sizeKey] = measures;
    }
    return result;
  }

  /// Filtra la tabla estándar a las tallas del producto.
  Map<String, Map<String, List<double>>> _filterToProductSizes(
    Map<String, Map<String, List<double>>> standardTable,
  ) {
    final result = <String, Map<String, List<double>>>{};
    // Para calzado no necesitamos mapeo letra/número — las tallas son directas (38, 39...)
    Map<String, String>? numToLetter;
    if (_productType == _GarmentType.footwear) {
      numToLetter = null; // las tallas de calzado ya son numéricas
    } else if (_productType == _GarmentType.bottoms) {
      numToLetter = _gender == 'mujer'
          ? _kFemaleBottomNumToLetter
          : _kMaleBottomNumToLetter;
    } else {
      numToLetter = _gender == 'mujer'
          ? _kFemaleNumericToLetter
          : _kMaleNumericToLetter;
    }

    for (final size in widget.productSizes) {
      // Intentar directamente (ej: "M", "L", "42")
      if (standardTable.containsKey(size.toUpperCase())) {
        result[size] = standardTable[size.toUpperCase()]!;
        continue;
      }
      if (standardTable.containsKey(size)) {
        result[size] = standardTable[size]!;
        continue;
      }
      // Intentar mapeo numérico → letra
      if (numToLetter != null) {
        final letter = numToLetter[size];
        if (letter != null && standardTable.containsKey(letter)) {
          result[size] = standardTable[letter]!;
        }
      }
    }
    return result;
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.gray600,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.gold500.withValues(alpha: 0.2),
                        AppColors.gold600.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.straighten_rounded,
                    color: AppColors.gold400,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recomendador de talla',
                        style: AppTextStyles.h4.copyWith(fontSize: 17),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Encuentra tu talla ideal en ${_totalSteps - 1} pasos',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.gray800,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: _buildProgressBar(),
          ),
          const Divider(color: AppColors.divider, height: 1),
          // Content
          Flexible(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) {
                return FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: anim,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: child,
                  ),
                );
              },
              child: _buildStepContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Row(
      children: List.generate(_totalSteps, (i) {
        final isActive = i <= _step;
        final isCurrent = i == _step;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < _totalSteps - 1 ? 6 : 0),
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: isActive
                  ? (isCurrent
                        ? AppColors.gold500
                        : AppColors.gold600.withValues(alpha: 0.6))
                  : AppColors.gray700,
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: AppColors.gold500.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepContent() {
    final key = _currentStepKey;
    return switch (key) {
      'genero' => _StepGender(
        key: const ValueKey('step_gender'),
        selected: _gender,
        onSelect: (g) {
          setState(() => _gender = g);
          _nextStep();
        },
      ),
      'medidas' => _StepMeasurements(
        key: const ValueKey('step_measures'),
        availableMeasures: _availableMeasures,
        ctrlFor: _ctrlFor,
        labelFor: _labelFor,
        iconFor: _iconFor,
        productType: _productType,
        onNext: _nextStep,
        onBack: _step > 0 ? _prevStep : null,
      ),
      'ajuste' => _StepFitPreference(
        key: const ValueKey('step_fit'),
        selected: _fitPreference,
        onSelect: (f) {
          setState(() => _fitPreference = f);
          _nextStep();
        },
        onBack: _prevStep,
      ),
      'resultado' => _StepResult(
        key: const ValueKey('step_result'),
        recommendation: _recommendation,
        onSelectSize: (size) {
          widget.onSelectSize(size);
          Navigator.pop(context);
        },
        onRetry: () {
          setState(() => _step = 0);
        },
        labelFor: _labelFor,
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

// ─────────────────────────────────────────────────────────────
//  PASO 1: SELECCIONAR GÉNERO
// ─────────────────────────────────────────────────────────────

class _StepGender extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _StepGender({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        children: [
          const Icon(Icons.wc_rounded, color: AppColors.gold400, size: 40),
          const SizedBox(height: 16),
          Text(
            '¿Para quién es la prenda?',
            style: AppTextStyles.h3.copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Esto nos ayuda a usar las tablas de medidas correctas',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _GenderCard(
                  label: 'Hombre',
                  icon: Icons.male_rounded,
                  isSelected: selected == 'hombre',
                  onTap: () => onSelect('hombre'),
                  gradient: [const Color(0xFF1E3A5F), const Color(0xFF0F2744)],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _GenderCard(
                  label: 'Mujer',
                  icon: Icons.female_rounded,
                  isSelected: selected == 'mujer',
                  onTap: () => onSelect('mujer'),
                  gradient: [const Color(0xFF5F1E3A), const Color(0xFF440F27)],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final List<Color> gradient;

  const _GenderCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.gold500 : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.gold500.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PASO 2: INTRODUCIR MEDIDAS
// ─────────────────────────────────────────────────────────────

class _StepMeasurements extends StatelessWidget {
  final List<String> availableMeasures;
  final TextEditingController Function(String) ctrlFor;
  final String Function(String) labelFor;
  final IconData Function(String) iconFor;
  final _GarmentType productType;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const _StepMeasurements({
    super.key,
    required this.availableMeasures,
    required this.ctrlFor,
    required this.labelFor,
    required this.iconFor,
    required this.productType,
    required this.onNext,
    this.onBack,
  });

  bool get _hasAtLeastOneMeasure {
    return availableMeasures.any(
      (m) => (double.tryParse(ctrlFor(m).text) ?? 0) > 0,
    );
  }

  String get _title {
    return switch (productType) {
      _GarmentType.footwear => 'Medidas del pie',
      _GarmentType.bottoms => 'Tus medidas de cintura y pierna',
      _GarmentType.fullBody => 'Tus medidas corporales',
      _GarmentType.tops => 'Tus medidas corporales',
    };
  }

  String get _tip {
    return switch (productType) {
      _GarmentType.footwear =>
        'Coloca el pie sobre un papel, marca la punta y el talón, y mide la distancia. Para el ancho, mide la parte más ancha del pie.',
      _GarmentType.bottoms =>
        'Mide la cintura a la altura del ombligo, la cadera en la parte más ancha, y la entrepierna desde la ingle hasta el tobillo.',
      _ =>
        'Mide con una cinta métrica pegada al cuerpo sin apretar. Cuantas más medidas introduzcas, más precisa será la recomendación.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_title, style: AppTextStyles.h3.copyWith(fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            'Introduce las medidas que conozcas (mínimo 1)',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          // Medidas
          ...availableMeasures.map(
            (m) => _MeasureInput(
              measure: m,
              label: labelFor(m),
              icon: iconFor(m),
              controller: ctrlFor(m),
            ),
          ),
          const SizedBox(height: 8),
          // Ayuda visual
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.info.withValues(alpha: 0.7),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _tip,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Botones
          Row(
            children: [
              if (onBack != null) ...[
                _BackButton(onTap: onBack!),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: _NextButton(
                  label: 'Continuar',
                  enabled: _hasAtLeastOneMeasure,
                  onTap: onNext,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MeasureInput extends StatelessWidget {
  final String measure;
  final String label;
  final IconData icon;
  final TextEditingController controller;

  const _MeasureInput({
    required this.measure,
    required this.label,
    required this.icon,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.gray800.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.gold500.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(14),
                ),
              ),
              child: Icon(icon, color: AppColors.gold400, size: 22),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  style: AppTextStyles.body.copyWith(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: label,
                    hintStyle: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Text(
                'cm',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PASO 3: PREFERENCIA DE AJUSTE
// ─────────────────────────────────────────────────────────────

class _StepFitPreference extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onBack;

  const _StepFitPreference({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        children: [
          const Icon(
            Icons.checkroom_rounded,
            color: AppColors.gold400,
            size: 40,
          ),
          const SizedBox(height: 16),
          Text(
            '¿Cómo prefieres el ajuste?',
            style: AppTextStyles.h3.copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Ajustaremos la recomendación según tu preferencia',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          _FitOption(
            label: 'Ajustado',
            description: 'Pegado al cuerpo, silueta ceñida',
            icon: Icons.compress_rounded,
            isSelected: selected == 'ajustado',
            onTap: () => onSelect('ajustado'),
          ),
          const SizedBox(height: 12),
          _FitOption(
            label: 'Normal',
            description: 'Cómodo, ni apretado ni holgado',
            icon: Icons.straighten_rounded,
            isSelected: selected == 'normal',
            onTap: () => onSelect('normal'),
          ),
          const SizedBox(height: 12),
          _FitOption(
            label: 'Holgado',
            description: 'Amplio, con movimiento libre',
            icon: Icons.expand_rounded,
            isSelected: selected == 'holgado',
            onTap: () => onSelect('holgado'),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _BackButton(onTap: onBack),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
    );
  }
}

class _FitOption extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FitOption({
    required this.label,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gold500.withValues(alpha: 0.1)
              : AppColors.gray800.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.gold500 : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.gold500.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.gold500.withValues(alpha: 0.2)
                    : AppColors.gray700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.gold400 : AppColors.textMuted,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.gold400
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.gold500,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.black,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PASO 4: RESULTADO
// ─────────────────────────────────────────────────────────────

class _StepResult extends StatelessWidget {
  final SizeRecommendation? recommendation;
  final ValueChanged<String> onSelectSize;
  final VoidCallback onRetry;
  final String Function(String) labelFor;

  const _StepResult({
    super.key,
    required this.recommendation,
    required this.onSelectSize,
    required this.onRetry,
    required this.labelFor,
  });

  Color _confidenceColor(int confidence) {
    if (confidence >= 80) return AppColors.success;
    if (confidence >= 60) return AppColors.gold500;
    if (confidence >= 40) return AppColors.warning;
    return AppColors.error;
  }

  String _confidenceLabel(int confidence) {
    if (confidence >= 85) return 'Excelente';
    if (confidence >= 70) return 'Buena';
    if (confidence >= 55) return 'Moderada';
    return 'Baja';
  }

  @override
  Widget build(BuildContext context) {
    if (recommendation == null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.warning,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No pudimos calcular una recomendación',
              style: AppTextStyles.h4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Introduce al menos una medida corporal para obtener una sugerencia.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _NextButton(label: 'Reintentar', enabled: true, onTap: onRetry),
          ],
        ),
      );
    }

    final rec = recommendation!;
    final confColor = _confidenceColor(rec.confidence);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        children: [
          // Talla recomendada
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.gold500.withValues(alpha: 0.15),
                  AppColors.gold700.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.gold500.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Tu talla recomendada',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.gold500,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold500.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      rec.size,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Confianza
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      rec.confidence >= 70
                          ? Icons.verified_rounded
                          : Icons.info_outline_rounded,
                      color: confColor,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Confianza: ${_confidenceLabel(rec.confidence)} (${rec.confidence}%)',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: confColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Barra de confianza
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: rec.confidence / 100,
                    backgroundColor: AppColors.gray700,
                    valueColor: AlwaysStoppedAnimation<Color>(confColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Desglose por medida
          if (rec.scores.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Desglose por medida',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...rec.scores.entries.map(
              (e) => _ScoreRow(label: labelFor(e.key), score: e.value.round()),
            ),
          ],
          const SizedBox(height: 24),

          // Botón seleccionar
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onSelectSize(rec.size);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold500,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'SELECCIONAR TALLA ${rec.size}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Repetir
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Repetir con otras medidas'),
            style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final int score;

  const _ScoreRow({required this.label, required this.score});

  Color get _color {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.gold500;
    if (score >= 40) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: score / 100,
                backgroundColor: AppColors.gray700,
                valueColor: AlwaysStoppedAnimation<Color>(_color),
                minHeight: 5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 35,
            child: Text(
              '$score%',
              textAlign: TextAlign.right,
              style: AppTextStyles.bodySmall.copyWith(
                color: _color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  BOTONES COMPARTIDOS
// ─────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.gray800,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textMuted,
          size: 18,
        ),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _NextButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 48,
        decoration: BoxDecoration(
          color: enabled ? AppColors.gold500 : AppColors.gray700,
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.gold500.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: enabled ? Colors.black : AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_forward_rounded,
                color: enabled ? Colors.black : AppColors.textMuted,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  EXTENSIÓN HELPER
// ─────────────────────────────────────────────────────────────

extension _StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
