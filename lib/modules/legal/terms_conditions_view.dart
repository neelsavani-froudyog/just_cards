import 'package:flutter/material.dart';

import 'legal_page_scaffold.dart';

class TermsConditionsView extends StatelessWidget {
  const TermsConditionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalPageScaffold(
      title: 'Terms of Service',
      subtitle: 'Rules for using the app and your responsibilities.',
      icon: Icons.policy_outlined,
      children: [
        LegalSectionCard(
          title: 'Acceptance of Terms',
          icon: Icons.verified_user_outlined,
          child: Text(
            'By using this app, you agree to these Terms of Service. Replace this text with your legal copy.',
          ),
        ),
        LegalSectionCard(
          title: 'Accounts',
          icon: Icons.person_outline_rounded,
          child: Text(
            'Users are responsible for maintaining the confidentiality of their account and activity under the account.',
          ),
        ),
        LegalSectionCard(
          title: 'Content & Usage',
          icon: Icons.article_outlined,
          child: Text(
            'Describe allowed and prohibited usage, and any rules related to cards, contacts, organizations, and events.',
          ),
        ),
        LegalSectionCard(
          title: 'Termination',
          icon: Icons.block_outlined,
          child: Text(
            'Explain when accounts may be suspended/terminated and how users can delete their account.',
          ),
        ),
        LegalSectionCard(
          title: 'Contact',
          icon: Icons.support_agent_rounded,
          child: Text(
            'Add your support email or help channel so users can reach you with questions about these terms.',
          ),
        ),
      ],
    );
  }
}
