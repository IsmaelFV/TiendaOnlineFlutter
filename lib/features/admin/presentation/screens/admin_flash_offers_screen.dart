import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../shared/widgets/animations.dart';
import '../../../settings/presentation/providers/flash_offers_provider.dart';

class AdminFlashOffersScreen extends ConsumerStatefulWidget {
  const AdminFlashOffersScreen({super.key});

  @override
  ConsumerState<AdminFlashOffersScreen> createState() =>
      _AdminFlashOffersScreenState();
}

class _AdminFlashOffersScreenState extends ConsumerState<AdminFlashOffersScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final List<Animation<double>> _anims;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _anims = createStaggerAnimations(
      controller: _entryCtrl,
      count: 6,
      delayPerItem: 0.08,
      itemDuration: 0.3,
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleFlashOffers(bool enabled) async {
    if (_toggling) return;
    setState(() => _toggling = true);
    HapticFeedback.mediumImpact();
    await Supabase.instance.client.from('site_settings').upsert({
      'key': 'flash_offers_enabled',
      'value': enabled.toString(),
    }, onConflict: 'key');
    ref.invalidate(flashOffersEnabledProvider);
    if (mounted) setState(() => _toggling = false);
  }

  @override
  Widget build(BuildContext context) {
    final flashAsync = ref.watch(flashOffersEnabledProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ═══ APP BAR ═══
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.surface,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.06),
                  ),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(
                left: 56,
                bottom: 16,
                right: 56,
              ),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.gold500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.flash_on_rounded,
                      size: 14,
                      color: AppColors.gold500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ofertas Flash',
                    style: AppTextStyles.h4.copyWith(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          // ═══ BODY ═══
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Hero toggle card ──
                FadeSlideItem(
                  index: 0,
                  animation: _anims[0],
                  child: flashAsync.when(
                    loading: () => Container(
                      height: 260,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: BouncingDotsLoader(color: AppColors.gold500),
                      ),
                    ),
                    error: (e, _) => Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          'Error: $e',
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ),
                    data: (enabled) => _buildHeroCard(enabled),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Info cards row ──
                FadeSlideItem(
                  index: 1,
                  animation: _anims[1],
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          Icons.bolt_rounded,
                          'Tiempo real',
                          'Sincronización vía Supabase Realtime',
                          AppColors.info,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildInfoCard(
                          Icons.people_alt_rounded,
                          'Global',
                          'Afecta a todos los usuarios activos',
                          AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                FadeSlideItem(
                  index: 2,
                  animation: _anims[2],
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          Icons.visibility_rounded,
                          'Visibilidad',
                          'Sección home de la app móvil',
                          AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildInfoCard(
                          Icons.speed_rounded,
                          'Instantáneo',
                          'Los cambios son inmediatos',
                          AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── How it works section ──
                FadeSlideItem(
                  index: 3,
                  animation: _anims[3],
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.04),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.gold500.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.info_outline_rounded,
                                color: AppColors.gold500,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Cómo funciona',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildStep(1, 'Activas el switch de ofertas flash'),
                        _buildStep(2, 'Se actualiza en site_settings'),
                        _buildStep(3, 'Supabase Realtime lo detecta'),
                        _buildStep(4, 'Todos los usuarios ven las ofertas'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Hero Card ───
  Widget _buildHeroCard(bool enabled) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (enabled ? AppColors.gold500 : AppColors.border).withValues(
            alpha: enabled ? 0.3 : 0.04,
          ),
        ),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.gold500.withValues(alpha: 0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // Animated flash icon
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, child) => Transform.scale(
              scale: enabled ? _pulseAnim.value : 0.85,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (enabled ? AppColors.gold500 : AppColors.textMuted)
                      .withValues(alpha: 0.1),
                  boxShadow: enabled
                      ? [
                          BoxShadow(
                            color: AppColors.gold500.withValues(
                              alpha: 0.15 * _pulseAnim.value,
                            ),
                            blurRadius: 25,
                            spreadRadius: 5,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  enabled ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  color: enabled ? AppColors.gold500 : AppColors.textMuted,
                  size: 36,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Status text
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              enabled ? 'ACTIVADAS' : 'DESACTIVADAS',
              key: ValueKey(enabled),
              style: TextStyle(
                color: enabled ? AppColors.gold500 : AppColors.textMuted,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            enabled
                ? 'Los usuarios ven las ofertas flash'
                : 'Las ofertas flash están ocultas',
            style: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),

          // Toggle button
          GestureDetector(
            onTap: _toggling ? null : () => _toggleFlashOffers(!enabled),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: enabled
                    ? null
                    : const LinearGradient(
                        colors: [AppColors.gold500, Color(0xFFE8C547)],
                      ),
                color: enabled ? AppColors.error.withValues(alpha: 0.12) : null,
                borderRadius: BorderRadius.circular(14),
                border: enabled
                    ? Border.all(color: AppColors.error.withValues(alpha: 0.2))
                    : null,
              ),
              child: Center(
                child: _toggling
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: enabled ? AppColors.error : Colors.black,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            enabled
                                ? Icons.power_settings_new_rounded
                                : Icons.flash_on_rounded,
                            color: enabled ? AppColors.error : Colors.black,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            enabled
                                ? 'Desactivar ofertas'
                                : 'Activar ofertas flash',
                            style: TextStyle(
                              color: enabled ? AppColors.error : Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Info Card ───
  Widget _buildInfoCard(IconData icon, String title, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            sub,
            style: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.6),
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step ───
  Widget _buildStep(int num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold500.withValues(alpha: 0.1),
            ),
            child: Center(
              child: Text(
                '$num',
                style: const TextStyle(
                  color: AppColors.gold500,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
