// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OrderModelImpl _$$OrderModelImplFromJson(Map<String, dynamic> json) =>
    _$OrderModelImpl(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String?,
      userId: json['user_id'] as String?,
      customerEmail: json['customer_email'] as String?,
      shippingFullName: json['shipping_full_name'] as String?,
      shippingPhone: json['shipping_phone'] as String?,
      shippingAddressLine1: json['shipping_address_line1'] as String?,
      shippingAddressLine2: json['shipping_address_line2'] as String?,
      shippingCity: json['shipping_city'] as String?,
      shippingState: json['shipping_state'] as String?,
      shippingPostalCode: json['shipping_postal_code'] as String?,
      shippingCountry: json['shipping_country'] as String?,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      shippingCost: (json['shipping_cost'] as num?)?.toDouble() ?? 0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'pending',
      paymentMethod: json['payment_method'] as String?,
      paymentStatus: json['payment_status'] as String?,
      paymentId: json['payment_id'] as String?,
      customerNotes: json['customer_notes'] as String?,
      adminNotes: json['admin_notes'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      orderItems:
          (json['order_items'] as List<dynamic>?)
              ?.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$OrderModelImplToJson(_$OrderModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_number': instance.orderNumber,
      'user_id': instance.userId,
      'customer_email': instance.customerEmail,
      'shipping_full_name': instance.shippingFullName,
      'shipping_phone': instance.shippingPhone,
      'shipping_address_line1': instance.shippingAddressLine1,
      'shipping_address_line2': instance.shippingAddressLine2,
      'shipping_city': instance.shippingCity,
      'shipping_state': instance.shippingState,
      'shipping_postal_code': instance.shippingPostalCode,
      'shipping_country': instance.shippingCountry,
      'subtotal': instance.subtotal,
      'shipping_cost': instance.shippingCost,
      'tax': instance.tax,
      'discount': instance.discount,
      'total': instance.total,
      'status': instance.status,
      'payment_method': instance.paymentMethod,
      'payment_status': instance.paymentStatus,
      'payment_id': instance.paymentId,
      'customer_notes': instance.customerNotes,
      'admin_notes': instance.adminNotes,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'order_items': instance.orderItems.map((e) => e.toJson()).toList(),
    };

_$OrderItemModelImpl _$$OrderItemModelImplFromJson(Map<String, dynamic> json) =>
    _$OrderItemModelImpl(
      id: json['id'] as String,
      orderId: json['order_id'] as String?,
      productId: json['product_id'] as String?,
      productName: json['product_name'] as String?,
      productSlug: json['product_slug'] as String?,
      productSku: json['product_sku'] as String?,
      productImage: json['product_image'] as String?,
      size: json['size'] as String?,
      color: json['color'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$$OrderItemModelImplToJson(
  _$OrderItemModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'order_id': instance.orderId,
  'product_id': instance.productId,
  'product_name': instance.productName,
  'product_slug': instance.productSlug,
  'product_sku': instance.productSku,
  'product_image': instance.productImage,
  'size': instance.size,
  'color': instance.color,
  'quantity': instance.quantity,
  'price': instance.price,
  'subtotal': instance.subtotal,
};
