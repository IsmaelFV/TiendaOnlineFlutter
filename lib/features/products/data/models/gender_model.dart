/// Modelo simple de género (no requiere Freezed/build_runner)
class GenderModel {
  final String id;
  final String name;
  final String slug;
  final int displayOrder;
  final bool isActive;

  const GenderModel({
    required this.id,
    required this.name,
    required this.slug,
    this.displayOrder = 0,
    this.isActive = true,
  });

  factory GenderModel.fromJson(Map<String, dynamic> json) => GenderModel(
    id: json['id'] as String,
    name: json['name'] as String,
    slug: (json['slug'] as String?) ?? '',
    displayOrder: (json['display_order'] as int?) ?? 0,
    isActive: (json['is_active'] as bool?) ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'display_order': displayOrder,
    'is_active': isActive,
  };
}
