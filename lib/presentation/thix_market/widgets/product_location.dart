import 'package:flutter/material.dart';

class ProductLocation extends StatelessWidget {
  final String city;
  final String country;
  final double distance;

  const ProductLocation({
    super.key,
    required this.city,
    required this.country,
    this.distance = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            city == 'En ligne' ? '📦 Livraison partout' : '$city, $country',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
          if (distance > 0) ...[
            const SizedBox(width: 4),
            Text('• ${distance.toStringAsFixed(0)} km', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          ],
        ],
      ),
    );
  }
}
