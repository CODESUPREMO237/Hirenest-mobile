// lib/features/marketplace/presentation/pages/product_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/product_detail_provider.dart';
import '../widgets/image_gallery.dart';
import '../widgets/seller_info_card.dart';
import '../../../chat/data/repositories/chat_repository.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/utils/logger.dart';

class ProductDetailPage extends ConsumerWidget {
  final String productId;

  const ProductDetailPage({
    super.key,
    required this.productId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      body: productAsync.when(
        data: (product) {
// Use this consistently
          final bool isOwner = currentUser?.id.toString() == product.seller.id.toString();

          return CustomScrollView(
            slivers: [
              // Image Gallery App Bar
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: ImageGallery(
                    images: product.images.map((img) => img.url).toList(),
                  ),
                ),
                actions: [
                  if (isOwner)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => context.push('/marketplace/${product.id}/edit'),
                    ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {
                      // Share logic
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showProductOptions(context, ref, product),
                  ),
                ],
              ),

              // Product Info Body
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price and Title Section
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  NumberFormat.currency(
                                    symbol: '${product.price.currency} ',
                                    decimalDigits: 0,
                                  ).format(product.price.amount),
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (product.price.negotiable)
                                Chip(
                                  label: const Text('Negotiable'),
                                  backgroundColor: Colors.orange.withOpacity(0.1),
                                  side: const BorderSide(color: Colors.orange),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            product.name,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: [
                              _buildInfoChip(context, Icons.category_outlined, product.category),
                              _buildInfoChip(context, Icons.inventory_2_outlined, _getConditionText(product.condition)),
                              _buildInfoChip(context, Icons.location_on_outlined, product.location.city),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Divider(),

                    // Description Section
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            product.description,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),

                    const Divider(),

                    // Delivery Options
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivery Options',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          if (product.location.pickupAvailable)
                            _buildDeliveryOption(context, Icons.store_outlined, 'Pickup Available', 'Meet seller at agreed location'),
                          if (product.location.canShip)
                            _buildDeliveryOption(context, Icons.local_shipping_outlined, 'Shipping Available', 'Seller can ship to your location'),
                        ],
                      ),
                    ),

                    const Divider(),

                    // Seller Info Card
                    if (isOwner)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            "This is your listing",
                            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      SellerInfoCard(seller: product.seller),

                    const SizedBox(height: 100), // Bottom padding for FAB/Bar
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          AppLogger.error('Failed to load product details', error: error, stackTrace: stack);

          return CustomErrorWidget(
            message: error.toString(),
            onRetry: () => ref.refresh(productDetailProvider(productId)),
          );
        },
      ),
      bottomNavigationBar: productAsync.maybeWhen(
        data: (product) {
          final bool isOwner = currentUser?.id == product.seller.id;
          return isOwner ? const SizedBox.shrink() : _buildBottomBar(context, ref, product);
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, WidgetRef ref, dynamic product) {
    final ValueNotifier<bool> isChatLoading = ValueNotifier(false);
    final ValueNotifier<bool> isBuyLoading = ValueNotifier(false);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Chat Button
            Expanded(
              child: ValueListenableBuilder<bool>(
                valueListenable: isChatLoading,
                builder: (context, loading, child) {
                  return OutlinedButton.icon(
                    onPressed: loading
                        ? null
                        : () async {
                      isChatLoading.value = true;
                      try {
                        final repository = ref.read(chatRepositoryProvider);
// Validate the seller ID exists
                        if (product.seller.id == null || product.seller.id.isEmpty) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Unable to start chat: Seller information is missing'),
                              ),
                            );
                          }
                          return; // Exit early
                        }
                        // 1. Get the chatId (this is a String, not an object)
                        final String chatId = await repository.getOrCreateChat(
                          receiverId: product.seller.id,
                          productId: product.id, // Pass the productId to keep context!
                        );

                        // 2. Send the automated message using the String ID
                        await repository.sendMessage(
                            chatId,
                            "I'm interested in: ${product.name}"
                        );

                        if (context.mounted) {
                          context.push('/chats/$chatId');
                        }
                      } catch (e, st) {
                        if (context.mounted) {
                          AppLogger.error('Failed to start chat', error: e, stackTrace: st);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Could not start chat: $e')),
                          );
                        }
                      } finally {
                        isChatLoading.value = false;
                      }
                    },
                    icon: loading
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.chat_bubble_outline),
                    label: loading ? const Text('Starting...') : const Text('Chat'),
                  );
                },
              ),
            ),

            const SizedBox(width: 12),

            // Buy Now Button
            Expanded(
              flex: 2,
              child: ValueListenableBuilder<bool>(
                valueListenable: isBuyLoading,
                builder: (context, loading, child) {
                  return ElevatedButton(
                    onPressed: product.stock.available && !loading
                        ? () async {
                      isBuyLoading.value = true;
                      try {
                        // Navigate to payment page
                        if (context.mounted) {
                          context.push('/marketplace/payment/${product.id}');
                        }
                      } catch (e, st) {
                        if (context.mounted) {
                          AppLogger.error('Failed to start payment', error: e, stackTrace: st);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Could not start payment: $e')),
                          );
                        }
                      } finally {
                        isBuyLoading.value = false;
                      }
                    }
                        : null,
                    child: loading
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : Text(product.stock.available ? 'Buy Now' : 'Sold Out'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).primaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryOption(BuildContext context, IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getConditionText(String condition) {
    switch (condition) {
      case 'new':
        return 'New';
      case 'like_new':
        return 'Like New';
      case 'good':
        return 'Good';
      case 'fair':
        return 'Fair';
      case 'poor':
        return 'Poor';
      default:
        return condition;
    }
  }

  void _showProductOptions(BuildContext context, WidgetRef ref, dynamic product) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Report'),
              onTap: () {
                Navigator.pop(context);
                _showReportDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Product'),
        content: const Text('Are you sure you want to report this product?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Report')),
        ],
      ),
    );
  }
}
