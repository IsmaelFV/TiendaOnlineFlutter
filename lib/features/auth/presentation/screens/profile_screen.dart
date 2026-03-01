import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../shared/widgets/loader.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/animated_press.dart';
import '../../../../shared/widgets/animations.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _staggerCtrl;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();
    _anims = createStaggerAnimations(
      controller: _staggerCtrl,
      count: 14,
      delayPerItem: 0.06,
      itemDuration: 0.25,
    );
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GoldIcon(icon: Icons.person_outline, size: 22),
            const SizedBox(width: 8),
            Text('Mi Perfil', style: AppTextStyles.h4),
          ],
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        actions: [
          ScaleFadeIn(
            delay: const Duration(milliseconds: 400),
            child: IconButton(
              icon: const GoldIcon(icon: Icons.settings_outlined, size: 22),
              onPressed: () => context.push('/perfil/seguridad'),
            ),
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Loader(),
        error: (error, _) => AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(currentUserProvider),
        ),
        data: (user) {
          if (user == null) {
            return AnimatedEmptyState(
              icon: Icons.person_outline,
              title: 'Inicia sesi\u00f3n para ver tu perfil',
              subtitle: 'Accede a tus pedidos, favoritos y m\u00e1s',
              buttonText: 'Iniciar Sesi\u00f3n',
              onAction: () => context.push('/login'),
            );
          }
          return _buildProfile(context, ref, user);
        },
      ),
    );
  }

  Widget _buildProfile(BuildContext context, WidgetRef ref, dynamic user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar with animated gradient border
          FadeSlideItem(
            index: 0,
            animation: _anims[0],
            child: AnimatedGradientBorder(
              borderWidth: 3,
              borderRadius: 50,
              child: CircleAvatar(
                radius: 45,
                backgroundColor: AppColors.gold500.withValues(alpha: 0.15),
                child: Text(
                  (user.fullName ?? user.email).substring(0, 1).toUpperCase(),
                  style: AppTextStyles.h2.copyWith(color: AppColors.gold500),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeSlideItem(
            index: 1,
            animation: _anims[1],
            child: ShimmerText(
              text: user.fullName ?? 'Sin nombre',
              style: AppTextStyles.h3,
            ),
          ),
          const SizedBox(height: 4),
          FadeSlideItem(
            index: 2,
            animation: _anims[2],
            child: Text(
              user.email,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
          if (user.isAdmin) ...[
            const SizedBox(height: 8),
            FadeSlideItem(
              index: 3,
              animation: _anims[3],
              child: PulseGlow(
                glowColor: AppColors.gold500,
                maxRadius: 8,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const GoldIcon(icon: Icons.shield_outlined, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'ADMINISTRADOR',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.gold500,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
          _buildMenuSection(context, ref),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider).value ?? false;
    int animIdx = 4;

    return Column(
      children: [
        _buildMenuItem(
          animIndex: animIdx++,
          icon: Icons.shopping_bag_outlined,
          title: 'Mis Pedidos',
          onTap: () => context.push('/perfil/mis-pedidos'),
        ),
        _buildMenuItem(
          animIndex: animIdx++,
          icon: Icons.favorite_outline,
          title: 'Favoritos',
          onTap: () => context.push('/perfil/favoritos'),
        ),
        _buildMenuItem(
          animIndex: animIdx++,
          icon: Icons.lock_outline,
          title: 'Seguridad',
          subtitle: 'Cambiar contrase\u00f1a',
          onTap: () => context.push('/perfil/seguridad'),
        ),
        _buildMenuItem(
          animIndex: animIdx++,
          icon: Icons.help_outline,
          title: 'Preguntas Frecuentes',
          onTap: () => context.push('/faq'),
        ),
        _buildMenuItem(
          animIndex: animIdx++,
          icon: Icons.local_shipping_outlined,
          title: 'Env\u00edos y Entregas',
          onTap: () => context.push('/envios'),
        ),
        _buildMenuItem(
          animIndex: animIdx++,
          icon: Icons.assignment_return_outlined,
          title: 'Devoluciones',
          onTap: () => context.push('/devoluciones'),
        ),
        _buildMenuItem(
          animIndex: animIdx++,
          icon: Icons.info_outline,
          title: 'Sobre Nosotros',
          onTap: () => context.push('/sobre-nosotros'),
        ),
        if (isAdmin) ...[
          const SizedBox(height: 16),
          FadeSlideItem(
            index: animIdx,
            animation: _anims[animIdx.clamp(0, _anims.length - 1)],
            child: AnimatedGradientBorder(
              borderWidth: 1.5,
              borderRadius: 14,
              child: _buildMenuTile(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Panel de Administraci\u00f3n',
                iconColor: AppColors.gold500,
                onTap: () => context.push('/admin'),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        _buildMenuItem(
          animIndex: (animIdx + 1).clamp(0, _anims.length - 1),
          icon: Icons.logout,
          title: 'Cerrar Sesi\u00f3n',
          iconColor: AppColors.error,
          titleColor: AppColors.error,
          onTap: () async {
            HapticFeedback.mediumImpact();
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Cerrar sesi\u00f3n'),
                content: const Text(
                  '\u00bfEst\u00e1s seguro de que quieres cerrar sesi\u00f3n?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text(
                      'Cerrar sesi\u00f3n',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              ref.read(authActionsProvider.notifier).signOut();
            }
          },
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required int animIndex,
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    final idx = animIndex.clamp(0, _anims.length - 1);
    return FadeSlideItem(
      index: animIndex,
      animation: _anims[idx],
      child: AnimatedPress(
        scaleDown: 0.97,
        onPressed: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: _buildMenuTile(
          icon: icon,
          title: title,
          subtitle: subtitle,
          iconColor: iconColor,
          titleColor: titleColor,
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: iconColor != null
            ? Icon(icon, color: iconColor, size: 22)
            : GoldIcon(icon: icon, size: 22),
        title: Text(
          title,
          style: AppTextStyles.body.copyWith(
            color: titleColor ?? AppColors.textPrimary,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              )
            : null,
        trailing: Icon(
          Icons.chevron_right,
          color: AppColors.textMuted.withValues(alpha: 0.5),
          size: 20,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
