class CartItem {
  final String id;
  final String productId;
  final String title;
  final String imageUrl;
  final double price;
  final int quantity;
  final double? oldPrice;

  CartItem({
    required this.id,
    required this.productId,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    this.oldPrice,
  });

  double get totalPrice => price * quantity;
  String get formattedTotal => '${totalPrice.toStringAsFixed(0)} FCFA';

  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      productId: productId,
      title: title,
      imageUrl: imageUrl,
      price: price,
      quantity: quantity ?? this.quantity,
      oldPrice: oldPrice,
    );
  }
}
