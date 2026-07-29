// Order Model
// ============================================================================
// order_model.dart
// lib/features/marketplace/data/models/order_model.dart
// ============================================================================

class OrderModel {
  final String id;
  final String orderNumber;
  final String productId;
  final String buyerId;
  final String sellerId;
  final PricingModel pricing;
  final PaymentModel payment;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Populated fields
  final OrderProductModel? product;
  final OrderUserModel? buyer;
  final OrderUserModel? seller;

  double get amount => pricing.productPrice;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.productId,
    required this.buyerId,
    required this.sellerId,
    required this.pricing,
    required this.payment,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.product,
    this.buyer,
    this.seller,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['_id'] ?? json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      productId: json['product'] == null
          ? ''
          : json['product'] is String
              ? json['product']
              : (json['product']['_id'] ?? ''),
      buyerId: json['buyer'] == null
          ? ''
          : json['buyer'] is String
              ? json['buyer']
              : (json['buyer']['_id'] ?? ''),
      sellerId: json['seller'] == null
          ? ''
          : json['seller'] is String
              ? json['seller']
              : (json['seller']['_id'] ?? ''),
      pricing: json['pricing'] != null
          ? PricingModel.fromJson(json['pricing'])
          : PricingModel(productPrice: 0, commission: 0, sellerAmount: 0, currency: 'XAF'),
      payment: PaymentModel.fromJson(json['payment']),
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt']) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (DateTime.tryParse(json['updatedAt']) ?? DateTime.now())
          : DateTime.now(),
      product: json['product'] is Map<String, dynamic>
          ? OrderProductModel.fromJson(json['product'])
          : null,
      buyer: json['buyer'] is Map<String, dynamic>
          ? OrderUserModel.fromJson(json['buyer'])
          : null,
      seller: json['seller'] is Map<String, dynamic>
          ? OrderUserModel.fromJson(json['seller'])
          : null,
    );
  }
}

class PricingModel {
  final double productPrice;
  final double commission;
  final double sellerAmount;
  final String currency;

  PricingModel({
    required this.productPrice,
    required this.commission,
    required this.sellerAmount,
    required this.currency,
  });

  factory PricingModel.fromJson(Map<String, dynamic> json) {
    return PricingModel(
      productPrice: (json['productPrice'] ?? 0).toDouble(),
      commission: (json['commission'] ?? 0).toDouble(),
      sellerAmount: (json['sellerAmount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'XAF',
    );
  }
}

class PaymentModel {
  final String? method;
  final String paymentStatus;
  final DateTime? paidAt;
  final String? transactionId;

  PaymentModel({
    this.method,
    required this.paymentStatus,
    this.paidAt,
    this.transactionId,
  });

  factory PaymentModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return PaymentModel(paymentStatus: 'PENDING');
    }
    return PaymentModel(
      method: json['method'],
      paymentStatus: json['paymentStatus'] ?? 'PENDING',
      paidAt: json['paidAt'] != null ? DateTime.tryParse(json['paidAt']) : null,
      transactionId: json['transactionId'],
    );
  }
}

class OrderProductModel {
  final String id;
  final String name;
  final PricingModel? price;
  final List<ProductImageModel>? images;

  OrderProductModel({
    required this.id,
    required this.name,
    this.price,
    this.images,
  });

  factory OrderProductModel.fromJson(Map<String, dynamic> json) {
    return OrderProductModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      price: json['price'] != null ? PricingModel.fromJson(json['price']) : null,
      images: json['images'] != null
          ? (json['images'] as List).map((i) => ProductImageModel.fromJson(i)).toList()
          : null,
    );
  }
}

class ProductImageModel {
  final String url;
  ProductImageModel({required this.url});
  factory ProductImageModel.fromJson(Map<String, dynamic> json) {
    return ProductImageModel(url: json['url'] ?? '');
  }
}

class OrderUserModel {
  final String id;
  final String? username;
  final String? email;
  final String? avatar;
  final String? name;

  OrderUserModel({
    required this.id,
    this.username,
    this.email,
    this.avatar,
    this.name,
  });

  factory OrderUserModel.fromJson(Map<String, dynamic> json) {
    String? fullName;
    if (json['profile'] != null) {
      fullName = json['profile']['fullName'];
      if (fullName == null || fullName.isEmpty) {
        final f = json['profile']['firstName'] ?? '';
        final l = json['profile']['lastName'] ?? '';
        fullName = '$f $l'.trim();
      }
    }
    if (fullName == null || fullName.isEmpty) fullName = json['username'];

    return OrderUserModel(
      id: json['_id'] ?? json['id'] ?? '',
      username: json['username'],
      email: json['email'],
      avatar: json['avatar'],
      name: fullName,
    );
  }
}