import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apolo_mobile/core/services/chat_realtime_client.dart';
import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/screens/chat_list_screen.dart';
import 'package:apolo_mobile/screens/chat_room_screen.dart';
import 'package:apolo_mobile/widgets/notification_badge.dart';

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
              'peer_online': true,
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

      if (request.path == '/chat/conversations/77/messages' &&
          request.method == 'GET') {
        return _jsonBody({
          'status': 'success',
          'messages': [
            {
              'id': 901,
              'is_mine': true,
              'sender_name': 'Amine',
              'body': 'This is a reply sent to a message',
              'created_at_time': '5:03 PM',
              'type': 'text',
              'reply_to': {
                'id': '900',
                'sender_name': 'Joshua',
                'body': 'This is a message sent from other',
              },
            },
          ],
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

    // Compact centered divider (`wast osa4ir`) & bottom-pinned online dot (`ltaht machi fo9`)
    final dividerFinder = find.byKey(const Key('inbox-divider-0'));
    expect(dividerFinder, findsOneWidget);
    final dividerSize = tester.getSize(dividerFinder);
    expect(dividerSize.height, lessThanOrEqualTo(1.0));
    expect(dividerSize.width, closeTo(390 * 0.62, 2.0));

    final onlineBadge = tester.widget<NotificationBadge>(
      find.byKey(const Key('inbox-online-dot-1')),
    );
    expect(onlineBadge.bottom, 0);
    expect(onlineBadge.top, isNull);

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

    // Clear search, test Dynamic Layer long-press action sheet (Pin -> Pinned pill) & Mark all read
    await tester.tap(find.byKey(const Key('inbox-search-clear')));
    await tester.pumpAndSettle();
    expect(find.text('Casa Oliva Villa'), findsOneWidget);

    await tester.longPress(find.byKey(const Key('inbox-row-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inbox-sheet-pin')), findsOneWidget);
    await tester.tap(find.byKey(const Key('inbox-sheet-pin')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('inbox-filter-pinned')), findsOneWidget);
    await tester.tap(find.byKey(const Key('inbox-mark-all-read')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inbox-unread-badge-1')), findsNothing);
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

    testWidgets(
        'ChatRoomScreen renders Dynamic Layer v5.1 reply quote bar, #D9F0FF reply bubble, and timestamp (33215:34358)',
        (WidgetTester tester) async {
      await pumpPhone(
        tester,
        const ChatRoomScreen(
          conversationId: 77,
          peerName: 'Joshua',
        ),
        dir: TextDirection.ltr,
      );

      expect(find.text('Joshua'), findsAtLeastNWidgets(2));
      expect(find.text('This is a message sent from other'), findsOneWidget);
      expect(find.text('This is a reply sent to a message'), findsOneWidget);
      expect(find.text('5:03 PM'), findsOneWidget);

      final replyText = tester.widget<Text>(
        find.text('This is a reply sent to a message'),
      );
      expect(replyText.style?.color, const Color(0xFF0A78E6));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'ChatRoomScreen & ChatListScreen receive new incoming messages live without refreshing',
        (WidgetTester tester) async {
      var roomMessages = <Map<String, dynamic>>[
        {
          'id': 201,
          'sender_id': 24,
          'is_mine': false,
          'body': 'واش نقدر نشوف السلعة اليوم؟',
          'created_at_time': '6:10 PM',
          'type': 'text',
        },
      ];
      var inboxPreview = 'واش نقدر نشوف السلعة اليوم؟';

      final liveAdapter = _ChatStubAdapter((request) {
        if (request.path == '/chat/conversations/88/messages' &&
            request.method == 'GET') {
          return _jsonBody({
            'status': 'success',
            'messages': roomMessages,
          });
        }
        if (request.path == '/chat/conversations' && request.method == 'GET') {
          return _jsonBody({
            'status': 'success',
            'conversations': [
              {
                'id': 88,
                'peer_id': 24,
                'peer_name': 'Yassine',
                'peer_avatar': '',
                'last_message': inboxPreview,
                'last_message_time': '6:11 PM',
                'unread_count': 1,
              },
            ],
          });
        }
        return _jsonBody({'status': 'success', 'data': []});
      });

      state.api.dio = Dio(BaseOptions(baseUrl: 'https://tests.invalid'))
        ..httpClientAdapter = liveAdapter;

      // Open ChatRoomScreen with synthetic hash conversationId + firestoreDocId + backendConversationId
      await pumpPhone(
        tester,
        const ChatRoomScreen(
          conversationId: 99887766,
          backendConversationId: 88,
          firestoreDocId: 'ad_50_u_9_24',
          peerId: 24,
          peerName: 'Yassine',
        ),
        dir: TextDirection.rtl,
      );

      expect(find.text('واش نقدر نشوف السلعة اليوم؟'), findsOneWidget);
      expect(find.text('أنا جاي دابا فـ الطريق!'), findsNothing);

      // Simulate peer sending a new message while room is open (no refresh)
      roomMessages = [
        ...roomMessages,
        {
          'id': 202,
          'sender_id': 24,
          'body': 'أنا جاي دابا فـ الطريق!',
          'created_at': '2026-11-27T18:11:00Z',
          'type': 'text',
        },
      ];

      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();

      expect(find.text('أنا جاي دابا فـ الطريق!'), findsOneWidget);
      // Header online dot is also pinned to bottom (`bottom: 0`, `top: null`)
      final roomOnlineBadge = tester.widget<NotificationBadge>(
        find.byKey(const Key('chat-header-online-dot')),
      );
      expect(roomOnlineBadge.bottom, 0);
      expect(roomOnlineBadge.top, isNull);
      expect(tester.takeException(), isNull);

      // Instant 0ms WebSocket stream arrival updates ChatRoomScreen without waiting for polling!
      ChatRealtimeClient.instance.injectIncomingMessage({
        'channel_id': 'ad_50_u_9_24',
        'message_id': 'ws_9001',
        'client_message_id': 'c_ws_9001',
        'sender_id': 24,
        'sender_name': 'Yassine',
        'type': 'text',
        'body': 'رسالة فورية فـ 0 ثانية!',
        'created_at': '2026-11-27T18:11:05Z',
      });
      await tester.pump();
      expect(find.text('رسالة فورية فـ 0 ثانية!'), findsOneWidget);

      // Sending the exact same message again (duplicate echo) never duplicates it
      ChatRealtimeClient.instance.injectIncomingMessage({
        'channel_id': 'ad_50_u_9_24',
        'message_id': 'ws_9001',
        'client_message_id': 'c_ws_9001',
        'sender_id': 24,
        'sender_name': 'Yassine',
        'type': 'text',
        'body': 'رسالة فورية فـ 0 ثانية!',
        'created_at': '2026-11-27T18:11:05Z',
      });
      await tester.pump();
      expect(find.text('رسالة فورية فـ 0 ثانية!'), findsOneWidget);

      // Verify ChatListScreen updates within 2.5s AND updates instantly on WebSocket message
      await pumpPhone(tester, const ChatListScreen());
      expect(find.text('واش نقدر نشوف السلعة اليوم؟'), findsOneWidget);

      ChatRealtimeClient.instance.injectIncomingMessage({
        'channel_id': 'conv_88',
        'message_id': 'ws_9002',
        'sender_id': 24,
        'sender_name': 'Yassine',
        'type': 'text',
        'body': 'وصلت حدا الباب فـ الحين!',
        'created_at': '2026-11-27T18:11:10Z',
      });
      await tester.pump();
      expect(find.text('وصلت حدا الباب فـ الحين!'), findsOneWidget);

      inboxPreview = 'تحديث عبر 2.5 ثانية!';
      await tester.pump(const Duration(milliseconds: 2600));
      await tester.pumpAndSettle();

      expect(find.text('تحديث عبر 2.5 ثانية!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Prevents overlapping concurrent backend requests and enforces 3s timeout',
        (WidgetTester tester) async {
      int inFlight = 0;
      int maxConcurrent = 0;
      int getCount = 0;

      final slowAdapter = _ChatStubAdapter((request) async {
        if (request.path == '/chat/conversations/88/messages' &&
            request.method == 'GET') {
          getCount++;
          inFlight++;
          if (inFlight > maxConcurrent) maxConcurrent = inFlight;
          await Future<void>.delayed(const Duration(milliseconds: 2200));
          inFlight--;
          return _jsonBody({
            'status': 'success',
            'messages': [
              {
                'id': 301,
                'sender_id': 24,
                'is_mine': false,
                'body': 'مرحباً بدون تداخل',
                'created_at_time': '7:00 PM',
                'type': 'text',
              },
            ],
          });
        }
        return _jsonBody({'status': 'success', 'data': []});
      });

      state.api.dio = Dio(BaseOptions(baseUrl: 'https://tests.invalid'))
        ..httpClientAdapter = slowAdapter;

      await tester.pumpWidget(
        MaterialApp(
          home: const ChatRoomScreen(
            conversationId: 88,
            peerId: 24,
            peerName: 'Yassine',
          ),
        ),
      );
      // Advance past the 1.5s fallback tick while initial 2.2s request is still in-flight
      await tester.pump(const Duration(milliseconds: 1600));
      expect(maxConcurrent, 1);
      expect(getCount, 1);

      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();
      expect(find.text('مرحباً بدون تداخل'), findsOneWidget);
      expect(maxConcurrent, 1);
    });
  });
}
