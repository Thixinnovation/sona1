// lib/services/banner_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/banner.dart';

class BannerService {
  final SupabaseClient _supabase;

  BannerService(this._supabase);

  Future<List<BannerAd>> getActiveBanners() async {
    final response = await _supabase
        .from('home_banners')
        .select('*')
        .eq('is_active', true)
        .order('display_order', ascending: true);
    return (response as List).map((e) => BannerAd.fromJson(e)).toList();
  }
}
