import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../shared/exceptions/failure.dart';
import '../../../../shared/widgets/cached_image.dart';
import '../../../../shared/widgets/loader.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/extensions/number_extensions.dart';
import '../../../../shared/extensions/date_extensions.dart';
import '../../../../shared/services/api_client.dart';
import '../../../../shared/services/invoice_pdf_service.dart';
import '../../data/models/order_model.dart';
import '../providers/orders_provider.dart';
import '../../../products/presentation/providers/products_provider.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderByIdProvider(orderId));

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) ref.invalidate(ordersProvider);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Detalle del pedido', style: AppTextStyles.h4),
          centerTitle: true,
          backgroundColor: AppColors.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        body: orderAsync.when(
          loading: () => const Loader(),
          error: (error, _) => AppErrorWidget(
            message: error is Failure
                ? error.userMessage
                : 'Error al cargar el pedido',
            onRetry: () => ref.invalidate(orderByIdProvider(orderId)),
          ),
          data: (order) => RefreshIndicator(
            color: AppColors.accentGold,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              ref.invalidate(orderByIdProvider(orderId));
              await ref.read(orderByIdProvider(orderId).future);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Número de pedido
                  Text(
                    order.orderNumber ?? '#${order.id.substring(0, 8)}',
                    style: AppTextStyles.h3,
                  ),
                  if (order.createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      DateTime.tryParse(order.createdAt!)?.fullDate ?? '',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Timeline de estado
                  _buildTimeline(order.status),
                  const SizedBox(height: 24),

                  // Items del pedido
                  Text('Productos', style: AppTextStyles.h4),
                  const SizedBox(height: 12),
                  ...order.orderItems.map(
                    (item) => _buildOrderItem(context, item),
                  ),
                  const SizedBox(height: 24),

                  // Resumen económico
                  Text('Resumen', style: AppTextStyles.h4),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _row('Subtotal', order.subtotal.toEuroCurrency),
                        _row(
                          'Envío',
                          order.shippingCost > 0
                              ? order.shippingCost.toEuroCurrency
                              : 'Gratis',
                        ),
                        if (order.discount > 0)
                          _row(
                            'Descuento',
                            '-${order.discount.toEuroCurrency}',
                            color: AppColors.success,
                          ),
                        const Divider(height: 24),
                        _row('Total', order.total.toEuroCurrency, isBold: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Dirección de envío
                  Text('Dirección de envío', style: AppTextStyles.h4),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (order.shippingFullName != null)
                          Text(
                            order.shippingFullName!,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (order.shippingAddressLine1 != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            order.shippingAddressLine1!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (order.shippingCity != null ||
                            order.shippingPostalCode != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${order.shippingPostalCode ?? ''} ${order.shippingCity ?? ''}, ${order.shippingState ?? ''}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── Botón descargar factura PDF ───
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          InvoicePdfService.generateAndShare(context, order),
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                      label: const Text('DESCARGAR FACTURA'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGold,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── Acciones según estado + ventana de 2h ───
                  ..._buildOrderActions(context, ref, order),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline(String currentStatus) {
    final statuses = [
      'pending',
      'confirmed',
      'processing',
      'shipped',
      'delivered',
    ];
    final labels = [
      'Pendiente',
      'Confirmado',
      'Procesando',
      'Enviado',
      'Entregado',
    ];

    if (currentStatus == 'cancelled' ||
        currentStatus == 'refunded' ||
        currentStatus == 'return_requested') {
      final isReturn = currentStatus == 'return_requested';
      final statusColor = isReturn ? AppColors.warning : AppColors.error;
      final statusIcon = isReturn
          ? Icons.assignment_return_outlined
          : Icons.cancel_outlined;
      final statusText = currentStatus == 'cancelled'
          ? 'Pedido cancelado'
          : currentStatus == 'refunded'
          ? 'Reembolsado'
          : 'Reembolso solicitado';
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 24),
            const SizedBox(width: 12),
            Text(
              statusText,
              style: AppTextStyles.body.copyWith(color: statusColor),
            ),
          ],
        ),
      );
    }

    final currentIndex = statuses.indexOf(currentStatus);

    return Column(
      children: List.generate(statuses.length, (index) {
        final isCompleted = index <= currentIndex;
        final isCurrent = index == currentIndex;

        return Row(
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted ? AppColors.gold500 : AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted ? AppColors.gold500 : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.black, size: 14)
                      : null,
                ),
                if (index < statuses.length - 1)
                  Container(
                    width: 2,
                    height: 30,
                    color: isCompleted
                        ? AppColors.gold500
                        : AppColors.border.withValues(alpha: 0.3),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Text(
              labels[index],
              style: AppTextStyles.body.copyWith(
                color: isCurrent
                    ? AppColors.gold500
                    : isCompleted
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildOrderItem(BuildContext context, OrderItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: CachedImage(
              imageUrl: item.productImage ?? '',
              width: 60,
              height: 75,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName ?? '',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Talla: ${item.size ?? '-'} · x${item.quantity}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            item.subtotal.toEuroCurrency,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color ?? AppColors.textSecondary,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? AppColors.textPrimary,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  ACCIONES SEGÚN VENTANA DE CANCELACIÓN (2 HORAS)
  // ═══════════════════════════════════════════════════════════

  List<Widget> _buildOrderActions(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
  ) {
    final widgets = <Widget>[];
    final canCancel = _canCancelOrder(order);
    final canRefund = _canRequestRefund(order);

    if (canCancel) {
      widgets.addAll([
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _processCancellation(context, ref, order),
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('CANCELAR PEDIDO'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'Tiempo restante: ${_remainingCancelTime(order)}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ),
      ]);
    }

    if (canRefund) {
      widgets.add(
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () =>
                context.push('/perfil/mis-pedidos/${order.id}/reembolso'),
            icon: const Icon(Icons.currency_exchange_rounded, size: 18),
            label: Text(
              order.status == 'delivered'
                  ? 'SOLICITAR DEVOLUCIÓN'
                  : 'SOLICITAR REEMBOLSO',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.warning,
              side: const BorderSide(color: AppColors.warning),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  bool _canCancelOrder(OrderModel order) {
    if (order.status != 'pending' && order.status != 'confirmed') return false;
    if (order.createdAt == null) return true;
    final created = DateTime.tryParse(order.createdAt!);
    if (created == null) return true;
    return DateTime.now().toUtc().difference(created.toUtc()).inMinutes < 120;
  }

  bool _canRequestRefund(OrderModel order) {
    const noRefund = ['cancelled', 'refunded', 'return_requested'];
    if (noRefund.contains(order.status)) return false;
    if (_canCancelOrder(order)) return false;
    const refundable = [
      'pending',
      'confirmed',
      'processing',
      'shipped',
      'delivered',
    ];
    return refundable.contains(order.status);
  }

  String _remainingCancelTime(OrderModel order) {
    if (order.createdAt == null) return '';
    final created = DateTime.tryParse(order.createdAt!);
    if (created == null) return '';
    final deadline = created.toUtc().add(const Duration(hours: 2));
    final remaining = deadline.difference(DateTime.now().toUtc());
    if (remaining.isNegative) return 'expirado';
    final h = remaining.inHours;
    final m = remaining.inMinutes % 60;
    if (h > 0) return '${h}h ${m}min';
    return '$m min';
  }

  Future<void> _processCancellation(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Cancelar pedido'),
        content: const Text(
          '¿Estás seguro de que quieres cancelar este pedido?\n'
          'Se procesará el reembolso del importe completo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Sí, cancelar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.gold500),
      ),
    );

    try {
      // Backend maneja: refund Stripe, restaurar stock, returns record, email
      await ApiClient.instance.postFunction(
        'cancel-order',
        body: {'orderId': order.id},
      );

      // Refrescar providers
      ref.invalidate(ordersProvider);
      ref.invalidate(orderByIdProvider(order.id));
      // Refrescar stock de productos
      ref.invalidate(productsProvider);
      ref.invalidate(featuredProductsProvider);
      ref.invalidate(newProductsProvider);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pedido cancelado · Reembolso en proceso'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cancelar: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}
