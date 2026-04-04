import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/toast_service.dart';
import '../../core/theme/app_colors.dart';
import 'legal_page_scaffold.dart';

class SupportView extends StatelessWidget {
  const SupportView({super.key});

  static const _supportEmail = 'support@yourcompany.com';
  static const _faqUrl = 'https://example.com/help';

  Future<void> _openEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: <String, String>{
        'subject': 'Just Cards Support',
      },
    );

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ToastService.error('Could not open email app');
    }
  }

  Future<void> _openFaq() async {
    final uri = Uri.parse(_faqUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ToastService.error('Could not open link');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LegalPageScaffold(
      title: 'Support',
      subtitle: 'Get help, report issues, and contact our team.',
      icon: Icons.help_outline_rounded,
      children: [
        LegalSectionCard(
          title: 'Contact Us',
          icon: Icons.support_agent_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email: $_supportEmail'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _ActionChip(
                    label: 'Email Support',
                    icon: Icons.mail_outline_rounded,
                    onTap: _openEmail,
                  ),
                  _ActionChip(
                    label: 'Help Center',
                    icon: Icons.open_in_new_rounded,
                    onTap: _openFaq,
                  ),
                ],
              ),
            ],
          ),
        ),
        const LegalSectionCard(
          title: 'Before You Contact',
          icon: Icons.lightbulb_outline_rounded,
          child: Text(
            'Include what you were trying to do, screenshots (if possible), and the steps to reproduce the issue.',
          ),
        ),
        const LegalSectionCard(
          title: 'Response Time',
          icon: Icons.schedule_rounded,
          child: Text(
            'Typical response time is within 1–2 business days. Update this to match your support policy.',
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: AppColors.primary.withValues(alpha: 0.06),
          border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.ink.withValues(alpha: 0.78)),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.80),
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
