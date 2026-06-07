import 'package:flutter/foundation.dart';

/// Platform-aware utilities for handling web-specific features
class PlatformUtils {
  /// Check if running on web
  static bool get isWeb => kIsWeb;

  /// Check if running on mobile platforms
  static bool get isMobile => !kIsWeb;

  /// Get appropriate storage path based on platform
  static String getStoragePath() {
    if (isWeb) {
      return 'localStorage'; // Uses browser localStorage
    }
    return 'app_data'; // Uses native storage
  }

  /// Check if a feature is available on current platform
  static bool isFeatureAvailable(String feature) {
    if (isWeb) {
      // Disable mobile-only features on web
      return !['nfc', 'gps', 'bluetooth', 'camera_mobile'].contains(feature);
    }
    return true;
  }

  /// Log platform information
  static void logPlatformInfo() {
    debugPrint('🖥️ Platform Info: ${isWeb ? 'WEB' : 'MOBILE'}');
    debugPrint('📱 kIsWeb: $kIsWeb');
  }
}
