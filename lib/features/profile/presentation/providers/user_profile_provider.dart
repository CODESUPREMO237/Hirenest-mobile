// lib/features/profile/presentation/providers/user_profile_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../marketplace/data/models/product_model.dart';
import '../../../marketplace/data/repositories/marketplace_repository.dart';
// Assuming SellerModel or a similar PublicUser model exists

/// Fetches only the products belonging to a specific user
final userProfileProductsProvider = FutureProvider.family<List<ProductModel>, String>((ref, userId) async {
  return ref.read(marketplaceRepositoryProvider).getProductsBySeller(userId);
});

/// Fetches the public profile details (Name, Bio, Rating) of a specific user
final userPublicInfoProvider = FutureProvider.family<SellerModel, String>((ref, userId) async {
  // This should call an endpoint like GET /users/:id/public
  // If you don't have this endpoint yet, you can often derive it from the
  // first product's seller object in the list above.
  final marketplaceRepo = ref.read(marketplaceRepositoryProvider);
  return marketplaceRepo.getSellerPublicProfile(userId);
});