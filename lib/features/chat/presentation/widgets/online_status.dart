import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

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
        color: isOnline ? AppColors.success : AppColors.textMutedLight,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surfaceLight, width: 2),
      ),
    );
  }
}