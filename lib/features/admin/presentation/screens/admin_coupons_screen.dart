import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../shared/services/api_client.dart';
import '../../../../shared/services/email_service.dart';
import '../../../../shared/widgets/animations.dart';

/// ─── Provider: lista de cupones ───
final couponsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((
  ref,
) async {
  final response = await Supabase.instance.client
      .from('discount_codes')
      .select()
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

class AdminCouponsScreen extends ConsumerStatefulWidget {
  const AdminCouponsScreen({super.key});

  @override
  ConsumerState<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends ConsumerState<AdminCouponsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final List<Animation<double>> _anims;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _anims = createStaggerAnimations(
      controller: _animCtrl,
      count: 8,
      delayPerItem: 0.07,
      itemDuration: 0.28,
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final couponsAsync = ref.watch(couponsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ═══ COMPACT APP BAR ═══
          SliverAppBar(
            expandedHeight: 0,
            toolbarHeight: 52,
            floating: true,
            pinned: true,
            backgroundColor: AppColors.surface,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.06),
                  ),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
              ),
              onPressed: () => context.pop(),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFAB7BFF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.confirmation_number_rounded,
                    size: 13,
                    color: Color(0xFFAB7BFF),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Cupones', style: AppTextStyles.h4.copyWith(fontSize: 15)),
              ],
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFAB7BFF), Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  onPressed: () => _showCouponDialog(),
                ),
              ),
            ],
          ),

          // ═══ SEARCH BAR ═══
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: FadeSlideItem(
                index: 0,
                animation: _anims[0],
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.06),
                    ),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Buscar por código...',
                      hintStyle: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.4),
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppColors.textMuted.withValues(alpha: 0.35),
                        size: 18,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ═══ STATS ROW ═══
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: FadeSlideItem(
                index: 1,
                animation: _anims[1],
                child: couponsAsync.when(
                  loading: () => const SizedBox(),
                  error: (e, s) => const SizedBox(),
                  data: (coupons) {
                    final active = coupons
                        .where((c) => c['is_active'] == true)
                        .length;
                    final total = coupons.length;
                    return Row(
                      children: [
                        _statChip(
                          'Total',
                          '$total',
                          const Color(0xFFAB7BFF),
                          Icons.confirmation_number_rounded,
                        ),
                        const SizedBox(width: 10),
                        _statChip(
                          'Activos',
                          '$active',
                          AppColors.success,
                          Icons.check_circle_rounded,
                        ),
                        const SizedBox(width: 10),
                        _statChip(
                          'Inactivos',
                          '${total - active}',
                          AppColors.textMuted,
                          Icons.pause_circle_rounded,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),

          // ═══ COUPONS LIST ═══
          couponsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: BouncingDotsLoader(color: Color(0xFFAB7BFF)),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error.withValues(alpha: 0.5),
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Error: $e',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            data: (coupons) {
              final filtered = _search.isEmpty
                  ? coupons
                  : coupons
                        .where(
                          (c) => (c['code'] ?? '')
                              .toString()
                              .toLowerCase()
                              .contains(_search.toLowerCase()),
                        )
                        .toList();

              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.confirmation_number_outlined,
                          size: 48,
                          color: AppColors.textMuted.withValues(alpha: 0.25),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _search.isEmpty
                              ? 'No hay cupones creados'
                              : 'Sin resultados',
                          style: TextStyle(
                            color: AppColors.textMuted.withValues(alpha: 0.5),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Pulsa + para crear un cupón de descuento',
                          style: TextStyle(
                            color: AppColors.textMuted.withValues(alpha: 0.35),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final coupon = filtered[index];
                    final animIdx = (index + 2).clamp(0, _anims.length - 1);
                    return FadeSlideItem(
                      index: index + 2,
                      animation: _anims[animIdx],
                      child: _buildCouponCard(coupon),
                    );
                  }, childCount: filtered.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── STAT CHIP ───
  Widget _statChip(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color.withValues(alpha: 0.6), size: 16),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── SAFE TYPE HELPERS ───
  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  // ─── COUPON CARD ───
  Widget _buildCouponCard(Map<String, dynamic> coupon) {
    final code = coupon['code'] ?? '';
    final discountType = coupon['discount_type']?.toString() ?? 'percentage';
    final discountValue = _toDouble(coupon['discount_value']);
    final isActive = coupon['is_active'] == true;
    final minOrder = _toDouble(coupon['min_purchase_amount']);
    final maxUses = _toInt(coupon['max_uses']);
    final usesCount = _toInt(coupon['uses_count']);
    final expiresAt = coupon['valid_until'];
    final expiryDate = expiresAt != null
        ? DateTime.tryParse(expiresAt.toString())
        : null;
    final id = coupon['id'];

    final isExpired = expiryDate?.isBefore(DateTime.now()) == true;

    final discountDisplay = discountType == 'percentage'
        ? '${discountValue.toStringAsFixed(0)}%'
        : '${discountValue.toStringAsFixed(2)}€';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive && !isExpired
              ? const Color(0xFFAB7BFF).withValues(alpha: 0.12)
              : AppColors.border.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color:
                (isActive && !isExpired
                        ? const Color(0xFFAB7BFF)
                        : Colors.black)
                    .withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showCouponDialog(coupon: coupon),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Code + Badge + Actions
                Row(
                  children: [
                    // Discount badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: isActive && !isExpired
                            ? const LinearGradient(
                                colors: [Color(0xFFAB7BFF), Color(0xFF7C3AED)],
                              )
                            : LinearGradient(
                                colors: [
                                  AppColors.textMuted.withValues(alpha: 0.2),
                                  AppColors.textMuted.withValues(alpha: 0.15),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        discountDisplay,
                        style: TextStyle(
                          color: isActive && !isExpired
                              ? Colors.white
                              : AppColors.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            code.toString().toUpperCase(),
                            style: TextStyle(
                              color: isActive && !isExpired
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            discountType == 'percentage'
                                ? 'Descuento porcentual'
                                : 'Descuento fijo',
                            style: TextStyle(
                              color: AppColors.textMuted.withValues(alpha: 0.5),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isExpired
                            ? AppColors.error.withValues(alpha: 0.1)
                            : isActive
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.textMuted.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isExpired
                            ? 'Expirado'
                            : isActive
                            ? 'Activo'
                            : 'Inactivo',
                        style: TextStyle(
                          color: isExpired
                              ? AppColors.error
                              : isActive
                              ? AppColors.success
                              : AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    // Toggle + Delete
                    PopupMenuButton<String>(
                      iconSize: 18,
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: AppColors.textMuted.withValues(alpha: 0.4),
                        size: 18,
                      ),
                      color: AppColors.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'toggle',
                          child: Row(
                            children: [
                              Icon(
                                isActive
                                    ? Icons.pause_circle_rounded
                                    : Icons.play_circle_rounded,
                                size: 16,
                                color: isActive
                                    ? AppColors.warning
                                    : AppColors.success,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isActive ? 'Desactivar' : 'Activar',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'publish',
                          child: Row(
                            children: [
                              Icon(
                                Icons.send_rounded,
                                size: 16,
                                color: const Color(
                                  0xFFAB7BFF,
                                ).withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Publicar',
                                style: TextStyle(
                                  color: const Color(
                                    0xFFAB7BFF,
                                  ).withValues(alpha: 0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_rounded,
                                size: 16,
                                color: AppColors.error.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Eliminar',
                                style: TextStyle(
                                  color: AppColors.error.withValues(alpha: 0.8),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (action) {
                        if (action == 'toggle') {
                          _toggleCoupon(id, !isActive);
                        } else if (action == 'delete') {
                          _deleteCoupon(id, code);
                        } else if (action == 'publish') {
                          _publishCoupon(coupon);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Row 2: Meta info
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      _metaItem(
                        Icons.shopping_bag_outlined,
                        'Min: ${minOrder > 0 ? '${minOrder.toStringAsFixed(0)}€' : '-'}',
                      ),
                      _metaSeparator(),
                      _metaItem(
                        Icons.repeat_rounded,
                        'Usos: $usesCount${maxUses > 0 ? '/$maxUses' : ''}',
                      ),
                      _metaSeparator(),
                      _metaItem(
                        Icons.schedule_rounded,
                        expiryDate != null
                            ? DateFormat(
                                'dd/MM/yy',
                              ).format(expiryDate.toLocal())
                            : 'Sin fecha',
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

  Widget _metaItem(IconData icon, String text) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 12,
            color: AppColors.textMuted.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaSeparator() {
    return Container(
      width: 1,
      height: 14,
      color: AppColors.border.withValues(alpha: 0.06),
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  // ─── TOGGLE ACTIVE ───
  Future<void> _toggleCoupon(String id, bool active) async {
    HapticFeedback.mediumImpact();
    try {
      await ApiClient.instance.postFunction(
        'manage-coupons',
        body: {
          'action': 'toggle',
          'id': id,
          'data': {'is_active': active},
        },
      );
      ref.invalidate(couponsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar estado: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ─── DELETE ───
  Future<void> _deleteCoupon(String id, String code) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Eliminar cupón',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text.rich(
          TextSpan(
            text: '¿Eliminar el cupón ',
            style: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.7),
              fontSize: 14,
            ),
            children: [
              TextSpan(
                text: code.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const TextSpan(text: '?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.6),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    HapticFeedback.mediumImpact();
    try {
      await ApiClient.instance.postFunction(
        'manage-coupons',
        body: {'action': 'delete', 'id': id},
      );
      ref.invalidate(couponsProvider);
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
                Text('Cupón $code eliminado'),
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
  }

  // ─── PUBLISH COUPON (BROADCAST EMAIL) ───
  Future<void> _publishCoupon(Map<String, dynamic> coupon) async {
    final code = (coupon['code'] ?? '').toString().toUpperCase();
    final discountType = coupon['discount_type']?.toString() ?? 'percentage';
    final discountValue = _toDouble(coupon['discount_value']);
    final minOrder = _toDouble(coupon['min_purchase_amount']);
    final expiresAt = coupon['valid_until'];

    final discountDisplay = discountType == 'percentage'
        ? '${discountValue.toStringAsFixed(0)}%'
        : '${discountValue.toStringAsFixed(2)}€';
    final expiryDate = expiresAt != null
        ? DateTime.tryParse(expiresAt.toString())
        : null;
    final expiryStr = expiryDate != null
        ? DateFormat('dd/MM/yyyy').format(expiryDate.toLocal())
        : null;

    // Confirmar
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFAB7BFF).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Color(0xFFAB7BFF),
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Publicar cupón',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFAB7BFF).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFAB7BFF).withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    code,
                    style: const TextStyle(
                      color: Color(0xFFAB7BFF),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$discountDisplay de descuento',
                    style: TextStyle(
                      color: AppColors.textMuted.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Se enviará un email con este cupón a todos los clientes registrados.',
              style: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.7),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.6),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Enviar a todos',
              style: TextStyle(
                color: Color(0xFFAB7BFF),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    HapticFeedback.mediumImpact();

    // Mostrar loading
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Enviando emails...'),
            ],
          ),
          backgroundColor: const Color(0xFF7C3AED),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 30),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    try {
      final client = Supabase.instance.client;

      // Recopilar emails únicos de clientes (desde pedidos)
      final ordersResp = await client
          .from('orders')
          .select('customer_email, shipping_full_name, user_id')
          .order('created_at', ascending: false);

      final emailMap = <String, String>{};
      for (final o in (ordersResp as List)) {
        final email = o['customer_email']?.toString() ?? '';
        if (email.isNotEmpty && !emailMap.containsKey(email)) {
          emailMap[email] = o['shipping_full_name']?.toString() ?? 'Cliente';
        }
      }

      // También recopilar de suscriptores del newsletter
      try {
        final subsResp = await client
            .from('newsletter_subscribers')
            .select('email')
            .eq('status', 'subscribed');
        for (final s in (subsResp as List)) {
          final email = s['email']?.toString() ?? '';
          if (email.isNotEmpty && !emailMap.containsKey(email)) {
            emailMap[email] = 'Cliente';
          }
        }
      } catch (_) {}

      final recipients = emailMap.entries
          .map((e) => {'email': e.key, 'name': e.value})
          .toList();

      final sent = await EmailService.sendCouponBroadcast(
        recipients: recipients,
        couponCode: code,
        discountDisplay: discountDisplay,
        minOrder: minOrder > 0 ? minOrder.toStringAsFixed(0) : null,
        expiresAt: expiryStr,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
                Text(
                  'Cupón enviado a $sent destinatario${sent != 1 ? 's' : ''}',
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
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  // ─── ADD / EDIT DIALOG ───
  Future<void> _showCouponDialog({Map<String, dynamic>? coupon}) async {
    final isEdit = coupon != null;
    final codeCtrl = TextEditingController(
      text: coupon?['code']?.toString() ?? '',
    );
    final valueCtrl = TextEditingController(
      text: coupon?['discount_value']?.toString() ?? '',
    );
    final minOrderCtrl = TextEditingController(
      text: coupon?['min_purchase_amount']?.toString() ?? '',
    );
    final maxUsesCtrl = TextEditingController(
      text: coupon?['max_uses']?.toString() ?? '',
    );
    String discountType = coupon?['discount_type']?.toString() ?? 'percentage';
    bool isActive = coupon != null ? coupon['is_active'] == true : true;
    DateTime? expiresAt = coupon?['valid_until'] != null
        ? DateTime.tryParse(coupon!['valid_until'].toString())
        : null;
    bool saving = false;
    bool needsRefresh = false;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFAB7BFF).withValues(alpha: 0.1),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFAB7BFF,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          isEdit ? Icons.edit_rounded : Icons.add_rounded,
                          color: const Color(0xFFAB7BFF),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isEdit ? 'Editar Cupón' : 'Nuevo Cupón',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Code
                  _dialogField(
                    codeCtrl,
                    'Código',
                    Icons.confirmation_number_rounded,
                    'Ej: VERANO25',
                  ),
                  const SizedBox(height: 12),

                  // Discount type selector
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setSheetState(() => discountType = 'percentage'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: discountType == 'percentage'
                                  ? const Color(
                                      0xFFAB7BFF,
                                    ).withValues(alpha: 0.12)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: discountType == 'percentage'
                                    ? const Color(
                                        0xFFAB7BFF,
                                      ).withValues(alpha: 0.3)
                                    : AppColors.border.withValues(alpha: 0.06),
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.percent_rounded,
                                  color: discountType == 'percentage'
                                      ? const Color(0xFFAB7BFF)
                                      : AppColors.textMuted.withValues(
                                          alpha: 0.4,
                                        ),
                                  size: 20,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Porcentaje',
                                  style: TextStyle(
                                    color: discountType == 'percentage'
                                        ? const Color(0xFFAB7BFF)
                                        : AppColors.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setSheetState(() => discountType = 'fixed'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: discountType == 'fixed'
                                  ? const Color(
                                      0xFFAB7BFF,
                                    ).withValues(alpha: 0.12)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: discountType == 'fixed'
                                    ? const Color(
                                        0xFFAB7BFF,
                                      ).withValues(alpha: 0.3)
                                    : AppColors.border.withValues(alpha: 0.06),
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.euro_rounded,
                                  color: discountType == 'fixed'
                                      ? const Color(0xFFAB7BFF)
                                      : AppColors.textMuted.withValues(
                                          alpha: 0.4,
                                        ),
                                  size: 20,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Fijo (€)',
                                  style: TextStyle(
                                    color: discountType == 'fixed'
                                        ? const Color(0xFFAB7BFF)
                                        : AppColors.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Value
                  _dialogField(
                    valueCtrl,
                    discountType == 'percentage' ? 'Valor (%)' : 'Valor (€)',
                    Icons.sell_rounded,
                    discountType == 'percentage' ? 'Ej: 15' : 'Ej: 5.00',
                    isNumber: true,
                  ),
                  const SizedBox(height: 12),

                  // Min order + Max uses
                  Row(
                    children: [
                      Expanded(
                        child: _dialogField(
                          minOrderCtrl,
                          'Mín. pedido €',
                          Icons.shopping_cart_rounded,
                          '0',
                          isNumber: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _dialogField(
                          maxUsesCtrl,
                          'Máx. usos',
                          Icons.repeat_rounded,
                          'Vacío = ilimitado',
                          isNumber: true,
                          intOnly: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Expires date picker
                  GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: ctx,
                        initialDate:
                            expiresAt ??
                            DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365 * 2),
                        ),
                        builder: (context, child) => Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Color(0xFFAB7BFF),
                              surface: Color(0xFF1A1A1A),
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (date != null) {
                        setSheetState(() => expiresAt = date);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: AppColors.textMuted.withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              expiresAt != null
                                  ? 'Expira: ${DateFormat('dd/MM/yyyy').format(expiresAt!)}'
                                  : 'Sin fecha de expiración',
                              style: TextStyle(
                                color: expiresAt != null
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted.withValues(
                                        alpha: 0.4,
                                      ),
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (expiresAt != null)
                            GestureDetector(
                              onTap: () =>
                                  setSheetState(() => expiresAt = null),
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: AppColors.textMuted.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Active toggle
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.power_settings_new_rounded,
                          size: 16,
                          color: isActive
                              ? AppColors.success
                              : AppColors.textMuted.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Cupón activo',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Switch(
                          value: isActive,
                          onChanged: (v) => setSheetState(() => isActive = v),
                          activeThumbColor: AppColors.success,
                          activeTrackColor: AppColors.success.withValues(
                            alpha: 0.3,
                          ),
                          inactiveThumbColor: AppColors.textMuted.withValues(
                            alpha: 0.4,
                          ),
                          inactiveTrackColor: AppColors.surface,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Save button
                  GestureDetector(
                    onTap: saving
                        ? null
                        : () async {
                            final code = codeCtrl.text.trim().toUpperCase();
                            final value = double.tryParse(valueCtrl.text) ?? 0;

                            if (code.isEmpty || value <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Código y valor son obligatorios',
                                  ),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                              return;
                            }

                            setSheetState(() => saving = true);
                            HapticFeedback.mediumImpact();

                            final maxUsesVal = int.tryParse(maxUsesCtrl.text);

                            final data = {
                              'code': code,
                              'discount_type': discountType,
                              'discount_value': value,
                              'min_purchase_amount':
                                  double.tryParse(minOrderCtrl.text) ?? 0,
                              'max_uses': (maxUsesVal != null && maxUsesVal > 0)
                                  ? maxUsesVal
                                  : null,
                              'is_active': isActive,
                              'valid_until': expiresAt?.toIso8601String(),
                            };

                            try {
                              await ApiClient.instance.postFunction(
                                'manage-coupons',
                                body: {
                                  'action': isEdit ? 'update' : 'create',
                                  if (isEdit) 'id': coupon!['id'],
                                  'data': data,
                                },
                              );

                              needsRefresh = true;
                              if (ctx.mounted) Navigator.pop(ctx);
                            } catch (e) {
                              if (ctx.mounted) {
                                setSheetState(() => saving = false);
                              }
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: saving
                            ? LinearGradient(
                                colors: [
                                  const Color(
                                    0xFFAB7BFF,
                                  ).withValues(alpha: 0.3),
                                  const Color(
                                    0xFF7C3AED,
                                  ).withValues(alpha: 0.3),
                                ],
                              )
                            : const LinearGradient(
                                colors: [Color(0xFFAB7BFF), Color(0xFF7C3AED)],
                              ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: saving
                            ? []
                            : [
                                BoxShadow(
                                  color: const Color(
                                    0xFFAB7BFF,
                                  ).withValues(alpha: 0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: saving
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isEdit
                                      ? Icons.save_rounded
                                      : Icons.add_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isEdit ? 'ACTUALIZAR CUPÓN' : 'CREAR CUPÓN',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
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
        },
      ),
    );

    // Defer controller disposal to after the modal exit animation completes.
    // Disposing immediately causes TextFields still alive in the exit
    // animation to reference disposed controllers → ErrorWidget crash.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      codeCtrl.dispose();
      valueCtrl.dispose();
      minOrderCtrl.dispose();
      maxUsesCtrl.dispose();
    });

    // Show success and refresh after the modal is fully closed
    if (needsRefresh && mounted) {
      // Small delay to let the modal exit animation finish completely
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
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
              Text(isEdit ? 'Cupón actualizado' : 'Cupón creado'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      ref.invalidate(couponsProvider);
    }
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String label,
    IconData icon,
    String hint, {
    bool isNumber = false,
    bool intOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: isNumber
            ? (intOnly
                  ? TextInputType.number
                  : const TextInputType.numberWithOptions(decimal: true))
            : TextInputType.text,
        inputFormatters: intOnly
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        textCapitalization: isNumber
            ? TextCapitalization.none
            : TextCapitalization.characters,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: AppColors.textMuted.withValues(alpha: 0.5),
            fontSize: 12,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.textMuted.withValues(alpha: 0.3),
            fontSize: 12,
          ),
          prefixIcon: Icon(
            icon,
            color: AppColors.textMuted.withValues(alpha: 0.35),
            size: 16,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
