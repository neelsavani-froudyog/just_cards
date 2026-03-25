import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  /// Brand / Theme color: #FFA25F
  static const Color seed = Color.fromARGB(255, 55, 55, 55);

  /// Primary brand color (same as seed)
  static const Color primary = seed;

  /// Darker brand shade for gradients/buttons
  static const Color primaryDark = Color.fromARGB(255, 55, 55, 55);

  /// Lighter brand tint for gradients/backgrounds
  static const Color primaryLight = Color(0xFFFFC9A6);

  /// Optional supporting accents (can be tuned later)
  static const Color accentTeal = primary;
  static const Color accentPurple = Color(0xFF7A5CFF);

  // Common neutrals
  // Use this for all primary text/icon color (dark grey theme).
  static const Color darkGrey = seed;
  // Keep the original “ink” used across existing UI styles/components.
  // Default theme typography can still be overridden via `AppTextStyles`.
  static const Color ink = Color(0xFF0B1220);
  static const Color white = Color(0xFFFFFFFF);
  static const Color surface = white;

  // App background (light theme)
  static const List<Color> appBackgroundGradient = <Color>[
    Color(0xFFFFFBF8),
    Color(0xFFFFF1E7),
    Color(0xFFFFE8D9),
  ];

  // Common UI surfaces
  static const Color fieldFill = Color(0xFFF4F7FF);

  // Feedback
  static const Color danger = Color(0xFFB42318);
  static const Color success = Color(0xFF16A34A);

  // Contact action colors (use real app-like colors)
  static const Color contactCall = Color(0xFF2563EB); // blue
  static const Color contactEmail = Color(0xFF94A3B8); // cool gray
  static const Color contactWhatsApp = Color(0xFF22C55E); // WhatsApp green
  static const Color buttonColor = Color(0xFF4ADE80); // WhatsApp green
  static const Color contactShare = Color(0xFF2563EB); // blue

  static const List<Color> splashGradient = <Color>[
    Color(0xFFFFFBF8),
    Color(0xFFFFF1E7),
    Color(0xFFFFE8D9),
  ];

  static const Color cardFill = surface;

  /// Dark grey hub (organization detail, org settings) — layered on brand seed.
  static const Color darkBg = Color(0xFF1A1A1A);
  /// App bar + org header strip
  static const Color darkSoft = Color(0xFF1F1F1F);
  static const Color darkSurface = Color(0xFF242424);
  static const Color darkCard = Color(0xFF2E2E2E);
  static const Color darkBorder = Color(0xFF3F3F3F);
  static const Color darkOnSurface = Color(0xFFF4F4F5);
  static const Color darkOnSurfaceMuted = Color(0xFFA1A1AA);
  /// Tab / link accent on dark backgrounds (readable contrast).
  static const Color darkAccent = Color(0xFF5B9FFF);

  /// Light hub — same feel as **Manage Event** (cool grey page, white chrome).
  static const Color lightHubBg = Color(0xFFF8F9FB);
  static const Color lightHubSurface = Color(0xFFFFFFFF);
  static const Color lightHubInk = Color(0xFF1A1C1E);
  static const Color lightHubMuted = Color(0xFF74777F);
  static const Color lightHubBlue = Color(0xFF007AFF);
  static const Color lightHubHint = Color(0xFFC4C7C5);
  static const Color lightHubBorder = Color(0xFFE3E5E8);
  static const Color lightHubFab = Color(0xFF303030);
  static const Color lightHubAvatarFill = Color(0xFFF0F0F2);
}

