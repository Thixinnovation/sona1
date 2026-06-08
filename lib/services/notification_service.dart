import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushNotificationService {
  final SupabaseClient _client;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  PushNotificationService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  String _platformLabel() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      default:
        return 'unknown';
    }
  }

  Future<void> _upsertToken({required String userId, required String token}) async {
    try {
      await _client.from('thix_push_tokens').upsert({
        'user_id': userId,
        'token': token,
        'platform': _platformLabel(),
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'token');
      debugPrint('PushNotificationService: token upsert success');
    } on PostgrestException catch (e) {
      debugPrint('PushNotificationService: PostgrestException $e');
    } catch (e) {
      debugPrint('PushNotificationService: token upsert error $e');
    }
  }

  Future<void> _initLocalNotifications() async {
    if (kIsWeb) return; // Web non supporté

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const init = InitializationSettings(android: androidInit, iOS: iosInit);
    await _localNotifications.initialize(init);

    const channel = AndroidNotificationChannel(
      'thix_general',
      'THIX Notifications',
      description: 'Notifications générales THIX ID',
      importance: Importance.high,
    );
    await _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> showNotification({required String title, required String body, String? payload, String? icon}) async {
    if (kIsWeb) return;

    const androidDetails = AndroidNotificationDetails(
      'thix_general',
      'THIX Notifications',
      channelDescription: 'Notifications générales THIX ID',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }
}
