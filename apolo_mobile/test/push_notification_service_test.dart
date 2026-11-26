import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:apolo_mobile/core/services/push_notification_service.dart';
import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/screens/main_shell.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubAdapter implements HttpClientAdapter {
  final FutureOr<ResponseBody> Function(RequestOptions options) handler;

  _StubAdapter(this.handler);

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

ResponseBody _json(Object payload, [int statusCode = 200]) {
  return ResponseBody.fromString(
    jsonEncode(payload),
    statusCode,
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
    await state.setLocale(const Locale('en'));
  });

  tearDown(() async {
    state.currentUser = null;
    await state.api.setToken(null);
    await state.setLocale(originalLocale);
    state.api.dio = originalDio;
  });

  test('channelForType maps message, call, and alert notification channels', () {
    expect(
      ApoloPushNotificationService.channelForType('message'),
      ApoloPushNotificationService.channelMessages,
    );
    expect(
      ApoloPushNotificationService.channelForType('new_chat'),
      ApoloPushNotificationService.channelMessages,
    );
    expect(
      ApoloPushNotificationService.channelForType('video_call'),
      ApoloPushNotificationService.channelCalls,
    );
    expect(
      ApoloPushNotificationService.channelForType('offer'),
      ApoloPushNotificationService.channelAlerts,
    );
    expect(
      ApoloPushNotificationService.channelForType(null),
      ApoloPushNotificationService.channelAlerts,
    );
  });

  test('decodePayload safely parses JSON payloads and ignores invalid raw strings', () {
    expect(ApoloPushNotificationService.decodePayload(null), isEmpty);
    expect(ApoloPushNotificationService.decodePayload(''), isEmpty);
    expect(ApoloPushNotificationService.decodePayload('{broken'), isEmpty);
    expect(
      ApoloPushNotificationService.decodePayload('{"type":"message","ad_id":42}'),
      {'type': 'message', 'ad_id': 42},
    );
  });

  test('syncTokenWithBackend and unregisterTokenFromBackend hit /chat/push-tokens cleanly', () async {
    final requests = <Map<String, dynamic>>[];

    state.api.dio = Dio(BaseOptions(baseUrl: 'https://tests.invalid'))
      ..httpClientAdapter = _StubAdapter((options) {
        requests.add({
          'method': options.method,
          'path': options.path,
          'data': options.data,
        });
        return _json({'status': 'ok'});
      });

    state.currentUser = {'id': 42, 'name': 'Amine'};
    await state.api.setToken('sanctum_token');

    final registered = await ApoloPushNotificationService.instance
        .syncTokenWithBackend(overrideToken: 'fcm_device_token_abc');
    expect(registered, isTrue);

    await ApoloPushNotificationService.instance.unregisterTokenFromBackend();

    expect(requests.length, 2);
    expect(requests[0]['method'], 'POST');
    expect(requests[0]['path'], '/chat/push-tokens');
    final postBody = Map<String, dynamic>.from(requests[0]['data'] as Map);
    expect(postBody['provider'], 'fcm');
    expect(postBody['token'], 'fcm_device_token_abc');
    expect((postBody['device_id'] ?? '').toString(), isNotEmpty);

    expect(requests[1]['method'], 'DELETE');
    expect(requests[1]['path'], '/chat/push-tokens');
    final delBody = Map<String, dynamic>.from(requests[1]['data'] as Map);
    expect(delBody['device_id'], postBody['device_id']);
  });

  testWidgets('MainShell does not display any floating in-app notification banner', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    state.api.dio = Dio(BaseOptions(baseUrl: 'https://tests.invalid'))
      ..httpClientAdapter = _StubAdapter(
        (_) => _json({
          'status': 'success',
          'data': [],
          'categories': [],
          'cities': [],
        }),
      );
    state.currentUser = {'id': 42, 'name': 'Amine'};
    await state.api.setToken('sanctum_token');
    state.setUnreadNotificationsCount(0);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        builder: (context, w) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: w!,
        ),
        home: const MainShell(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    state.setUnreadNotificationsCount(3);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('You have a new Apolo notification'), findsNothing);
    expect(find.text('Apolo.ma'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
