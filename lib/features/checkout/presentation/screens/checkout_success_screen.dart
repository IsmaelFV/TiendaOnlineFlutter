import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../shared/widgets/animations.dart';
import '../../../../shared/widgets/custom_button.dart';

class CheckoutSuccessScreen extends StatefulWidget {
  final String? orderId;
  const CheckoutSuccessScreen({super.key, this.orderId});

  @override
  State<CheckoutSuccessScreen> createState() => _CheckoutSuccessScreenState();
}

class _CheckoutSuccessScreenState extends State<CheckoutSuccessScreen>
    with TickerProviderStateMixin {
  late final AnimationController _checkCtrl;
  late final AnimationController _ringsCtrl;
  late final AnimationController _confettiCtrl;
  late final AnimationController _staggerCtrl;
  late final List<Animation<double>> _staggerAnims;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();

    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _ringsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _staggerAnims = createStaggerAnimations(
      controller: _staggerCtrl,
      count: 4,
      delayPerItem: 0.15,
      itemDuration: 0.35,
    );

    // Secuencia: anillos -> check -> confetti -> texto
    _ringsCtrl.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _checkCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        _confettiCtrl.forward();
        HapticFeedback.mediumImpact();
      }
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _staggerCtrl.forward();
    });
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    _ringsCtrl.dispose();
    _confettiCtrl.dispose();
    _staggerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono animado con anillos y confetti
              SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Anillos expansivos
                    AnimatedBuilder(
                      animation: _ringsCtrl,
                      builder: (_, _) => CustomPaint(
                        size: const Size(160, 160),
                        painter: _SuccessRingsPainter(
                          progress: _ringsCtrl.value,
                        ),
                      ),
                    ),
                    // Confetti
                    AnimatedBuilder(
                      animation: _confettiCtrl,
                      builder: (_, _) => CustomPaint(
                        size: const Size(160, 160),
                        painter: _ConfettiPainter(
                          progress: _confettiCtrl.value,
                        ),
                      ),
                    ),
                    // Circulo check
                    AnimatedBuilder(
                      animation: _checkCtrl,
                      builder: (_, _) {
                        final scale = Tween(begin: 0.0, end: 1.0)
                            .chain(CurveTween(curve: Curves.elasticOut))
                            .evaluate(_checkCtrl);
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.gold400,
                                  AppColors.gold500,
                                  AppColors.gold700,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.gold500.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: AnimatedBuilder(
                              animation: _checkCtrl,
                              builder: (_, _) {
                                final checkProgress = Curves.easeOut.transform(
                                  (_checkCtrl.value * 2 - 0.5).clamp(0.0, 1.0),
                                );
                                return CustomPaint(
                                  painter: _CheckPainter(
                                    progress: checkProgress,
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Texto con stagger
              FadeSlideItem(
                index: 0,
                animation: _staggerAnims[0],
                child: ShimmerText(
                  text: 'Pedido Confirmado!',
                  style: AppTextStyles.h2,
                ),
              ),
              const SizedBox(height: 12),
              FadeSlideItem(
                index: 1,
                animation: _staggerAnims[1],
                child: Text(
                  'Tu pedido ha sido recibido y esta siendo procesado.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              FadeSlideItem(
                index: 2,
                animation: _staggerAnims[2],
                child: Text(
                  'Recibiras un email con los detalles de tu compra.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 44),

              // Botones
              FadeSlideItem(
                index: 3,
                animation: _staggerAnims[3],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomButton(
                      text: 'VER MIS PEDIDOS',
                      onPressed: () => context.push('/perfil/mis-pedidos'),
                    ),
                    const SizedBox(height: 12),
                    CustomButton(
                      text: 'SEGUIR COMPRANDO',
                      isOutlined: true,
                      onPressed: () => context.go('/'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Anillos expansivos dorados
class _SuccessRingsPainter extends CustomPainter {
  final double progress;
  _SuccessRingsPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 3; i++) {
      final delay = i * 0.2;
      final t = ((progress - delay) / (1.0 - delay)).clamp(0.0, 1.0);
      final radius = 30.0 + 50.0 * Curves.easeOut.transform(t);
      final opacity = (1.0 - t) * 0.4;
      final paint = Paint()
        ..color = AppColors.gold500.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * (1.0 - t);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SuccessRingsPainter old) =>
      old.progress != progress;
}

// Confetti dorado
class _ConfettiPainter extends CustomPainter {
  final double progress;
  _ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rng = math.Random(42);
    const count = 16;

    for (var i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi + rng.nextDouble() * 0.5;
      final distance = 30.0 + 50.0 * progress * (0.5 + rng.nextDouble() * 0.5);
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final particleSize = 3.0 * (1.0 - progress * 0.5);

      final x = center.dx + math.cos(angle) * distance;
      final y = center.dy + math.sin(angle) * distance - 10 * progress;

      final colors = [
        AppColors.gold400,
        AppColors.gold500,
        AppColors.accentEmerald,
        AppColors.gold300,
      ];

      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: opacity * 0.8)
        ..style = PaintingStyle.fill;

      if (i % 3 == 0) {
        // Estrella
        canvas.drawCircle(Offset(x, y), particleSize, paint);
      } else {
        // Rect
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(x, y),
              width: particleSize * 2,
              height: particleSize,
            ),
            const Radius.circular(1),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}

// Check mark pintado progresivamente
class _CheckPainter extends CustomPainter {
  final double progress;
  _CheckPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Primer trazo (abajo-izquierda a centro)
    final firstEnd = progress.clamp(0.0, 0.5) * 2;
    path.moveTo(cx - 14, cy);
    path.lineTo(cx - 14 + 10 * firstEnd, cy + 10 * firstEnd);

    // Segundo trazo (centro a arriba-derecha)
    if (progress > 0.5) {
      final secondEnd = ((progress - 0.5) * 2).clamp(0.0, 1.0);
      path.lineTo(cx - 4 + 22 * secondEnd, cy + 10 - 22 * secondEnd);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckPainter old) => old.progress != progress;
}
