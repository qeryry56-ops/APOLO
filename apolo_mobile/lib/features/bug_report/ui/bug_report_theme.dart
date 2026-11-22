import 'package:flutter/material.dart';

/// Adaptive Dark/Light palette tailored to Apolo.ma (#E31B23 / #FFFFFF)
/// while preserving crisp contrast across both brightness modes.
class BugReportPalette {
  final bool isDark;
  final Color brandRed;
  final Color brandRedPressed;
  final Color onBrandRed;
  final Color surface;
  final Color secondarySurface;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color mutedIcon;
  final Color secondaryActionRed;
  final Color handleColor;
  final Color errorBg;
  final Color errorBorder;
  final Color errorText;

  const BugReportPalette({
    required this.isDark,
    required this.brandRed,
    required this.brandRedPressed,
    required this.onBrandRed,
    required this.surface,
    required this.secondarySurface,
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.mutedIcon,
    required this.secondaryActionRed,
    required this.handleColor,
    required this.errorBg,
    required this.errorBorder,
    required this.errorText,
  });

  factory BugReportPalette.of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    if (isDark) {
      return const BugReportPalette(
        isDark: true,
        brandRed: Color(0xFFE31B23),
        brandRedPressed: Color(0xFFC5141B),
        onBrandRed: Color(0xFFFFFFFF),
        surface: Color(0xFF12161F),
        secondarySurface: Color(0xFF1C2331),
        card: Color(0xFF1E2533),
        border: Color(0xFF2D3748),
        textPrimary: Color(0xFFFFFFFF),
        textSecondary: Color(0xFF94A3B8),
        mutedIcon: Color(0xFF94A3B8),
        secondaryActionRed: Color(0xFFFF5A60),
        handleColor: Color(0xFF475569),
        errorBg: Color(0xFF331419),
        errorBorder: Color(0xFF7F1D1D),
        errorText: Color(0xFFFCA5A5),
      );
    }

    return const BugReportPalette(
      isDark: false,
      brandRed: Color(0xFFE31B23),
      brandRedPressed: Color(0xFFC5141B),
      onBrandRed: Color(0xFFFFFFFF),
      surface: Color(0xFFFFFFFF),
      secondarySurface: Color(0xFFF3F4F6),
      card: Color(0xFFF7F8FA),
      border: Color(0xFFE5E7EB),
      textPrimary: Color(0xFF0A0A0A),
      textSecondary: Color(0xFF525D6F),
      mutedIcon: Color(0xFF6B7280),
      secondaryActionRed: Color(0xFFE31B23),
      handleColor: Color(0xFFD1D5DB),
      errorBg: Color(0xFFFEF2F2),
      errorBorder: Color(0xFFFECACA),
      errorText: Color(0xFFB91C1C),
    );
  }
}
