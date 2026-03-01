import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../config/theme/app_gradients.dart';
import '../../../../shared/widgets/animations.dart';
import '../../../../shared/widgets/animated_press.dart';
import '../../data/models/category_model.dart';
import '../../data/models/gender_model.dart';
import '../providers/products_provider.dart';

// ─────────────────────────────────────────────────────────────
//  Pantalla de exploración de categorías jerárquica
//  Flujo: Género (Hombre / Mujer) → Subcategorías → Sub-sub
// ─────────────────────────────────────────────────────────────

class CategoryExplorerScreen extends ConsumerStatefulWidget {
  const CategoryExplorerScreen({super.key});

  @override
  ConsumerState<CategoryExplorerScreen> createState() =>
      _CategoryExplorerScreenState();
}

class _CategoryExplorerScreenState extends ConsumerState<CategoryExplorerScreen>
    with TickerProviderStateMixin {
  // ── Navegación jerárquica ──
  GenderModel? _selectedGender;
  bool _isTodoMode = false; // "Todo" = todas las categorías sin género
  CategoryModel? _selectedParentCat; // Subcategoría nivel 1 seleccionada

  // ── Animaciones ──
  late final AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _selectGender(GenderModel gender) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedGender = gender;
      _isTodoMode = false;
      _selectedParentCat = null;
    });
  }

  void _selectTodo() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedGender = null;
      _isTodoMode = true;
      _selectedParentCat = null;
    });
  }

  void _selectParentCategory(CategoryModel cat) {
    HapticFeedback.lightImpact();
    setState(() => _selectedParentCat = cat);
  }

  void _goBack() {
    HapticFeedback.lightImpact();
    if (_selectedParentCat != null) {
      setState(() => _selectedParentCat = null);
    } else if (_selectedGender != null || _isTodoMode) {
      setState(() {
        _selectedGender = null;
        _isTodoMode = false;
      });
    }
  }

  void _navigateToProducts({String? categoryId, String? genderId}) {
    HapticFeedback.mediumImpact();
    final params = <String, String>{};
    if (genderId != null) params['genderId'] = genderId;
    if (categoryId != null) params['categoryId'] = categoryId;
    final uri = Uri(path: '/tienda', queryParameters: params);
    context.push(uri.toString());
  }

  String get _title {
    if (_selectedParentCat != null) return _selectedParentCat!.name;
    if (_selectedGender != null) return _selectedGender!.name;
    if (_isTodoMode) return 'Todo';
    return 'Tienda';
  }

  String get _subtitle {
    if (_selectedParentCat != null) return 'Elige una subcategoría';
    if (_selectedGender != null || _isTodoMode) return 'Elige una categoría';
    return 'Elige tu estilo';
  }

  @override
  Widget build(BuildContext context) {
    final gendersAsync = ref.watch(gendersProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildHeader()),
          if (_selectedGender != null || _isTodoMode)
            SliverToBoxAdapter(child: _buildBreadcrumbs()),
          SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _selectedParentCat != null
                  ? _buildChildCategories(
                      key: ValueKey('children-${_selectedParentCat!.id}'),
                      categoriesAsync: categoriesAsync,
                    )
                  : _selectedGender != null
                  ? _buildGenderCategories(
                      key: ValueKey('cats-${_selectedGender!.id}'),
                      categoriesAsync: categoriesAsync,
                    )
                  : _isTodoMode
                  ? _buildTodoCategories(
                      key: const ValueKey('cats-todo'),
                      categoriesAsync: categoriesAsync,
                    )
                  : _buildGenderSelection(
                      key: const ValueKey('genders'),
                      gendersAsync: gendersAsync,
                    ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  APP BAR
  // ─────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppColors.surface.withValues(alpha: 0.9),
      surfaceTintColor: Colors.transparent,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(color: Colors.transparent),
        ),
      ),
      leading: (_selectedGender != null || _isTodoMode)
          ? IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
              onPressed: _goBack,
            )
          : null,
      title: ShimmerText(
        text: 'TIENDA',
        style: AppTextStyles.h4.copyWith(letterSpacing: 3, fontSize: 16),
      ),
      centerTitle: true,
    );
  }

  // ─────────────────────────────────────────────────────────
  //  HEADER
  // ─────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeCtrl,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: AppGradients.gold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _subtitle.toUpperCase(),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.gold500,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: Text(
                _title,
                key: ValueKey(_title),
                style: AppTextStyles.h1.copyWith(fontSize: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  BREADCRUMBS
  // ─────────────────────────────────────────────────────────
  Widget _buildBreadcrumbs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _breadcrumbItem(
              'Inicio',
              onTap: () {
                setState(() {
                  _selectedGender = null;
                  _selectedParentCat = null;
                });
              },
            ),
            _breadcrumbDivider(),
            if (_selectedGender != null)
              _breadcrumbItem(
                _selectedGender!.name,
                active: _selectedParentCat == null,
                onTap: () {
                  if (_selectedParentCat != null) {
                    setState(() => _selectedParentCat = null);
                  }
                },
              ),
            if (_isTodoMode && _selectedGender == null)
              _breadcrumbItem(
                'Todo',
                active: _selectedParentCat == null,
                onTap: () {
                  if (_selectedParentCat != null) {
                    setState(() => _selectedParentCat = null);
                  }
                },
              ),
            if (_selectedParentCat != null) ...[
              _breadcrumbDivider(),
              _breadcrumbItem(_selectedParentCat!.name, active: true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _breadcrumbItem(
    String text, {
    bool active = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: active ? AppColors.gold500 : AppColors.textMuted,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _breadcrumbDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Icon(
        Icons.chevron_right_rounded,
        size: 16,
        color: AppColors.textMuted.withValues(alpha: 0.5),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  PASO 1: SELECCIÓN DE GÉNERO (Hombre / Mujer)
  // ─────────────────────────────────────────────────────────
  Widget _buildGenderSelection({
    required Key key,
    required AsyncValue<List<GenderModel>> gendersAsync,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: gendersAsync.when(
        loading: () => _buildShimmerCards(2),
        error: (_, _) => _buildErrorWidget('No se pudieron cargar los géneros'),
        data: (genders) {
          if (genders.isEmpty) {
            return _buildEmptyState('No hay géneros disponibles');
          }

          final genderVisuals = {
            'mujer': _GenderVisual(
              icon: Icons.female_rounded,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2D1B3D), Color(0xFF1A1025)],
              ),
              accentColor: const Color(0xFFE8A0BF),
              description: 'Moda, accesorios y más',
              backgroundIcon: Icons.spa_outlined,
            ),
            'hombre': _GenderVisual(
              icon: Icons.male_rounded,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1B2838), Color(0xFF0F1923)],
              ),
              accentColor: const Color(0xFF7EB8DA),
              description: 'Estilo urbano y clásico',
              backgroundIcon: Icons.shield_outlined,
            ),
          };

          final filtered = genders
              .where((g) => !g.name.toLowerCase().contains('unisex'))
              .toList();

          return Column(
            children: [
              ...List.generate(filtered.length, (i) {
                final gender = filtered[i];
                final visual =
                    genderVisuals[gender.slug] ??
                    _GenderVisual(
                      icon: Icons.person_outline_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
                      ),
                      accentColor: AppColors.gold500,
                      description: '',
                      backgroundIcon: Icons.star_outline_rounded,
                    );

                return ScaleFadeIn(
                  delay: Duration(milliseconds: 200 * i),
                  child: _GenderCard(
                    gender: gender,
                    visual: visual,
                    onTap: () => _selectGender(gender),
                  ),
                );
              }),
              // Tarjeta "Todo"
              ScaleFadeIn(
                delay: Duration(milliseconds: 200 * filtered.length),
                child: _GenderCard(
                  gender: const GenderModel(
                    id: 'todo',
                    name: 'Todo',
                    slug: 'todo',
                  ),
                  visual: _GenderVisual(
                    icon: Icons.apps_rounded,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2A2210), Color(0xFF1A1508)],
                    ),
                    accentColor: AppColors.gold500,
                    description: 'Todas las categorías',
                    backgroundIcon: Icons.grid_view_rounded,
                  ),
                  onTap: _selectTodo,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  PASO 2: CATEGORÍAS DE UN GÉNERO
  //  Muestra categorías de nivel raíz (parentId == null o level 1)
  //  que pertenecen al género seleccionado.
  //  Si una categoría tiene hijos → tap lleva al paso 3.
  //  Si no tiene hijos → tap lleva a productos.
  // ─────────────────────────────────────────────────────────
  Widget _buildGenderCategories({
    required Key key,
    required AsyncValue<List<CategoryModel>> categoriesAsync,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: categoriesAsync.when(
        loading: () => _buildShimmerCards(4),
        error: (_, _) => _buildErrorWidget('Error cargando categorías'),
        data: (allCategories) {
          final genderCats = allCategories
              .where((c) => c.genderId == _selectedGender!.id)
              .toList();

          // Categorías raíz: sin parent o level 1
          var rootCats = genderCats
              .where((c) => c.parentId == null || c.level == 1)
              .toList();

          // Fallback: si todas las categorías son planas (sin jerarquía),
          // mostrarlas directamente
          if (rootCats.isEmpty) rootCats = genderCats;

          rootCats.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

          // Filtrar las categorías "Novedades" y "Rebajas" del listado
          // (se acceden desde los tiles dedicados verde/rojo)
          rootCats = rootCats.where((c) {
            final lower = c.name.toLowerCase();
            return !lower.contains('novedades') && !lower.contains('rebajas');
          }).toList();

          if (rootCats.isEmpty) {
            return _buildEmptyState('No hay categorías disponibles');
          }

          return Column(
            children: [
              // Banner "Ver todo"
              ScaleFadeIn(
                delay: const Duration(milliseconds: 100),
                child: _ViewAllBanner(
                  genderName: _selectedGender!.name,
                  onTap: () =>
                      _navigateToProducts(genderId: _selectedGender!.id),
                ),
              ),
              const SizedBox(height: 10),

              // Tile "Novedades" para este género
              ScaleFadeIn(
                delay: const Duration(milliseconds: 130),
                child: _NovedadesTile(
                  label: 'Novedades ${_selectedGender!.name}',
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    final uri = Uri(
                      path: '/novedades',
                      queryParameters: {'genderId': _selectedGender!.id},
                    );
                    context.push(uri.toString());
                  },
                ),
              ),
              const SizedBox(height: 6),

              // Tile "Rebajas" para este género
              ScaleFadeIn(
                delay: const Duration(milliseconds: 160),
                child: _RebajasTile(
                  label: 'Rebajas ${_selectedGender!.name}',
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    final uri = Uri(
                      path: '/tienda',
                      queryParameters: {
                        'isOnSale': 'true',
                        'genderId': _selectedGender!.id,
                      },
                    );
                    context.push(uri.toString());
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Lista de categorías raíz
              ...List.generate(rootCats.length, (i) {
                final cat = rootCats[i];
                final childCount = genderCats
                    .where((c) => c.parentId == cat.id)
                    .length;
                final hasChildren = childCount > 0;

                return ScaleFadeIn(
                  delay: Duration(milliseconds: 150 + 70 * i),
                  child: _CategoryTile(
                    category: cat,
                    icon: _iconForCategory(cat.slug, cat.categoryType),
                    subtitle: hasChildren
                        ? '$childCount subcategorías'
                        : cat.description,
                    hasArrow: true,
                    onTap: () {
                      if (hasChildren) {
                        _selectParentCategory(cat);
                      } else {
                        _navigateToProducts(
                          categoryId: cat.id,
                          genderId: _selectedGender!.id,
                        );
                      }
                    },
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  PASO 2b: CATEGORÍAS "TODO" — Deduplicadas por nombre
  //  Agrupa categorías de todos los géneros, sin duplicados.
  // ─────────────────────────────────────────────────────────
  Widget _buildTodoCategories({
    required Key key,
    required AsyncValue<List<CategoryModel>> categoriesAsync,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: categoriesAsync.when(
        loading: () => _buildShimmerCards(4),
        error: (_, _) => _buildErrorWidget('Error cargando categorías'),
        data: (allCategories) {
          // Categorías raíz de todos los géneros
          var rootCats = allCategories
              .where((c) => c.parentId == null || c.level == 1)
              .toList();
          if (rootCats.isEmpty) rootCats = allCategories;

          // Filtrar las categorías "Novedades" y "Rebajas" del listado
          rootCats = rootCats.where((c) {
            final lower = c.name.toLowerCase();
            return !lower.contains('novedades') && !lower.contains('rebajas');
          }).toList();

          // Deduplicar por nombre
          final seen = <String>{};
          final deduped = <CategoryModel>[];
          for (final cat in rootCats) {
            if (!seen.contains(cat.name)) {
              seen.add(cat.name);
              deduped.add(cat);
            }
          }
          deduped.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

          if (deduped.isEmpty) {
            return _buildEmptyState('No hay categorías disponibles');
          }

          return Column(
            children: [
              // Banner "Ver todo"
              ScaleFadeIn(
                delay: const Duration(milliseconds: 100),
                child: _ViewAllBanner(
                  genderName: 'Todo',
                  onTap: () => _navigateToProducts(),
                ),
              ),
              const SizedBox(height: 10),

              // Tile "Novedades" general
              ScaleFadeIn(
                delay: const Duration(milliseconds: 130),
                child: _NovedadesTile(
                  label: 'Novedades',
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.push('/novedades');
                  },
                ),
              ),
              const SizedBox(height: 6),

              // Tile "Rebajas" general
              ScaleFadeIn(
                delay: const Duration(milliseconds: 160),
                child: _RebajasTile(
                  label: 'Rebajas',
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.push('/tienda?isOnSale=true');
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Lista de categorías deduplicadas
              ...List.generate(deduped.length, (i) {
                final cat = deduped[i];
                // Contar hijos (de cualquier género con el mismo nombre)
                final sameName = allCategories
                    .where((c) => c.name == cat.name)
                    .map((c) => c.id)
                    .toSet();
                final childCount = allCategories
                    .where((c) => sameName.contains(c.parentId))
                    .length;
                final hasChildren = childCount > 0;

                return ScaleFadeIn(
                  delay: Duration(milliseconds: 150 + 70 * i),
                  child: _CategoryTile(
                    category: cat,
                    icon: _iconForCategory(cat.slug, cat.categoryType),
                    subtitle: hasChildren
                        ? '$childCount subcategorías'
                        : cat.description,
                    hasArrow: true,
                    onTap: () {
                      if (hasChildren) {
                        _selectParentCategory(cat);
                      } else {
                        // Navegar sin género — mandamos categoryId solamente
                        _navigateToProducts(categoryId: cat.id);
                      }
                    },
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  PASO 3: SUBCATEGORÍAS DENTRO DE UNA CATEGORÍA PADRE
  // ─────────────────────────────────────────────────────────
  Widget _buildChildCategories({
    required Key key,
    required AsyncValue<List<CategoryModel>> categoriesAsync,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: categoriesAsync.when(
        loading: () => _buildShimmerCards(4),
        error: (_, _) => _buildErrorWidget('Error cargando subcategorías'),
        data: (allCategories) {
          // En modo "Todo", buscar hijos del padre Y también de equivalentes por nombre
          Set<String> parentIds;
          if (_isTodoMode) {
            final parentName = _selectedParentCat!.name;
            parentIds = allCategories
                .where((c) => c.name == parentName)
                .map((c) => c.id)
                .toSet();
          } else {
            parentIds = {_selectedParentCat!.id};
          }

          var children = allCategories
              .where((c) => parentIds.contains(c.parentId))
              .toList();

          // Deduplicar por nombre en modo Todo
          if (_isTodoMode) {
            final seen = <String>{};
            final deduped = <CategoryModel>[];
            for (final c in children) {
              if (!seen.contains(c.name)) {
                seen.add(c.name);
                deduped.add(c);
              }
            }
            children = deduped;
          }

          children.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

          // Si no tiene hijos, mostrar la propia categoría
          if (children.isEmpty) {
            children = [_selectedParentCat!];
          }

          return Column(
            children: [
              // Banner "Ver todo en esta categoría"
              ScaleFadeIn(
                delay: const Duration(milliseconds: 100),
                child: AnimatedPress(
                  scaleDown: 0.97,
                  onPressed: () => _navigateToProducts(
                    categoryId: _selectedParentCat!.id,
                    genderId: _selectedGender?.id,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppGradients.goldSubtle,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.gold500.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.gold500.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppColors.gold500,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ver todo en ${_selectedParentCat!.name}',
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${children.length} subcategorías',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: AppColors.gold500,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Grid de subcategorías (2 columnas)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                ),
                itemCount: children.length,
                itemBuilder: (context, i) {
                  final cat = children[i];
                  // Check if this child has its own children (deeper nesting)
                  final grandchildCount = allCategories
                      .where((c) => c.parentId == cat.id)
                      .length;

                  return ScaleFadeIn(
                    delay: Duration(milliseconds: 150 + 80 * i),
                    child: _SubcategoryCard(
                      category: cat,
                      icon: _iconForCategory(cat.slug, cat.categoryType),
                      hasChildren: grandchildCount > 0,
                      childCount: grandchildCount,
                      onTap: () {
                        if (grandchildCount > 0) {
                          // Navegar más profundo
                          _selectParentCategory(cat);
                        } else {
                          _navigateToProducts(
                            categoryId: cat.id,
                            genderId: _selectedGender?.id,
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  SHIMMER / ERROR / EMPTY
  // ─────────────────────────────────────────────────────────
  Widget _buildShimmerCards(int count) {
    return Column(
      children: List.generate(count, (i) {
        return Container(
          height: i == 0 ? 90 : 64,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.gold500,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(
              Icons.category_outlined,
              color: AppColors.textMuted.withValues(alpha: 0.4),
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  HELPERS DE ICONOS
  // ─────────────────────────────────────────────────────────
  IconData _iconForCategory(String slug, String? type) {
    final lower = (type ?? slug).toLowerCase();
    if (lower.contains('ropa') ||
        lower.contains('cloth') ||
        lower.contains('main') ||
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
    if (lower.contains('pantalon') ||
        lower.contains('pant') ||
        lower.contains('jean')) {
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
    if (lower.contains('falda') || lower.contains('skirt')) {
      return Icons.content_cut_rounded;
    }
    if (lower.contains('sudader') ||
        lower.contains('hoodie') ||
        lower.contains('jersey')) {
      return Icons.thermostat_rounded;
    }
    return Icons.category_rounded;
  }
}

// ═════════════════════════════════════════════════════════════
//  WIDGETS PRIVADOS
// ═════════════════════════════════════════════════════════════

class _GenderVisual {
  final IconData icon;
  final LinearGradient gradient;
  final Color accentColor;
  final String description;
  final IconData backgroundIcon;

  const _GenderVisual({
    required this.icon,
    required this.gradient,
    required this.accentColor,
    required this.description,
    required this.backgroundIcon,
  });
}

// ─────────────────────────────────────────────────────────────
//  GENDER CARD — Tarjeta inmersiva de género
// ─────────────────────────────────────────────────────────────
class _GenderCard extends StatelessWidget {
  final GenderModel gender;
  final _GenderVisual visual;
  final VoidCallback onTap;

  const _GenderCard({
    required this.gender,
    required this.visual,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AnimatedPress(
        scaleDown: 0.96,
        onPressed: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 150),
          decoration: BoxDecoration(
            gradient: visual.gradient,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: visual.accentColor.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: visual.accentColor.withValues(alpha: 0.08),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Icono de fondo decorativo
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Icon(
                    visual.backgroundIcon,
                    size: 140,
                    color: visual.accentColor.withValues(alpha: 0.06),
                  ),
                ),
                // Patrón sutil de puntos
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DotPatternPainter(
                      color: visual.accentColor.withValues(alpha: 0.04),
                    ),
                  ),
                ),
                // Contenido principal
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 22,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: visual.accentColor.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: visual.accentColor.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: Icon(
                                visual.icon,
                                color: visual.accentColor,
                                size: 26,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              gender.name,
                              style: AppTextStyles.h2.copyWith(
                                color: Colors.white,
                                fontSize: 24,
                              ),
                            ),
                            if (visual.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                visual.description,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: visual.accentColor.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: visual.accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: visual.accentColor,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CATEGORY TILE — Fila de categoría raíz (paso 2)
// ─────────────────────────────────────────────────────────────
class _CategoryTile extends StatelessWidget {
  final CategoryModel category;
  final IconData icon;
  final String? subtitle;
  final bool hasArrow;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.icon,
    this.subtitle,
    this.hasArrow = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedPress(
        scaleDown: 0.98,
        onPressed: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icono
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.gold500.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.gold500.withValues(alpha: 0.12),
                  ),
                ),
                child: Icon(icon, color: AppColors.gold500, size: 20),
              ),
              const SizedBox(width: 14),

              // Nombre + subtítulo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.name,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),

              if (hasArrow)
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SUBCATEGORY CARD — Tarjeta de subcategoría (paso 3, grid)
// ─────────────────────────────────────────────────────────────
class _SubcategoryCard extends StatelessWidget {
  final CategoryModel category;
  final IconData icon;
  final bool hasChildren;
  final int childCount;
  final VoidCallback onTap;

  const _SubcategoryCard({
    required this.category,
    required this.icon,
    this.hasChildren = false,
    this.childCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPress(
      scaleDown: 0.95,
      onPressed: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.gold500.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // Icono de fondo
              Positioned(
                right: -6,
                bottom: -6,
                child: Icon(
                  icon,
                  size: 60,
                  color: AppColors.gold500.withValues(alpha: 0.05),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: AppGradients.goldSubtle,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.gold500.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Icon(icon, color: AppColors.gold500, size: 20),
                    ),
                    const Spacer(),
                    Text(
                      category.name,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasChildren)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '$childCount más',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.gold500,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  VIEW ALL BANNER
// ─────────────────────────────────────────────────────────────
class _ViewAllBanner extends StatelessWidget {
  final String genderName;
  final VoidCallback onTap;

  const _ViewAllBanner({required this.genderName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedPress(
      scaleDown: 0.97,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF2A2210), Color(0xFF1A1508)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.gold500.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: AppGradients.gold,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.grid_view_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ver todo $genderName',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Explorar todos los productos',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.gold500.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.gold500,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  TILE DE NOVEDADES — acceso rápido a productos nuevos
// ─────────────────────────────────────────────────────────────
class _NovedadesTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NovedadesTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: AnimatedPress(
        scaleDown: 0.97,
        onPressed: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF1A2A20), Color(0xFF122218)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.accentEmerald.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentEmerald.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.accentEmerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accentEmerald.withValues(alpha: 0.15),
                  ),
                ),
                child: const Icon(
                  Icons.fiber_new_rounded,
                  color: AppColors.accentEmerald,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Los últimos productos añadidos',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.accentEmerald.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.accentEmerald,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  TILE DE REBAJAS — acceso rápido a productos en oferta
// ─────────────────────────────────────────────────────────────
class _RebajasTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _RebajasTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFC9A84C); // dorado/ámbar
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: AnimatedPress(
        scaleDown: 0.97,
        onPressed: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF2A2010), Color(0xFF221A0C)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentColor.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.15),
                  ),
                ),
                child: const Icon(
                  Icons.local_offer_rounded,
                  color: accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Descuentos y ofertas especiales',
                      style: AppTextStyles.caption.copyWith(
                        color: accentColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: accentColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PAINTER DE PUNTOS DECORATIVO
// ─────────────────────────────────────────────────────────────
class _DotPatternPainter extends CustomPainter {
  final Color color;
  _DotPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const spacing = 24.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
