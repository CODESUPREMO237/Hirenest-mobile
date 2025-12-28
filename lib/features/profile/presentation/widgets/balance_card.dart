// Balance Card
// =====================================================
// PROFILE WIDGETS
// lib/features/profile/presentation/widgets/balance_card.dart
// =====================================================
import 'package:flutter/material.dart';

class BalanceCard extends StatelessWidget {
  final double available;
  final double pending;
  final VoidCallback? onWithdraw;

  const BalanceCard({
    super.key,
    required this.available,
    required this.pending,
    this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Balance',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'XAF$available',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pending', style: TextStyle(color: Colors.grey)),
                    Text('XAF$pending', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                if (onWithdraw != null && available > 0)
                  ElevatedButton.icon(
                    onPressed: onWithdraw,
                    icon: const Icon(Icons.account_balance_wallet),
                    label: const Text('Withdraw'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}