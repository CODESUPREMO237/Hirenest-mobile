// Cached Image
// ============================================================================
// cached_image.dart
// lib/core/widgets/cached_image.dart
// ============================================================================

import 'package:flutter/material.dart';
import '../../../../../../../../core/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomCachedImage extends StatelessWidget {
final String imageUrl;
final double? width;
final double? height;
final BoxFit fit;
final BorderRadius? borderRadius;

const CustomCachedImage({
super.key,
required this.imageUrl,
this.width,
this.height,
this.fit = BoxFit.cover,
this.borderRadius,
});

@override
Widget build(BuildContext context) {
Widget image = CachedNetworkImage(
imageUrl: imageUrl,
width: width,
height: height,
fit: fit,
placeholder: (context, url) => Container(
width: width,
height: height,
color: AppColors.grey200,
child: const Center(
child: CircularProgressIndicator(),
),
),
errorWidget: (context, url, error) => Container(
width: width,
height: height,
color: AppColors.grey200,
child: Icon(
Icons.image_not_supported,
color: AppColors.grey400,
size: 40,
),
),
);

if (borderRadius != null) {
return ClipRRect(
borderRadius: borderRadius!,
child: image,
);
}

return image;
}
}
