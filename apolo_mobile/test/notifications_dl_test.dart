import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:apolo_mobile/core/services/media_rtc_bridge.dart';
import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/screens/notifications_screen.dart';
import 'package:apolo_mobile/theme/app_theme.dart';
import 'package:apolo_mobile/widgets/apolo_badges_kit.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockNotificationsAdapter implements HttpClientAdapter {
  final FutureOr<ResponseBody> Function(RequestOptions options) handler;

  _MockNotificationsAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return await handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonReply(Object payload, [int status = 200]) {
  return ResponseBody.fromString(
    jsonEncode(payload),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final state = AppState();
  late Dio originalDio;
  late Locale originalLocale;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    originalDio = state.api.dio;
    originalLocale = state.locale;
    MediaRtcBridge.debugPermissionOverride = 'granted';
    state.currentUser = {'id': 7, 'name': 'Amine'};
    await state.api.setToken('tok-notif');
    await state.setLocale(const Locale('en'));
  });

  tearDown(() async {
    MediaRtcBridge.debugPermissionOverride = null;
    MediaRtcBridge.debugRequestPermissionHandler = null;
    state.currentUser = null;
    await state.api.setToken(null);
    await state.setLocale(originalLocale);
    state.api.dio = originalDio;
  });

  testWidgets(
      'Dynamic Layer v5.1 filter pills, verified badges, mark-all-read, and preferences sheet work in EN & AR RTL',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    int readAllCalls = 0;
    state.api.dio = Dio(BaseOptions(baseUrl: 'https://tests.invalid'))
      ..httpClientAdapter = _MockNotificationsAdapter((req) {
        if (req.path == '/notifications' && req.method == 'GET') {
          return _jsonReply({
            'status': 'success',
            'notifications': [
              {
                'id': 101,
                'type': 'chat',
                'title': 'Atlas Auto Store',
                'body': 'Yes, the car is available in Casablanca.',
                'is_read': false,
                'is_verified': true,
              },
            ],
          });
        }
        if (req.path == '/notifications/read-all' && req.method == 'POST') {
          readAllCalls++;
          return _jsonReply({'status': 'success'});
        }
        return _jsonReply({'status': 'success'});
      });

    await tester.pumpWidget(
      AnimatedBuilder(
        animation: state,
        builder: (context, _) => MaterialApp(
          theme: AppTheme.light(state.locale)
              .copyWith(splashFactory: NoSplash.splashFactory),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: const NotificationsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('dl-notifications-filter-bar')), findsOneWidget);
    expect(find.text('Atlas Auto Store'), findsOneWidget);
    expect(find.byType(ApoloVerifiedBadge), findsOneWidget);
    expect(find.byKey(const Key('dl-notification-mark-all-read')), findsOneWidget);

    // Filter -> Updates (0 matching items -> shows flat #F6F6F6 empty category card)
    await tester.ensureVisible(find.byKey(const Key('dl-notif-filter-updates')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dl-notif-filter-updates')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dl-notifications-filter-empty')), findsOneWidget);

    // Reset filter -> Show all
    await tester.tap(find.byKey(const Key('dl-notifications-filter-reset')));
    await tester.pumpAndSettle();
    expect(find.text('Atlas Auto Store'), findsOneWidget);

    // Mark all read clears the pill and triggers endpoint
    final beforeCalls = readAllCalls;
    await tester.ensureVisible(
      find.byKey(const Key('dl-notification-mark-all-read')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dl-notification-mark-all-read')));
    await tester.pumpAndSettle();
    expect(readAllCalls, greaterThan(beforeCalls));
    expect(find.byKey(const Key('dl-notification-mark-all-read')), findsNothing);

    // Open Notification Preferences sheet & toggle Saved listings alert
    await tester.tap(find.byKey(const Key('dl-notification-prefs-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dl-notif-pref-messages')), findsOneWidget);
    expect(find.byKey(const Key('dl-notif-pref-saved')), findsOneWidget);
    expect(find.byKey(const Key('dl-notif-pref-stores')), findsOneWidget);

    await tester.tap(find.byKey(const Key('dl-notif-pref-saved')));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('apolo_notif_pref_saved_v1'), isFalse);

    await tester.tap(find.byKey(const Key('dl-notif-pref-done')));
    await tester.pumpAndSettle();

    // Switch to Arabic RTL and verify zero overflow
    await tester.runAsync(() => state.setLocale(const Locale('ar')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('الإشعارات'), findsOneWidget);
    expect(find.text('الكل'), findsOneWidget);
  });

  testWidgets('Offline state renders Dynamic Layer #F6F6F6 card and reconnects',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    state.api.dio = Dio(BaseOptions(baseUrl: 'https://tests.invalid'))
      ..httpClientAdapter = _MockNotificationsAdapter(
        (_) => _jsonReply({'status': 'success', 'notifications': <dynamic>[]}),
      );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(const Locale('en'))
            .copyWith(splashFactory: NoSplash.splashFactory),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: const NotificationsScreen(initialSimulateOffline: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dl-notifications-offline-card')), findsOneWidget);
    await tester.tap(find.byKey(const Key('dl-notifications-retry-btn')));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dl-notifications-offline-card')), findsNothing);
    expect(find.byKey(const Key('dl-notifications-main-container')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
