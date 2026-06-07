import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartService extends ChangeNotifier {
  List<CartItem> _items = [];
  
  List<CartItem> get items => _items;
  int get itemCount => _items.length;
  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);
  
  double get totalPrice => _items.fold(0, (sum, item) => sum + item.totalPrice);
  String get formattedTotal => '${totalPrice.toStringAsFixed(0)} FCFA';

  CartService() {
    _loadCart();
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString('market_cart');
    if (cartJson != null) {
      final List<dynamic> decoded = jsonDecode(cartJson);
      _items = decoded.map((e) => CartItem(
        id: e['id'],
        productId: e['productId'],
        title: e['title'],
        imageUrl: e['imageUrl'],
        price: e['price'],
        quantity: e['quantity'],
        oldPrice: e['oldPrice'],
      )).toList();
      notifyListeners();
    }
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = jsonEncode(_items.map((e) => {
      'id': e.id,
      'productId': e.productId,
      'title': e.title,
      'imageUrl': e.imageUrl,
      'price': e.price,
      'quantity': e.quantity,
      'oldPrice': e.oldPrice,
    }).toList());
    await prefs.setString('market_cart', cartJson);
  }

  void addItem(Product product, {int quantity = 1}) {
    final existingIndex = _items.indexWhere((item) => item.productId == product.id);
    
    if (existingIndex != -1) {
      _items[existingIndex] = _items[existingIndex].copyWith(
        quantity: _items[existingIndex].quantity + quantity,
      );
    } else {
      _items.add(CartItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        productId: product.id,
        title: product.title,
        imageUrl: product.imageUrl,
        price: product.price,
        quantity: quantity,
        oldPrice: product.oldPrice,
      ));
    }
    _saveCart();
    notifyListeners();
  }

  void updateQuantity(String id, int newQuantity) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      if (newQuantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index] = _items[index].copyWith(quantity: newQuantity);
      }
      _saveCart();
      notifyListeners();
    }
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    _saveCart();
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _saveCart();
    notifyListeners();
  }
}
