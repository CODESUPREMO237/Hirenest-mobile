// lib/features/marketplace/domain/notifiers/paginated_products_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../../core/providers/global_error_provider.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/marketplace_repository.dart';
import '../providers/products_state.dart';
import '../../../../core/utils/logger.dart';

class PaginatedProductsNotifier extends AsyncNotifier<ProductsState> {
  static const int _pageLimit = 20;

  @override
  Future<ProductsState> build() async {
    return _loadInitial();
  }

  /// Fix _loadInitial to also respect potential default filters
  Future<ProductsState> _loadInitial() async {
    final repo = ref.read(marketplaceRepositoryProvider);
    // If you ever want to start the app with a specific filter,
    // you'd change this line.
    const initialFilters = ProductFilters();

    try {
      final response = await repo.getProducts(page: 1, limit: _pageLimit);
      return ProductsState(
        products: response.items,
        loading: false,
        currentPage: 1,
        endReached: response.items.length < _pageLimit,
        hasMore: response.items.length >= _pageLimit,
        filters: initialFilters,
      );
    } catch (e, st) {
      AppLogger.error('Failed to load initial products', error: e, stackTrace: st);
      if (e is DioException) {
        final isConnectionError = e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.unknown;

        if (isConnectionError) {
          debugPrint('🚨 [paginatedProductsProvider] Critical connection failure — triggering global overlay');
          ref.read(globalCriticalErrorProvider.notifier).state = CriticalError(
            message: 'Unable to connect to the server. Please check your internet connection.',
            onRetry: () => ref.read(paginatedProductsProvider.notifier).refresh(),
          );
        }
      }
      rethrow;
    }
  }

  /// Load next page of products
  Future<void> loadPage() async {
    final current = state.value;
    if (current == null || current.endReached || current.loading) return;

    state = AsyncData(current.copyWith(loading: true));

    final repo = ref.read(marketplaceRepositoryProvider);
    final nextPage = current.currentPage + 1;

    try {
      final response = await repo.getProducts(
        page: nextPage,
        limit: _pageLimit,
        search: current.filters?.search,
        category: current.filters?.category,
        minPrice: current.filters?.minPrice,
        maxPrice: current.filters?.maxPrice,
        condition: current.filters?.condition,
        location: current.filters?.location,
        availableOnly: current.filters?.availableOnly,
        sortBy: current.filters?.sortBy,
        sortOrder: current.filters?.sortOrder,
      );

      final isLastPage = response.items.length < _pageLimit;

      state = AsyncData(
        current.copyWith(
          loading: false,
          currentPage: nextPage,
          products: [...current.products, ...response.items],
          endReached: isLastPage,
          hasMore: !isLastPage,
        ),
      );
    } catch (e, st) {
      AppLogger.error('Failed to load page $nextPage', error: e, stackTrace: st);
      state = AsyncData(current.copyWith(loading: false));
    }
  }

  /// Delete a product with optimistic update
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

      // Rollback on failure
      state = AsyncData(current.copyWith(products: previousProducts));
      rethrow;
    }
  }

  /// Update a single product in the list
  void updateProduct(ProductModel updatedProduct) {
    final current = state.value;
    if (current == null) return;

    final updatedProducts = current.products.map((p) {
      return p.id == updatedProduct.id ? updatedProduct : p;
    }).toList();

    state = AsyncData(current.copyWith(products: updatedProducts));
  }

  /// Mark product as sold with optimistic update
  Future<void> markProductAsSold(String productId) async {
    final current = state.value;
    if (current == null) return;

    final repo = ref.read(marketplaceRepositoryProvider);
    final previousProducts = current.products;

    // Optimistic update
    final updatedProducts = previousProducts.map((p) {
      if (p.id == productId) {
        return p.copyWith(
          status: 'sold',
          stock: StockModel(available: false, quantity: 0),
        );
      }
      return p;
    }).toList();

    state = AsyncData(current.copyWith(products: updatedProducts));

    try {
      final updatedProduct = await repo.markAsSold(productId);
      // Update with server response
      updateProduct(updatedProduct);
    } catch (e, st) {
      AppLogger.error(
        'Failed to mark product as sold $productId',
        error: e,
        stackTrace: st,
      );

      // Rollback on failure
      state = AsyncData(current.copyWith(products: previousProducts));
      rethrow;
    }
  }

  /// Increment view count locally (for immediate UI feedback)
  void incrementViewCount(String productId) {
    final current = state.value;
    if (current == null) return;

    final updatedProducts = current.products.map((p) {
      if (p.id == productId && p.stats != null) {
        return p.copyWith(
          stats: StatsModel(
            views: p.stats!.views + 1,
            uniqueViews: p.stats!.uniqueViews,
            chatInitiated: p.stats!.chatInitiated,
            saves: p.stats!.saves,
            shares: p.stats!.shares,
          ),
        );
      }
      return p;
    }).toList();

    state = AsyncData(current.copyWith(products: updatedProducts));
  }

  /// Increment save count
  void incrementSaveCount(String productId) {
    final current = state.value;
    if (current == null) return;

    final updatedProducts = current.products.map((p) {
      if (p.id == productId && p.stats != null) {
        return p.copyWith(
          stats: StatsModel(
            views: p.stats!.views,
            uniqueViews: p.stats!.uniqueViews,
            chatInitiated: p.stats!.chatInitiated,
            saves: p.stats!.saves + 1,
            shares: p.stats!.shares,
          ),
        );
      }
      return p;
    }).toList();

    state = AsyncData(current.copyWith(products: updatedProducts));
  }

  /// Apply filters and reload
  Future<void> applyFilters(ProductFilters filters) async {
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(loading: true, filters: filters));
    } else {
      state = const AsyncLoading();
    }

    final repo = ref.read(marketplaceRepositoryProvider);

    try {
      final response = await repo.getProducts(
        page: 1,
        limit: _pageLimit,
        search: filters.search,
        category: filters.category,
        minPrice: filters.minPrice,
        maxPrice: filters.maxPrice,
        condition: filters.condition,
        location: filters.location,
        availableOnly: filters.availableOnly,
        sortBy: filters.sortBy,
        sortOrder: filters.sortOrder,
      );

      state = AsyncData(
        ProductsState(
          products: response.items,
          loading: false,
          currentPage: 1,
          endReached: response.items.length < _pageLimit,
          hasMore: response.items.length >= _pageLimit,
          filters: filters,
        ),
      );
    } catch (e, st) {
      AppLogger.error('Failed to apply filters', error: e, stackTrace: st);
      state = AsyncError(e, st);
    }
  }

  /// Clear all filters
  Future<void> clearFilters() async {
    await applyFilters(const ProductFilters());
  }

  /// Refresh products list
  Future<void> refresh() async {
    final currentFilters = state.value?.filters ?? const ProductFilters();
    try {
      await applyFilters(currentFilters);
    } catch (e, st) {
      AppLogger.error('Failed to refresh products', error: e, stackTrace: st);
      state = AsyncError(e, st);
    }
  }


  /// Add a newly created product to the top of the list
  void addProduct(ProductModel product) {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(
      current.copyWith(
        products: [product, ...current.products],
      ),
    );
  }
}

final paginatedProductsProvider =
AsyncNotifierProvider<PaginatedProductsNotifier, ProductsState>(
  PaginatedProductsNotifier.new,
);