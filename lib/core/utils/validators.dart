
// ============================================================================
// validators.dart
// lib/core/utils/validators.dart
// ============================================================================
import '../constants/app_constants.dart';

class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(AppConstants.emailPattern);
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }

    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove spaces and special characters
    final cleaned = value.replaceAll(RegExp(r'[^\d+]'), '');

    // Check Cameroon format
    if (!cleaned.startsWith('+237') && !cleaned.startsWith('237') && !cleaned.startsWith('6')) {
      return 'Please enter a valid Cameroon phone number';
    }

    return null;
  }

  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  static String? minLength(String? value, int minLength, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return null; // Let required validator handle this
    }

    if (value.length < minLength) {
      return '${fieldName ?? 'This field'} must be at least $minLength characters';
    }

    return null;
  }

  static String? maxLength(String? value, int maxLength, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return null;
    }

    if (value.length > maxLength) {
      return '${fieldName ?? 'This field'} must be at most $maxLength characters';
    }

    return null;
  }

  static String? url(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    final urlRegex = RegExp(AppConstants.urlPattern);
    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }

    return null;
  }

  static String? number(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }

    return null;
  }
}