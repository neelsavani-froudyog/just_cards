import 'package:flutter/material.dart';

import 'legal_page_scaffold.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalPageScaffold(
      title: 'Privacy Policy',
      subtitle: 'Learn what data we collect and how we use it.',
      icon: Icons.privacy_tip_outlined,
      children: [
        LegalSectionCard(
          title: 'Overview',
          icon: Icons.info_outline_rounded,
          child: Text(
            'This page is a template. Replace the text with your actual privacy policy and compliance details.',
          ),
        ),
        LegalSectionCard(
          title: 'Data We Collect',
          icon: Icons.storage_rounded,
          child: Text(
            'Common examples: name, email, profile details, device info, and usage analytics (if enabled).',
          ),
        ),
        LegalSectionCard(
          title: 'How We Use Data',
          icon: Icons.manage_accounts_outlined,
          child: Text(
            'Common examples: account creation, providing app features, improving reliability, and support requests.',
          ),
        ),
        LegalSectionCard(
          title: 'Sharing & Security',
          icon: Icons.security_rounded,
          child: Text(
            'Explain if you share data with third parties (e.g., analytics, email) and what security practices you follow.',
          ),
        ),
        LegalSectionCard(
          title: 'Your Choices',
          icon: Icons.tune_rounded,
          child: Text(
            'Explain how users can request deletion, export, corrections, or opt out of optional tracking (if applicable).',
          ),
        ),
      ],
    );
  }
}
