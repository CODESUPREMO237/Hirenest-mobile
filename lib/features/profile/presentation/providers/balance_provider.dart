// =====================================================
// UPDATED BALANCE PROVIDER
// lib/features/profile/presentation/providers/balance_provider.dart
// =====================================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/logger.dart'; // Import your AppLogger
import '../../data/repositories/payment_repository.dart';

class BalanceData {
  final double availableForWithdrawal;
  final double pendingEarnings;
  final double totalEarnings;
  final String currency;

  BalanceData({
    required this.availableForWithdrawal,
    required this.pendingEarnings,
    required this.totalEarnings,
    required this.currency,
  });
}
// lib/features/profile/presentation/providers/balance_provider.dart

final balanceProvider = FutureProvider<BalanceData>((ref) async {
  final repository = ref.read(paymentRepositoryProvider);

  try {
    final Map<String, dynamic> data = await repository.getBalance();

    // Use a helper to safely convert to double and handle nulls
    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    return BalanceData(
      // MATCHING BACKEND KEYS EXACTLY
      availableForWithdrawal: toDouble(data['availableForWithdrawal']),
      pendingEarnings: toDouble(data['pendingEarnings']),
      totalEarnings: toDouble(data['totalEarnings']),
      currency: data['currency'] ?? 'XAF',
    );
  } catch (e, stack) {
    AppLogger.error('Balance mapping error', error: e, stackTrace: stack);
    rethrow;
  }
});