import 'dart:typed_data';
import 'package:flutter/material.dart'
    show
        BuildContext,
        ScaffoldMessenger,
        SnackBar,
        Text,
        RoundedRectangleBorder,
        BorderRadius,
        SnackBarBehavior,
        Color;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:dio/dio.dart';

import '../../features/orders/data/models/order_model.dart';

/// Servicio para generar facturas PDF con el diseño de la app
class InvoicePdfService {
  InvoicePdfService._();

  // ─── Colores del tema ───
  static final _gold = PdfColor.fromInt(0xFFD4AF37);
  static final _dark = PdfColor.fromInt(0xFF0A0A0A);
  static final _darkSurface = PdfColor.fromInt(0xFF171717);
  static const _white = PdfColors.white;
  static const _grayMid = PdfColors.grey600;

  /// Formatea un valor ya en euros: 44.99 → "44.99"
  /// Los datos de orders/order_items ya están en euros en la BD.
  static String _euro(double amount) => amount.toStringAsFixed(2);

  /// Genera los bytes del PDF de factura para un pedido.
  /// Se usa también desde EmailService para adjuntar en emails.
  static Future<Uint8List> generateBytes(OrderModel order) async {
    final pdf = await _buildDocument(order);
    return Uint8List.fromList(await pdf.save());
  }

  /// Genera y abre la vista previa para compartir/descargar el PDF
  static Future<void> generateAndShare(
    BuildContext context,
    OrderModel order,
  ) async {
    try {
      final bytes = await generateBytes(order);

      await Printing.sharePdf(
        bytes: Uint8List.fromList(bytes),
        filename:
            'factura_${order.orderNumber ?? order.id.substring(0, 8)}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  CONSTRUIR PDF
  // ═══════════════════════════════════════════════════════════

  static Future<pw.Document> _buildDocument(OrderModel order) async {
    // Cargar fuente Roboto (soporta €, ñ y todos los glifos necesarios)
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final pdf = pw.Document(
      title: 'Factura ${order.orderNumber ?? ''}',
      author: 'Fashion Store',
      theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
    );

    // Descargar imágenes de productos (en paralelo)
    final imageMap = <String, Uint8List>{};
    final futures = <Future>[];
    for (final item in order.orderItems) {
      final url = item.productImage;
      if (url != null && url.isNotEmpty && !imageMap.containsKey(url)) {
        futures.add(
          _downloadImage(url).then((bytes) {
            if (bytes != null) imageMap[url] = bytes;
          }),
        );
      }
    }
    await Future.wait(futures);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          _header(order),
          pw.SizedBox(height: 24),
          _orderInfo(order),
          pw.SizedBox(height: 20),
          _itemsTable(order, imageMap),
          pw.SizedBox(height: 16),
          _totals(order),
          pw.SizedBox(height: 24),
          if (order.shippingFullName != null) _shippingAddress(order),
          pw.SizedBox(height: 32),
          _footer(),
        ],
      ),
    );

    return pdf;
  }

  // ─── HEADER ───
  static pw.Widget _header(OrderModel order) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: pw.BoxDecoration(
        color: _dark,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'FASHION STORE',
                style: pw.TextStyle(
                  color: _gold,
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Factura de compra',
                style: pw.TextStyle(color: PdfColors.grey400, fontSize: 11),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _gold, width: 1),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(
              _statusLabel(order.status),
              style: pw.TextStyle(
                color: _gold,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── INFO PEDIDO ───
  static pw.Widget _orderInfo(OrderModel order) {
    final createdAt = order.createdAt != null
        ? DateTime.tryParse(order.createdAt!)
        : null;
    final dateStr = createdAt != null
        ? '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}'
        : '-';

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _infoRow(
                'N.º Pedido',
                order.orderNumber ?? '#${order.id.substring(0, 8)}',
              ),
              pw.SizedBox(height: 4),
              _infoRow('Fecha', dateStr),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _infoRow('Método de pago', order.paymentMethod ?? 'Tarjeta'),
              pw.SizedBox(height: 4),
              _infoRow('Estado pago', order.paymentStatus ?? 'Completado'),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text('$label: ', style: pw.TextStyle(color: _grayMid, fontSize: 9)),
        pw.Text(
          value,
          style: pw.TextStyle(
            color: _dark,
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ─── TABLA DE PRODUCTOS ───
  static pw.Widget _itemsTable(
    OrderModel order,
    Map<String, Uint8List> imageMap,
  ) {
    return pw.Table(
      border: null,
      columnWidths: {
        0: const pw.FixedColumnWidth(50), // imagen
        1: const pw.FlexColumnWidth(3), // nombre
        2: const pw.FlexColumnWidth(1), // talla
        3: const pw.FlexColumnWidth(0.7), // cant
        4: const pw.FlexColumnWidth(1.2), // precio
        5: const pw.FlexColumnWidth(1.2), // subtotal
      },
      children: [
        // Cabecera
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: _darkSurface,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          children: [
            _headerCell(''),
            _headerCell('Producto'),
            _headerCell('Talla'),
            _headerCell('Cant.'),
            _headerCell('Precio'),
            _headerCell('Subtotal'),
          ],
        ),
        // Filas
        ...order.orderItems.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final isEven = idx % 2 == 0;
          final bgColor = isEven ? _white : PdfColors.grey50;
          final imageBytes = item.productImage != null
              ? imageMap[item.productImage]
              : null;

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bgColor),
            children: [
              // Imagen
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: imageBytes != null
                    ? pw.ClipRRect(
                        horizontalRadius: 4,
                        verticalRadius: 4,
                        child: pw.Image(
                          pw.MemoryImage(imageBytes),
                          width: 40,
                          height: 50,
                          fit: pw.BoxFit.cover,
                        ),
                      )
                    : pw.Container(
                        width: 40,
                        height: 50,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey200,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                      ),
              ),
              // Nombre
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 8,
                ),
                child: pw.Text(
                  item.productName ?? 'Producto',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                  ),
                ),
              ),
              // Talla
              _bodyCell(item.size ?? '-'),
              // Cantidad
              _bodyCell('${item.quantity}'),
              // Precio unitario
              _bodyCell('${_euro(item.price)} €'),
              // Subtotal
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 8,
                ),
                child: pw.Text(
                  '${_euro(item.subtotal)} €',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _dark,
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _headerCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: _gold,
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static pw.Widget _bodyCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
      ),
    );
  }

  // ─── TOTALES ───
  static pw.Widget _totals(OrderModel order) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 220,
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey50,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        ),
        child: pw.Column(
          children: [
            _totalRow('Subtotal', '${_euro(order.subtotal)} €'),
            pw.SizedBox(height: 4),
            _totalRow(
              'Envío',
              order.shippingCost > 0
                  ? '${_euro(order.shippingCost)} €'
                  : 'Gratis',
            ),
            if (order.discount > 0) ...[
              pw.SizedBox(height: 4),
              _totalRow(
                'Descuento',
                '-${_euro(order.discount)} €',
                valueColor: PdfColor.fromInt(0xFF22C55E),
              ),
            ],
            pw.Divider(color: _gold, thickness: 1),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TOTAL',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: _dark,
                  ),
                ),
                pw.Text(
                  '${_euro(order.total)} €',
                  style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                    color: _gold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _totalRow(
    String label,
    String value, {
    PdfColor? valueColor,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: valueColor ?? _dark,
          ),
        ),
      ],
    );
  }

  // ─── DIRECCIÓN DE ENVÍO ───
  static pw.Widget _shippingAddress(OrderModel order) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DIRECCIÓN DE ENVÍO',
            style: pw.TextStyle(
              color: _gold,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 8),
          if (order.shippingFullName != null)
            pw.Text(
              order.shippingFullName!,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: _dark,
              ),
            ),
          if (order.shippingAddressLine1 != null)
            pw.Text(
              order.shippingAddressLine1!,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          if (order.shippingCity != null || order.shippingPostalCode != null)
            pw.Text(
              '${order.shippingPostalCode ?? ''} ${order.shippingCity ?? ''}, ${order.shippingState ?? ''}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          if (order.shippingPhone != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Tel: ${order.shippingPhone}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
            ),
          ],
        ],
      ),
    );
  }

  // ─── FOOTER ───
  static pw.Widget _footer() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'FASHION STORE',
            style: pw.TextStyle(
              color: _gold,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Gracias por tu compra',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Este documento sirve como comprobante de tu pedido.',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey400),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  UTILIDADES
  // ═══════════════════════════════════════════════════════════

  static String _statusLabel(String status) {
    const labels = {
      'pending': 'PENDIENTE',
      'confirmed': 'CONFIRMADO',
      'processing': 'PROCESANDO',
      'shipped': 'ENVIADO',
      'delivered': 'ENTREGADO',
      'cancelled': 'CANCELADO',
      'refunded': 'REEMBOLSADO',
      'return_requested': 'DEVOLUCIÓN',
    };
    return labels[status] ?? status.toUpperCase();
  }

  static Future<Uint8List?> _downloadImage(String url) async {
    try {
      final response = await Dio().get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      final data = response.data;
      if (response.statusCode == 200 && data != null && data.isNotEmpty) {
        return Uint8List.fromList(data);
      }
    } catch (_) {}
    return null;
  }
}
