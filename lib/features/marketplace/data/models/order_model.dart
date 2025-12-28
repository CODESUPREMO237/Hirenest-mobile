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
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['_id'] ?? json['id'],
      orderNumber: json['orderNumber'],
      productId: json['product'] is String
          ? json['product']
          : json['product']['_id'],
      buyerId: json['buyer'] is String ? json['buyer'] : json['buyer']['_id'],
      sellerId: json['seller'] is String
          ? json['seller']
          : json['seller']['_id'],
      pricing: PricingModel.fromJson(json['pricing']),
      payment: PaymentModel.fromJson(json['payment']),
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
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
      productPrice: json['productPrice'].toDouble(),
      commission: json['commission'].toDouble(),
      sellerAmount: json['sellerAmount'].toDouble(),
      currency: json['currency'],
    );
  }
}

class PaymentModel {
  final String method;
  final String paymentStatus;
  final DateTime? paidAt;
  final String? transactionId;

  PaymentModel({
    required this.method,
    required this.paymentStatus,
    this.paidAt,
    this.transactionId,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      method: json['method'],
      paymentStatus: json['paymentStatus'],
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      transactionId: json['transactionId'],
    );
  }
}