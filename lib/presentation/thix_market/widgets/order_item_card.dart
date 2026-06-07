import 'package:flutter/material.dart';
import '../../../models/order.dart';

class OrderItemCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;

  const OrderItemCard({super.key, required this.order, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: order.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(order.statusText, style: TextStyle(color: order.statusColor, fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(order.formattedDate, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
            const SizedBox(height: 8),
            Text('${order.items.length} article(s)', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(order.formattedTotal, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
