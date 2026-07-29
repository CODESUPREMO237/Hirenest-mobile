// ============================================================================
// app_text_styles.dart
// lib/core/theme/app_text_styles.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  // Base text themes for Poppins (Headings) and Open Sans (Body)
  static final TextTheme textTheme = TextTheme(
    displayLarge: GoogleFonts.poppins(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.2,
    ),
    displayMedium: GoogleFonts.poppins(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      height: 1.25,
    ),
    displaySmall: GoogleFonts.poppins(
      fontSize: 26,
      fontWeight: FontWeight.w600,
      height: 1.25,
    ),
    headlineLarge: GoogleFonts.poppins(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    headlineMedium: GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.35,
    ),
    headlineSmall: GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.35,
    ),
    titleLarge: GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      height: 1.4,
    ),
    titleMedium: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.4,
    ),
    titleSmall: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.4,
    ),
    bodyLarge: GoogleFonts.openSans(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    bodyMedium: GoogleFonts.openSans(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    bodySmall: GoogleFonts.openSans(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    labelLarge: GoogleFonts.openSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    labelMedium: GoogleFonts.openSans(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.4,
    ),
    labelSmall: GoogleFonts.openSans(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      height: 1.4,
    ),
  );

  /// Helper to apply color to the TextTheme for Light/Dark mode
  static TextTheme getThemeWithColor(Color displayColor, Color bodyColor) {
    return textTheme.apply(
      displayColor: displayColor,
      bodyColor: bodyColor,
    );
  }
}