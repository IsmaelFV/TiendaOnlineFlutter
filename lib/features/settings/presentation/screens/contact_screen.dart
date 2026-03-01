import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../shared/widgets/custom_input.dart';
import '../../../../shared/widgets/custom_button.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Contacto', style: AppTextStyles.h4),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _sent ? _buildSuccess() : _buildForm(),
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 60),
        Icon(Icons.check_circle_outline, color: AppColors.success, size: 64),
        const SizedBox(height: 16),
        Text('¡Mensaje enviado!', style: AppTextStyles.h3),
        const SizedBox(height: 8),
        Text(
          'Nos pondremos en contacto contigo\nlo antes posible.',
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => context.go('/'),
          child: const Text('VOLVER AL INICIO'),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Escríbenos', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            'Estamos aquí para ayudarte. Rellena el formulario y responderemos en menos de 24 horas.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Info de contacto
          _contactRow(Icons.email_outlined, 'contacto@fashionstore.com'),
          _contactRow(Icons.phone_outlined, '+34 912 345 678'),
          _contactRow(Icons.schedule, 'Lunes a Viernes: 9:00 - 18:00'),
          const SizedBox(height: 24),

          // Formulario
          CustomInput(
            controller: _nameCtrl,
            label: 'Nombre completo',
            validator: (v) =>
                v == null || v.isEmpty ? 'Tu nombre es requerido' : null,
          ),
          const SizedBox(height: 12),
          CustomInput(
            controller: _emailCtrl,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email requerido';
              if (!v.contains('@')) return 'Email no válido';
              return null;
            },
          ),
          const SizedBox(height: 12),
          CustomInput(
            controller: _messageCtrl,
            label: 'Tu mensaje',
            maxLines: 5,
            validator: (v) =>
                v == null || v.isEmpty ? 'Escribe tu mensaje' : null,
          ),
          const SizedBox(height: 20),
          CustomButton(
            text: 'ENVIAR MENSAJE',
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                setState(() => _sent = true);
              }
            },
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
