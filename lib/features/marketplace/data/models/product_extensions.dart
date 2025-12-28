import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'product_model.dart';

extension ProductImageExtension on ProductModel {
  String get primaryImageFullUrl {
    if (images.isEmpty) return '';
    final path = images.firstWhere((img) => img.isPrimary, orElse: () => images[0]).url;
    final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    return '$baseUrl/${path.replaceFirst(RegExp(r'^/+'), '')}';
  }
}
