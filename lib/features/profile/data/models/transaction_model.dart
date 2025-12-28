// lib/features/profile/data/models/transaction_model.dart

class TransactionModel {
  final String id;
  final String type; // 'purchase', 'deposit', 'withdrawal', 'refund'
  final double amount;
  final String status; // 'completed', 'pending', 'failed'
  final String? description;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    this.description,
    required this.createdAt,
    this.metadata,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    // 1. Extract nested data from your MeSomb service structure
    final pricing = json['pricing'] as Map<String, dynamic>?;
    final snapshot = json['productSnapshot'] as Map<String, dynamic>?;

    // 2. Defensive Amount Parsing
    // Checks 'amount', then nested 'productPrice', then 'sellerAmount'
    final dynamic rawAmount = json['amount'] ??
        pricing?['productPrice'] ??
        pricing?['sellerAmount'] ??
        0;

    return TransactionModel(
      id: json['_id'] ?? json['id'] ?? 'unknown_id',
      type: json['type'] ?? 'payment',
      // Safe cast: handles nulls, ints, and doubles
      amount: (rawAmount as num).toDouble(),
      status: json['status'] ?? 'pending',
      // Look for name in snapshot first, then description
      description: snapshot?['name'] ??
          json['description'] ??
          (json['type'] == 'deposit' ? 'Wallet Top-up' : 'Transaction'),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      metadata: json['metadata'] ?? json['extra'],
    );
  }
}
// lib/features/profile/data/models/withdrawal_model.dart

class WithdrawalRequest {
  final double amount;
  final String method; // 'MTN', 'ORANGE', 'BANK'
  final String phoneNumber;
  final Map<String, dynamic>? extraDetails;

  WithdrawalRequest({
    required this.amount,
    required this.method,
    required this.phoneNumber,
    this.extraDetails,
    required Map<String, dynamic> accountDetails,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'method': method,
      'phoneNumber': phoneNumber,
      if (extraDetails != null) 'extraDetails': extraDetails,
    };
  }
}