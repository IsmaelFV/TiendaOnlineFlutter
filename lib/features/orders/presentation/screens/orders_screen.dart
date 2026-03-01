import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../shared/extensions/number_extensions.dart';
import '../../../../shared/widgets/loader.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/animated_press.dart';
import '../../../../shared/widgets/animations.dart';
import '../../../../shared/extensions/date_extensions.dart';
import '../../data/models/order_model.dart';
import '../providers/orders_provider.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _staggerCtrl;
  late final List<Animation<double>> _anims;

  // ── Filtro multi-selección de estados ──
  final Set<String> _selectedStatuses = {};

  static const _allStatuses = [
    _OrderStatus(
      'pending',
      'Pendiente',
      Icons.hourglass_top_rounded,
      AppColors.warning,
    ),
    _OrderStatus(
      'confirmed',
      'Confirmado',
      Icons.check_circle_outline_rounded,
      AppColors.info,
    ),
    _OrderStatus(
      'processing',
      'Procesando',
      Icons.settings_outlined,
      Color(0xFF6366F1),
    ),
    _OrderStatus(
      'shipped',
      'Enviado',
      Icons.local_shipping_outlined,
      AppColors.accentTeal,
    ),
    _OrderStatus(
      'delivered',
      'Entregado',
      Icons.done_all_rounded,
      AppColors.success,
    ),
    _OrderStatus(
      'cancelled',
      'Cancelado',
      Icons.cancel_outlined,
      AppColors.error,
    ),
    _OrderStatus(
      'refunded',
      'Reembolsado',
      Icons.currency_exchange_rounded,
      AppColors.textMuted,
    ),
    _OrderStatus(
      'return_requested',
      'Devolución',
      Icons.assignment_return_outlined,
      AppColors.warning,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();
    _anims = createStaggerAnimations(
      controller: _staggerCtrl,
      count: 15,
      delayPerItem: 0.06,
      itemDuration: 0.25,
    );
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  void _toggleStatus(String status) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedStatuses.contains(status)) {
        _selectedStatuses.remove(status);
      } else {
        _selectedStatuses.add(status);
      }
    });
    _staggerCtrl.reset();
    _staggerCtrl.forward();
  }

  void _clearFilters() {
    HapticFeedback.lightImpact();
    setState(() => _selectedStatuses.clear());
    _staggerCtrl.reset();
    _staggerCtrl.forward();
  }

  List<OrderModel> _filterOrders(List<OrderModel> orders) {
    if (_selectedStatuses.isEmpty) return orders;
    return orders.where((o) => _selectedStatuses.contains(o.status)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GoldIcon(icon: Icons.receipt_long_outlined, size: 22),
            const SizedBox(width: 8),
            Text('Mis Pedidos', style: AppTextStyles.h4),
          ],
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: ordersAsync.when(
        loading: () => const Loader(),
        error: (error, _) => AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(ordersProvider),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return AnimatedEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No tienes pedidos a\u00fan',
              subtitle:
                  'Cuando realices una compra, tus pedidos aparecer\u00e1n aqu\u00ed',
              buttonText: 'EXPLORAR TIENDA',
              onAction: () => context.go('/productos'),
            );
          }

          final filtered = _filterOrders(orders);
          final existingStatuses = orders.map((o) => o.status).toSet();
          final availableStatuses = _allStatuses
              .where((s) => existingStatuses.contains(s.key))
              .toList();

          return Column(
            children: [
              // ── Barra de filtros ──
              if (availableStatuses.length > 1)
                _buildFilterBar(availableStatuses),

              // ── Lista de pedidos ──
              Expanded(
                child: filtered.isEmpty
                    ? _buildNoResults()
                    : RefreshIndicator(
                        color: AppColors.accentGold,
                        backgroundColor: AppColors.surface,
                        onRefresh: () async {
                          ref.invalidate(ordersProvider);
                          await ref.read(ordersProvider.future);
                          _staggerCtrl.reset();
                          _staggerCtrl.forward();
                        },
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final order = filtered[index];
                            final animIdx = index.clamp(0, _anims.length - 1);
                            return FadeSlideItem(
                              index: index,
                              animation: _anims[animIdx],
                              child: _buildOrderCard(context, order),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  BARRA DE FILTROS MULTI-SELECCIÓN
  // ─────────────────────────────────────────────────────────
  Widget _buildFilterBar(List<_OrderStatus> availableStatuses) {
    final hasFilters = _selectedStatuses.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.15)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Icon(
                  Icons.filter_list_rounded,
                  size: 16,
                  color: hasFilters ? AppColors.gold500 : AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  'Filtrar por estado',
                  style: AppTextStyles.caption.copyWith(
                    color: hasFilters ? AppColors.gold500 : AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    fontSize: 11,
                  ),
                ),
                if (hasFilters) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_selectedStatuses.length}',
                      style: const TextStyle(
                        color: AppColors.gold500,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (hasFilters)
                  GestureDetector(
                    onTap: _clearFilters,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold500.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.close_rounded,
                            size: 12,
                            color: AppColors.gold500,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Limpiar',
                            style: TextStyle(
                              color: AppColors.gold500,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              itemCount: availableStatuses.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final status = availableStatuses[index];
                final selected = _selectedStatuses.contains(status.key);
                return _FilterChip(
                  status: status,
                  selected: selected,
                  onTap: () => _toggleStatus(status.key),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  SIN RESULTADOS
  // ─────────────────────────────────────────────────────────
  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: AppColors.textMuted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin resultados',
              style: AppTextStyles.h4.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'No hay pedidos con los estados seleccionados',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.filter_list_off_rounded, size: 18),
              label: const Text('QUITAR FILTROS'),
              style: TextButton.styleFrom(foregroundColor: AppColors.gold500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    final isActive = [
      'pending',
      'confirmed',
      'processing',
      'shipped',
    ].contains(order.status);

    return AnimatedPress(
      scaleDown: 0.97,
      onPressed: () {
        HapticFeedback.lightImpact();
        context.push('/perfil/mis-pedidos/${order.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? AppColors.gold500.withValues(alpha: 0.12)
                : AppColors.border.withValues(alpha: 0.1),
          ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GoldIcon(icon: _statusIcon(order.status), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      order.orderNumber ?? '#${order.id.substring(0, 8)}',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                isActive
                    ? PulseGlow(
                        glowColor: _statusConfig(order.status).color,
                        maxRadius: 6,
                        borderRadius: BorderRadius.circular(20),
                        child: _buildStatusBadge(order.status),
                      )
                    : _buildStatusBadge(order.status),
              ],
            ),
            const SizedBox(height: 10),
            if (order.createdAt != null)
              Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateTime.tryParse(order.createdAt!)?.fullDate ?? '',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.border.withValues(alpha: 0.0),
                    AppColors.border.withValues(alpha: 0.2),
                    AppColors.border.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${order.orderItems.length} producto${order.orderItems.length > 1 ? 's' : ''}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  order.total.toEuroCurrency,
                  style: AppTextStyles.price.copyWith(fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'confirmed':
        return Icons.check_circle_outline_rounded;
      case 'processing':
        return Icons.settings_outlined;
      case 'shipped':
        return Icons.local_shipping_outlined;
      case 'delivered':
        return Icons.done_all_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'refunded':
        return Icons.currency_exchange_rounded;
      case 'return_requested':
        return Icons.assignment_return_outlined;
      default:
        return Icons.receipt_outlined;
    }
  }

  Widget _buildStatusBadge(String status) {
    final config = _statusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          color: config.color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  _StatusConfig _statusConfig(String status) {
    switch (status) {
      case 'pending':
        return _StatusConfig('Pendiente', AppColors.warning);
      case 'confirmed':
        return _StatusConfig('Confirmado', AppColors.info);
      case 'processing':
        return _StatusConfig('Procesando', const Color(0xFF6366F1));
      case 'shipped':
        return _StatusConfig('Enviado', AppColors.accentTeal);
      case 'delivered':
        return _StatusConfig('Entregado', AppColors.success);
      case 'cancelled':
        return _StatusConfig('Cancelado', AppColors.error);
      case 'refunded':
        return _StatusConfig('Reembolsado', AppColors.textMuted);
      case 'return_requested':
        return _StatusConfig('Devoluci\u00f3n', AppColors.warning);
      default:
        return _StatusConfig(status, AppColors.textMuted);
    }
  }
}

// ═════════════════════════════════════════════════════════════
//  WIDGETS PRIVADOS
// ═════════════════════════════════════════════════════════════

class _StatusConfig {
  final String label;
  final Color color;
  _StatusConfig(this.label, this.color);
}

class _OrderStatus {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  const _OrderStatus(this.key, this.label, this.icon, this.color);
}

/// Chip de filtro animado con glow al seleccionar
class _FilterChip extends StatelessWidget {
  final _OrderStatus status;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.status,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? status.color.withValues(alpha: 0.18)
              : AppColors.card.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? status.color.withValues(alpha: 0.5)
                : AppColors.border.withValues(alpha: 0.15),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: status.color.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              status.icon,
              size: 14,
              color: selected ? status.color : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              status.label,
              style: TextStyle(
                color: selected ? status.color : AppColors.textMuted,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 4),
              Icon(Icons.check_rounded, size: 13, color: status.color),
            ],
          ],
        ),
      ),
    );
  }
}
