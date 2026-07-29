// ============================================================================
// app_constants.dart
// lib/core/constants/app_constants.dart
// ============================================================================

class AppConstants {
  // App Info
  static const String appName = 'HireNest';
  static const String appVersion = '1.0.0';

  // API
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Image
  static const int maxImageSizeMB = 5;
  static const int imageQuality = 85;
  static const int maxImagesPerProduct = 5;

  // Cache
  static const int cacheDurationMinutes = 30;
  static const int maxCacheSizeMB = 100;

  // Guest Limits
  static const int guestJobsLimit = 10;
  static const int guestProductsLimit = 20;

  // Job Types
  static const List<String> jobTypes = [
    'full-time',
    'part-time',
    'contract',
    'internship',
    'freelance',
  ];

  // Experience Levels
  static const List<String> experienceLevels = [
    'entry',
    'mid',
    'senior',
    'executive',
  ];

  // Product Conditions
  static const List<String> productConditions = [
    'new',
    'like_new',
    'good',
    'fair',
    'poor',
  ];

  // Categories
  static const List<String> jobCategories = [
    'Technology',
    'Marketing',
    'Sales',
    'Design',
    'Finance',
    'Healthcare',
    'Education',
    'Engineering',
    'Customer Service',
    'Other',
  ];

  static const List<String> productCategories = [
    'Electronics',
    'Fashion',
    'Home & Garden',
    'Sports',
    'Books',
    'Toys',
    'Automotive',
    'Health & Beauty',
    'Other',
  ];

  // Regex Patterns
  static const String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String phonePattern = r'^\+?[1-9]\d{1,14}$';
  static const String urlPattern = r'^https?:\/\/.+';
}