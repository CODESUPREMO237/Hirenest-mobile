import 'package:flutter/foundation.dart';
// ============================================================================
// api_client.dart (COMPLETE - Uses Backend JWT for REST API)
// lib/core/network/api_client.dart
// ============================================================================

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../utils/logger.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Add interceptors
  dio.interceptors.add(AuthInterceptor(ref));

  if (AppConfig.isDevelopment) {
    dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
        compact: true,
      ),
    );
  }

  dio.interceptors.add(ErrorInterceptor(ref));

  return dio;
});

// ============================================================================
// AUTH INTERCEPTOR - Uses Backend JWT Token for REST API
// ============================================================================
class AuthInterceptor extends Interceptor {
  final Ref ref;

  AuthInterceptor(this.ref);

  @override
  void onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    debugPrint('');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🔐 [AuthInterceptor] ${options.method} ${options.path}');

    try {
      final authService = ref.read(authServiceProvider);
      debugPrint('   📱 AuthService obtained');

      // ✅ Use getBackendToken() for REST API requests
      final token = await authService.getBackendToken();

      if (token != null) {
        debugPrint('   ✅ Backend JWT found: ${token.substring(0, 30)}...');
        options.headers['Authorization'] = 'Bearer $token';
        debugPrint('   ✅ Authorization header added');
      } else {
        debugPrint('   ⚠️ No backend token - request will be unauthorized');
      }
    } catch (e) {
      debugPrint('   ❌ Error getting token: $e');
      AppLogger.error('Error getting token in interceptor', error: e);
    }

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('');

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    debugPrint('');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🔥 [AuthInterceptor] Error ${err.response?.statusCode}');

    if (err.response?.statusCode == 401) {
      debugPrint('   🔄 401 Unauthorized - attempting token refresh...');
      final authService = ref.read(authServiceProvider);

      // Try to get a fresh backend token (with auto-refresh)
      final newToken = await authService.getBackendToken(forceRefresh: true);
      debugPrint('   🎫 Refresh: ${newToken != null ? "✅ Success" : "❌ Failed"}');

      if (newToken != null) {
        debugPrint('   🔄 Retrying request with new token...');

        // Retry the original request with the new token
        final options = err.requestOptions;
        options.headers['Authorization'] = 'Bearer $newToken';

        try {
          final dio = Dio();
          dio.options.baseUrl = options.baseUrl;
          final response = await dio.fetch(options);
          debugPrint('   ✅ Retry successful');
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          debugPrint('');
          return handler.resolve(response);
        } catch (retryError) {
          debugPrint('   ❌ Retry failed: $retryError');
        }
      }

      // Don't auto-signout here — let the calling code handle it.
      // Auto-signout was causing a destructive race during login flows.
      debugPrint('   ⚠️ Token refresh failed - passing error through');
    }

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('');
    handler.next(err);
  }
}

// ============================================================================
// ERROR INTERCEPTOR
// ============================================================================
class ErrorInterceptor extends Interceptor {
  final Ref ref;
  ErrorInterceptor(this.ref);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String errorMessage = 'An error occurred';

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        errorMessage = 'Unable to connect to the server. Please check your internet connection.';
        break;
      case DioExceptionType.badResponse:
        errorMessage = _handleResponseError(err.response);
        break;
      case DioExceptionType.cancel:
        errorMessage = 'Request cancelled';
        break;
      default:
        errorMessage = 'Something went wrong';
    }

    AppLogger.error(
      'API Error: $errorMessage',
      error: err,
      stackTrace: err.stackTrace,
    );

    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: errorMessage,
      ),
    );
  }

  String _handleResponseError(Response? response) {
    if (response == null) return 'Server error occurred';

    try {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data['message'] ?? data['error'] ?? 'Server error occurred';
      }
    } catch (e) {
      AppLogger.error('Error parsing error response', error: e);
    }

    switch (response.statusCode) {
      case 400:
        return 'Bad request';
      case 401:
        return 'Unauthorized. Please login again.';
      case 403:
        return 'Access forbidden';
      case 404:
        return 'Resource not found';
      case 500:
        return 'Server error';
      default:
        return 'Something went wrong (${response.statusCode})';
    }
  }
}

// ============================================================================
// API RESPONSE WRAPPER
// ============================================================================
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final Map<String, dynamic>? errors;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(
      Map<String, dynamic> json,
      T Function(dynamic)? fromJsonT,
      ) {
    return ApiResponse(
      success: json['status'] == 'success',
      message: json['message'],
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
      errors: json['errors'],
    );
  }
}
