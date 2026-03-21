import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.child,
    this.footer,
    this.showBack = false,
    this.onBack,
    this.useCard = true,
  });

  final Widget child;
  final Widget? footer;
  final bool showBack;
  final VoidCallback? onBack;
  final bool useCard;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final isCompact = width < 420;
    final maxWidth = width > 720 ? 520.0 : width;
    final side = isCompact ? 18.0 : 26.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.appBackgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const _SoftBlobs(),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: side),
                    child: Column(
                      children: [
                        const SizedBox(height: 14),
                        if (showBack)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: onBack,
                              icon: const Icon(Icons.arrow_back_rounded),
                              color: AppColors.ink,
                              tooltip: 'Back',
                            ),
                          )
                        else
                          const SizedBox(height: 48),
                        Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: useCard ? _GlassCard(child: child) : child,
                          ),
                        ),
                        if (footer != null) ...[
                          const SizedBox(height: 14),
                          footer!,
                        ],
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.surface.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.10),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SoftBlobs extends StatelessWidget {
  const _SoftBlobs();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: -120,
            top: 40,
            child: _Blob(color: AppColors.primary.withValues(alpha: 0.12)),
          ),
          Positioned(
            right: -140,
            bottom: 80,
            child: _Blob(color: AppColors.primaryLight.withValues(alpha: 0.14)),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(260),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: const SizedBox(width: 260, height: 260),
      ),
    );
  }
}
