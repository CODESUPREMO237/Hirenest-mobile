// =====================================================
// REPOSITORY (UPDATED)
// lib/features/profile/data/repositories/payment_repository.dart
// =====================================================
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/utils/logger.dart';
import '../models/transaction_model.dart';

class PaymentRepository {
  final Dio _dio;

  PaymentRepository(this._dio);

  /// Fetches balance and returns a Map with keys matching your backend log
  Future<Map<String, dynamic>> getBalance() async {
    try {
      AppLogger.debug('Fetching balance from: ${ApiEndpoints.balance}');
      final response = await _dio.get(ApiEndpoints.balance);

      // Based on your log, the structure is { status: success, data: { ... } }
      final data = response.data['data'];

      if (data == null) {
        AppLogger.warning('API returned success but data was null');
        return {
          'availableForWithdrawal': 0.0,
          'pendingEarnings': 0.0,
          'totalEarnings': 0.0,
        };
      }

      return data as Map<String, dynamic>;
    } catch (e, stack) {
      AppLogger.error('PaymentRepository.getBalance failed', error: e, stackTrace: stack);
      rethrow;
    }
  }


  Future<List<TransactionModel>> getTransactions({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      AppLogger.debug('Fetching transactions from: ${ApiEndpoints.transactions}');
      final response = await _dio.get(
        ApiEndpoints.transactions,
        queryParameters: {'page': page, 'limit': limit},
      );

      // Accessing 'transactions' inside the 'data' object per your logs
      final List? transactionsData = response.data['data']['transactions'];

      if (transactionsData == null) return [];

      return transactionsData
          .map((json) => TransactionModel.fromJson(json))
          .toList();
    } catch (e, stack) {
      AppLogger.error('PaymentRepository.getTransactions failed', error: e, stackTrace: stack);
      throw Exception('Failed to fetch transactions: $e');
    }
  }

  Future<void> requestWithdrawal(Map<String, dynamic> requestData) async {
    try {
      // Using the correct endpoint from your ApiEndpoints class
      await _dio.post(ApiEndpoints.payout, data: requestData);
    } catch (e, stack) {
      AppLogger.error('Withdrawal request failed', error: e, stackTrace: stack);
      if (e is DioException && e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Withdrawal failed');
      }
      throw Exception('Failed to request withdrawal: $e');
    }
  }
  // lib/features/profile/data/repositories/payment_repository.dart

  Future<Map<String, dynamic>> initializeDeposit({
    required double amount,
    required String phoneNumber,
    required String paymentMethod,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.createPayment,
        data: {
          'amount': amount,
          'currency': 'XAF',
          'type': 'deposit',
          'phoneNumber': phoneNumber,
          'paymentMethod': paymentMethod, // e.g., 'mtn' or 'orange'
          'productId': 'wallet_topup',    // Backend requires this; use a placeholder for deposits
        },
      );
      return response.data['data'];
    } catch (e, stack) {
      AppLogger.error('Failed to initialize deposit', error: e, stackTrace: stack);
      rethrow;
    }
  }
// Add to lib/features/profile/data/repositories/payment_repository.dart

  Future<void> purchaseProduct(String productId, double price) async {
    try {
      await _dio.post(
        '/payments/purchase', // Ensure this matches your backend purchase route
        data: {
          'productId': productId,
          'amount': price,
        },
      );
      AppLogger.info('Purchase successful for product: $productId');
    } catch (e, stack) {
      AppLogger.error('Purchase failed', error: e, stackTrace: stack);
      rethrow;
    }
  }
  Future<Map<String, dynamic>> getPaymentMethods() async {
    try {
      final response = await _dio.get(ApiEndpoints.paymentMethods);
      return response.data['data'] ?? {};
    } catch (e, stack) {
      AppLogger.error('Failed to fetch payment methods', error: e, stackTrace: stack);
      throw Exception('Failed to fetch payment methods: $e');
    }
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  // Ensure your dioProvider is correctly configured in your project
  return PaymentRepository(ref.read(dioProvider));
});