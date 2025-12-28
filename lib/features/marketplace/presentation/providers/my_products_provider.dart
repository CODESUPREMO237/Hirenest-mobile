import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/marketplace_repository.dart';
import 'products_state.dart';
import '../../../../core/utils/logger.dart';

class MyProductsNotifier extends AsyncNotifier<ProductsState> {
  @override
  Future<ProductsState> build() async {
    return _loadProducts();
  }

  Future<ProductsState> _loadProducts() async {
    final repo = ref.read(marketplaceRepositoryProvider);
    final paginated = await repo.getMyProducts();

    return ProductsState(
      products: paginated.items,
      loading: false,
      currentPage: 1,
      endReached: true,
    );
  }

  Future<void> deleteProduct(String productId) async {
    final current = state.value;
    if (current == null) return;

    final repo = ref.read(marketplaceRepositoryProvider);
    final previousProducts = current.products;

    // Optimistic update for immediate UI feedback
    state = AsyncData(
      current.copyWith(
        products: previousProducts.where((p) => p.id != productId).toList(),
      ),
    );

    try {
      await repo.deleteProduct(productId);
    } catch (e, st) {
      AppLogger.error(
        'Failed to delete product $productId',
        error: e,
        stackTrace: st,
      );

      // Rollback on error
      state = AsyncData(
        current.copyWith(products: previousProducts),
      );

      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _loadProducts());
  }
}

// Make sure this is the ONLY definition of myProductsProvider
final myProductsProvider =
AsyncNotifierProvider<MyProductsNotifier, ProductsState>(
  MyProductsNotifier.new,
);

final myProductsStatsProvider = Provider<Map<String, int>>((ref) {
  final state = ref.watch(myProductsProvider).value;

  if (state == null) {
    return {
      'total': 0,
      'active': 0,
      'sold': 0,
      'totalViews': 0,
    };
  }

  final products = state.products;

  return {
    'total': products.length,
    'active': products.where((p) => p.status == 'active').length,
    'sold': products.where((p) => p.status == 'sold').length,
    'totalViews': products.fold<int>(
      0,
          (sum, p) => sum + (p.stats?.views ?? 0),
    ),
  };
});