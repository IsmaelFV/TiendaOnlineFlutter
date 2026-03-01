import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../shared/widgets/animations.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../data/models/product_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/gender_model.dart';
import '../providers/products_provider.dart';
import '../widgets/product_card.dart';

// ─────────────────────────────────────────────────────────────
//  Tallas y colores predefinidos para filtros
// ─────────────────────────────────────────────────────────────
const List<String> _kClothingSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
const List<String> _kShoeSizes = [
  '36',
  '37',
  '38',
  '39',
  '40',
  '41',
  '42',
  '43',
  '44',
  '45',
];
const List<_FilterColor> _kColors = [
  _FilterColor('Negro', Color(0xFF1A1A1A)),
  _FilterColor('Blanco', Color(0xFFF5F5F5)),
  _FilterColor('Rojo', Color(0xFFE53935)),
  _FilterColor('Azul', Color(0xFF1E88E5)),
  _FilterColor('Azul Marino', Color(0xFF1A237E)),
  _FilterColor('Verde', Color(0xFF43A047)),
  _FilterColor('Rosa', Color(0xFFEC407A)),
  _FilterColor('Gris', Color(0xFF9E9E9E)),
  _FilterColor('Marrón', Color(0xFF795548)),
  _FilterColor('Beige', Color(0xFFD7CCC8)),
  _FilterColor('Naranja', Color(0xFFFF9800)),
  _FilterColor('Morado', Color(0xFF7B1FA2)),
  _FilterColor('Burdeos', Color(0xFF880E4F)),
  _FilterColor('Dorado', Color(0xFFD4AF37)),
];

class _FilterColor {
  final String name;
  final Color value;
  const _FilterColor(this.name, this.value);
}

class ProductListScreen extends ConsumerStatefulWidget {
  final String? initialGenderId;
  final String? initialCategoryId;
  final bool? initialIsNew;
  final bool? initialIsOnSale;

  const ProductListScreen({
    super.key,
    this.initialGenderId,
    this.initialCategoryId,
    this.initialIsNew,
    this.initialIsOnSale,
  });

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  ProductsFilter _filter = const ProductsFilter();
  final List<ProductModel> _allProducts = [];
  final Set<String> _seenIds = {}; // Para evitar duplicados
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _initialLoaded = false;
  bool _initialError = false;
  String _errorMessage = '';

  // Categorías y géneros
  String? _selectedCategoryId;
  String? _selectedGenderId;
  List<CategoryModel> _categories = [];
  List<GenderModel> _genders = [];

  /// Devuelve categorías sin duplicados por nombre.
  /// Cuando genderId == null (Todos), agrupa por nombre y queda uno solo.
  List<CategoryModel> _deduplicatedCats({String? genderId}) {
    final filtered = genderId == null
        ? _categories
        : _categories.where((c) => c.genderId == genderId).toList();
    final seen = <String>{};
    final result = <CategoryModel>[];
    for (final cat in filtered) {
      // Excluir categorías "Novedades" y "Rebajas" (se acceden por etiquetas)
      final lower = cat.name.toLowerCase();
      if (lower.contains('novedades') || lower.contains('rebajas')) continue;
      if (!seen.contains(cat.name)) {
        seen.add(cat.name);
        result.add(cat);
      }
    }
    return result;
  }

  /// Dado un categoryId, devuelve todos los IDs con el mismo nombre.
  List<String> _allIdsForCategoryName(String categoryId) {
    final cat = _categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => _categories.first,
    );
    return _categories
        .where((c) => c.name == cat.name)
        .map((c) => c.id)
        .toList();
  }

  // Filtros locales (no van al backend)
  String? _selectedSize;
  String? _selectedColor;

  // Animaciones
  late final AnimationController _headerAnimController;
  late final AnimationController _gridAnimController;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Aplicar filtros iniciales de query params
    if (widget.initialGenderId != null) {
      _selectedGenderId = widget.initialGenderId;
      _filter = _filter.copyWith(genderId: widget.initialGenderId);
    }
    if (widget.initialCategoryId != null) {
      _selectedCategoryId = widget.initialCategoryId;
      _filter = _filter.copyWith(categoryId: widget.initialCategoryId);
    }
    if (widget.initialIsNew == true) {
      _filter = _filter.copyWith(isNew: true);
    }
    if (widget.initialIsOnSale == true) {
      _filter = _filter.copyWith(isOnSale: true);
    }

    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _gridAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _headerAnimController.forward();
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _headerAnimController.dispose();
    _gridAnimController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        _hasMore &&
        !_isLoadingMore) {
      _loadMore();
    }
  }

  /// Añade productos sin duplicados
  void _addProductsNoDuplicates(List<ProductModel> products) {
    for (final p in products) {
      if (_seenIds.add(p.id)) {
        _allProducts.add(p);
      }
    }
  }

  /// Productos filtrados por talla/color (filtrado local)
  List<ProductModel> get _filteredProducts {
    var list = _allProducts;
    if (_selectedSize != null) {
      list = list
          .where(
            (p) =>
                p.sizes.any(
                  (s) => s.toUpperCase() == _selectedSize!.toUpperCase(),
                ) ||
                p.availableSizes.any(
                  (s) => s.toUpperCase() == _selectedSize!.toUpperCase(),
                ),
          )
          .toList();
    }
    if (_selectedColor != null) {
      list = list
          .where(
            (p) =>
                p.color != null &&
                p.color!.toLowerCase().trim() ==
                    _selectedColor!.toLowerCase().trim(),
          )
          .toList();
    }
    return list;
  }

  Future<void> _loadInitialData() async {
    try {
      final repo = ref.read(productsRepositoryProvider);
      final result = await repo.getProducts(
        page: _filter.page,
        limit: _filter.limit,
        categoryId: _filter.categoryId,
        categoryIds: _filter.categoryIds,
        genderId: _filter.genderId,
        sortBy: _filter.sortBy,
        ascending: _filter.ascending,
        minPrice: _filter.minPrice,
        maxPrice: _filter.maxPrice,
        isOnSale: _filter.isOnSale,
        isNew: _filter.isNew,
        featured: _filter.featured,
      );

      result.fold(
        (failure) {
          if (mounted) {
            setState(() {
              _initialError = true;
              _errorMessage = failure.userMessage;
            });
          }
        },
        (products) {
          if (mounted) {
            setState(() {
              _addProductsNoDuplicates(products);
              _initialLoaded = true;
              _initialError = false;
              if (products.length < _filter.limit) _hasMore = false;
            });
            _gridAnimController.forward();
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _initialError = true;
          _errorMessage = 'Error al cargar productos';
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    final nextFilter = _filter.copyWith(page: _filter.page + 1);
    final repo = ref.read(productsRepositoryProvider);
    final result = await repo.getProducts(
      page: nextFilter.page,
      limit: nextFilter.limit,
      categoryId: nextFilter.categoryId,
      categoryIds: nextFilter.categoryIds,
      genderId: nextFilter.genderId,
      sortBy: nextFilter.sortBy,
      ascending: nextFilter.ascending,
      minPrice: nextFilter.minPrice,
      maxPrice: nextFilter.maxPrice,
      isOnSale: nextFilter.isOnSale,
      isNew: nextFilter.isNew,
      featured: nextFilter.featured,
    );

    result.fold((_) {}, (products) {
      if (products.isEmpty || products.length < _filter.limit) {
        _hasMore = false;
      }
      setState(() {
        _addProductsNoDuplicates(products);
        _filter = nextFilter;
      });
    });

    setState(() => _isLoadingMore = false);
  }

  /// Refresco completo al cambiar filtros de backend
  Future<void> _applyFilters() async {
    // Calcular categoryIds cuando hay categoría seleccionada sin género
    List<String>? catIds;
    if (_selectedCategoryId != null && _selectedGenderId == null) {
      catIds = _allIdsForCategoryName(_selectedCategoryId!);
      if (catIds.length <= 1) catIds = null; // usar categoryId simple
    }

    setState(() {
      _allProducts.clear();
      _seenIds.clear();
      _hasMore = true;
      _initialLoaded = false;
      _initialError = false;
      _filter = ProductsFilter(
        page: 1,
        limit: _filter.limit,
        categoryId: catIds != null ? null : _selectedCategoryId,
        categoryIds: catIds,
        genderId: _selectedGenderId,
        sortBy: _filter.sortBy,
        ascending: _filter.ascending,
        minPrice: _filter.minPrice,
        maxPrice: _filter.maxPrice,
        isOnSale: _filter.isOnSale,
        isNew: _filter.isNew,
        featured: _filter.featured,
      );
    });
    _gridAnimController.reset();
    await _loadInitialData();
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _allProducts.clear();
      _seenIds.clear();
      _hasMore = true;
      _initialLoaded = false;
      _initialError = false;
      _filter = _filter.copyWith(page: 1);
    });
    _gridAnimController.reset();
    await _loadInitialData();
  }

  int get _activeFilterCount {
    int count = 0;
    if (_filter.isOnSale == true) count++;
    if (_filter.isNew == true) count++;
    if (_filter.featured == true) count++;
    if (_filter.sortBy != null) count++;
    if (_selectedGenderId != null) count++;
    if (_selectedCategoryId != null) count++;
    if (_selectedSize != null) count++;
    if (_selectedColor != null) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    categoriesAsync.whenData((cats) {
      if (_categories.isEmpty && cats.isNotEmpty) {
        _categories = cats;
      }
    });

    final gendersAsync = ref.watch(gendersProvider);
    gendersAsync.whenData((g) {
      if (_genders.isEmpty && g.isNotEmpty) {
        _genders = g;
      }
    });

    final headerAnims = createStaggerAnimations(
      controller: _headerAnimController,
      count: 3,
      delayPerItem: 0.15,
      itemDuration: 0.45,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(headerAnims),
          // Barra de género (Mujer / Hombre / Todo)
          SliverToBoxAdapter(
            child: FadeSlideItem(
              index: 1,
              animation: headerAnims.length > 1
                  ? headerAnims[1]
                  : _headerAnimController,
              child: _buildGenderBar(),
            ),
          ),
          // Barra de categorías (deduplicada según género)
          if (_categories.isNotEmpty)
            SliverToBoxAdapter(
              child: FadeSlideItem(
                index: 1,
                animation: headerAnims.length > 1
                    ? headerAnims[1]
                    : _headerAnimController,
                child: _buildCategoriesBar(),
              ),
            ),
          SliverToBoxAdapter(
            child: FadeSlideItem(
              index: 2,
              animation: headerAnims.length > 2
                  ? headerAnims[2]
                  : _headerAnimController,
              child: _buildActiveFiltersRow(),
            ),
          ),
        ],
        body: _buildBody(),
      ),
    );
  }

  Widget _buildSliverAppBar(List<Animation<double>> anims) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      title: FadeSlideItem(
        index: 0,
        animation: anims.isNotEmpty ? anims[0] : _headerAnimController,
        child: ShimmerText(
          text: 'Tienda',
          style: AppTextStyles.h4.copyWith(fontSize: 22),
        ),
      ),
      centerTitle: true,
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const GoldIcon(icon: Icons.tune_rounded, size: 22),
              onPressed: () => _showFilters(context),
              tooltip: 'Filtros',
            ),
            if (_activeFilterCount > 0)
              Positioned(
                top: 8,
                right: 6,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$_activeFilterCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  //  BARRA DE GÉNERO (Mujer / Hombre / Todo)
  // ─────────────────────────────────────────────────────────
  Widget _buildGenderBar() {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // "Todo" primero
          _buildGenderTabChip(
            null,
            'Todo',
            Icons.apps_rounded,
            _selectedGenderId == null,
          ),
          // Géneros desde el provider (sin Unisex)
          ..._genders
              .where((g) => !g.name.toLowerCase().contains('unisex'))
              .map((g) {
                return _buildGenderTabChip(
                  g.id,
                  g.name,
                  _genderIcon(g.name),
                  _selectedGenderId == g.id,
                );
              }),
        ],
      ),
    );
  }

  Widget _buildGenderTabChip(
    String? genderId,
    String label,
    IconData icon,
    bool isActive,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedGenderId = genderId;
            _selectedCategoryId = null;
          });
          _applyFilters();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.gold500.withValues(alpha: 0.18)
                : AppColors.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isActive
                  ? AppColors.gold500.withValues(alpha: 0.5)
                  : AppColors.border.withValues(alpha: 0.15),
              width: isActive ? 1.5 : 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.gold500.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 17,
                color: isActive ? AppColors.gold500 : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? AppColors.gold500 : AppColors.textSecondary,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesBar() {
    final displayCats = _deduplicatedCats(genderId: _selectedGenderId);

    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: displayCats.length + 1,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final cat = isAll ? null : displayCats[index - 1];
          // Verificar selección por nombre (para deduplicados)
          final isSelected = isAll
              ? _selectedCategoryId == null
              : _selectedCategoryId != null &&
                    _categories
                            .firstWhere(
                              (c) => c.id == _selectedCategoryId,
                              orElse: () => _categories.first,
                            )
                            .name ==
                        cat!.name;
          final label = isAll ? 'Todas' : cat!.name;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedCategoryId = isAll ? null : cat!.id;
                  _filter = _filter.copyWith(categoryId: _selectedCategoryId);
                });
                _applyFilters();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.gold500 : AppColors.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.gold500
                        : AppColors.border.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.gold500.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.background
                        : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveFiltersRow() {
    final List<_ActiveFilter> active = [];
    if (_filter.isOnSale == true) {
      active.add(
        _ActiveFilter('En oferta', Icons.local_offer_rounded, () {
          setState(() => _filter = _filter.copyWith(isOnSale: null));
          _applyFilters();
        }),
      );
    }
    if (_filter.isNew == true) {
      active.add(
        _ActiveFilter('Nuevos', Icons.fiber_new_rounded, () {
          setState(() => _filter = _filter.copyWith(isNew: null));
          _applyFilters();
        }),
      );
    }
    if (_filter.featured == true) {
      active.add(
        _ActiveFilter('Destacados', Icons.star_rounded, () {
          setState(() => _filter = _filter.copyWith(featured: null));
          _applyFilters();
        }),
      );
    }
    if (_filter.sortBy != null) {
      String sortLabel = 'Ordenado';
      if (_filter.sortBy == 'price') {
        sortLabel = _filter.ascending ? 'Precio ↑' : 'Precio ↓';
      } else if (_filter.sortBy == 'popularity_score') {
        sortLabel = 'Popular';
      } else if (_filter.sortBy == 'created_at') {
        sortLabel = 'Recientes';
      }
      active.add(
        _ActiveFilter(sortLabel, Icons.sort_rounded, () {
          setState(
            () => _filter = _filter.copyWith(sortBy: null, ascending: false),
          );
          _applyFilters();
        }),
      );
    }
    if (_selectedGenderId != null) {
      String genderName = 'Género';
      for (final p in _allProducts) {
        if (p.genderId == _selectedGenderId && p.genders != null) {
          genderName = (p.genders!['name'] as String?) ?? 'Género';
          break;
        }
      }
      active.add(
        _ActiveFilter(genderName, Icons.person_rounded, () {
          setState(() {
            _selectedGenderId = null;
            _selectedCategoryId = null;
            _filter = _filter.copyWith(genderId: null, categoryId: null);
          });
          _applyFilters();
        }),
      );
    }
    if (_selectedCategoryId != null) {
      final catName =
          _categories
              .where((c) => c.id == _selectedCategoryId)
              .map((c) => c.name)
              .firstOrNull ??
          'Categoría';
      active.add(
        _ActiveFilter(catName, Icons.category_rounded, () {
          setState(() {
            _selectedCategoryId = null;
            _filter = _filter.copyWith(categoryId: null);
          });
          _applyFilters();
        }),
      );
    }
    if (_selectedSize != null) {
      active.add(
        _ActiveFilter('Talla: $_selectedSize', Icons.straighten_rounded, () {
          setState(() => _selectedSize = null);
        }),
      );
    }
    if (_selectedColor != null) {
      active.add(
        _ActiveFilter('Color: $_selectedColor', Icons.palette_rounded, () {
          setState(() => _selectedColor = null);
        }),
      );
    }

    if (active.isEmpty) return const SizedBox.shrink();

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (int i = 0; i < active.length; i++) ...[
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 300 + (i * 60)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(15 * (1 - value), 0),
                        child: child,
                      ),
                    );
                  },
                  child: _buildRemovableChip(
                    active[i].label,
                    active[i].icon,
                    active[i].onRemove,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              _buildClearAllChip(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRemovableChip(
    String label,
    IconData icon,
    VoidCallback onRemove,
  ) {
    return Container(
      padding: const EdgeInsets.only(left: 8, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.gold500.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold500.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.gold400),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.gold400,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onRemove();
            },
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.gold500.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 11,
                color: AppColors.gold300,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClearAllChip() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedCategoryId = null;
          _selectedGenderId = null;
          _selectedSize = null;
          _selectedColor = null;
          _filter = const ProductsFilter();
        });
        _applyFilters();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.clear_all_rounded, size: 13, color: AppColors.error),
            SizedBox(width: 4),
            Text(
              'Limpiar',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_initialError) {
      return AppErrorWidget(message: _errorMessage, onRetry: _onRefresh);
    }

    if (!_initialLoaded) {
      return _buildSkeletonGrid();
    }

    final products = _filteredProducts;

    if (products.isEmpty) {
      return AnimatedEmptyState(
        icon: Icons.storefront_outlined,
        title: 'No se encontraron productos',
        subtitle: _activeFilterCount > 0
            ? 'Prueba con filtros diferentes o limpia los actuales'
            : 'Todavía no hay productos disponibles',
        buttonText: _activeFilterCount > 0 ? 'Limpiar filtros' : null,
        onAction: _activeFilterCount > 0
            ? () {
                setState(() {
                  _selectedCategoryId = null;
                  _selectedGenderId = null;
                  _selectedSize = null;
                  _selectedColor = null;
                  _filter = const ProductsFilter();
                });
                _applyFilters();
              }
            : null,
      );
    }

    final gridAnims = createStaggerAnimations(
      controller: _gridAnimController,
      count: products.length.clamp(0, 12),
      delayPerItem: 0.06,
      itemDuration: 0.25,
    );

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.gold500,
      backgroundColor: AppColors.surface,
      child: CustomScrollView(
        slivers: [
          // Barra de conteo + ordenar
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            sliver: SliverToBoxAdapter(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) {
                          return FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.3),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          '${products.length}${_hasMore ? '+' : ''} productos',
                          key: ValueKey(products.length),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _showFilters(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.gold500.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const GoldIcon(icon: Icons.sort_rounded, size: 14),
                            const SizedBox(width: 5),
                            Text(
                              'Ordenar',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.gold500,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Grid de productos
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.50,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final card = ProductCard(
                  product: products[index],
                  index: index,
                );

                if (index < gridAnims.length) {
                  return FadeSlideItem(
                    index: index,
                    animation: gridAnims[index],
                    slideOffset: 40,
                    child: card,
                  );
                }
                return ScaleFadeIn(
                  delay: Duration(milliseconds: 50 * (index % 4)),
                  duration: const Duration(milliseconds: 350),
                  child: card,
                );
              }, childCount: products.length),
            ),
          ),

          // Loader al final
          if (_hasMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: BouncingDotsLoader()),
              ),
            ),

          // Fin de resultados
          if (!_hasMore && products.isNotEmpty)
            SliverToBoxAdapter(
              child: ScaleFadeIn(
                delay: const Duration(milliseconds: 200),
                duration: const Duration(milliseconds: 500),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: child,
                              );
                            },
                            child: Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: AppColors.accentEmerald.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Has visto todos los productos',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSkeletonGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.50,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return ScaleFadeIn(
          delay: Duration(milliseconds: 80 * index),
          child: const _SkeletonCard(),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Filtros Bottom Sheet — organizado por secciones con tabs
  // ─────────────────────────────────────────────────────────────
  void _showFilters(BuildContext context) {
    ProductsFilter tempFilter = _filter;
    String? tempGenderId = _selectedGenderId;
    String? tempCategoryId = _selectedCategoryId;
    String? tempSize = _selectedSize;
    String? tempColor = _selectedColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: DraggableScrollableSheet(
                initialChildSize: 0.75,
                minChildSize: 0.45,
                maxChildSize: 0.92,
                expand: false,
                builder: (_, scrollCtrl) {
                  return Column(
                    children: [
                      // Handle + Header (fijo arriba)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 16, 0),
                        child: Column(
                          children: [
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: AppColors.textMuted.withValues(
                                    alpha: 0.3,
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                const GoldIcon(
                                  icon: Icons.tune_rounded,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Filtros y orden',
                                  style: AppTextStyles.h4.copyWith(
                                    fontSize: 18,
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () {
                                    setModalState(() {
                                      tempFilter = const ProductsFilter();
                                      tempGenderId = null;
                                      tempCategoryId = null;
                                      tempSize = null;
                                      tempColor = null;
                                    });
                                  },
                                  child: const Text(
                                    'Resetear',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: AppColors.divider, height: 20),
                          ],
                        ),
                      ),

                      // Contenido scrollable
                      Expanded(
                        child: ListView(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                          children: [
                            // ═══ ORDENAR POR ═══
                            _animatedFilterSection(
                              0,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _filterSectionHeader(
                                    'Ordenar por',
                                    Icons.swap_vert_rounded,
                                  ),
                                  const SizedBox(height: 10),
                                  _buildSortGrid(
                                    tempFilter,
                                    (f) => setModalState(() => tempFilter = f),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),

                            // ═══ GÉNERO Y CATEGORÍA ═══
                            if (_categories.isNotEmpty) ...[
                              _animatedFilterSection(
                                1,
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _filterSectionHeader(
                                      'Género',
                                      Icons.people_rounded,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildGenderToggle(
                                      tempGenderId,
                                      (id) => setModalState(() {
                                        tempGenderId = id;
                                        tempCategoryId = null;
                                      }),
                                    ),
                                    const SizedBox(height: 18),
                                    _filterSectionHeader(
                                      'Categoría',
                                      Icons.category_rounded,
                                    ),
                                    const SizedBox(height: 10),
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 350,
                                      ),
                                      switchInCurve: Curves.easeOutCubic,
                                      switchOutCurve: Curves.easeInCubic,
                                      transitionBuilder: (child, anim) {
                                        return FadeTransition(
                                          opacity: anim,
                                          child: SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(0.05, 0),
                                              end: Offset.zero,
                                            ).animate(anim),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: _buildSubcategoryChips(
                                        key: ValueKey(tempGenderId),
                                        genderId: tempGenderId,
                                        selectedCategoryId: tempCategoryId,
                                        onSelect: (id) {
                                          setModalState(
                                            () => tempCategoryId = id,
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              ),
                            ],

                            // ═══ TALLA ═══
                            _animatedFilterSection(
                              2,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _filterSectionHeader(
                                    'Talla',
                                    Icons.straighten_rounded,
                                  ),
                                  const SizedBox(height: 10),
                                  _buildSizeGrid(
                                    tempSize,
                                    (s) => setModalState(() => tempSize = s),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),

                            // ═══ COLOR ═══
                            _animatedFilterSection(
                              3,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _filterSectionHeader(
                                    'Color',
                                    Icons.palette_rounded,
                                  ),
                                  const SizedBox(height: 10),
                                  _buildColorGrid(
                                    tempColor,
                                    (c) => setModalState(() => tempColor = c),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),

                            // ═══ ETIQUETAS ═══
                            _animatedFilterSection(
                              4,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _filterSectionHeader(
                                    'Etiquetas',
                                    Icons.label_rounded,
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      _buildLabelChip(
                                        'En oferta',
                                        Icons.local_offer_rounded,
                                        AppColors.error,
                                        tempFilter.isOnSale == true,
                                        (val) => setModalState(() {
                                          tempFilter = tempFilter.copyWith(
                                            isOnSale: val ? true : null,
                                          );
                                        }),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildLabelChip(
                                        'Nuevos',
                                        Icons.fiber_new_rounded,
                                        AppColors.gold500,
                                        tempFilter.isNew == true,
                                        (val) => setModalState(() {
                                          tempFilter = tempFilter.copyWith(
                                            isNew: val ? true : null,
                                          );
                                        }),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildLabelChip(
                                        'Destacados',
                                        Icons.star_rounded,
                                        AppColors.accentEmerald,
                                        tempFilter.featured == true,
                                        (val) => setModalState(() {
                                          tempFilter = tempFilter.copyWith(
                                            featured: val ? true : null,
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 28),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Botón aplicar (fijo abajo)
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border(
                            top: BorderSide(color: AppColors.divider, width: 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Conteo de filtros activos
                            _buildFilterCountPreview(
                              tempFilter,
                              tempGenderId,
                              tempCategoryId,
                              tempSize,
                              tempColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    _selectedGenderId = tempGenderId;
                                    _selectedCategoryId = tempCategoryId;
                                    _selectedSize = tempSize;
                                    _selectedColor = tempColor;
                                    _filter = tempFilter;
                                  });
                                  _applyFilters();
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'APLICAR FILTROS',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  /// Envuelve una sección del filtro con animación de entrada escalonada
  Widget _animatedFilterSection(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 450 + (index * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildFilterCountPreview(
    ProductsFilter f,
    String? gender,
    String? cat,
    String? size,
    String? color,
  ) {
    int count = 0;
    if (f.isOnSale == true) count++;
    if (f.isNew == true) count++;
    if (f.featured == true) count++;
    if (f.sortBy != null) count++;
    if (gender != null) count++;
    if (cat != null) count++;
    if (size != null) count++;
    if (color != null) count++;
    if (count == 0) return const SizedBox.shrink();
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.gold500.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gold500.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(
          '$count',
          style: const TextStyle(
            color: AppColors.gold400,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _filterSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.gold500.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  /// Grid de opciones de orden (2 columnas)
  Widget _buildSortGrid(
    ProductsFilter current,
    ValueChanged<ProductsFilter> onChanged,
  ) {
    final options = [
      ('Recientes', Icons.schedule_rounded, 'created_at', false),
      (
        'Popular',
        Icons.local_fire_department_rounded,
        'popularity_score',
        false,
      ),
      ('Precio ↑', Icons.trending_up_rounded, 'price', true),
      ('Precio ↓', Icons.trending_down_rounded, 'price', false),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isActive =
            current.sortBy == opt.$3 && current.ascending == opt.$4;
        return GestureDetector(
          onTap: () {
            if (isActive) {
              onChanged(current.copyWith(sortBy: null, ascending: false));
            } else {
              onChanged(current.copyWith(sortBy: opt.$3, ascending: opt.$4));
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.gold500.withValues(alpha: 0.18)
                  : AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? AppColors.gold500.withValues(alpha: 0.5)
                    : AppColors.border.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  opt.$2,
                  size: 15,
                  color: isActive ? AppColors.gold400 : AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  opt.$1,
                  style: TextStyle(
                    color: isActive
                        ? AppColors.gold400
                        : AppColors.textSecondary,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Grid de tallas agrupadas (Ropa / Calzado)
  Widget _buildSizeGrid(String? current, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Ropa ──
        _buildSizeSubgroup(
          label: 'Ropa',
          icon: Icons.checkroom_rounded,
          sizes: _kClothingSizes,
          current: current,
          onChanged: onChanged,
        ),
        const SizedBox(height: 14),
        // ── Calzado ──
        _buildSizeSubgroup(
          label: 'Calzado',
          icon: Icons.ice_skating_rounded,
          sizes: _kShoeSizes,
          current: current,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSizeSubgroup({
    required String label,
    required IconData icon,
    required List<String> sizes,
    required String? current,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: AppColors.textMuted.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: sizes.map((size) {
              final isActive = current == size;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(isActive ? null : size);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  constraints: const BoxConstraints(minWidth: 44),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.gold500.withValues(alpha: 0.18)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isActive
                          ? AppColors.gold500.withValues(alpha: 0.5)
                          : AppColors.border.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      size,
                      style: TextStyle(
                        color: isActive
                            ? AppColors.gold400
                            : AppColors.textSecondary,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Grid de colores — círculos grandes con nombre debajo
  Widget _buildColorGrid(String? current, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.08)),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 14,
        alignment: WrapAlignment.center,
        children: _kColors.map((fc) {
          final isActive =
              current?.toLowerCase().trim() == fc.name.toLowerCase().trim();
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(isActive ? null : fc.name);
            },
            child: SizedBox(
              width: 56,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Círculo de color
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: fc.value,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive
                            ? Colors.white.withValues(alpha: 0.9)
                            : Colors.white.withValues(alpha: 0.15),
                        width: isActive ? 2.5 : 1,
                      ),
                      boxShadow: [
                        if (isActive)
                          BoxShadow(
                            color: fc.value.withValues(alpha: 0.6),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        BoxShadow(
                          color: fc.value.withValues(alpha: 0.25),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: isActive
                        ? Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: _contrastIconColor(fc.value),
                          )
                        : null,
                  ),
                  const SizedBox(height: 5),
                  // Nombre
                  Text(
                    fc.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isActive
                          ? AppColors.textPrimary
                          : AppColors.textMuted.withValues(alpha: 0.7),
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Devuelve blanco o negro según luminosidad del color
  Color _contrastIconColor(Color c) {
    final luminance = c.computeLuminance();
    return luminance > 0.4 ? Colors.black87 : Colors.white;
  }

  Widget _buildLabelChip(
    String label,
    IconData icon,
    Color accentColor,
    bool isActive,
    ValueChanged<bool> onChanged,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!isActive);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive
                ? accentColor.withValues(alpha: 0.12)
                : AppColors.card.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? accentColor.withValues(alpha: 0.4)
                  : AppColors.border.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isActive
                      ? accentColor.withValues(alpha: 0.2)
                      : AppColors.background,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive
                        ? accentColor.withValues(alpha: 0.5)
                        : AppColors.border.withValues(alpha: 0.1),
                  ),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isActive ? accentColor : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? accentColor : AppColors.textSecondary,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Género → Subcategoría
  // ─────────────────────────────────────────────────────────────

  IconData _genderIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('mujer') ||
        lower.contains('woman') ||
        lower.contains('female')) {
      return Icons.female_rounded;
    }
    if (lower.contains('hombre') ||
        lower.contains('man') ||
        lower.contains('male')) {
      return Icons.male_rounded;
    }
    return Icons.people_rounded;
  }

  Widget _buildGenderToggle(
    String? selectedId,
    ValueChanged<String?> onSelect,
  ) {
    // Construir lista: [Todo, ...géneros del provider (sin Unisex)]
    final items = <({String? id, String label, IconData icon})>[
      (id: null, label: 'Todo', icon: Icons.apps_rounded),
      ..._genders
          .where((g) => !g.name.toLowerCase().contains('unisex'))
          .map((g) => (id: g.id, label: g.name, icon: _genderIcon(g.name))),
    ];

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: items.map((item) {
          final isActive = item.id == selectedId;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onSelect(item.id);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.gold500.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  border: isActive
                      ? Border.all(
                          color: AppColors.gold500.withValues(alpha: 0.4),
                        )
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      size: 16,
                      color: isActive ? AppColors.gold400 : AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.label,
                      style: TextStyle(
                        color: isActive
                            ? AppColors.gold400
                            : AppColors.textSecondary,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Categorías organizadas por grupo padre con diseño limpio
  Widget _buildSubcategoryChips({
    Key? key,
    String? genderId,
    String? selectedCategoryId,
    required ValueChanged<String?> onSelect,
  }) {
    final displayCats = _deduplicatedCats(genderId: genderId);

    if (displayCats.isEmpty) {
      return Container(
        key: key,
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.category_outlined,
                size: 28,
                color: AppColors.textMuted.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 8),
              Text(
                'No hay categorías',
                style: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Verificar selección comparando por nombre (deduplicado)
    final selectedName = selectedCategoryId != null
        ? _categories
              .where((c) => c.id == selectedCategoryId)
              .map((c) => c.name)
              .firstOrNull
        : null;

    // Agrupar categorías: raíz (level 1, parentId == null) con sus hijas
    final rootCats = displayCats
        .where((c) => c.parentId == null || c.level == 1)
        .toList();
    final leafCats = displayCats
        .where((c) => c.parentId != null && c.level != 1)
        .toList();

    // Construir grupos: padre → [hijas]
    final groups = <CategoryModel, List<CategoryModel>>{};
    for (final root in rootCats) {
      // Buscar hijas que pertenezcan a esta raíz (por parentId directo
      // o por parentId que apunte a alguna categoría del mismo nombre)
      final rootIds = _categories
          .where((c) => c.name == root.name)
          .map((c) => c.id)
          .toSet();
      final children = leafCats
          .where((c) => rootIds.contains(c.parentId))
          .toList();
      groups[root] = children;
    }

    // Huérfanas: hijas sin padre en la lista
    final orphans = leafCats.where((c) {
      return !groups.values.any((list) => list.contains(c));
    }).toList();

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chip "Todas" siempre primero
        _buildCategoryFilterChip(
          label: 'Todas',
          icon: Icons.grid_view_rounded,
          isActive: selectedCategoryId == null,
          onTap: () => onSelect(null),
        ),
        const SizedBox(height: 12),

        // Grupos expandibles
        ...groups.entries.where((e) => e.value.isNotEmpty).map((entry) {
          final parent = entry.key;
          final children = entry.value;
          final isParentActive = selectedName == parent.name;
          final anyChildActive = children.any((c) => c.name == selectedName);

          return _buildCategoryGroup(
            parent: parent,
            children: children,
            selectedName: selectedName,
            isParentActive: isParentActive,
            isExpanded: isParentActive || anyChildActive,
            onSelectParent: () => onSelect(parent.id),
            onSelectChild: (id) => onSelect(id),
          );
        }),

        // Raíz sin hijas (categorías simples)
        if (groups.entries.any((e) => e.value.isEmpty)) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: groups.entries.where((e) => e.value.isEmpty).map((e) {
              final cat = e.key;
              final isActive = selectedName == cat.name;
              return _buildCategoryFilterChip(
                label: cat.name,
                isActive: isActive,
                onTap: () => onSelect(isActive ? null : cat.id),
              );
            }).toList(),
          ),
        ],

        // Huérfanas
        if (orphans.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: orphans.map((cat) {
              final isActive = selectedName == cat.name;
              return _buildCategoryFilterChip(
                label: cat.name,
                isActive: isActive,
                onTap: () => onSelect(isActive ? null : cat.id),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  /// Grupo de categoría expandible (padre + hijas)
  Widget _buildCategoryGroup({
    required CategoryModel parent,
    required List<CategoryModel> children,
    required String? selectedName,
    required bool isParentActive,
    required bool isExpanded,
    required VoidCallback onSelectParent,
    required ValueChanged<String> onSelectChild,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: (isParentActive || isExpanded)
              ? AppColors.gold500.withValues(alpha: 0.04)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: (isParentActive || isExpanded)
                ? AppColors.gold500.withValues(alpha: 0.12)
                : AppColors.border.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera del grupo (padre)
            InkWell(
              onTap: onSelectParent,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    Icon(
                      _iconForCategorySlug(parent.slug, parent.categoryType),
                      size: 18,
                      color: isParentActive
                          ? AppColors.gold400
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        parent.name,
                        style: TextStyle(
                          color: isParentActive
                              ? AppColors.gold400
                              : AppColors.textPrimary,
                          fontWeight: isParentActive
                              ? FontWeight.w700
                              : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      '${children.length}',
                      style: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        Icons.expand_more_rounded,
                        size: 20,
                        color: AppColors.textMuted.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Hijas (expandible)
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: children.map((cat) {
                    final isActive = selectedName == cat.name;
                    return GestureDetector(
                      onTap: () => onSelectChild(cat.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.gold500.withValues(alpha: 0.18)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isActive
                                ? AppColors.gold500.withValues(alpha: 0.5)
                                : AppColors.border.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          cat.name,
                          style: TextStyle(
                            color: isActive
                                ? AppColors.gold400
                                : AppColors.textSecondary,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 280),
              sizeCurve: Curves.easeOutCubic,
            ),
          ],
        ),
      ),
    );
  }

  /// Chip de categoría individual (para "Todas" y sueltas)
  Widget _buildCategoryFilterChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.gold500.withValues(alpha: 0.18)
              : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? AppColors.gold500.withValues(alpha: 0.5)
                : AppColors.border.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: isActive ? AppColors.gold400 : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.gold400 : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Icono según slug de categoría
  IconData _iconForCategorySlug(String slug, String? type) {
    final lower = (type ?? slug).toLowerCase();
    if (lower.contains('ropa') ||
        lower.contains('cloth') ||
        lower.contains('camis') ||
        lower.contains('top')) {
      return Icons.checkroom_rounded;
    }
    if (lower.contains('zapat') ||
        lower.contains('shoe') ||
        lower.contains('calzado') ||
        lower.contains('sneaker') ||
        lower.contains('bota')) {
      return Icons.ice_skating_rounded;
    }
    if (lower.contains('accesor') || lower.contains('access')) {
      return Icons.watch_rounded;
    }
    if (lower.contains('deport') || lower.contains('sport')) {
      return Icons.fitness_center_rounded;
    }
    if (lower.contains('bolso') || lower.contains('bag')) {
      return Icons.shopping_bag_rounded;
    }
    if (lower.contains('joya') || lower.contains('jewel')) {
      return Icons.diamond_rounded;
    }
    if (lower.contains('perfum') || lower.contains('fragrance')) {
      return Icons.air_rounded;
    }
    if (lower.contains('pantalon') || lower.contains('jean')) {
      return Icons.straighten_rounded;
    }
    if (lower.contains('vestid') || lower.contains('dress')) {
      return Icons.dry_cleaning_rounded;
    }
    if (lower.contains('chubasquer') ||
        lower.contains('abrig') ||
        lower.contains('chaquet') ||
        lower.contains('jacket')) {
      return Icons.severe_cold_rounded;
    }
    if (lower.contains('rebaj') ||
        lower.contains('sale') ||
        lower.contains('oferta')) {
      return Icons.local_offer_rounded;
    }
    if (lower.contains('noved') || lower.contains('new')) {
      return Icons.fiber_new_rounded;
    }
    return Icons.category_rounded;
  }
}

class _ActiveFilter {
  final String label;
  final IconData icon;
  final VoidCallback onRemove;
  const _ActiveFilter(this.label, this.icon, this.onRemove);
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 0.82,
              child: Container(
                color: AppColors.gray800,
                child: Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 28,
                    color: AppColors.textMuted.withValues(alpha: 0.15),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 8,
                      width: 50,
                      decoration: BoxDecoration(
                        color: AppColors.gray800,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.gray800,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: 12,
                      width: 65,
                      decoration: BoxDecoration(
                        color: AppColors.gray800,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
