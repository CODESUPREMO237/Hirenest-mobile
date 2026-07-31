// lib/features/talent/presentation/providers/talent_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/talent_repository.dart';
import '../../../auth/data/models/user_model.dart';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/providers/global_error_provider.dart';

final talentListProvider = FutureProvider<List<UserModel>>((ref) async {
  try {
    final repository = ref.read(talentRepositoryProvider);
    return await repository.getTalent();
  } catch (e) {
    if (e is DioException) {
      final isConnectionError = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown;

      if (isConnectionError) {
        debugPrint('🚨 [talentListProvider] Critical connection failure — triggering global overlay');
        ref.read(globalCriticalErrorProvider.notifier).state = CriticalError(
          message: 'Unable to connect to the server. Please check your internet connection.',
          onRetry: () => ref.invalidateSelf(),
        );
      }
    }
    rethrow;
  }
});
