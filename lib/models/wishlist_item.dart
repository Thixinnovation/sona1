class WishlistItem {
  final String id;
  final String productId;
  final String userId;
  final DateTime addedAt;

  WishlistItem({
    required this.id,
    required this.productId,
    required this.userId,
    required this.addedAt,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) => WishlistItem(
    id: json['id'].toString(),
    productId: json['product_id'],
    userId: json['user_id'],
    addedAt: DateTime.parse(json['created_at']),
  );
}
