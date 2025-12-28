import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/marketplace_repository.dart';
import 'products_state.dart';
import '../../../../core/utils/logger.dart';

class PaginatedProductsNotifier extends AsyncNotifier<ProductsState> {
  @override
  Future<ProductsState> build() async {
    return _loadInitial();
  }

  Future<ProductsState> _loadInitial() async {
    final repo = ref.read(marketplaceRepositoryProvider);

    try {
      final page1 = await repo.getProducts(page: 1);
      return ProductsState(
        products: page1.items,
        loading: false,
        currentPage: 1,
        endReached: page1.items.isEmpty,
      );
    } catch (e, st) {
      AppLogger.error('Failed to load initial products', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> loadPage() async {
    final current = state.value!;

    if (current.endReached || current.loading) return;

    state = AsyncData(current.copyWith(loading: true));

    final repo = ref.read(marketplaceRepositoryProvider);
    final nextPage = current.currentPage + 1;

    try {
      final response = await repo.getProducts(page: nextPage);
      if (response.items.isEmpty) {
        state = AsyncData(current.copyWith(loading: false, endReached: true));
        return;
      }

      state = AsyncData(
        current.copyWith(
          loading: false,
          currentPage: nextPage,
          products: [...current.products, ...response.items],
        ),
      );
    } catch (e, st) {
      AppLogger.error('Failed to load page $nextPage', error: e, stackTrace: st);
      state = AsyncData(current.copyWith(loading: false));
    }
  }

  Future<void> deleteProduct(String productId) async {
    final current = state.value;
    if (current == null) return;

    final repo = ref.read(marketplaceRepositoryProvider);

    final previousProducts = current.products;

    // Optimistic update
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

      // Rollback
      state = AsyncData(
        current.copyWith(products: previousProducts),
      );

      rethrow;
    }
  }



  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      state = AsyncData(await _loadInitial());
    } catch (e) {
      state = AsyncError(
        'Something went wrong',
        StackTrace.current,
      );

    }
  }
}

final paginatedProductsProvider =
AsyncNotifierProvider<PaginatedProductsNotifier, ProductsState>(
  PaginatedProductsNotifier.new,
);
