import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';

class ShippingInfoScreen extends StatelessWidget {
  const ShippingInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Envíos', style: AppTextStyles.h4),
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
            Text('Información de Envíos', style: AppTextStyles.h3),
            const SizedBox(height: 16),
            _section(
              'Envío Estándar',
              'Entrega en 3-5 días laborables. Coste: 4.99€ (gratis en pedidos superiores a 50€).',
            ),
            _section(
              'Envío Exprés',
              'Entrega en 24-48 horas. Coste: 9.99€. Disponible para pedidos realizados antes de las 14:00h.',
            ),
            _section(
              'Zonas de Envío',
              'Realizamos envíos a toda España peninsular, Baleares y Canarias. Para Canarias pueden aplicarse costes adicionales de aduanas.',
            ),
            _section(
              'Seguimiento',
              'Una vez que tu pedido sea enviado, recibirás un correo con el número de seguimiento. Podrás consultar el estado en la sección "Mis Pedidos".',
            ),
            _section(
              'Entregas No Realizadas',
              'Si no estás disponible durante la entrega, el transportista intentará un segundo reparto al día siguiente. Tras dos intentos fallidos, el paquete será depositado en un punto de recogida cercano.',
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
            ),
          ),
        ],
      ),
    );
  }
}
