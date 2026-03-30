import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class OrganizationContactsShimmerView extends StatefulWidget {
  const OrganizationContactsShimmerView({super.key});

  @override
  State<OrganizationContactsShimmerView> createState() =>
      _OrganizationContactsShimmerViewState();
}

class _OrganizationContactsShimmerViewState
    extends State<OrganizationContactsShimmerView>
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
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, __) => _ShimmerContactCard(progress: t),
        );
      },
    );
  }
}

class _ShimmerContactCard extends StatelessWidget {
  const _ShimmerContactCard({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      decoration: BoxDecoration(
        color: AppColors.lightHubSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightHubBorder.withValues(alpha: 0.9)),
      ),
      child: Row(
        children: [
          _ShimmerBlock(
            width: 44,
            height: 44,
            radius: 22,
            progress: progress,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBlock(
                  width: double.infinity,
                  height: 14,
                  radius: 8,
                  progress: progress,
                ),
                const SizedBox(height: 8),
                _ShimmerBlock(
                  width: double.infinity,
                  height: 12,
                  radius: 8,
                  progress: progress,
                ),
                const SizedBox(height: 8),
                _ShimmerBlock(
                  width: 150,
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
            AppColors.lightHubInk.withValues(alpha: 0.04),
            AppColors.lightHubInk.withValues(alpha: 0.10),
            AppColors.lightHubInk.withValues(alpha: 0.04),
          ],
        ),
      ),
    );
  }
}

