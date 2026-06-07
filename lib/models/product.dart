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
  final bool inStock;
  final bool isFlashSale;
  final int? flashDiscount;

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
    required this.inStock,
    this.isFlashSale = false,
    this.flashDiscount,
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
    inStock: json['in_stock'] as bool? ?? true,
    isFlashSale: json['is_flash_sale'] as bool? ?? false,
    flashDiscount: json['flash_discount'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'price': price,
    'old_price': oldPrice,
    'category': category,
    'image_url': imageUrl,
    'rating': rating,
    'reviews_count': reviewsCount,
    'seller': seller,
    'in_stock': inStock,
    'is_flash_sale': isFlashSale,
    'flash_discount': flashDiscount,
  };

  String get formattedPrice => '${price.toStringAsFixed(0)} FCFA';
  String get formattedOldPrice => oldPrice != null ? '${oldPrice!.toStringAsFixed(0)} FCFA' : '';
  double get discountPercent => oldPrice != null ? ((oldPrice! - price) / oldPrice! * 100).roundToDouble() : 0;
}
