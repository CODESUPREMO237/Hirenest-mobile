// lib/features/talent/data/repositories/talent_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/utils/logger.dart';
import '../../../auth/data/models/user_model.dart';

final talentRepositoryProvider = Provider((ref) {
  return TalentRepository(ref.read(dioProvider));
});

class TalentRepository {
  final Dio _dio;

  TalentRepository(this._dio);

  Future<List<UserModel>> getTalent({int page = 1, int limit = 10}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.talent,
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.data['status'] == 'success') {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => UserModel.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      AppLogger.error('DioException in getTalent', error: e);
      throw _handleError(e);
    } catch (e) {
      AppLogger.error('Error in getTalent', error: e);
      throw Exception('Failed to load talent');
    }
  }

  String _handleError(DioException e) {
    if (e.response != null && e.response?.data != null) {
      return e.response?.data['message'] ?? 'An error occurred';
    }
    return e.message ?? 'Network error';
  }
}
