// Balance Card
// =====================================================
// PROFILE WIDGETS
// lib/features/profile/presentation/widgets/balance_card.dart
// =====================================================
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class BalanceCard extends StatelessWidget {
  final double available;
  final double pending;
  final VoidCallback? onWithdraw;

  const BalanceCard({
    super.key,
    required this.available,
    required this.pending,
    this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.roundedLg,
        boxShadow: AppSpacing.cardShadow,
        border: Border.all(color: AppColors.borderLight),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Balance',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textMutedLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'XAF$available',
            style: textTheme.headlineMedium?.copyWith(
              color: AppColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pending',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textMutedLight,
                    ),
                  ),
                  Text(
                    'XAF$pending',
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (onWithdraw != null && available > 0)
                ElevatedButton.icon(
                  onPressed: onWithdraw,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.roundedMd,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                  ),
                  icon: const Icon(Icons.account_balance_wallet, size: 20),
                  label: const Text('Withdraw', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}