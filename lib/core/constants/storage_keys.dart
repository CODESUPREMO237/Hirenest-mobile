
// ============================================================================
// storage_keys.dart
// lib/core/constants/storage_keys.dart
// ============================================================================

class StorageKeys {
  // Auth
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String userRole = 'user_role';

  // User Data
  static const String userData = 'user_data';
  static const String profileData = 'profile_data';

  // Settings
  static const String isDarkMode = 'is_dark_mode';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String language = 'language';

  // Onboarding
  static const String hasSeenOnboarding = 'has_seen_onboarding';

  // Cache
  static const String cachedJobs = 'cached_jobs';
  static const String cachedProducts = 'cached_products';
  static const String cacheTimestamp = 'cache_timestamp';

  // Favorites
  static const String savedJobs = 'saved_jobs';
  static const String savedProducts = 'saved_products';

  // Search History
  static const String jobSearchHistory = 'job_search_history';
  static const String productSearchHistory = 'product_search_history';

  // Biometrics
  static const String biometricEnabled = 'biometric_enabled';
  static const String biometricCredentials = 'biometric_credentials';

}
