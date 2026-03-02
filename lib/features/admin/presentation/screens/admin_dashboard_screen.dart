import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../shared/widgets/animations.dart';
import '../../../../shared/extensions/number_extensions.dart';

// ─────────────────────────────────────────────────────────────
//  Provider de estadísticas
// ─────────────────────────────────────────────────────────────
final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  final client = Supabase.instance.client;

  final ordersResponse = await client
      .from('orders')
      .select('id, total, status, created_at');
  final productsResponse = await client
      .from('products')
      .select('id, is_active, stock');

  int usersCount = 0;
  try {
    final profilesResp = await client.from('profiles').select('id');
    usersCount = (profilesResp as List).length;
  } catch (_) {
    try {
      final orderUsers = await client.from('orders').select('user_id');
      usersCount = (orderUsers as List).map((o) => o['user_id']).toSet().length;
    } catch (_) {}
  }

  final orders = ordersResponse as List;
  final products = productsResponse as List;

  final totalRevenue = orders
      .where((o) => o['status'] != 'cancelled' && o['status'] != 'refunded')
      .fold<double>(
        0,
        (sum, o) => sum + ((o['total'] as num?)?.toDouble() ?? 0),
      );

  final pendingOrders = orders.where((o) => o['status'] == 'pending').length;
  final confirmedOrders = orders
      .where((o) => o['status'] == 'confirmed')
      .length;
  final processingOrders = orders
      .where((o) => o['status'] == 'processing')
      .length;
  final shippedOrders = orders.where((o) => o['status'] == 'shipped').length;
  final deliveredOrders = orders
      .where((o) => o['status'] == 'delivered')
      .length;
  final cancelledOrders = orders
      .where((o) => o['status'] == 'cancelled')
      .length;
  final activeProducts = products.where((p) => p['is_active'] == true).length;
  final lowStockProducts = products
      .where(
        (p) => (p['stock'] as int? ?? 0) <= 5 && (p['stock'] as int? ?? 0) > 0,
      )
      .length;
  final outOfStockProducts = products
      .where((p) => (p['stock'] as int? ?? 0) == 0)
      .length;

  // Ventas últimos 7 días
  final now = DateTime.now();
  final salesByDay = <String, double>{};
  final ordersByDay = <String, int>{};
  for (int i = 6; i >= 0; i--) {
    final day = now.subtract(Duration(days: i));
    final key = '${day.day}/${day.month}';
    salesByDay[key] = 0;
    ordersByDay[key] = 0;
  }

  double todayRevenue = 0;
  int todayOrders = 0;

  for (final order in orders) {
    if (order['status'] == 'cancelled' || order['status'] == 'refunded') {
      continue;
    }
    final createdAt = DateTime.tryParse(order['created_at'] ?? '');
    if (createdAt != null && now.difference(createdAt).inDays < 7) {
      final key = '${createdAt.day}/${createdAt.month}';
      salesByDay[key] =
          (salesByDay[key] ?? 0) + ((order['total'] as num?)?.toDouble() ?? 0);
      ordersByDay[key] = (ordersByDay[key] ?? 0) + 1;

      if (createdAt.day == now.day &&
          createdAt.month == now.month &&
          createdAt.year == now.year) {
        todayRevenue += ((order['total'] as num?)?.toDouble() ?? 0);
        todayOrders++;
      }
    }
  }

  // ─── Top productos por ingresos ───
  List<Map<String, dynamic>> topProducts = [];
  try {
    final itemsResp = await client
        .from('order_items')
        .select('product_id, product_name, product_image, quantity, price');
    final rawItems = itemsResp as List;
    final aggMap = <String, Map<String, dynamic>>{};
    for (final it in rawItems) {
      final pid = it['product_id'] as String? ?? '';
      final qty = (it['quantity'] as num?)?.toInt() ?? 0;
      final price = ((it['price'] as num?)?.toDouble() ?? 0) / 100;
      if (aggMap.containsKey(pid)) {
        aggMap[pid]!['revenue'] =
            (aggMap[pid]!['revenue'] as double) + price * qty;
        aggMap[pid]!['units'] = (aggMap[pid]!['units'] as int) + qty;
      } else {
        aggMap[pid] = {
          'name': it['product_name'] as String? ?? 'Producto',
          'image': it['product_image'] as String? ?? '',
          'revenue': price * qty,
          'units': qty,
        };
      }
    }
    topProducts = aggMap.values.toList()
      ..sort(
        (a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double),
      );
    if (topProducts.length > 5) topProducts = topProducts.sublist(0, 5);
  } catch (_) {}

  return AdminStats(
    totalOrders: orders.length,
    totalRevenue: totalRevenue,
    todayRevenue: todayRevenue,
    todayOrders: todayOrders,
    pendingOrders: pendingOrders,
    confirmedOrders: confirmedOrders,
    processingOrders: processingOrders,
    shippedOrders: shippedOrders,
    deliveredOrders: deliveredOrders,
    cancelledOrders: cancelledOrders,
    totalProducts: products.length,
    activeProducts: activeProducts,
    lowStockProducts: lowStockProducts,
    outOfStockProducts: outOfStockProducts,
    totalUsers: usersCount,
    salesByDay: salesByDay,
    ordersByDay: ordersByDay,
    topProducts: topProducts,
  );
});

class AdminStats {
  final int totalOrders;
  final double totalRevenue;
  final double todayRevenue;
  final int todayOrders;
  final int pendingOrders;
  final int confirmedOrders;
  final int processingOrders;
  final int shippedOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final int totalProducts;
  final int activeProducts;
  final int lowStockProducts;
  final int outOfStockProducts;
  final int totalUsers;
  final Map<String, double> salesByDay;
  final Map<String, int> ordersByDay;
  final List<Map<String, dynamic>> topProducts;

  AdminStats({
    required this.totalOrders,
    required this.totalRevenue,
    required this.todayRevenue,
    required this.todayOrders,
    required this.pendingOrders,
    required this.confirmedOrders,
    required this.processingOrders,
    required this.shippedOrders,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.totalProducts,
    required this.activeProducts,
    required this.lowStockProducts,
    required this.outOfStockProducts,
    required this.totalUsers,
    required this.salesByDay,
    required this.ordersByDay,
    required this.topProducts,
  });
}

// ─────────────────────────────────────────────────────────────
//  Dashboard Screen
// ─────────────────────────────────────────────────────────────
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with TickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final List<Animation<double>> _anims;
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;
  late final AnimationController _shimmerCtrl;
  late final Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
    _anims = createStaggerAnimations(
      controller: _animCtrl,
      count: 14,
      delayPerItem: 0.04,
      itemDuration: 0.35,
    );
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _shimmerAnim = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _glowCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String get _todayFormatted {
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    final now = DateTime.now();
    return '${days[now.weekday - 1]} ${now.day} ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF070707),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ═══ PREMIUM APP BAR ═══
          SliverAppBar(
            expandedHeight: 0,
            toolbarHeight: 60,
            floating: true,
            pinned: true,
            backgroundColor: const Color(0xFF0C0C0C),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Center(
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.gold500.withValues(alpha: 0.12),
                          AppColors.gold500.withValues(alpha: 0.04),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.gold500.withValues(alpha: 0.15),
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 15,
                      color: AppColors.gold400,
                    ),
                  ),
                ),
              ),
            ),
            title: AnimatedBuilder(
              animation: _glowAnim,
              builder: (_, child) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.gold400, AppColors.gold700],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold500.withValues(
                            alpha: 0.15 + 0.15 * _glowAnim.value,
                          ),
                          blurRadius: 10 + 6 * _glowAnim.value,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.diamond_rounded,
                      size: 14,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    ref.invalidate(adminStatsProvider);
                  },
                  child: AnimatedBuilder(
                    animation: _glowAnim,
                    builder: (_, child) => Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.gold500.withValues(alpha: 0.12),
                            AppColors.gold500.withValues(alpha: 0.04),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.gold500.withValues(alpha: 0.15),
                        ),
                      ),
                      child: const Icon(
                        Icons.refresh_rounded,
                        size: 17,
                        color: AppColors.gold400,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ═══ BODY ═══
          statsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: BouncingDotsLoader(color: AppColors.gold500),
              ),
            ),
            error: (e, _) =>
                SliverFillRemaining(child: _buildErrorState(e.toString())),
            data: (stats) => SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 60),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ─── GREETING ───
                  _fadeSlide(0, _buildGreetingHeader()),
                  const SizedBox(height: 20),

                  // ─── REVENUE HERO ───
                  _fadeSlide(1, _buildRevenueHero(stats)),
                  const SizedBox(height: 16),

                  // ─── LIVE STATS STRIP ───
                  _fadeSlide(2, _buildLiveStatsStrip(stats)),
                  const SizedBox(height: 28),

                  // ─── QUICK ACTIONS ───
                  _fadeSlide(3, _buildQuickActions()),
                  const SizedBox(height: 28),

                  // ─── KPI GRID ───
                  _fadeSlide(4, _buildKPIGrid(stats)),
                  const SizedBox(height: 28),

                  // ─── SALES CHART ───
                  _fadeSlide(5, _buildSalesChart(stats)),
                  const SizedBox(height: 28),

                  // ─── ORDERS BAR CHART ───
                  _fadeSlide(6, _buildOrdersBarChart(stats)),
                  const SizedBox(height: 28),

                  // ─── TOP PRODUCTOS ───
                  if (stats.topProducts.isNotEmpty)
                    _fadeSlide(7, _buildTopProductsChart(stats)),
                  if (stats.topProducts.isNotEmpty) const SizedBox(height: 28),

                  // ─── STATUS DISTRIBUTION ───
                  _fadeSlide(8, _buildStatusDonut(stats)),
                  const SizedBox(height: 28),

                  // ─── ORDERS PIPELINE ───
                  _fadeSlide(9, _buildOrdersPipeline(stats)),
                  const SizedBox(height: 28),

                  // ─── INVENTORY STATUS ───
                  _fadeSlide(10, _buildInventoryStatus(stats)),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fadeSlide(int index, Widget child) {
    final i = index.clamp(0, _anims.length - 1);
    return FadeSlideItem(index: index, animation: _anims[i], child: child);
  }

  // ─────────────────────────────────────────────────────────
  //  GREETING HEADER
  // ─────────────────────────────────────────────────────────
  Widget _buildGreetingHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium shimmer greeting
              AnimatedBuilder(
                animation: _shimmerAnim,
                builder: (_, _) => ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: const [
                      AppColors.gold300,
                      Colors.white,
                      AppColors.gold300,
                    ],
                    stops: [
                      (_shimmerAnim.value - 0.3).clamp(0.0, 1.0),
                      _shimmerAnim.value.clamp(0.0, 1.0),
                      (_shimmerAnim.value + 0.3).clamp(0.0, 1.0),
                    ],
                  ).createShader(bounds),
                  child: Text(
                    _greeting,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.gold500.withValues(alpha: 0.15),
                          AppColors.gold500.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.gold500.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.diamond_rounded,
                          color: AppColors.gold500,
                          size: 10,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'ADMIN',
                          style: TextStyle(
                            color: AppColors.gold500,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _todayFormatted,
                    style: TextStyle(
                      color: AppColors.textMuted.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Premium live pulse indicator with glow
        AnimatedBuilder(
          animation: _glowAnim,
          builder: (_, _) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(
                alpha: 0.06 + 0.06 * _glowAnim.value,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.success.withValues(
                  alpha: 0.15 + 0.12 * _glowAnim.value,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(
                    alpha: 0.08 * _glowAnim.value,
                  ),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(
                          alpha: 0.6 * _glowAnim.value,
                        ),
                        blurRadius: 6 + 5 * _glowAnim.value,
                        spreadRadius: 1 + _glowAnim.value,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'En vivo',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  //  REVENUE HERO — Premium glass card
  // ─────────────────────────────────────────────────────────
  Widget _buildRevenueHero(AdminStats stats) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold500.withValues(
                alpha: 0.10 + 0.10 * _glowAnim.value,
              ),
              blurRadius: 40 + 16 * _glowAnim.value,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: child,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Main card
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2E2714),
                    Color(0xFF1E180B),
                    Color(0xFF161108),
                    Color(0xFF100D06),
                  ],
                  stops: [0.0, 0.35, 0.65, 1.0],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.gold500.withValues(alpha: 0.22),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top label row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.gold500.withValues(alpha: 0.18),
                              AppColors.gold500.withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.gold500.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: AppColors.gold400,
                              size: 11,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'HOY',
                              style: TextStyle(
                                color: AppColors.gold400,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold500.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.gold500.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.shopping_bag_outlined,
                              color: AppColors.gold400,
                              size: 13,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${stats.todayOrders} pedido${stats.todayOrders != 1 ? 's' : ''}',
                              style: const TextStyle(
                                color: AppColors.gold400,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Revenue amount — much bigger
                  AnimatedCounter(
                    value: stats.todayRevenue,
                    formatter: (v) => v.toEuroCurrency,
                    style: const TextStyle(
                      color: AppColors.gold300,
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2.0,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ingresos del día',
                    style: TextStyle(
                      color: AppColors.textMuted.withValues(alpha: 0.55),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Animated gold divider
                  AnimatedBuilder(
                    animation: _glowAnim,
                    builder: (_, _) => Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.gold500.withValues(alpha: 0),
                            AppColors.gold500.withValues(
                              alpha: 0.15 + 0.10 * _glowAnim.value,
                            ),
                            AppColors.gold500.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bottom stats
                  Row(
                    children: [
                      _heroStat(
                        Icons.account_balance_wallet_rounded,
                        'Total acumulado',
                        stats.totalRevenue.toEuroCurrency,
                      ),
                      Container(
                        height: 34,
                        width: 1,
                        color: AppColors.gold500.withValues(alpha: 0.1),
                      ),
                      _heroStat(
                        Icons.people_alt_rounded,
                        'Usuarios',
                        '${stats.totalUsers}',
                      ),
                      Container(
                        height: 34,
                        width: 1,
                        color: AppColors.gold500.withValues(alpha: 0.1),
                      ),
                      _heroStat(
                        Icons.receipt_long_rounded,
                        'Pedidos',
                        '${stats.totalOrders}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Shimmer overlay effect
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _shimmerAnim,
                builder: (_, _) {
                  final t = _shimmerAnim.value;
                  return IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: LinearGradient(
                          begin: Alignment(-1.0 + 3.0 * t, -0.3),
                          end: Alignment(-0.5 + 3.0 * t, 0.3),
                          colors: [
                            Colors.transparent,
                            AppColors.gold300.withValues(alpha: 0.05),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroStat(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.gold500.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.gold500.withValues(alpha: 0.6),
              size: 16,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.45),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  LIVE STATS STRIP — scrollable horizontal chips
  // ─────────────────────────────────────────────────────────
  Widget _buildLiveStatsStrip(AdminStats stats) {
    final items = [
      _LiveStat(
        '${stats.pendingOrders}',
        'pendientes',
        AppColors.warning,
        Icons.schedule_rounded,
      ),
      _LiveStat(
        '${stats.processingOrders}',
        'procesando',
        const Color(0xFF6366F1),
        Icons.settings_rounded,
      ),
      _LiveStat(
        '${stats.shippedOrders}',
        'enviados',
        AppColors.accentTeal,
        Icons.local_shipping_rounded,
      ),
      _LiveStat(
        '${stats.outOfStockProducts}',
        'sin stock',
        AppColors.error,
        Icons.remove_shopping_cart_rounded,
      ),
    ];

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, _) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    item.color.withValues(alpha: 0.12),
                    item.color.withValues(alpha: 0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: item.color.withValues(
                    alpha: 0.12 + 0.06 * _glowAnim.value,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: item.color.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(item.icon, color: item.color, size: 14),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.value,
                    style: TextStyle(
                      color: item.color,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: item.color.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  ERROR STATE
  // ─────────────────────────────────────────────────────────
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar datos',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => ref.invalidate(adminStatsProvider),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold500.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.gold500.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      size: 16,
                      color: AppColors.gold500,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Reintentar',
                      style: TextStyle(
                        color: AppColors.gold500,
                        fontWeight: FontWeight.w700,
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

  // ─────────────────────────────────────────────────────────
  //  KPI GRID — 2x2 with animated hover feel
  // ─────────────────────────────────────────────────────────
  Widget _buildKPIGrid(AdminStats stats) {
    final kpis = [
      _KPI(
        'Pendientes',
        '${stats.pendingOrders}',
        Icons.schedule_rounded,
        AppColors.gold500,
        () => context.push('/admin/pedidos'),
      ),
      _KPI(
        'Productos',
        '${stats.activeProducts}/${stats.totalProducts}',
        Icons.inventory_2_rounded,
        AppColors.accentTeal,
        () => context.push('/admin/productos'),
      ),
      _KPI(
        'Sin stock',
        '${stats.outOfStockProducts}',
        Icons.remove_shopping_cart_rounded,
        AppColors.accentEmerald,
        () => context.push('/admin/productos'),
      ),
      _KPI(
        'Stock bajo',
        '${stats.lowStockProducts}',
        Icons.warning_amber_rounded,
        AppColors.gold400,
        () => context.push('/admin/productos'),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.65,
      children: kpis.map((kpi) => _buildKPICard(kpi)).toList(),
    );
  }

  Widget _buildKPICard(_KPI kpi) {
    return _ScaleTap(
      onTap: () {
        HapticFeedback.lightImpact();
        kpi.onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kpi.color.withValues(alpha: 0.10),
              kpi.color.withValues(alpha: 0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: kpi.color.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: kpi.color.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    kpi.color.withValues(alpha: 0.15),
                    kpi.color.withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: kpi.color.withValues(alpha: 0.10)),
              ),
              child: Icon(kpi.icon, color: kpi.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    kpi.value,
                    style: TextStyle(
                      color: kpi.color,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    kpi.label,
                    style: TextStyle(
                      color: AppColors.textMuted.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: kpi.color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                color: kpi.color.withValues(alpha: 0.35),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  SALES CHART
  // ─────────────────────────────────────────────────────────
  Widget _buildSalesChart(AdminStats stats) {
    final weekTotal = stats.salesByDay.values.fold<double>(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1D18), Color(0xFF141310)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold500.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold500.withValues(alpha: 0.04),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.gold500.withValues(alpha: 0.15),
                      AppColors.gold500.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  color: AppColors.gold500,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ventas · 7 días',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${stats.ordersByDay.values.fold<int>(0, (a, b) => a + b)} pedidos esta semana',
                    style: TextStyle(
                      color: AppColors.textMuted.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold500.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  weekTotal.toEuroCurrency,
                  style: const TextStyle(
                    color: AppColors.gold400,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(height: 200, child: _buildLineChart(stats.salesByDay)),
        ],
      ),
    );
  }

  Widget _buildLineChart(Map<String, double> data) {
    if (data.isEmpty) {
      return const Center(
        child: Text('Sin datos', style: TextStyle(color: AppColors.textMuted)),
      );
    }

    final maxY = data.values.fold<double>(0, math.max);
    final spots = data.entries.toList().asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 0 ? maxY / 3 : 1,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.border.withValues(alpha: 0.04),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.keys.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      data.keys.elementAt(index),
                      style: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF1A1508),
            tooltipRoundedRadius: 12,
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            tooltipBorder: BorderSide(
              color: AppColors.gold500.withValues(alpha: 0.25),
            ),
            getTooltipItems: (spots) => spots.map((s) {
              return LineTooltipItem(
                s.y.toEuroCurrency,
                const TextStyle(
                  color: AppColors.gold300,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppColors.gold500,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                radius: 4,
                color: AppColors.gold500,
                strokeWidth: 3,
                strokeColor: const Color(0xFF1E1D18),
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.gold500.withValues(alpha: 0.25),
                  AppColors.gold500.withValues(alpha: 0.08),
                  AppColors.gold500.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  ORDERS BAR CHART — pedidos por día
  // ─────────────────────────────────────────────────────────
  Widget _buildOrdersBarChart(AdminStats stats) {
    final weekOrders = stats.ordersByDay.values.fold<int>(0, (a, b) => a + b);
    final maxOrders = stats.ordersByDay.values.fold<int>(0, math.max);
    final safeMax = math.max(1, maxOrders);
    final avgOrders = stats.ordersByDay.isEmpty
        ? 0.0
        : weekOrders / stats.ordersByDay.length;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF171E1C), Color(0xFF111615)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.accentTeal.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentTeal.withValues(alpha: 0.05),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accentTeal.withValues(alpha: 0.18),
                      AppColors.accentTeal.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: AppColors.accentTeal,
                  size: 17,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pedidos · 7 días',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Promedio: ${avgOrders.toStringAsFixed(1)}/día',
                      style: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accentTeal.withValues(alpha: 0.12),
                      AppColors.accentTeal.withValues(alpha: 0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shopping_bag_rounded,
                      color: AppColors.accentTeal,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$weekOrders',
                      style: const TextStyle(
                        color: AppColors.accentTeal,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          SizedBox(
            height: 190,
            child: BarChart(
              BarChartData(
                maxY: (safeMax + 1).toDouble(),
                barGroups: stats.ordersByDay.entries
                    .toList()
                    .asMap()
                    .entries
                    .map((e) {
                      final isMax = e.value.value == maxOrders && maxOrders > 0;
                      return BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value.value.toDouble(),
                            width: 22,
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: isMax
                                  ? [
                                      AppColors.accentTeal,
                                      AppColors.accentTeal.withValues(
                                        alpha: 0.7,
                                      ),
                                    ]
                                  : [
                                      AppColors.accentTeal.withValues(
                                        alpha: 0.7,
                                      ),
                                      AppColors.accentTeal.withValues(
                                        alpha: 0.4,
                                      ),
                                    ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(10),
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: (safeMax + 1).toDouble(),
                              color: AppColors.accentTeal.withValues(
                                alpha: 0.04,
                              ),
                            ),
                          ),
                        ],
                      );
                    })
                    .toList(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: math.max(1, safeMax / 3).toDouble(),
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.border.withValues(alpha: 0.04),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        final keys = stats.ordersByDay.keys.toList();
                        if (index >= 0 && index < keys.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              keys[index],
                              style: TextStyle(
                                color: AppColors.textMuted.withValues(
                                  alpha: 0.5,
                                ),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF0F2A1D),
                    tooltipRoundedRadius: 12,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    tooltipBorder: BorderSide(
                      color: AppColors.accentTeal.withValues(alpha: 0.3),
                    ),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final keys = stats.ordersByDay.keys.toList();
                      final day = groupIndex < keys.length
                          ? keys[groupIndex]
                          : '';
                      return BarTooltipItem(
                        '$day\n',
                        TextStyle(
                          color: AppColors.textMuted.withValues(alpha: 0.6),
                          fontSize: 10,
                        ),
                        children: [
                          TextSpan(
                            text: '${rod.toY.toInt()} pedidos',
                            style: const TextStyle(
                              color: AppColors.accentTeal,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  TOP PRODUCTOS — mejores productos por ingresos
  // ─────────────────────────────────────────────────────────
  Widget _buildTopProductsChart(AdminStats stats) {
    if (stats.topProducts.isEmpty) return const SizedBox.shrink();

    final maxRevenue = stats.topProducts.fold<double>(
      0,
      (m, p) => math.max(m, (p['revenue'] as double)),
    );
    final safeMax = maxRevenue > 0 ? maxRevenue : 1.0;

    const barColors = [
      AppColors.gold400,
      AppColors.gold500,
      AppColors.gold600,
      AppColors.gold700,
      AppColors.gold800,
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1D18), Color(0xFF141310)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold500.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold500.withValues(alpha: 0.04),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.gold500.withValues(alpha: 0.18),
                      AppColors.gold500.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.gold400,
                  size: 17,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Top Productos',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Los más vendidos por ingresos',
                      style: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold500.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: AppColors.gold400,
                      size: 13,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Top ${stats.topProducts.length}',
                      style: const TextStyle(
                        color: AppColors.gold400,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Products list
          ...stats.topProducts.asMap().entries.map((entry) {
            final index = entry.key;
            final product = entry.value;
            final name = product['name'] as String;
            final revenue = product['revenue'] as double;
            final units = product['units'] as int;
            final color = barColors[index % barColors.length];
            final fraction = revenue / safeMax;

            return Padding(
              padding: EdgeInsets.only(
                bottom: index < stats.topProducts.length - 1 ? 18 : 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Rank badge
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: index == 0
                              ? LinearGradient(
                                  colors: [
                                    AppColors.gold500.withValues(alpha: 0.2),
                                    AppColors.gold500.withValues(alpha: 0.08),
                                  ],
                                )
                              : null,
                          color: index > 0
                              ? AppColors.border.withValues(alpha: 0.06)
                              : null,
                          borderRadius: BorderRadius.circular(9),
                          border: index == 0
                              ? Border.all(
                                  color: AppColors.gold500.withValues(
                                    alpha: 0.2,
                                  ),
                                )
                              : null,
                        ),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: index == 0
                                ? AppColors.gold400
                                : AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$units uds',
                        style: TextStyle(
                          color: AppColors.textMuted.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        revenue.toEuroCurrency,
                        style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Animated bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 8,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: fraction),
                            duration: Duration(milliseconds: 800 + index * 150),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) =>
                                FractionallySizedBox(
                                  widthFactor: value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          color,
                                          color.withValues(alpha: 0.6),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  STATUS DONUT — distribución de estados de pedidos
  // ─────────────────────────────────────────────────────────
  Widget _buildStatusDonut(AdminStats stats) {
    final statusData = [
      _StatusSlice('Pendiente', stats.pendingOrders, AppColors.warning),
      _StatusSlice('Confirmado', stats.confirmedOrders, AppColors.info),
      _StatusSlice(
        'Procesando',
        stats.processingOrders,
        const Color(0xFF6366F1),
      ),
      _StatusSlice('Enviado', stats.shippedOrders, AppColors.accentTeal),
      _StatusSlice('Entregado', stats.deliveredOrders, AppColors.success),
      _StatusSlice('Cancelado', stats.cancelledOrders, AppColors.error),
    ].where((s) => s.count > 0).toList();

    final total = statusData.fold<int>(0, (s, e) => s + e.count);
    if (total == 0) return const SizedBox.shrink();

    // Mayor estado para mostrar en el centro
    final topStatus = statusData.reduce((a, b) => a.count >= b.count ? a : b);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B1A22), Color(0xFF131218)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.05),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6366F1).withValues(alpha: 0.18),
                      const Color(0xFF6366F1).withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.donut_large_rounded,
                  color: Color(0xFF6366F1),
                  size: 17,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Distribución de pedidos',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6366F1).withValues(alpha: 0.12),
                      const Color(0xFF6366F1).withValues(alpha: 0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$total total',
                  style: const TextStyle(
                    color: Color(0xFF6366F1),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 40,
                        sections: statusData.map((s) {
                          final pct = s.count / total * 100;
                          return PieChartSectionData(
                            value: s.count.toDouble(),
                            color: s.color,
                            radius: 30,
                            title: pct >= 12 ? '${pct.round()}%' : '',
                            titleStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            titlePositionPercentageOffset: 0.55,
                          );
                        }).toList(),
                      ),
                    ),
                    // Centro del donut: stat más grande
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${topStatus.count}',
                          style: TextStyle(
                            color: topStatus.color,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          topStatus.label,
                          style: TextStyle(
                            color: AppColors.textMuted.withValues(alpha: 0.5),
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: statusData.map((s) {
                    final pct = (s.count / total * 100).round();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: s.color,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: s.color.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              s.label,
                              style: TextStyle(
                                color: AppColors.textMuted.withValues(
                                  alpha: 0.7,
                                ),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            '${s.count}',
                            style: TextStyle(
                              color: s.color,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 36,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: s.color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '$pct%',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: s.color.withValues(alpha: 0.8),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  ORDERS PIPELINE — enhanced with animated progress
  // ─────────────────────────────────────────────────────────
  Widget _buildOrdersPipeline(AdminStats stats) {
    final stages = [
      _Stage(
        'Pendiente',
        stats.pendingOrders,
        AppColors.warning,
        Icons.schedule_rounded,
      ),
      _Stage(
        'Confirmado',
        stats.confirmedOrders,
        AppColors.info,
        Icons.check_circle_outline_rounded,
      ),
      _Stage(
        'Procesando',
        stats.processingOrders,
        const Color(0xFF6366F1),
        Icons.settings_rounded,
      ),
      _Stage(
        'Enviado',
        stats.shippedOrders,
        AppColors.accentTeal,
        Icons.local_shipping_rounded,
      ),
      _Stage(
        'Entregado',
        stats.deliveredOrders,
        AppColors.success,
        Icons.done_all_rounded,
      ),
      _Stage(
        'Cancelado',
        stats.cancelledOrders,
        AppColors.error,
        Icons.cancel_outlined,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF171E1C), Color(0xFF111615)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.accentTeal.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentTeal.withValues(alpha: 0.04),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accentTeal.withValues(alpha: 0.15),
                      AppColors.accentTeal.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.timeline_rounded,
                  color: AppColors.accentTeal,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Pipeline de pedidos',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/admin/pedidos'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentTeal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ver todos',
                        style: TextStyle(
                          color: AppColors.accentTeal,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.accentTeal,
                        size: 12,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          Builder(
            builder: (context) {
              final totalActive = stages.fold<int>(0, (s, e) => s + e.count);
              if (totalActive > 0) {
                return Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: SizedBox(
                        height: 7,
                        child: Row(
                          children: stages
                              .where((s) => s.count > 0)
                              .map(
                                (s) => Expanded(
                                  flex: s.count,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          s.color,
                                          s.color.withValues(alpha: 0.7),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Stages grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: stages.map((s) {
              final isActive = s.count > 0;
              return Container(
                width: (MediaQuery.of(context).size.width - 68) / 3,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? s.color.withValues(alpha: 0.06)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: isActive
                        ? s.color.withValues(alpha: 0.15)
                        : AppColors.border.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: s.color.withValues(
                          alpha: isActive ? 0.12 : 0.06,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(s.icon, color: s.color, size: 15),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${s.count}',
                      style: TextStyle(
                        color: isActive
                            ? s.color
                            : AppColors.textMuted.withValues(alpha: 0.4),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      s.label,
                      style: TextStyle(
                        color: AppColors.textMuted.withValues(
                          alpha: isActive ? 0.7 : 0.4,
                        ),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  INVENTORY STATUS
  // ─────────────────────────────────────────────────────────
  Widget _buildInventoryStatus(AdminStats stats) {
    final activePercent = stats.totalProducts > 0
        ? (stats.activeProducts / stats.totalProducts * 100).round()
        : 0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF171A20), Color(0xFF111318)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.info.withValues(alpha: 0.04),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.info.withValues(alpha: 0.15),
                      AppColors.info.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: AppColors.info,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Estado inventario',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/admin/productos'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Gestionar',
                    style: TextStyle(
                      color: AppColors.info,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 74,
                height: 74,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 74,
                      height: 74,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: activePercent / 100),
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) =>
                            CircularProgressIndicator(
                              value: value,
                              strokeWidth: 6.5,
                              backgroundColor: AppColors.border.withValues(
                                alpha: 0.08,
                              ),
                              valueColor: const AlwaysStoppedAnimation(
                                AppColors.success,
                              ),
                              strokeCap: StrokeCap.round,
                            ),
                      ),
                    ),
                    AnimatedCounter(
                      value: activePercent,
                      formatter: (v) => '${v.toInt()}%',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _inventoryRow(
                      'Activos',
                      stats.activeProducts,
                      AppColors.success,
                    ),
                    const SizedBox(height: 7),
                    _inventoryRow(
                      'Inactivos',
                      stats.totalProducts - stats.activeProducts,
                      AppColors.textMuted,
                    ),
                    const SizedBox(height: 7),
                    _inventoryRow(
                      'Stock bajo',
                      stats.lowStockProducts,
                      AppColors.warning,
                    ),
                    const SizedBox(height: 7),
                    _inventoryRow(
                      'Sin stock',
                      stats.outOfStockProducts,
                      AppColors.error,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _inventoryRow(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 4),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.65),
              fontSize: 12,
            ),
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  //  QUICK ACTIONS — Premium cards
  // ─────────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(
        'Productos',
        'Gestionar catálogo',
        Icons.inventory_2_rounded,
        const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A2210), Color(0xFF1C170A)],
        ),
        AppColors.gold500,
        '/admin/productos',
      ),
      _QuickAction(
        'Pedidos',
        'Revisar y gestionar',
        Icons.receipt_long_rounded,
        const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F2A2A), Color(0xFF0A1E1E)],
        ),
        AppColors.accentTeal,
        '/admin/pedidos',
      ),
      _QuickAction(
        'Devoluciones',
        'Aprobar o rechazar',
        Icons.assignment_return_rounded,
        const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2E22), Color(0xFF0F1E16)],
        ),
        AppColors.accentEmerald,
        '/admin/devoluciones',
      ),
      _QuickAction(
        'Ofertas Flash',
        'Activar campañas',
        Icons.flash_on_rounded,
        const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E2810), Color(0xFF1E1A0A)],
        ),
        AppColors.gold400,
        '/admin/flash-offers',
      ),
      _QuickAction(
        'Cupones',
        'Códigos de descuento',
        Icons.confirmation_number_rounded,
        const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF162828), Color(0xFF0E1C1C)],
        ),
        AppColors.accentTeal,
        '/admin/cupones',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.gold500.withValues(alpha: 0.15),
                    AppColors.gold500.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.gold500.withValues(alpha: 0.10),
                ),
              ),
              child: const Icon(
                Icons.rocket_launch_rounded,
                color: AppColors.gold500,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Acceso rápido',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Gestión del negocio',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // ── Custom staggered layout ──
        // Row 1: hero card full-width
        _buildQuickActionCard(actions[0], isHero: true),
        const SizedBox(height: 12),
        // Row 2: two columns
        Row(
          children: [
            Expanded(child: _buildQuickActionCard(actions[1])),
            const SizedBox(width: 12),
            Expanded(child: _buildQuickActionCard(actions[2])),
          ],
        ),
        const SizedBox(height: 12),
        // Row 3: two columns
        Row(
          children: [
            Expanded(child: _buildQuickActionCard(actions[3])),
            const SizedBox(width: 12),
            Expanded(child: _buildQuickActionCard(actions[4])),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(_QuickAction action, {bool isHero = false}) {
    return _ScaleTap(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.push(action.route);
      },
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (_, _) {
          final glow = _glowAnim.value;
          return Container(
            height: isHero ? 110 : 130,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: action.gradient,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: action.color.withValues(alpha: 0.12 + 0.08 * glow),
              ),
              boxShadow: [
                BoxShadow(
                  color: action.color.withValues(alpha: 0.10 + 0.06 * glow),
                  blurRadius: 24 + 8 * glow,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // ── Holographic scan line ──
                AnimatedBuilder(
                  animation: _shimmerAnim,
                  builder: (_, _) {
                    final t = _shimmerAnim.value;
                    return Positioned(
                      left: 0,
                      right: 0,
                      top: -2 + (isHero ? 114 : 134) * (t.clamp(0.0, 1.0)),
                      child: Container(
                        height: 1.5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              action.color.withValues(alpha: 0.35),
                              action.color.withValues(alpha: 0.5),
                              action.color.withValues(alpha: 0.35),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // ── HUD corner brackets: top-left ──
                Positioned(
                  top: 0,
                  left: 0,
                  child: CustomPaint(
                    size: const Size(18, 18),
                    painter: _CornerBracketPainter(
                      color: action.color.withValues(alpha: 0.30 + 0.15 * glow),
                      corner: _Corner.topLeft,
                    ),
                  ),
                ),
                // ── HUD corner brackets: bottom-right ──
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CustomPaint(
                    size: const Size(18, 18),
                    painter: _CornerBracketPainter(
                      color: action.color.withValues(alpha: 0.30 + 0.15 * glow),
                      corner: _Corner.bottomRight,
                    ),
                  ),
                ),

                // ── Glowing energy bar at bottom ──
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 0,
                  child: Container(
                    height: 2.5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        colors: [
                          action.color.withValues(alpha: 0.0),
                          action.color.withValues(alpha: 0.4 + 0.25 * glow),
                          action.color.withValues(alpha: 0.0),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: action.color.withValues(alpha: 0.3 * glow),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Content ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  child: isHero
                      ? _buildHeroContent(action, glow)
                      : _buildCompactContent(action, glow),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Hero card content — horizontal layout for full-width card
  Widget _buildHeroContent(_QuickAction action, double glow) {
    return Row(
      children: [
        // Diamond-rotated icon
        _buildDiamondIcon(action, glow, size: 52),
        const SizedBox(width: 18),
        // Text content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                action.label.toUpperCase(),
                style: TextStyle(
                  color: action.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                action.subtitle,
                style: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // Chevron pulse
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: action.color.withValues(alpha: 0.06 + 0.04 * glow),
            border: Border.all(
              color: action.color.withValues(alpha: 0.12 + 0.08 * glow),
            ),
          ),
          child: Icon(
            Icons.arrow_forward_rounded,
            color: action.color.withValues(alpha: 0.7 + 0.3 * glow),
            size: 18,
          ),
        ),
      ],
    );
  }

  /// Compact card content — vertical layout for grid cards
  Widget _buildCompactContent(_QuickAction action, double glow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Diamond icon
        _buildDiamondIcon(action, glow, size: 42),
        const Spacer(),
        // Label with tracking
        Text(
          action.label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 3),
        // Animated underline + subtitle
        Row(
          children: [
            // Pulsing accent dash
            Container(
              width: 16 + 4 * glow,
              height: 2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                color: action.color.withValues(alpha: 0.6 + 0.3 * glow),
                boxShadow: [
                  BoxShadow(
                    color: action.color.withValues(alpha: 0.2 * glow),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                action.subtitle,
                style: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Diamond-shaped icon container with orbiting ring
  Widget _buildDiamondIcon(
    _QuickAction action,
    double glow, {
    required double size,
  }) {
    final innerSize = size * 0.72;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer rotating ring
          AnimatedBuilder(
            animation: _shimmerAnim,
            builder: (_, _) => Transform.rotate(
              angle: _shimmerAnim.value * 2 * math.pi / 3,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: action.color.withValues(alpha: 0.08 + 0.06 * glow),
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: action.color.withValues(alpha: 0.6 + 0.4 * glow),
                      boxShadow: [
                        BoxShadow(
                          color: action.color.withValues(alpha: 0.4 * glow),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Diamond (45° rotated rounded square)
          Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: innerSize,
              height: innerSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    action.color.withValues(alpha: 0.20),
                    action.color.withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(innerSize * 0.28),
                border: Border.all(
                  color: action.color.withValues(alpha: 0.18 + 0.1 * glow),
                ),
                boxShadow: [
                  BoxShadow(
                    color: action.color.withValues(alpha: 0.12 + 0.08 * glow),
                    blurRadius: 14 + 6 * glow,
                  ),
                ],
              ),
            ),
          ),
          // Icon (not rotated)
          Icon(action.icon, color: action.color, size: innerSize * 0.52),
        ],
      ),
    );
  }
}

// ─── Helper classes ───
class _KPI {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _KPI(this.label, this.value, this.icon, this.color, [this.onTap]);
}

class _Stage {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  const _Stage(this.label, this.count, this.color, this.icon);
}

class _LiveStat {
  final String value;
  final String label;
  final Color color;
  final IconData icon;
  const _LiveStat(this.value, this.label, this.color, this.icon);
}

class _QuickAction {
  final String label;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final Color color;
  final String route;
  const _QuickAction(
    this.label,
    this.subtitle,
    this.icon,
    this.gradient,
    this.color,
    this.route,
  );
}

class _StatusSlice {
  final String label;
  final int count;
  final Color color;
  const _StatusSlice(this.label, this.count, this.color);
}

// ─── HUD Corner Bracket Painter ───
enum _Corner { topLeft, bottomRight }

class _CornerBracketPainter extends CustomPainter {
  final Color color;
  final _Corner corner;
  const _CornerBracketPainter({required this.color, required this.corner});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final len = size.width * 0.7;

    switch (corner) {
      case _Corner.topLeft:
        canvas.drawLine(const Offset(2, 2), Offset(2 + len, 2), paint);
        canvas.drawLine(const Offset(2, 2), Offset(2, 2 + len), paint);
        break;
      case _Corner.bottomRight:
        canvas.drawLine(
          Offset(size.width - 2, size.height - 2),
          Offset(size.width - 2 - len, size.height - 2),
          paint,
        );
        canvas.drawLine(
          Offset(size.width - 2, size.height - 2),
          Offset(size.width - 2, size.height - 2 - len),
          paint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(_CornerBracketPainter old) =>
      color != old.color || corner != old.corner;
}

// ─── Scale Tap Animation Widget ───
class _ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _ScaleTap({required this.child, required this.onTap});

  @override
  State<_ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<_ScaleTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
