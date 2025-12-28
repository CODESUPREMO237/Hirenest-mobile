import 'package:json_annotation/json_annotation.dart';

part 'product_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ProductModel {
  @JsonKey(name: '_id')
  final String id;
  final String name;
  final String description;
  final String category;

  final PriceModel price;
  final String condition;
  final List<ProductImageModel> images;
  final LocationModel location;
  final StockModel stock;

  @JsonKey(fromJson: _sellerFromJson)
  final SellerModel seller;

  final DateTime createdAt;
  final DateTime updatedAt;
  final String status;
  final StatsModel? stats;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.condition,
    required this.images,
    required this.location,
    required this.stock,
    required this.seller,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    this.stats,
  });

  static SellerModel _sellerFromJson(dynamic json) {
    if (json == null) return SellerModel(id: '');
    if (json is String) return SellerModel(id: json);
    return SellerModel.fromJson(json as Map<String, dynamic>);
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductModelToJson(this);

  String get primaryImageUrl {
    if (images.isEmpty) return '';
    return images.firstWhere((img) => img.isPrimary, orElse: () => images[0]).url;
  }
}

@JsonSerializable(explicitToJson: true)
class ProductImageModel {
  @JsonKey(name: '_id')
  final String? id;
  final String url;
  final String? publicId;
  final bool isPrimary;
  final int? order;

  ProductImageModel({
    this.id,
    required this.url,
    this.publicId,
    this.isPrimary = false,
    this.order,
  });

  factory ProductImageModel.fromJson(Map<String, dynamic> json) =>
      _$ProductImageModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductImageModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PriceModel {
  @JsonKey(fromJson: _toDouble)
  final double amount;
  final String currency;
  final bool negotiable;

  PriceModel({
    required this.amount,
    required this.currency,
    required this.negotiable,
  });

  static double _toDouble(dynamic val) => (val is num) ? val.toDouble() : 0.0;

  factory PriceModel.fromJson(Map<String, dynamic> json) =>
      _$PriceModelFromJson(json);

  Map<String, dynamic> toJson() => _$PriceModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class StatsModel {
  final int views;
  final int uniqueViews;
  final int chatInitiated;
  final int saves;
  final int shares;

  StatsModel({
    this.views = 0,
    this.uniqueViews = 0,
    this.chatInitiated = 0,
    this.saves = 0,
    this.shares = 0,
  });

  factory StatsModel.fromJson(Map<String, dynamic> json) =>
      _$StatsModelFromJson(json);

  Map<String, dynamic> toJson() => _$StatsModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class LocationModel {
  final String city;
  final String? state;
  final String country;
  final bool canShip;
  final bool pickupAvailable;
  final CoordinatesModel? coordinates;

  LocationModel({
    required this.city,
    this.state,
    required this.country,
    required this.canShip,
    required this.pickupAvailable,
    this.coordinates,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) =>
      _$LocationModelFromJson(json);

  Map<String, dynamic> toJson() => _$LocationModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class CoordinatesModel {
  @JsonKey(fromJson: _toDouble)
  final double latitude;
  @JsonKey(fromJson: _toDouble)
  final double longitude;

  CoordinatesModel({
    required this.latitude,
    required this.longitude,
  });

  static double _toDouble(dynamic val) => (val is num) ? val.toDouble() : 0.0;

  factory CoordinatesModel.fromJson(Map<String, dynamic> json) =>
      _$CoordinatesModelFromJson(json);

  Map<String, dynamic> toJson() => _$CoordinatesModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class StockModel {
  final bool available;
  final int quantity;

  StockModel({
    required this.available,
    required this.quantity,
  });

  factory StockModel.fromJson(Map<String, dynamic> json) =>
      _$StockModelFromJson(json);

  Map<String, dynamic> toJson() => _$StockModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SellerModel {
  @JsonKey(name: '_id')
  final String id;
  final String? name;
  final String? email;
  final String? role;
  final String? avatar;

  @JsonKey(fromJson: _toDouble)
  final double? rating;
  final int? reviewCount;

  SellerModel({
    required this.id,
    this.name,
    this.email,
    this.role,
    this.avatar,
    this.rating,
    this.reviewCount,
  });

  static double? _toDouble(dynamic val) => (val is num) ? val.toDouble() : null;

  /// Custom factory to handle Node.js nested population structure
  factory SellerModel.fromJson(Map<String, dynamic> json) {
    // Look for nested profile object
    final profile = json['profile'] as Map<String, dynamic>?;
    // Look for nested marketplace stats
    final mStats = json['marketplaceStats'] as Map<String, dynamic>?;

    // Build Name
    String? extractedName = profile?['fullName'];
    if (extractedName == null && profile != null) {
      final fName = profile['firstName'] ?? '';
      final lName = profile['lastName'] ?? '';
      extractedName = '$fName $lName'.trim();
    }

    return SellerModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: (extractedName != null && extractedName.isNotEmpty)
          ? extractedName
          : json['username'],
      email: json['email'],
      role: json['role'],
      avatar: profile?['avatar'] ?? json['avatar'],
      rating: _toDouble(json['rating'] ?? mStats?['rating']),
      reviewCount: json['reviewCount'] ?? mStats?['reviewCount'],
    );
  }

  Map<String, dynamic> toJson() => _$SellerModelToJson(this);
}