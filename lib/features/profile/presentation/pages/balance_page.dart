import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

// Providers & Models
import '../providers/balance_provider.dart';
import '../providers/transactions_provider.dart';
import '../../data/models/transaction_model.dart';

// Widgets
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/utils/logger.dart';

class BalancePage extends ConsumerWidget {
  const BalancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(balanceProvider);
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(balanceProvider);
          ref.invalidate(transactionsProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: balanceAsync.when(
          data: (balance) {
            AppLogger.debug('Balance Data: Avail: ${balance.availableForWithdrawal}, Pending: ${balance.pendingEarnings}');

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 260,
                  floating: false,
                  pinned: true,
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
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
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'My Balance',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: AppColors.white.withValues(alpha: 0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.refresh_rounded, color: AppColors.white),
                                    onPressed: () {
                                      AppLogger.info('Manual refresh triggered on BalancePage');
                                      ref.invalidate(balanceProvider);
                                      ref.invalidate(transactionsProvider);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                '${balance.availableForWithdrawal.toStringAsFixed(0)} XAF',
                                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: AppColors.white.withValues(alpha: 0.15),
                                  borderRadius: AppSpacing.roundedLg,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.pending_actions_rounded,
                                      color: AppColors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      'Pending: ${balance.pendingEarnings.toStringAsFixed(0)} XAF',
                                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        color: AppColors.white,
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

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildModernActionButton(
                                context,
                                'Withdraw',
                                Icons.arrow_circle_up_rounded,
                                AppColors.success,
                                () => context.push('/profile/payout'),
                                enabled: balance.availableForWithdrawal > 0,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _buildModernActionButton(
                                context,
                                'History',
                                Icons.history_rounded,
                                AppColors.primary,
                                () => _showTransactionHistory(context, ref),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Activity',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        if (transactionsAsync.hasValue && transactionsAsync.value!.isNotEmpty)
                          TextButton(
                            onPressed: () => _showTransactionHistory(context, ref),
                            child: Text(
                              'View All',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                transactionsAsync.when(
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(context),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildModernTransactionTile(context, transactions[index]),
                          childCount: transactions.length > 5 ? 5 : transactions.length,
                        ),
                      ),
                    );
                  },
                  loading: () => const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
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
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
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
              boxShadow: AppSpacing.elevatedShadow,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 64,
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
            'Your activity will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondaryLight,
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
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.roundedLg,
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: AppSpacing.roundedLg,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl, horizontal: AppSpacing.md),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: enabled ? color.withValues(alpha: 0.1) : AppColors.textMutedLight.withValues(alpha: 0.1),
                    borderRadius: AppSpacing.roundedMd,
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: enabled ? color : AppColors.textMutedLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: enabled ? AppColors.textPrimaryLight : AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTransactionTile(BuildContext context, TransactionModel transaction) {
    final isWithdrawal = transaction.type.toLowerCase() == 'withdrawal';
    final color = isWithdrawal ? AppColors.warning : AppColors.success;
    final icon = isWithdrawal ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.roundedLg,
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppSpacing.roundedLg,
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: AppSpacing.roundedMd,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.description ?? (isWithdrawal ? 'Withdrawal' : 'Payment Received'),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: AppColors.textMutedLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeago.format(transaction.createdAt),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  '${isWithdrawal ? '-' : '+'}${transaction.amount.toStringAsFixed(0)} XAF',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isWithdrawal ? AppColors.error : AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ),
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
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            final txAsync = ref.watch(transactionsProvider);
            return Column(
              children: [
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Row(
                    children: [
                      Text(
                        'All Transactions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textPrimaryLight),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: txAsync.when(
                    data: (list) => list.isEmpty
                        ? _buildEmptyState(context)
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
                            itemCount: list.length,
                            itemBuilder: (context, i) => _buildModernTransactionTile(context, list[i]),
                          ),
                    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
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