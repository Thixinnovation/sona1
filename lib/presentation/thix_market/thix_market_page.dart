import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../services/market_service.dart';
import '../../../services/cart_service.dart';
import '../../../models/product.dart';
import 'product_detail_page.dart';
import 'widgets/products_grid.dart';
import 'widgets/rating_stars.dart';
import 'widgets/product_card.dart'; // ✅ AJOUT IMPORT

class ThixMarketPage extends StatefulWidget {
  const ThixMarketPage({super.key});

  @override
  State<ThixMarketPage> createState() => _ThixMarketPageState();
}

class _ThixMarketPageState extends State<ThixMarketPage> {
  late MarketService _marketService;
  List<Product> _flashSales = [];
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _loading = true;
  String _selectedCategory = 'Tous';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'Tous', 'Électronique', 'Mode & Fashion', 'Maison & Déco', 'Beauté & Santé', 'Sports & Loisirs'
  ];

  @override
  void initState() {
    super.initState();
    _marketService = MarketService(Supabase.instance.client);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final flash = await _marketService.getFlashSales();
      final all = await _marketService.getFeaturedProducts();
      setState(() {
        _flashSales = flash;
        _allProducts = all;
        _filteredProducts = all;
      });
    } catch (e) {
      _loadDemoData();
    } finally {
      setState(() => _loading = false);
    }
  }

  void _loadDemoData() {
    _flashSales = [
      Product(
        id: '1', title: 'Écouteurs sans fil Premium Pro', description: '', price: 32900, oldPrice: 47000,
        category: 'Électronique', imageUrl: 'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=300&h=300&fit=crop',
        rating: 4.8, reviewsCount: 124, seller: 'THIX Store', inStock: true, isFlashSale: true, flashDiscount: 30,
      ),
      Product(
        id: '2', title: 'Montre Connectée THIX Watch 5', description: '', price: 75000, oldPrice: 100000,
        category: 'Électronique', imageUrl: 'https://images.unsplash.com/photo-1546868871-7041f2a55e12?w=300&h=300&fit=crop',
        rating: 4.9, reviewsCount: 89, seller: 'THIX Tech', inStock: true, isFlashSale: true, flashDiscount: 25,
      ),
      Product(
        id: '3', title: 'Sneakers Air N Édition Limitée', description: '', price: 56000, oldPrice: 70000,
        category: 'Mode & Fashion', imageUrl: 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=300&h=300&fit=crop',
        rating: 4.7, reviewsCount: 63, seller: 'THIX Fashion', inStock: true, isFlashSale: true, flashDiscount: 20,
      ),
    ];
    _allProducts = [..._flashSales,
      Product(id: '4', title: 'iPhone 15 Pro', description: '', price: 1250000, oldPrice: null, category: 'Électronique', imageUrl: 'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=300&h=300&fit=crop', rating: 4.9, reviewsCount: 450, seller: 'Apple Store', inStock: true),
      Product(id: '5', title: 'Casque Audio Bluetooth', description: '', price: 45000, oldPrice: 65000, category: 'Électronique', imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=300&h=300&fit=crop', rating: 4.6, reviewsCount: 230, seller: 'Sony', inStock: true),
    ];
    _filteredProducts = _allProducts;
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == 'Tous') {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts = _allProducts.where((p) => p.category == category).toList();
      }
    });
  }

  void _searchProducts(String query) {
    if (query.isEmpty) {
      _filterByCategory(_selectedCategory);
      return;
    }
    setState(() {
      _filteredProducts = _allProducts.where((p) =>
        p.title.toLowerCase().contains(query.toLowerCase()) ||
        p.category.toLowerCase().contains(query.toLowerCase())
      ).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1B3D),
        elevation: 0,
        title: const Text('THIX MARKET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                onPressed: () => context.push('/market/cart'),
              ),
              if (cartService.itemCount > 0)
                Positioned(
                  right: 4, top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text('${cartService.itemCount}', textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildFeatures(),
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 20),
              _buildCategories(),
              const SizedBox(height: 20),
              if (_flashSales.isNotEmpty) _buildFlashSales(),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_selectedCategory == 'Tous' ? 'Tous les produits' : 'Produits - $_selectedCategory',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ProductsGrid(
                      products: _filteredProducts,
                      onProductTap: (product) => _showProductDetail(context, product),
                      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                    ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0B1B3D), Color(0xFF1A2D56)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('Bonjour, Michel 🎉', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Votre marketplace premium et sécurisée', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: const Color(0xFF0B1B3D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Explorer le marché', fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatures() {
    final features = [
      ('🔒', 'Paiement sécurisé'), ('✅', 'Vendeurs vérifiés'),
      ('🚚', 'Livraison fiable'), ('💬', 'Support 24/7'),
    ];
    return Row(
      children: features.map((f) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              Text(f.$1, style: const TextStyle(fontSize: 20)),
              Text(f.$2, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: _searchProducts,
      decoration: InputDecoration(
        hintText: 'Rechercher un produit, une marque...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); _searchProducts(''); })
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
        filled: true, fillColor: Colors.white,
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cat),
              selected: _selectedCategory == cat,
              onSelected: (_) => _filterByCategory(cat),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFFD4AF37),
              labelStyle: TextStyle(color: _selectedCategory == cat ? const Color(0xFF0B1B3D) : Colors.grey.shade700),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFlashSales() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('⚡ Offres flash', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(onPressed: () {}, child: const Text('Voir tout >')),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _flashSales.length,
            itemBuilder: (context, index) => SizedBox(
              width: 150,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ProductCard( // ✅ UTILISATION CORRECTE
                  product: _flashSales[index],
                  onTap: () => _showProductDetail(context, _flashSales[index]),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_outlined, 'Accueil', true, () => context.go('/')),
          _navItem(Icons.category_outlined, 'Catégories', false, () => _filterByCategory('Tous')),
          _navItem(Icons.shopping_bag_outlined, 'Commandes', false, () => context.push('/market/orders')),
          _navItem(Icons.person_outline, 'Profil', false, () => context.go('/user-dashboard')),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: active ? const Color(0xFFD4AF37) : Colors.grey, size: 22),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: active ? const Color(0xFFD4AF37) : Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  void _showProductDetail(BuildContext context, Product product) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)));
  }
}
