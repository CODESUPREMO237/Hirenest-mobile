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

  dio.interceptors.add(ErrorInterceptor());

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
    print('');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔐 [AuthInterceptor] ${options.method} ${options.path}');

    try {
      final authService = ref.read(authServiceProvider);
      print('   📱 AuthService obtained');

      // ✅ Use getBackendToken() for REST API requests
      final token = await authService.getBackendToken();

      if (token != null) {
        print('   ✅ Backend JWT found: ${token.substring(0, 30)}...');
        options.headers['Authorization'] = 'Bearer $token';
        print('   ✅ Authorization header added');
      } else {
        print('   ⚠️ No backend token - request will be unauthorized');
      }
    } catch (e, stackTrace) {
      print('   ❌ Error getting token: $e');
      AppLogger.error('Error getting token in interceptor', error: e);
    }

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('');

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    print('');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔥 [AuthInterceptor] Error ${err.response?.statusCode}');

    if (err.response?.statusCode == 401) {
      print('   🔄 401 Unauthorized - attempting token refresh...');
      final authService = ref.read(authServiceProvider);

      // Try to get a fresh backend token (with auto-refresh)
      final newToken = await authService.getBackendToken(forceRefresh: true);
      print('   🎫 Refresh: ${newToken != null ? "✅ Success" : "❌ Failed"}');

      if (newToken != null) {
        print('   🔄 Retrying request with new token...');

        // Retry the original request with the new token
        final options = err.requestOptions;
        options.headers['Authorization'] = 'Bearer $newToken';

        try {
          final dio = Dio();
          dio.options.baseUrl = options.baseUrl;
          final response = await dio.fetch(options);
          print('   ✅ Retry successful');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          print('');
          return handler.resolve(response);
        } catch (retryError) {
          print('   ❌ Retry failed: $retryError');
        }
      }

      // If refresh fails, sign out the user
      print('   ⚠️ Token refresh failed - signing out');
      await authService.signOut();
    }

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('');
    handler.next(err);
  }
}

// ============================================================================
// ERROR INTERCEPTOR
// ============================================================================
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String errorMessage = 'An error occurred';

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorMessage = 'Connection timeout. Please check your internet connection.';
        break;
      case DioExceptionType.badResponse:
        errorMessage = _handleResponseError(err.response);
        break;
      case DioExceptionType.cancel:
        errorMessage = 'Request cancelled';
        break;
      case DioExceptionType.connectionError:
        errorMessage = 'No internet connection';
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