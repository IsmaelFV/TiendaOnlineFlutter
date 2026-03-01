import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';

/// Loader premium con anillos pulsantes dorados
class Loader extends StatefulWidget {
  final double size;
  final Color? color;
  const Loader({super.key, this.size = 44, this.color});

  @override
  State<Loader> createState() => _LoaderState();
}

class _LoaderState extends State<Loader> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.accentGold;
    return Center(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, _) => CustomPaint(
            painter: _RingsPainter(progress: _ctrl.value, color: color),
          ),
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingsPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // 3 anillos concéntricos con diferentes fases
    for (var i = 0; i < 3; i++) {
      final phase = (progress + i * 0.33) % 1.0;
      final radius = maxRadius * (0.3 + 0.7 * phase);
      final opacity = (1.0 - phase).clamp(0.0, 1.0) * 0.6;
      final strokeWidth = 2.5 * (1.0 - phase * 0.5);

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, radius, paint);
    }

    // Punto central que pulsa
    final pulseSize = 3.0 + 2.0 * math.sin(progress * math.pi * 2);
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, pulseSize, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) => old.progress != progress;
}

/// Loader a pantalla completa con fondo oscuro
class FullScreenLoader extends StatelessWidget {
  const FullScreenLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Loader(),
    );
  }
}
