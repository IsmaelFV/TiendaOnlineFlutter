import 'package:fpdart/fpdart.dart';

import '../../../../shared/exceptions/failure.dart';
import '../../data/models/product_model.dart';
import '../../data/models/category_model.dart';

/// Contrato del repositorio de productos
abstract class ProductsRepository {
  /// Obtener productos con paginación y filtros
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
  });

  /// Obtener producto por slug
  Future<Either<Failure, ProductModel>> getProductBySlug(String slug);

  /// Buscar productos con texto
  Future<Either<Failure, List<ProductModel>>> searchProducts(String query);

  /// Obtener géneros (Mujer, Hombre…)
  Future<Either<Failure, List<Map<String, dynamic>>>> getGenders();

  /// Obtener categorías
  Future<Either<Failure, List<CategoryModel>>> getCategories();

  /// Obtener productos en oferta (flash offers)
  Future<Either<Failure, List<ProductModel>>> getFlashOfferProducts();

  /// Obtener productos destacados
  Future<Either<Failure, List<ProductModel>>> getFeaturedProducts();

  /// Obtener productos nuevos
  Future<Either<Failure, List<ProductModel>>> getNewProducts();

  /// Crear producto (Admin)
  Future<Either<Failure, ProductModel>> createProduct(
    Map<String, dynamic> data,
  );

  /// Actualizar producto (Admin)
  Future<Either<Failure, Unit>> updateProduct(
    String id,
    Map<String, dynamic> data,
  );

  /// Eliminar producto (Admin)
  Future<Either<Failure, Unit>> deleteProduct(String id);

  /// Toggle campo booleano de producto (Admin)
  Future<Either<Failure, Unit>> toggleProductField(
    String id,
    String field,
    bool value,
  );

  /// Subir imagen de producto
  Future<Either<Failure, String>> uploadProductImage(
    String fileName,
    List<int> bytes,
  );
}
