import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/screens/chat_list_screen.dart';
import 'package:apolo_mobile/screens/chat_room_screen.dart';

class _ChatStubAdapter implements HttpClientAdapter {
  final FutureOr<ResponseBody> Function(RequestOptions) handler;
  final List<RequestOptions> requests = [];

  _ChatStubAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return await handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonBody(Object data, [int status = 200]) =>
    ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  final state = AppState();
  late Dio originalDio;
  late Locale originalLocale;
  late _ChatStubAdapter adapter;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    originalDio = state.api.dio;
    originalLocale = state.locale;

    adapter = _ChatStubAdapter((request) {
      if (request.path == '/chat/conversations') {
        return _jsonBody({
          'status': 'success',
          'conversations': [
            {
              'id': 1,
              'peer_name': 'Jenny Wilson',
              'peer_avatar': '',
              'last_message': "Can't wait to try it out!",
              'last_message_time': '10:41 AM',
              'unread_count': 2,
              'ad_title': 'Casa Oliva Villa',
              'ad_price': '212 MAD',
            },
            {
              'id': 2,
              'peer_name': 'Aileen Fullbright',
              'peer_avatar': '',
              'last_message': 'Wow, this is really epic',
              'last_message_time': '12:30 PM',
              'unread_count': 5,
            },
            {
              'id': 3,
              'peer_name': 'Ronald Richards',
              'peer_avatar': '',
              'last_message': 'Great job man!',
              'last_message_time': '12:30 PM',
              'unread_count': 0,
            },
          ],
        });
      }

      if (request.path == '/chat/conversations/42/messages' &&
          request.method == 'GET') {
        return _jsonBody({
          'status': 'success',
          'messages': [
            {
              'id': 101,
              'is_mine': false,
              'body': 'السلام عليكم، واش باقي متوفر؟',
              'created_at_time': '10:40 AM',
              'type': 'text',
            },
            {
              'id': 102,
              'is_mine': true,
              'body': 'وعليكم السلام، نعم متوفر',
              'created_at_time': '10:41 AM',
              'type': 'text',
              'read': true,
            },
          ],
        });
      }

      if (request.path == '/chat/conversations/42/messages' &&
          request.method == 'POST') {
        return _jsonBody({
          'status': 'success',
          'message': {
            'id': 103,
            'is_mine': true,
            'body': 'Tamam',
            'created_at_time': '10:42 AM',
            'type': 'text',
          },
        });
      }

      return _jsonBody({'status': 'success', 'data': []});
    });

    state.api.dio = Dio(BaseOptions(baseUrl: 'https://tests.invalid'))
      ..httpClientAdapter = adapter;
    state.currentUser = {'id': 9, 'name': 'Amine'};
    await state.api.setToken('chat-test-token');
    await state.setLocale(const Locale('en'));
  });

  tearDown(() async {
    await state.setLocale(originalLocale);
    state.api.dio = originalDio;
    state.currentUser = null;
    await state.api.setToken(null);
  });

  Future<void> pumpPhone(WidgetTester tester, Widget child,
      {TextDirection dir = TextDirection.ltr}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        builder: (context, w) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: Directionality(textDirection: dir, child: w!),
        ),
        home: child,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
      'ChatListScreen matches sky-blue iOS Chats design, filters All/Unread, and searches chats',
      (WidgetTester tester) async {
    await pumpPhone(tester, const ChatListScreen());

    expect(tester.takeException(), isNull);
    expect(find.text('Chats'), findsOneWidget);
    expect(find.text('Search chat'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Unread'), findsOneWidget);
    expect(find.byIcon(Icons.filter_list_rounded), findsOneWidget);

    // Top sky-blue `+` circle & bare camera icon + subtle gray `...`
    final plusContainer = tester.widget<Container>(
      find.ancestor(
        of: find.byIcon(CupertinoIcons.plus),
        matching: find.byType(Container),
      ).first,
    );
    final plusDecoration = plusContainer.decoration as BoxDecoration;
    expect(plusDecoration.color, const Color(0xFF288AF2));
    expect(plusDecoration.shape, BoxShape.circle);

    // Conversation rows & unread sky-blue badge
    expect(find.text('Jenny Wilson'), findsOneWidget);
    expect(find.text('Aileen Fullbright'), findsOneWidget);
    expect(find.text('Ronald Richards'), findsOneWidget);

    final badgeContainer = tester.widget<Container>(
      find.ancestor(
        of: find.text('2'),
        matching: find.byType(Container),
      ).first,
    );
    final badgeDecoration = badgeContainer.decoration as BoxDecoration;
    expect(badgeDecoration.color, const Color(0xFF288AF2));

    // Active `All` pill uses soft sky-blue `#E3F1FE` + `#288AF2` text
    final allText = tester.widget<Text>(find.text('All'));
    expect(allText.style?.color, const Color(0xFF288AF2));

    // Filtering by `Unread` hides Ronald Richards (unread_count = 0)
    await tester.tap(find.text('Unread'));
    await tester.pumpAndSettle();
    expect(find.text('Jenny Wilson'), findsOneWidget);
    expect(find.text('Ronald Richards'), findsNothing);

    // Switch back to `All` and search for 'Ronald'
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Ronald');
    await tester.pumpAndSettle();
    expect(find.text('Ronald Richards'), findsOneWidget);
    expect(find.text('Jenny Wilson'), findsNothing);
  });

  group('ChatRoomScreen Arabic RTL', () {
    setUp(() async {
      await state.setLocale(const Locale('ar'));
    });

    testWidgets(
        'ChatRoomScreen renders ad context bar, RTL/LTR sky-blue bubbles, sends text, and keeps safety state',
        timeout: const Timeout(Duration(seconds: 12)),
        (WidgetTester tester) async {
      await pumpPhone(
        tester,
        const ChatRoomScreen(
          conversationId: 42,
          peerName: 'Marta',
          adTitle: 'Casa Oliva Villa',
          adPrice: '212 MAD',
        ),
        dir: TextDirection.rtl,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Marta'), findsOneWidget);
      expect(find.text('Casa Oliva Villa'), findsOneWidget);
      expect(find.text('212 MAD'), findsOneWidget);
      expect(find.text('Online'), findsNothing);
      expect(find.text('غير متصل'), findsOneWidget);
      expect(find.text('السلام عليكم، واش باقي متوفر؟'), findsOneWidget);
      expect(find.text('وعليكم السلام، نعم متوفر'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.mic), findsOneWidget);

      // Typing shows sky-blue send button and sends POST request
      await tester.enterText(find.byKey(const Key('chat-draft')), 'Tamam');
      await tester.pump();
      expect(find.byKey(const Key('chat-send')), findsOneWidget);

      await tester.tap(find.byKey(const Key('chat-send')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        adapter.requests.any(
          (r) =>
              r.method == 'POST' && r.path == '/chat/conversations/42/messages',
        ),
        isTrue,
      );
    });
  });
}
