import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class NotificationsShimmerView extends StatefulWidget {
  const NotificationsShimmerView({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  State<NotificationsShimmerView> createState() => _NotificationsShimmerViewState();
}

class _NotificationsShimmerViewState extends State<NotificationsShimmerView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      itemCount: widget.itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            final base = AppColors.ink.withValues(alpha: 0.06);
            final hi = AppColors.ink.withValues(alpha: 0.12);
            final color = Color.lerp(base, hi, (0.5 - (t - 0.5).abs()) * 2)!;

            return Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.ink.withValues(alpha: 0.07)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 14,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 72,
                              height: 22,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 12,
                          width: MediaQuery.of(context).size.width * 0.55,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

