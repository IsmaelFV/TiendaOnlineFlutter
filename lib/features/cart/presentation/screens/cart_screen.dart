import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../shared/extensions/number_extensions.dart';
import '../../../../shared/widgets/cached_image.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_input.dart';
import '../../../../shared/widgets/animated_press.dart';
import '../../../../shared/widgets/animations.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/cart_state.dart';
import '../providers/cart_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen>
    with TickerProviderStateMixin {
  final _discountController = TextEditingController();
  bool _isApplyingDiscount = false;

  late final AnimationController _listCtrl;
  late List<Animation<double>> _itemAnims;

  @override
  void initState() {
    super.initState();
    _listCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    _itemAnims = createStaggerAnimations(
      controller: _listCtrl,
      count: 10,
      delayPerItem: 0.08,
      itemDuration: 0.25,
    );
  }

  @override
  void dispose() {
    _discountController.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GoldIcon(icon: Icons.shopping_bag_outlined, size: 22),
            const SizedBox(width: 8),
            Text('Carrito', style: AppTextStyles.h4),
            const SizedBox(width: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Text(
                '(${cart.itemCount})',
                key: ValueKey(cart.itemCount),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.gold500,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        actions: [
          if (cart.items.isNotEmpty)
            TextButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Vaciar carrito'),
                    content: const Text(
                      '\u00bfEst\u00e1s seguro de que quieres vaciar el carrito?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(cartProvider.notifier).clear();
                          Navigator.pop(ctx);
                        },
                        child: const Text(
                          'Vaciar',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: Text(
                'Vaciar',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ),
        ],
      ),
      body: cart.items.isEmpty
          ? AnimatedEmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Tu carrito est\u00e1 vac\u00edo',
              subtitle: 'A\u00f1ade productos para empezar a comprar',
              buttonText: 'EXPLORAR TIENDA',
              onAction: () => context.go('/productos'),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final entry = cart.items.entries.toList()[index];
                      final item = entry.value;
                      final animIndex = index.clamp(0, _itemAnims.length - 1);
                      return FadeSlideItem(
                        index: index,
                        animation: _itemAnims[animIndex],
                        child: _buildCartItem(context, ref, item),
                      );
                    },
                  ),
                ),
                _buildSummary(context, ref, cart),
              ],
            ),
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    WidgetRef ref,
    CartItemModel item,
  ) {
    return Dismissible(
      key: Key('${item.productId}-${item.size}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.error.withValues(alpha: 0.0),
              AppColors.error.withValues(alpha: 0.15),
              AppColors.error.withValues(alpha: 0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              'Eliminar',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        ref.read(cartProvider.notifier).removeItem(item.productId, item.size);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedImage(
                imageUrl: item.image ?? '',
                width: 80,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const GoldIcon(icon: Icons.straighten, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Talla: ${item.size}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.price.toCurrency,
                    style: AppTextStyles.price.copyWith(fontSize: 15),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                children: [
                  AnimatedPress(
                    scaleDown: 0.85,
                    onPressed: item.quantity >= item.maxStock
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            ref
                                .read(cartProvider.notifier)
                                .updateQuantity(
                                  item.productId,
                                  item.size,
                                  item.quantity + 1,
                                );
                          },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(11),
                        ),
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        size: 18,
                        color: item.quantity >= item.maxStock
                            ? AppColors.textMuted.withValues(alpha: 0.3)
                            : null,
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      child: Text(
                        '${item.quantity}',
                        key: ValueKey(item.quantity),
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.gold500,
                        ),
                      ),
                    ),
                  ),
                  AnimatedPress(
                    scaleDown: 0.85,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      ref
                          .read(cartProvider.notifier)
                          .updateQuantity(
                            item.productId,
                            item.size,
                            item.quantity - 1,
                          );
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(11),
                        ),
                      ),
                      child: const Icon(Icons.remove_rounded, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context, WidgetRef ref, CartState cart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: CustomInput(
                  controller: _discountController,
                  hint: 'C\u00f3digo de descuento',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: _isApplyingDiscount
                      ? null
                      : () async {
                          if (_discountController.text.isEmpty) return;
                          setState(() => _isApplyingDiscount = true);
                          final success = await ref
                              .read(cartProvider.notifier)
                              .applyDiscountCode(
                                _discountController.text.trim(),
                              );
                          setState(() => _isApplyingDiscount = false);

                          if (context.mounted) {
                            HapticFeedback.mediumImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? '\u00a1C\u00f3digo aplicado!'
                                      : 'C\u00f3digo no v\u00e1lido',
                                ),
                                backgroundColor: success
                                    ? AppColors.success
                                    : AppColors.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        },
                  child: _isApplyingDiscount
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Aplicar'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _summaryRow('Subtotal', cart.subtotal.toCurrency),
          if (cart.discountAmount > 0)
            _summaryRow(
              'Descuento (${cart.discountCode})',
              '-${cart.discountAmount.toCurrency}',
              color: AppColors.success,
            ),
          _summaryRow('Env\u00edo', 'Gratis', color: AppColors.success),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.gold500.withValues(alpha: 0.0),
                    AppColors.gold500.withValues(alpha: 0.3),
                    AppColors.gold500.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                AnimatedCounter(
                  value: cart.total / 100,
                  style: AppTextStyles.price.copyWith(fontSize: 20),
                  formatter: (v) =>
                      '${v.toStringAsFixed(2).replaceAll('.', ',')} \u20ac',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'FINALIZAR COMPRA',
            onPressed: () => context.push('/checkout'),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color ?? AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
