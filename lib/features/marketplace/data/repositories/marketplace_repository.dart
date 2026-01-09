// lib/features/marketplace/data/repositories/marketplace_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/models/paginated_response.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../models/order_model.dart';

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  return MarketplaceRepository(ref.read(dioProvider));
});

class MarketplaceRepository {
  final Dio dio;

  MarketplaceRepository(this.dio);

  // Get all products with filters
  Future<PaginatedResponse<ProductModel>> getProducts({
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
    double? minPrice,
    double? maxPrice,
    String? condition,
    String? location,
    bool? availableOnly,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null && category.isNotEmpty) 'category': category,
        if (minPrice != null) 'minPrice': minPrice,
        if (maxPrice != null) 'maxPrice': maxPrice,
        if (condition != null && condition.isNotEmpty) 'condition': condition,
        if (location != null && location.isNotEmpty) 'location': location,
        if (availableOnly != null) 'availableOnly': availableOnly,
        if (sortBy != null) 'sortBy': sortBy,
        if (sortOrder != null) 'sortOrder': sortOrder,
      };

      print('Fetching products with params: $queryParams');

      final response = await dio.get(
        ApiEndpoints.products,
        queryParameters: queryParams,
      );

      print('Response status: ${response.statusCode}');
      print('Response data structure: ${response.data?.keys}');

      if (response.data == null) {
        return PaginatedResponse.empty();
      }

      if (response.data['status'] != 'success') {
        throw Exception(response.data['message'] ?? 'Failed to fetch products');
      }

      final data = response.data['data'];
      if (data == null) {
        return PaginatedResponse.empty();
      }

      return PaginatedResponse.fromJson(
        data,
            (json) => ProductModel.fromJson(json),
      );
    } on DioException catch (e) {
      print('DioException: ${e.type}');
      print('DioException message: ${e.message}');
      print('DioException response: ${e.response?.data}');

      if (e.response?.statusCode == 500) {
        return PaginatedResponse.empty();
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Connection timeout. Please check your internet connection.');
      }

      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Cannot connect to server. Please check your internet connection.');
      }

      rethrow;
    } catch (e) {
      print('General error in getProducts: $e');
      return PaginatedResponse.empty();
    }
  }

  // Get product by ID
  Future<ProductModel> getProduct(String id) async {
    try {
      final response = await dio.get(ApiEndpoints.product(id));

      if (response.data['status'] != 'success') {
        throw Exception(response.data['message'] ?? 'Failed to fetch product');
      }

      return ProductModel.fromJson(response.data['data']['product']);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Product not found');
      }
      rethrow;
    }
  }

  // Create product
  Future<ProductModel> createProduct({
    required String name,
    required String description,
    required String category,
    required double price,
    required String currency,
    required bool negotiable,
    required String condition,
    required String city,
    String? state,
    required String country,
    required bool canShip,
    required bool pickupAvailable,
    required int quantity,
    required List<XFile> images,
    Map<String, dynamic>? coordinates,
  }) async {
    try {
      final compressedImages = await _compressImages(images);

      // Create FormData with proper field structure
      final formData = FormData();

      // Add basic fields
      formData.fields.addAll([
        MapEntry('name', name),
        MapEntry('description', description),
        MapEntry('category', category),
        MapEntry('condition', condition),
      ]);

      // Add price fields with nested structure
      formData.fields.addAll([
        MapEntry('price[amount]', price.toString()),
        MapEntry('price[currency]', currency),
        MapEntry('price[negotiable]', negotiable.toString()),
      ]);

      // Add location fields with nested structure
      formData.fields.addAll([
        MapEntry('location[city]', city),
        MapEntry('location[country]', country),
        MapEntry('location[canShip]', canShip.toString()),
        MapEntry('location[pickupAvailable]', pickupAvailable.toString()),
      ]);

      if (state != null && state.isNotEmpty) {
        formData.fields.add(MapEntry('location[state]', state));
      }

      // Add stock fields with nested structure
      formData.fields.addAll([
        MapEntry('stock[quantity]', quantity.toString()),
        MapEntry('stock[available]', (quantity > 0).toString()),
      ]);

      // Handle coordinates - extract from GeoJSON format and send as flat fields
      if (coordinates != null) {
        final coordsArray = coordinates['coordinates'];
        if (coordsArray is List && coordsArray.length == 2) {
          final longitude = coordsArray[0];
          final latitude = coordsArray[1];

          formData.fields.addAll([
            MapEntry('longitude', longitude.toString()),
            MapEntry('latitude', latitude.toString()),
          ]);

          print('✅ Sending coordinates: longitude=$longitude, latitude=$latitude');
        } else {
          print('⚠️ Invalid coordinates format: $coordinates');
        }
      } else {
        print('⚠️ No coordinates provided');
      }

      // Add images
      for (var i = 0; i < compressedImages.length; i++) {
        formData.files.add(
          MapEntry(
            'images',
            await MultipartFile.fromFile(
              compressedImages[i].path,
              filename: 'image_$i.jpg',
            ),
          ),
        );
      }

      // Debug log
      print('📤 Creating product with fields:');
      for (var field in formData.fields) {
        print('  ${field.key} = ${field.value}');
      }
      print('  images count: ${formData.files.length}');

      final response = await dio.post(
        ApiEndpoints.products,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      if (response.data['status'] != 'success') {
        throw Exception(response.data['message'] ?? 'Failed to create product');
      }

      return ProductModel.fromJson(response.data['data']['product']);
    } on DioException catch (e) {
      print('DioException in createProduct: ${e.message}');
      print('Response: ${e.response?.data}');
      throw Exception('Error creating product: ${e.response?.data['message'] ?? e.message}');
    } catch (e, stackTrace) {
      print('Error creating product: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Error creating product: $e');
    }
  }

  // Update product
  Future<ProductModel> updateProduct(
      String id,
      Map<String, dynamic> updates,
      ) async {
    try {
      final response = await dio.put(
        ApiEndpoints.product(id),
        data: updates,
      );

      return ProductModel.fromJson(response.data['data']['product']);
    } catch (e) {
      throw Exception('Error updating product: $e');
    }
  }

  // Delete product
  Future<void> deleteProduct(String id) async {
    await dio.delete(ApiEndpoints.product(id));
  }

  // Get order by ID
  Future<OrderModel> getOrder(String orderId) async {
    final response = await dio.get('/orders/$orderId');
    return OrderModel.fromJson(response.data['data']['order']);
  }

  // Get my orders
  Future<List<OrderModel>> getMyOrders({String? status}) async {
    final response = await dio.get(
      '/orders/my-orders',
      queryParameters: {
        if (status != null) 'status': status,
      },
    );

    final orders = response.data['data']['orders'] as List;
    return orders.map((json) => OrderModel.fromJson(json)).toList();
  }


  // Get category by ID
  Future<CategoryModel> getCategory(String id) async {
    final response = await dio.get('/marketplace/categories/$id');
    return CategoryModel.fromJson(response.data['data']['category']);
  }

  // Get my products


  Future<PaginatedResponse<ProductModel>> getMyProducts({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final response = await dio.get(
        ApiEndpoints.myProducts,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (status != null) 'status': status,
        },
      );
// Check if status is 200 and what the data looks like
      debugPrint("SERVER RESPONSE: ${response.data['status']}");
      debugPrint("DATA KEYS: ${response.data['data']?.keys}");
      // YOUR BACKEND RETURN: { status: 'success', data: { products: [], pagination: {} } }
      // So we must pass response.data['data'] which contains 'products' and 'pagination'
      if (response.data != null && response.data['data'] != null) {
        print("Raw Response Data: ${response.data}");
        return PaginatedResponse.fromJson(
          response.data['data'],
              (json) => ProductModel.fromJson(json),
        );
      }

      return PaginatedResponse.empty();
    } catch (e) {
      print('Repository Error: $e');
      return PaginatedResponse.empty();
    }
  }
  // Mark product as sold
  Future<ProductModel> markAsSold(String id) async {
    final response = await dio.put('${ApiEndpoints.product(id)}/mark-sold');
    return ProductModel.fromJson(response.data['data']['product']);
  }

  // Get categories
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await dio.get(ApiEndpoints.categories);
      final categories = response.data['data']['categories'] as List;
      return categories.map((json) => CategoryModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // Report product
  Future<void> reportProduct(String id, String reason) async {
    await dio.post(
      '${ApiEndpoints.product(id)}/report',
      data: {'reason': reason},
    );
  }
  Future<List<ProductModel>> getProductsBySeller(String sellerId) async {
    try {
      // Calling your Node.js endpoint: GET /api/v1/marketplace/products/seller/:sellerId
      final response = await dio.get('/marketplace/products/seller/$sellerId');

      if (response.statusCode == 200) {
        final List data = response.data['data']['products'];
        return data.map((json) => ProductModel.fromJson(json)).toList();
      }
      throw Exception('Failed to load seller products');
    } catch (e) {
      rethrow;
    }
  }
  // lib/features/marketplace/data/repositories/marketplace_repository.dart


  Future<SellerModel> getSellerPublicProfile(String sellerId) async {
    try {
      // FIX: Changed userId to sellerId to match the parameter
      final response = await dio.get('/users/$sellerId/public-profile');

      if (response.data['status'] == 'success') {
        // The controller returns { data: { user: { ... } } }
        return SellerModel.fromJson(response.data['data']['user']);
      }
      throw Exception('Failed to load seller profile');
    } catch (e) {
      print('Error in getSellerPublicProfile: $e');
      rethrow;
    }
  }

  // Compress images
  Future<List<XFile>> _compressImages(List<XFile> images) async {
    final compressed = <XFile>[];

    for (var image in images) {
      try {
        final result = await FlutterImageCompress.compressAndGetFile(
          image.path,
          '${image.path}_compressed.jpg',
          quality: 85,
          minWidth: 1024,
          minHeight: 1024,
        );

        if (result != null) {
          compressed.add(XFile(result.path));
        } else {
          compressed.add(image);
        }
      } catch (e) {
        print('Error compressing image: $e');
        compressed.add(image);
      }
    }

    return compressed;
  }
}