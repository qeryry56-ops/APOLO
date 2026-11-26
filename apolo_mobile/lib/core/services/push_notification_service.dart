import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/bug_report/services/bug_report_controller.dart';
import '../../screens/ad_detail_screen.dart';
import '../../screens/chat_room_screen.dart';
import '../../screens/notifications_screen.dart';
import '../state/app_state.dart';
import 'firebase_chat_service.dart';
import 'media_rtc_bridge.dart';

/// Top-level Firebase Messaging background handler required on Android/iOS
/// when push messages arrive while the app is backgrounded or terminated.
@pragma('vm:entry-point')
Future<void> apoloFirebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {}
}

/// Unified Push & Local OS Notification Service for APOLO (Android, iOS, Web).
///
/// Delivers real phone notifications (Notification Bar / Lock Screen) via
/// Firebase Cloud Messaging (FCM) + `flutter_local_notifications` and routes
/// notification taps to the target screen.
class ApoloPushNotificationService {
  ApoloPushNotificationService._();
  static final ApoloPushNotificationService instance =
      ApoloPushNotificationService._();

  static const String channelMessages = 'apolo_messages';
  static const String channelCalls = 'apolo_calls';
  static const String channelAlerts = 'apolo_alerts';

  static const String _prefDeviceIdKey = 'apolo_push_device_id_v1';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _localPluginReady = false;
  String _cachedMobilePermission = 'unsupported';
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onOpenedAppSub;
  StreamSubscription<String>? _onTokenRefreshSub;

  static String channelForType(String? rawType) {
    final normalized = (rawType ?? '').toLowerCase().trim();
    if (normalized.contains('call')) return channelCalls;
    if (normalized.contains('message') || normalized.contains('chat')) {
      return channelMessages;
    }
    return channelAlerts;
  }

  static Map<String, dynamic> decodePayload(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const <String, dynamic>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return const <String, dynamic>{};
  }

  static String get _platformLabel {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'web';
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (kIsWeb) {
      return;
    }

    await _initLocalNotifications();
    await _initFirebaseMessaging();
    await getPermissionStatusAsync();
  }

  Future<void> _initLocalNotifications() async {
    if (_localPluginReady || kIsWeb) return;
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const settings = InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
      );

      await _localNotifications.initialize(
        settings,
        onDidReceiveNotificationResponse: (response) {
          final data = decodePayload(response.payload);
          if (data.isNotEmpty) {
            handleNotificationPayload(data);
          }
        },
      );

      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            channelMessages,
            'Messages',
            description: 'Direct buyer & seller chat messages on Apolo.ma',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            channelCalls,
            'Incoming Calls',
            description: 'Voice and video calls on Apolo.ma',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            channelAlerts,
            'Apolo Alerts',
            description: 'Offers, ad approvals, orders, and account activity',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );
      }

      _localPluginReady = true;
    } catch (e) {
      debugPrint('Local notifications init skipped: $e');
    }
  }

  Future<void> _initFirebaseMessaging() async {
    if (kIsWeb || Firebase.apps.isEmpty) return;
    try {
      FirebaseMessaging.onBackgroundMessage(
        apoloFirebaseMessagingBackgroundHandler,
      );

      final messaging = FirebaseMessaging.instance;
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      await _onMessageSub?.cancel();
      _onMessageSub = FirebaseMessaging.onMessage.listen((message) {
        final data = Map<String, dynamic>.from(message.data);
        final docId = (data['firestore_doc_id'] ?? '').toString();
        if (docId.isNotEmpty &&
            docId == FirebaseChatService.activeChatDocId) {
          return;
        }

        final title = (message.notification?.title ??
                data['title'] ??
                data['sender_name'] ??
                'Apolo.ma')
            .toString()
            .trim();
        final body = (message.notification?.body ??
                data['body'] ??
                data['message'] ??
                '')
            .toString()
            .trim();

        if (title.isEmpty && body.isEmpty) return;

        final channel = (data['channel'] ??
                channelForType(data['type']?.toString()))
            .toString();
        unawaited(
          showLocalNotification(
            title: title.isNotEmpty ? title : 'Apolo.ma',
            body: body,
            channel: channel,
            payload: data,
          ),
        );
      });

      await _onOpenedAppSub?.cancel();
      _onOpenedAppSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
        handleNotificationPayload(Map<String, dynamic>.from(message.data));
      });

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null && initialMessage.data.isNotEmpty) {
        final payload = Map<String, dynamic>.from(initialMessage.data);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          handleNotificationPayload(payload);
        });
      }

      await _onTokenRefreshSub?.cancel();
      _onTokenRefreshSub = messaging.onTokenRefresh.listen((newToken) {
        unawaited(syncTokenWithBackend(overrideToken: newToken));
      });
    } catch (e) {
      debugPrint('Firebase Messaging init skipped: $e');
    }
  }

  String getPermissionStatusSync() {
    if (MediaRtcBridge.debugPermissionOverride != null) {
      return MediaRtcBridge.debugPermissionOverride!;
    }
    if (kIsWeb) {
      return MediaRtcBridge.getNotificationPermissionStatus();
    }
    return _cachedMobilePermission;
  }

  Future<String> getPermissionStatusAsync() async {
    if (MediaRtcBridge.debugPermissionOverride != null) {
      return MediaRtcBridge.debugPermissionOverride!;
    }
    if (kIsWeb) {
      return MediaRtcBridge.getNotificationPermissionStatus();
    }
    try {
      final status = await Permission.notification.status;
      final mapped = _mapPermissionStatus(status);
      _cachedMobilePermission = mapped;
      return mapped;
    } catch (_) {
      return _cachedMobilePermission;
    }
  }

  Future<String> requestPermission() async {
    if (MediaRtcBridge.debugRequestPermissionHandler != null) {
      return await MediaRtcBridge.debugRequestPermissionHandler!();
    }
    if (MediaRtcBridge.debugPermissionOverride != null) {
      return MediaRtcBridge.debugPermissionOverride!;
    }
    if (kIsWeb) {
      return await MediaRtcBridge.requestNotificationPermissionWithResult();
    }

    String mapped = 'unsupported';
    try {
      final result = await Permission.notification.request();
      mapped = _mapPermissionStatus(result);
    } catch (_) {}

    if (Firebase.apps.isNotEmpty) {
      try {
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        if (settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional) {
          mapped = 'granted';
        } else if (settings.authorizationStatus == AuthorizationStatus.denied &&
            mapped == 'unsupported') {
          mapped = 'denied';
        }
      } catch (_) {}
    }

    _cachedMobilePermission = mapped;
    if (mapped == 'granted') {
      unawaited(syncTokenWithBackend());
    }
    return mapped;
  }

  static String _mapPermissionStatus(PermissionStatus status) {
    if (status.isGranted || status.isProvisional || status.isLimited) {
      return 'granted';
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return 'denied';
    }
    return 'default';
  }

  Future<String> _getOrCreateDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getString(_prefDeviceIdKey);
      if (existing != null && existing.trim().isNotEmpty) {
        return existing;
      }
      final rng = math.Random.secure();
      final suffix = List<int>.generate(12, (_) => rng.nextInt(16))
          .map((n) => n.toRadixString(16))
          .join();
      final created = 'apolo_${_platformLabel}_$suffix';
      await prefs.setString(_prefDeviceIdKey, created);
      return created;
    } catch (_) {
      return 'apolo_${_platformLabel}_default';
    }
  }

  Future<bool> syncTokenWithBackend({String? overrideToken}) async {
    final state = AppState();
    if (!state.isLoggedIn || !state.api.isAuthenticated) return false;

    String? token = overrideToken?.trim();
    if ((token == null || token.isEmpty) && Firebase.apps.isNotEmpty) {
      try {
        token = (await FirebaseMessaging.instance.getToken())?.trim();
      } catch (_) {
        token = null;
      }
    }
    if (token == null || token.isEmpty) return false;

    try {
      final deviceId = await _getOrCreateDeviceId();
      await state.api.dio.post<dynamic>(
        '/chat/push-tokens',
        data: <String, dynamic>{
          'device_id': deviceId,
          'platform': _platformLabel,
          'provider': 'fcm',
          'token': token,
        },
      );
      return true;
    } catch (e) {
      debugPrint('Push token registration failed: $e');
      return false;
    }
  }

  Future<void> unregisterTokenFromBackend() async {
    final state = AppState();
    if (!state.api.isAuthenticated) return;
    try {
      final deviceId = await _getOrCreateDeviceId();
      await state.api.dio.delete<dynamic>(
        '/chat/push-tokens',
        data: <String, dynamic>{
          'device_id': deviceId,
        },
      );
    } catch (_) {}
  }

  Future<void> notifyRemoteUser({
    required int recipientUserId,
    required String title,
    required String body,
    String type = 'message',
    Map<String, dynamic>? data,
  }) async {
    final state = AppState();
    if (recipientUserId <= 0 ||
        !state.isLoggedIn ||
        !state.api.isAuthenticated) {
      return;
    }
    try {
      await state.api.dio.post<dynamic>(
        '/chat/push-notify',
        data: <String, dynamic>{
          'recipient_user_id': recipientUserId,
          'title': title,
          'body': body,
          'type': type,
          'channel_id': channelForType(type),
          if (data != null && data.isNotEmpty) 'data': data,
        },
      );
    } catch (_) {}
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String channel = channelAlerts,
    Map<String, dynamic>? payload,
    int? id,
  }) async {
    if (kIsWeb) {
      MediaRtcBridge.showBrowserNotification(title, body);
      return;
    }

    if (!_localPluginReady) {
      await _initLocalNotifications();
    }
    if (!_localPluginReady) return;

    final channelName = switch (channel) {
      channelMessages => 'Messages',
      channelCalls => 'Incoming Calls',
      _ => 'Apolo Alerts',
    };

    try {
      final notificationId = id ??
          (DateTime.now().millisecondsSinceEpoch % 0x7fffffff);
      await _localNotifications.show(
        notificationId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel,
            channelName,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload != null && payload.isNotEmpty
            ? jsonEncode(payload)
            : null,
      );
    } catch (e) {
      debugPrint('Failed to display local OS notification: $e');
    }
  }

  void handleNotificationPayload(Map<String, dynamic> data) {
    final nav = BugReportController.navigatorKey.currentState;
    if (nav == null) return;

    final type = (data['type'] ?? '').toString().toLowerCase().trim();
    final firestoreDocId = data['firestore_doc_id']?.toString();
    final channelId = int.tryParse('${data['channel_id'] ?? 0}') ?? 0;

    if (type == 'message' ||
        type == 'chat' ||
        (firestoreDocId != null && firestoreDocId.isNotEmpty) ||
        channelId > 0) {
      nav.push(
        MaterialPageRoute<void>(
          builder: (_) => ChatRoomScreen(
            conversationId:
                int.tryParse('${data['conversation_id'] ?? channelId}') ?? 0,
            firestoreDocId: firestoreDocId,
            peerId: int.tryParse('${data['peer_id'] ?? data['sender_id'] ?? ''}'),
            peerName:
                (data['peer_name'] ?? data['sender_name'] ?? 'Apolo').toString(),
            peerAvatar: data['peer_avatar']?.toString(),
            adTitle: (data['ad_title'] ?? '').toString(),
            adPrice: data['ad_price']?.toString(),
            adImage: data['ad_image']?.toString(),
          ),
        ),
      );
      return;
    }

    final adId = int.tryParse('${data['ad_id'] ?? ''}') ?? 0;
    if (adId > 0) {
      nav.push(
        MaterialPageRoute<void>(
          builder: (_) => AdDetailScreen(adId: adId),
        ),
      );
      return;
    }

    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => const NotificationsScreen(),
      ),
    );
  }
}
