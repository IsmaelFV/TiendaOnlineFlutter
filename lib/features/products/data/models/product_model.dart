import 'package:freezed_annotation/freezed_annotation.dart';
part 'product_model.freezed.dart';
part 'product_model.g.dart';

@freezed
class ProductModel with _$ProductModel {
  const factory ProductModel({
    required String id,
    required String name,
    required String slug,
    String? description,
    required double price,
    @Default(0) int stock,
    @Default({}) Map<String, int> stockBySize,
    String? categoryId,
    String? genderId,
    @Default([]) List<String> images,
    @Default([]) List<String> sizes,
    @Default([]) List<String> availableSizes,
    @Default(false) bool featured,
    @Default(true) bool isActive,
    @Default(false) bool isNew,
    @Default(false) bool isOnSale,
    @Default(false) bool isSustainable,
    double? salePrice,
    String? color,
    @Default([]) List<String> colorIds,
    String? material,
    String? careInstructions,
    String? sku,
    Map<String, dynamic>? sizeMeasurements,
    @Default(0) int popularityScore,
    @Default(0) int salesCount,
    int? weightGrams,
    String? metaTitle,
    String? metaDescription,
    String? createdAt,
    String? updatedAt,
    // Relaciones embebidas (nullable)
    Map<String, dynamic>? categories,
    Map<String, dynamic>? genders,
  }) = _ProductModel;

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);
}
