// Analytics Repository
// lib/features/analytics/data/repositories/analytics_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(ref.read(dioProvider));
});

class AnalyticsRepository {
  final Dio dio;

  AnalyticsRepository(this.dio);

  // Get user analytics
  Future<Map<String, dynamic>> getUserAnalytics() async {
    try {
      final response = await dio.get(ApiEndpoints.dashboardStats);

      if (response.data['status'] == 'success') {
        return response.data['data']['analytics'] as Map<String, dynamic>;
      }

      throw Exception(response.data['message'] ?? 'Failed to load analytics');
    } catch (e) {
      rethrow;
    }
  }

  // Get platform stats (Admin only)
  Future<Map<String, dynamic>> getPlatformStats({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      };

      final response = await dio.get(
        '/analytics/platform',
        queryParameters: queryParams,
      );

      if (response.data['status'] == 'success') {
        return response.data['data'] as Map<String, dynamic>;
      }

      throw Exception(response.data['message'] ?? 'Failed to load platform stats');
    } catch (e) {
      rethrow;
    }
  }

  // Get revenue analytics (Admin only)
  Future<Map<String, dynamic>> getRevenueAnalytics({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      };

      final response = await dio.get(
        '/analytics/revenue',
        queryParameters: queryParams,
      );

      if (response.data['status'] == 'success') {
        return response.data['data'] as Map<String, dynamic>;
      }

      throw Exception(response.data['message'] ?? 'Failed to load revenue analytics');
    } catch (e) {
      rethrow;
    }
  }
}