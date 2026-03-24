import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class HomeEventsShimmerView extends StatefulWidget {
  const HomeEventsShimmerView({super.key});

  @override
  State<HomeEventsShimmerView> createState() => _HomeEventsShimmerViewState();
}

class _HomeEventsShimmerViewState extends State<HomeEventsShimmerView>
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
    return SizedBox(
      height: 118,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, __) => _ShimmerEventCard(progress: t),
          );
        },
      ),
    );
  }
}

class _ShimmerEventCard extends StatelessWidget {
  const _ShimmerEventCard({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 192,
      height: 112,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShimmerBlock(width: 130, height: 14, radius: 8, progress: progress),
          const SizedBox(height: 10),
          _ShimmerBlock(width: 110, height: 12, radius: 8, progress: progress),
          const Spacer(),
          _ShimmerBlock(width: 96, height: 14, radius: 8, progress: progress),
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
