import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/exceptions/failure.dart';
import '../../../products/data/models/product_model.dart';

/// Estado del wishlist
final wishlistProvider = NotifierProvider<WishlistNotifier, List<ProductModel>>(
  WishlistNotifier.new,
);

/// Comprobar si un producto está en favoritos
final isInWishlistProvider = Provider.family<bool, String>((ref, productId) {
  final items = ref.watch(wishlistProvider);
  return items.any((p) => p.id == productId);
});

class WishlistNotifier extends Notifier<List<ProductModel>> {
  @override
  List<ProductModel> build() {
    _load();
    return [];
  }

  SupabaseClient get _client => Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<void> _load() async {
    if (_userId == null) return;

    try {
      final response = await _client
          .from('wishlist_items')
          .select('product_id, products(*)')
          .eq('user_id', _userId!);

      final list = (response as List)
          .where((item) => item['products'] != null)
          .map(
            (item) =>
                ProductModel.fromJson(item['products'] as Map<String, dynamic>),
          )
          .toList();

      state = list;
    } catch (_) {
      // silencioso en carga inicial
    }
  }

  Future<void> toggle(String productId) async {
    if (_userId == null) {
      throw const Failure.auth(message: 'Inicia sesión para usar favoritos');
    }

    final isIn = state.any((p) => p.id == productId);

    if (isIn) {
      // Eliminar
      state = state.where((p) => p.id != productId).toList();
      await _client
          .from('wishlist_items')
          .delete()
          .eq('user_id', _userId!)
          .eq('product_id', productId);
    } else {
      // Agregar
      await _client.from('wishlist_items').insert({
        'user_id': _userId!,
        'product_id': productId,
      });

      try {
        final productResponse = await _client
            .from('products')
            .select()
            .eq('id', productId)
            .single();
        final product = ProductModel.fromJson(productResponse);
        state = [...state, product];
      } catch (_) {
        // Si no se puede cargar el producto, ignorar en UI
      }
    }
  }

  Future<void> refresh() async => _load();
}
