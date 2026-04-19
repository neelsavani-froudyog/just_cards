import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/toast_service.dart';
import '../../core/theme/app_colors.dart';
import '../../routes/app_routes.dart';

class LegalMarkdownView extends StatefulWidget {
  const LegalMarkdownView({super.key});

  @override
  State<LegalMarkdownView> createState() => _LegalMarkdownViewState();
}

class _LegalMarkdownViewState extends State<LegalMarkdownView> {
  late final _LegalDocConfig _config;
  late Future<String> _markdownFuture;

  @override
  void initState() {
    super.initState();
    _config = _LegalDocConfig.fromNavigation(
      route: Get.currentRoute,
      args: Get.arguments,
    );
    _markdownFuture = rootBundle.loadString(_config.assetPath);
  }

  Future<void> _openLink(String href) async {
    final uri = Uri.tryParse(href);
    if (uri == null) {
      await ToastService.error('Invalid link');
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      await ToastService.error('Could not open link');
    }
  }

  void _retryLoad() {
    setState(() {
      _markdownFuture = rootBundle.loadString(_config.assetPath);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(_config.title),
        centerTitle: false,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: FutureBuilder<String>(
          future: _markdownFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !(snapshot.hasData && snapshot.data!.trim().isNotEmpty)) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 40,
                        color: AppColors.ink.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Could not load document',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Please try again.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.ink.withValues(alpha: 0.62),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonal(
                        onPressed: _retryLoad,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Markdown(
              data: snapshot.data!,
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
              selectable: true,
              onTapLink: (_, href, __) {
                if (href == null || href.trim().isEmpty) return;
                _openLink(href.trim());
              },
              styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                h1: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
                h2: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
                p: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.ink.withValues(alpha: 0.86),
                  height: 1.45,
                ),
                listBullet: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.ink.withValues(alpha: 0.86),
                ),
                a: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                ),
                blockquoteDecoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                blockquotePadding: const EdgeInsets.all(10),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LegalDocConfig {
  const _LegalDocConfig({
    required this.title,
    required this.assetPath,
  });

  final String title;
  final String assetPath;

  static _LegalDocConfig fromNavigation({
    required String route,
    dynamic args,
  }) {
    final type = (args is Map ? args['type'] : args)?.toString().toLowerCase().trim();
    if (type == 'support') return _support;
    if (type == 'privacy') return _privacy;
    if (type == 'terms') return _terms;
    if (type == 'about') return _about;

    if (route == Routes.support) return _support;
    if (route == Routes.privacyPolicy) return _privacy;
    if (route == Routes.aboutUs) return _about;
    return _terms;
  }

  static const _LegalDocConfig _support = _LegalDocConfig(
    title: 'Support',
    assetPath: 'assets/markdown_data/support_justscans.md',
  );

  static const _LegalDocConfig _terms = _LegalDocConfig(
    title: 'Terms of Service',
    assetPath: 'assets/markdown_data/terms_of_service_justscans.md',
  );

  static const _LegalDocConfig _privacy = _LegalDocConfig(
    title: 'Privacy Policy',
    assetPath: 'assets/markdown_data/privacy_policy_justscans.md',
  );

  static const _LegalDocConfig _about = _LegalDocConfig(
    title: 'About Us',
    assetPath: 'assets/markdown_data/about_us_justscans.md',
  );
}
