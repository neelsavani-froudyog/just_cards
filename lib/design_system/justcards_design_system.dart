// ============================================================
//  JustCards — Flutter Design System
//  Generated: April 29, 2026
//  Inspired by LinkedIn design language
// ============================================================
//
//  HOW TO USE
//  ----------
//  1. Import wherever needed:
//       import 'package:just_cards/design_system/justcards_design_system.dart';
//
// ============================================================

import 'package:flutter/material.dart';

// ──────────────────────────────────────────────────────────────────────────────
// 1. COLOR TOKENS
// ──────────────────────────────────────────────────────────────────────────────

class JCColors {
  JCColors._();

  // Brand
  static const Color primary = Color(0xFF0A66C2); // LinkedIn-style blue
  static const Color primaryDark = Color(0xFF095AB0);
  static const Color primaryLight = Color(0xFFE8F1FF);
  static const Color accent = Color(0xFFE86A2F); // icon accent / warm orange

  // Backgrounds
  static const Color bgPage = Color(0xFFF3F6F8); // page / scaffold
  static const Color bgCard = Color(0xFFFFFFFF); // card surface
  static const Color bgInput = Color(0xFFF3F6F8); // unfocused input

  // Text
  static const Color textPrimary = Color(0xFF0F1923);
  static const Color textSecondary = Color(0xFF6B7A99);
  static const Color textTertiary = Color(0xFF8E9BB5);
  static const Color textPlaceholder = Color(0xFFB0BACE);
  static const Color textLink = Color(0xFF0A66C2);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Borders / Dividers
  static const Color border = Color(0xFFE8ECF0);

  // Avatar palette (cycle by initials hash)
  static const List<Color> avatarColors = [
    Color(0xFF0A66C2),
    Color(0xFF7B2FC7),
    Color(0xFF0D8A4E),
    Color(0xFFC47A00),
    Color(0xFFC55A00),
    Color(0xFF0D6C8A),
    Color(0xFFB00020),
  ];

  // Nav
  static const Color navBg = Color(0xFFFFFFFF);
  static const Color navInactive = Color(0xFF8E9BB5);
  static const Color navActive = Color(0xFF0A66C2);

  // FAB
  static const Color fabBg = Color(0xFF0F1923);
}

// ──────────────────────────────────────────────────────────────────────────────
// 2. TYPOGRAPHY TOKENS
// ──────────────────────────────────────────────────────────────────────────────

class JCTypography {
  JCTypography._();

  // Display
  static const TextStyle displayLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: JCColors.textPrimary,
    letterSpacing: -0.5,
  );

  // Headings
  static const TextStyle headingSM = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: JCColors.textPrimary,
  );

  // Labels / UI
  static const TextStyle labelXS = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: JCColors.textTertiary,
    letterSpacing: 0.04,
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// 3. SPACING & SIZING TOKENS
// ──────────────────────────────────────────────────────────────────────────────

class JCSpacing {
  JCSpacing._();

  static const double cardPadV = 14.0;
  static const double cardPadH = 16.0;
}

// ──────────────────────────────────────────────────────────────────────────────
// 4. RADIUS TOKENS
// ──────────────────────────────────────────────────────────────────────────────

class JCRadius {
  JCRadius._();

  static const double lg = 12.0; // cards, list items
}

// ──────────────────────────────────────────────────────────────────────────────
// 5. SHADOW TOKENS
// ──────────────────────────────────────────────────────────────────────────────

class JCShadows {
  JCShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
  ];
}

// ──────────────────────────────────────────────────────────────────────────────
// 6. REUSABLE WIDGET HELPERS (minimal set used by current UI)
// ──────────────────────────────────────────────────────────────────────────────

class JCCard extends StatelessWidget {
  const JCCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = JCRadius.lg,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final inner = Container(
      padding: padding ??
          const EdgeInsets.symmetric(
            vertical: JCSpacing.cardPadV,
            horizontal: JCSpacing.cardPadH,
          ),
      decoration: BoxDecoration(
        color: JCColors.bgCard,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: JCShadows.card,
      ),
      child: child,
    );

    if (onTap == null) return inner;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: inner,
      ),
    );
  }
}

class JCStatCard extends StatelessWidget {
  const JCStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return JCCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: tint),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: JCTypography.labelXS),
              const SizedBox(height: 10),
              Text(value, style: JCTypography.displayLarge),
            ],
          ),
        ],
      ),
    );
  }
}

