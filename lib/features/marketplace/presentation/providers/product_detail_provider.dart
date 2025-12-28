// Product Detail Provider
// =====================================================
// PRODUCT DETAIL PROVIDER
// lib/features/marketplace/presentation/providers/product_detail_provider.dart
// =====================================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/marketplace_repository.dart';

final productDetailProvider = FutureProvider.family<ProductModel, String>(
      (ref, productId) async {
    return await ref.read(marketplaceRepositoryProvider).getProduct(productId);
  },
);