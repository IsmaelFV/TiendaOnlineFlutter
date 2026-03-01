import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';

/// Pantalla estática genérica para FAQ, Envíos, Políticas, etc.
class StaticPageScreen extends StatelessWidget {
  final String title;
  final String type;
  const StaticPageScreen({super.key, required this.title, required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title, style: AppTextStyles.h4),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    switch (type) {
      case 'faq':
        return _buildFaq();
      case 'envios':
        return _buildShipping();
      case 'devoluciones':
        return _buildReturns();
      case 'terminos':
        return _buildTerms();
      case 'privacidad':
        return _buildPrivacy();
      case 'sobre':
        return _buildAbout();
      default:
        return Text('Contenido de $title', style: AppTextStyles.body);
    }
  }

  Widget _buildFaq() {
    final faqs = [
      {
        'q': '¿Cuánto tarda el envío?',
        'a':
            'Los envíos estándar tardan entre 3-5 días laborables. El envío es gratuito para pedidos superiores a 50€.',
      },
      {
        'q': '¿Puedo devolver un producto?',
        'a':
            'Sí, aceptamos devoluciones dentro de los 14 días siguientes a la recepción del pedido.',
      },
      {
        'q': '¿Cómo puedo rastrear mi pedido?',
        'a':
            'Consulta el estado en la sección "Mis Pedidos". Recibirás un email con el tracking al enviar.',
      },
      {
        'q': '¿Qué métodos de pago aceptan?',
        'a':
            'Tarjetas de crédito/débito (Visa, Mastercard) a través de Stripe.',
      },
      {
        'q': '¿Las tallas son estándar?',
        'a': 'Usamos tallas europeas. Cada producto incluye guía de tallas.',
      },
      {
        'q': '¿Tienen productos sostenibles?',
        'a': 'Sí, filtra con la etiqueta "Eco" para encontrarlos.',
      },
      {
        'q': '¿Cómo contacto con atención al cliente?',
        'a': 'Escribe a contacto@fashionstore.com. Respondemos en 24h.',
      },
    ];

    return Column(
      children: faqs
          .map(
            (faq) => Container(
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
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
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
            ),
          )
          .toList(),
    );
  }

  Widget _section(String heading, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.gold500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShipping() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section(
          'Envío Estándar',
          'Entrega en 3-5 días laborables. Coste: 4.99€ (gratis en pedidos superiores a 50€).',
        ),
        _section('Envío Exprés', 'Entrega en 24-48 horas. Coste: 9.99€.'),
        _section(
          'Zonas de Envío',
          'Toda España peninsular, Baleares y Canarias.',
        ),
        _section(
          'Seguimiento',
          'Recibirás un correo con el número de seguimiento.',
        ),
      ],
    );
  }

  Widget _buildReturns() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section('Plazo', '14 días naturales desde la recepción.'),
        _section(
          'Condiciones',
          'Artículos sin usar, con etiquetas originales y embalaje original.',
        ),
        _section(
          'Proceso',
          '1. Accede a "Mis Pedidos"\n2. Selecciona "Solicitar Devolución"\n3. Recibe etiqueta de envío por email\n4. Deposita en punto de recogida\n5. Reembolso en 5-10 días laborables',
        ),
        _section('Reembolso', 'Mediante el mismo método de pago utilizado.'),
      ],
    );
  }

  Widget _buildTerms() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section(
          'Aceptación',
          'Al utilizar Fashion Store, aceptas estos términos y condiciones de uso.',
        ),
        _section(
          'Uso del Servicio',
          'El servicio está destinado a usuarios mayores de 16 años. Los productos están sujetos a disponibilidad.',
        ),
        _section(
          'Precios',
          'Los precios incluyen IVA. Nos reservamos el derecho a modificar los precios sin previo aviso.',
        ),
        _section(
          'Propiedad Intelectual',
          'Todo el contenido (imágenes, textos, logotipos) es propiedad de Fashion Store o sus licenciantes.',
        ),
        _section(
          'Responsabilidad',
          'Fashion Store no se hace responsable de daños indirectos derivados del uso de la plataforma.',
        ),
        _section(
          'Legislación',
          'Estas condiciones se rigen por la legislación española.',
        ),
      ],
    );
  }

  Widget _buildPrivacy() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section('Responsable', 'Fashion Store S.L.'),
        _section(
          'Datos Recogidos',
          'Nombre, email, dirección de envío, historial de pedidos y datos de navegación.',
        ),
        _section(
          'Finalidad',
          'Gestión de pedidos, envío de comunicaciones comerciales (con consentimiento) y mejora del servicio.',
        ),
        _section(
          'Base Legal',
          'Ejecución del contrato de compraventa y consentimiento del usuario.',
        ),
        _section(
          'Derechos',
          'Acceso, rectificación, supresión, portabilidad y oposición. Contacto: privacy@fashionstore.com',
        ),
        _section(
          'Cookies',
          'Utilizamos cookies técnicas y analíticas. Puedes configurar las preferencias en tu navegador.',
        ),
      ],
    );
  }

  Widget _buildAbout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'FASHION\nSTORE',
            textAlign: TextAlign.center,
            style: AppTextStyles.h2.copyWith(
              color: AppColors.gold500,
              letterSpacing: 4,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _section(
          'Nuestra Historia',
          'Fashion Store nació con la misión de democratizar la moda de calidad.',
        ),
        _section(
          'Valores',
          'Sostenibilidad, calidad, comunidad y pasión por la moda.',
        ),
        _section(
          'Contacto',
          'Email: contacto@fashionstore.com\nTeléfono: +34 912 345 678\nMadrid, España',
        ),
      ],
    );
  }
}
