import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/theme/app_colors.dart';

/// Botón corazón animado estilo Dribbble — explota partículas al activar.
class AnimatedHeartButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onToggle;
  final double size;
  final Color? activeColor;

  const AnimatedHeartButton({
    super.key,
    required this.isFavorite,
    required this.onToggle,
    this.size = 22,
    this.activeColor,
  });

  @override
  State<AnimatedHeartButton> createState() => _AnimatedHeartButtonState();
}

class _AnimatedHeartButtonState extends State<AnimatedHeartButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _particleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>(
      [
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.7), weight: 20),
        TweenSequenceItem(tween: Tween(begin: 0.7, end: 1.3), weight: 40),
        TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 40),
      ],
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _particleAnimation = CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();

    if (!widget.isFavorite) {
      _scaleController.forward(from: 0);
      _particleController.forward(from: 0);
    } else {
      _scaleController.forward(from: 0);
    }

    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? AppColors.error;

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: widget.size + 20,
        height: widget.size + 20,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Partículas
            AnimatedBuilder(
              animation: _particleAnimation,
              builder: (context, _) {
                if (_particleAnimation.value == 0 ||
                    _particleAnimation.value == 1) {
                  return const SizedBox.shrink();
                }
                return CustomPaint(
                  size: Size(widget.size + 20, widget.size + 20),
                  painter: _ParticlePainter(
                    progress: _particleAnimation.value,
                    color: activeColor,
                  ),
                );
              },
            ),
            // Corazón
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) =>
                  Transform.scale(scale: _scaleAnimation.value, child: child),
              child: Icon(
                widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                size: widget.size,
                color: widget.isFavorite ? activeColor : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;

  _ParticlePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..color = color.withValues(alpha: 1.0 - progress);

    const particleCount = 8;
    final radius = 8 + (progress * 14);

    for (int i = 0; i < particleCount; i++) {
      final angle = (i * 2 * math.pi / particleCount) - math.pi / 2;
      final dx = center.dx + radius * math.cos(angle);
      final dy = center.dy + radius * math.sin(angle);
      final particleSize = 2.5 * (1.0 - progress);
      canvas.drawCircle(Offset(dx, dy), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) =>
      old.progress != progress;
}
