// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CartItemModelImpl _$$CartItemModelImplFromJson(Map<String, dynamic> json) =>
    _$CartItemModelImpl(
      productId: json['product_id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: (json['quantity'] as num).toInt(),
      size: json['size'] as String,
      image: json['image'] as String?,
      slug: json['slug'] as String?,
      category: json['category'] as String?,
      gender: json['gender'] as String?,
      maxStock: (json['max_stock'] as num?)?.toInt() ?? 999,
    );

Map<String, dynamic> _$$CartItemModelImplToJson(_$CartItemModelImpl instance) =>
    <String, dynamic>{
      'product_id': instance.productId,
      'name': instance.name,
      'price': instance.price,
      'quantity': instance.quantity,
      'size': instance.size,
      'image': instance.image,
      'slug': instance.slug,
      'category': instance.category,
      'gender': instance.gender,
      'max_stock': instance.maxStock,
    };
