import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class MarketService {
  final SupabaseClient _supabase;

  MarketService(this._supabase);

  // ==================== PRODUITS ====================

  Future<List<Product>> getFlashSales() async {
    try {
      final response = await _supabase
          .from('market_products')
          .select('*')
          .eq('is_flash_sale', true)
          .eq('in_stock', true)
          .order('created_at', ascending: false)
          .limit(6);
      return (response as List).map((e) => Product.fromJson(e)).toList();
    } catch (e) {
      print('Error getFlashSales: $e');
      return [];
    }
  }

  Future<List<Product>> getFeaturedProducts() async {
    try {
      final response = await _supabase
          .from('market_products')
          .select('*')
          .eq('is_featured', true)
          .eq('in_stock', true)
          .order('created_at', ascending: false)
          .limit(20);
      return (response as List).map((e) => Product.fromJson(e)).toList();
    } catch (e) {
      print('Error getFeaturedProducts: $e');
      return [];
    }
  }

  Future<List<Product>> getProductsByCategory(String category, {int limit = 20}) async {
    try {
      var query = _supabase
          .from('market_products')
          .select('*')
          .eq('in_stock', true);
      
      if (category != 'Tous') {
        query = query.eq('category', category);
      }
      
      final response = await query.order('created_at', ascending: false).limit(limit);
      return (response as List).map((e) => Product.fromJson(e)).toList();
    } catch (e) {
      print('Error getProductsByCategory: $e');
      return [];
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    if (query.isEmpty) return [];
    try {
      final response = await _supabase
          .from('market_products')
          .select('*')
          .ilike('title', '%$query%')
          .eq('in_stock', true)
          .limit(30);
      return (response as List).map((e) => Product.fromJson(e)).toList();
    } catch (e) {
      print('Error searchProducts: $e');
      return [];
    }
  }

  Future<Product?> getProductById(String id) async {
    try {
      final response = await _supabase
          .from('market_products')
          .select('*')
          .eq('id', id)
          .maybeSingle();
      return response != null ? Product.fromJson(response) : null;
    } catch (e) {
      print('Error getProductById: $e');
      return null;
    }
  }

  Future<List<Product>> getProductsByCity(String city, {int limit = 20}) async {
    try {
      final response = await _supabase
          .from('market_products')
          .select('*')
          .eq('city', city)
          .eq('in_stock', true)
          .order('created_at', ascending: false)
          .limit(limit);
      return (response as List).map((e) => Product.fromJson(e)).toList();
    } catch (e) {
      print('Error getProductsByCity: $e');
      return [];
    }
  }

  Future<List<Product>> getProductsByPriceRange(double min, double max, {int limit = 20}) async {
    try {
      final response = await _supabase
          .from('market_products')
          .select('*')
          .gte('price', min)
          .lte('price', max)
          .eq('in_stock', true)
          .order('price', ascending: true)
          .limit(limit);
      return (response as List).map((e) => Product.fromJson(e)).toList();
    } catch (e) {
      print('Error getProductsByPriceRange: $e');
      return [];
    }
  }

  Future<List<Product>> getProductsByRating(double minRating, {int limit = 20}) async {
    try {
      final response = await _supabase
          .from('market_products')
          .select('*')
          .gte('rating', minRating)
          .eq('in_stock', true)
          .order('rating', ascending: false)
          .limit(limit);
      return (response as List).map((e) => Product.fromJson(e)).toList();
    } catch (e) {
      print('Error getProductsByRating: $e');
      return [];
    }
  }

  // ==================== ADMIN ====================

  Future<String> createProduct(Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from('market_products')
          .insert(data)
          .select();
      return (response as List).first['id'] as String;
    } catch (e) {
      print('Error createProduct: $e');
      rethrow;
    }
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    try {
      await _supabase
          .from('market_products')
          .update(data)
          .eq('id', id);
    } catch (e) {
      print('Error updateProduct: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _supabase
          .from('market_products')
          .delete()
          .eq('id', id);
    } catch (e) {
      print('Error deleteProduct: $e');
      rethrow;
    }
  }

  Future<void> updateStock(String id, int newStock) async {
    try {
      await _supabase
          .from('market_products')
          .update({'stock': newStock, 'in_stock': newStock > 0})
          .eq('id', id);
    } catch (e) {
      print('Error updateStock: $e');
      rethrow;
    }
  }

  // ==================== STATISTIQUES ====================

  Future<int> getTotalProducts() async {
    try {
      final response = await _supabase
          .from('market_products')
          .select('id');
      return (response as List).length;
    } catch (e) {
      print('Error getTotalProducts: $e');
      return 0;
    }
  }

  Future<Map<String, dynamic>> getStats() async {
    try {
      final total = await getTotalProducts();
      final inStock = await _supabase
          .from('market_products')
          .select('id')
          .eq('in_stock', true);
      final categories = await _supabase
          .from('market_products')
          .select('category');
      
      final categoryList = (categories as List).map((e) => e['category'] as String).toList();
      final uniqueCategories = categoryList.toSet().length;
      
      return {
        'total_products': total,
        'in_stock': (inStock as List).length,
        'categories_count': uniqueCategories,
      };
    } catch (e) {
      print('Error getStats: $e');
      return {
        'total_products': 0,
        'in_stock': 0,
        'categories_count': 0,
      };
    }
  }
}
