import 'package:flutter/material.dart';

class Order {
  final String id;
  final String orderNumber;
  final DateTime date;
  final double total;
  final String status;
  final List<OrderItem> items;
  final String? trackingNumber;
  final String? shippingAddress;
  final String? estimatedDelivery;
  final List<OrderStatusHistory> statusHistory;

  Order({
    required this.id,
    required this.orderNumber,
    required this.date,
    required this.total,
    required this.status,
    required this.items,
    this.trackingNumber,
    this.shippingAddress,
    this.estimatedDelivery,
    this.statusHistory = const [],
  });

  String get formattedTotal => '${total.toStringAsFixed(0)} FCFA';
  String get formattedDate => '${date.day}/${date.month}/${date.year}';

  String get statusText {
    switch (status) {
      case 'pending': return 'En attente';
      case 'confirmed': return 'Confirmée';
      case 'processing': return 'En préparation';
      case 'shipped': return 'Expédiée';
      case 'delivered': return 'Livrée';
      case 'cancelled': return 'Annulée';
      default: return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'processing': return Colors.purple;
      case 'shipped': return Colors.cyan;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'pending': return Icons.pending;
      case 'confirmed': return Icons.check_circle;
      case 'processing': return Icons.build;
      case 'shipped': return Icons.local_shipping;
      case 'delivered': return Icons.home;
      case 'cancelled': return Icons.cancel;
      default: return Icons.help;
    }
  }
}

class OrderItem {
  final String productId;
  final String title;
  final String imageUrl;
  final double price;
  final int quantity;

  OrderItem({
    required this.productId,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.quantity,
  });

  double get total => price * quantity;
}

class OrderStatusHistory {
  final String status;
  final DateTime date;
  final String? message;

  OrderStatusHistory({
    required this.status,
    required this.date,
    this.message,
  });

  String get statusText {
    switch (status) {
      case 'pending': return 'Commande placée';
      case 'confirmed': return 'Commande confirmée';
      case 'processing': return 'En préparation';
      case 'shipped': return 'Expédiée';
      case 'delivered': return 'Livrée';
      default: return status;
    }
  }
}
