// lib/services/admin_news_service.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/supabase/supabase_config.dart';

class AdminNewsService {
  static const String table = 'thix_news';
  static const String coverBucketDefault = 'thix_news_images';

  final SupabaseClient _client;

  AdminNewsService({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  Future<List<Map<String, dynamic>>> listNews() async {
    try {
      final res = await _client
          .from(table)
          .select('*')
          .order('created_at', ascending: false);
      return (res is List) ? res.cast<Map<String, dynamic>>() : [];
    } catch (e) {
      debugPrint('AdminNewsService.listNews error: $e');
      rethrow;
    }
  }

  Future<String> upsertNews({
    String? id,
    required String title,
    required String subtitle,
    required String category,
    required String source,
    required String severity,
    required String content,
    required bool isFeatured,
    required String status,
  }) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final data = {
        'title': title,
        'subtitle': subtitle,
        'category': category,
        'source': source,
        'severity': severity,
        'content': content,
        'is_featured': isFeatured,
        'status': status,
        'updated_at': now,
      };

      if (id == null || id.isEmpty) {
        data['created_at'] = now;
        final res = await _client.from(table).insert(data).select().single();
        return res['id'].toString();
      } else {
        await _client.from(table).update(data).eq('id', id);
        return id;
      }
    } catch (e) {
      debugPrint('AdminNewsService.upsertNews error: $e');
      rethrow;
    }
  }

  Future<void> updateCoverImage({
    required String newsId,
    required String bucket,
    required String storagePath,
  }) async {
    try {
      await _client.from(table).update({
        'cover_image_bucket': bucket,
        'cover_image_path': storagePath,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', newsId);
    } catch (e) {
      debugPrint('AdminNewsService.updateCoverImage error: $e');
      rethrow;
    }
  }

  Future<void> deleteNews({required String id}) async {
    try {
      await _client.from(table).delete().eq('id', id);
    } catch (e) {
      debugPrint('AdminNewsService.deleteNews error: $e');
      rethrow;
    }
  }
}
