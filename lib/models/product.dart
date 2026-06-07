class Product {
  final String id;
  final String title;
  final String description;
  final double price;
  final double? oldPrice;
  final String category;
  final String imageUrl;
  final double rating;
  final int reviewsCount;
  final String seller;
  final String sellerId;
  final String sellerAvatar;
  final int stock;
  final String city;
  final String country;
  final bool inStock;
  final bool isFlashSale;
  final int? flashDiscount;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.oldPrice,
    required this.category,
    required this.imageUrl,
    required this.rating,
    required this.reviewsCount,
    required this.seller,
    required this.sellerId,
    required this.sellerAvatar,
    required this.stock,
    required this.city,
    required this.country,
    required this.inStock,
    this.isFlashSale = false,
    this.flashDiscount,
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'].toString(),
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    price: (json['price'] as num).toDouble(),
    oldPrice: (json['old_price'] as num?)?.toDouble(),
    category: json['category'] as String,
    imageUrl: json['image_url'] as String? ?? '',
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    reviewsCount: json['reviews_count'] as int? ?? 0,
    seller: json['seller'] as String,
    sellerId: json['seller_id'] as String? ?? '',
    sellerAvatar: json['seller_avatar'] as String? ?? '',
    stock: json['stock'] as int? ?? 0,
    city: json['city'] as String? ?? 'En ligne',
    country: json['country'] as String? ?? 'Sénégal',
    inStock: (json['stock'] as int? ?? 0) > 0,
    isFlashSale: json['is_flash_sale'] as bool? ?? false,
    flashDiscount: json['flash_discount'] as int?,
    createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
  );

  String get formattedPrice => '${price.toStringAsFixed(0)} FCFA';
  String get formattedOldPrice => oldPrice != null ? '${oldPrice!.toStringAsFixed(0)} FCFA' : '';
  double get discountPercent => oldPrice != null ? ((oldPrice! - price) / oldPrice! * 100).roundToDouble() : 0;
  String get location => city == 'En ligne' ? '📦 Livraison partout' : '📍 $city, $country';
}
