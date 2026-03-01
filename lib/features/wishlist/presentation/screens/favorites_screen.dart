import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../shared/widgets/cached_image.dart';
import '../../../../shared/widgets/animated_heart_button.dart';
import '../../../../shared/widgets/animated_press.dart';
import '../../../../shared/widgets/animations.dart';
import '../../../../shared/extensions/number_extensions.dart';
import '../providers/wishlist_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(wishlistProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GoldIcon(icon: Icons.favorite_outline, size: 22),
            const SizedBox(width: 8),
            Text('Favoritos', style: AppTextStyles.h4),
            if (items.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.gold500.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${items.length}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.gold500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
      ),
      body: items.isEmpty
          ? const AnimatedEmptyState(
              icon: Icons.favorite_border,
              title: 'Sin productos favoritos',
              subtitle: 'Toca el \u2661 en cualquier producto para guardarlo',
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final product = items[index];
                return ScaleFadeIn(
                  delay: Duration(milliseconds: 80 * index),
                  child: AnimatedPress(
                    scaleDown: 0.95,
                    onPressed: () => context.push('/productos/${product.slug}'),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(14),
                                  ),
                                  child: CachedImage(
                                    imageUrl: product.images.isNotEmpty
                                        ? product.images.first
                                        : '',
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: AnimatedHeartButton(
                                      isFavorite: true,
                                      size: 18,
                                      onToggle: () => ref
                                          .read(wishlistProvider.notifier)
                                          .toggle(product.id),
                                    ),
                                  ),
                                ),
                                if (product.isOnSale)
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.error,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'SALE',
                                        style: AppTextStyles.caption.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      Text(
                                        product.price.toCurrency,
                                        style: product.isOnSale
                                            ? AppTextStyles.bodySmall.copyWith(
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                color: AppColors.textMuted,
                                              )
                                            : AppTextStyles.price.copyWith(
                                                fontSize: 14,
                                              ),
                                      ),
                                      if (product.isOnSale &&
                                          product.salePrice != null) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          product.salePrice!.toCurrency,
                                          style: AppTextStyles.price.copyWith(
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
