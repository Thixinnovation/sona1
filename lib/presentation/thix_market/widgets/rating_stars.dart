import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final int? reviewsCount;
  final double size;

  const RatingStars({super.key, required this.rating, this.reviewsCount, this.size = 12});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...List.generate(5, (index) {
          final starValue = index + 1;
          if (rating >= starValue) {
            return Icon(Icons.star, size: size, color: Colors.amber);
          } else if (rating >= starValue - 0.5) {
            return Icon(Icons.star_half, size: size, color: Colors.amber);
          } else {
            return Icon(Icons.star_border, size: size, color: Colors.amber);
          }
        }),
        if (reviewsCount != null) ...[
          const SizedBox(width: 4),
          Text('($reviewsCount)', style: TextStyle(fontSize: size - 2, color: Colors.grey.shade500)),
        ],
      ],
    );
  }
}
