import 'package:flutter/material.dart';
import '../../data/models/product_model.dart';
import '../../../../core/utils/logger.dart';

extension ProductImageExtension on ProductModel {
  String get primaryImageFullUrl {
    if (images.isEmpty) return '';
    final primary = images.firstWhere((img) => img.isPrimary, orElse: () => images[0]);
    return primary.url;
  }
}

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isSold = product.status.toLowerCase() == 'sold';
    final Color statusColor = isSold ? Colors.red : Colors.green;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    product.primaryImageFullUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      product.status.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${product.price.amount.toStringAsFixed(0)} XAF',
                    style: TextStyle(
                      color: isSold ? Colors.grey : Colors.green,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      decoration: isSold ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}