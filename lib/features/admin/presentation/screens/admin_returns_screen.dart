import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../shared/widgets/animations.dart';
import '../../../../shared/extensions/date_extensions.dart';
import '../../../../shared/extensions/number_extensions.dart';
import '../../../../shared/services/api_client.dart';
import '../../../returns/presentation/screens/returns_screen.dart';

const _kReturnTabs = <String, String>{
  'all': 'Todas',
  'pending': 'Pendientes',
  'approved': 'Aprobadas',
  'rejected': 'Rechazadas',
  'completed': 'Completadas',
};

class AdminReturnsScreen extends ConsumerStatefulWidget {
  const AdminReturnsScreen({super.key});

  @override
  ConsumerState<AdminReturnsScreen> createState() => _AdminReturnsScreenState();
}

class _AdminReturnsScreenState extends ConsumerState<AdminReturnsScreen>
    with SingleTickerProviderStateMixin {
  String _statusFilter = 'all';
  bool _isProcessingRefund = false;

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
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  List<ReturnModel> _applyFilters(List<ReturnModel> returns) {
    if (_statusFilter == 'all') return returns;
    return returns.where((r) => r.status == _statusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final returnsAsync = ref.watch(allReturnsProvider);

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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.refresh_rounded, size: 18),
                ),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  ref.invalidate(allReturnsProvider);
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
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.assignment_return_rounded,
                      size: 14,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Devoluciones',
                    style: AppTextStyles.h4.copyWith(fontSize: 16),
                  ),
                ],
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
                children: _kReturnTabs.entries.map((e) {
                  final selected = _statusFilter == e.key;
                  final color = _returnStatusColor(e.key);
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

          // ═══ RETURNS LIST ═══
          returnsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: BouncingDotsLoader(color: AppColors.warning),
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
            data: (allReturns) {
              final returns = _applyFilters(allReturns);

              if (returns.isEmpty) {
                return SliverFillRemaining(
                  child: AnimatedEmptyState(
                    icon: Icons.assignment_return_outlined,
                    title: 'No hay devoluciones',
                    subtitle: _statusFilter != 'all'
                        ? 'No hay devoluciones con este estado'
                        : 'Las devoluciones aparecerán aquí',
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
                        child: Row(
                          children: [
                            Text(
                              '${returns.length} devolución${returns.length != 1 ? 'es' : ''}',
                              style: TextStyle(
                                color: AppColors.textMuted.withValues(
                                  alpha: 0.6,
                                ),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${allReturns.where((r) => r.status == 'pending').length} pendientes',
                              style: TextStyle(
                                color: AppColors.warning.withValues(alpha: 0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final ret = returns[index - 1];
                    final animIdx = index.clamp(0, _anims.length - 1);
                    return FadeSlideItem(
                      index: index,
                      animation: _anims[animIdx],
                      child: _buildReturnTile(ret),
                    );
                  }, childCount: returns.length + 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Return Tile ───
  Widget _buildReturnTile(ReturnModel ret) {
    final color = _returnStatusColor(ret.status);
    final label = _returnStatusLabel(ret.status);
    final icon = _returnStatusIcon(ret.status);

    return GestureDetector(
      onTap: () => context.push('/admin/pedidos/${ret.orderId}'),
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
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: color, size: 14),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          ret.orderNumber ?? '#${ret.orderId.substring(0, 8)}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
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

                  // Reason
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: AppColors.textMuted.withValues(alpha: 0.4),
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ret.reason,
                            style: TextStyle(
                              color: AppColors.textMuted.withValues(alpha: 0.8),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Refund items
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
                                width: 36,
                                height: 45,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 36,
                                  height: 45,
                                  color: AppColors.surface,
                                  child: const Icon(
                                    Icons.image,
                                    size: 14,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (item['product_name'] as String?) ?? '',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Talla: ${item['size'] ?? '-'} · x${item['quantity'] ?? 1}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textMuted.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              ((item['subtotal'] as num?)?.toDouble() ?? 0)
                                  .toEuroCurrency,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Refund amount
                  if (ret.refundAmount > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold500.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Importe reembolso',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            ret.refundAmount.toEuroCurrency,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gold500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (ret.requestedAt != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          color: AppColors.textMuted.withValues(alpha: 0.4),
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateTime.tryParse(ret.requestedAt!)?.fullDate ?? '',
                          style: TextStyle(
                            color: AppColors.textMuted.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Actions
            if (ret.status == 'pending')
              Container(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showApproveRejectDialog(ret, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.success,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Aprobar',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showApproveRejectDialog(ret, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.cancel_rounded,
                                  color: AppColors.error,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Rechazar',
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
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

            if (ret.status == 'approved')
              Container(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: GestureDetector(
                  onTap: _isProcessingRefund
                      ? null
                      : () async {
                          HapticFeedback.lightImpact();
                          await _completeRefund(ret);
                        },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(
                        alpha: _isProcessingRefund ? 0.05 : 0.1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Center(
                      child: _isProcessingRefund
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.info,
                              ),
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.currency_exchange_rounded,
                                  color: AppColors.info,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Completar y reembolsar',
                                  style: TextStyle(
                                    color: AppColors.info,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
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

  // ─── Helpers ───
  Future<void> _updateReturnStatus(
    String returnId,
    String status, {
    String? adminNotes,
  }) async {
    final data = <String, dynamic>{'status': status};
    await Supabase.instance.client
        .from('returns')
        .update(data)
        .eq('id', returnId);
  }

  /// Diálogo para aprobar / rechazar con notas del admin
  Future<void> _showApproveRejectDialog(ReturnModel ret, bool isApprove) async {
    final notesCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(isApprove ? 'Aprobar reembolso' : 'Rechazar reembolso'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isApprove
                  ? 'El cliente recibirá un email de aprobación.'
                  : 'El cliente recibirá un email con el motivo del rechazo.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            if (ret.refundAmount > 0) ...[
              const SizedBox(height: 10),
              Text(
                'Importe: ${ret.refundAmount.toEuroCurrency}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.gold500,
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: isApprove
                    ? 'Notas para el cliente (opcional)'
                    : 'Motivo del rechazo...',
                hintStyle: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              isApprove ? 'Aprobar' : 'Rechazar',
              style: TextStyle(
                color: isApprove ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    HapticFeedback.lightImpact();
    final notes = notesCtrl.text.trim();
    final action = isApprove ? 'approve' : 'reject';

    try {
      // Backend maneja: actualizar estado, enviar emails
      await ApiClient.instance.postFunction(
        'manage-return',
        body: {
          'returnId': ret.id,
          'action': action,
          if (notes.isNotEmpty) 'adminNotes': notes,
        },
      );
    } catch (_) {
      // Fallback: actualizar localmente si el backend falla
      await _updateReturnStatus(
        ret.id,
        isApprove ? 'approved' : 'rejected',
        adminNotes: notes,
      );
    }

    ref.invalidate(allReturnsProvider);
  }

  /// Completar reembolso vía backend (Stripe refund + stock + estado)
  Future<void> _completeRefund(ReturnModel ret) async {
    if (_isProcessingRefund) return;
    setState(() => _isProcessingRefund = true);

    try {
      HapticFeedback.lightImpact();

      // Backend maneja: refund Stripe, restaurar stock, actualizar estados, email
      await ApiClient.instance.postFunction(
        'manage-return',
        body: {'returnId': ret.id, 'action': 'complete'},
      );

      ref.invalidate(allReturnsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reembolso completado correctamente'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al completar reembolso: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingRefund = false);
      }
    }
  }

  Color _returnStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'completed':
        return AppColors.info;
      default:
        return AppColors.textPrimary;
    }
  }

  String _returnStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'approved':
        return 'Aprobada';
      case 'rejected':
        return 'Rechazada';
      case 'completed':
        return 'Completada';
      default:
        return status;
    }
  }

  IconData _returnStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule_rounded;
      case 'approved':
        return Icons.check_circle_outline_rounded;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'completed':
        return Icons.done_all_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}
