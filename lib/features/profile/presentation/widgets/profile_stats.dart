// Profile Stats
// =====================================================
// lib/features/profile/presentation/widgets/profile_stats.dart
// =====================================================
import 'package:flutter/material.dart';

class ProfileStats extends StatelessWidget {
  final int productsPosted;
  final int activeProducts;
  final int totalViews;
  final double rating;

  const ProfileStats({
    super.key,
    required this.productsPosted,
    required this.activeProducts,
    required this.totalViews,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStat('Products', productsPosted.toString(), Icons.shopping_bag),
            _buildStat('Active', activeProducts.toString(), Icons.check_circle),
            _buildStat('Views', totalViews.toString(), Icons.visibility),
            _buildStat('Rating', rating.toStringAsFixed(1), Icons.star),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
