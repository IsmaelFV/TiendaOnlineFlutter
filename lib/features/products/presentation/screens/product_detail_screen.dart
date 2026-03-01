import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../shared/widgets/cached_image.dart';
import '../../../../shared/widgets/loader.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/animated_heart_button.dart';
import '../../../../shared/widgets/animated_press.dart';
import '../../../../shared/widgets/animations.dart';
import '../../../../shared/extensions/number_extensions.dart';
import '../../../wishlist/presentation/providers/wishlist_provider.dart';
import '../../../reviews/presentation/widgets/reviews_section.dart';
import '../providers/products_provider.dart';
import '../widgets/add_to_cart_btn.dart';
import '../widgets/size_recommender.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String slug;
  const ProductDetailScreen({super.key, required this.slug});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen>
    with TickerProviderStateMixin {
  String _selectedSize = '';
  int _currentImageIndex = 0;
  final PageController _imageController = PageController();

  late final AnimationController _contentCtrl;
  late final List<Animation<double>> _contentAnims;

  @override
  void initState() {
    super.initState();
    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();
    _contentAnims = createStaggerAnimations(
      controller: _contentCtrl,
      count: 7,
      delayPerItem: 0.08,
      itemDuration: 0.30,
    );
  }

  @override
  void dispose() {
    _imageController.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productBySlugProvider(widget.slug));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: productAsync.when(
        loading: () => const Loader(),
        error: (error, _) => AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(productBySlugProvider(widget.slug)),
        ),
        data: (product) {
          final hasDiscount = product.isOnSale && product.salePrice != null;
          final displayPrice = hasDiscount ? product.salePrice! : product.price;
          final stockForSize = product.stockBySize[_selectedSize] ?? 0;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 420,
                pinned: true,
                backgroundColor: AppColors.surface,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, size: 18),
                  ),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  _WishlistButton(productId: product.id),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.background.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                      child: const GoldIcon(
                        icon: Icons.share_outlined,
                        size: 18,
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Share.share(
                        '\u00a1Mira ${product.name} en Fashion Store!',
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      PageView.builder(
                        controller: _imageController,
                        itemCount: product.images.length.clamp(1, 999),
                        onPageChanged: (index) =>
                            setState(() => _currentImageIndex = index),
                        itemBuilder: (context, index) {
                          return CachedImage(
                            imageUrl: product.images.isNotEmpty
                                ? product.images[index]
                                : '',
                            fit: BoxFit.cover,
                            width: double.infinity,
                          );
                        },
                      ),
                      if (product.images.length > 1)
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              product.images.length,
                              (i) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                width: i == _currentImageIndex ? 24 : 6,
                                height: 6,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: i == _currentImageIndex
                                      ? AppColors.gold500
                                      : AppColors.textMuted.withValues(
                                          alpha: 0.5,
                                        ),
                                  borderRadius: BorderRadius.circular(3),
                                  boxShadow: i == _currentImageIndex
                                      ? [
                                          BoxShadow(
                                            color: AppColors.gold500.withValues(
                                              alpha: 0.4,
                                            ),
                                            blurRadius: 6,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Categor\u00eda
                      FadeSlideItem(
                        index: 0,
                        animation: _contentAnims[0],
                        child: product.categories != null
                            ? Text(
                                (product.categories!['name'] as String? ?? '')
                                    .toUpperCase(),
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.gold500,
                                  letterSpacing: 2,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 8),

                      // Nombre
                      FadeSlideItem(
                        index: 1,
                        animation: _contentAnims[1],
                        child: Text(product.name, style: AppTextStyles.h2),
                      ),
                      const SizedBox(height: 12),

                      // Precio con animaci\u00f3n
                      FadeSlideItem(
                        index: 2,
                        animation: _contentAnims[2],
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            AnimatedCounter(
                              value: displayPrice / 100,
                              style: AppTextStyles.price.copyWith(fontSize: 28),
                              formatter: (v) =>
                                  '${v.toStringAsFixed(2).replaceAll('.', ',')} \u20ac',
                            ),
                            if (hasDiscount) ...[
                              const SizedBox(width: 12),
                              Text(
                                product.price.toCurrency,
                                style: AppTextStyles.priceOld.copyWith(
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '-${(((product.price - product.salePrice!) / product.price) * 100).round()}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Selector de tallas
                      FadeSlideItem(
                        index: 3,
                        animation: _contentAnims[3],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Talla',
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              children: product.sizes.map((size) {
                                final stock = product.stockBySize[size] ?? 0;
                                final isSelected = _selectedSize == size;
                                final isAvailable = stock > 0;

                                return AnimatedPress(
                                  scaleDown: 0.90,
                                  onPressed: isAvailable
                                      ? () {
                                          HapticFeedback.selectionClick();
                                          setState(() => _selectedSize = size);
                                        }
                                      : () {},
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeOutCubic,
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.gold500
                                          : AppColors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.gold500
                                            : isAvailable
                                            ? AppColors.border
                                            : AppColors.border.withValues(
                                                alpha: 0.2,
                                              ),
                                        width: isSelected ? 2 : 1,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: AppColors.gold500
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 10,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        size,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.black
                                              : isAvailable
                                              ? AppColors.textPrimary
                                              : AppColors.textMuted.withValues(
                                                  alpha: 0.4,
                                                ),
                                          fontWeight: FontWeight.w600,
                                          decoration: isAvailable
                                              ? null
                                              : TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            if (_selectedSize.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  stockForSize > 0
                                      ? '$stockForSize unidades disponibles'
                                      : 'Agotado',
                                  key: ValueKey('$_selectedSize-$stockForSize'),
                                  style: AppTextStyles.caption.copyWith(
                                    color: stockForSize > 0
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Recomendador de talla
                      if (product.sizes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: GestureDetector(
                            onTap: () {
                              SizeRecommenderSheet.show(
                                context,
                                productSizes: product.sizes,
                                sizeMeasurements: product.sizeMeasurements,
                                categoryName: product.categories != null
                                    ? product.categories!['name'] as String?
                                    : null,
                                onSelectSize: (size) {
                                  setState(() => _selectedSize = size);
                                },
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.gold500.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.gold500.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.straighten_rounded,
                                    color: AppColors.gold400,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '¿No sabes tu talla? Descúbrela aquí',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.gold400,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Add to cart
                      FadeSlideItem(
                        index: 4,
                        animation: _contentAnims[4],
                        child: AddToCartButton(
                          productId: product.id,
                          name: product.name,
                          price: displayPrice,
                          selectedSize: _selectedSize,
                          availableStock: stockForSize,
                          image: product.images.isNotEmpty
                              ? product.images.first
                              : null,
                          slug: product.slug,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Descripci\u00f3n
                      if (product.description != null &&
                          product.description!.isNotEmpty) ...[
                        FadeSlideItem(
                          index: 5,
                          animation: _contentAnims[5],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Descripci\u00f3n', style: AppTextStyles.h4),
                              const SizedBox(height: 8),
                              Text(
                                product.description!,
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Detalles
                      FadeSlideItem(
                        index: 6,
                        animation: _contentAnims[6],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (product.material != null ||
                                product.careInstructions != null)
                              _buildDetails(product),
                            ReviewsSection(productId: product.id),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetails(dynamic product) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text('Detalles del producto', style: AppTextStyles.h4),
        children: [
          if (product.material != null)
            _detailRow(Icons.layers_outlined, 'Material', product.material!),
          if (product.sku != null)
            _detailRow(Icons.qr_code, 'SKU', product.sku!),
          if (product.careInstructions != null)
            _detailRow(
              Icons.dry_cleaning_outlined,
              'Cuidados',
              product.careInstructions!,
            ),
          if (product.weightGrams != null)
            _detailRow(Icons.scale_outlined, 'Peso', '${product.weightGrams}g'),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GoldIcon(icon: icon, size: 18),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WishlistButton extends ConsumerWidget {
  final String productId;
  const _WishlistButton({required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(isInWishlistProvider(productId));

    return Container(
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.7),
        shape: BoxShape.circle,
      ),
      child: AnimatedHeartButton(
        isFavorite: isFav,
        size: 20,
        onToggle: () {
          ref.read(wishlistProvider.notifier).toggle(productId);
        },
      ),
    );
  }
}
