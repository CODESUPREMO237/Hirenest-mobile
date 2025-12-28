// lib/features/profile/presentation/pages/user_profile_page.dart

import 'package:flutter/material.dart';
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
      body: RefreshIndicator(
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
                flexibleSpace: FlexibleSpaceBar(
                  background: Column(
                    children: [
                      _buildProfileHeader(context, seller),
                      _buildContactButton(context, ref, userId),
                    ],
                  ),
                ),
              ),
              loading: () => const SliverAppBar(expandedHeight: 240),
              error: (err, _) => SliverAppBar(title: Text("Error: $err")),
            ),

            // 2. Section Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Active Listings",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // 3. Grid of Products
            productsAsync.when(
              data: (products) => products.isEmpty
                  ? const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Text("No items for sale"),
                  ),
                ),
              )
                  : SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7, // Adjusted to fit the extra button
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final product = products[index];
                      return Column(
                        children: [
                          Expanded(child: ProductCard(product: product)),
                          const SizedBox(height: 4),
                          // Quick Inquiry Button for each product
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                side: BorderSide(color: Theme.of(context).primaryColor),
                              ),
                              onPressed: () => _handleInquiry(context, ref, product),
                              child: const Text("Inquire", style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      );
                    },
                    childCount: products.length,
                  ),
                ),
              ),
              loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
              error: (err, _) => SliverToBoxAdapter(child: Center(child: Text("Error: $err"))),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  /// Handles inquiry for a specific product (Matches Product Detail Page logic)
  Future<void> _handleInquiry(BuildContext context, WidgetRef ref, dynamic product) async {
    try {
      // Show simple loading overlay
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final repository = ref.read(chatRepositoryProvider);

      // 1. Get/Update Chat with Product Context
      final String chatId = await repository.getOrCreateChat(
        receiverId: product.seller.id,
        productId: product.id,
      );

      // 2. Send the automated interest message
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Widget _buildProfileHeader(BuildContext context, dynamic seller) {
    return Container(
      padding: const EdgeInsets.only(top: 60, bottom: 10),
      color: Theme.of(context).primaryColor,
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: seller.avatar != null ? NetworkImage(seller.avatar!) : null,
            child: seller.avatar == null ? const Icon(Icons.person, size: 40) : null,
          ),
          const SizedBox(height: 10),
          Text(
            seller.name ?? "User",
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(
                "${seller.rating?.toStringAsFixed(1) ?? '5.0'} (${seller.reviewCount ?? 0} reviews)",
                style: const TextStyle(color: Colors.white70),
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
      color: Theme.of(context).primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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

                  // General message when no specific product is selected
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
                        SnackBar(content: Text("Could not open chat: $e"))
                    );
                  }
                } finally {
                  isLoading.value = false;
                }
              },
              icon: loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue))
                  : const Icon(Icons.message),
              label: Text(loading ? "Starting Chat..." : "Message Seller"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).primaryColor,
                minimumSize: const Size(double.infinity, 45),
                elevation: 0,
              ),
            );
          }
      ),
    );
  }
}