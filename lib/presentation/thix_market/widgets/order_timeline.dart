import 'package:flutter/material.dart';
import '../../../models/order.dart';

class OrderTimeline extends StatelessWidget {
  final Order order;

  const OrderTimeline({super.key, required this.order});

  List<Map<String, dynamic>> _getTimelineSteps() {
    // Helper pour récupérer la date d'un statut
    DateTime? _getDateForStatus(String status) {
      final found = order.statusHistory.firstWhere(
        (h) => h.status == status,
        orElse: () => null,
      );
      return found?.date;
    }

    return [
      {'status': 'pending', 'title': 'Commande placée', 'icon': Icons.shopping_cart, 'date': order.date},
      {'status': 'confirmed', 'title': 'Confirmée', 'icon': Icons.check_circle, 'date': _getDateForStatus('confirmed')},
      {'status': 'processing', 'title': 'En préparation', 'icon': Icons.build, 'date': _getDateForStatus('processing')},
      {'status': 'shipped', 'title': 'Expédiée', 'icon': Icons.local_shipping, 'date': _getDateForStatus('shipped')},
      {'status': 'delivered', 'title': 'Livrée', 'icon': Icons.home, 'date': _getDateForStatus('delivered')},
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
        // Timeline des étapes
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
                      border: isCurrent
                          ? Border.all(color: const Color(0xFFD4AF37), width: 2)
                          : null,
                    ),
                    child: Icon(
                      step['icon'] as IconData,
                      color: isCompleted ? Colors.white : Colors.grey,
                      size: 20,
                    ),
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
        // Labels des étapes
        Row(
          children: steps.map((step) {
            return Expanded(
              child: Column(
                children: [
                  Text(
                    step['title'] as String,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  if (step['date'] != null)
                    Text(
                      _formatDate(step['date'] as DateTime),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }
}
