import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../shared/widgets/loader.dart';
import '../../../../shared/extensions/date_extensions.dart';
import '../../../../shared/extensions/number_extensions.dart';

/// Modelo de devolución / solicitud de reembolso
class ReturnModel {
  final String id;
  final String orderId;
  final String? returnNumber;
  final String? userId;
  final String type; // 'cancellation' o 'return'
  final String reason;
  final String? description;
  final String
  status; // pending, approved, rejected, completed, received, refunded, cancelled, expired
  final double refundAmount;
  final String? customerEmail;
  final String? adminNotes;
  final String? createdAt;
  final String? updatedAt;
  final String? orderNumber;
  // Items JSON almacenados en la columna 'items'
  final List<Map<String, dynamic>> refundItems;

  ReturnModel({
    required this.id,
    required this.orderId,
    this.returnNumber,
    this.userId,
    this.type = 'return',
    required this.reason,
    this.description,
    required this.status,
    this.refundAmount = 0,
    this.customerEmail,
    this.adminNotes,
    this.createdAt,
    this.updatedAt,
    this.orderNumber,
    this.refundItems = const [],
  });

  factory ReturnModel.fromJson(Map<String, dynamic> json) {
    // Parsear items (columna 'items' JSONB en la tabla returns)
    List<Map<String, dynamic>> items = [];
    final raw = json['items'];
    if (raw is List) {
      items = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    return ReturnModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      returnNumber: json['return_number'] as String?,
      userId: json['user_id'] as String?,
      type: json['type'] as String? ?? 'return',
      reason: json['reason'] as String? ?? '',
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'pending',
      refundAmount: (json['refund_amount'] as num?)?.toDouble() ?? 0,
      customerEmail: json['customer_email'] as String?,
      adminNotes: json['admin_notes'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      orderNumber:
          (json['orders'] as Map<String, dynamic>?)?['order_number'] as String?,
      refundItems: items,
    );
  }
}

/// Provider de devoluciones del usuario
final returnsProvider = FutureProvider<List<ReturnModel>>((ref) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];

  final response = await client
      .from('returns')
      .select('*, orders(order_number)')
      .eq('user_id', userId)
      .order('created_at', ascending: false);

  return (response as List)
      .map((json) => ReturnModel.fromJson(json as Map<String, dynamic>))
      .toList();
});

/// Provider para admin — todos los returns
final allReturnsProvider = FutureProvider<List<ReturnModel>>((ref) async {
  final response = await Supabase.instance.client
      .from('returns')
      .select('*, orders(order_number)')
      .order('created_at', ascending: false);

  return (response as List)
      .map((json) => ReturnModel.fromJson(json as Map<String, dynamic>))
      .toList();
});

class ReturnsScreen extends ConsumerWidget {
  const ReturnsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final returnsAsync = ref.watch(returnsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Mis Devoluciones', style: AppTextStyles.h4),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: returnsAsync.when(
        loading: () => const Loader(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (returns) {
          if (returns.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_return_outlined,
                    size: 60,
                    color: AppColors.textMuted.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes devoluciones',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: returns.length,
            itemBuilder: (context, index) {
              final ret = returns[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            ret.returnNumber ??
                                ret.orderNumber ??
                                ret.orderId.substring(0, 8),
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _buildStatusChip(ret.status),
                      ],
                    ),
                    if (ret.orderNumber != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Pedido: ${ret.orderNumber}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Motivo: ${ret.reason}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    // Items del reembolso
                    if (ret.refundItems.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ...ret.refundItems.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  (item['product_image'] as String?) ?? '',
                                  width: 40,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    width: 40,
                                    height: 50,
                                    color: AppColors.surface,
                                    child: const Icon(
                                      Icons.image,
                                      size: 16,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (item['product_name'] as String?) ?? '',
                                      style: AppTextStyles.caption.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Talla: ${item['size'] ?? '-'} · x${item['quantity'] ?? 1}',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                ((item['subtotal'] as num?)?.toDouble() ?? 0)
                                    .toEuroCurrency,
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    // Importe del reembolso
                    if (ret.refundAmount > 0) ...[
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Importe reembolso',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            ret.refundAmount.toEuroCurrency,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700,
                              color:
                                  ret.status == 'approved' ||
                                      ret.status == 'completed'
                                  ? AppColors.success
                                  : AppColors.gold500,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (ret.adminNotes != null &&
                        ret.adminNotes!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: ret.status == 'rejected'
                              ? AppColors.error.withValues(alpha: 0.1)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              ret.status == 'rejected'
                                  ? Icons.info_outline
                                  : Icons.chat_bubble_outline,
                              color: ret.status == 'rejected'
                                  ? AppColors.error
                                  : AppColors.textMuted,
                              size: 14,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                ret.adminNotes!,
                                style: AppTextStyles.caption.copyWith(
                                  color: ret.status == 'rejected'
                                      ? AppColors.error
                                      : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (ret.createdAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        DateTime.tryParse(ret.createdAt!)?.fullDate ?? '',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'pending':
        color = AppColors.warning;
        label = 'Pendiente';
        break;
      case 'approved':
        color = AppColors.success;
        label = 'Aprobada';
        break;
      case 'rejected':
        color = AppColors.error;
        label = 'Rechazada';
        break;
      case 'completed':
        color = AppColors.info;
        label = 'Completada';
        break;
      default:
        color = AppColors.textMuted;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
