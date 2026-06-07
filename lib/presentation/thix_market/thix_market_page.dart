import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../services/market_service.dart';
import '../../../services/cart_service.dart';
import '../../../models/product.dart';
import 'product_detail_page.dart';
import 'widgets/products_grid.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'widgets/product_card.dart';
import 'widgets/filter_sheet.dart';

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

  // Filtres avancés
  String _sortBy = 'newest';
  RangeValues _priceRange = const RangeValues(0, 10000000);
  double _minRating = 0;
  String _selectedCity = 'Toutes';

  final List<String> _categories = [
    'Tous', 'Électronique', 'Mode & Fashion', 'Maison & Déco', 'Beauté & Santé', 'Sports & Loisirs'
  ];

  final List<String> _cities = [
    'Toutes', 'Kinshasa', 'Lubumbashi', 'Mbuji-Mayi', 'Kisangani', 'Bukavu', 'Goma', 'Kananga'
  ];

  @override
  void initState() {
    super.initState();
    _marketService = MarketService(Supabase.instance.client);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      debugPrint('Error loading market data: $e');
      _loadDemoData();
    } finally {
      setState(() => _loading = false);
    }
  }

  void _loadDemoData() {
    _flashSales = [
      Product(
        id: '1', title: 'Écouteurs sans fil Premium Pro', description: 'Qualité sonore exceptionnelle', 
        price: 199500, oldPrice: 285000,
        category: 'Électronique', imageUrl: 'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=300&h=300&fit=crop',
        rating: 4.8, reviewsCount: 124, seller: 'THIX Store', sellerId: '', sellerAvatar: '',
        stock: 15, city: 'Kinshasa', country: 'RDC', inStock: true, isFlashSale: true, flashDiscount: 30,
        createdAt: DateTime.now(),
      ),
      Product(
        id: '2', title: 'Montre Connectée THIX Watch 5', description: 'Suivi sportif et santé', 
        price: 455000, oldPrice: 605000,
        category: 'Électronique', imageUrl: 'https://images.unsplash.com/photo-1546868871-7041f2a55e12?w=300&h=300&fit=crop',
        rating: 4.9, reviewsCount: 89, seller: 'THIX Tech', sellerId: '', sellerAvatar: '',
        stock: 8, city: 'Lubumbashi', country: 'RDC', inStock: true, isFlashSale: true, flashDiscount: 25,
        createdAt: DateTime.now(),
      ),
      Product(
        id: '3', title: 'Sneakers Air N Édition Limitée', description: 'Confort et style', 
        price: 340000, oldPrice: 425000,
        category: 'Mode & Fashion', imageUrl: 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=300&h=300&fit=crop',
        rating: 4.7, reviewsCount: 63, seller: 'THIX Fashion', sellerId: '', sellerAvatar: '',
        stock: 12, city: 'Kinshasa', country: 'RDC', inStock: true, isFlashSale: true, flashDiscount: 20,
        createdAt: DateTime.now(),
      ),
    ];
    _allProducts = [
      ..._flashSales,
      Product(id: '4', title: 'iPhone 15 Pro', description: 'Le dernier smartphone Apple', price: 2500000, oldPrice: null, 
        category: 'Électronique', imageUrl: 'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=300&h=300&fit=crop', 
        rating: 4.9, reviewsCount: 450, seller: 'Apple Store', sellerId: '', sellerAvatar: '',
        stock: 5, city: 'Kinshasa', country: 'RDC', inStock: true, createdAt: DateTime.now()),
      Product(id: '5', title: 'Casque Audio Bluetooth', description: 'Son haute fidélité', price: 275000, oldPrice: 395000, 
        category: 'Électronique', imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=300&h=300&fit=crop', 
        rating: 4.6, reviewsCount: 230, seller: 'Sony', sellerId: '', sellerAvatar: '',
        stock: 20, city: 'Goma', country: 'RDC', inStock: true, createdAt: DateTime.now()),
      Product(id: '6', title: 'Sac à main Cuir', description: 'Collection luxe', price: 540000, oldPrice: 725000, 
        category: 'Mode & Fashion', imageUrl: 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=300&h=300&fit=crop', 
        rating: 4.8, reviewsCount: 178, seller: 'Luxury Bags', sellerId: '', sellerAvatar: '',
        stock: 7, city: 'Bukavu', country: 'RDC', inStock: true, createdAt: DateTime.now()),
      Product(id: '7', title: 'Smart TV 55" 4K', description: 'Qualité image exceptionnelle', price: 1250000, oldPrice: 1650000, 
        category: 'Électronique', imageUrl: 'https://images.unsplash.com/photo-1593359677879-a4bb92f829d1?w=300&h=300&fit=crop', 
        rating: 4.7, reviewsCount: 312, seller: 'Samsung', sellerId: '', sellerAvatar: '',
        stock: 3, city: 'Lubumbashi', country: 'RDC', inStock: true, createdAt: DateTime.now()),
    ];
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    setState(() {
      var filtered = _allProducts.where((p) {
        // Filtre catégorie
        if (_selectedCategory != 'Tous' && p.category != _selectedCategory) return false;
        
        // Filtre prix
        if (p.price < _priceRange.start || p.price > _priceRange.end) return false;
        
        // Filtre note
        if (p.rating < _minRating) return false;
        
        // Filtre ville
        if (_selectedCity != 'Toutes' && p.city != _selectedCity) return false;
        
        return true;
      }).toList();
      
      // Tri
      switch (_sortBy) {
        case 'price_asc':
          filtered.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'price_desc':
          filtered.sort((a, b) => b.price.compareTo(a.price));
          break;
        case 'rating':
          filtered.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'popularity':
          filtered.sort((a, b) => b.reviewsCount.compareTo(a.reviewsCount));
          break;
        case 'newest':
        default:
          filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
      }
      
      _filteredProducts = filtered;
    });
  }

  void _filterByCategory(String category) {
    _selectedCategory = category;
    _applyFiltersAndSort();
  }

  void _searchProducts(String query) {
    if (query.isEmpty) {
      _applyFiltersAndSort();
      return;
    }
    setState(() {
      _filteredProducts = _allProducts.where((p) =>
        p.title.toLowerCase().contains(query.toLowerCase()) ||
        p.category.toLowerCase().contains(query.toLowerCase()) ||
        p.city.toLowerCase().contains(query.toLowerCase())
      ).toList();
    });
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text('Filtres', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                // Prix
                const Text('Prix (CDF)', style: TextStyle(fontWeight: FontWeight.bold)),
                RangeSlider(
                  values: _priceRange,
                  min: 0,
                  max: 5000000,
                  divisions: 10,
                  labels: RangeLabels(
                    '${_priceRange.start.round()} CDF',
                    '${_priceRange.end.round()} CDF',
                  ),
                  onChanged: (values) => setModalState(() => _priceRange = values),
                ),
                const SizedBox(height: 16),
                
                // Note
                const Text('Note minimum', style: TextStyle(fontWeight: FontWeight.bold)),
                Slider(
                  value: _minRating,
                  min: 0,
                  max: 5,
                  divisions: 10,
                  label: _minRating.toStringAsFixed(1),
                  onChanged: (v) => setModalState(() => _minRating = v),
                ),
                const SizedBox(height: 16),
                
                // Ville
                const Text('Ville', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _cities.map((city) => FilterChip(
                    label: Text(city),
                    selected: _selectedCity == city,
                    onSelected: (_) => setModalState(() => _selectedCity = city),
                    selectedColor: const Color(0xFFD4AF37),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                
                // Tri
                const Text('Trier par', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildSortChip('Plus récents', 'newest', setModalState),
                    _buildSortChip('Prix croissant', 'price_asc', setModalState),
                    _buildSortChip('Prix décroissant', 'price_desc', setModalState),
                    _buildSortChip('Meilleures notes', 'rating', setModalState),
                    _buildSortChip('Plus populaires', 'popularity', setModalState),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setModalState(() {
                            _priceRange = const RangeValues(0, 5000000);
                            _minRating = 0;
                            _selectedCity = 'Toutes';
                            _sortBy = 'newest';
                          });
                        },
                        child: const Text('Tout effacer'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _applyFiltersAndSort();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: const Color(0xFF0B1B3D),
                        ),
                        child: const Text('Appliquer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortChip(String label, String value, Function(dynamic) setModalState) {
    return FilterChip(
      label: Text(label),
      selected: _sortBy == value,
      onSelected: (_) => setModalState(() => _sortBy = value),
      selectedColor: const Color(0xFFD4AF37),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);
    final auth = Provider.of<AuthController>(context);
    final userName = auth.currentUser?.displayName ?? 'Invité';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1B3D),
        elevation: 0,
        title: const Text('THIX MARKET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilters,
          ),
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
              _buildHeader(userName),
              const SizedBox(height: 20),
              _buildFeatures(),
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 20),
              _buildCategories(),
              const SizedBox(height: 20),
              _buildCityFilter(),
              const SizedBox(height: 20),
              if (_flashSales.isNotEmpty) _buildFlashSales(),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedCategory == 'Tous' ? 'Tous les produits' : 'Produits - $_selectedCategory',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_filteredProducts.length} produits',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
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

  Widget _buildHeader(String userName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0B1B3D), Color(0xFF1A2D56)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Bonjour, $userName 🎉',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Votre marketplace premium et sécurisée',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
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
              child: const Text('Explorer le marché', style: TextStyle(fontWeight: FontWeight.bold)),
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
              labelStyle: TextStyle(
                color: _selectedCategory == cat ? const Color(0xFF0B1B3D) : Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCityFilter() {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _cities.length,
        itemBuilder: (context, index) {
          final city = _cities[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(city),
              selected: _selectedCity == city,
              onSelected: (_) {
                setState(() => _selectedCity = city);
                _applyFiltersAndSort();
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFFD4AF37),
              labelStyle: TextStyle(
                color: _selectedCity == city ? const Color(0xFF0B1B3D) : Colors.grey.shade700,
              ),
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
                child: ProductCard(
                  product: _flashSales[index],
                  onTap: () => _showProductDetail(context, _flashSales[index]),
                  showLocation: true,
                  showStock: true,
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
