import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../shared/services/api_client.dart';
import '../../../../shared/widgets/cached_image.dart';
import '../../../../shared/widgets/animations.dart';
import '../../../../shared/extensions/number_extensions.dart';
import '../../../products/presentation/providers/products_provider.dart';
import '../../../products/data/models/product_model.dart';

// ─── Filtro de productos admin ───
enum _AdminProductFilter { all, active, inactive, featured, lowStock, noStock }

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() =>
      _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  _AdminProductFilter _filter = _AdminProductFilter.all;
  String _query = '';

  late final AnimationController _animCtrl;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _anims = createStaggerAnimations(
      controller: _animCtrl,
      count: 20,
      delayPerItem: 0.03,
      itemDuration: 0.3,
    );
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  List<ProductModel> _applyFilters(List<ProductModel> products) {
    var result = products.where((p) {
      if (_query.isNotEmpty) {
        final q = _query;
        if (!p.name.toLowerCase().contains(q) &&
            !p.price.toCurrency.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    switch (_filter) {
      case _AdminProductFilter.active:
        result = result.where((p) => p.isActive).toList();
        break;
      case _AdminProductFilter.inactive:
        result = result.where((p) => !p.isActive).toList();
        break;
      case _AdminProductFilter.featured:
        result = result.where((p) => p.featured).toList();
        break;
      case _AdminProductFilter.lowStock:
        result = result.where((p) => p.stock > 0 && p.stock <= 5).toList();
        break;
      case _AdminProductFilter.noStock:
        result = result.where((p) => p.stock == 0).toList();
        break;
      case _AdminProductFilter.all:
        break;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(
      productsProvider(const ProductsFilter(limit: 500)),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/productos/nuevo'),
        backgroundColor: AppColors.gold500,
        icon: const Icon(Icons.add_rounded, color: Colors.black),
        label: const Text(
          'Nuevo',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ═══ APP BAR ═══
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.surface,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.06),
                  ),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.06),
                    ),
                  ),
                  child: const Icon(Icons.refresh_rounded, size: 17),
                ),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  ref.invalidate(
                    productsProvider(const ProductsFilter(limit: 500)),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(
                left: 56,
                bottom: 16,
                right: 56,
              ),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      size: 14,
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Productos',
                    style: AppTextStyles.h4.copyWith(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          // ═══ SEARCH BAR ═══
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: AppColors.textMuted.withValues(alpha: 0.5),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Buscar producto...',
                          hintStyle: TextStyle(
                            color: AppColors.textMuted.withValues(alpha: 0.4),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      GestureDetector(
                        onTap: () => _searchCtrl.clear(),
                        child: Icon(
                          Icons.close_rounded,
                          color: AppColors.textMuted.withValues(alpha: 0.5),
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ═══ FILTER CHIPS ═══
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                children: _AdminProductFilter.values.map((f) {
                  final selected = _filter == f;
                  final label = _filterLabel(f);
                  final color = _filterColor(f);
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _filter = f);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? color.withValues(alpha: 0.15)
                              : AppColors.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? color.withValues(alpha: 0.4)
                                : AppColors.border.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: selected ? color : AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ═══ PRODUCT LIST ═══
          productsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: BouncingDotsLoader(color: AppColors.gold500),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Error: $e',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            data: (allProducts) {
              final products = _applyFilters(allProducts);

              if (products.isEmpty) {
                return SliverFillRemaining(
                  child: AnimatedEmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: _query.isNotEmpty
                        ? 'Sin resultados'
                        : 'No hay productos',
                    subtitle: _query.isNotEmpty
                        ? 'Intenta con otro término'
                        : 'Añade un nuevo producto',
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    // Counter header
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8, top: 4),
                        child: Row(
                          children: [
                            Text(
                              '${products.length} producto${products.length != 1 ? 's' : ''}',
                              style: TextStyle(
                                color: AppColors.textMuted.withValues(
                                  alpha: 0.6,
                                ),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${allProducts.where((p) => p.isActive).length} activos',
                              style: TextStyle(
                                color: AppColors.success.withValues(alpha: 0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final product = products[index - 1];
                    final animIdx = (index).clamp(0, _anims.length - 1);
                    return FadeSlideItem(
                      index: index,
                      animation: _anims[animIdx],
                      child: _buildProductTile(product),
                    );
                  }, childCount: products.length + 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Product Tile ───
  Widget _buildProductTile(ProductModel product) {
    final stockColor = product.stock == 0
        ? AppColors.error
        : product.stock <= 5
        ? AppColors.warning
        : AppColors.success;

    return GestureDetector(
      onTap: () => context.push('/admin/productos/${product.id}/editar'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.04)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  CachedImage(
                    imageUrl: product.images.isNotEmpty
                        ? product.images.first
                        : '',
                    width: 60,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                  if (!product.isActive)
                    Container(
                      width: 60,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.visibility_off_rounded,
                          color: Colors.white54,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (product.featured)
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: AppColors.gold500.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            color: AppColors.gold500,
                            size: 12,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.price.toCurrency,
                    style: const TextStyle(
                      color: AppColors.gold400,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Active badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (product.isActive
                                      ? AppColors.success
                                      : AppColors.error)
                                  .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: product.isActive
                                    ? AppColors.success
                                    : AppColors.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              product.isActive ? 'Activo' : 'Inactivo',
                              style: TextStyle(
                                color: product.isActive
                                    ? AppColors.success
                                    : AppColors.error,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Stock badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: stockColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.stock == 0
                              ? 'Sin stock'
                              : 'Stock: ${product.stock}',
                          style: TextStyle(
                            color: stockColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            // Actions
            PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textMuted,
                  size: 16,
                ),
              ),
              onSelected: (value) => _handleAction(value, product),
              itemBuilder: (_) => [
                _popupItem(
                  'edit',
                  Icons.edit_rounded,
                  'Editar',
                  AppColors.info,
                ),
                _popupItem(
                  'toggle_active',
                  product.isActive
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  product.isActive ? 'Desactivar' : 'Activar',
                  product.isActive ? AppColors.warning : AppColors.success,
                ),
                _popupItem(
                  'toggle_featured',
                  product.featured
                      ? Icons.star_outline_rounded
                      : Icons.star_rounded,
                  product.featured ? 'Quitar destacado' : 'Destacar',
                  AppColors.gold500,
                ),
                _popupItem(
                  'delete',
                  Icons.delete_rounded,
                  'Eliminar',
                  AppColors.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _popupItem(
    String value,
    IconData icon,
    String label,
    Color color,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(String value, ProductModel product) async {
    switch (value) {
      case 'edit':
        context.push('/admin/productos/${product.id}/editar');
        break;
      case 'toggle_active':
        HapticFeedback.mediumImpact();
        try {
          await ApiClient.instance.postFunction(
            'manage-products',
            body: {
              'action': 'toggle_active',
              'id': product.id,
              'data': {'is_active': !product.isActive},
            },
          );
          ref.invalidate(productsProvider(const ProductsFilter(limit: 500)));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(
                      product.isActive
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      product.isActive
                          ? 'Producto oculto de la tienda'
                          : 'Producto visible en la tienda',
                    ),
                  ],
                ),
                backgroundColor: product.isActive
                    ? AppColors.warning
                    : AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
        break;
      case 'toggle_featured':
        HapticFeedback.mediumImpact();
        try {
          await ApiClient.instance.postFunction(
            'manage-products',
            body: {
              'action': 'toggle_featured',
              'id': product.id,
              'data': {'featured': !product.featured},
            },
          );
          ref.invalidate(productsProvider(const ProductsFilter(limit: 500)));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(
                      product.featured
                          ? Icons.star_outline_rounded
                          : Icons.star_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      product.featured
                          ? 'Producto quitado de destacados'
                          : 'Producto marcado como destacado',
                    ),
                  ],
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Eliminar producto',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: Text(
              '¿Eliminar "${product.name}"?\nEsta acción no se puede deshacer.',
              style: const TextStyle(color: AppColors.textMuted),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        );
        if (confirm == true) {
          HapticFeedback.mediumImpact();
          try {
            await ApiClient.instance.postFunction(
              'manage-products',
              body: {'action': 'delete', 'id': product.id},
            );
            ref.invalidate(productsProvider(const ProductsFilter(limit: 500)));
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text('"${product.name}" eliminado'),
                    ],
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }
          } on ApiException catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.message),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        }
        break;
    }
  }

  String _filterLabel(_AdminProductFilter f) {
    switch (f) {
      case _AdminProductFilter.all:
        return 'Todos';
      case _AdminProductFilter.active:
        return 'Activos';
      case _AdminProductFilter.inactive:
        return 'Inactivos';
      case _AdminProductFilter.featured:
        return 'Destacados';
      case _AdminProductFilter.lowStock:
        return 'Stock bajo';
      case _AdminProductFilter.noStock:
        return 'Sin stock';
    }
  }

  Color _filterColor(_AdminProductFilter f) {
    switch (f) {
      case _AdminProductFilter.all:
        return AppColors.textPrimary;
      case _AdminProductFilter.active:
        return AppColors.success;
      case _AdminProductFilter.inactive:
        return AppColors.textMuted;
      case _AdminProductFilter.featured:
        return AppColors.gold500;
      case _AdminProductFilter.lowStock:
        return AppColors.warning;
      case _AdminProductFilter.noStock:
        return AppColors.error;
    }
  }
}
