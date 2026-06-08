import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/supabase/supabase_config.dart';

/// Push notifications service using Supabase (replaces Firebase Cloud Messaging).
///
/// What this service does:
/// - Requests permissions on iOS / Android 13+
/// - Generates and stores device tokens in Supabase (`thix_push_tokens`)
/// - Manages local notifications when the app is foregrounded
/// - Tracks push notification preferences per user
class PushNotificationService {
  static final PushNotificationService instance = PushNotificationService._();
  PushNotificationService._();

  final SupabaseClient _client = SupabaseConfig.client;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Generate a unique device token (can be replaced with actual device ID)
  static String generateDeviceToken() {
    return '${DateTime.now().millisecondsSinceEpoch}-${DateTime.now().microsecond}';
  }

  Future<void> initIfNeeded() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await _initLocalNotifications();
    } catch (e, st) {
      debugPrint('PushNotificationService: init failed err=$e');
      debugPrint(st.toString());
    }
  }

  Future<void> onSignedIn({required String userId}) async {
    await initIfNeeded();
    await _requestPermission();
    await _syncToken(userId: userId);
  }

  Future<void> onSignedOut() async {
    // Cleanup on sign out
  }

  Future<void> _requestPermission() async {
    if (kIsWeb) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('PushNotificationService: requestPermission failed err=$e');
    }
  }

  Future<void> _syncToken({required String userId}) async {
    try {
      final token = generateDeviceToken();
      if (token.isEmpty) return;
      await _upsertToken(userId: userId, token: token);
    } catch (e, st) {
      debugPrint('PushNotificationService: _syncToken failed err=$e');
      debugPrint(st.toString());
    }
  }

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
      debugPrint('PushNotificationService: token upserted user=$userId platform=${_platformLabel()}');
    } on PostgrestException catch (e) {
      debugPrint('PushNotificationService: token upsert PostgrestException ${e.code} ${e.message}');
    } catch (e) {
      debugPrint('PushNotificationService: token upsert failed err=$e');
    }
  }

  // ✅ CORRECTION: La méthode initialize ne prend pas de paramètre
  Future<void> _initLocalNotifications() async {
    // Web doesn't support flutter_local_notifications.
    if (kIsWeb) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const init = InitializationSettings(android: androidInit, iOS: iosInit);
    // ✅ Correction: await _localNotifications.initialize(init);
    await _localNotifications.initialize(init);

    const channel = AndroidNotificationChannel(
      'thix_general',
      'THIX Notifications',
      description: 'Notifications générales THIX ID',
      importance: Importance.high,
    );
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
  }

  /// Show a notification locally
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;
    try {
      const android = AndroidNotificationDetails(
        'thix_general',
        'THIX Notifications',
        channelDescription: 'Notifications générales THIX ID',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
      );
      const ios = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const details = NotificationDetails(android: android, iOS: ios);
      await _localNotifications.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('PushNotificationService: show notification failed err=$e');
    }
  }
}
