import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/profile/presentation/pages/transactions_page.dart';
import '../network/api_client.dart';
import '../constants/api_endpoints.dart';

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService(ref.read(dioProvider));
});

class PaymentService {
  final Dio dio;

  PaymentService(this.dio);

  Future<PaymentResponse> createPayment({
    required String productId,
    required String phoneNumber,
    required String paymentMethod, // 'mesomb_mtn' or 'mesomb_orange'
    required String idempotencyKey,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.createPayment,
        data: {
          'productId': productId,
          'phoneNumber': phoneNumber,
          'paymentMethod': paymentMethod,
          'idempotencyKey': idempotencyKey,
        },
      );

      return PaymentResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<PaymentStatus> checkPaymentStatus(String orderId) async {
    try {
      final response = await dio.get(
        ApiEndpoints.paymentStatus(orderId),
      );

      return PaymentStatus.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<BalanceResponse> getBalance() async {
    try {
      final response = await dio.get(ApiEndpoints.balance);
      return BalanceResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }


  Future<List<Transaction>> getTransactions() async {
    try {
      final response = await dio.get(ApiEndpoints.transactions);

      if (response.data['status'] == 'success') {
        final transactionsList = response.data['data']['transactions'] as List;
        return transactionsList
            .map((json) => Transaction.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to load transactions: $e');
    }
  }
  Future<PayoutResponse> requestPayout({
    required double amount,
    required String phoneNumber,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.payout,
        data: {
          'amount': amount,
          'phoneNumber': phoneNumber,
        },
      );

      return PayoutResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(dynamic error) {
    if (error is DioException) {
      return error.error?.toString() ?? 'Payment error occurred';
    }
    return error.toString();
  }
}


// Models
class PaymentResponse {
  final String orderId;
  final String orderNumber;
  final String status;
  final String mesombReference;

  PaymentResponse({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.mesombReference,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final order = data['order'];
    return PaymentResponse(
      orderId: order['_id'],
      orderNumber: order['orderNumber'],
      status: order['status'],
      mesombReference: data['mesombReference'],
    );
  }
}

class PaymentStatus {
  final String status;
  final String paymentStatus;

  PaymentStatus({
    required this.status,
    required this.paymentStatus,
  });

  factory PaymentStatus.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return PaymentStatus(
      status: data['order']['status'],
      paymentStatus: data['paymentStatus'],
    );
  }
}

class BalanceResponse {
  final double totalEarnings;
  final double availableForWithdrawal;
  final double pendingEarnings;
  final String currency;

  BalanceResponse({
    required this.totalEarnings,
    required this.availableForWithdrawal,
    required this.pendingEarnings,
    required this.currency,
  });

  factory BalanceResponse.fromJson(Map<String, dynamic> json) {
    // The logs show the fields are directly inside 'data'
    final data = json['data'] ?? {};

    return BalanceResponse(
      // Use .toDouble() safely by providing a fallback 0
      totalEarnings: (data['totalEarnings'] ?? 0).toDouble(),
      availableForWithdrawal: (data['availableForWithdrawal'] ?? 0).toDouble(),
      pendingEarnings: (data['pendingEarnings'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'XAF',
    );
  }
}

class PayoutResponse {
  final String status;
  final String reference;

  PayoutResponse({
    required this.status,
    required this.reference,
  });

  factory PayoutResponse.fromJson(Map<String, dynamic> json) {
    final transaction = json['data']['transaction'];
    return PayoutResponse(
      status: transaction['status'],
      reference: transaction['reference'],
    );
  }
}