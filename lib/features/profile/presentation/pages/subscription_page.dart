// ============================================================================
// SUBSCRIPTION PLANS PAGE
// lib/features/profile/presentation/pages/subscription_page.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/account_repository.dart';
import '../../../../core/services/feature_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class SubscriptionPage extends ConsumerStatefulWidget {
  const SubscriptionPage({super.key});

  @override
  ConsumerState<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends ConsumerState<SubscriptionPage> {
  bool _subscribing = false;
  String? _selectedPlanId;
  final _phoneController = TextEditingController();

  Future<void> _subscribe() async {
    if (_selectedPlanId == null || _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a plan and enter your phone number')),
      );
      return;
    }

    setState(() => _subscribing = true);
    try {
      final repo = ref.read(accountRepositoryProvider);
      await repo.subscribe(planId: _selectedPlanId!, phoneNumber: _phoneController.text.trim());
      ref.invalidate(mySubscriptionProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Subscription activated!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _subscribing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(plansProvider);
    final subAsync = ref.watch(mySubscriptionProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Subscription Plans'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimaryLight,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        physics: const BouncingScrollPhysics(),
        children: [
          subAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (sub) {
              if (sub == null) return const SizedBox.shrink();
              final plan = sub['plan'];
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.xl),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: AppSpacing.roundedLg,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Active: ${plan?['name'] ?? 'Plan'}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          )
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Expires: ${sub['endDate']?.toString().substring(0, 10) ?? 'N/A'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight)
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Status: ${sub['status']?.toString().toUpperCase()}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight)
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    OutlinedButton(
                      onPressed: () async {
                        await ref.read(accountRepositoryProvider).cancelSubscription();
                        ref.invalidate(mySubscriptionProvider);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                      ),
                      child: const Text('Cancel Subscription'),
                    ),
                  ],
                ),
              );
            },
          ),

          Text(
            'Available Plans', 
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight)
          ),
          const SizedBox(height: AppSpacing.md),

          plansAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => Text('Error loading plans: $e'),
            data: (plans) {
              if (plans.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text('No plans available', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textMutedLight)),
                  )
                );
              }
              return Column(
                children: plans.map<Widget>((plan) {
                  final isSelected = _selectedPlanId == plan['_id'];
                  final features = plan['features'] ?? {};
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPlanId = plan['_id']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: AppSpacing.roundedLg,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.borderLight,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected ? AppSpacing.cardShadow : [],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  plan['name'] ?? '', 
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                                ),
                                Text(
                                  '${plan['price']} ${plan['currency'] ?? 'XAF'}',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold, 
                                    color: AppColors.primary
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${plan['durationDays']} days', 
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMutedLight)
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (features['maxBoostedListings'] != null && features['maxBoostedListings'] > 0)
                              _featureRow(context, Icons.rocket_launch_rounded, '${features['maxBoostedListings']} boosted listings'),
                            if (features['prioritySupport'] == true)
                              _featureRow(context, Icons.support_agent_rounded, 'Priority support'),
                            if (features['unlimitedSearches'] == true)
                              _featureRow(context, Icons.search_rounded, 'Unlimited searches'),
                            if (features['verifiedBadge'] == true)
                              _featureRow(context, Icons.verified_rounded, 'Verified badge'),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: AppSpacing.xl),

          if (_selectedPlanId != null) ...[
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'MoMo Phone Number',
                hintText: '6XXXXXXXX',
                prefixText: '+237 ',
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(borderRadius: AppSpacing.roundedLg, borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: AppSpacing.roundedLg, borderSide: const BorderSide(color: AppColors.borderLight)),
                focusedBorder: OutlineInputBorder(borderRadius: AppSpacing.roundedLg, borderSide: const BorderSide(color: AppColors.primary, width: 2)),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _subscribing ? null : _subscribe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
                ),
                child: _subscribing
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                    : Text('Subscribe Now', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _featureRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}
