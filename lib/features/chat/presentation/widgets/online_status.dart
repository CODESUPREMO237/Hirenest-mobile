// Online Status

// =====================================================
// lib/features/chat/presentation/widgets/online_status.dart
// =====================================================
import 'package:flutter/material.dart';

class OnlineStatus extends StatelessWidget {
  final bool isOnline;
  final double size;

  const OnlineStatus({
    super.key,
    required this.isOnline,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isOnline ? Colors.green : Colors.grey,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}