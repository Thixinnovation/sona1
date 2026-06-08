import 'package:flutter/material.dart';
import '../../../models/order.dart';

class OrderTimeline extends StatelessWidget {
  final Order order;

  const OrderTimeline({super.key, required this.order});

  List<Map<String, dynamic>> _getTimelineSteps() {
    // Fonction helper pour récupérer la date
    DateTime? _getDate(String status) {
      try {
        final found = order.statusHistory.firstWhere((h) => h.status == status);
        return found.date;
      } catch (e) {
        return null;
      }
    }

    return [
      {'status': 'pending', 'title': 'Commande placée', 'icon': Icons.shopping_cart, 'date': order.date},
      {'status': 'confirmed', 'title': 'Confirmée', 'icon': Icons.check_circle, 'date': _getDate('confirmed')},
      {'status': 'processing', 'title': 'En préparation', 'icon': Icons.build, 'date': _getDate('processing')},
      {'status': 'shipped', 'title': 'Expédiée', 'icon': Icons.local_shipping, 'date': _getDate('shipped')},
      {'status': 'delivered', 'title': 'Livrée', 'icon': Icons.home, 'date': _getDate('delivered')},
    ];
  }

  int _getCurrentStep() {
    final statuses = ['pending', 'confirmed', 'processing', 'shipped', 'delivered'];
    final index = statuses.indexOf(order.status);
    return index == -1 ? 0 : index;
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
                    child: Icon(step['icon'] as IconData, color: isCompleted ? Colors.white : Colors.grey, size: 20),
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
          children: steps.map((step) {
            return Expanded(
              child: Column(
                children: [
                  Text(step['title'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                  const SizedBox(height: 2),
                  if (step['date'] != null)
                    Text(
                      '${(step['date'] as DateTime).day}/${(step['date'] as DateTime).month}',
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
