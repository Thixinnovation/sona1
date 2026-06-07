class Order {
  final String id;
  final String orderNumber;
  final DateTime date;
  final double total;
  final String status;
  final List<OrderItem> items;
  final String? trackingNumber;

  Order({
    required this.id,
    required this.orderNumber,
    required this.date,
    required this.total,
    required this.status,
    required this.items,
    this.trackingNumber,
  });

  String get formattedTotal => '${total.toStringAsFixed(0)} FCFA';
  String get formattedDate => '${date.day}/${date.month}/${date.year}';

  String get statusText {
    switch (status) {
      case 'pending': return 'En attente';
      case 'confirmed': return 'Confirmée';
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
      case 'shipped': return Colors.purple;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
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
