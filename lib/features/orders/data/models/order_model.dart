import 'package:freezed_annotation/freezed_annotation.dart';
part 'order_model.freezed.dart';
part 'order_model.g.dart';

@freezed
class OrderModel with _$OrderModel {
  const factory OrderModel({
    required String id,
    String? orderNumber,
    String? userId,
    String? customerEmail,
    String? shippingFullName,
    String? shippingPhone,
    String? shippingAddressLine1,
    String? shippingAddressLine2,
    String? shippingCity,
    String? shippingState,
    String? shippingPostalCode,
    String? shippingCountry,
    @Default(0) double subtotal,
    @Default(0) double shippingCost,
    @Default(0) double tax,
    @Default(0) double discount,
    @Default(0) double total,
    @Default('pending') String status,
    String? paymentMethod,
    String? paymentStatus,
    String? paymentId,
    String? customerNotes,
    String? adminNotes,
    String? createdAt,
    String? updatedAt,
    // Items embebidos
    @Default([]) List<OrderItemModel> orderItems,
  }) = _OrderModel;

  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);
}

@freezed
class OrderItemModel with _$OrderItemModel {
  const factory OrderItemModel({
    required String id,
    String? orderId,
    String? productId,
    String? productName,
    String? productSlug,
    String? productSku,
    String? productImage,
    String? size,
    String? color,
    @Default(1) int quantity,
    @Default(0) double price,
    @Default(0) double subtotal,
  }) = _OrderItemModel;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) =>
      _$OrderItemModelFromJson(json);
}
