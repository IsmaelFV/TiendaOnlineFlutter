// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ProductModel _$ProductModelFromJson(Map<String, dynamic> json) {
  return _ProductModel.fromJson(json);
}

/// @nodoc
mixin _$ProductModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get slug => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  int get stock => throw _privateConstructorUsedError;
  Map<String, int> get stockBySize => throw _privateConstructorUsedError;
  String? get categoryId => throw _privateConstructorUsedError;
  String? get genderId => throw _privateConstructorUsedError;
  List<String> get images => throw _privateConstructorUsedError;
  List<String> get sizes => throw _privateConstructorUsedError;
  List<String> get availableSizes => throw _privateConstructorUsedError;
  bool get featured => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  bool get isNew => throw _privateConstructorUsedError;
  bool get isOnSale => throw _privateConstructorUsedError;
  bool get isSustainable => throw _privateConstructorUsedError;
  double? get salePrice => throw _privateConstructorUsedError;
  String? get color => throw _privateConstructorUsedError;
  List<String> get colorIds => throw _privateConstructorUsedError;
  String? get material => throw _privateConstructorUsedError;
  String? get careInstructions => throw _privateConstructorUsedError;
  String? get sku => throw _privateConstructorUsedError;
  Map<String, dynamic>? get sizeMeasurements =>
      throw _privateConstructorUsedError;
  int get popularityScore => throw _privateConstructorUsedError;
  int get salesCount => throw _privateConstructorUsedError;
  int? get weightGrams => throw _privateConstructorUsedError;
  String? get metaTitle => throw _privateConstructorUsedError;
  String? get metaDescription => throw _privateConstructorUsedError;
  String? get createdAt => throw _privateConstructorUsedError;
  String? get updatedAt =>
      throw _privateConstructorUsedError; // Relaciones embebidas (nullable)
  Map<String, dynamic>? get categories => throw _privateConstructorUsedError;
  Map<String, dynamic>? get genders => throw _privateConstructorUsedError;

  /// Serializes this ProductModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProductModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProductModelCopyWith<ProductModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProductModelCopyWith<$Res> {
  factory $ProductModelCopyWith(
    ProductModel value,
    $Res Function(ProductModel) then,
  ) = _$ProductModelCopyWithImpl<$Res, ProductModel>;
  @useResult
  $Res call({
    String id,
    String name,
    String slug,
    String? description,
    double price,
    int stock,
    Map<String, int> stockBySize,
    String? categoryId,
    String? genderId,
    List<String> images,
    List<String> sizes,
    List<String> availableSizes,
    bool featured,
    bool isActive,
    bool isNew,
    bool isOnSale,
    bool isSustainable,
    double? salePrice,
    String? color,
    List<String> colorIds,
    String? material,
    String? careInstructions,
    String? sku,
    Map<String, dynamic>? sizeMeasurements,
    int popularityScore,
    int salesCount,
    int? weightGrams,
    String? metaTitle,
    String? metaDescription,
    String? createdAt,
    String? updatedAt,
    Map<String, dynamic>? categories,
    Map<String, dynamic>? genders,
  });
}

/// @nodoc
class _$ProductModelCopyWithImpl<$Res, $Val extends ProductModel>
    implements $ProductModelCopyWith<$Res> {
  _$ProductModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProductModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? slug = null,
    Object? description = freezed,
    Object? price = null,
    Object? stock = null,
    Object? stockBySize = null,
    Object? categoryId = freezed,
    Object? genderId = freezed,
    Object? images = null,
    Object? sizes = null,
    Object? availableSizes = null,
    Object? featured = null,
    Object? isActive = null,
    Object? isNew = null,
    Object? isOnSale = null,
    Object? isSustainable = null,
    Object? salePrice = freezed,
    Object? color = freezed,
    Object? colorIds = null,
    Object? material = freezed,
    Object? careInstructions = freezed,
    Object? sku = freezed,
    Object? sizeMeasurements = freezed,
    Object? popularityScore = null,
    Object? salesCount = null,
    Object? weightGrams = freezed,
    Object? metaTitle = freezed,
    Object? metaDescription = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? categories = freezed,
    Object? genders = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            slug: null == slug
                ? _value.slug
                : slug // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            price: null == price
                ? _value.price
                : price // ignore: cast_nullable_to_non_nullable
                      as double,
            stock: null == stock
                ? _value.stock
                : stock // ignore: cast_nullable_to_non_nullable
                      as int,
            stockBySize: null == stockBySize
                ? _value.stockBySize
                : stockBySize // ignore: cast_nullable_to_non_nullable
                      as Map<String, int>,
            categoryId: freezed == categoryId
                ? _value.categoryId
                : categoryId // ignore: cast_nullable_to_non_nullable
                      as String?,
            genderId: freezed == genderId
                ? _value.genderId
                : genderId // ignore: cast_nullable_to_non_nullable
                      as String?,
            images: null == images
                ? _value.images
                : images // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            sizes: null == sizes
                ? _value.sizes
                : sizes // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            availableSizes: null == availableSizes
                ? _value.availableSizes
                : availableSizes // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            featured: null == featured
                ? _value.featured
                : featured // ignore: cast_nullable_to_non_nullable
                      as bool,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
            isNew: null == isNew
                ? _value.isNew
                : isNew // ignore: cast_nullable_to_non_nullable
                      as bool,
            isOnSale: null == isOnSale
                ? _value.isOnSale
                : isOnSale // ignore: cast_nullable_to_non_nullable
                      as bool,
            isSustainable: null == isSustainable
                ? _value.isSustainable
                : isSustainable // ignore: cast_nullable_to_non_nullable
                      as bool,
            salePrice: freezed == salePrice
                ? _value.salePrice
                : salePrice // ignore: cast_nullable_to_non_nullable
                      as double?,
            color: freezed == color
                ? _value.color
                : color // ignore: cast_nullable_to_non_nullable
                      as String?,
            colorIds: null == colorIds
                ? _value.colorIds
                : colorIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            material: freezed == material
                ? _value.material
                : material // ignore: cast_nullable_to_non_nullable
                      as String?,
            careInstructions: freezed == careInstructions
                ? _value.careInstructions
                : careInstructions // ignore: cast_nullable_to_non_nullable
                      as String?,
            sku: freezed == sku
                ? _value.sku
                : sku // ignore: cast_nullable_to_non_nullable
                      as String?,
            sizeMeasurements: freezed == sizeMeasurements
                ? _value.sizeMeasurements
                : sizeMeasurements // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            popularityScore: null == popularityScore
                ? _value.popularityScore
                : popularityScore // ignore: cast_nullable_to_non_nullable
                      as int,
            salesCount: null == salesCount
                ? _value.salesCount
                : salesCount // ignore: cast_nullable_to_non_nullable
                      as int,
            weightGrams: freezed == weightGrams
                ? _value.weightGrams
                : weightGrams // ignore: cast_nullable_to_non_nullable
                      as int?,
            metaTitle: freezed == metaTitle
                ? _value.metaTitle
                : metaTitle // ignore: cast_nullable_to_non_nullable
                      as String?,
            metaDescription: freezed == metaDescription
                ? _value.metaDescription
                : metaDescription // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as String?,
            categories: freezed == categories
                ? _value.categories
                : categories // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            genders: freezed == genders
                ? _value.genders
                : genders // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ProductModelImplCopyWith<$Res>
    implements $ProductModelCopyWith<$Res> {
  factory _$$ProductModelImplCopyWith(
    _$ProductModelImpl value,
    $Res Function(_$ProductModelImpl) then,
  ) = __$$ProductModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String slug,
    String? description,
    double price,
    int stock,
    Map<String, int> stockBySize,
    String? categoryId,
    String? genderId,
    List<String> images,
    List<String> sizes,
    List<String> availableSizes,
    bool featured,
    bool isActive,
    bool isNew,
    bool isOnSale,
    bool isSustainable,
    double? salePrice,
    String? color,
    List<String> colorIds,
    String? material,
    String? careInstructions,
    String? sku,
    Map<String, dynamic>? sizeMeasurements,
    int popularityScore,
    int salesCount,
    int? weightGrams,
    String? metaTitle,
    String? metaDescription,
    String? createdAt,
    String? updatedAt,
    Map<String, dynamic>? categories,
    Map<String, dynamic>? genders,
  });
}

/// @nodoc
class __$$ProductModelImplCopyWithImpl<$Res>
    extends _$ProductModelCopyWithImpl<$Res, _$ProductModelImpl>
    implements _$$ProductModelImplCopyWith<$Res> {
  __$$ProductModelImplCopyWithImpl(
    _$ProductModelImpl _value,
    $Res Function(_$ProductModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ProductModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? slug = null,
    Object? description = freezed,
    Object? price = null,
    Object? stock = null,
    Object? stockBySize = null,
    Object? categoryId = freezed,
    Object? genderId = freezed,
    Object? images = null,
    Object? sizes = null,
    Object? availableSizes = null,
    Object? featured = null,
    Object? isActive = null,
    Object? isNew = null,
    Object? isOnSale = null,
    Object? isSustainable = null,
    Object? salePrice = freezed,
    Object? color = freezed,
    Object? colorIds = null,
    Object? material = freezed,
    Object? careInstructions = freezed,
    Object? sku = freezed,
    Object? sizeMeasurements = freezed,
    Object? popularityScore = null,
    Object? salesCount = null,
    Object? weightGrams = freezed,
    Object? metaTitle = freezed,
    Object? metaDescription = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? categories = freezed,
    Object? genders = freezed,
  }) {
    return _then(
      _$ProductModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        slug: null == slug
            ? _value.slug
            : slug // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        price: null == price
            ? _value.price
            : price // ignore: cast_nullable_to_non_nullable
                  as double,
        stock: null == stock
            ? _value.stock
            : stock // ignore: cast_nullable_to_non_nullable
                  as int,
        stockBySize: null == stockBySize
            ? _value._stockBySize
            : stockBySize // ignore: cast_nullable_to_non_nullable
                  as Map<String, int>,
        categoryId: freezed == categoryId
            ? _value.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String?,
        genderId: freezed == genderId
            ? _value.genderId
            : genderId // ignore: cast_nullable_to_non_nullable
                  as String?,
        images: null == images
            ? _value._images
            : images // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        sizes: null == sizes
            ? _value._sizes
            : sizes // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        availableSizes: null == availableSizes
            ? _value._availableSizes
            : availableSizes // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        featured: null == featured
            ? _value.featured
            : featured // ignore: cast_nullable_to_non_nullable
                  as bool,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        isNew: null == isNew
            ? _value.isNew
            : isNew // ignore: cast_nullable_to_non_nullable
                  as bool,
        isOnSale: null == isOnSale
            ? _value.isOnSale
            : isOnSale // ignore: cast_nullable_to_non_nullable
                  as bool,
        isSustainable: null == isSustainable
            ? _value.isSustainable
            : isSustainable // ignore: cast_nullable_to_non_nullable
                  as bool,
        salePrice: freezed == salePrice
            ? _value.salePrice
            : salePrice // ignore: cast_nullable_to_non_nullable
                  as double?,
        color: freezed == color
            ? _value.color
            : color // ignore: cast_nullable_to_non_nullable
                  as String?,
        colorIds: null == colorIds
            ? _value._colorIds
            : colorIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        material: freezed == material
            ? _value.material
            : material // ignore: cast_nullable_to_non_nullable
                  as String?,
        careInstructions: freezed == careInstructions
            ? _value.careInstructions
            : careInstructions // ignore: cast_nullable_to_non_nullable
                  as String?,
        sku: freezed == sku
            ? _value.sku
            : sku // ignore: cast_nullable_to_non_nullable
                  as String?,
        sizeMeasurements: freezed == sizeMeasurements
            ? _value._sizeMeasurements
            : sizeMeasurements // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        popularityScore: null == popularityScore
            ? _value.popularityScore
            : popularityScore // ignore: cast_nullable_to_non_nullable
                  as int,
        salesCount: null == salesCount
            ? _value.salesCount
            : salesCount // ignore: cast_nullable_to_non_nullable
                  as int,
        weightGrams: freezed == weightGrams
            ? _value.weightGrams
            : weightGrams // ignore: cast_nullable_to_non_nullable
                  as int?,
        metaTitle: freezed == metaTitle
            ? _value.metaTitle
            : metaTitle // ignore: cast_nullable_to_non_nullable
                  as String?,
        metaDescription: freezed == metaDescription
            ? _value.metaDescription
            : metaDescription // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as String?,
        categories: freezed == categories
            ? _value._categories
            : categories // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        genders: freezed == genders
            ? _value._genders
            : genders // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ProductModelImpl implements _ProductModel {
  const _$ProductModelImpl({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.price,
    this.stock = 0,
    final Map<String, int> stockBySize = const {},
    this.categoryId,
    this.genderId,
    final List<String> images = const [],
    final List<String> sizes = const [],
    final List<String> availableSizes = const [],
    this.featured = false,
    this.isActive = true,
    this.isNew = false,
    this.isOnSale = false,
    this.isSustainable = false,
    this.salePrice,
    this.color,
    final List<String> colorIds = const [],
    this.material,
    this.careInstructions,
    this.sku,
    final Map<String, dynamic>? sizeMeasurements,
    this.popularityScore = 0,
    this.salesCount = 0,
    this.weightGrams,
    this.metaTitle,
    this.metaDescription,
    this.createdAt,
    this.updatedAt,
    final Map<String, dynamic>? categories,
    final Map<String, dynamic>? genders,
  }) : _stockBySize = stockBySize,
       _images = images,
       _sizes = sizes,
       _availableSizes = availableSizes,
       _colorIds = colorIds,
       _sizeMeasurements = sizeMeasurements,
       _categories = categories,
       _genders = genders;

  factory _$ProductModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProductModelImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String slug;
  @override
  final String? description;
  @override
  final double price;
  @override
  @JsonKey()
  final int stock;
  final Map<String, int> _stockBySize;
  @override
  @JsonKey()
  Map<String, int> get stockBySize {
    if (_stockBySize is EqualUnmodifiableMapView) return _stockBySize;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_stockBySize);
  }

  @override
  final String? categoryId;
  @override
  final String? genderId;
  final List<String> _images;
  @override
  @JsonKey()
  List<String> get images {
    if (_images is EqualUnmodifiableListView) return _images;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_images);
  }

  final List<String> _sizes;
  @override
  @JsonKey()
  List<String> get sizes {
    if (_sizes is EqualUnmodifiableListView) return _sizes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sizes);
  }

  final List<String> _availableSizes;
  @override
  @JsonKey()
  List<String> get availableSizes {
    if (_availableSizes is EqualUnmodifiableListView) return _availableSizes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_availableSizes);
  }

  @override
  @JsonKey()
  final bool featured;
  @override
  @JsonKey()
  final bool isActive;
  @override
  @JsonKey()
  final bool isNew;
  @override
  @JsonKey()
  final bool isOnSale;
  @override
  @JsonKey()
  final bool isSustainable;
  @override
  final double? salePrice;
  @override
  final String? color;
  final List<String> _colorIds;
  @override
  @JsonKey()
  List<String> get colorIds {
    if (_colorIds is EqualUnmodifiableListView) return _colorIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_colorIds);
  }

  @override
  final String? material;
  @override
  final String? careInstructions;
  @override
  final String? sku;
  final Map<String, dynamic>? _sizeMeasurements;
  @override
  Map<String, dynamic>? get sizeMeasurements {
    final value = _sizeMeasurements;
    if (value == null) return null;
    if (_sizeMeasurements is EqualUnmodifiableMapView) return _sizeMeasurements;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey()
  final int popularityScore;
  @override
  @JsonKey()
  final int salesCount;
  @override
  final int? weightGrams;
  @override
  final String? metaTitle;
  @override
  final String? metaDescription;
  @override
  final String? createdAt;
  @override
  final String? updatedAt;
  // Relaciones embebidas (nullable)
  final Map<String, dynamic>? _categories;
  // Relaciones embebidas (nullable)
  @override
  Map<String, dynamic>? get categories {
    final value = _categories;
    if (value == null) return null;
    if (_categories is EqualUnmodifiableMapView) return _categories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  final Map<String, dynamic>? _genders;
  @override
  Map<String, dynamic>? get genders {
    final value = _genders;
    if (value == null) return null;
    if (_genders is EqualUnmodifiableMapView) return _genders;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'ProductModel(id: $id, name: $name, slug: $slug, description: $description, price: $price, stock: $stock, stockBySize: $stockBySize, categoryId: $categoryId, genderId: $genderId, images: $images, sizes: $sizes, availableSizes: $availableSizes, featured: $featured, isActive: $isActive, isNew: $isNew, isOnSale: $isOnSale, isSustainable: $isSustainable, salePrice: $salePrice, color: $color, colorIds: $colorIds, material: $material, careInstructions: $careInstructions, sku: $sku, sizeMeasurements: $sizeMeasurements, popularityScore: $popularityScore, salesCount: $salesCount, weightGrams: $weightGrams, metaTitle: $metaTitle, metaDescription: $metaDescription, createdAt: $createdAt, updatedAt: $updatedAt, categories: $categories, genders: $genders)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProductModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.stock, stock) || other.stock == stock) &&
            const DeepCollectionEquality().equals(
              other._stockBySize,
              _stockBySize,
            ) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.genderId, genderId) ||
                other.genderId == genderId) &&
            const DeepCollectionEquality().equals(other._images, _images) &&
            const DeepCollectionEquality().equals(other._sizes, _sizes) &&
            const DeepCollectionEquality().equals(
              other._availableSizes,
              _availableSizes,
            ) &&
            (identical(other.featured, featured) ||
                other.featured == featured) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.isNew, isNew) || other.isNew == isNew) &&
            (identical(other.isOnSale, isOnSale) ||
                other.isOnSale == isOnSale) &&
            (identical(other.isSustainable, isSustainable) ||
                other.isSustainable == isSustainable) &&
            (identical(other.salePrice, salePrice) ||
                other.salePrice == salePrice) &&
            (identical(other.color, color) || other.color == color) &&
            const DeepCollectionEquality().equals(other._colorIds, _colorIds) &&
            (identical(other.material, material) ||
                other.material == material) &&
            (identical(other.careInstructions, careInstructions) ||
                other.careInstructions == careInstructions) &&
            (identical(other.sku, sku) || other.sku == sku) &&
            const DeepCollectionEquality().equals(
              other._sizeMeasurements,
              _sizeMeasurements,
            ) &&
            (identical(other.popularityScore, popularityScore) ||
                other.popularityScore == popularityScore) &&
            (identical(other.salesCount, salesCount) ||
                other.salesCount == salesCount) &&
            (identical(other.weightGrams, weightGrams) ||
                other.weightGrams == weightGrams) &&
            (identical(other.metaTitle, metaTitle) ||
                other.metaTitle == metaTitle) &&
            (identical(other.metaDescription, metaDescription) ||
                other.metaDescription == metaDescription) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality().equals(
              other._categories,
              _categories,
            ) &&
            const DeepCollectionEquality().equals(other._genders, _genders));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    name,
    slug,
    description,
    price,
    stock,
    const DeepCollectionEquality().hash(_stockBySize),
    categoryId,
    genderId,
    const DeepCollectionEquality().hash(_images),
    const DeepCollectionEquality().hash(_sizes),
    const DeepCollectionEquality().hash(_availableSizes),
    featured,
    isActive,
    isNew,
    isOnSale,
    isSustainable,
    salePrice,
    color,
    const DeepCollectionEquality().hash(_colorIds),
    material,
    careInstructions,
    sku,
    const DeepCollectionEquality().hash(_sizeMeasurements),
    popularityScore,
    salesCount,
    weightGrams,
    metaTitle,
    metaDescription,
    createdAt,
    updatedAt,
    const DeepCollectionEquality().hash(_categories),
    const DeepCollectionEquality().hash(_genders),
  ]);

  /// Create a copy of ProductModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProductModelImplCopyWith<_$ProductModelImpl> get copyWith =>
      __$$ProductModelImplCopyWithImpl<_$ProductModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProductModelImplToJson(this);
  }
}

abstract class _ProductModel implements ProductModel {
  const factory _ProductModel({
    required final String id,
    required final String name,
    required final String slug,
    final String? description,
    required final double price,
    final int stock,
    final Map<String, int> stockBySize,
    final String? categoryId,
    final String? genderId,
    final List<String> images,
    final List<String> sizes,
    final List<String> availableSizes,
    final bool featured,
    final bool isActive,
    final bool isNew,
    final bool isOnSale,
    final bool isSustainable,
    final double? salePrice,
    final String? color,
    final List<String> colorIds,
    final String? material,
    final String? careInstructions,
    final String? sku,
    final Map<String, dynamic>? sizeMeasurements,
    final int popularityScore,
    final int salesCount,
    final int? weightGrams,
    final String? metaTitle,
    final String? metaDescription,
    final String? createdAt,
    final String? updatedAt,
    final Map<String, dynamic>? categories,
    final Map<String, dynamic>? genders,
  }) = _$ProductModelImpl;

  factory _ProductModel.fromJson(Map<String, dynamic> json) =
      _$ProductModelImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get slug;
  @override
  String? get description;
  @override
  double get price;
  @override
  int get stock;
  @override
  Map<String, int> get stockBySize;
  @override
  String? get categoryId;
  @override
  String? get genderId;
  @override
  List<String> get images;
  @override
  List<String> get sizes;
  @override
  List<String> get availableSizes;
  @override
  bool get featured;
  @override
  bool get isActive;
  @override
  bool get isNew;
  @override
  bool get isOnSale;
  @override
  bool get isSustainable;
  @override
  double? get salePrice;
  @override
  String? get color;
  @override
  List<String> get colorIds;
  @override
  String? get material;
  @override
  String? get careInstructions;
  @override
  String? get sku;
  @override
  Map<String, dynamic>? get sizeMeasurements;
  @override
  int get popularityScore;
  @override
  int get salesCount;
  @override
  int? get weightGrams;
  @override
  String? get metaTitle;
  @override
  String? get metaDescription;
  @override
  String? get createdAt;
  @override
  String? get updatedAt; // Relaciones embebidas (nullable)
  @override
  Map<String, dynamic>? get categories;
  @override
  Map<String, dynamic>? get genders;

  /// Create a copy of ProductModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProductModelImplCopyWith<_$ProductModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
