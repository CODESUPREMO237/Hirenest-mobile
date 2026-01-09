import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/PaginatedProductsNotifier.dart';
import '../providers/products_state.dart';
import '../widgets/product_card.dart';
import '../widgets/product_shimmer_grid.dart';
import '../widgets/category_chips.dart';
import '../widgets/product_filters_widget.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/error_widget.dart';
import 'package:go_router/go_router.dart';

class MarketplacePage extends ConsumerStatefulWidget {
  const MarketplacePage({super.key});

  @override
  ConsumerState<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends ConsumerState<MarketplacePage> {
  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();



  @override
  void initState() {
    super.initState();

    scrollController.addListener(() {
      final notifier = ref.read(paginatedProductsProvider.notifier);
      if (scrollController.position.pixels >
          scrollController.position.maxScrollExtent - 250) {
        notifier.loadPage();
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

// Inside _MarketplacePageState
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Keeps the rounded corners visible
      builder: (context) => const ProductFiltersWidget(), // Use the correct name
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paginatedProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Marketplace"),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list), // Add this button
            onPressed: _showFilterSheet,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(paginatedProductsProvider.notifier).refresh(),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.push('/marketplace/create');
          if (result == true) {
            ref.read(paginatedProductsProvider.notifier).refresh();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Sell'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(paginatedProductsProvider.notifier).refresh();
        },
        child: state.when(
          data: (productsState) {
            final products = productsState.products;

            return CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: CategoryChips(
                      // 1. Matches the categories in your Filter Widget
                      categories: const ['Electronics', 'Fashion', 'Home', 'Sports', 'Books', 'Toys', 'Other'],

                      // 2. Use ?. and ?? to handle potential null filters
                      selectedCategory: productsState.filters?.category,

                      onSelected: (cat) {
                        print("DEBUG: Selected category is: $cat"); // If you click All, this should print null
                        // 3. Handle null by providing a default ProductFilters object if state.filters is null
                        final currentFilters = productsState.filters ?? const ProductFilters();
                        final newFilters = currentFilters.copyWith(category: cat);

                        ref.read(paginatedProductsProvider.notifier).applyFilters(newFilters);
                      },
                    ),
                  ),
                ),

                if (products.isEmpty && productsState.loading)
                  const SliverToBoxAdapter(child: ProductShimmerGrid())
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(12),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: .75,
                      ),
                      delegate: SliverChildBuilderDelegate(
                            (context, i) => ProductCard(
                          product: products[i],
                          onTap: () {
                            AppLogger.debug('🐛 Tapped product id: ${products[i].id}');
                            context.push('/marketplace/products/${products[i].id}');
                          },
                        ),
                        childCount: products.length,
                      ),
                    ),
                  ),

                if (productsState.loading) const SliverToBoxAdapter(child: ProductShimmerGrid()),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => CustomErrorWidget(
            message: error.toString(),
            onRetry: () => ref.read(paginatedProductsProvider.notifier).refresh(),
          ),
        ),
      ),
    );
  }
}
