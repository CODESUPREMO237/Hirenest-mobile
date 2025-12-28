// ============================================================================
// PRODUCTS REPOSITORY - Data Layer
// lib/features/marketplace/data/repositories/products_repository.dart
// ============================================================================

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../../../../core/models/paginated_response.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepository(ref.read(dioProvider));
});

class ProductsRepository {
  final Dio dio;

  ProductsRepository(this.dio);

  /// Get all products with optional filters
  Future<PaginatedResponse<ProductModel>> getProducts({
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
    double? minPrice,
    double? maxPrice,
    String? condition,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null) 'category': category,
        if (minPrice != null) 'minPrice': minPrice,
        if (maxPrice != null) 'maxPrice': maxPrice,
        if (condition != null) 'condition': condition,
        if (sortBy != null) 'sortBy': sortBy,
        if (sortOrder != null) 'sortOrder': sortOrder,
      };

      final response = await dio.get(
        ApiEndpoints.products,
        queryParameters: queryParams,
      );

      return PaginatedResponse.fromJson(
        response.data['data'],
            (json) => ProductModel.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }



  /// Get single product by ID
  Future<ProductModel> getProduct(String id) async {
    try {
      final response = await dio.get(ApiEndpoints.product(id));

      final data = response.data['data']['product'] ?? response.data['data'];
      return ProductModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get my products
  Future<PaginatedResponse<ProductModel>> getMyProducts({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await dio.get(
        ApiEndpoints.myProducts,
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      return PaginatedResponse.fromJson(
        response.data['data'],
            (json) => ProductModel.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get products by seller
  Future<PaginatedResponse<ProductModel>> getProductsBySeller(
      String sellerId, {
        int page = 1,
        int limit = 20,
      }) async {
    try {
      final response = await dio.get(
        '/marketplace/products/seller/$sellerId',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      return PaginatedResponse.fromJson(
        response.data['data'],
            (json) => ProductModel.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Create new product
  Future<ProductModel> createProduct(FormData formData) async {
    try {
      final response = await dio.post(
        ApiEndpoints.products,
        data: formData,
      );

      final data = response.data['data']['product'] ?? response.data['data'];
      return ProductModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Update product
  Future<ProductModel> updateProduct(String id, FormData formData) async {
    try {
      final response = await dio.put(
        ApiEndpoints.product(id),
        data: formData,
      );

      final data = response.data['data']['product'] ?? response.data['data'];
      return ProductModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete product
  Future<void> deleteProduct(String id) async {
    try {
      await dio.delete(ApiEndpoints.product(id));
    } catch (e) {
      rethrow;
    }
  }

  /// Mark product as sold
  Future<ProductModel> markAsSold(String id) async {
    try {
      final response = await dio.put('/marketplace/products/$id/mark-sold');

      final data = response.data['data']['product'] ?? response.data['data'];
      return ProductModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get nearby products
  Future<PaginatedResponse<ProductModel>> getNearbyProducts({
    required double latitude,
    required double longitude,
    double? radius,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await dio.get(
        ApiEndpoints.nearbyProducts,
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          if (radius != null) 'radius': radius,
          'page': page,
          'limit': limit,
        },
      );

      return PaginatedResponse.fromJson(
        response.data['data'],
            (json) => ProductModel.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get categories
  Future<List<String>> getCategories() async {
    try {
      final response = await dio.get(ApiEndpoints.categories);

      final data = response.data['data']['categories'] ?? response.data['data'] ?? [];
      return List<String>.from(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Report product
  Future<void> reportProduct(String id, String reason) async {
    try {
      await dio.post(
        '/marketplace/products/$id/report',
        data: {'reason': reason},
      );
    } catch (e) {
      rethrow;
    }
  }
}