// lib/features/marketplace/domain/products_state.dart

import '../../data/models/product_model.dart';

class ProductsState {
  final List<ProductModel> products;
  final bool loading;
  final int currentPage;
  final bool endReached;
  final bool hasMore;
  final String? error;
  final ProductFilters? filters;

  const ProductsState({
    required this.products,
    required this.loading,
    required this.currentPage,
    required this.endReached,
    this.hasMore = true,
    this.error,
    this.filters,
  });

  ProductsState copyWith({
    List<ProductModel>? products,
    bool? loading,
    int? currentPage,
    bool? endReached,
    bool? hasMore,
    String? error,
    ProductFilters? filters,
  }) {
    return ProductsState(
      products: products ?? this.products,
      loading: loading ?? this.loading,
      currentPage: currentPage ?? this.currentPage,
      endReached: endReached ?? this.endReached,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
      filters: filters ?? this.filters,
    );
  }

  bool get isEmpty => products.isEmpty && !loading;
  bool get isNotEmpty => products.isNotEmpty;
  bool get isLoadingMore => loading && products.isNotEmpty;
  bool get isInitialLoading => loading && products.isEmpty;
}

class ProductFilters {
  final String? search;
  final String? category;
  final double? minPrice;
  final double? maxPrice;
  final String? condition;
  final String? location;
  final bool? availableOnly;
  final String? sortBy;
  final String? sortOrder;

  const ProductFilters({
    this.search,
    this.category,
    this.minPrice,
    this.maxPrice,
    this.condition,
    this.location,
    this.availableOnly,
    this.sortBy,
    this.sortOrder,
  });

  ProductFilters copyWith({
    String? search,
    Object? category = _sentinel, // Use a sentinel default
    double? minPrice,
    double? maxPrice,
    String? condition,
    String? location,
    bool? availableOnly,
    String? sortBy,
    String? sortOrder,
  }) {
    return ProductFilters(
      search: search ?? this.search,
      // If category is the sentinel, use existing. If it's null or a string, use that.
      category: category == _sentinel ? this.category : (category as String?),
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      condition: condition ?? this.condition,
      location: location ?? this.location,
      availableOnly: availableOnly ?? this.availableOnly,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toQueryParams() {
    return {
      if (search != null && search!.isNotEmpty) 'search': search,
      if (category != null && category!.isNotEmpty) 'category': category,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
      if (condition != null && condition!.isNotEmpty) 'condition': condition,
      if (location != null && location!.isNotEmpty) 'location': location,
      if (availableOnly != null) 'availableOnly': availableOnly,
      if (sortBy != null) 'sortBy': sortBy,
      if (sortOrder != null) 'sortOrder': sortOrder,
    };
  }

  bool get hasActiveFilters =>
      search != null ||
          category != null ||
          minPrice != null ||
          maxPrice != null ||
          condition != null ||
          location != null ||
          availableOnly != null;

  static const _sentinel = Object();
}