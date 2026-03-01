import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────
//  FADE-SLIDE STAGGER — Aparición escalonada universal
// ─────────────────────────────────────────────────────────────

/// Widget que envuelve cualquier hijo con animación fade+slide stagger.
/// Uso: FadeSlideItem(index: 0, child: ...)
class FadeSlideItem extends StatelessWidget {
  final int index;
  final Widget child;
  final Animation<double> animation;
  final double slideOffset;

  const FadeSlideItem({
    super.key,
    required this.index,
    required this.child,
    required this.animation,
    this.slideOffset = 30,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, _) => Opacity(
        opacity: animation.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, slideOffset * (1 - animation.value)),
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  STAGGER LIST HELPER — genera Intervals escalonados
// ─────────────────────────────────────────────────────────────

List<Animation<double>> createStaggerAnimations({
  required AnimationController controller,
  required int count,
  double delayPerItem = 0.08,
  double itemDuration = 0.30,
  Curve curve = Curves.easeOutCubic,
}) {
  return List.generate(count, (i) {
    final start = (i * delayPerItem).clamp(0.0, 1.0);
    final end = (start + itemDuration).clamp(0.0, 1.0);
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(start, end, curve: curve),
      ),
    );
  });
}

// ─────────────────────────────────────────────────────────────
//  PULSE GLOW — Animación de pulso para badges/indicadores
// ─────────────────────────────────────────────────────────────

class PulseGlow extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double maxRadius;
  final Duration duration;
  final BorderRadius? borderRadius;

  const PulseGlow({
    super.key,
    required this.child,
    this.glowColor = const Color(0xFFD4AF37),
    this.maxRadius = 8,
    this.duration = const Duration(milliseconds: 1500),
    this.borderRadius,
  });

  @override
  State<PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<PulseGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          shape: widget.borderRadius != null
              ? BoxShape.rectangle
              : BoxShape.circle,
          borderRadius: widget.borderRadius,
          boxShadow: [
            BoxShadow(
              color: widget.glowColor.withValues(alpha: 0.3 * _ctrl.value),
              blurRadius: widget.maxRadius * _ctrl.value,
              spreadRadius: widget.maxRadius * 0.3 * _ctrl.value,
            ),
          ],
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SHIMMER TEXT — Texto con brillo deslizante premium
// ─────────────────────────────────────────────────────────────

class ShimmerText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final Duration duration;

  const ShimmerText({
    super.key,
    required this.text,
    required this.style,
    this.textAlign = TextAlign.center,
    this.duration = const Duration(milliseconds: 2500),
  });

  @override
  State<ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: const [
            AppColors.gold500,
            AppColors.gold300,
            AppColors.gold100,
            AppColors.gold300,
            AppColors.gold500,
          ],
          stops: [
            (_ctrl.value - 0.3).clamp(0.0, 1.0),
            (_ctrl.value - 0.1).clamp(0.0, 1.0),
            _ctrl.value,
            (_ctrl.value + 0.1).clamp(0.0, 1.0),
            (_ctrl.value + 0.3).clamp(0.0, 1.0),
          ],
        ).createShader(bounds),
        child: child,
      ),
      child: Text(
        widget.text,
        style: widget.style.copyWith(color: Colors.white),
        textAlign: widget.textAlign,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  BOUNCING DOT LOADER — Loader premium con 3 dots
// ─────────────────────────────────────────────────────────────

class BouncingDotsLoader extends StatefulWidget {
  final double dotSize;
  final Color color;

  const BouncingDotsLoader({
    super.key,
    this.dotSize = 10,
    this.color = AppColors.accentGold,
  });

  @override
  State<BouncingDotsLoader> createState() => _BouncingDotsLoaderState();
}

class _BouncingDotsLoaderState extends State<BouncingDotsLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final delay = i * 0.2;
          final t = ((_ctrl.value - delay) % 1.0).clamp(0.0, 1.0);
          final bounce = math.sin(t * math.pi);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            child: Transform.translate(
              offset: Offset(0, -8 * bounce),
              child: Opacity(
                opacity: 0.4 + 0.6 * bounce,
                child: Container(
                  width: widget.dotSize,
                  height: widget.dotSize,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.4 * bounce),
                        blurRadius: 6 * bounce,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ANIMATED COUNTER — Número que cuenta hacia arriba/abajo
// ─────────────────────────────────────────────────────────────

class AnimatedCounter extends StatelessWidget {
  final num value;
  final TextStyle style;
  final String Function(num)? formatter;
  final Duration duration;

  const AnimatedCounter({
    super.key,
    required this.value,
    required this.style,
    this.formatter,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<num>(
      tween: Tween(end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, val, _) {
        final display = formatter?.call(val) ?? val.toStringAsFixed(0);
        return Text(display, style: style);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SCALE FADE IN — Aparición con escala y fade
// ─────────────────────────────────────────────────────────────

class ScaleFadeIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double initialScale;

  const ScaleFadeIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
    this.initialScale = 0.8,
  });

  @override
  State<ScaleFadeIn> createState() => _ScaleFadeInState();
}

class _ScaleFadeInState extends State<ScaleFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween(
      begin: widget.initialScale,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.scale(scale: _scale.value, child: child),
      ),
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ANIMATED GRADIENT BORDER — Borde de gradiente animado
// ─────────────────────────────────────────────────────────────

class AnimatedGradientBorder extends StatefulWidget {
  final Widget child;
  final double borderWidth;
  final double borderRadius;
  final Duration duration;

  const AnimatedGradientBorder({
    super.key,
    required this.child,
    this.borderWidth = 2,
    this.borderRadius = 16,
    this.duration = const Duration(milliseconds: 3000),
  });

  @override
  State<AnimatedGradientBorder> createState() => _AnimatedGradientBorderState();
}

class _AnimatedGradientBorderState extends State<AnimatedGradientBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: SweepGradient(
            startAngle: _ctrl.value * 2 * math.pi,
            colors: const [
              AppColors.gold500,
              AppColors.gold300,
              AppColors.accentEmerald,
              AppColors.gold400,
              AppColors.gold500,
            ],
          ),
        ),
        child: Container(
          margin: EdgeInsets.all(widget.borderWidth),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(
              widget.borderRadius - widget.borderWidth,
            ),
          ),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  FLOATING ACTION — Botón/widget que flota con movimiento suave
// ─────────────────────────────────────────────────────────────

class FloatingEffect extends StatefulWidget {
  final Widget child;
  final double amplitude;
  final Duration duration;

  const FloatingEffect({
    super.key,
    required this.child,
    this.amplitude = 6,
    this.duration = const Duration(milliseconds: 2500),
  });

  @override
  State<FloatingEffect> createState() => _FloatingEffectState();
}

class _FloatingEffectState extends State<FloatingEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, -widget.amplitude * math.sin(_ctrl.value * math.pi)),
        child: child,
      ),
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  GOLD ICON — Icono premium con gradiente dorado
// ─────────────────────────────────────────────────────────────

class GoldIcon extends StatelessWidget {
  final IconData icon;
  final double size;

  const GoldIcon({super.key, required this.icon, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.gold300, AppColors.gold500, AppColors.gold600],
      ).createShader(bounds),
      child: Icon(icon, size: size, color: Colors.white),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  EMPTY STATE — Estado vacío premium con animación
// ─────────────────────────────────────────────────────────────

class AnimatedEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onAction;

  const AnimatedEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FloatingEffect(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold500.withValues(alpha: 0.08),
                  border: Border.all(
                    color: AppColors.gold500.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                ),
                child: GoldIcon(icon: icon, size: 44),
              ),
            ),
            const SizedBox(height: 28),
            ScaleFadeIn(
              delay: const Duration(milliseconds: 200),
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            ScaleFadeIn(
              delay: const Duration(milliseconds: 350),
              child: Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (buttonText != null && onAction != null) ...[
              const SizedBox(height: 28),
              ScaleFadeIn(
                delay: const Duration(milliseconds: 500),
                child: ElevatedButton(
                  onPressed: onAction,
                  child: Text(buttonText!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
