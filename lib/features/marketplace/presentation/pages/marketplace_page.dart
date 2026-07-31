import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/paginated_products_notifier.dart';
import '../providers/products_state.dart';
import '../widgets/product_card.dart';
import '../widgets/product_shimmer_grid.dart';
import '../widgets/category_chips.dart';
import '../widgets/product_filters_widget.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/services/account_repository.dart';
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

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ProductFiltersWidget(),
    );
  }

  Future<void> _showSaveSearchDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    bool alertsEnabled = true;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Save Product Search'),
              shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Search Name',
                      hintText: 'e.g., Used Laptops',
                      border: OutlineInputBorder(borderRadius: AppSpacing.roundedLg),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SwitchListTile(
                    title: const Text('Email Alerts'),
                    subtitle: const Text('Get notified of new items'),
                    value: alertsEnabled,
                    onChanged: (v) => setState(() => alertsEnabled = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    Navigator.pop(ctx);

                    try {
                      final repo = ref.read(accountRepositoryProvider);
                      await repo.saveSearch(
                        searchType: 'product',
                        name: nameController.text.trim(),
                        criteria: {
                          'query': searchController.text,
                        },
                        alertsEnabled: alertsEnabled,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Search saved!'), 
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'), 
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _onSearchSubmitted(String query) {
    final currentFilters = ref.read(paginatedProductsProvider).value?.filters ?? const ProductFilters();
    final newFilters = currentFilters.copyWith(search: query.isEmpty ? null : query);
    ref.read(paginatedProductsProvider.notifier).applyFilters(newFilters);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paginatedProductsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.push('/marketplace/create');
          if (result == true) {
            ref.read(paginatedProductsProvider.notifier).refresh();
          }
        },
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('Sell Item', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(paginatedProductsProvider.notifier).refresh();
          },
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              // Custom Header with Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Marketplace",
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.bookmark_outline),
                            tooltip: 'Save Search',
                            onPressed: () => _showSaveSearchDialog(context, ref),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      
                      // Search Bar & Filter Row
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              onSubmitted: _onSearchSubmitted,
                              decoration: InputDecoration(
                                hintText: 'Search for anything...',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    searchController.clear();
                                    _onSearchSubmitted('');
                                  },
                                ),
                                filled: true,
                                fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                                border: OutlineInputBorder(
                                  borderRadius: AppSpacing.roundedLg,
                                  borderSide: BorderSide(
                                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: AppSpacing.roundedLg,
                                  borderSide: BorderSide(
                                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: AppSpacing.roundedLg,
                              boxShadow: AppSpacing.cardShadow,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.tune, color: AppColors.white),
                              onPressed: _showFilterSheet,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              state.when(
                data: (productsState) {
                  final products = productsState.products;

                  return SliverMainAxisGroup(
                    slivers: [
                      // Category Chips
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: CategoryChips(
                            categories: const ['Electronics', 'Fashion', 'Home', 'Sports', 'Books', 'Toys', 'Other'],
                            selectedCategory: productsState.filters?.category,
                            onSelected: (cat) {
                              debugPrint("DEBUG: Selected category is: $cat");
                              final currentFilters = productsState.filters ?? const ProductFilters();
                              final newFilters = currentFilters.copyWith(category: cat);
                              ref.read(paginatedProductsProvider.notifier).applyFilters(newFilters);
                            },
                          ),
                        ),
                      ),

                      // Loading or Grid
                      if (products.isEmpty && productsState.loading)
                        const SliverToBoxAdapter(child: ProductShimmerGrid())
                      else if (products.isEmpty && !productsState.loading)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xxl),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.xl),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Text(
                                  'No items found',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Try adjusting your search or filters.',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textMutedLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: AppSpacing.md,
                              crossAxisSpacing: AppSpacing.md,
                              childAspectRatio: 0.65, // Match new card aspect ratio
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

                      if (productsState.loading && products.isNotEmpty) 
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.lg),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                        
                      // Bottom padding to ensure content isn't hidden behind FAB
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 100),
                      ),
                    ],
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => SliverFillRemaining(child: CustomErrorWidget(error: error, onRetry: () => ref.invalidate(paginatedProductsProvider))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
