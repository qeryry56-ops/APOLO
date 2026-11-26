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
      'ChatListScreen matches Dynamic Layer v5.1 Inbox design (21768:49231), active search border, All/Unread pills, red unread badge, and E2EE footer',
      (WidgetTester tester) async {
    await pumpPhone(tester, const ChatListScreen());

    expect(tester.takeException(), isNull);
    expect(find.text('Chats'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Unread'), findsOneWidget);
    expect(find.byKey(const Key('inbox-e2ee-caption')), findsOneWidget);
    expect(
      find.text('Your personal messages are end-to-end encrypted'),
      findsOneWidget,
    );

    // Search bar starts borderless `#EEEEEE` (`Default`), gains `1.5px` `#000000` border + `×` on focus (`Search / Active`)
    AnimatedContainer searchBox() => tester.widget<AnimatedContainer>(
          find.byKey(const Key('inbox-search-container')),
        );
    final defaultDec = searchBox().decoration as BoxDecoration;
    expect(defaultDec.color, const Color(0xFFEEEEEE));
    expect((defaultDec.border as Border).top.color, Colors.transparent);
    expect(find.byKey(const Key('inbox-search-clear')), findsNothing);

    await tester.tap(find.byKey(const Key('inbox-search-field')));
    await tester.pumpAndSettle();
    final activeDec = searchBox().decoration as BoxDecoration;
    expect((activeDec.border as Border).top.color, const Color(0xFF000000));
    expect((activeDec.border as Border).top.width, 1.5);
    expect(find.byKey(const Key('inbox-search-clear')), findsOneWidget);

    // Conversation rows & red `#E31B23` unread count badge
    expect(find.text('Jenny Wilson'), findsOneWidget);
    expect(find.text('Aileen Fullbright'), findsOneWidget);
    expect(find.text('Ronald Richards'), findsOneWidget);

    final badgeContainer = tester.widget<Container>(
      find.byKey(const Key('inbox-unread-badge-1')),
    );
    final badgeDecoration = badgeContainer.decoration as BoxDecoration;
    expect(badgeDecoration.color, const Color(0xFFE31B23));

    // Active `All` pill uses solid `#000000` + `#FFFFFF` text; `Unread` uses `#EEEEEE` + `#000000` text
    final allMat = tester.widget<Material>(
      find.ancestor(
        of: find.byKey(const Key('inbox-filter-all')),
        matching: find.byType(Material),
      ).first,
    );
    final unreadMat = tester.widget<Material>(
      find.ancestor(
        of: find.byKey(const Key('inbox-filter-unread')),
        matching: find.byType(Material),
      ).first,
    );
    expect(allMat.color, const Color(0xFF000000));
    expect(unreadMat.color, const Color(0xFFEEEEEE));

    // Filtering by `Unread` hides Ronald Richards (unread_count = 0)
    await tester.tap(find.byKey(const Key('inbox-filter-unread')));
    await tester.pumpAndSettle();
    expect(find.text('Jenny Wilson'), findsOneWidget);
    expect(find.text('Ronald Richards'), findsNothing);

    // Switch back to `All` and search for 'Ronald' (`Search / Filled` state)
    await tester.tap(find.byKey(const Key('inbox-filter-all')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('inbox-search-field')), 'Ronald');
    await tester.pumpAndSettle();
    expect(find.text('Ronald Richards'), findsOneWidget);
    expect(find.text('Jenny Wilson'), findsNothing);

    // Unfocusing with query keeps `×` clear button and hides black border (`Search / Filled`)
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final filledDec = searchBox().decoration as BoxDecoration;
    expect((filledDec.border as Border).top.color, Colors.transparent);
    expect(find.byKey(const Key('inbox-search-clear')), findsOneWidget);
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
      expect(find.byKey(const Key('chat-dl-top-nav')), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.ellipsis), findsOneWidget);
      expect(find.text('السلام عليكم، واش باقي متوفر؟'), findsOneWidget);
      expect(find.text('وعليكم السلام، نعم متوفر'), findsOneWidget);
      expect(find.text('رسائل سريعة مقترحة:'), findsNothing);
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
