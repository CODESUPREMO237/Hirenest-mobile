// Modern Transaction History Page
// lib/features/profile/presentation/pages/transactions_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/payment_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/error_widget.dart';

// Provider for transactions
final transactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final paymentService = ref.read(paymentServiceProvider);
  try {
    final data = await paymentService.getTransactions();
    return data;
  } catch (e, stack) {
    AppLogger.error('TRANSACTION_FETCH_ERROR', error: e, stackTrace: stack);
    rethrow;
  }
});

class TransactionsPage extends ConsumerWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Transactions',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),
          ),
          transactionsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => SliverFillRemaining(
              child: CustomErrorWidget(
                message: 'Unable to load your transactions. Please try again.',
                onRetry: () => ref.invalidate(transactionsProvider),
              ),
            ),
            data: (transactions) {
              if (transactions.isEmpty) {
                return SliverFillRemaining(child: _buildEmptyState());
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      if (index == 0) {
                        return Column(
                          children: [
                            _buildSummaryCard(transactions),
                            const SizedBox(height: 24),
                            _buildSectionHeader('Recent Activity'),
                            const SizedBox(height: 12),
                          ],
                        );
                      }
                      return _TransactionCard(
                        transaction: transactions[index - 1],
                      );
                    },
                    childCount: transactions.length + 1,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(List<Transaction> transactions) {
    final completed = transactions.where((t) =>
    t.status.toLowerCase() == 'completed' || t.status.toLowerCase() == 'success'
    ).toList();

    final totalIn = completed
        .where((t) => t.type.toLowerCase() == 'payment' || t.type.toLowerCase() == 'refund')
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalOut = completed
        .where((t) => t.type.toLowerCase() == 'payout' || t.type.toLowerCase() == 'withdrawal')
        .fold(0.0, (sum, t) => sum + t.amount);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[600]!,
            Colors.blue[800]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SummaryItem(
                icon: Icons.arrow_downward_rounded,
                label: 'Total In',
                amount: totalIn,
                currency: transactions.firstOrNull?.currency ?? 'XAF',
                color: Colors.greenAccent,
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              _SummaryItem(
                icon: Icons.arrow_upward_rounded,
                label: 'Total Out',
                amount: totalOut,
                currency: transactions.firstOrNull?.currency ?? 'XAF',
                color: Colors.redAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 80,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your transaction history will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;
  final String currency;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.amount,
    required this.currency,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            NumberFormat.currency(
              symbol: currency,
              decimalDigits: 0,
            ).format(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Transaction transaction;

  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // TODO: Navigate to transaction details
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _TransactionIcon(type: transaction.type),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getTransactionTitle(transaction.type),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          transaction.description ?? 'No description',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM dd, yyyy').format(transaction.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(width: 12),
                            _StatusBadge(status: transaction.status),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_getAmountPrefix(transaction.type)}${NumberFormat.currency(
                          symbol: transaction.currency,
                          decimalDigits: 0,
                        ).format(transaction.amount)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getAmountColor(transaction.type),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('hh:mm a').format(transaction.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getTransactionTitle(String type) {
    switch (type.toLowerCase()) {
      case 'payment':
        return 'Payment Received';
      case 'payout':
        return 'Payout';
      case 'refund':
        return 'Refund';
      case 'withdrawal':
        return 'Withdrawal';
      default:
        return type;
    }
  }

  String _getAmountPrefix(String type) {
    return type.toLowerCase() == 'payment' || type.toLowerCase() == 'refund'
        ? '+'
        : '-';
  }

  Color _getAmountColor(String type) {
    return type.toLowerCase() == 'payment' || type.toLowerCase() == 'refund'
        ? Colors.green[600]!
        : Colors.red[600]!;
  }
}

class _TransactionIcon extends StatelessWidget {
  final String type;

  const _TransactionIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (type.toLowerCase()) {
      case 'payment':
        icon = Icons.arrow_downward_rounded;
        color = Colors.green;
        break;
      case 'payout':
      case 'withdrawal':
        icon = Icons.arrow_upward_rounded;
        color = Colors.red;
        break;
      case 'refund':
        icon = Icons.refresh_rounded;
        color = Colors.blue;
        break;
      default:
        icon = Icons.attach_money_rounded;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        backgroundColor = Colors.green.withOpacity(0.15);
        textColor = Colors.green[700]!;
        label = 'Completed';
        break;
      case 'pending':
        backgroundColor = Colors.orange.withOpacity(0.15);
        textColor = Colors.orange[700]!;
        label = 'Pending';
        break;
      case 'failed':
        backgroundColor = Colors.red.withOpacity(0.15);
        textColor = Colors.red[700]!;
        label = 'Failed';
        break;
      case 'cancelled':
        backgroundColor = Colors.grey.withOpacity(0.15);
        textColor = Colors.grey[700]!;
        label = 'Cancelled';
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.15);
        textColor = Colors.grey[700]!;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// lib/features/payments/models/transaction.dart

class Transaction {
  final String id;
  final String type;
  final double amount;
  final String currency;
  final String status;
  final String? description;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.currency,
    required this.status,
    this.description,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final pricing = json['pricing'] as Map<String, dynamic>?;
    final snapshot = json['productSnapshot'] as Map<String, dynamic>?;

    return Transaction(
      id: json['_id'] ?? json['id'] ?? 'unknown',
      type: json['type'] ?? 'purchase',
      amount: ((pricing?['productPrice'] ?? json['amount'] ?? 0) as num).toDouble(),
      currency: pricing?['currency'] ?? json['currency'] ?? 'XAF',
      status: json['status'] ?? 'pending',
      description: snapshot?['name'] ?? json['description'] ?? 'No description',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}