import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../shared/exceptions/failure.dart';
import '../../data/models/order_model.dart';

/// Provider de pedidos del usuario actual
final ordersProvider = FutureProvider<List<OrderModel>>((ref) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];

  try {
    final response = await client
        .from('orders')
        .select('*, order_items(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
        .toList();
  } catch (e) {
    throw Failure.unknown(message: 'Error al cargar pedidos', error: e);
  }
});

/// Provider de un pedido individual (autoDispose = siempre fresco al abrir)
final orderByIdProvider = FutureProvider.autoDispose.family<OrderModel, String>(
  (ref, orderId) async {
    final client = Supabase.instance.client;

    try {
      final response = await client
          .from('orders')
          .select('*, order_items(*)')
          .eq('id', orderId)
          .single();

      return OrderModel.fromJson(response);
    } catch (e) {
      throw Failure.unknown(message: 'Error al cargar pedido', error: e);
    }
  },
);

/// Provider para todos los pedidos (Admin)
final allOrdersProvider = FutureProvider<List<OrderModel>>((ref) async {
  final client = Supabase.instance.client;

  try {
    final response = await client
        .from('orders')
        .select('*, order_items(*)')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
        .toList();
  } catch (e) {
    throw Failure.unknown(message: 'Error al cargar pedidos', error: e);
  }
});

/// Actualizar estado del pedido (Admin)
Future<Either<Failure, Unit>> updateOrderStatus(
  String orderId,
  String status,
) async {
  try {
    await Supabase.instance.client
        .from('orders')
        .update({
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', orderId);
    return right(unit);
  } catch (e) {
    return left(
      Failure.unknown(message: 'Error al actualizar estado', error: e),
    );
  }
}
