import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ManageOrganizationShimmerView extends StatefulWidget {
  const ManageOrganizationShimmerView({super.key});

  @override
  State<ManageOrganizationShimmerView> createState() =>
      _ManageOrganizationShimmerViewState();
}

class _ManageOrganizationShimmerViewState
    extends State<ManageOrganizationShimmerView>
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
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, __) => _ShimmerOrganizationCard(progress: t),
        );
      },
    );
  }
}

class _ShimmerOrganizationCard extends StatelessWidget {
  const _ShimmerOrganizationCard({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          _ShimmerBlock(
            width: 50,
            height: 50,
            radius: 14,
            progress: progress,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBlock(
                  width: 160,
                  height: 16,
                  radius: 8,
                  progress: progress,
                ),
                const SizedBox(height: 8),
                _ShimmerBlock(
                  width: 110,
                  height: 12,
                  radius: 8,
                  progress: progress,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _ShimmerBlock(
            width: 68,
            height: 24,
            radius: 999,
            progress: progress,
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
            AppColors.ink.withValues(alpha: 0.06),
            AppColors.ink.withValues(alpha: 0.12),
            AppColors.ink.withValues(alpha: 0.06),
          ],
        ),
      ),
    );
  }
}

