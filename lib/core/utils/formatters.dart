
// ============================================================================
// formatters.dart
// lib/core/utils/formatters.dart
// ============================================================================

import 'package:intl/intl.dart';

class Formatters {
  static String currency(double amount, {String currency = 'XAF'}) {
    return NumberFormat.currency(
      symbol: currency,
      decimalDigits: 0,
    ).format(amount);
  }

  static String compactCurrency(double amount, {String currency = 'XAF'}) {
    return NumberFormat.compactCurrency(
      symbol: currency,
      decimalDigits: 0,
    ).format(amount);
  }

  static String number(int number) {
    return NumberFormat('#,###').format(number);
  }

  static String date(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String dateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
  }

  static String time(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  static String phone(String phone) {
    // Format: +237 6XX XXX XXX
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');

    if (cleaned.length == 9) {
      return '+237 ${cleaned.substring(0, 1)}${cleaned.substring(1, 3)} ${cleaned.substring(3, 6)} ${cleaned.substring(6)}';
    } else if (cleaned.length == 12) {
      return '+${cleaned.substring(0, 3)} ${cleaned.substring(3, 4)}${cleaned.substring(4, 6)} ${cleaned.substring(6, 9)} ${cleaned.substring(9)}';
    }

    return phone;
  }

  static String fileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
