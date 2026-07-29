// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductModel _$ProductModelFromJson(Map<String, dynamic> json) => ProductModel(
      id: json['_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      price: PriceModel.fromJson(json['price'] as Map<String, dynamic>),
      condition: json['condition'] as String,
      images: (json['images'] as List<dynamic>)
          .map((e) => ProductImageModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      location:
          LocationModel.fromJson(json['location'] as Map<String, dynamic>),
      stock: StockModel.fromJson(json['stock'] as Map<String, dynamic>),
      seller: ProductModel._sellerFromJson(json['seller']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      status: json['status'] as String,
      stats: json['stats'] == null
          ? null
          : StatsModel.fromJson(json['stats'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ProductModelToJson(ProductModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'category': instance.category,
      'price': instance.price.toJson(),
      'condition': instance.condition,
      'images': instance.images.map((e) => e.toJson()).toList(),
      'location': instance.location.toJson(),
      'stock': instance.stock.toJson(),
      'seller': instance.seller.toJson(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'status': instance.status,
      'stats': instance.stats?.toJson(),
    };

ProductImageModel _$ProductImageModelFromJson(Map<String, dynamic> json) =>
    ProductImageModel(
      id: json['_id'] as String?,
      url: json['url'] as String,
      publicId: json['publicId'] as String?,
      isPrimary: json['isPrimary'] as bool? ?? false,
      order: (json['order'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ProductImageModelToJson(ProductImageModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'url': instance.url,
      'publicId': instance.publicId,
      'isPrimary': instance.isPrimary,
      'order': instance.order,
    };

PriceModel _$PriceModelFromJson(Map<String, dynamic> json) => PriceModel(
      amount: PriceModel._toDouble(json['amount']),
      currency: json['currency'] as String,
      negotiable: json['negotiable'] as bool,
    );

Map<String, dynamic> _$PriceModelToJson(PriceModel instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'currency': instance.currency,
      'negotiable': instance.negotiable,
    };

StatsModel _$StatsModelFromJson(Map<String, dynamic> json) => StatsModel(
      views: (json['views'] as num?)?.toInt() ?? 0,
      uniqueViews: (json['uniqueViews'] as num?)?.toInt() ?? 0,
      chatInitiated: (json['chatInitiated'] as num?)?.toInt() ?? 0,
      saves: (json['saves'] as num?)?.toInt() ?? 0,
      shares: (json['shares'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$StatsModelToJson(StatsModel instance) =>
    <String, dynamic>{
      'views': instance.views,
      'uniqueViews': instance.uniqueViews,
      'chatInitiated': instance.chatInitiated,
      'saves': instance.saves,
      'shares': instance.shares,
    };

LocationModel _$LocationModelFromJson(Map<String, dynamic> json) =>
    LocationModel(
      city: json['city'] as String,
      state: json['state'] as String?,
      country: json['country'] as String,
      canShip: json['canShip'] as bool,
      pickupAvailable: json['pickupAvailable'] as bool,
      coordinates: json['coordinates'] == null
          ? null
          : CoordinatesModel.fromJson(
              json['coordinates'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LocationModelToJson(LocationModel instance) =>
    <String, dynamic>{
      'city': instance.city,
      'state': instance.state,
      'country': instance.country,
      'canShip': instance.canShip,
      'pickupAvailable': instance.pickupAvailable,
      'coordinates': instance.coordinates?.toJson(),
    };

CoordinatesModel _$CoordinatesModelFromJson(Map<String, dynamic> json) =>
    CoordinatesModel(
      latitude: CoordinatesModel._toDouble(json['latitude']),
      longitude: CoordinatesModel._toDouble(json['longitude']),
    );

Map<String, dynamic> _$CoordinatesModelToJson(CoordinatesModel instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

StockModel _$StockModelFromJson(Map<String, dynamic> json) => StockModel(
      available: json['available'] as bool,
      quantity: (json['quantity'] as num).toInt(),
    );

Map<String, dynamic> _$StockModelToJson(StockModel instance) =>
    <String, dynamic>{
      'available': instance.available,
      'quantity': instance.quantity,
    };

Map<String, dynamic> _$SellerModelToJson(SellerModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'role': instance.role,
      'avatar': instance.avatar,
      'rating': instance.rating,
      'reviewCount': instance.reviewCount,
    };
