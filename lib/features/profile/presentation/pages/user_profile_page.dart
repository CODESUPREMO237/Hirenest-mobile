// lib/features/profile/presentation/pages/user_profile_page.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../chat/data/repositories/chat_repository.dart';
import '../providers/user_profile_provider.dart';
import '../../../marketplace/presentation/widgets/product_card.dart';

class UserProfilePage extends ConsumerWidget {
  final String userId;
  const UserProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(userProfileProductsProvider(userId));
    final sellerAsync = ref.watch(userPublicInfoProvider(userId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(userProfileProductsProvider(userId));
          ref.invalidate(userPublicInfoProvider(userId));
        },
        child: CustomScrollView(
          slivers: [
            // 1. App Bar with Seller Info & General Message Button
            sellerAsync.when(
              data: (seller) => SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                backgroundColor: AppColors.primary,
                iconTheme: const IconThemeData(color: AppColors.white),
                flexibleSpace: FlexibleSpaceBar(
                  background: Column(
                    children: [
                      _buildProfileHeader(context, seller),
                      _buildContactButton(context, ref, userId),
                    ],
                  ),
                ),
              ),
              loading: () => const SliverAppBar(
                expandedHeight: 240,
                backgroundColor: AppColors.primary,
                iconTheme: IconThemeData(color: AppColors.white),
              ),
              error: (err, _) => SliverAppBar(
                title: Text("Error: $err", style: const TextStyle(color: AppColors.white)),
                backgroundColor: AppColors.error,
                iconTheme: const IconThemeData(color: AppColors.white),
              ),
            ),

            // 2. Section Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  "Active Listings",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
                ),
              ),
            ),

            // 3. Grid of Products
            productsAsync.when(
              data: (products) => products.isEmpty
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          child: Text(
                            "No items for sale",
                            style: TextStyle(color: AppColors.textMutedLight),
                          ),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65, // Adjusted to fit the extra button and maintain clean spacing
                          mainAxisSpacing: AppSpacing.md,
                          crossAxisSpacing: AppSpacing.md,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = products[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: AppSpacing.roundedLg,
                                border: Border.all(color: AppColors.borderLight),
                                boxShadow: AppSpacing.cardShadow,
                              ),
                              child: Column(
                                children: [
                                  Expanded(child: ProductCard(product: product)),
                                  Padding(
                                    padding: const EdgeInsets.all(AppSpacing.sm),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                          foregroundColor: AppColors.primary,
                                          side: const BorderSide(color: AppColors.primary),
                                          shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                                        ),
                                        onPressed: () => _handleInquiry(context, ref, product),
                                        child: const Text("Inquire", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          childCount: products.length,
                        ),
                      ),
                    ),
              loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
              error: (err, _) => SliverToBoxAdapter(child: Center(child: Text("Error: $err"))),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ),
      ),
    );
  }

  /// Handles inquiry for a specific product
  Future<void> _handleInquiry(BuildContext context, WidgetRef ref, dynamic product) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );

      final repository = ref.read(chatRepositoryProvider);

      final String chatId = await repository.getOrCreateChat(
        receiverId: product.seller.id,
        productId: product.id,
      );

      await repository.sendMessage(
          chatId,
          "Hi, I'm interested in: ${product.name}. Is it still available?"
      );

      if (context.mounted) {
        Navigator.pop(context); // Remove loading
        context.push('/chats/$chatId');
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e", style: const TextStyle(color: AppColors.white)), backgroundColor: AppColors.error));
      }
    }
  }

  Widget _buildProfileHeader(BuildContext context, dynamic seller) {
    return Container(
      padding: const EdgeInsets.only(top: 80, bottom: AppSpacing.md),
      width: double.infinity,
      color: AppColors.primary,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceLight,
              border: Border.all(color: AppColors.surfaceLight, width: 3),
              image: seller.avatar != null
                  ? DecorationImage(image: NetworkImage(seller.avatar!), fit: BoxFit.cover)
                  : null,
            ),
            child: seller.avatar == null
                ? const Icon(Icons.person, size: 40, color: AppColors.textMutedLight)
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            seller.name ?? "User",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: AppColors.warning, size: 16),
              const SizedBox(width: AppSpacing.xs),
              Text(
                "${seller.rating?.toStringAsFixed(1) ?? '5.0'} (${seller.reviewCount ?? 0} reviews)",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.white.withValues(alpha: 0.9),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton(BuildContext context, WidgetRef ref, String sellerId) {
    final isLoading = ValueNotifier<bool>(false);

    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      child: ValueListenableBuilder<bool>(
          valueListenable: isLoading,
          builder: (context, loading, _) {
            return ElevatedButton.icon(
              onPressed: loading ? null : () async {
                isLoading.value = true;
                try {
                  final String chatId = await ref.read(chatRepositoryProvider).getOrCreateChat(
                    receiverId: sellerId,
                    productId: null,
                  );

                  await ref.read(chatRepositoryProvider).sendMessage(
                      chatId,
                      "Hello! I'm interested in your listings. Can we chat?"
                  );

                  if (context.mounted) {
                    context.push('/chats/$chatId');
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Could not open chat: $e"), backgroundColor: AppColors.error)
                    );
                  }
                } finally {
                  isLoading.value = false;
                }
              },
              icon: loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                  : const Icon(Icons.message),
              label: Text(loading ? "Starting Chat..." : "Message Seller"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceLight,
                foregroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 50),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          }
      ),
    );
  }
}