// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProductModelImpl _$$ProductModelImplFromJson(
  Map<String, dynamic> json,
) => _$ProductModelImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  slug: json['slug'] as String,
  description: json['description'] as String?,
  price: (json['price'] as num).toDouble(),
  stock: (json['stock'] as num?)?.toInt() ?? 0,
  stockBySize:
      (json['stock_by_size'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ) ??
      const {},
  categoryId: json['category_id'] as String?,
  genderId: json['gender_id'] as String?,
  images:
      (json['images'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  sizes:
      (json['sizes'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  availableSizes:
      (json['available_sizes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  featured: json['featured'] as bool? ?? false,
  isActive: json['is_active'] as bool? ?? true,
  isNew: json['is_new'] as bool? ?? false,
  isOnSale: json['is_on_sale'] as bool? ?? false,
  isSustainable: json['is_sustainable'] as bool? ?? false,
  salePrice: (json['sale_price'] as num?)?.toDouble(),
  color: json['color'] as String?,
  colorIds:
      (json['color_ids'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  material: json['material'] as String?,
  careInstructions: json['care_instructions'] as String?,
  sku: json['sku'] as String?,
  sizeMeasurements: json['size_measurements'] as Map<String, dynamic>?,
  popularityScore: (json['popularity_score'] as num?)?.toInt() ?? 0,
  salesCount: (json['sales_count'] as num?)?.toInt() ?? 0,
  weightGrams: (json['weight_grams'] as num?)?.toInt(),
  metaTitle: json['meta_title'] as String?,
  metaDescription: json['meta_description'] as String?,
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
  categories: json['categories'] as Map<String, dynamic>?,
  genders: json['genders'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$$ProductModelImplToJson(_$ProductModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'description': instance.description,
      'price': instance.price,
      'stock': instance.stock,
      'stock_by_size': instance.stockBySize,
      'category_id': instance.categoryId,
      'gender_id': instance.genderId,
      'images': instance.images,
      'sizes': instance.sizes,
      'available_sizes': instance.availableSizes,
      'featured': instance.featured,
      'is_active': instance.isActive,
      'is_new': instance.isNew,
      'is_on_sale': instance.isOnSale,
      'is_sustainable': instance.isSustainable,
      'sale_price': instance.salePrice,
      'color': instance.color,
      'color_ids': instance.colorIds,
      'material': instance.material,
      'care_instructions': instance.careInstructions,
      'sku': instance.sku,
      'size_measurements': instance.sizeMeasurements,
      'popularity_score': instance.popularityScore,
      'sales_count': instance.salesCount,
      'weight_grams': instance.weightGrams,
      'meta_title': instance.metaTitle,
      'meta_description': instance.metaDescription,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'categories': instance.categories,
      'genders': instance.genders,
    };
