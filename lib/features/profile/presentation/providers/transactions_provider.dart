// =====================================================
// TRANSACTIONS PROVIDER
// lib/features/profile/presentation/providers/transactions_provider.dart
// =====================================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/payment_repository.dart';

final transactionsProvider = FutureProvider<List<TransactionModel>>((ref) async {
  final repository = ref.read(paymentRepositoryProvider);
  return await repository.getTransactions();
});