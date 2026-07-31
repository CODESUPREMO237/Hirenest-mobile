// ============================================================================
// Admin Disputes Page
// lib/features/admin/presentation/pages/admin_disputes_page.dart
// ============================================================================

import 'package:flutter/material.dart';
import '../../../../core/widgets/error_widget.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/admin_disputes_provider.dart';

class AdminDisputesPage extends ConsumerStatefulWidget {
  const AdminDisputesPage({super.key});

  @override
  ConsumerState<AdminDisputesPage> createState() => _AdminDisputesPageState();
}

class _AdminDisputesPageState extends ConsumerState<AdminDisputesPage> {
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _showResolveDialog(BuildContext context, dynamic order, String resolution) {
    _notesController.clear();
    final isBuyer = resolution == 'buyer';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Resolve for ${isBuyer ? 'Buyer' : 'Seller'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isBuyer
                ? 'This will refund the buyer and cancel the order.'
                : 'This will release the escrowed funds to the seller.'),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Resolution Notes',
                border: OutlineInputBorder(),
                hintText: 'Enter reason for this decision...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isBuyer ? AppColors.error : AppColors.success,
              foregroundColor: AppColors.surfaceLight,
            ),
            onPressed: () async {
              final reason = _notesController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide resolution notes.')),
                );
                return;
              }

              Navigator.pop(context); // close dialog
              
              try {
                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );

                await ref.read(adminServiceProvider).resolveDispute(
                  order['_id'],
                  resolution: resolution,
                  reason: reason,
                );

                if (context.mounted) {
                  Navigator.pop(context); // close loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dispute resolved successfully.'), backgroundColor: AppColors.success),
                  );
                  ref.invalidate(disputedOrdersProvider);
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // close loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Confirm Resolution'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final disputesAsync = ref.watch(disputedOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Disputed Orders', style: TextStyle(color: AppColors.textPrimaryLight)),
        backgroundColor: AppColors.surfaceLight,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(disputedOrdersProvider),
          ),
        ],
      ),
      body: disputesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => CustomErrorWidget(error: error, onRetry: () => ref.invalidate(disputedOrdersProvider)),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Text(
                'No disputed orders found.',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondaryLight),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final buyer = order['buyer'];
              final seller = order['seller'];
              final product = order['product'];
              
              final productPrice = order['pricing']?['productPrice'] ?? 0;
              final currency = order['pricing']?['currency'] ?? 'XAF';
              
              final disputeReason = order['disputeReason'] ?? 'Unknown reason';
              final disputeDateStr = order['disputeDate'];
              final disputeDate = disputeDateStr != null 
                ? DateFormat.yMMMd().add_jm().format(DateTime.parse(disputeDateStr))
                : 'Unknown date';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Order #${order['orderNumber'] ?? order['_id'].toString().substring(0, 8)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: AppSpacing.roundedLg,
                            ),
                            child: const Text(
                              'DISPUTED',
                              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Image
                          if (product != null && product['images'] != null && product['images'].isNotEmpty)
                            ClipRRect(
                              borderRadius: AppSpacing.roundedSm,
                              child: Image.network(
                                product['images'][0],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 60,
                                  height: 60,
                                  color: AppColors.borderLight,
                                  child: const Icon(Icons.image_not_supported, color: AppColors.borderLight),
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppColors.borderLight,
                                borderRadius: AppSpacing.roundedSm,
                              ),
                              child: const Icon(Icons.shopping_bag, color: AppColors.borderLight),
                            ),
                          const SizedBox(width: 16),
                          // Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product?['name'] ?? order['productSnapshot']?['name'] ?? 'Unknown Product',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$productPrice $currency',
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                _buildUserRow(Icons.person_outline, 'Buyer', buyer?['email'] ?? 'Unknown'),
                                const SizedBox(height: 4),
                                _buildUserRow(Icons.storefront, 'Seller', seller?['email'] ?? 'Unknown'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: AppSpacing.roundedSm,
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.error),
                                const SizedBox(width: 8),
                                Text(
                                  'Dispute Reason ($disputeDate)',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              disputeReason,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () => _showResolveDialog(context, order, 'buyer'),
                              child: const Text('Refund Buyer'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: AppColors.surfaceLight,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () => _showResolveDialog(context, order, 'seller'),
                              child: const Text('Pay Seller'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildUserRow(IconData icon, String label, String email) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondaryLight),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(
            email,
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimaryLight),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
