import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';

class ReturnsPolicyScreen extends StatelessWidget {
  const ReturnsPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Política de Devoluciones', style: AppTextStyles.h4),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Devoluciones y Cambios', style: AppTextStyles.h3),
            const SizedBox(height: 16),
            _section(
              'Plazo',
              'Dispones de 14 días naturales desde la recepción del pedido para solicitar una devolución.',
            ),
            _section(
              'Condiciones',
              'Los artículos deben estar sin usar, con las etiquetas originales y en su embalaje original. No se aceptan devoluciones de ropa interior o trajes de baño por razones de higiene.',
            ),
            _section(
              'Proceso',
              '1. Accede a "Mis Pedidos" y selecciona el pedido.\n2. Pulsa "Solicitar Devolución" e indica el motivo.\n3. Recibirás un email con la etiqueta de envío.\n4. Deposita el paquete en el punto de recogida indicado.\n5. Una vez verificado el estado del artículo, procederemos al reembolso.',
            ),
            _section(
              'Reembolso',
              'El reembolso se realizará mediante el mismo método de pago utilizado en la compra. El plazo para procesar el reembolso es de 5-10 días laborables desde la recepción del artículo en nuestro almacén.',
            ),
            _section(
              'Cambios de Talla',
              'Si necesitas cambiar la talla, puedes solicitar la devolución y realizar un nuevo pedido con la talla correcta. No ofrecemos cambios directos.',
            ),
            _section(
              'Artículos Defectuosos',
              'Si recibes un artículo defectuoso, contacta con nosotros en un plazo de 48 horas. Gestionaremos el cambio o reembolso sin coste adicional.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.gold500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
