import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

// Providers & Models
import '../providers/balance_provider.dart';
import '../providers/transactions_provider.dart';
import '../../data/models/transaction_model.dart';

// Widgets
import '../widgets/balance_card.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/utils/logger.dart';

class BalancePage extends ConsumerWidget {
  const BalancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(balanceProvider);
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.refresh(balanceProvider.future);
          await ref.refresh(transactionsProvider.future);
        },
        child: balanceAsync.when(
          data: (balance) {
            AppLogger.debug('Balance Data: Avail: ${balance.availableForWithdrawal}, Pending: ${balance.pendingEarnings}');

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Modern App Bar with Balance
                SliverAppBar(
                  expandedHeight: 280,
                  floating: false,
                  pinned: true,
                  backgroundColor: Theme.of(context).primaryColor,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'My Balance',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                                    onPressed: () {
                                      AppLogger.info('Manual refresh triggered on BalancePage');
                                      ref.invalidate(balanceProvider);
                                      ref.invalidate(transactionsProvider);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${balance.availableForWithdrawal.toStringAsFixed(0)} XAF',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.pending_actions_rounded,
                                      color: Colors.white70,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Pending: ${balance.pendingEarnings.toStringAsFixed(0)} XAF',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Quick Actions
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildModernActionButton(
                                context,
                                'Top Up',
                                Icons.add_circle_outline_rounded,
                                Colors.blue,
                                    () => _showTopUpDialog(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildModernActionButton(
                                context,
                                'Withdraw',
                                Icons.arrow_circle_up_rounded,
                                Colors.green,
                                    () => context.push('/profile/payout'),
                                enabled: balance.availableForWithdrawal > 0,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildModernActionButton(
                                context,
                                'History',
                                Icons.history_rounded,
                                Colors.purple,
                                    () => _showTransactionHistory(context, ref),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Recent Transactions Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Activity',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (transactionsAsync.hasValue && transactionsAsync.value!.isNotEmpty)
                          TextButton(
                            onPressed: () => _showTransactionHistory(context, ref),
                            child: const Text('View All'),
                          ),
                      ],
                    ),
                  ),
                ),

                // Transactions List
                transactionsAsync.when(
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildModernTransactionTile(transactions[index]),
                          childCount: transactions.length > 5 ? 5 : transactions.length,
                        ),
                      ),
                    );
                  },
                  loading: () => const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, stack) {
                    AppLogger.error('Transactions List Error', error: err, stackTrace: stack);
                    return SliverFillRemaining(
                      child: CustomErrorWidget(
                        message: 'Could not load transactions',
                        onRetry: () => ref.invalidate(transactionsProvider),
                      ),
                    );
                  },
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) {
            AppLogger.error('Balance Page Major Error', error: err, stackTrace: stack);
            return CustomErrorWidget(
              message: err.toString(),
              onRetry: () => ref.invalidate(balanceProvider),
            );
          },
        ),
      ),
    );
  }

  // --- Modern Helper Widgets ---

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
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your activity will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionButton(
      BuildContext context,
      String label,
      IconData icon,
      Color color,
      VoidCallback onTap, {
        bool enabled = true,
      }) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: enabled ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: enabled ? color : Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: enabled ? Colors.black87 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTransactionTile(TransactionModel transaction) {
    final isWithdrawal = transaction.type.toLowerCase() == 'withdrawal';
    final color = isWithdrawal ? Colors.orange[600]! : Colors.green[600]!;
    final icon = isWithdrawal ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // TODO: Navigate to transaction details
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.description ?? (isWithdrawal ? 'Withdrawal' : 'Payment Received'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeago.format(transaction.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  '${isWithdrawal ? '-' : '+'}${transaction.amount.toStringAsFixed(0)} XAF',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isWithdrawal ? Colors.red[600] : Colors.green[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Dialogs & Bottom Sheets ---

  void _showTopUpDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Top Up Wallet',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter amount to add to your balance',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixText: 'XAF',
                hintText: 'e.g. 5000',
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = controller.text;
              Navigator.pop(context);
              context.push('/profile/deposit?amount=$amount');
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showWithdrawalDialog(BuildContext context, double amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Confirm Withdrawal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'You are about to withdraw ${amount.toStringAsFixed(0)} XAF to your registered account.',
          style: TextStyle(color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/profile/payout');
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  void _showTransactionHistory(BuildContext context, WidgetRef ref) {
    AppLogger.debug('Opening Transaction History Sheet');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            final txAsync = ref.watch(transactionsProvider);
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Text(
                        'All Transactions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: txAsync.when(
                    data: (list) => list.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: list.length,
                      itemBuilder: (context, i) => _buildModernTransactionTile(list[i]),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => CustomErrorWidget(message: e.toString()),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}