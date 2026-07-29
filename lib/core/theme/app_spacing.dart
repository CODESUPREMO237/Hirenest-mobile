// ============================================================================
// app_spacing.dart
// lib/core/theme/app_spacing.dart
// ============================================================================

import 'package:flutter/material.dart';

class AppSpacing {
  // ── Padding & Margin ────────────────────────────────────────────────────
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;

  // ── Border Radius ───────────────────────────────────────────────────────
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0;

  // ── Border Radius Geometries ────────────────────────────────────────────
  static const BorderRadius roundedSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius roundedMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius roundedLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius roundedXl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius roundedFull = BorderRadius.all(Radius.circular(radiusFull));

  // ── Shadows ─────────────────────────────────────────────────────────────
  
  /// Subtle shadow for standard cards
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 8.0,
      offset: Offset(0, 2),
    ),
  ];

  /// More pronounced shadow for elevated cards, modals, or floating elements
  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0x12000000),
      blurRadius: 16.0,
      offset: Offset(0, 4),
    ),
  ];

  /// Shadow for elements fixed to the bottom (e.g., bottom nav bar, sticky action bars)
  static const List<BoxShadow> bottomNavShadow = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 12.0,
      offset: Offset(0, -2),
    ),
  ];
}
