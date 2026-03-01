import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Sobre Nosotros', style: AppTextStyles.h4),
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
            Center(
              child: Column(
                children: [
                  Text(
                    'FASHION\nSTORE',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.gold500,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(width: 60, height: 2, color: AppColors.gold500),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Nuestra Historia', style: AppTextStyles.h3),
            const SizedBox(height: 12),
            Text(
              'Fashion Store nació con la misión de democratizar la moda de alta calidad. '
              'Creemos que todo el mundo merece vestir con estilo, sin comprometer la calidad ni el presupuesto.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            Text('Nuestros Valores', style: AppTextStyles.h3),
            const SizedBox(height: 12),
            _valueItem(
              Icons.eco_outlined,
              'Sostenibilidad',
              'Comprometidos con prácticas responsables y materiales eco-friendly.',
            ),
            _valueItem(
              Icons.verified_outlined,
              'Calidad',
              'Seleccionamos cuidadosamente cada prenda para garantizar la mejor calidad.',
            ),
            _valueItem(
              Icons.people_outline,
              'Comunidad',
              'Construimos una comunidad de amantes de la moda con valores compartidos.',
            ),
            _valueItem(
              Icons.favorite_border,
              'Pasión',
              'La moda es nuestra pasión y la compartimos contigo en cada colección.',
            ),
            const SizedBox(height: 24),
            Text('Contacto', style: AppTextStyles.h3),
            const SizedBox(height: 12),
            _contactRow(Icons.email_outlined, 'contacto@fashionstore.com'),
            _contactRow(Icons.phone_outlined, '+34 912 345 678'),
            _contactRow(Icons.location_on_outlined, 'Madrid, España'),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Fashion Store © ${DateTime.now().year}\nTodos los derechos reservados',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _valueItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.gold500.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.gold500, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold500, size: 18),
          const SizedBox(width: 10),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
