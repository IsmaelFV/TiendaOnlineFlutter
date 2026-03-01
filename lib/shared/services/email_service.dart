import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';

import '../../features/orders/data/models/order_model.dart';
import 'invoice_pdf_service.dart';

/// Servicio de emails transaccionales vía API de Brevo (Sendinblue).
///
/// Llama directamente a la API REST de Brevo desde Flutter.
/// No necesita Edge Functions, CLI ni despliegues adicionales.
class EmailService {
  static const _apiKey =
      'YOUR_BREVO_API_KEY_HERE';
  static const _fromEmail = 'ismaelfloresvargas22@gmail.com';
  static const _fromName = 'Fashion Store';
  static const _apiUrl = 'https://api.brevo.com/v3/smtp/email';

  static final _dio = Dio(
    BaseOptions(
      baseUrl: _apiUrl,
      headers: {
        'api-key': _apiKey,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  // ═══════════════════════════════════════════════════════════════
  //  MÉTODOS PÚBLICOS
  // ═══════════════════════════════════════════════════════════════

  /// Email de confirmación de compra.
  static Future<void> sendPurchaseConfirmation({
    required OrderModel order,
  }) async {
    final orderNum = order.orderNumber ?? '#${order.id.substring(0, 8)}';
    final html = _baseLayout(
      title: '¡Gracias por tu compra!',
      preheader: 'Tu pedido $orderNum ha sido confirmado',
      body:
          '''
        <h2 style="color:#C9A84C;margin:0 0 8px">Pedido confirmado</h2>
        <p style="color:#aaa;margin:0 0 20px">Pedido <strong style="color:#fff">$orderNum</strong></p>
        <p style="color:#ccc;line-height:1.6">
          Hemos recibido tu pedido y lo estamos preparando.
          Recibirás una notificación cuando se envíe.
        </p>
        ${_itemsTable(order.orderItems)}
        ${_invoiceSummary(order.subtotal, order.shippingCost, order.discount, order.total)}
      ''',
    );
    await _sendEmail(
      toEmail: order.customerEmail ?? '',
      toName: order.shippingFullName ?? 'Cliente',
      subject: 'Confirmación de pedido $orderNum — Fashion Store',
      html: html,
      attachment: await _pdfAttachment(order, 'factura'),
    );
  }

  /// Email de cancelación de pedido.
  static Future<void> sendOrderCancelled({required OrderModel order}) async {
    final orderNum = order.orderNumber ?? '#${order.id.substring(0, 8)}';
    final html = _baseLayout(
      title: 'Pedido cancelado',
      preheader: 'Tu pedido $orderNum ha sido cancelado',
      body:
          '''
        <h2 style="color:#E53935;margin:0 0 8px">Pedido cancelado</h2>
        <p style="color:#aaa;margin:0 0 20px">Pedido <strong style="color:#fff">$orderNum</strong></p>
        <p style="color:#ccc;line-height:1.6">
          Tu pedido ha sido cancelado correctamente.
          El reembolso de <strong style="color:#C9A84C">${_euro(order.total)} €</strong>
          se procesará en los próximos días.
        </p>
        ${_itemsTable(order.orderItems)}
        ${_creditNote(order.total)}
      ''',
    );
    await _sendEmail(
      toEmail: order.customerEmail ?? '',
      toName: order.shippingFullName ?? 'Cliente',
      subject: 'Pedido $orderNum cancelado — Fashion Store',
      html: html,
      attachment: await _pdfAttachment(order, 'abono'),
    );
  }

  /// Email de solicitud de reembolso recibida.
  static Future<void> sendRefundRequested({
    required OrderModel order,
    required List<OrderItemModel> refundItems,
    required double refundAmount,
    required String reason,
  }) async {
    final orderNum = order.orderNumber ?? '#${order.id.substring(0, 8)}';
    final html = _baseLayout(
      title: 'Solicitud de reembolso recibida',
      preheader: 'Hemos recibido tu solicitud de reembolso para $orderNum',
      body:
          '''
        <h2 style="color:#FFA726;margin:0 0 8px">Solicitud recibida</h2>
        <p style="color:#aaa;margin:0 0 20px">Pedido <strong style="color:#fff">$orderNum</strong></p>
        <p style="color:#ccc;line-height:1.6">
          Hemos recibido tu solicitud de reembolso. Nuestro equipo la revisará
          y te notificaremos la resolución por email.
        </p>
        <div style="background:#1a1a1a;border-radius:8px;padding:12px;margin:16px 0">
          <p style="color:#aaa;margin:0 0 4px;font-size:12px">MOTIVO</p>
          <p style="color:#ccc;margin:0">${_esc(reason)}</p>
        </div>
        <p style="color:#aaa;font-size:13px;margin:0 0 12px">Artículos a devolver:</p>
        ${_itemsTable(refundItems)}
        <table width="100%" style="margin-top:16px"><tr>
          <td style="color:#aaa;font-size:14px">Importe solicitado</td>
          <td align="right" style="color:#C9A84C;font-size:18px;font-weight:700">${_euro(refundAmount)} €</td>
        </tr></table>
      ''',
    );
    await _sendEmail(
      toEmail: order.customerEmail ?? '',
      toName: order.shippingFullName ?? 'Cliente',
      subject: 'Solicitud de reembolso recibida — $orderNum',
      html: html,
    );
  }

  /// Email de reembolso aprobado.
  static Future<void> sendRefundApproved({
    required String toEmail,
    required String toName,
    required String orderNumber,
    required List<Map<String, dynamic>> refundItems,
    required double refundAmount,
    String? adminNotes,
  }) async {
    final html = _baseLayout(
      title: '¡Reembolso aprobado!',
      preheader: 'Tu reembolso para el pedido $orderNumber ha sido aprobado',
      body:
          '''
        <h2 style="color:#43A047;margin:0 0 8px">Reembolso aprobado</h2>
        <p style="color:#aaa;margin:0 0 20px">Pedido <strong style="color:#fff">$orderNumber</strong></p>
        <p style="color:#ccc;line-height:1.6">
          Tu solicitud de reembolso ha sido <strong style="color:#43A047">aprobada</strong>.
          El importe de <strong style="color:#C9A84C">${_euro(refundAmount)} €</strong>
          será devuelto a tu método de pago original.
        </p>
        ${adminNotes != null && adminNotes.isNotEmpty ? '''
        <div style="background:#1a1a1a;border-radius:8px;padding:12px;margin:16px 0">
          <p style="color:#aaa;margin:0 0 4px;font-size:12px">NOTA DEL EQUIPO</p>
          <p style="color:#ccc;margin:0">${_esc(adminNotes)}</p>
        </div>
        ''' : ''}
        ${_itemsTableFromMaps(refundItems)}
        ${_creditNote(refundAmount)}
      ''',
    );
    await _sendEmail(
      toEmail: toEmail,
      toName: toName,
      subject: 'Reembolso aprobado — Pedido $orderNumber',
      html: html,
      attachmentRaw: await _pdfAttachmentFromItems(
        orderNumber,
        refundItems,
        refundAmount,
      ),
    );
  }

  /// Email de reembolso rechazado.
  static Future<void> sendRefundRejected({
    required String toEmail,
    required String toName,
    required String orderNumber,
    required List<Map<String, dynamic>> refundItems,
    required double refundAmount,
    String? adminNotes,
  }) async {
    final html = _baseLayout(
      title: 'Solicitud de reembolso rechazada',
      preheader:
          'Tu solicitud de reembolso para $orderNumber no ha sido aprobada',
      body:
          '''
        <h2 style="color:#E53935;margin:0 0 8px">Reembolso rechazado</h2>
        <p style="color:#aaa;margin:0 0 20px">Pedido <strong style="color:#fff">$orderNumber</strong></p>
        <p style="color:#ccc;line-height:1.6">
          Lamentamos informarte de que tu solicitud de reembolso
          no ha podido ser aprobada.
        </p>
        ${adminNotes != null && adminNotes.isNotEmpty ? '''
        <div style="background:#2a1a1a;border-left:3px solid #E53935;border-radius:8px;padding:12px;margin:16px 0">
          <p style="color:#aaa;margin:0 0 4px;font-size:12px">MOTIVO</p>
          <p style="color:#ccc;margin:0">${_esc(adminNotes)}</p>
        </div>
        ''' : ''}
        ${_itemsTableFromMaps(refundItems)}
        <p style="color:#aaa;font-size:13px;margin-top:16px">
          Si tienes alguna duda, puedes contactarnos respondiendo a este email.
        </p>
      ''',
    );
    await _sendEmail(
      toEmail: toEmail,
      toName: toName,
      subject: 'Solicitud de reembolso rechazada — Pedido $orderNumber',
      html: html,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  PLANTILLA HTML BASE
  // ═══════════════════════════════════════════════════════════════

  static String _baseLayout({
    required String title,
    required String preheader,
    required String body,
  }) {
    return '''
<!DOCTYPE html>
<html lang="es">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>$title</title>
<style>
  body{margin:0;padding:0;background:#0D0D0D;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif}
  .wrapper{max-width:600px;margin:0 auto;background:#111;border-radius:12px;overflow:hidden}
  .header{background:linear-gradient(135deg,#1a1a1a 0%,#0d0d0d 100%);padding:32px 24px;text-align:center;border-bottom:1px solid #222}
  .logo{font-size:22px;font-weight:800;color:#C9A84C;letter-spacing:2px}
  .content{padding:32px 24px}
  .footer{padding:20px 24px;text-align:center;border-top:1px solid #222;font-size:11px;color:#666}
</style>
</head>
<body>
<span style="display:none;max-height:0;overflow:hidden">$preheader</span>
<div style="background:#0D0D0D;padding:24px 12px">
<div class="wrapper">
  <div class="header">
    <div class="logo">FASHION STORE</div>
  </div>
  <div class="content">$body</div>
  <div class="footer">
    &copy; ${DateTime.now().year} Fashion Store &mdash; Todos los derechos reservados<br>
    <span style="color:#444">Este email fue generado automáticamente</span>
  </div>
</div>
</div>
</body>
</html>''';
  }

  // ═══════════════════════════════════════════════════════════════
  //  COMPONENTES HTML
  // ═══════════════════════════════════════════════════════════════

  static String _itemsTable(List<OrderItemModel> items) {
    final rows = items
        .map(
          (i) =>
              '''
      <tr>
        <td style="padding:8px 0;border-bottom:1px solid #222">
          <img src="${i.productImage ?? ''}" width="50" height="62"
               style="border-radius:6px;object-fit:cover;vertical-align:middle;background:#1a1a1a" alt="">
        </td>
        <td style="padding:8px 10px;border-bottom:1px solid #222;color:#ddd;font-size:13px">
          ${_esc(i.productName ?? '')}<br>
          <span style="color:#888;font-size:11px">Talla: ${i.size ?? '-'} · x${i.quantity}</span>
        </td>
        <td align="right" style="padding:8px 0;border-bottom:1px solid #222;color:#fff;font-size:13px;font-weight:600;white-space:nowrap">
          ${_euro(i.subtotal)} €
        </td>
      </tr>
    ''',
        )
        .join();

    return '<table width="100%" cellpadding="0" cellspacing="0" style="margin:16px 0">$rows</table>';
  }

  static String _itemsTableFromMaps(List<Map<String, dynamic>> items) {
    final rows = items.map((i) {
      final name = (i['product_name'] as String?) ?? '';
      final image = (i['product_image'] as String?) ?? '';
      final size = i['size'] ?? '-';
      final qty = i['quantity'] ?? 1;
      final subtotal = (i['subtotal'] as num?)?.toDouble() ?? 0;
      return '''
      <tr>
        <td style="padding:8px 0;border-bottom:1px solid #222">
          <img src="$image" width="50" height="62"
               style="border-radius:6px;object-fit:cover;vertical-align:middle;background:#1a1a1a" alt="">
        </td>
        <td style="padding:8px 10px;border-bottom:1px solid #222;color:#ddd;font-size:13px">
          ${_esc(name)}<br>
          <span style="color:#888;font-size:11px">Talla: $size · x$qty</span>
        </td>
        <td align="right" style="padding:8px 0;border-bottom:1px solid #222;color:#fff;font-size:13px;font-weight:600;white-space:nowrap">
          ${_euro(subtotal)} €
        </td>
      </tr>
      ''';
    }).join();

    return '<table width="100%" cellpadding="0" cellspacing="0" style="margin:16px 0">$rows</table>';
  }

  static String _invoiceSummary(
    double subtotal,
    double shipping,
    double discount,
    double total,
  ) {
    return '''
    <table width="100%" style="margin-top:20px;border-top:1px solid #333;padding-top:12px">
      <tr><td style="color:#aaa;padding:4px 0;font-size:13px">Subtotal</td>
          <td align="right" style="color:#ddd;font-size:13px">${_euro(subtotal)} €</td></tr>
      <tr><td style="color:#aaa;padding:4px 0;font-size:13px">Envío</td>
          <td align="right" style="color:#ddd;font-size:13px">${shipping > 0 ? '${_euro(shipping)} €' : 'Gratis'}</td></tr>
      ${discount > 0 ? '<tr><td style="color:#43A047;padding:4px 0;font-size:13px">Descuento</td><td align="right" style="color:#43A047;font-size:13px">-${_euro(discount)} €</td></tr>' : ''}
      <tr><td style="color:#fff;padding:8px 0 0;font-size:16px;font-weight:700;border-top:1px solid #333">TOTAL</td>
          <td align="right" style="color:#C9A84C;padding:8px 0 0;font-size:18px;font-weight:700;border-top:1px solid #333">${_euro(total)} €</td></tr>
    </table>''';
  }

  static String _creditNote(double amount) {
    return '''
    <div style="background:#1a2e1a;border-radius:8px;padding:16px;margin-top:20px;text-align:center">
      <p style="color:#43A047;margin:0 0 4px;font-size:12px;text-transform:uppercase;letter-spacing:1px">Nota de abono</p>
      <p style="color:#fff;margin:0;font-size:24px;font-weight:700">${_euro(amount)} €</p>
    </div>''';
  }

  static String _esc(String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  /// Formatea un valor ya en euros: 44.99 → "44.99"
  /// Los datos de orders/order_items ya están en euros en la BD.
  static String _euro(double amount) => amount.toStringAsFixed(2);

  /// Mapa de estado → datos para el email
  static Map<String, dynamic> _statusEmailData(String status) {
    switch (status) {
      case 'confirmed':
        return {
          'color': '#42A5F5',
          'icon': '&#10003;',
          'title': 'Pedido confirmado',
          'msg':
              'Tu pedido ha sido confirmado y está siendo preparado por nuestro equipo.',
        };
      case 'processing':
        return {
          'color': '#7E57C2',
          'icon': '&#9881;',
          'title': 'Pedido en preparación',
          'msg':
              'Estamos preparando tu pedido con mucho cuidado. Pronto estará listo para enviar.',
        };
      case 'shipped':
        return {
          'color': '#26A69A',
          'icon': '&#128666;',
          'title': '¡Tu pedido está en camino!',
          'msg':
              'Tu pedido ha salido de nuestro almacén y está de camino a tu dirección. Recibirás una notificación cuando se entregue.',
        };
      case 'delivered':
        return {
          'color': '#43A047',
          'icon': '&#10004;',
          'title': 'Pedido entregado',
          'msg':
              '¡Tu pedido ha sido entregado! Esperamos que disfrutes de tus productos. Si tienes algún problema, puedes solicitar una devolución desde la app.',
        };
      default:
        return {
          'color': '#C9A84C',
          'icon': '&#8226;',
          'title': 'Actualización de pedido',
          'msg': 'El estado de tu pedido ha sido actualizado.',
        };
    }
  }

  /// Timeline visual del progreso del pedido
  static String _statusTimeline(String currentStatus) {
    const steps = [
      'pending',
      'confirmed',
      'processing',
      'shipped',
      'delivered',
    ];
    const labels = [
      'Recibido',
      'Confirmado',
      'Preparando',
      'Enviado',
      'Entregado',
    ];
    final currentIdx = steps.indexOf(currentStatus);

    final rows = <String>[];
    for (var i = 0; i < steps.length; i++) {
      final done = i <= currentIdx;
      final isCurrent = i == currentIdx;
      final dotColor = done ? '#C9A84C' : '#333';
      final textColor = isCurrent
          ? '#C9A84C'
          : done
          ? '#ddd'
          : '#555';
      final weight = isCurrent ? '700' : '400';
      final lineColor = (i < currentIdx) ? '#C9A84C' : '#333';

      rows.add('''
        <tr>
          <td width="30" style="text-align:center;vertical-align:top;padding:0">
            <div style="width:14px;height:14px;border-radius:50%;background:$dotColor;margin:3px auto 0;border:2px solid ${done ? '#C9A84C' : '#444'}"></div>
            ${i < steps.length - 1 ? '<div style="width:2px;height:24px;background:$lineColor;margin:0 auto"></div>' : ''}
          </td>
          <td style="padding:2px 0 ${i < steps.length - 1 ? '12px' : '0'} 10px;color:$textColor;font-size:13px;font-weight:$weight">${labels[i]}</td>
        </tr>
      ''');
    }

    return '''
    <div style="background:#1a1a1a;border-radius:10px;padding:16px;margin:20px 0">
      <table cellpadding="0" cellspacing="0">${rows.join()}</table>
    </div>''';
  }

  // ═══════════════════════════════════════════════════════════════
  //  EMAIL DE CAMBIO DE ESTADO DEL PEDIDO
  // ═══════════════════════════════════════════════════════════════

  /// Envía email al cliente cuando el estado del pedido avanza.
  static Future<void> sendOrderStatusUpdate({
    required OrderModel order,
    required String newStatus,
  }) async {
    final orderNum = order.orderNumber ?? '#${order.id.substring(0, 8)}';
    final data = _statusEmailData(newStatus);
    final color = data['color'] as String;
    final title = data['title'] as String;
    final msg = data['msg'] as String;

    final html = _baseLayout(
      title: title,
      preheader: '$title — Pedido $orderNum',
      body:
          '''
        <div style="text-align:center;margin-bottom:20px">
          <div style="display:inline-block;width:56px;height:56px;line-height:56px;font-size:28px;border-radius:50%;background:${color}22;color:$color;text-align:center">${data['icon']}</div>
        </div>
        <h2 style="color:$color;margin:0 0 8px;text-align:center">$title</h2>
        <p style="color:#aaa;margin:0 0 20px;text-align:center">Pedido <strong style="color:#fff">$orderNum</strong></p>
        <p style="color:#ccc;line-height:1.6;text-align:center">$msg</p>
        ${_statusTimeline(newStatus)}
        ${_itemsTable(order.orderItems)}
        ${_invoiceSummary(order.subtotal, order.shippingCost, order.discount, order.total)}
      ''',
    );
    await _sendEmail(
      toEmail: order.customerEmail ?? '',
      toName: order.shippingFullName ?? 'Cliente',
      subject: '$title — Pedido $orderNum',
      html: html,
      attachment: await _pdfAttachment(order, 'factura'),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  EMAIL DE ALERTA STOCK BAJO (AL ADMIN)
  // ═══════════════════════════════════════════════════════════════

  /// Envía UNA alerta al admin cuando un producto tiene stock bajo.
  /// [products] es una lista de mapas con: name, image, stock, sku
  static Future<void> sendLowStockAlert({
    required List<Map<String, dynamic>> products,
  }) async {
    if (products.isEmpty) return;

    final productRows = products.map((p) {
      final name = _esc((p['name'] as String?) ?? '');
      final image = (p['image'] as String?) ?? '';
      final stock = p['stock'] ?? 0;
      final sku = (p['sku'] as String?) ?? '';
      final stockColor = (stock as int) <= 0 ? '#E53935' : '#FFA726';
      return '''
      <tr>
        <td style="padding:10px 0;border-bottom:1px solid #222">
          <img src="$image" width="50" height="62"
               style="border-radius:6px;object-fit:cover;vertical-align:middle;background:#1a1a1a" alt="">
        </td>
        <td style="padding:10px 10px;border-bottom:1px solid #222;color:#ddd;font-size:13px">
          $name<br>
          <span style="color:#666;font-size:11px">SKU: $sku</span>
        </td>
        <td align="right" style="padding:10px 0;border-bottom:1px solid #222;white-space:nowrap">
          <span style="background:${stockColor}22;color:$stockColor;padding:4px 10px;border-radius:12px;font-size:13px;font-weight:700">
            $stock uds
          </span>
        </td>
      </tr>''';
    }).join();

    final html = _baseLayout(
      title: 'Alerta de stock bajo',
      preheader: '${products.length} producto(s) con stock bajo',
      body:
          '''
        <div style="text-align:center;margin-bottom:20px">
          <div style="display:inline-block;width:56px;height:56px;line-height:56px;font-size:28px;border-radius:50%;background:#FFA72622;color:#FFA726;text-align:center">&#9888;</div>
        </div>
        <h2 style="color:#FFA726;margin:0 0 8px;text-align:center">Stock bajo</h2>
        <p style="color:#ccc;line-height:1.6;text-align:center">
          Los siguientes productos tienen un stock inferior a <strong style="color:#fff">5 unidades</strong>.
          Revisa el inventario para evitar quedarte sin existencias.
        </p>
        <table width="100%" cellpadding="0" cellspacing="0" style="margin:20px 0">
          $productRows
        </table>
        <div style="background:#2a1e0a;border-radius:8px;padding:14px;margin-top:16px;text-align:center">
          <p style="color:#FFA726;margin:0;font-size:13px">
            &#128240; ${products.length} producto${products.length > 1 ? 's' : ''} necesita${products.length > 1 ? 'n' : ''} reposición
          </p>
        </div>
      ''',
    );
    await _sendEmail(
      toEmail: _fromEmail, // Al admin
      toName: 'Admin Fashion Store',
      subject: '⚠️ Stock bajo — ${products.length} producto(s)',
      html: html,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  EMAIL WISHLIST — STOCK BAJO
  // ═══════════════════════════════════════════════════════════════

  /// Avisa a un usuario que un producto de su lista de deseos se está agotando.
  static Future<void> sendWishlistLowStock({
    required String toEmail,
    required String toName,
    required String productName,
    required String productImage,
    required int stock,
  }) async {
    final urgencyColor = stock <= 1
        ? '#E53935'
        : stock <= 3
        ? '#FFA726'
        : '#FFD54F';
    final urgencyText = stock <= 1
        ? '¡Solo queda $stock unidad!'
        : '¡Solo quedan $stock unidades!';

    final html = _baseLayout(
      title: '¡Se está agotando!',
      preheader: '$productName tiene pocas unidades — ¡No te lo pierdas!',
      body:
          '''
        <div style="text-align:center;margin-bottom:20px">
          <div style="display:inline-block;width:56px;height:56px;line-height:56px;font-size:28px;border-radius:50%;background:#E5393522;color:#E53935;text-align:center">&#128293;</div>
        </div>
        <h2 style="color:#C9A84C;margin:0 0 6px;text-align:center">¡No te lo pierdas!</h2>
        <p style="color:#aaa;margin:0 0 24px;text-align:center;font-size:14px">
          Un producto de tu lista de deseos se está agotando
        </p>

        <!-- Producto -->
        <div style="background:#1a1a1a;border-radius:12px;padding:16px;margin:0 0 20px;border:1px solid #2a2a2a">
          <table width="100%" cellpadding="0" cellspacing="0"><tr>
            <td width="90" style="vertical-align:top">
              <img src="$productImage" width="80" height="100"
                   style="border-radius:8px;object-fit:cover;background:#222;display:block" alt="">
            </td>
            <td style="vertical-align:top;padding-left:14px">
              <p style="color:#fff;font-size:15px;font-weight:700;margin:0 0 8px">${_esc(productName)}</p>
              <div style="display:inline-block;background:${urgencyColor}22;color:$urgencyColor;padding:4px 12px;border-radius:20px;font-size:13px;font-weight:700">
                $urgencyText
              </div>
              <p style="color:#888;font-size:12px;margin:10px 0 0">En tu lista de deseos &#10084;</p>
            </td>
          </tr></table>
        </div>

        <!-- Barra de urgencia -->
        <div style="background:#1a1a1a;border-radius:8px;padding:14px;text-align:center;margin-bottom:20px">
          <div style="background:#333;border-radius:4px;height:8px;overflow:hidden">
            <div style="background:linear-gradient(90deg,$urgencyColor,#E53935);width:${((5 - stock) / 5 * 100).clamp(20, 100).toInt()}%;height:100%;border-radius:4px"></div>
          </div>
          <p style="color:$urgencyColor;font-size:12px;font-weight:700;margin:8px 0 0">
            &#9888; Stock muy limitado — Puede agotarse pronto
          </p>
        </div>

        <p style="color:#aaa;font-size:13px;text-align:center;margin:0">
          ¡Abre la app y hazte con él antes de que se agote!
        </p>
      ''',
    );
    await _sendEmail(
      toEmail: toEmail,
      toName: toName,
      subject: '🔥 ¡Se agota! $productName tiene pocas unidades',
      html: html,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  EMAIL BROADCAST — CUPÓN PROMOCIONAL
  // ═══════════════════════════════════════════════════════════════

  /// Envía un email promocional de cupón a una lista de destinatarios.
  /// [recipients] = lista de {'email': ..., 'name': ...}
  static Future<int> sendCouponBroadcast({
    required List<Map<String, String>> recipients,
    required String couponCode,
    required String discountDisplay,
    String? minOrder,
    String? expiresAt,
  }) async {
    if (recipients.isEmpty) return 0;

    final expiryHtml = expiresAt != null && expiresAt.isNotEmpty
        ? '<p style="color:#aaa;font-size:12px;margin:12px 0 0">Válido hasta <strong style="color:#ddd">$expiresAt</strong></p>'
        : '<p style="color:#aaa;font-size:12px;margin:12px 0 0">Sin fecha de expiración</p>';

    final minOrderHtml =
        minOrder != null &&
            minOrder.isNotEmpty &&
            minOrder != '0' &&
            minOrder != '0.0'
        ? '<p style="color:#aaa;font-size:12px;margin:4px 0 0">Pedido mínimo: <strong style="color:#ddd">$minOrder€</strong></p>'
        : '';

    final html = _baseLayout(
      title: '¡Cupón exclusivo para ti!',
      preheader:
          'Usa el código $couponCode y obtén $discountDisplay de descuento',
      body:
          '''
        <div style="text-align:center;margin-bottom:20px">
          <div style="display:inline-block;width:56px;height:56px;line-height:56px;font-size:28px;border-radius:50%;background:#AB7BFF22;color:#AB7BFF;text-align:center">&#127873;</div>
        </div>
        <h2 style="color:#C9A84C;margin:0 0 6px;text-align:center">¡Cupón de descuento!</h2>
        <p style="color:#aaa;margin:0 0 28px;text-align:center;font-size:14px">
          Tenemos una oferta especial para ti
        </p>

        <!-- Cupón visual -->
        <div style="background:linear-gradient(135deg,#1a1230 0%,#0d0d0d 100%);border-radius:16px;padding:28px 20px;margin:0 0 24px;border:2px dashed #AB7BFF44;text-align:center;position:relative">
          <p style="color:#AB7BFF;font-size:12px;text-transform:uppercase;letter-spacing:2px;margin:0 0 8px;font-weight:600">Tu código de descuento</p>
          <div style="background:#AB7BFF22;border:2px solid #AB7BFF66;border-radius:10px;padding:14px 24px;display:inline-block;margin:0 0 12px">
            <span style="color:#fff;font-size:24px;font-weight:900;letter-spacing:4px">$couponCode</span>
          </div>
          <div style="margin-top:8px">
            <span style="display:inline-block;background:linear-gradient(135deg,#AB7BFF,#7C3AED);color:#fff;padding:8px 24px;border-radius:20px;font-size:20px;font-weight:900">
              $discountDisplay OFF
            </span>
          </div>
          $minOrderHtml
          $expiryHtml
        </div>

        <p style="color:#ccc;font-size:14px;line-height:1.6;text-align:center;margin:0 0 20px">
          Introduce el código al finalizar tu compra y disfruta del descuento.
          ¡No dejes pasar esta oportunidad!
        </p>

        <div style="background:#1a1a1a;border-radius:8px;padding:14px;text-align:center">
          <p style="color:#888;font-size:12px;margin:0">
            &#128717; Aplícalo en tu próximo pedido desde la app
          </p>
        </div>
      ''',
    );

    int sent = 0;
    for (final r in recipients) {
      try {
        await _sendEmail(
          toEmail: r['email'] ?? '',
          toName: r['name'] ?? 'Cliente',
          subject:
              '🎁 ¡Cupón exclusivo! $discountDisplay de descuento con $couponCode',
          html: html,
        );
        sent++;
      } catch (_) {
        // Continuar con el siguiente
      }
    }
    return sent;
  }

  // ═══════════════════════════════════════════════════════════════
  //  PDF ADJUNTO
  // ═══════════════════════════════════════════════════════════════

  /// Genera el PDF de factura para adjuntar en emails.
  /// Devuelve el mapa compatible con Brevo (`content` en base64, `name`).
  static Future<Map<String, String>?> _pdfAttachment(
    OrderModel order,
    String prefix,
  ) async {
    try {
      final bytes = await InvoicePdfService.generateBytes(order);
      return {
        'content': base64Encode(bytes),
        'name':
            '${prefix}_${order.orderNumber ?? order.id.substring(0, 8)}.pdf',
      };
    } catch (e) {
      log(
        'EmailService: error generando PDF adjunto: $e',
        name: 'EmailService',
      );
      return null;
    }
  }

  /// Genera un PDF simplificado de nota de abono para reembolsos
  /// (cuando no tenemos el OrderModel completo, solo items como Maps).
  static Future<Map<String, String>?> _pdfAttachmentFromItems(
    String orderNumber,
    List<Map<String, dynamic>> refundItems,
    double refundAmount,
  ) async {
    try {
      // Construir un OrderModel minimal para reutilizar InvoicePdfService
      final items = refundItems
          .map(
            (i) => OrderItemModel(
              id: '',
              productName: (i['product_name'] as String?) ?? '',
              productImage: (i['product_image'] as String?) ?? '',
              size: (i['size'] as String?) ?? '-',
              quantity: (i['quantity'] as int?) ?? 1,
              price: ((i['price'] as num?)?.toDouble() ?? 0),
              subtotal: ((i['subtotal'] as num?)?.toDouble() ?? 0),
            ),
          )
          .toList();

      final order = OrderModel(
        id: orderNumber,
        orderNumber: orderNumber,
        status: 'refunded',
        subtotal: refundAmount,
        total: refundAmount,
        orderItems: items,
      );

      final bytes = await InvoicePdfService.generateBytes(order);
      return {'content': base64Encode(bytes), 'name': 'abono_$orderNumber.pdf'};
    } catch (e) {
      log('EmailService: error generando PDF abono: $e', name: 'EmailService');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  ENVIAR EMAIL VÍA BREVO API
  // ═══════════════════════════════════════════════════════════════

  static Future<void> _sendEmail({
    required String toEmail,
    required String toName,
    required String subject,
    required String html,
    Map<String, String>? attachment,
    Map<String, String>? attachmentRaw,
  }) async {
    if (toEmail.isEmpty) {
      log('EmailService: email vacío, se omite envío', name: 'EmailService');
      return;
    }
    try {
      final attach = attachment ?? attachmentRaw;
      final data = <String, dynamic>{
        'sender': {'name': _fromName, 'email': _fromEmail},
        'to': [
          {'email': toEmail, 'name': toName},
        ],
        'subject': subject,
        'htmlContent': html,
      };
      if (attach != null) {
        data['attachment'] = [attach];
      }
      await _dio.post('', data: data);
      log('EmailService: email enviado a $toEmail', name: 'EmailService');
    } catch (e) {
      // No bloquear flujo si falla el email
      log('EmailService error: $e', name: 'EmailService');
    }
  }
}
