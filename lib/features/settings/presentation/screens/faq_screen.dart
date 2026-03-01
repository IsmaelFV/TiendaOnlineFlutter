import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const _faqs = [
    {
      'q': '¿Cuánto tarda el envío?',
      'a':
          'Los envíos estándar tardan entre 3-5 días laborables. Los envíos exprés se entregan en 24-48 horas. El envío es gratuito para pedidos superiores a 50€.',
    },
    {
      'q': '¿Puedo devolver un producto?',
      'a':
          'Sí, aceptamos devoluciones dentro de los 14 días siguientes a la recepción del pedido. El producto debe estar sin usar y con las etiquetas originales.',
    },
    {
      'q': '¿Cómo puedo rastrear mi pedido?',
      'a':
          'Una vez que tu pedido sea enviado, recibirás un email con el número de seguimiento. También puedes consultar el estado en la sección "Mis Pedidos".',
    },
    {
      'q': '¿Qué métodos de pago aceptan?',
      'a':
          'Aceptamos tarjetas de crédito/débito (Visa, Mastercard, American Express), así como pagos a través de Stripe para una transacción segura.',
    },
    {
      'q': '¿Las tallas son estándar?',
      'a':
          'Utilizamos tallas europeas estándar. En cada producto encontrarás una guía de tallas con las medidas exactas para ayudarte a elegir la talla correcta.',
    },
    {
      'q': '¿Tienen productos sostenibles?',
      'a':
          'Sí, contamos con una línea de productos sostenibles fabricados con materiales eco-friendly. Puedes filtrar estos productos con la etiqueta "Eco".',
    },
    {
      'q': '¿Puedo modificar mi pedido?',
      'a':
          'Si tu pedido aún está en estado "Pendiente", puedes cancelarlo y realizar uno nuevo. Una vez confirmado, no es posible modificarlo.',
    },
    {
      'q': '¿Cómo contacto con atención al cliente?',
      'a':
          'Puedes escribirnos a contacto@fashionstore.com o a través de nuestras redes sociales. Respondemos en un plazo máximo de 24 horas.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Preguntas Frecuentes', style: AppTextStyles.h4),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _faqs.length,
        itemBuilder: (context, index) {
          final faq = _faqs[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              iconColor: AppColors.gold500,
              collapsedIconColor: AppColors.textMuted,
              title: Text(
                faq['q']!,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
              ),
              children: [
                Text(
                  faq['a']!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
