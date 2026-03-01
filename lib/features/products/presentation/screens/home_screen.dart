import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../shared/extensions/number_extensions.dart';
import '../../../../config/theme/app_gradients.dart';
import '../../../../shared/widgets/animated_press.dart';
import '../../../../shared/widgets/animations.dart';
import '../../../../shared/widgets/cached_image.dart';
import '../../../../shared/widgets/loader.dart';
import '../../../settings/presentation/providers/flash_offers_provider.dart';
import '../../data/models/product_model.dart';
import '../providers/products_provider.dart';
import '../widgets/product_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  final _bannerCtrl = PageController();
  Timer? _autoScroll;
  late final AnimationController _staggerCtrl;
  late final List<Animation<double>> _sectionAnims;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();
    _sectionAnims = createStaggerAnimations(
      controller: _staggerCtrl,
      count: 7,
      delayPerItem: 0.10,
      itemDuration: 0.30,
    );
    _autoScroll = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_bannerCtrl.hasClients) {
        final next = ((_bannerCtrl.page?.round() ?? 0) + 1) % 2;
        _bannerCtrl.animateToPage(
          next,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoScroll?.cancel();
    _bannerCtrl.dispose();
    _staggerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flashEnabled = ref.watch(flashOffersEnabledProvider);
    final flashProducts = ref.watch(flashOffersProductsProvider);
    final featuredProducts = ref.watch(featuredProductsProvider);
    final newWomenProducts = ref.watch(newProductsForWomenProvider);
    final newMenProducts = ref.watch(newProductsForMenProvider);
    final showFlash = flashEnabled.valueOrNull == true;

    // ── Deduplicar: solo flash vs. destacados ──
    final flashIds = <String>{};
    final flashList = flashProducts.valueOrNull ?? [];
    for (final p in flashList) {
      flashIds.add(p.id);
    }

    // Destacados: quitar los que ya salieron en flash
    final featuredFiltered = featuredProducts.whenData(
      (list) => list.where((p) => !flashIds.contains(p.id)).toList(),
    );

    // Novedades mujer/hombre: se muestran sin deduplicación
    // (un producto puede ser destacado y novedad a la vez)
    final newWomenFiltered = newWomenProducts;
    final newMenFiltered = newMenProducts;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.surface,
            title: ShimmerText(
              text: 'FASHION STORE',
              style: AppTextStyles.h4.copyWith(letterSpacing: 3),
            ),
            centerTitle: true,
            actions: [
              ScaleFadeIn(
                delay: const Duration(milliseconds: 500),
                child: IconButton(
                  icon: const GoldIcon(
                    icon: Icons.notifications_outlined,
                    size: 24,
                  ),
                  onPressed: () {},
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: FadeSlideItem(
              index: 0,
              animation: _sectionAnims[0],
              child: _buildHeroBanner(context),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeSlideItem(
              index: 1,
              animation: _sectionAnims[1],
              child: _buildQuickAccess(context),
            ),
          ),
          if (showFlash)
            SliverToBoxAdapter(
              child: FadeSlideItem(
                index: 2,
                animation: _sectionAnims[2],
                child: _buildFlashOffers(context, ref, flashProducts),
              ),
            ),
          SliverToBoxAdapter(
            child: FadeSlideItem(
              index: 3,
              animation: _sectionAnims[3],
              child: _buildProductSection(
                context,
                title: 'Destacados',
                subtitle: 'Lo mejor de la temporada',
                asyncProducts: featuredFiltered,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeSlideItem(
              index: 4,
              animation: _sectionAnims[4],
              child: _buildProductSection(
                context,
                title: 'Novedades Mujer',
                subtitle: 'Lo último para ella',
                asyncProducts: newWomenFiltered,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeSlideItem(
              index: 5,
              animation: _sectionAnims[5],
              child: _buildProductSection(
                context,
                title: 'Novedades Hombre',
                subtitle: 'Lo último para él',
                asyncProducts: newMenFiltered,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    final banners = [
      {
        'title': 'NUESTRO\nCATÁLOGO',
        'subtitle': 'Explora todos los productos',
        'cta': 'VER CATÁLOGO',
        'route': '/tienda',
      },
      {
        'title': 'REBAJAS\nDE TEMPORADA',
        'subtitle': 'Hasta -50% en selección',
        'cta': 'VER OFERTAS',
        'route': '/tienda?isOnSale=true',
      },
    ];

    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          PageView.builder(
            controller: _bannerCtrl,
            itemCount: banners.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _bannerCtrl,
                builder: (_, child) {
                  double parallax = 0;
                  if (_bannerCtrl.hasClients) {
                    parallax = (_bannerCtrl.page ?? 0) - index;
                  }
                  return Transform.translate(
                    offset: Offset(parallax * 50, 0),
                    child: child,
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: index == 0
                        ? AppGradients.goldSubtle
                        : AppGradients.surface,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (index == 0)
                        ShimmerText(
                          text: banners[index]['title']!,
                          textAlign: TextAlign.left,
                          style: AppTextStyles.h1.copyWith(
                            height: 1.1,
                            letterSpacing: 2,
                          ),
                        )
                      else
                        Text(
                          banners[index]['title']!,
                          style: AppTextStyles.h1.copyWith(
                            color: AppColors.gold500,
                            height: 1.1,
                            letterSpacing: 2,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        banners[index]['subtitle']!,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textMuted,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => context.push(banners[index]['route']!),
                        child: Text(banners[index]['cta']!),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _bannerCtrl,
                count: banners.length,
                effect: ExpandingDotsEffect(
                  dotHeight: 6,
                  dotWidth: 6,
                  activeDotColor: AppColors.gold500,
                  dotColor: AppColors.textMuted,
                  expansionFactor: 3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccess(BuildContext context) {
    final items = [
      {
        'icon': Icons.fiber_new_rounded,
        'label': 'Novedades',
        'route': '/novedades',
        'color': AppColors.accentEmerald,
      },
      {
        'icon': Icons.local_offer_outlined,
        'label': 'Rebajas',
        'route': '/tienda?isOnSale=true',
        'color': AppColors.gold500,
      },
      {
        'icon': Icons.female_rounded,
        'label': 'Mujer',
        'route': '/productos',
        'color': const Color(0xFFE8A0BF),
      },
      {
        'icon': Icons.male_rounded,
        'label': 'Hombre',
        'route': '/productos',
        'color': const Color(0xFF7EB8DA),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(items.length, (i) {
          final item = items[i];
          final color = item['color'] as Color;
          return ScaleFadeIn(
            delay: Duration(milliseconds: 300 + i * 100),
            child: AnimatedPress(
              scaleDown: 0.90,
              onPressed: () {
                HapticFeedback.lightImpact();
                context.push(item['route'] as String);
              },
              child: Column(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withValues(alpha: 0.20)),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['label'] as String,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFlashOffers(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ProductModel>> flashProducts,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              PulseGlow(
                glowColor: AppColors.gold400,
                maxRadius: 12,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppGradients.gold,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flash_on, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'OFERTAS FLASH',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: flashProducts.when(
            loading: () => const Loader(),
            error: (_, _) => const SizedBox.shrink(),
            data: (products) {
              if (products.isEmpty) return const SizedBox.shrink();
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ScaleFadeIn(
                    delay: Duration(milliseconds: 100 * index),
                    child: Container(
                      width: 150,
                      margin: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () => context.push('/productos/${product.slug}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedImage(
                                  imageUrl: product.images.isNotEmpty
                                      ? product.images.first
                                      : '',
                                  fit: BoxFit.cover,
                                  width: 150,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              product.name,
                              style: AppTextStyles.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                Text(
                                  (product.salePrice ?? product.price)
                                      .toCurrency,
                                  style: AppTextStyles.price.copyWith(
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (product.salePrice != null)
                                  Text(
                                    product.price.toCurrency,
                                    style: AppTextStyles.priceOld.copyWith(
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductSection(
    BuildContext context, {
    required String title,
    required String subtitle,
    required AsyncValue<dynamic> asyncProducts,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 24,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.gold400, AppColors.gold600],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.h3),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 280,
          child: asyncProducts.when(
            loading: () => const Loader(),
            error: (_, _) => const SizedBox.shrink(),
            data: (products) => ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: products.length,
              itemBuilder: (context, index) => ScaleFadeIn(
                delay: Duration(milliseconds: 80 * index),
                child: SizedBox(
                  width: 165,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ProductCard(product: products[index], compact: true),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
