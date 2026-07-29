import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/order_details_provider.dart';
import '../../data/models/order_model.dart';

class MyOrdersPage extends ConsumerWidget {
  const MyOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myOrdersProvider);
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('My Purchases'), elevation: 0),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) return _buildEmptyState(context);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myOrdersProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: orders.length,
              itemBuilder: (context, index) => _buildOrderCard(context, orders[index]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading orders', style: TextStyle(color: AppColors.error)),
              const SizedBox(height: AppSpacing.sm),
              ElevatedButton(onPressed: () => ref.invalidate(myOrdersProvider), child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.textMutedLight),
          const SizedBox(height: AppSpacing.lg),
          Text('No purchases yet', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.sm),
          Text('When you buy something, it will appear here.', style: TextStyle(color: AppColors.textSecondaryLight)),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(onPressed: () => context.go('/marketplace'), child: const Text('Browse Marketplace')),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    final product = order.product;
    final formatter = NumberFormat.currency(symbol: product?.price?.currency ?? 'FCFA', decimalDigits: 0);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
      elevation: 0,
      color: AppColors.surfaceLight,
      child: InkWell(
        onTap: () => context.push('/marketplace/orders/${order.id}'),
        borderRadius: AppSpacing.roundedMd,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Order #${order.id.substring(order.id.length - 8).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondaryLight)),
                  _buildStatusBadge(order.status),
                ],
              ),
              const Divider(height: AppSpacing.xl),
              Row(
                children: [
                  if (product?.images != null && product!.images!.isNotEmpty)
                    ClipRRect(
                      borderRadius: AppSpacing.roundedSm,
                      child: Image.network(product.images!.first.url, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 60, height: 60, color: AppColors.borderLight, child: const Icon(Icons.broken_image, color: AppColors.textMutedLight))),
                    )
                  else
                    Container(width: 60, height: 60, decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: AppSpacing.roundedSm), child: const Icon(Icons.image, color: AppColors.textMutedLight)),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product?.name ?? 'Unknown Product', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: AppSpacing.xs),
                        Text(formatter.format(order.amount), style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              if (order.status == 'PAID_ESCROW') ...[
                const SizedBox(height: AppSpacing.lg),
                Text('Awaiting shipment from seller.', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
              ] else if (order.status == 'SHIPPED') ...[
                const SizedBox(height: AppSpacing.lg),
                Text('Item shipped! Inspect it and confirm delivery to release funds.', style: TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'PENDING': color = AppColors.warning; label = 'Pending'; break;
      case 'PAID_ESCROW': color = AppColors.info; label = 'Awaiting Shipment'; break;
      case 'SHIPPED': color = AppColors.primary; label = 'Shipped'; break;
      case 'OUT_FOR_DELIVERY': color = AppColors.primary; label = 'Out for Delivery'; break;
      case 'DELIVERED_CONFIRMED':
      case 'RELEASED':
      case 'AUTO_RELEASED': color = AppColors.success; label = 'Completed'; break;
      case 'DISPUTED': color = AppColors.error; label = 'Disputed'; break;
      case 'REFUNDED': color = AppColors.textMutedLight; label = 'Refunded'; break;
      default: color = AppColors.textMutedLight; label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: AppSpacing.roundedMd, border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}