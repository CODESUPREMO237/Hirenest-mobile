// lib/features/marketplace/presentation/pages/my_products_page.dart

import 'package:flutter/material.dart';
import '../../../../core/widgets/error_widget.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../providers/my_products_provider.dart';
import '../widgets/product_card.dart';

class MyProductsPage extends ConsumerWidget {
  const MyProductsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the products and stats
    final productsState = ref.watch(myProductsProvider);
    final stats = ref.watch(myProductsStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('My Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => context.push('/marketplace/create'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(myProductsProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            /// 1. Stats Dashboard
            if (stats.isNotEmpty)
              SliverToBoxAdapter(
                child: _DashboardStatsGrid(stats: stats),
              ),

            /// 2. Product List
            productsState.when(
              data: (state) {
                final products = state.products;

                if (products.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textMutedLight),
                          SizedBox(height: 16),
                          Text('You haven\'t listed any products yet.'),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final product = products[index];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Dismissible(
                            key: ValueKey(product.id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) => _confirmDelete(context, product.name),
                            onDismissed: (_) async {
                              await ref.read(myProductsProvider.notifier).deleteProduct(product.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${product.name} removed')),
                                );
                              }
                            },
                            background: _buildDeleteBackground(),
                            child: ProductCard(
                              product: product,
                              // FIX: Use the explicit router path string
                              onTap: () => context.push(
                                ApiEndpoints.product(product.id),
                                // onTap: () => context.push('/marketplace/products/${product.id}'),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: products.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => SliverFillRemaining(child: CustomErrorWidget(error: err)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: AppSpacing.roundedMd,
      ),
      child: const Icon(Icons.delete_outline, color: AppColors.white, size: 28),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text('Remove "$name" permanently? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('DELETE', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }
}

class _DashboardStatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _DashboardStatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppSpacing.roundedLg,
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat('Total', stats['total'] ?? 0, AppColors.primary),
          _stat('Active', stats['active'] ?? 0, AppColors.success),
          _stat('Sold', stats['sold'] ?? 0, AppColors.warning),
        ],
      ),
    );
  }

  Widget _stat(String label, dynamic value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
      ],
    );
  }
}