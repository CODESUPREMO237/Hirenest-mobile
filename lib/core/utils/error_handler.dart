import 'package:dio/dio.dart';
import 'logger.dart';

class ErrorHandler {
  static String getUserFacingMessage(dynamic error) {
    if (error is DioException) {
      AppLogger.error('API Error: ${error.type}', error: error);
      
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
        case DioExceptionType.unknown:
          return 'Unable to connect to the server. Please check your internet connection.';
        case DioExceptionType.badResponse:
          // Try to extract the backend's provided message
          final data = error.response?.data;
          if (data != null && data is Map<String, dynamic> && data['message'] != null) {
            return data['message'].toString();
          }
          return 'Something went wrong on our end. Please try again later.';
        case DioExceptionType.cancel:
          return 'Request was cancelled.';
        default:
          return 'Unable to connect to the server. Please check your internet connection.';
      }
    }
    
    // For any other unexpected Dart errors
    AppLogger.error('Unexpected App Error', error: error);
    return 'Unable to connect to the server. Please check your internet connection.';
  }
}
