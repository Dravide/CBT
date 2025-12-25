import 'package:flutter/material.dart';

class SkeletonLoading extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  
  const SkeletonLoading({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black, // Color doesn't matter as Shimmer overrides it
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
