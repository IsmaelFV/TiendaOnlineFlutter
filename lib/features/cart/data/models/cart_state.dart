import 'package:freezed_annotation/freezed_annotation.dart';
import 'cart_item_model.dart';
part 'cart_state.freezed.dart';

@freezed
class CartState with _$CartState {
  const CartState._();

  const factory CartState({
    @Default({}) Map<String, CartItemModel> items,
    @Default('') String discountCode,
    @Default(0.0) double discountAmount,
  }) = _CartState;

  /// Clave única por producto+talla
  static String itemKey(String productId, String size) => '$productId-$size';

  /// Total de artículos en el carrito
  int get itemCount => items.values.fold(0, (sum, item) => sum + item.quantity);

  /// Subtotal en euros
  double get subtotal =>
      items.values.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

  /// Total con descuento
  double get total => (subtotal - discountAmount).clamp(0, double.infinity);

  /// Número de productos únicos
  int get uniqueItemCount => items.length;
}
