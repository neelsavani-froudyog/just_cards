import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import 'splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = theme.colorScheme.onSurface;

    return Scaffold(
      body: AnimatedBuilder(
        animation: controller.animationController,
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: controller.backgroundGradient,
              ),
            ),
            child: Stack(
              children: [
                const _NoiseOverlay(),
                Align(
                  alignment: const Alignment(0, -0.1),
                  child: _CardScanHero(
                    lineT: controller.scanLine.value,
                    glow: controller.glow.value,
                  ),
                ),
                Align(
                  alignment: const Alignment(0, 0.62),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Obx(
                        () => Text(
                          controller.appName.value,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Obx(
                        () => Text(
                          controller.tagline.value,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: fg.withValues(alpha: 0.72),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Text(
                        'v1.0',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: fg.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
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

class _CardScanHero extends StatelessWidget {
  const _CardScanHero({required this.lineT, required this.glow});

  final double lineT;
  final double glow;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _CardScanPainter(lineT: lineT, glow: glow),
        child: const SizedBox(width: 280, height: 220),
      ),
    );
  }
}

class _CardScanPainter extends CustomPainter {
  _CardScanPainter({required this.lineT, required this.glow});

  final double lineT;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(18, 22, size.width - 36, size.height - 44),
      const Radius.circular(22),
    );

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..shader = const LinearGradient(
        colors: [AppColors.accentTeal, AppColors.accentPurple],
      ).createShader(rect);

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.cardFill.withValues(alpha: 0.72);

    final shadowPaint = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawRRect(cardRect.shift(const Offset(0, 8)), shadowPaint);
    canvas.drawRRect(cardRect, fillPaint);
    canvas.drawRRect(cardRect, borderPaint);

    final inner = cardRect.deflate(20);
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppColors.ink.withValues(alpha: 0.12);

    canvas.drawRRect(
      RRect.fromRectAndRadius(inner.outerRect, const Radius.circular(14)),
      linePaint,
    );

    final scanY = inner.top + (inner.height * lineT);
    final scanRect = Rect.fromLTWH(inner.left, scanY - 3, inner.width, 6);

    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 14 * glow)
      ..shader = LinearGradient(
        colors: [
          AppColors.accentTeal.withValues(alpha: 0),
          AppColors.accentTeal.withValues(alpha: 0.55),
          AppColors.accentPurple.withValues(alpha: 0),
        ],
      ).createShader(scanRect);

    canvas.drawRect(scanRect, glowPaint);

    final hardLinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = const LinearGradient(
        colors: [AppColors.accentTeal, AppColors.accentPurple],
      ).createShader(scanRect);
    canvas.drawLine(Offset(inner.left, scanY), Offset(inner.right, scanY), hardLinePaint);

    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.ink.withValues(alpha: 0.14);
    for (int i = 0; i < 5; i++) {
      canvas.drawCircle(Offset(inner.left + 18 + (i * 28), inner.top + 22), 2.2, dotPaint);
    }

    final chipRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(inner.left + 12, inner.bottom - 36, 46, 26),
      const Radius.circular(8),
    );
    final chipPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = AppColors.accentTeal.withValues(alpha: 0.35);
    canvas.drawRRect(chipRect, chipPaint);
  }

  @override
  bool shouldRepaint(covariant _CardScanPainter oldDelegate) =>
      oldDelegate.lineT != lineT || oldDelegate.glow != glow;
}

class _NoiseOverlay extends StatelessWidget {
  const _NoiseOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.045,
        child: CustomPaint(
          painter: _NoisePainter(seed: DateTime.now().millisecondsSinceEpoch),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _NoisePainter extends CustomPainter {
  _NoisePainter({required this.seed});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFFFFFFF);
    final step = 10.0;
    int n = seed;
    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        n = 1664525 * n + 1013904223;
        final v = (n & 0xFF) / 255.0;
        paint.color = const Color(0xFFFFFFFF).withValues(alpha: v * 0.09);
        canvas.drawRect(Rect.fromLTWH(x, y, 1.2, 1.2), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NoisePainter oldDelegate) => false;
}
