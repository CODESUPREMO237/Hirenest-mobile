// Product Grid
// =====================================================
// lib/features/marketplace/presentation/widgets/product_grid.dart
// =====================================================
import 'package:flutter/material.dart';
import '../../data/models/product_model.dart';
import 'product_card.dart';

class ProductGrid extends StatelessWidget {
  final List<ProductModel> products;
  final Function(ProductModel) onProductTap;

  const ProductGrid({
    super.key,
    required this.products,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No products found'),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductCard(
          product: products[index],
          onTap: () => onProductTap(products[index]),
        );
      },
    );
  }
}
