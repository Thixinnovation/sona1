import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import '../models/cart_item.dart';

class OrderService {
  final SupabaseClient _supabase;

  OrderService(this._supabase);

  Future<Order> createOrder(String userId, List<CartItem> cartItems, double total, String address) async {
    final orderNumber = 'THIX-${DateTime.now().millisecondsSinceEpoch}';
    final orderId = DateTime.now().millisecondsSinceEpoch.toString();
    
    final orderData = {
      'id': orderId,
      'order_number': orderNumber,
      'user_id': userId,
      'total': total,
      'status': 'pending',
      'shipping_address': address,
      'items': cartItems.map((item) => {
        'product_id': item.productId,
        'title': item.title,
        'image_url': item.imageUrl,
        'price': item.price,
        'quantity': item.quantity,
      }).toList(),
      'created_at': DateTime.now().toIso8601String(),
    };
    
    await _supabase.from('market_orders').insert(orderData);
    
    return Order(
      id: orderId,
      orderNumber: orderNumber,
      date: DateTime.now(),
      total: total,
      status: 'pending',
      items: cartItems.map((item) => OrderItem(
        productId: item.productId,
        title: item.title,
        imageUrl: item.imageUrl,
        price: item.price,
        quantity: item.quantity,
      )).toList(),
    );
  }

  Future<List<Order>> getUserOrders(String userId) async {
    final response = await _supabase
        .from('market_orders')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    
    return (response as List).map((e) => Order(
      id: e['id'],
      orderNumber: e['order_number'],
      date: DateTime.parse(e['created_at']),
      total: (e['total'] as num).toDouble(),
      status: e['status'],
      items: (e['items'] as List).map((item) => OrderItem(
        productId: item['product_id'],
        title: item['title'],
        imageUrl: item['image_url'],
        price: (item['price'] as num).toDouble(),
        quantity: item['quantity'],
      )).toList(),
      trackingNumber: e['tracking_number'],
    )).toList();
  }
}
