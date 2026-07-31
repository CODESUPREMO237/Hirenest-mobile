import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
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

  String _getConditionText(String condition) {
    switch (condition.toLowerCase()) {
      case 'new': return 'New';
      case 'like_new': return 'Like New';
      case 'good': return 'Good';
      case 'fair': return 'Fair';
      case 'poor': return 'Poor';
      default: return condition;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));
    final currentUser = ref.watch(currentUserProvider).value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: productAsync.when(
        data: (product) {
          final bool isOwner = currentUser?.id.toString() == product.seller.id.toString();

          return CustomScrollView(
            slivers: [
              // Image Gallery App Bar
              SliverAppBar(
                expandedHeight: 350,
                pinned: true,
                backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                leading: Container(
                  margin: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.surfaceDark : AppColors.surfaceLight).withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const BackButton(),
                ),
                actions: [
                  if (isOwner)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.surfaceDark : AppColors.surfaceLight).withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => context.push('/marketplace/${product.id}/edit'),
                      ),
                    ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.surfaceDark : AppColors.surfaceLight).withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.share_outlined),
                      onPressed: () {},
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: AppSpacing.xs, right: AppSpacing.md, top: AppSpacing.sm, bottom: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.surfaceDark : AppColors.surfaceLight).withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showProductOptions(context, ref, product),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      ImageGallery(
                        images: product.images.map((img) => img.url).toList(),
                      ),
                      // Gradient overlay for better icon visibility
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 100,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.4),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Product Info Body
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
                  ),
                  transform: Matrix4.translationValues(0, -20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      
                      // Price and Title Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    product.name,
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Text(
                                  NumberFormat.currency(
                                    symbol: '${product.price.currency} ',
                                    decimalDigits: 0,
                                  ).format(product.price.amount),
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (product.price.negotiable) ...[
                                  const SizedBox(width: AppSpacing.sm),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning.withValues(alpha: 0.1),
                                      borderRadius: AppSpacing.roundedSm,
                                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      'Negotiable',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: AppColors.warning,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            
                            const SizedBox(height: AppSpacing.lg),
                            
                            // Chips Row
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildInfoChip(context, Icons.category_outlined, product.category, isDark),
                                  const SizedBox(width: AppSpacing.sm),
                                  _buildInfoChip(context, Icons.inventory_2_outlined, _getConditionText(product.condition), isDark),
                                  const SizedBox(width: AppSpacing.sm),
                                  _buildInfoChip(context, Icons.location_on_outlined, product.location.city, isDark),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight, thickness: 1),
                      ),

                      // Description Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Description',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              product.description,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                height: 1.5,
                                color: isDark ? AppColors.textSecondaryLight : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight, thickness: 1),
                      ),

                      // Delivery Options
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delivery Options',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (product.location.pickupAvailable)
                              _buildDeliveryOption(context, Icons.store_outlined, 'Pickup Available', 'Meet seller at agreed location', isDark),
                            if (product.location.canShip)
                              _buildDeliveryOption(context, Icons.local_shipping_outlined, 'Shipping Available', 'Seller can ship to your location', isDark),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight, thickness: 1),
                      ),

                      // Seller Info Card
                      if (isOwner)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                              borderRadius: AppSpacing.roundedLg,
                              border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  "This is your listing",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SellerInfoCard(seller: product.seller),

                      const SizedBox(height: 120), // Bottom padding for sticky bar
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          AppLogger.error('Failed to load product details', error: error, stackTrace: stack);
          return CustomErrorWidget(
            error: error,
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

  Widget _buildInfoChip(BuildContext context, IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: AppSpacing.roundedFull,
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).primaryColor),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryOption(BuildContext context, IconData icon, String title, String subtitle, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: AppSpacing.roundedMd,
            ),
            child: Icon(icon, color: AppColors.success),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: AppColors.textMutedLight, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, WidgetRef ref, dynamic product) {
    final ValueNotifier<bool> isChatLoading = ValueNotifier(false);
    final ValueNotifier<bool> isBuyLoading = ValueNotifier(false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
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
                        if (product.seller.id == null || product.seller.id.isEmpty) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Unable to start chat: Seller information is missing'),
                              ),
                            );
                          }
                          return;
                        }
                        final String chatId = await repository.getOrCreateChat(
                          receiverId: product.seller.id,
                          productId: product.id,
                        );

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
                    label: loading ? const Text('Starting...') : const Text('Message'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Buy Now Button
            Expanded(
              flex: 1,
              child: ValueListenableBuilder<bool>(
                valueListenable: isBuyLoading,
                builder: (context, loading, child) {
                  return FilledButton(
                    onPressed: product.stock.available && !loading
                        ? () async {
                      isBuyLoading.value = true;
                      try {
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
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
                    ),
                    child: loading
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                        : Text(
                            product.stock.available ? 'Buy Now' : 'Sold Out',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductOptions(BuildContext context, WidgetRef ref, dynamic product) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: AppSpacing.roundedFull,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('Share Product'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: AppColors.error),
                title: const Text('Report Listing', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _showReportDialog(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Product'),
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
        content: const Text('Are you sure you want to report this product? Our team will review the listing.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Cancel')
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context), 
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Report')
          ),
        ],
      ),
    );
  }
}
