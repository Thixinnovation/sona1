import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class NotificationService {
  final SupabaseClient _client;
  static const String _table = 'notifications';

  NotificationService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Map<String, dynamic> _normalizeRow(Map<String, dynamic> row) {
    return {
      'id': row['id'],
      'user_id': row['user_id'],
      'type': (row['type'] ?? 'generic').toString(),
      'title': (row['title'] ?? 'Notification').toString(),
      'body': (row['body'] ?? row['message'] ?? '').toString(),
      'read': row['read'] ?? row['seen'] ?? false,
      'data': row['data'] ?? {},
      'created_at': row['created_at'],
    };
  }

  /// Stream des notifications avec polling (sans Realtime)
  Stream<List<Map<String, dynamic>>> streamForUser(String uid) {
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();
    Timer? pollTimer;
    bool cancelled = false;

    Future<void> fetchAndEmit() async {
      if (cancelled) return;
      try {
        final data = await _client
            .from(_table)
            .select()
            .eq('user_id', uid)
            .order('created_at', ascending: false)
            .limit(50);

        final list = (data as List)
            .map((e) => _normalizeRow(e as Map<String, dynamic>))
            .toList();
        controller.add(list);
      } catch (e) {
        debugPrint('NotificationService fetch error: $e');
        controller.add([]);
      }
    }

    // Polling toutes les 3 secondes
    void startPolling() {
      pollTimer?.cancel();
      pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => fetchAndEmit());
    }

    startPolling();
    fetchAndEmit(); // Chargement initial

    controller.onCancel = () {
      cancelled = true;
      pollTimer?.cancel();
    };

    return controller.stream;
  }

  Stream<int> streamUnreadCount(String uid) {
    return streamForUser(uid)
        .map((list) => list.where((n) => n['read'] != true).length)
        .distinct();
  }

  Future<void> add({
    required String toUid,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _client.from(_table).insert({
        'user_id': toUid,
        'type': type,
        'title': title,
        'body': body,
        'read': false,
        'data': data ?? {},
      });
    } catch (e) {
      debugPrint('Notification add error: $e');
    }
  }

  Future<void> markRead({required String uid, required String notificationId}) async {
    try {
      await _client
          .from(_table)
          .update({'read': true})
          .eq('id', notificationId)
          .eq('user_id', uid);
    } catch (e) {
      debugPrint('Notification markRead error: $e');
    }
  }

  Future<void> markAllRead(String uid) async {
    try {
      await _client
          .from(_table)
          .update({'read': true})
          .eq('user_id', uid)
          .eq('read', false);
    } catch (e) {
      debugPrint('Notification markAllRead error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getNotifications(String uid) async {
    try {
      final data = await _client
          .from(_table)
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(50);
      
      return (data as List)
          .map((e) => _normalizeRow(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('NotificationService getNotifications error: $e');
      return [];
    }
  }

  Future<void> delete(String notificationId) async {
    try {
      await _client.from(_table).delete().eq('id', notificationId);
    } catch (e) {
      debugPrint('Notification delete error: $e');
    }
  }
}
