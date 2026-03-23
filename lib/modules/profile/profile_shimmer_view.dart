import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class ProfileHeaderShimmerCard extends StatefulWidget {
  const ProfileHeaderShimmerCard({super.key});

  @override
  State<ProfileHeaderShimmerCard> createState() =>
      _ProfileHeaderShimmerCardState();
}

class _ProfileHeaderShimmerCardState extends State<ProfileHeaderShimmerCard>
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
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.ink.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              _ShimmerBlock(
                width: 76,
                height: 76,
                radius: 38,
                progress: t,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBlock(
                      width: 170,
                      height: 22,
                      radius: 10,
                      progress: t,
                    ),
                    const SizedBox(height: 10),
                    _ShimmerBlock(
                      width: 220,
                      height: 16,
                      radius: 8,
                      progress: t,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
            AppColors.ink.withValues(alpha: 0.06),
            AppColors.ink.withValues(alpha: 0.12),
            AppColors.ink.withValues(alpha: 0.06),
          ],
        ),
      ),
    );
  }
}

