import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../shared/widgets/cached_image.dart';
import '../../../../shared/widgets/loader.dart';
import '../../../../shared/extensions/number_extensions.dart';
import '../../../../shared/services/api_client.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import 'returns_screen.dart';

/// Pantalla de solicitud de reembolso parcial / devolución.
///
/// El usuario selecciona los productos que quiere devolver,
/// escribe un motivo y envía la solicitud. Se requiere la
/// aprobación del administrador.
class RefundRequestScreen extends ConsumerStatefulWidget {
  final String orderId;
  const RefundRequestScreen({super.key, required this.orderId});

  @override
  ConsumerState<RefundRequestScreen> createState() =>
      _RefundRequestScreenState();
}

/// Valores permitidos por el CHECK constraint de la columna reason.
const _reasonOptions = <String, String>{
  'defective': 'Producto defectuoso',
  'wrong_item': 'Producto incorrecto',
  'wrong_size': 'Talla incorrecta',
  'not_as_described': 'No coincide con la descripción',
  'changed_mind': 'He cambiado de opinión',
  'too_late': 'Llegó demasiado tarde',
  'better_price': 'Encontré mejor precio',
  'other': 'Otro motivo',
};

class _RefundRequestScreenState extends ConsumerState<RefundRequestScreen> {
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  /// Motivo seleccionado (valor de la BD)
  String? _selectedReason;

  /// Mapa productId+size → seleccionado
  final Map<String, bool> _selected = {};

  /// Mapa productId+size → cantidad a devolver
  final Map<String, int> _quantities = {};

  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  String _itemKey(OrderItemModel item) => '${item.productId}_${item.size}';

  double _refundAmount(List<OrderItemModel> items) {
    double total = 0;
    for (final item in items) {
      final key = _itemKey(item);
      if (_selected[key] == true) {
        final qty = _quantities[key] ?? item.quantity;
        total += item.price * qty;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderByIdProvider(widget.orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Solicitar reembolso', style: AppTextStyles.h4),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: orderAsync.when(
        loading: () => const Loader(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (order) => _buildBody(order),
      ),
    );
  }

  Widget _buildBody(OrderModel order) {
    final items = order.orderItems;
    final amount = _refundAmount(items);
    final anySelected = _selected.values.any((v) => v);

    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Info del pedido ───
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.receipt_long_outlined,
                          color: AppColors.gold500,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Pedido ${order.orderNumber ?? '#${order.id.substring(0, 8)}'}',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          order.total.toEuroCurrency,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.gold500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── Seleccionar productos ───
                  Text(
                    'Selecciona los productos a devolver',
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Marca los artículos que deseas devolver y ajusta la cantidad si es necesario.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 14),

                  ...items.map((item) => _buildItemTile(item)),
                  const SizedBox(height: 24),

                  // ─── Motivo (dropdown) ───
                  Text('Motivo de la devolución', style: AppTextStyles.h4),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedReason,
                    decoration: InputDecoration(
                      hintText: 'Selecciona un motivo...',
                      hintStyle: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.gold500,
                          width: 1,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                    ),
                    dropdownColor: AppColors.surface,
                    style: AppTextStyles.bodySmall,
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.gold500,
                    ),
                    items: _reasonOptions.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedReason = v),
                    validator: (v) {
                      if (v == null) return 'Selecciona un motivo';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // ─── Descripción (texto libre) ───
                  Text('Descripción', style: AppTextStyles.h4),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText:
                          'Explica con más detalle el problema (opcional)...',
                      hintStyle: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.gold500,
                          width: 1,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ─── Barra inferior: resumen + botón ───
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.border.withValues(alpha: 0.1)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (anySelected) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Importe a reembolsar',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          amount.toEuroCurrency,
                          style: AppTextStyles.h4.copyWith(
                            color: AppColors.gold500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: anySelected && !_isSubmitting
                          ? () => _submitRequest(order)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold500,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: AppColors.gold500.withValues(
                          alpha: 0.3,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              'ENVIAR SOLICITUD',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
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
  }

  // ─── Item tile con checkbox y selector de cantidad ───
  Widget _buildItemTile(OrderItemModel item) {
    final key = _itemKey(item);
    final isSelected = _selected[key] == true;
    final qty = _quantities[key] ?? item.quantity;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selected[key] = !isSelected;
          if (!_quantities.containsKey(key)) {
            _quantities[key] = item.quantity;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gold500.withValues(alpha: 0.06)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.gold500.withValues(alpha: 0.4)
                : AppColors.border.withValues(alpha: 0.06),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.gold500 : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? AppColors.gold500 : AppColors.textMuted,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.black)
                  : null,
            ),
            const SizedBox(width: 12),
            // Imagen
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedImage(
                imageUrl: item.productImage ?? '',
                width: 56,
                height: 70,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName ?? '',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Talla: ${item.size ?? '-'}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.price.toEuroCurrency,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Selector de cantidad (solo si seleccionado y qty > 1)
            if (isSelected && item.quantity > 1) ...[
              const SizedBox(width: 8),
              Column(
                children: [
                  Text(
                    'Cant.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _qtyBtn(Icons.remove, () {
                          if (qty > 1) {
                            setState(() => _quantities[key] = qty - 1);
                          }
                        }),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '$qty',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        _qtyBtn(Icons.add, () {
                          if (qty < item.quantity) {
                            setState(() => _quantities[key] = qty + 1);
                          }
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ] else if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                'x${item.quantity}',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 16, color: AppColors.textSecondary),
      ),
    );
  }

  // ─── Enviar solicitud ───
  Future<void> _submitRequest(OrderModel order) async {
    if (!_formKey.currentState!.validate()) return;
    if (!_selected.values.any((v) => v)) return;

    setState(() => _isSubmitting = true);

    try {
      final reason = _selectedReason!;
      final description = _descriptionController.text.trim();

      // Build selected items list for the return
      final selectedItems = <Map<String, dynamic>>[];
      for (final item in order.orderItems) {
        final key = _itemKey(item);
        if (_selected[key] == true) {
          final qty = _quantities[key] ?? item.quantity;
          selectedItems.add({
            'product_id': item.productId,
            'product_name': item.productName ?? 'Producto',
            'product_image': item.productImage ?? '',
            'order_item_id': item.id,
            'size': item.size ?? 'Única',
            'quantity': qty,
            'refund_amount': item.price * qty,
          });
        }
      }

      final totalRefund = _refundAmount(order.orderItems);

      // Edge Function maneja: crear return, actualizar pedido, enviar email
      await ApiClient.instance.postFunction(
        'manage-return',
        body: {
          'action': 'request',
          'orderId': order.id,
          'reason': description.isEmpty
              ? (_reasonOptions[reason] ?? reason)
              : description,
          'items': selectedItems,
          'refundAmount': totalRefund,
        },
      );

      // Invalidar providers
      ref.invalidate(ordersProvider);
      ref.invalidate(orderByIdProvider(widget.orderId));
      ref.invalidate(returnsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Solicitud enviada · Recibirás una respuesta pronto',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        context.pop();
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
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
