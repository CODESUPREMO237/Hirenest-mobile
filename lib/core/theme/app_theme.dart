import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  /* --------------------------------------------------------------------------
   * Colors
   * -------------------------------------------------------------------------- */

  static const Color primaryColor = Color(0xFF6366F1);
  static const Color secondaryColor = Color(0xFF10B981);
  static const Color accentColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);

  // Light
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color surfaceLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color borderLight = Color(0xFFE5E7EB);

  // Dark
  static const Color backgroundDark = Color(0xFF111827);
  static const Color surfaceDark = Color(0xFF1F2937);
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color borderDark = Color(0xFF374151);

  /* --------------------------------------------------------------------------
   * Design Tokens
   * -------------------------------------------------------------------------- */

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;

  static const double elevationNone = 0;
  static const double elevationSm = 1;
  static const double elevationMd = 3;
  static const double elevationLg = 8;

  static const EdgeInsets buttonPadding =
  EdgeInsets.symmetric(horizontal: 24, vertical: 16);

  static const EdgeInsets inputPadding =
  EdgeInsets.symmetric(horizontal: 16, vertical: 16);

  /* --------------------------------------------------------------------------
   * Typography
   * -------------------------------------------------------------------------- */

  static TextTheme _textTheme(Color primary, Color secondary) {
    return GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: primary,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        height: 1.5,
        color: primary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        height: 1.45,
        color: primary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        color: secondary,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: primary,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondary,
      ),
    );
  }

  /* --------------------------------------------------------------------------
   * Base Theme Builder
   * -------------------------------------------------------------------------- */

  static ThemeData _baseTheme({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required Color background,
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
    required Color border,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      visualDensity: VisualDensity.adaptivePlatformDensity,

      /* ---------------- AppBar ---------------- */
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: elevationNone,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),

      /* ---------------- Cards ---------------- */
      cardTheme: CardThemeData(
        color: surface,
        elevation: elevationSm,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(color: border),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      /* ---------------- Dialogs ---------------- */
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: elevationLg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
      ),

      /* ---------------- Buttons ---------------- */
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: elevationNone,
          padding: buttonPadding,
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: buttonPadding,
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      /* ---------------- Inputs ---------------- */
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: inputPadding,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: errorColor),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: textSecondary,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: textSecondary,
        ),
      ),

      /* ---------------- Navigation ---------------- */
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: elevationNone,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      /* ---------------- Snackbar ---------------- */
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: GoogleFonts.inter(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),

      textTheme: _textTheme(textPrimary, textSecondary),
    );
  }

  /* --------------------------------------------------------------------------
   * Public Themes
   * -------------------------------------------------------------------------- */

  static ThemeData get lightTheme => _baseTheme(
    brightness: Brightness.light,
    background: backgroundLight,
    surface: surfaceLight,
    border: borderLight,
    textPrimary: textPrimaryLight,
    textSecondary: textSecondaryLight,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      error: errorColor,
    ),
  );

  static ThemeData get darkTheme => _baseTheme(
    brightness: Brightness.dark,
    background: backgroundDark,
    surface: surfaceDark,
    border: borderDark,
    textPrimary: textPrimaryDark,
    textSecondary: textSecondaryDark,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      error: errorColor,
    ),
  );
}
