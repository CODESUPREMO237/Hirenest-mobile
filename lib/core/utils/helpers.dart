// ============================================================================
// helpers.dart
// lib/core/utils/helpers.dart
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Helpers {
  /* --------------------------------------------------------------------------
   * Build modes
   * -------------------------------------------------------------------------- */

  static bool get isDebug => kDebugMode;
  static bool get isRelease => kReleaseMode;

  /* --------------------------------------------------------------------------
   * Platform checks (Web safe)
   * -------------------------------------------------------------------------- */

  static bool get isWeb => kIsWeb;
  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  static bool get isMobile => isAndroid || isIOS;

  /* --------------------------------------------------------------------------
   * Greetings
   * -------------------------------------------------------------------------- */

  static String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  /* --------------------------------------------------------------------------
   * Name utilities
   * -------------------------------------------------------------------------- */

  static String getInitials(String name) {
    final parts =
    name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();

    if (parts.isEmpty) return '';

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  /* --------------------------------------------------------------------------
   * Avatar color (consistent across sessions)
   * -------------------------------------------------------------------------- */

  static Color getAvatarColor(String text) {
    if (text.isEmpty) return Colors.grey;

    final palette = <Color>[
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];

    final index = text.codeUnitAt(0) % palette.length;
    return palette[index];
  }

  /* --------------------------------------------------------------------------
   * Delay helper
   * -------------------------------------------------------------------------- */

  static Future<void> wait(int milliseconds) {
    return Future.delayed(Duration(milliseconds: milliseconds));
  }
}
