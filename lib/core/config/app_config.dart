import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class AppConfig {
  // API Configuration
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000/api/v1';

  static String get socketUrl =>
      dotenv.env['SOCKET_URL'] ?? 'http://localhost:5000';

  static String get appName =>
      dotenv.env['APP_NAME'] ?? 'HireNest';

  static String get appVersion =>
      dotenv.env['APP_VERSION'] ?? '1.0.0';

  // Environment
  static bool get isDevelopment =>
      dotenv.env['FLUTTER_ENV'] == 'development' || !kReleaseMode;

  // Pagination
  static const int itemsPerPage = 20;

  // Commission rate as a decimal (e.g., 5% = 0.05)
  static const double commissionRate = 0.05;

  // File Upload
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const int maxImages = 5;

  // Guest Limits
  static const int guestJobViewLimit = 10;
  static const int guestProductViewLimit = 20;

  // Cache
  static const Duration cacheDuration = Duration(minutes: 15);
  static int get cacheDurationMinutes => cacheDuration.inMinutes;

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // OAuth Configuration
  static String get githubClientId =>
      dotenv.env['GITHUB_CLIENT_ID'] ?? '';

  static String get githubRedirectUri =>
      dotenv.env['GITHUB_REDIRECT_URI'] ?? '';

  // Microsoft OAuth
  static String get microsoftClientId =>
      dotenv.env['MICROSOFT_CLIENT_ID'] ?? '';
  static String get microsoftTenantId =>
      dotenv.env['MICROSOFT_TENANT_ID'] ?? 'common';
  static String get microsoftRedirectUri =>
      dotenv.env['MICROSOFT_REDIRECT_URI'] ?? '';


  // Optional: Google OAuth (if needed for configuration)
  static String get googleClientId =>
      dotenv.env['GOOGLE_CLIENT_ID'] ?? '';

  static String get googleServerClientId =>
      dotenv.env['GOOGLE_SERVER_CLIENT_ID'] ?? '';

  static String? get googleHostedDomain =>
      dotenv.env['GOOGLE_HOSTED_DOMAIN'];
}