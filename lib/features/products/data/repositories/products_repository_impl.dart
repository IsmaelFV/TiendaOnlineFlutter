import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/exceptions/failure.dart';
import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../../domain/repositories/products_repository.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  final SupabaseClient _client;

  ProductsRepositoryImpl(this._client);

  @override
  Future<Either<Failure, List<ProductModel>>> getProducts({
    int page = 1,
    int limit = 12,
    String? categoryId,
    List<String>? categoryIds,
    String? genderId,
    String? sortBy,
    bool ascending = false,
    double? minPrice,
    double? maxPrice,
    bool? isOnSale,
    bool? isNew,
    bool? isSustainable,
    bool? featured,
  }) async {
    try {
      var query = _client
          .from('products')
          .select('*, categories!category_id(*), genders!gender_id(*)')
          .eq('is_active', true);

      if (categoryIds != null && categoryIds.isNotEmpty) {
        query = query.inFilter('category_id', categoryIds);
      } else if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }
      if (genderId != null) query = query.eq('gender_id', genderId);
      if (isOnSale == true) query = query.eq('is_on_sale', true);
      if (isNew == true) {
        // Novedades: productos creados en los últimos 30 días O marcados manualmente
        final thirtyDaysAgo = DateTime.now()
            .subtract(const Duration(days: 30))
            .toUtc()
            .toIso8601String();
        query = query.or('is_new.eq.true,created_at.gte.$thirtyDaysAgo');
      }
      if (isSustainable == true) query = query.eq('is_sustainable', true);
      if (featured == true) query = query.eq('featured', true);
      if (minPrice != null) query = query.gte('price', minPrice);
      if (maxPrice != null) query = query.lte('price', maxPrice);

      final offset = (page - 1) * limit;
      final orderColumn = sortBy ?? 'created_at';

      final response = await query
          .order(orderColumn, ascending: ascending)
          .range(offset, offset + limit - 1);

      final products = (response as List)
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return right(products);
    } on PostgrestException catch (e) {
      return left(
        Failure.network(
          message: e.message,
          statusCode: e.code != null ? int.tryParse(e.code!) : null,
        ),
      );
    } catch (e) {
      return left(
        Failure.unknown(message: 'Error al cargar productos', error: e),
      );
    }
  }

  @override
  Future<Either<Failure, ProductModel>> getProductBySlug(String slug) async {
    try {
      final response = await _client
          .from('products')
          .select('*, categories!category_id(*), genders!gender_id(*)')
          .eq('slug', slug)
          .single();

      return right(ProductModel.fromJson(response));
    } on PostgrestException catch (e) {
      return left(
        Failure.network(
          message: e.message,
          statusCode: e.code != null ? int.tryParse(e.code!) : null,
        ),
      );
    } catch (e) {
      return left(
        Failure.unknown(message: 'Error al cargar producto', error: e),
      );
    }
  }

  @override
  Future<Either<Failure, List<ProductModel>>> searchProducts(
    String query,
  ) async {
    try {
      final response = await _client.rpc(
        'search_products',
        params: {'search_query': query},
      );

      final products = (response as List)
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return right(products);
    } catch (e) {
      // Fallback a búsqueda simple por nombre
      try {
        final response = await _client
            .from('products')
            .select('*, categories!category_id(*), genders!gender_id(*)')
            .eq('is_active', true)
            .ilike('name', '%$query%')
            .limit(20);

        final products = (response as List)
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();

        return right(products);
      } catch (e2) {
        return left(
          Failure.unknown(message: 'Error en la búsqueda', error: e2),
        );
      }
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getGenders() async {
    try {
      final response = await _client
          .from('genders')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);

      final genders = (response as List)
          .map((json) => json as Map<String, dynamic>)
          .toList();

      return right(genders);
    } catch (e) {
      return left(
        Failure.unknown(message: 'Error al cargar géneros', error: e),
      );
    }
  }

  @override
  Future<Either<Failure, List<CategoryModel>>> getCategories() async {
    try {
      final response = await _client
          .from('categories')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);

      final categories = (response as List)
          .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return right(categories);
    } catch (e) {
      return left(
        Failure.unknown(message: 'Error al cargar categorías', error: e),
      );
    }
  }

  @override
  Future<Either<Failure, List<ProductModel>>> getFlashOfferProducts() async {
    try {
      final response = await _client
          .from('products')
          .select('*, categories!category_id(*), genders!gender_id(*)')
          .eq('is_on_sale', true)
          .eq('is_active', true)
          .limit(30);

      final products = (response as List)
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Aleatorizar y devolver hasta 10
      products.shuffle();
      final result = products.length > 10 ? products.sublist(0, 10) : products;

      return right(result);
    } catch (e) {
      return left(
        Failure.unknown(message: 'Error al cargar ofertas', error: e),
      );
    }
  }

  @override
  Future<Either<Failure, List<ProductModel>>> getFeaturedProducts() async {
    try {
      final response = await _client
          .from('products')
          .select('*, categories!category_id(*), genders!gender_id(*)')
          .eq('is_active', true)
          .eq('featured', true)
          .order('popularity_score', ascending: false)
          .limit(8);

      final products = (response as List)
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return right(products);
    } catch (e) {
      return left(
        Failure.unknown(message: 'Error al cargar destacados', error: e),
      );
    }
  }

  @override
  Future<Either<Failure, List<ProductModel>>> getNewProducts() async {
    try {
      // Novedades: productos creados en los últimos 30 días O marcados manualmente
      final thirtyDaysAgo = DateTime.now()
          .subtract(const Duration(days: 30))
          .toUtc()
          .toIso8601String();
      final response = await _client
          .from('products')
          .select('*, categories!category_id(*), genders!gender_id(*)')
          .eq('is_active', true)
          .or('is_new.eq.true,created_at.gte.$thirtyDaysAgo')
          .order('created_at', ascending: false)
          .limit(8);

      final products = (response as List)
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return right(products);
    } catch (e) {
      return left(Failure.unknown(message: 'Error al cargar nuevos', error: e));
    }
  }

  @override
  Future<Either<Failure, ProductModel>> createProduct(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client
          .from('products')
          .insert(data)
          .select()
          .single();

      return right(ProductModel.fromJson(response));
    } on PostgrestException catch (e) {
      return left(Failure.network(message: e.message));
    } catch (e) {
      return left(
        Failure.unknown(message: 'Error al crear producto', error: e),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> updateProduct(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      await _client.from('products').update(data).eq('id', id);
      return right(unit);
    } on PostgrestException catch (e) {
      return left(Failure.network(message: e.message));
    } catch (e) {
      return left(
        Failure.unknown(message: 'Error al actualizar producto', error: e),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteProduct(String id) async {
    try {
      await _client.from('products').delete().eq('id', id);
      return right(unit);
    } on PostgrestException catch (e) {
      return left(Failure.network(message: e.message));
    } catch (e) {
      return left(
        Failure.unknown(message: 'Error al eliminar producto', error: e),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> toggleProductField(
    String id,
    String field,
    bool value,
  ) async {
    try {
      await _client.from('products').update({field: value}).eq('id', id);
      return right(unit);
    } catch (e) {
      return left(
        Failure.unknown(message: 'Error al actualizar campo', error: e),
      );
    }
  }

  @override
  Future<Either<Failure, String>> uploadProductImage(
    String fileName,
    List<int> bytes,
  ) async {
    try {
      final path = 'productos/$fileName';
      await _client.storage
          .from('products-images')
          .uploadBinary(
            path,
            bytes as dynamic,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final publicUrl = _client.storage
          .from('products-images')
          .getPublicUrl(path);

      return right(publicUrl);
    } catch (e) {
      return left(Failure.unknown(message: 'Error al subir imagen', error: e));
    }
  }
}
