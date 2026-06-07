import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wishlist_item.dart';

class WishlistService {
  final SupabaseClient _supabase;

  WishlistService(this._supabase);

  Future<void> addToWishlist(String userId, String productId) async {
    final existing = await _supabase
        .from('wishlist')
        .select('id')
        .eq('user_id', userId)
        .eq('product_id', productId)
        .maybeSingle();
    
    if (existing == null) {
      await _supabase.from('wishlist').insert({
        'user_id': userId,
        'product_id': productId,
      });
    }
  }

  Future<void> removeFromWishlist(String userId, String productId) async {
    await _supabase
        .from('wishlist')
        .delete()
        .eq('user_id', userId)
        .eq('product_id', productId);
  }

  Future<List<String>> getUserWishlist(String userId) async {
    final response = await _supabase
        .from('wishlist')
        .select('product_id')
        .eq('user_id', userId);
    return (response as List).map((e) => e['product_id'].toString()).toList();
  }

  Future<bool> isInWishlist(String userId, String productId) async {
    final response = await _supabase
        .from('wishlist')
        .select('id')
        .eq('user_id', userId)
        .eq('product_id', productId)
        .maybeSingle();
    return response != null;
  }
}
