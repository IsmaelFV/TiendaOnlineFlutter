// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CategoryModelImpl _$$CategoryModelImplFromJson(Map<String, dynamic> json) =>
    _$CategoryModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      parentId: json['parent_id'] as String?,
      genderId: json['gender_id'] as String?,
      level: (json['level'] as num?)?.toInt() ?? 1,
      categoryType: json['category_type'] as String?,
      createdAt: json['created_at'] as String?,
    );

Map<String, dynamic> _$$CategoryModelImplToJson(_$CategoryModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'description': instance.description,
      'image_url': instance.imageUrl,
      'is_active': instance.isActive,
      'display_order': instance.displayOrder,
      'parent_id': instance.parentId,
      'gender_id': instance.genderId,
      'level': instance.level,
      'category_type': instance.categoryType,
      'created_at': instance.createdAt,
    };
