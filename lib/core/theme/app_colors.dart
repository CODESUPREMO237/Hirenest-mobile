// ============================================================================
// app_colors.dart
// lib/core/theme/app_colors.dart
// ============================================================================

import 'package:flutter/material.dart';

class AppColors {
  // ── Primary (Royal Blue) ────────────────────────────────────────────────
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF3B82F6);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // ── Secondary (Emerald Green) ───────────────────────────────────────────
  static const Color secondary = Color(0xFF059669);
  static const Color secondaryDark = Color(0xFF10B981);
  static const Color onSecondary = Color(0xFFFFFFFF);

  // ── Accent (Violet) ─────────────────────────────────────────────────────
  static const Color accent = Color(0xFF7C3AED);
  static const Color accentDark = Color(0xFF8B5CF6);
  static const Color onAccent = Color(0xFFFFFFFF);

  // ── Status Colors ───────────────────────────────────────────────────────
  static const Color success = Color(0xFF059669);
  static const Color successDark = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFFFBBF24);
  static const Color error = Color(0xFFDC2626);
  static const Color errorDark = Color(0xFFEF4444);
  static const Color info = Color(0xFF2563EB);
  static const Color infoDark = Color(0xFF3B82F6);

  // ── Background & Surface (Light Mode) ───────────────────────────────────
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF1F5F9);
  static const Color borderLight = Color(0xFFE2E8F0);

  // ── Background & Surface (Dark Mode) ────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceVariantDark = Color(0xFF334155);
  static const Color borderDark = Color(0xFF334155);

  // ── Text Colors (Light Mode) ────────────────────────────────────────────
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF334155);
  static const Color textMutedLight = Color(0xFF94A3B8);

  // ── Text Colors (Dark Mode) ─────────────────────────────────────────────
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFFCBD5E1);
  static const Color textMutedDark = Color(0xFF64748B);

  // ── Neutral Palette ─────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;

  // ── Domain Specific: Job Type Colors ────────────────────────────────────
  static const Color fullTime = Color(0xFF2563EB);
  static const Color partTime = Color(0xFF7C3AED);
  static const Color contract = Color(0xFFF59E0B);
  static const Color internship = Color(0xFF059669);
  static const Color freelance = Color(0xFFEC4899);

  // ── Domain Specific: Status ─────────────────────────────────────────────
  static const Color statusActive = Color(0xFF059669);
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusClosed = Color(0xFFDC2626);

  // ── Domain Specific: Application Status ─────────────────────────────────
  static const Color appPending = Color(0xFFF59E0B);
  static const Color appReviewing = Color(0xFF2563EB);
  static const Color appShortlisted = Color(0xFF7C3AED);
  static const Color appInterviewing = Color(0xFF059669);
  static const Color appOffered = Color(0xFF10B981);
  static const Color appRejected = Color(0xFFDC2626);

  // ── Brand Colors ────────────────────────────────────────────────────────
  static const Color google = Color(0xFFDB4437);
  static const Color github = Color(0xFF181717);
  static const Color microsoft = Color(0xFF00A4EF);
  static const Color facebook = Color(0xFF1877F2);
  static const Color linkedin = Color(0xFF0077B5);

  // ── Deprecated Compatibility Aliases (To be removed in later phases) ──
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color secondaryLight = Color(0xFF34D399);
  static const Color accentLight = Color(0xFFFBBF24);
  static const Color grey50 = Color(0xFFF9FAFB);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey900 = Color(0xFF111827);
  static const Color cta = primary;
  static const Color ctaDark = primaryDark;
  static const Color ctaLight = primaryLight;
  static const Color textLight = white;
  static const Color textPrimary = textPrimaryLight;
  static const Color textSecondary = textSecondaryLight;
  static const Color textMuted = textMutedLight;
  static const Color midnight = backgroundDark;
  static const Color instagram = Color(0xFFE1306C);

  static const Color statusPaused = warning;
  static const Color statusFilled = info;
  static const Color pending = warning;
  static const Color reviewing = primary;
  static const Color shortlisted = accent;
  static const Color interviewing = success;
  static const Color offered = successDark;
  static const Color rejected = error;

  static const Color conditionNew = successDark;
  static const Color conditionLikeNew = success;
  static const Color conditionGood = primary;
  static const Color conditionFair = warning;
  static const Color conditionPoor = error;
}

// ── Compatibility Extension ─────────────────────────────────────────────
// Allows old code using AppColors.color[100] or .shade100 to compile.
// Produces proper tints (lighter) and shades (darker) by blending with
// white or black, matching the visual intent of MaterialColor swatches.
extension ColorSwatchExtension on Color {
  Color operator [](int shade) {
    // shade 500 = the color itself
    // shade < 500 = blend toward white (lighter tint)
    // shade > 500 = blend toward black (darker shade)
    if (shade <= 50) return Color.lerp(Colors.white, this, 0.05)!;
    if (shade <= 500) {
      final t = shade / 500.0; // 0.0 (white) → 1.0 (original)
      return Color.lerp(Colors.white, this, t)!;
    }
    final t = (shade - 500) / 500.0; // 0.0 (original) → 1.0 (black)
    return Color.lerp(this, Colors.black, t * 0.6)!;
  }
  
  Color get shade50 => this[50];
  Color get shade100 => this[100];
  Color get shade200 => this[200];
  Color get shade300 => this[300];
  Color get shade400 => this[400];
  Color get shade500 => this[500];
  Color get shade600 => this[600];
  Color get shade700 => this[700];
  Color get shade800 => this[800];
  Color get shade900 => this[900];
}

