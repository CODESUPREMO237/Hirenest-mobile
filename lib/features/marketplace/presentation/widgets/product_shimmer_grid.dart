import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ProductShimmerGrid extends StatelessWidget {
  const ProductShimmerGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 450,
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: .75,
        children: List.generate(
          6,
              (_) => Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
