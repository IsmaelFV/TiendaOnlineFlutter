import 'package:freezed_annotation/freezed_annotation.dart';
part 'cart_item_model.freezed.dart';
part 'cart_item_model.g.dart';

@freezed
class CartItemModel with _$CartItemModel {
  const factory CartItemModel({
    required String productId,
    required String name,
    required double price,
    required int quantity,
    required String size,
    String? image,
    String? slug,
    String? category,
    String? gender,
    @Default(999) int maxStock,
  }) = _CartItemModel;

  factory CartItemModel.fromJson(Map<String, dynamic> json) =>
      _$CartItemModelFromJson(json);
}
