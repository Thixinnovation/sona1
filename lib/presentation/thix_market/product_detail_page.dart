import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/product.dart';
import '../../../services/cart_service.dart';
import '../../../services/wishlist_service.dart';
import 'widgets/quantity_selector.dart';
import 'widgets/rating_stars.dart';
import 'widgets/product_location.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _quantity = 1;
  late WishlistService _wishlistService;
  bool _isInWishlist = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _wishlistService = WishlistService(Supabase.instance.client);
    _userId = Supabase.instance.client.auth.currentUser?.id;
    _checkWishlist();
  }

  Future<void> _checkWishlist() async {
    if (_userId != null) {
      final inWishlist = await _wishlistService.isInWishlist(_userId!, widget.product.id);
      setState(() => _isInWishlist = inWishlist);
    }
  }

  Future<void> _toggleWishlist() async {
    if (_userId == null) return;
    if (_isInWishlist) {
      await _wishlistService.removeFromWishlist(_userId!, widget.product.id);
    } else {
      await _wishlistService.addToWishlist(_userId!, widget.product.id);
    }
    setState(() => _isInWishlist = !_isInWishlist);
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.product.title, style: const TextStyle(color: Colors.black)),
        actions: [
          IconButton(
            icon: Icon(_isInWishlist ? Icons.favorite : Icons.favorite_border, color: Colors.red),
            onPressed: _toggleWishlist,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Image.network(widget.product.imageUrl, height: 300, width: double.infinity, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(height: 300, color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported, size: 50))),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre et prix
                  Text(widget.product.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  RatingStars(rating: widget.product.rating, reviewsCount: widget.product.reviewsCount, size: 16),
                  const SizedBox(height: 12),
                  
                  // Prix
                  Row(
                    children: [
                      if (widget.product.oldPrice != null)
                        Text(widget.product.formattedOldPrice, style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(widget.product.formattedPrice, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Stock
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.product.inStock ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.product.inStock ? '✅ En stock (${widget.product.stock})' : '❌ Rupture de stock',
                      style: TextStyle(color: widget.product.inStock ? Colors.green : Colors.red, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Localisation
                  ProductLocation(city: widget.product.city, country: widget.product.country),
                  const SizedBox(height: 16),
                  
                  // Vendeur
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: widget.product.sellerAvatar.isNotEmpty
                              ? NetworkImage(widget.product.sellerAvatar)
                              : null,
                          child: widget.product.sellerAvatar.isEmpty
                              ? const Icon(Icons.store, size: 20)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.product.seller, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('Vendeur vérifié', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () => _startChat(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFD4AF37)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('Contacter', style: TextStyle(color: Color(0xFFD4AF37))),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(widget.product.description.isNotEmpty ? widget.product.description : 'Aucune description disponible.'),
                  const SizedBox(height: 16),
                  
                  // Quantité
                  if (widget.product.inStock) ...[
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Quantité', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        QuantitySelector(
                          quantity: _quantity,
                          onChanged: (q) => setState(() => _quantity = q),
                          max: widget.product.stock,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          cartService.addItem(widget.product, quantity: _quantity);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Ajouté au panier !'), backgroundColor: Colors.green),
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: const Color(0xFF0B1B3D),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text('AJOUTER AU PANIER', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startChat() {
    // Navigation vers la page de chat
    // context.push('/chat/seller/${widget.product.sellerId}?product=${widget.product.id}');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat avec le vendeur - Bientôt disponible'), backgroundColor: Colors.orange),
    );
  }
}
