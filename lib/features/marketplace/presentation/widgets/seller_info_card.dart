// lib/features/marketplace/presentation/widgets/seller_info_card.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Add this import
import '../../data/models/product_model.dart';

class SellerInfoCard extends StatelessWidget {
  final SellerModel seller;

  const SellerInfoCard({
    super.key,
    required this.seller,
  });

  @override
  Widget build(BuildContext context) {
    final String displayName = seller.name ?? 'Unknown Seller';

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seller Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  backgroundImage: (seller.avatar != null && seller.avatar!.isNotEmpty)
                      ? NetworkImage(seller.avatar!)
                      : null,
                  child: (seller.avatar == null || seller.avatar!.isEmpty)
                      ? Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (seller.rating != null && seller.rating! > 0)
                        Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              '${seller.rating!.toStringAsFixed(1)} (${seller.reviewCount ?? 0} reviews)',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        )
                      else
                        Text(
                          'New Seller',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                    ],
                  ),
                ),
                // UPDATED BUTTON
                OutlinedButton(
                  onPressed: () {
                    if (seller.id.isNotEmpty) {
                      // Navigate to the seller's public profile
                      context.push('/profile/${seller.id}');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Seller ID not found")),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('View Profile'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}