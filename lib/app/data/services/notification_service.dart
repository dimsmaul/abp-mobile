import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;

import 'api_service.dart';

/// Background message handler — MUST be a top-level / static function so
/// the Flutter engine can resolve it from the Android isolate that fires
/// when a push arrives while the app is killed.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Keep the handler intentionally minimal — no plugin re-init, no UI.
  // The OS already renders the notification; we just log so it's visible
  // in `adb logcat | grep FCM` while debugging.
  debugPrint('[FCM bg] ${message.messageId} data=${message.data}');
}

/// Lightweight FCM bootstrap that fails-safe when the Firebase config is
/// missing. On a clean clone without `android/app/google-services.json`,
/// `Firebase.initializeApp()` throws — we log and continue so the rest of
/// the app still launches.
class NotificationService extends GetxService {
  final isInitialized = false.obs;
  final fcmToken = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    // ignore: discarded_futures
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      // Firebase.initializeApp() picks options from the gradle-generated
      // google-services.json (Android) / GoogleService-Info.plist (iOS).
      // If neither is present this throws ArgumentError / FirebaseException
      // — we treat that as "FCM disabled" rather than crashing the app.
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('[FCM] Firebase.initializeApp skipped: $e');
      return;
    }

    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // iOS needs APNS before getToken() can return a value. On Android
      // this is a no-op.
      if (Platform.isIOS) {
        await messaging.getAPNSToken();
      }

      final token = await messaging.getToken();
      fcmToken.value = token;
      debugPrint('[FCM] token=${token?.substring(0, 12)}…');

      if (token != null && token.isNotEmpty) {
        await _registerWithBackend(token);
      }

      // Refresh — BE replaces the stored token so we don't have to delete
      // the previous one.
      messaging.onTokenRefresh.listen((next) {
        fcmToken.value = next;
        debugPrint('[FCM] token refreshed=${next.substring(0, 12)}…');
        // ignore: discarded_futures
        _registerWithBackend(next).catchError((_) {});
      });

      // Foreground push — render via snackbar (TODO swap to a local
      // notification once flutter_local_notifications is wired up).
      FirebaseMessaging.onMessage.listen((msg) {
        final title = msg.notification?.title ?? msg.data['title']?.toString();
        final body = msg.notification?.body ?? msg.data['body']?.toString();
        if (title != null || body != null) {
          Get.snackbar(title ?? 'Notification', body ?? '');
        }
      });

      isInitialized.value = true;
    } catch (e) {
      debugPrint('[FCM] post-init step failed: $e');
    }
  }

  Future<void> _registerWithBackend(String token) async {
    if (!Get.isRegistered<ApiService>()) return;
    try {
      final api = Get.find<ApiService>();
      // Skip if not signed in yet — token refresh after login will retry.
      if (!api.isLoggedIn) return;
      await api.registerDevice(
        fcmToken: token,
        platform: Platform.isIOS ? 'ios' : 'android',
      );
    } catch (e) {
      debugPrint('[FCM] registerDevice failed: $e');
    }
  }

  /// Public hook for AuthController — call after a successful sign-in so
  /// the cached FCM token (obtained at app launch before the user had a
  /// session) gets persisted to the user's row on BE.
  Future<void> registerCurrentToken() async {
    final token = fcmToken.value;
    if (token == null || token.isEmpty) return;
    await _registerWithBackend(token);
  }
}
