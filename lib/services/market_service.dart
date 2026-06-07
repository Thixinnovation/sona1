import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class MarketService {
  final SupabaseClient _supabase;

  MarketService(this._supabase);

  Future<List<Product>> getFlashSales() async {
    final response = await _supabase
        .from('market_products')
        .select('*')
        .eq('is_flash_sale', true)
        .eq('in_stock', true)
        .order('created_at', ascending: false)
        .limit(6);
    return (response as List).map((e) => Product.fromJson(e)).toList();
  }

  Future<List<Product>> getFeaturedProducts() async {
    final response = await _supabase
        .from('market_products')
        .select('*')
        .eq('is_featured', true)
        .eq('in_stock', true)
        .order('created_at', ascending: false)
        .limit(20);
    return (response as List).map((e) => Product.fromJson(e)).toList();
  }

  Future<List<Product>> getProductsByCategory(String category, {int limit = 20}) async {
  var query = _supabase
      .from('market_products')
      .select('*')
      .eq('in_stock', true);
  
  if (category != 'Tous') {
    query = query.eq('category', category);
  }
  final response = await query.order('created_at', ascending: false).limit(limit);
  return (response as List).map((e) => Product.fromJson(e)).toList();
}
  Future<List<Product>> searchProducts(String query) async {
    if (query.isEmpty) return [];
    final response = await _supabase
        .from('market_products')
        .select('*')
        .ilike('title', '%$query%')
        .eq('in_stock', true)
        .limit(30);
    return (response as List).map((e) => Product.fromJson(e)).toList();
  }

  Future<Product?> getProductById(String id) async {
    final response = await _supabase
        .from('market_products')
        .select('*')
        .eq('id', id)
        .maybeSingle();
    return response != null ? Product.fromJson(response) : null;
  }
}
