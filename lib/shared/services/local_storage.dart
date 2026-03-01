import 'package:hive_flutter/hive_flutter.dart';

/// Servicio de almacenamiento local con Hive
class LocalStorageService {
  LocalStorageService._();

  static const _settingsBoxName = 'settings_box';
  static const _recentlyViewedBoxName = 'recently_viewed_box';

  /// Inicializar Hive
  static Future<void> init() async {
    await Hive.initFlutter();
  }

  // ─── Settings ───

  static Future<Box> get _settingsBox async => Hive.isBoxOpen(_settingsBoxName)
      ? Hive.box(_settingsBoxName)
      : await Hive.openBox(_settingsBoxName);

  static Future<T?> getSetting<T>(String key) async {
    final box = await _settingsBox;
    return box.get(key) as T?;
  }

  static Future<void> setSetting<T>(String key, T value) async {
    final box = await _settingsBox;
    await box.put(key, value);
  }

  // ─── Recently Viewed ───

  static Future<Box> get _recentlyViewedBox async =>
      Hive.isBoxOpen(_recentlyViewedBoxName)
      ? Hive.box(_recentlyViewedBoxName)
      : await Hive.openBox(_recentlyViewedBoxName);

  static Future<List<String>> getRecentlyViewed() async {
    final box = await _recentlyViewedBox;
    final raw = box.get('items', defaultValue: <dynamic>[]) as List<dynamic>;
    return raw.cast<String>();
  }

  static Future<void> addRecentlyViewed(String productId) async {
    final box = await _recentlyViewedBox;
    final items = await getRecentlyViewed();
    items.remove(productId);
    items.insert(0, productId);
    if (items.length > 12) {
      items.removeRange(12, items.length);
    }
    await box.put('items', items);
  }
}
