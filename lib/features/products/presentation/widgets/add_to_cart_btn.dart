import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../cart/data/models/cart_item_model.dart';
import '../../../cart/presentation/providers/cart_provider.dart';

class AddToCartButton extends ConsumerStatefulWidget {
  final String productId;
  final String name;
  final double price;
  final String? image;
  final String? slug;
  final String selectedSize;
  final int availableStock;

  const AddToCartButton({
    super.key,
    required this.productId,
    required this.name,
    required this.price,
    required this.selectedSize,
    required this.availableStock,
    this.image,
    this.slug,
  });

  @override
  ConsumerState<AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends ConsumerState<AddToCartButton>
    with TickerProviderStateMixin {
  bool _added = false;

  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  late final AnimationController _successController;
  late final Animation<double> _progressAnimation;
  late final Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();

    // Bounce al pulsar
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _bounceAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.92), weight: 15),
          TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.06), weight: 35),
          TweenSequenceItem(tween: Tween(begin: 1.06, end: 0.98), weight: 25),
          TweenSequenceItem(tween: Tween(begin: 0.98, end: 1.0), weight: 25),
        ]).animate(
          CurvedAnimation(parent: _bounceController, curve: Curves.easeOut),
        );

    // Progreso de éxito
    _successController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _successController,
        curve: const Interval(0, 0.6, curve: Curves.easeOut),
      ),
    );
    _checkAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _successController,
        curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
      ),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _successController.dispose();
    super.dispose();
  }

  void _handleAddToCart() {
    if (widget.selectedSize.isEmpty) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selecciona una talla'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    if (widget.availableStock <= 0) return;

    // Verificar si ya se alcanzó el stock máximo para esta talla en el carrito
    final cartState = ref.read(cartProvider);
    final key = '${widget.productId}-${widget.selectedSize}';
    final existingItem = cartState.items[key];
    if (existingItem != null &&
        existingItem.quantity >= widget.availableStock) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Stock máximo alcanzado (${widget.availableStock} uds en talla ${widget.selectedSize})',
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // Haptic + animations
    HapticFeedback.mediumImpact();
    _bounceController.forward(from: 0);
    _successController.forward(from: 0);

    ref
        .read(cartProvider.notifier)
        .addItem(
          CartItemModel(
            productId: widget.productId,
            name: widget.name,
            price: widget.price,
            quantity: 1,
            size: widget.selectedSize,
            image: widget.image,
            slug: widget.slug,
            maxStock: widget.availableStock,
          ),
        );

    setState(() => _added = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _added = false);
        _successController.reset();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text('${widget.name} añadido al carrito')),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        action: SnackBarAction(
          label: 'VER CARRITO',
          textColor: Colors.white,
          onPressed: () => context.go('/cart'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final noSizeSelected = widget.selectedSize.isEmpty;
    final isDisabled = noSizeSelected || widget.availableStock <= 0;

    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) =>
          Transform.scale(scale: _bounceAnimation.value, child: child),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: Stack(
          children: [
            // Fondo con progreso animado
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, _) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: _added
                        ? LinearGradient(
                            colors: [
                              AppColors.success,
                              AppColors.success.withValues(alpha: 0.9),
                            ],
                            stops: [
                              _progressAnimation.value,
                              _progressAnimation.value,
                            ],
                          )
                        : null,
                    color: _added
                        ? null
                        : noSizeSelected
                        ? AppColors.gold500.withValues(alpha: 0.6)
                        : isDisabled
                        ? AppColors.gray700
                        : AppColors.accentGold,
                    boxShadow: isDisabled
                        ? null
                        : [
                            BoxShadow(
                              color:
                                  (_added
                                          ? AppColors.success
                                          : AppColors.accentGold)
                                      .withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                );
              },
            ),
            // Contenido del botón
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                splashColor: Colors.white.withValues(alpha: 0.15),
                onTap: isDisabled ? null : _handleAddToCart,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: _added
                        ? AnimatedBuilder(
                            animation: _checkAnimation,
                            builder: (context, _) => Transform.scale(
                              scale: _checkAnimation.value.clamp(0, 1.2),
                              child: const Row(
                                key: ValueKey('added'),
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '¡AÑADIDO!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Row(
                            key: const ValueKey('add'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                noSizeSelected
                                    ? Icons.straighten_rounded
                                    : isDisabled
                                    ? Icons.block_rounded
                                    : Icons.shopping_bag_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                noSizeSelected
                                    ? 'SELECCIONA UNA TALLA'
                                    : isDisabled
                                    ? 'AGOTADO'
                                    : 'AÑADIR AL CARRITO',
                                style: AppTextStyles.button.copyWith(
                                  letterSpacing: 1.2,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
