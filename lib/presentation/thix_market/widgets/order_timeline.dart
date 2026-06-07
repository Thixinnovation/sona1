import 'package:flutter/material.dart';
import '../../../models/order.dart';

class OrderTimeline extends StatelessWidget {
  final Order order;

  const OrderTimeline({super.key, required this.order});

  List<Map<String, dynamic>> _getTimelineSteps() {
    return [
      {'status': 'pending', 'title': 'Commande placée', 'icon': Icons.shopping_cart, 'date': order.date},
      {'status': 'confirmed', 'title': 'Confirmée', 'icon': Icons.check_circle, 'date': order.statusHistory.firstWhere((h) => h.status == 'confirmed', orElse: () => null)?.date},
      {'status': 'processing', 'title': 'En préparation', 'icon': Icons.build, 'date': order.statusHistory.firstWhere((h) => h.status == 'processing', orElse: () => null)?.date},
      {'status': 'shipped', 'title': 'Expédiée', 'icon': Icons.local_shipping, 'date': order.statusHistory.firstWhere((h) => h.status == 'shipped', orElse: () => null)?.date},
      {'status': 'delivered', 'title': 'Livrée', 'icon': Icons.home, 'date': order.statusHistory.firstWhere((h) => h.status == 'delivered', orElse: () => null)?.date},
    ];
  }

  int _getCurrentStep() {
    final statuses = ['pending', 'confirmed', 'processing', 'shipped', 'delivered'];
    return statuses.indexOf(order.status);
  }

  @override
  Widget build(BuildContext context) {
    final steps = _getTimelineSteps();
    final currentStep = _getCurrentStep();

    return Column(
      children: [
        Row(
          children: steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isCompleted = index <= currentStep;
            final isCurrent = index == currentStep;

            return Expanded(
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted ? const Color(0xFFD4AF37) : Colors.grey.shade200,
                    ),
                    child: Icon(step['icon'], color: isCompleted ? Colors.white : Colors.grey, size: 20),
                  ),
                  const SizedBox(height: 4),
                  if (index < steps.length - 1)
                    Container(
                      height: 2,
                      color: isCompleted ? const Color(0xFFD4AF37) : Colors.grey.shade200,
                    ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: steps.asMap().entries.map((entry) {
            final step = entry.value;
            return Expanded(
              child: Column(
                children: [
                  Text(step['title'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  if (step['date'] != null)
                    Text(
                      '${step['date'].day}/${step['date'].month}',
                      style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
