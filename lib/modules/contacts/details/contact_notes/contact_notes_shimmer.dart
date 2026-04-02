import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class ContactNotesShimmer extends StatefulWidget {
  const ContactNotesShimmer({super.key});

  @override
  State<ContactNotesShimmer> createState() => _ContactNotesShimmerState();
}

class _ContactNotesShimmerState extends State<ContactNotesShimmer>
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
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          itemCount: 6,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, __) => _ShimmerNoteCard(progress: t),
        );
      },
    );
  }
}

class _ShimmerNoteCard extends StatelessWidget {
  const _ShimmerNoteCard({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.07)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBlock(width: 140, height: 12, radius: 6, progress: progress),
                const SizedBox(height: 10),
                _ShimmerBlock(width: double.infinity, height: 14, radius: 8, progress: progress),
                const SizedBox(height: 8),
                _ShimmerBlock(width: double.infinity, height: 14, radius: 8, progress: progress),
                const SizedBox(height: 8),
                _ShimmerBlock(width: 96, height: 11, radius: 6, progress: progress),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _ShimmerBlock(width: 28, height: 28, radius: 8, progress: progress),
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
