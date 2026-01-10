import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/auth_service.dart';
import '../utils/logger.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['API_BASE_URL'] ?? 'https://your-backend.com/api/v1',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Add interceptors in order
  dio.interceptors.add(AuthInterceptor(ref));

  // if (dotenv.env['FLUTTER_ENV'] == 'development') {
  //   dio.interceptors.add(
  //     PrettyDioLogger(
  //       requestHeader: true,
  //       requestBody: true,
  //       responseHeader: true,
  //       responseBody: true,
  //       error: true,
  //       compact: true,
  //     ),
  //   );
  // }

  // Change the check to match your .env key 'FLUTTER_ENV'
  if (dotenv.env['FLUTTER_ENV'] == 'development') {
    dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: false,   // 1. Set to false to hide headers
        requestBody: false,     // 2. Set to false to hide the sent data
        responseHeader: false,  // 3. Set to false to hide response headers
        responseBody: false,    // 4. CRITICAL: Set to false to stop the large JSON logs
        error: true,            // Keep true so you can still see when things break
        compact: true,
      ),
    );
  }

  dio.interceptors.add(ErrorInterceptor(ref));

  return dio;
});

/// ✅ INTERCEPTOR 1: Adds the token to outgoing requests
class AuthInterceptor extends Interceptor {
  final Ref ref;
  AuthInterceptor(this.ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      if (_shouldSkipAuth(options.path)) {
        AppLogger.debug('🚀 [AuthInterceptor] Skipping auth for: ${options.path}');
        return handler.next(options);
      }

      final authService = ref.read(authServiceProvider);

      // CRITICAL: We use Backend JWT Token, not Firebase ID Token
      final token = await authService.getBackendToken();

      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
        AppLogger.debug('🔑 [AuthInterceptor] Added Backend JWT to: ${options.path}');
      } else {
        AppLogger.warn('⚠️ [AuthInterceptor] No token found for: ${options.path}');
      }
    } catch (e) {
      AppLogger.error('❌ [AuthInterceptor] Error getting token', error: e);
    }
    handler.next(options);
  }

  bool _shouldSkipAuth(String path) {
    final publicEndpoints = [
      '/auth/login',
      '/auth/register',
      '/auth/social',
      '/auth/refresh',
      '/auth/password-reset',
    ];
    return publicEndpoints.any((endpoint) => path.contains(endpoint));
  }
}

/// ✅ INTERCEPTOR 2: Handles 401s, Refreshes, and Retries
class ErrorInterceptor extends Interceptor {
  final Ref ref;
  bool _isRefreshing = false;
  final List<_QueuedRequest> _requestQueue = [];

  ErrorInterceptor(this.ref);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 1. Check for 401 Unauthorized
    if (err.response?.statusCode == 401) {
      AppLogger.warn('🚨 [ErrorInterceptor] 401 Detected at: ${err.requestOptions.path}');

      // If already refreshing, add to queue and wait
      if (_isRefreshing) {
        AppLogger.debug('🕒 [ErrorInterceptor] Refresh in progress, queueing request...');
        _requestQueue.add(_QueuedRequest(err, handler));
        return;
      }

      try {
        _isRefreshing = true;
        final authService = ref.read(authServiceProvider);

        AppLogger.info('🔄 [ErrorInterceptor] Starting Token Refresh Flow...');
        await authService.refreshAccessToken();

        // Get the fresh Backend Token
        final newToken = await authService.getBackendToken();

        if (newToken != null) {
          AppLogger.info('✅ [ErrorInterceptor] Token refresh successful. Retrying original request.');

          // 2. Retry original request with NEW token
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newToken';

          final retryDio = Dio(BaseOptions(
            baseUrl: options.baseUrl,
            headers: options.headers,
            connectTimeout: options.connectTimeout,
            receiveTimeout: options.receiveTimeout,
          ));

          final response = await retryDio.fetch(options);

          // 3. Process all queued requests that failed while we were refreshing
          await _processQueue(newToken);

          return handler.resolve(response);
        } else {
          throw Exception('New token was null after refresh');
        }
      } catch (e) {
        AppLogger.error('💀 [ErrorInterceptor] Refresh Flow failed, logging out...', error: e);
        _rejectQueue(err);
        await ref.read(authServiceProvider).logout();
        return handler.next(err);
      } finally {
        _isRefreshing = false;
      }
    }

    // Handle standard errors
    final errorMessage = _getErrorMessage(err);
    AppLogger.error('❌ [API Error] $errorMessage', error: err);

    handler.next(err);
  }

  /// ✅ Retries all requests that were waiting for the token
  Future<void> _processQueue(String newToken) async {
    AppLogger.debug('📦 [ErrorInterceptor] Processing ${_requestQueue.length} queued requests...');

    final queue = List<_QueuedRequest>.from(_requestQueue);
    _requestQueue.clear();

    for (final queuedRequest in queue) {
      try {
        final options = queuedRequest.error.requestOptions;
        options.headers['Authorization'] = 'Bearer $newToken';

        final retryDio = Dio(BaseOptions(
          baseUrl: options.baseUrl,
          headers: options.headers,
        ));

        AppLogger.debug('🔁 [ErrorInterceptor] Retrying queued request: ${options.path}');
        final response = await retryDio.fetch(options);
        queuedRequest.handler.resolve(response);
      } catch (e) {
        AppLogger.error('❌ [ErrorInterceptor] Queued retry failed', error: e);
        queuedRequest.handler.next(queuedRequest.error);
      }
    }
  }

  void _rejectQueue(DioException originalError) {
    AppLogger.debug('🚫 [ErrorInterceptor] Rejecting ${_requestQueue.length} queued requests');
    for (final queuedRequest in _requestQueue) {
      queuedRequest.handler.next(queuedRequest.error);
    }
    _requestQueue.clear();
  }

  String _getErrorMessage(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout) return 'Connection timeout';
    if (err.type == DioExceptionType.badResponse) {
      return err.response?.data?['message'] ?? 'Server error (${err.response?.statusCode})';
    }
    return err.message ?? 'An unexpected error occurred';
  }
}

class _QueuedRequest {
  final DioException error;
  final ErrorInterceptorHandler handler;
  _QueuedRequest(this.error, this.handler);
}