import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/product_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/gender_model.dart';
import '../../data/repositories/products_repository_impl.dart';
import '../../domain/repositories/products_repository.dart';

/// Provider del repositorio de productos
final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepositoryImpl(Supabase.instance.client);
});

/// Provider de géneros (Mujer, Hombre…)
final gendersProvider = FutureProvider<List<GenderModel>>((ref) async {
  final repo = ref.watch(productsRepositoryProvider);
  final result = await repo.getGenders();
  return result.fold(
    (failure) => throw failure,
    (list) => list.map((json) => GenderModel.fromJson(json)).toList(),
  );
});

/// Provider de categorías
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final repo = ref.watch(productsRepositoryProvider);
  final result = await repo.getCategories();
  return result.fold((failure) => throw failure, (categories) => categories);
});

/// Provider de productos con paginación y filtros
final productsProvider =
    FutureProvider.family<List<ProductModel>, ProductsFilter>((
      ref,
      filter,
    ) async {
      final repo = ref.watch(productsRepositoryProvider);
      final result = await repo.getProducts(
        page: filter.page,
        limit: filter.limit,
        categoryId: filter.categoryId,
        categoryIds: filter.categoryIds,
        genderId: filter.genderId,
        sortBy: filter.sortBy,
        ascending: filter.ascending,
        minPrice: filter.minPrice,
        maxPrice: filter.maxPrice,
        isOnSale: filter.isOnSale,
        isNew: filter.isNew,
        featured: filter.featured,
      );
      return result.fold((failure) => throw failure, (products) => products);
    });

/// Provider de producto por slug
final productBySlugProvider = FutureProvider.family<ProductModel, String>((
  ref,
  slug,
) async {
  final repo = ref.watch(productsRepositoryProvider);
  final result = await repo.getProductBySlug(slug);
  return result.fold((failure) => throw failure, (product) => product);
});

/// Provider de búsqueda de productos
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];

  final repo = ref.watch(productsRepositoryProvider);
  final result = await repo.searchProducts(query);
  return result.fold((failure) => throw failure, (products) => products);
});

/// Provider de productos destacados
final featuredProductsProvider = FutureProvider<List<ProductModel>>((
  ref,
) async {
  final repo = ref.watch(productsRepositoryProvider);
  final result = await repo.getFeaturedProducts();
  return result.fold((failure) => throw failure, (products) => products);
});

/// Provider de productos nuevos
final newProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final repo = ref.watch(productsRepositoryProvider);
  final result = await repo.getNewProducts();
  return result.fold((failure) => throw failure, (products) => products);
});

/// Provider de novedades mujer (filtrado server-side por género)
final newProductsForWomenProvider = FutureProvider<List<ProductModel>>((
  ref,
) async {
  final repo = ref.watch(productsRepositoryProvider);
  // Obtener el genderId de "mujer" desde el provider de géneros
  final genders = await ref.watch(gendersProvider.future);
  final mujerGender = genders.where(
    (g) => g.slug.toLowerCase() == 'mujer' || g.name.toLowerCase() == 'mujer',
  );
  if (mujerGender.isEmpty) return [];

  final result = await repo.getProducts(
    isNew: true,
    genderId: mujerGender.first.id,
    limit: 8,
    sortBy: 'created_at',
    ascending: false,
  );
  return result.fold((failure) => throw failure, (products) => products);
});

/// Provider de novedades hombre (filtrado server-side por género)
final newProductsForMenProvider = FutureProvider<List<ProductModel>>((
  ref,
) async {
  final repo = ref.watch(productsRepositoryProvider);
  // Obtener el genderId de "hombre" desde el provider de géneros
  final genders = await ref.watch(gendersProvider.future);
  final hombreGender = genders.where(
    (g) => g.slug.toLowerCase() == 'hombre' || g.name.toLowerCase() == 'hombre',
  );
  if (hombreGender.isEmpty) return [];

  final result = await repo.getProducts(
    isNew: true,
    genderId: hombreGender.first.id,
    limit: 8,
    sortBy: 'created_at',
    ascending: false,
  );
  return result.fold((failure) => throw failure, (products) => products);
});

/// Provider de ofertas flash (productos)
final flashOffersProductsProvider = FutureProvider<List<ProductModel>>((
  ref,
) async {
  final repo = ref.watch(productsRepositoryProvider);
  final result = await repo.getFlashOfferProducts();
  return result.fold((failure) => throw failure, (products) => products);
});

/// Sentinel para distinguir "no pasado" de "null explícito" en copyWith.
const _sentinel = Object();

/// Filtro para productos
class ProductsFilter {
  final int page;
  final int limit;
  final String? categoryId;
  final List<String>? categoryIds;
  final String? genderId;
  final String? sortBy;
  final bool ascending;
  final double? minPrice;
  final double? maxPrice;
  final bool? isOnSale;
  final bool? isNew;
  final bool? featured;

  const ProductsFilter({
    this.page = 1,
    this.limit = 12,
    this.categoryId,
    this.categoryIds,
    this.genderId,
    this.sortBy,
    this.ascending = false,
    this.minPrice,
    this.maxPrice,
    this.isOnSale,
    this.isNew,
    this.featured,
  });

  /// copyWith que soporta pasar null explícitamente para resetear campos.
  /// Usa Object? + sentinel para distinguir "no pasado" de "null".
  ProductsFilter copyWith({
    int? page,
    int? limit,
    Object? categoryId = _sentinel,
    Object? categoryIds = _sentinel,
    Object? genderId = _sentinel,
    Object? sortBy = _sentinel,
    bool? ascending,
    Object? minPrice = _sentinel,
    Object? maxPrice = _sentinel,
    Object? isOnSale = _sentinel,
    Object? isNew = _sentinel,
    Object? featured = _sentinel,
  }) {
    return ProductsFilter(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      categoryId: identical(categoryId, _sentinel)
          ? this.categoryId
          : categoryId as String?,
      categoryIds: identical(categoryIds, _sentinel)
          ? this.categoryIds
          : categoryIds as List<String>?,
      genderId: identical(genderId, _sentinel)
          ? this.genderId
          : genderId as String?,
      sortBy: identical(sortBy, _sentinel) ? this.sortBy : sortBy as String?,
      ascending: ascending ?? this.ascending,
      minPrice: identical(minPrice, _sentinel)
          ? this.minPrice
          : minPrice as double?,
      maxPrice: identical(maxPrice, _sentinel)
          ? this.maxPrice
          : maxPrice as double?,
      isOnSale: identical(isOnSale, _sentinel)
          ? this.isOnSale
          : isOnSale as bool?,
      isNew: identical(isNew, _sentinel) ? this.isNew : isNew as bool?,
      featured: identical(featured, _sentinel)
          ? this.featured
          : featured as bool?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductsFilter &&
          page == other.page &&
          limit == other.limit &&
          categoryId == other.categoryId &&
          _listEquals(categoryIds, other.categoryIds) &&
          genderId == other.genderId &&
          sortBy == other.sortBy &&
          ascending == other.ascending &&
          minPrice == other.minPrice &&
          maxPrice == other.maxPrice &&
          isOnSale == other.isOnSale &&
          isNew == other.isNew &&
          featured == other.featured;

  static bool _listEquals(List<String>? a, List<String>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    page,
    limit,
    categoryId,
    categoryIds != null ? Object.hashAll(categoryIds!) : null,
    genderId,
    sortBy,
    ascending,
    minPrice,
    maxPrice,
    isOnSale,
    isNew,
    featured,
  );
}
