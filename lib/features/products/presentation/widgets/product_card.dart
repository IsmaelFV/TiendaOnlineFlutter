import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../shared/widgets/cached_image.dart';
import '../../../../shared/widgets/animated_heart_button.dart';
import '../../data/models/product_model.dart';
import '../../../../shared/extensions/number_extensions.dart';
import '../../../wishlist/presentation/providers/wishlist_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';

/// ProductCard premium con animaciones de press, long-press peek overlay,
/// botón de favorito, badges, tallas y colores visibles. Estilo Dribbble.
class ProductCard extends ConsumerStatefulWidget {
  final ProductModel product;
  final int index;
  final bool compact;

  const ProductCard({
    super.key,
    required this.product,
    this.index = 0,
    this.compact = false,
  });

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard>
    with TickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;
  late final AnimationController _longPressController;
  late final Animation<double> _overlayAnimation;
  bool _pressed = false;
  bool _longPressed = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    _longPressController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _overlayAnimation = CurvedAnimation(
      parent: _longPressController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    _longPressController.dispose();
    super.dispose();
  }

  void _onLongPressStart() {
    HapticFeedback.mediumImpact();
    setState(() => _longPressed = true);
    _longPressController.forward();
  }

  void _onLongPressEnd() {
    _longPressController.reverse().then((_) {
      if (mounted) setState(() => _longPressed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final hasDiscount = product.isOnSale && product.salePrice != null;
    final displayPrice = hasDiscount ? product.salePrice! : product.price;
    final isFav = ref.watch(isInWishlistProvider(product.id));

    // Colores disponibles para el producto
    final colorName = product.color;
    final hasSizes = product.sizes.isNotEmpty;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) =>
          Transform.scale(scale: _scaleAnimation.value, child: child),
      child: GestureDetector(
        onTapDown: (_) {
          _pressController.forward();
          setState(() => _pressed = true);
        },
        onTapUp: (_) {
          _pressController.reverse();
          setState(() => _pressed = false);
          HapticFeedback.selectionClick();
          context.push('/productos/${product.slug}');
        },
        onTapCancel: () {
          _pressController.reverse();
          setState(() => _pressed = false);
        },
        onLongPressStart: (_) => _onLongPressStart(),
        onLongPressEnd: (_) => _onLongPressEnd(),
        onLongPressCancel: () => _onLongPressEnd(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _pressed || _longPressed
                  ? AppColors.gold500.withValues(alpha: 0.35)
                  : AppColors.border.withValues(alpha: 0.08),
              width: _longPressed ? 1.5 : 1.0,
            ),
            boxShadow: _pressed || _longPressed
                ? [
                    BoxShadow(
                      color: AppColors.gold500.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Imagen ───
                    AspectRatio(
                      aspectRatio: 0.82,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedImage(
                            imageUrl: product.images.isNotEmpty
                                ? product.images.first
                                : '',
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          // Gradiente inferior sobre la imagen
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 50,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    AppColors.card.withValues(alpha: 0.7),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Badges
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (hasDiscount)
                                  _buildBadge(
                                    '-${(((product.price - product.salePrice!) / product.price) * 100).round()}%',
                                    AppColors.error,
                                  ),
                                if (product.isNew) ...[
                                  const SizedBox(height: 4),
                                  _buildBadge('NUEVO', AppColors.gold500),
                                ],
                                if (product.featured && !product.isNew) ...[
                                  const SizedBox(height: 4),
                                  _buildBadge('TOP', AppColors.accentEmerald),
                                ],
                              ],
                            ),
                          ),
                          // Favorito
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                shape: BoxShape.circle,
                              ),
                              child: AnimatedHeartButton(
                                isFavorite: isFav,
                                onToggle: () => ref
                                    .read(wishlistProvider.notifier)
                                    .toggle(product.id),
                                size: 18,
                              ),
                            ),
                          ),
                          // Tallas pequeñas en esquina inferior izquierda
                          if (hasSizes)
                            Positioned(
                              bottom: 6,
                              left: 8,
                              child: _buildSizeDots(product.sizes),
                            ),
                        ],
                      ),
                    ),

                    // ─── Info ───
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Categoría + color
                            Row(
                              children: [
                                if (product.categories != null)
                                  Expanded(
                                    child: Text(
                                      (product.categories!['name'] as String? ??
                                              '')
                                          .toUpperCase(),
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textMuted,
                                        letterSpacing: 1,
                                        fontSize: 9,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                if (colorName != null &&
                                    colorName.isNotEmpty) ...[
                                  const SizedBox(width: 4),
                                  _buildColorDot(colorName),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Nombre
                            Text(
                              product.name,
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (!widget.compact) ...[
                              const SizedBox(height: 4),
                              // Tallas disponibles como mini chips
                              if (hasSizes) _buildInfoSizeChips(product.sizes),
                            ], // fin de !compact
                            const Spacer(),
                            // Separador sutil
                            if (!widget.compact)
                              Container(
                                height: 0.5,
                                margin: const EdgeInsets.only(bottom: 7),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      AppColors.gold500.withValues(alpha: 0.15),
                                      AppColors.gold500.withValues(alpha: 0.15),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            // Precio + indicador stock / carrito
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            displayPrice.toCurrency,
                                            style: AppTextStyles.price.copyWith(
                                              fontSize: 15,
                                            ),
                                          ),
                                          if (hasDiscount) ...[
                                            const SizedBox(width: 5),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 1,
                                              ),
                                              child: Text(
                                                product.price.toCurrency,
                                                style: AppTextStyles.priceOld
                                                    .copyWith(fontSize: 11),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (!widget.compact &&
                                          _stockLabel(product) != null) ...[
                                        const SizedBox(height: 2),
                                        Builder(
                                          builder: (context) {
                                            final ts =
                                                product.stockBySize.isNotEmpty
                                                ? product.stockBySize.values
                                                      .fold(0, (a, b) => a + b)
                                                : product.stock;
                                            return Text(
                                              _stockLabel(product)!,
                                              style: TextStyle(
                                                color: ts <= 3
                                                    ? AppColors.error
                                                          .withValues(
                                                            alpha: 0.8,
                                                          )
                                                    : AppColors.accentEmerald
                                                          .withValues(
                                                            alpha: 0.7,
                                                          ),
                                                fontSize: 9,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                // Mini botón carrito
                                if (!widget.compact)
                                  GestureDetector(
                                    onTap: () {
                                      // Absorber el tap para no navegar al detalle
                                    },
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () {
                                          HapticFeedback.mediumImpact();
                                          final firstSize =
                                              product.sizes.isNotEmpty
                                              ? product.sizes.first
                                              : (product
                                                        .availableSizes
                                                        .isNotEmpty
                                                    ? product
                                                          .availableSizes
                                                          .first
                                                    : 'Única');
                                          final sizeStock =
                                              product.stockBySize[firstSize] ??
                                              0;
                                          if (sizeStock <= 0) return;
                                          final added = ref
                                              .read(cartProvider.notifier)
                                              .quickAdd(
                                                productId: product.id,
                                                name: product.name,
                                                price: hasDiscount
                                                    ? product.salePrice!
                                                    : product.price,
                                                size: firstSize,
                                                maxStock: sizeStock,
                                                image: product.images.isNotEmpty
                                                    ? product.images.first
                                                    : null,
                                                slug: product.slug,
                                              );
                                          if (!added) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).clearSnackBars();
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Stock máximo alcanzado ($sizeStock uds)',
                                                ),
                                                backgroundColor:
                                                    AppColors.warning,
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                            );
                                            return;
                                          }
                                          ScaffoldMessenger.of(
                                            context,
                                          ).clearSnackBars();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Añadido al carrito (talla $firstSize)',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                              ),
                                              backgroundColor:
                                                  AppColors.accentEmerald,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              duration: const Duration(
                                                seconds: 2,
                                              ),
                                              action: SnackBarAction(
                                                label: 'VER',
                                                textColor: Colors.white,
                                                onPressed: () =>
                                                    context.go('/cart'),
                                              ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: AppColors.gold500.withValues(
                                              alpha: 0.12,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: AppColors.gold500
                                                  .withValues(alpha: 0.2),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.add_shopping_cart_rounded,
                                            size: 13,
                                            color: AppColors.gold400,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // ─── Long-press overlay con info rápida ───
                if (_longPressed)
                  AnimatedBuilder(
                    animation: _overlayAnimation,
                    builder: (context, child) {
                      return Positioned.fill(
                        child: Opacity(
                          opacity: _overlayAnimation.value,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: 3 * _overlayAnimation.value,
                                sigmaY: 3 * _overlayAnimation.value,
                              ),
                              child: Container(
                                color: AppColors.background.withValues(
                                  alpha: 0.75,
                                ),
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Nombre completo
                                    Text(
                                      product.name,
                                      style: AppTextStyles.body.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: AppColors.textPrimary,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 10),
                                    // Precio grande
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          displayPrice.toCurrency,
                                          style: AppTextStyles.price.copyWith(
                                            fontSize: 20,
                                          ),
                                        ),
                                        if (hasDiscount) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            product.price.toCurrency,
                                            style: AppTextStyles.priceOld
                                                .copyWith(fontSize: 13),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Tallas disponibles
                                    if (hasSizes)
                                      _buildQuickSizes(product.sizes),
                                    if (colorName != null &&
                                        colorName.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          _buildColorDot(colorName),
                                          const SizedBox(width: 6),
                                          Text(
                                            colorName,
                                            style: AppTextStyles.caption
                                                .copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 11,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 14),
                                    // Botón ver detalle
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.gold500,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'Ver detalle',
                                        style: TextStyle(
                                          color: AppColors.background,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Mini chips de tallas para la sección de info
  Widget _buildInfoSizeChips(List<String> sizes) {
    final show = sizes.take(4).toList();
    final extra = sizes.length - show.length;
    return Wrap(
      spacing: 4,
      runSpacing: 3,
      children: [
        for (final s in show)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.gold500.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppColors.gold500.withValues(alpha: 0.12),
                width: 0.5,
              ),
            ),
            child: Text(
              s,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        if (extra > 0)
          Text(
            '+$extra',
            style: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.5),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  /// Etiqueta de stock según la cantidad
  String? _stockLabel(ProductModel product) {
    final totalStock = product.stockBySize.isNotEmpty
        ? product.stockBySize.values.fold(0, (a, b) => a + b)
        : product.stock;
    if (totalStock <= 0) return 'Agotado';
    if (totalStock <= 3) return '¡Últimas $totalStock uds!';
    if (totalStock <= 10) return 'Pocas unidades';
    return null;
  }

  /// Dots de tallas visibles en la imagen
  Widget _buildSizeDots(List<String> sizes) {
    final show = sizes.take(4).toList();
    final extra = sizes.length - show.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < show.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Text(
              show[i],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (extra > 0) ...[
            const SizedBox(width: 2),
            Text(
              '+$extra',
              style: TextStyle(
                color: AppColors.gold300,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Tallas expandidas en el overlay de long-press
  Widget _buildQuickSizes(List<String> sizes) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: sizes.map((s) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gold500.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(6),
            color: AppColors.card.withValues(alpha: 0.6),
          ),
          child: Text(
            s,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Dot de color del producto
  Widget _buildColorDot(String colorName) {
    final c = _colorFromName(colorName);
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 0.5,
        ),
        boxShadow: [BoxShadow(color: c.withValues(alpha: 0.4), blurRadius: 3)],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Mapea nombres de color comunes a Color
  static Color _colorFromName(String name) {
    switch (name.toLowerCase().trim()) {
      case 'negro':
      case 'black':
        return const Color(0xFF1A1A1A);
      case 'blanco':
      case 'white':
        return const Color(0xFFF5F5F5);
      case 'rojo':
      case 'red':
        return const Color(0xFFE53935);
      case 'azul':
      case 'blue':
        return const Color(0xFF1E88E5);
      case 'azul marino':
      case 'navy':
        return const Color(0xFF1A237E);
      case 'verde':
      case 'green':
        return const Color(0xFF43A047);
      case 'amarillo':
      case 'yellow':
        return const Color(0xFFFDD835);
      case 'rosa':
      case 'pink':
        return const Color(0xFFEC407A);
      case 'gris':
      case 'grey':
      case 'gray':
        return const Color(0xFF9E9E9E);
      case 'marrón':
      case 'brown':
        return const Color(0xFF795548);
      case 'beige':
      case 'crema':
        return const Color(0xFFD7CCC8);
      case 'naranja':
      case 'orange':
        return const Color(0xFFFF9800);
      case 'morado':
      case 'purple':
        return const Color(0xFF7B1FA2);
      case 'burdeos':
      case 'burgundy':
        return const Color(0xFF880E4F);
      case 'coral':
        return const Color(0xFFFF7043);
      case 'oliva':
      case 'olive':
        return const Color(0xFF827717);
      case 'dorado':
      case 'gold':
        return const Color(0xFFD4AF37);
      case 'plateado':
      case 'silver':
        return const Color(0xFFC0C0C0);
      default:
        return AppColors.textMuted;
    }
  }
}
