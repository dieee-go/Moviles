import 'package:flutter/material.dart';

/// Reusable skeleton helpers to replace spinners during loading.
class Skeletons {
  static Widget box({double width = double.infinity, double height = 14, double radius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  static Widget circle({double size = 48}) => box(width: size, height: size, radius: size / 2);

  static Widget chips({int count = 6, double width = 90, double height = 34}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(
        count,
        (_) => box(width: width, height: height, radius: height / 2),
      ),
    );
  }

  static Widget listTiles({int count = 4, double leadingSize = 56, EdgeInsetsGeometry padding = EdgeInsets.zero}) {
    return Padding(
      padding: padding,
      child: Column(
        children: List.generate(
          count,
          (i) => Padding(
            padding: EdgeInsets.only(bottom: i == count - 1 ? 0 : 12),
            child: Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: box(width: leadingSize, height: leadingSize),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          box(width: 180, height: 14, radius: 6),
                          const SizedBox(height: 8),
                          box(width: 140, height: 12, radius: 6),
                          const SizedBox(height: 6),
                          box(width: 120, height: 12, radius: 6),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    circle(size: 26),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget heroCard({double height = 200}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: box(height: height),
            ),
            const SizedBox(height: 14),
            box(width: 200, height: 16, radius: 8),
            const SizedBox(height: 10),
            box(width: 160, height: 14, radius: 8),
            const SizedBox(height: 12),
            box(height: 38, radius: 10),
          ],
        ),
      ),
    );
  }

  static Widget form({int fields = 5, double fieldHeight = 50, double spacing = 14}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(fields, (i) {
        return Padding(
          padding: EdgeInsets.only(bottom: i == fields - 1 ? 0 : spacing),
          child: box(height: fieldHeight, radius: 10),
        );
      }),
    );
  }

  static Widget kpiGrid({int items = 4}) {
    return Column(
      children: List.generate(items, (i) {
        return Padding(
          padding: EdgeInsets.only(bottom: i == items - 1 ? 0 : 12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  circle(size: 42),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      box(width: 120, height: 14, radius: 6),
                      const SizedBox(height: 8),
                      box(width: 80, height: 18, radius: 6),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
