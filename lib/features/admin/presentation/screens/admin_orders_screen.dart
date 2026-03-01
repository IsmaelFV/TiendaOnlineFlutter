import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../shared/extensions/number_extensions.dart';
import '../../../../shared/widgets/animations.dart';
import '../../../../shared/extensions/date_extensions.dart';
import '../../../../shared/services/api_client.dart';
import '../../../../shared/services/email_service.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../orders/presentation/providers/orders_provider.dart';

// ─── Status filter ───
const _kStatusTabs = <String, String>{
  'all': 'Todos',
  'pending': 'Pendiente',
  'confirmed': 'Confirmado',
  'processing': 'Procesando',
  'shipped': 'Enviado',
  'delivered': 'Entregado',
  'cancelled': 'Cancelado',
  'refunded': 'Reembolsado',
};

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _statusFilter = 'all';

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

  List<OrderModel> _applyFilters(List<OrderModel> orders) {
    var result = orders;
    if (_query.isNotEmpty) {
      result = result.where((o) {
        final num = (o.orderNumber ?? o.id).toLowerCase();
        final name = (o.shippingFullName ?? '').toLowerCase();
        final email = (o.customerEmail ?? '').toLowerCase();
        return num.contains(_query) ||
            name.contains(_query) ||
            email.contains(_query);
      }).toList();
    }
    if (_statusFilter != 'all') {
      result = result.where((o) => o.status == _statusFilter).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(allOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
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
                  ref.invalidate(allOrdersProvider);
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
                      color: AppColors.accentTeal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      size: 14,
                      color: AppColors.accentTeal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Pedidos',
                    style: AppTextStyles.h4.copyWith(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          // ═══ SEARCH ═══
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
                          hintText: 'Buscar por nº, nombre o email...',
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

          // ═══ STATUS TABS ═══
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                children: _kStatusTabs.entries.map((e) {
                  final selected = _statusFilter == e.key;
                  final color = _statusColor(e.key);
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _statusFilter = e.key);
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
                          e.value,
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

          // ═══ ORDER LIST ═══
          ordersAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: BouncingDotsLoader(color: AppColors.accentTeal),
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
            data: (allOrders) {
              final orders = _applyFilters(allOrders);

              if (orders.isEmpty) {
                return SliverFillRemaining(
                  child: AnimatedEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: _query.isNotEmpty
                        ? 'Sin resultados'
                        : 'No hay pedidos',
                    subtitle: _query.isNotEmpty
                        ? 'Intenta con otro término'
                        : 'Los pedidos aparecerán aquí',
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8, top: 4),
                        child: Text(
                          '${orders.length} pedido${orders.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            color: AppColors.textMuted.withValues(alpha: 0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }

                    final order = orders[index - 1];
                    final animIdx = index.clamp(0, _anims.length - 1);
                    return FadeSlideItem(
                      index: index,
                      animation: _anims[animIdx],
                      child: _buildOrderTile(order),
                    );
                  }, childCount: orders.length + 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Order Tile ───
  Widget _buildOrderTile(OrderModel order) {
    final color = _statusColor(order.status);
    final label = _statusLabel(order.status);
    final transitions = _availableTransitions(order.status);

    return GestureDetector(
      onTap: () => context.push('/admin/pedidos/${order.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.04)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _statusIcon(order.status),
                          color: color,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.orderNumber ??
                                  '#${order.id.substring(0, 8)}',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              order.shippingFullName ?? 'Sin nombre',
                              style: TextStyle(
                                color: AppColors.textMuted.withValues(
                                  alpha: 0.7,
                                ),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Amount and date row
                  Row(
                    children: [
                      Text(
                        order.total.toEuroCurrency,
                        style: const TextStyle(
                          color: AppColors.gold400,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.calendar_today_rounded,
                        color: AppColors.textMuted.withValues(alpha: 0.4),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        order.createdAt != null
                            ? DateTime.tryParse(order.createdAt!)?.shortDate ??
                                  ''
                            : '',
                        style: TextStyle(
                          color: AppColors.textMuted.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            if (transitions.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Row(
                  children: transitions.map((t) {
                    final tColor = t['color'] as Color;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: t != transitions.last ? 8 : 0,
                        ),
                        child: GestureDetector(
                          onTap: () async {
                            HapticFeedback.lightImpact();
                            final newStatus = t['status']! as String;

                            // Confirmación para acciones destructivas
                            if (newStatus == 'cancelled') {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: AppColors.surface,
                                  title: const Text('Cancelar pedido'),
                                  content: Text(
                                    '¿Cancelar pedido ${order.orderNumber ?? order.id.substring(0, 8)}?\n'
                                    'Se hará reembolso en Stripe y se restaurará el stock.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('No'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text(
                                        'Sí, cancelar',
                                        style: TextStyle(
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed != true) return;

                              // Usar Edge Function cancel-order (refund + stock)
                              try {
                                await ApiClient.instance.postFunction(
                                  'cancel-order',
                                  body: {'orderId': order.id},
                                );
                              } catch (e) {
                                // Fallback: al menos actualizar estado
                                await updateOrderStatus(order.id, 'cancelled');
                              }
                              ref.invalidate(allOrdersProvider);
                              return;
                            }

                            await updateOrderStatus(order.id, newStatus);
                            // Enviar email de cambio de estado al cliente
                            try {
                              await EmailService.sendOrderStatusUpdate(
                                order: order,
                                newStatus: newStatus,
                              );
                            } catch (_) {
                              // No bloquear si falla el email
                            }
                            ref.invalidate(allOrdersProvider);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: tColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: tColor.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                t['label']! as String,
                                style: TextStyle(
                                  color: tColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ───
  List<Map<String, dynamic>> _availableTransitions(String status) {
    switch (status) {
      case 'pending':
        return [
          {
            'label': 'Confirmar',
            'status': 'confirmed',
            'color': AppColors.success,
          },
          {
            'label': 'Cancelar',
            'status': 'cancelled',
            'color': AppColors.error,
          },
        ];
      case 'confirmed':
        return [
          {
            'label': 'Procesar',
            'status': 'processing',
            'color': AppColors.info,
          },
          {
            'label': 'Cancelar',
            'status': 'cancelled',
            'color': AppColors.error,
          },
        ];
      case 'processing':
        return [
          {
            'label': 'Enviar',
            'status': 'shipped',
            'color': AppColors.accentTeal,
          },
        ];
      case 'shipped':
        return [
          {
            'label': 'Entregado',
            'status': 'delivered',
            'color': AppColors.success,
          },
        ];
      case 'return_requested':
        return [
          {
            'label': 'Reembolsar',
            'status': 'refunded',
            'color': AppColors.warning,
          },
        ];
      default:
        return [];
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
        return AppColors.info;
      case 'processing':
        return const Color(0xFF6366F1);
      case 'shipped':
        return AppColors.accentTeal;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      case 'refunded':
        return AppColors.textMuted;
      case 'return_requested':
        return AppColors.warning;
      default:
        return AppColors.textPrimary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'confirmed':
        return 'Confirmado';
      case 'processing':
        return 'Procesando';
      case 'shipped':
        return 'Enviado';
      case 'delivered':
        return 'Entregado';
      case 'cancelled':
        return 'Cancelado';
      case 'refunded':
        return 'Reembolsado';
      case 'return_requested':
        return 'Devolución';
      default:
        return status;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule_rounded;
      case 'confirmed':
        return Icons.check_circle_outline_rounded;
      case 'processing':
        return Icons.settings_rounded;
      case 'shipped':
        return Icons.local_shipping_rounded;
      case 'delivered':
        return Icons.done_all_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'refunded':
        return Icons.currency_exchange_rounded;
      case 'return_requested':
        return Icons.assignment_return_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}
