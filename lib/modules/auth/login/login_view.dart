import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/custom_text_field.dart';
import '../auth_shell.dart';
import 'login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 420;

    return AuthShell(
      useCard: false,
      footer: Text(
        'By continuing you agree to our Terms & Privacy Policy.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.ink.withValues(alpha: 0.50),
              fontWeight: FontWeight.w500,
            ),
      ),
      child: _LoginBody(isCompact: isCompact),
    );
  }
}

class _LoginBody extends StatelessWidget {
  const _LoginBody({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<LoginController>();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: EdgeInsets.only(top: isCompact ? 10 : 16),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    const _TopLogo(),
                    SizedBox(height: isCompact ? 22 : 28),
                    _LoginCard(isCompact: isCompact, controller: c),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// (removed unused brand header widget)

class _TopLogo extends StatelessWidget {
  const _TopLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: const Icon(Icons.credit_card_rounded, color: Colors.white, size: 34),
        ),
        const SizedBox(height: 14),
        Text(
          'JustCards',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sign in with email OTP',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.ink.withValues(alpha: 0.62),
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 14),
        const _ScanIllustration(),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({required this.isCompact, required this.controller});

  final bool isCompact;
  final LoginController controller;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.70)),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Enter your email',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.ink,
                    letterSpacing: -0.3,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'We’ll send a one-time code to verify.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.62),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            _EmailField(isCompact: isCompact),
            const SizedBox(height: 10),
            Obx(() {
              final err = controller.errorText.value;
              if (err == null) return const SizedBox.shrink();
              return Text(
                err,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
              );
            }),
            const SizedBox(height: 12),
            _PrimaryButton(label: 'Send OTP', onPressed: controller.sendOtp),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

// (removed illustration widgets to keep design minimal)

class _EmailField extends StatelessWidget {
  const _EmailField({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<LoginController>();

    return CustomTextField(
      controller: c.emailController,
      label: 'Email',
      hint: 'name@company.com',
      inputType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done,
      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.ink, size: 20),
      onSubmitted: (_) => c.sendOtp(),
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: isCompact ? 12 : 14,
      ),
    );
  }
}

class _ScanIllustration extends StatefulWidget {
  const _ScanIllustration();

  @override
  State<_ScanIllustration> createState() => _ScanIllustrationState();
}

class _ScanIllustrationState extends State<_ScanIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
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
        return CustomPaint(
          painter: _ScanIllustrationPainter(t: _controller.value),
          child: const SizedBox(width: 240, height: 120),
        );
      },
    );
  }
}

class _ScanIllustrationPainter extends CustomPainter {
  const _ScanIllustrationPainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final card = RRect.fromRectAndRadius(
      Rect.fromLTWH(18, 16, size.width - 36, size.height - 32),
      const Radius.circular(22),
    );

    final shadow = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawRRect(card.shift(const Offset(0, 10)), shadow);

    final fill = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(card, fill);

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = const LinearGradient(
        colors: [AppColors.accentTeal, AppColors.accentPurple],
      ).createShader(rect);
    canvas.drawRRect(card, border);

    final inner = card.deflate(16).outerRect;
    final avatar = RRect.fromRectAndRadius(
      Rect.fromLTWH(inner.left, inner.top + 6, 38, 38),
      const Radius.circular(14),
    );
    final avatarPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.accentTeal.withValues(alpha: 0.28),
          AppColors.accentPurple.withValues(alpha: 0.22),
        ],
      ).createShader(avatar.outerRect);
    canvas.drawRRect(avatar, avatarPaint);

    final linePaint = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.16)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(inner.left + 52, inner.top + 16), Offset(inner.right - 14, inner.top + 16), linePaint);
    canvas.drawLine(Offset(inner.left + 52, inner.top + 34), Offset(inner.right - 60, inner.top + 34), linePaint..color = AppColors.ink.withValues(alpha: 0.12));

    final scanY = inner.top + 10 + (inner.height - 20) * t;
    final scanRect = Rect.fromLTWH(inner.left, scanY - 2.5, inner.width, 5);
    final glow = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      ..shader = LinearGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0),
          AppColors.primary.withValues(alpha: 0.55),
          AppColors.primaryLight.withValues(alpha: 0),
        ],
      ).createShader(scanRect);
    canvas.drawRect(scanRect, glow);
  }

  @override
  bool shouldRepaint(covariant _ScanIllustrationPainter oldDelegate) => oldDelegate.t != t;
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<LoginController>();
    return Obx(() {
      final busy = c.isSending.value;
      return _GradientButton(
        enabled: !busy,
        onPressed: onPressed,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: busy
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Row(
                  key: const ValueKey('label'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(width: 10),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
        ),
      );
    });
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.enabled,
    required this.onPressed,
    required this.child,
  });

  final bool enabled;
  final Future<void> Function() onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: enabled
                ? const [AppColors.primary, AppColors.primary, AppColors.primary]
                : [
                    AppColors.primary.withValues(alpha: 0.35),
                    AppColors.primary.withValues(alpha: 0.35),
                    AppColors.primary.withValues(alpha: 0.35),
                  ],
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    blurRadius: 26,
                    offset: const Offset(0, 16),
                  ),
                ]
              : const [],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(18),
            child: Center(
              child: DefaultTextStyle(
                style: const TextStyle(color: Colors.white),
                child: IconTheme(
                  data: const IconThemeData(color: Colors.white),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
