import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ManageEventMembersShimmerView extends StatefulWidget {
  const ManageEventMembersShimmerView({super.key});

  @override
  State<ManageEventMembersShimmerView> createState() =>
      _ManageEventMembersShimmerViewState();
}

class _ManageEventMembersShimmerViewState
    extends State<ManageEventMembersShimmerView>
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
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 90),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, __) => _ShimmerMemberCard(progress: t),
        );
      },
    );
  }
}

class _ShimmerMemberCard extends StatelessWidget {
  const _ShimmerMemberCard({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          _ShimmerBlock(
            width: 52,
            height: 52,
            radius: 26,
            progress: progress,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBlock(
                  width: 130,
                  height: 14,
                  radius: 8,
                  progress: progress,
                ),
                const SizedBox(height: 8),
                _ShimmerBlock(
                  width: 180,
                  height: 12,
                  radius: 8,
                  progress: progress,
                ),
                const SizedBox(height: 8),
                _ShimmerBlock(
                  width: 90,
                  height: 12,
                  radius: 8,
                  progress: progress,
                ),
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
            AppColors.ink.withValues(alpha: 0.06),
            AppColors.ink.withValues(alpha: 0.12),
            AppColors.ink.withValues(alpha: 0.06),
          ],
        ),
      ),
    );
  }
}
