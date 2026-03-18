import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  /// Brand / Theme color: #FFA25F
  static const Color seed = Color(0xFFFFA25F);

  /// Primary brand color (same as seed)
  static const Color primary = seed;

  /// Darker brand shade for gradients/buttons
  static const Color primaryDark = Color(0xFFF07A2A);

  /// Lighter brand tint for gradients/backgrounds
  static const Color primaryLight = Color(0xFFFFC9A6);

  /// Optional supporting accents (can be tuned later)
  static const Color accentTeal = primary;
  static const Color accentPurple = Color(0xFF7A5CFF);

  // Neutrals
  static const Color ink = Color(0xFF0B1220);
  static const Color surface = Color(0xFFFFFFFF);

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

  // Contact action colors (use real app-like colors)
  static const Color contactCall = Color(0xFF2563EB); // blue
  static const Color contactEmail = Color(0xFF94A3B8); // cool gray
  static const Color contactWhatsApp = Color(0xFF22C55E); // WhatsApp green
  static const Color contactShare = Color(0xFF2563EB); // blue

  static const List<Color> splashGradient = <Color>[
    Color(0xFFFFFBF8),
    Color(0xFFFFF1E7),
    Color(0xFFFFE8D9),
  ];

  static const Color cardFill = surface;
}

