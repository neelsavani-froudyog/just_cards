import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Shown while `GET` / contact detail is loading — mirrors header, actions, tabs, and detail rows.
class ContactDetailsShimmer extends StatefulWidget {
  const ContactDetailsShimmer({super.key});

  @override
  State<ContactDetailsShimmer> createState() => _ContactDetailsShimmerState();
}

class _ContactDetailsShimmerState extends State<ContactDetailsShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Column(
          children: [
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
              child: Column(
                children: [
                  _ShimmerBlock(width: 62, height: 62, radius: 31, progress: t),
                  const SizedBox(height: 10),
                  _ShimmerBlock(width: 200, height: 22, radius: 8, progress: t),
                  const SizedBox(height: 8),
                  _ShimmerBlock(width: 160, height: 14, radius: 6, progress: t),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      4,
                      (_) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            children: [
                              _ShimmerBlock(width: 44, height: 44, radius: 22, progress: t),
                              const SizedBox(height: 6),
                              _ShimmerBlock(width: 48, height: 12, radius: 6, progress: t),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _ShimmerBlock(width: double.infinity, height: 42, radius: 14, progress: t)),
                      const SizedBox(width: 10),
                      Expanded(child: _ShimmerBlock(width: double.infinity, height: 42, radius: 14, progress: t)),
                      const SizedBox(width: 10),
                      Expanded(child: _ShimmerBlock(width: double.infinity, height: 42, radius: 14, progress: t)),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                itemCount: 6,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, __) => _ShimmerDetailRow(progress: t),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ShimmerDetailRow extends StatelessWidget {
  const _ShimmerDetailRow({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          _ShimmerBlock(width: 40, height: 40, radius: 20, progress: progress),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBlock(width: 88, height: 11, radius: 6, progress: progress),
                const SizedBox(height: 8),
                _ShimmerBlock(width: double.infinity, height: 14, radius: 8, progress: progress),
                const SizedBox(height: 6),
                _ShimmerBlock(width: 180, height: 14, radius: 8, progress: progress),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerBlock extends StatelessWidget {
  const _ShimmerBlock({
    required this.width,
    required this.height,
    required this.radius,
    required this.progress,
  });

  final double width;
  final double height;
  final double radius;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final begin = -1.2 + (progress * 2.4);
    final end = begin + 1.0;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(begin, -0.3),
          end: Alignment(end, 0.3),
          colors: [
            AppColors.ink.withValues(alpha: 0.04),
            AppColors.ink.withValues(alpha: 0.10),
            AppColors.ink.withValues(alpha: 0.04),
          ],
        ),
      ),
    );
  }
}
