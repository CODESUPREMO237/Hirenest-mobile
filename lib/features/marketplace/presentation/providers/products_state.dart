import '../../data/models/product_model.dart';

class ProductsState {
  final List<ProductModel> products;
  final bool loading;
  final int currentPage;
  final bool endReached;

  const ProductsState({
    required this.products,
    required this.loading,
    required this.currentPage,
    required this.endReached,
  });

  ProductsState copyWith({
    List<ProductModel>? products,
    bool? loading,
    int? currentPage,
    bool? endReached,
  }) {
    return ProductsState(
      products: products ?? this.products,
      loading: loading ?? this.loading,
      currentPage: currentPage ?? this.currentPage,
      endReached: endReached ?? this.endReached,
    );
  }
}
