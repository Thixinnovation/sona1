import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final SupabaseClient _client;

  NotificationService({SupabaseClient? client}) 
      : _client = client ?? Supabase.instance.client;

  Stream<List<Map<String, dynamic>>> streamForUser(String uid) async* {
    yield [];
  }

  Future<void> add({
    required String toUid,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {}

  Future<void> markAllRead(String uid) async {}

  Future<void> markRead({required String uid, required String notificationId}) async {}

  Future<List<Map<String, dynamic>>> getNotifications(String uid) async {
    return [];
  }
}
