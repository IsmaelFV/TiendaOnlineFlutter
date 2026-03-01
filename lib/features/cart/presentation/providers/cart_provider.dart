import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/cart_item_model.dart';
import '../../data/models/cart_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final cartProvider = NotifierProvider<CartNotifier, CartState>(
  CartNotifier.new,
);

class CartNotifier extends Notifier<CartState> {
  static const _boxName = 'cart_box';

  /// ID del usuario actual — se usa para aislar el carrito por cuenta
  String? _currentUserId;

  /// Clave de Hive única por usuario (o 'guest' si no hay sesión)
  String get _hiveKey => 'items_${_currentUserId ?? 'guest'}';

  @override
  CartState build() {
    // Observar cambios de sesión: al hacer login/logout se reconstruye
    // automáticamente el notifier con el carrito del nuevo usuario.
    final authState = ref.watch(authStateProvider);
    _currentUserId =
        authState.valueOrNull?.id ??
        Supabase.instance.client.auth.currentUser?.id;

    _loadFromLocal();
    return const CartState();
  }

  /// Añadir item al carrito (respeta stock máximo por talla)
  /// Devuelve true si se añadió, false si se alcanzó el límite.
  bool addItem(CartItemModel item) {
    final key = CartState.itemKey(item.productId, item.size);
    final existing = state.items[key];

    final updatedItems = Map<String, CartItemModel>.from(state.items);

    if (existing != null) {
      final maxStock = item.maxStock != 999 ? item.maxStock : existing.maxStock;
      final newQty = (existing.quantity + item.quantity).clamp(1, maxStock);
      if (newQty <= existing.quantity) return false; // ya en el máximo
      updatedItems[key] = existing.copyWith(
        quantity: newQty,
        maxStock: maxStock,
      );
    } else {
      final newQty = item.quantity.clamp(1, item.maxStock);
      updatedItems[key] = item.copyWith(quantity: newQty);
    }

    state = state.copyWith(items: updatedItems);
    _saveToLocal();
    return true;
  }

  /// Añadir item rápido desde la tarjeta de producto (primera talla disponible)
  bool quickAdd({
    required String productId,
    required String name,
    required double price,
    required String size,
    int maxStock = 999,
    String? image,
    String? slug,
  }) {
    return addItem(
      CartItemModel(
        productId: productId,
        name: name,
        price: price,
        quantity: 1,
        size: size,
        image: image,
        slug: slug,
        maxStock: maxStock,
      ),
    );
  }

  /// Eliminar item del carrito
  void removeItem(String productId, String size) {
    final key = CartState.itemKey(productId, size);
    final updatedItems = Map<String, CartItemModel>.from(state.items)
      ..remove(key);

    state = state.copyWith(items: updatedItems);
    _saveToLocal();
  }

  /// Actualizar cantidad de un item (respeta maxStock)
  void updateQuantity(String productId, String size, int qty) {
    final key = CartState.itemKey(productId, size);
    final existing = state.items[key];
    if (existing == null) return;

    if (qty <= 0) {
      removeItem(productId, size);
      return;
    }

    final capped = qty.clamp(1, existing.maxStock);
    final updatedItems = Map<String, CartItemModel>.from(state.items);
    updatedItems[key] = existing.copyWith(quantity: capped);

    state = state.copyWith(items: updatedItems);
    _saveToLocal();
  }

  /// Vaciar carrito
  void clear() {
    state = const CartState();
    _saveToLocal();
  }

  /// Aplicar código de descuento via RPC
  Future<bool> applyDiscountCode(String code) async {
    try {
      final response = await Supabase.instance.client.rpc(
        'validate_discount_code',
        params: {'code_input': code, 'order_total': state.subtotal},
      );

      if (response != null && response['valid'] == true) {
        final discount = (response['discount_amount'] as num).toDouble();
        state = state.copyWith(discountCode: code, discountAmount: discount);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Eliminar código descuento
  void removeDiscount() {
    state = state.copyWith(discountCode: '', discountAmount: 0);
  }

  // ─── Persistencia local con Hive ───

  Future<void> _loadFromLocal() async {
    try {
      final box = await Hive.openBox(_boxName);
      final raw = box.get(_hiveKey);
      if (raw != null && raw is Map) {
        final items = <String, CartItemModel>{};
        for (final entry in raw.entries) {
          try {
            items[entry.key] = CartItemModel.fromJson(
              Map<String, dynamic>.from(entry.value),
            );
          } catch (_) {
            // Skip corrupted entries
          }
        }
        if (items.isNotEmpty) {
          state = CartState(items: items);
        }
      }
    } catch (_) {
      // Hive error — start with empty cart
    }
  }

  Future<void> _saveToLocal() async {
    try {
      final box = await Hive.openBox(_boxName);
      final raw = state.items.map((key, item) => MapEntry(key, item.toJson()));
      await box.put(_hiveKey, raw);
    } catch (_) {
      // Silent fail — cart will be reloaded next time
    }
  }
}
