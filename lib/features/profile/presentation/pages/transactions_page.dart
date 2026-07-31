// Modern Transaction History Page
// lib/features/profile/presentation/pages/transactions_page.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
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
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Transactions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primaryDark,
                    ],
                  ),
                ),
              ),
            ),
          ),
          transactionsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
            error: (error, stack) => SliverFillRemaining(child: CustomErrorWidget(error: error, onRetry: () => ref.invalidate(transactionsProvider))),
            data: (transactions) {
              if (transactions.isEmpty) {
                return SliverFillRemaining(child: _buildEmptyState(context));
              }

              return SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == 0) {
                        return Column(
                          children: [
                            _buildSummaryCard(context, transactions),
                            const SizedBox(height: AppSpacing.xl),
                            _buildSectionHeader(context, 'Recent Activity'),
                            const SizedBox(height: AppSpacing.md),
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

  Widget _buildSummaryCard(BuildContext context, List<Transaction> transactions) {
    final completed = transactions.where((t) =>
      ['completed', 'success', 'paid_escrow', 'shipped', 'out_for_delivery', 'delivered_confirmed', 'released', 'auto_released']
          .contains(t.status.toLowerCase())
    ).toList();

    final totalIn = completed
        .where((t) => t.type.toLowerCase() == 'payment' || t.type.toLowerCase() == 'refund')
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalOut = completed
        .where((t) => t.type.toLowerCase() == 'payout' || t.type.toLowerCase() == 'withdrawal' || t.type.toLowerCase() == 'purchase')
        .fold(0.0, (sum, t) => sum + t.amount);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: AppSpacing.roundedXl,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
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
                color: AppColors.success,
              ),
              Container(width: 1, height: 40, color: AppColors.white.withValues(alpha: 0.24)),
              _SummaryItem(
                icon: Icons.arrow_upward_rounded,
                label: 'Total Out',
                amount: totalOut,
                currency: transactions.firstOrNull?.currency ?? 'XAF',
                color: AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              shape: BoxShape.circle,
              boxShadow: AppSpacing.cardShadow,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 80,
              color: AppColors.textMutedLight,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'No transactions yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your transaction history will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondaryLight,
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
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            NumberFormat.currency(
              symbol: currency,
              decimalDigits: 0,
            ).format(amount),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.white,
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
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.roundedLg,
        boxShadow: AppSpacing.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: AppSpacing.roundedLg,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  _TransactionIcon(type: transaction.type),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getTransactionTitle(transaction.type),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          transaction.description ?? 'No description',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: AppColors.textMutedLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM dd, yyyy').format(transaction.createdAt),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: AppColors.textMutedLight,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            _StatusBadge(status: transaction.status),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_getAmountPrefix(transaction.type)}${NumberFormat.currency(
                          symbol: transaction.currency,
                          decimalDigits: 0,
                        ).format(transaction.amount)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getAmountColor(transaction.type),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('hh:mm a').format(transaction.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: AppColors.textMutedLight,
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
      case 'purchase':
        return 'Purchase';
      case 'payout':
        return 'Payout';
      case 'refund':
        return 'Refund';
      case 'withdrawal':
        return 'Withdrawal';
      default:
        return type.isNotEmpty ? type[0].toUpperCase() + type.substring(1) : type;
    }
  }

  String _getAmountPrefix(String type) {
    return type.toLowerCase() == 'payment' || type.toLowerCase() == 'refund'
        ? '+'
        : '-';
  }

  Color _getAmountColor(String type) {
    return type.toLowerCase() == 'payment' || type.toLowerCase() == 'refund'
        ? AppColors.success
        : AppColors.error;
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
        color = AppColors.success;
        break;
      case 'purchase':
        icon = Icons.shopping_cart_rounded;
        color = AppColors.error;
        break;
      case 'payout':
      case 'withdrawal':
        icon = Icons.arrow_upward_rounded;
        color = AppColors.error;
        break;
      case 'refund':
        icon = Icons.refresh_rounded;
        color = AppColors.primary;
        break;
      default:
        icon = Icons.attach_money_rounded;
        color = AppColors.textMutedLight;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppSpacing.roundedMd,
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
      case 'paid_escrow':
      case 'shipped':
      case 'out_for_delivery':
      case 'delivered_confirmed':
      case 'released':
      case 'auto_released':
        backgroundColor = AppColors.success.withValues(alpha: 0.15);
        textColor = AppColors.successDark;
        label = status.split('_').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1).toLowerCase() : '').join(' ');
        break;
      case 'pending':
        backgroundColor = AppColors.warning.withValues(alpha: 0.15);
        textColor = AppColors.warning;
        label = 'Pending';
        break;
      case 'failed':
        backgroundColor = AppColors.error.withValues(alpha: 0.15);
        textColor = AppColors.error;
        label = 'Failed';
        break;
      case 'cancelled':
        backgroundColor = AppColors.textMutedLight.withValues(alpha: 0.15);
        textColor = AppColors.textSecondaryLight;
        label = 'Cancelled';
        break;
      default:
        backgroundColor = AppColors.textMutedLight.withValues(alpha: 0.15);
        textColor = AppColors.textSecondaryLight;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppSpacing.roundedSm,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 10,
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
