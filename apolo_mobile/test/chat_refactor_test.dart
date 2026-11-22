import 'dart:async';
import 'dart:convert';
import 'dart:ui' show PointerDeviceKind;

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/screens/chat_room_screen.dart';
import 'package:apolo_mobile/widgets/chat_input.dart';
import 'package:apolo_mobile/widgets/chat_message.dart';

class _TestHttpAdapter implements HttpClientAdapter {
  final FutureOr<ResponseBody> Function(RequestOptions) handler;
  final List<RequestOptions> requests = [];

  _TestHttpAdapter(this.handler);

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

ResponseBody _json(Object data, [int status = 200]) =>
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

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    originalDio = state.api.dio;
    originalLocale = state.locale;
    state.currentUser = {'id': 9, 'name': 'Amine'};
    await state.api.setToken('chat-refactor-token');
    await state.setLocale(const Locale('en'));
  });

  tearDown(() async {
    await state.setLocale(originalLocale);
    state.api.dio = originalDio;
    state.currentUser = null;
    await state.api.setToken(null);
  });

  group('Rule 1: Message Grouping (2-minute window, 1 avatar at top, 8px spacing)', () {
    test('computeGrouping groups consecutive messages within 2 minutes and splits after >2 minutes', () {
      final base = DateTime(2026, 11, 22, 10, 0, 0);
      final messages = <Map<String, dynamic>>[
        {
          'id': 1,
          'is_mine': false,
          'sender_id': '2',
          'sender_name': 'Maya',
          'body': 'First message',
          'created_at_ms': base.millisecondsSinceEpoch,
        },
        {
          'id': 2,
          'is_mine': false,
          'sender_id': '2',
          'sender_name': 'Maya',
          'body': 'Second within 45s',
          'created_at_ms':
              base.add(const Duration(seconds: 45)).millisecondsSinceEpoch,
        },
        {
          'id': 3,
          'is_mine': false,
          'sender_id': '2',
          'sender_name': 'Maya',
          'body': 'Third at exactly 2m',
          'created_at_ms':
              base.add(const Duration(minutes: 2)).millisecondsSinceEpoch,
        },
        {
          'id': 4,
          'is_mine': false,
          'sender_id': '2',
          'sender_name': 'Maya',
          'body': 'Fourth 3m later (> 2m starts new group)',
          'created_at_ms':
              base.add(const Duration(minutes: 5)).millisecondsSinceEpoch,
        },
        {
          'id': 5,
          'is_mine': true,
          'sender_id': '9',
          'sender_name': 'Amine',
          'body': 'Reply from different sender',
          'created_at_ms':
              base.add(const Duration(minutes: 5, seconds: 10)).millisecondsSinceEpoch,
        },
      ];

      final meta = ChatMessage.computeGrouping(messages);
      expect(meta.length, 5);

      // Message 1: top of group -> showAvatar = true
      expect(meta[0].isFirstInGroup, isTrue);
      expect(meta[0].showAvatar, isTrue);
      expect(meta[0].isLastInGroup, isFalse);

      // Message 2 & 3: consecutive within 2 min -> showAvatar = false, compact spacing
      expect(meta[1].isFirstInGroup, isFalse);
      expect(meta[1].showAvatar, isFalse);
      expect(meta[1].topSpacing, ChatMessage.intraGroupSpacing);

      expect(meta[2].isFirstInGroup, isFalse);
      expect(meta[2].showAvatar, isFalse);
      expect(meta[2].isLastInGroup, isTrue);

      // Message 4: >2 minutes gap -> new group -> showAvatar = true
      expect(meta[3].isFirstInGroup, isTrue);
      expect(meta[3].showAvatar, isTrue);

      // Message 5: different sender -> showAvatar = true & exact 8px spacing
      expect(meta[4].isFirstInGroup, isTrue);
      expect(meta[4].showAvatar, isTrue);
      expect(meta[4].topSpacing, 8.0);
    });

    testWidgets('renders only 1 avatar at top of group and no avatar on consecutive messages',
        (tester) async {
      final base = DateTime(2026, 11, 22, 10, 0, 0);
      final msgs = <Map<String, dynamic>>[
        {
          'id': '1',
          'is_mine': false,
          'sender_id': '2',
          'sender_name': 'Maya',
          'body': 'Hello there',
          'created_at_ms': base.millisecondsSinceEpoch,
        },
        {
          'id': '2',
          'is_mine': false,
          'sender_id': '2',
          'sender_name': 'Maya',
          'body': 'Is the car available?',
          'created_at_ms':
              base.add(const Duration(seconds: 30)).millisecondsSinceEpoch,
        },
        {
          'id': '3',
          'is_mine': true,
          'sender_id': '9',
          'sender_name': 'Amine',
          'body': 'Yes, still available!',
          'created_at_ms':
              base.add(const Duration(seconds: 50)).millisecondsSinceEpoch,
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: ChatRoomScreen(
            conversationId: 10,
            peerName: 'Maya',
            initialMessages: msgs,
          ),
        ),
      );
      await tester.pump();

      // Avatar rendered for message 1 (top of Maya's group) and message 3 (Amine), NOT message 2
      expect(find.byKey(const Key('chat-avatar-id_1')), findsOneWidget);
      expect(find.byKey(const Key('chat-avatar-id_2')), findsNothing);
      expect(find.byKey(const Key('chat-avatar-id_3')), findsOneWidget);
    });
  });

  group('Rule 2: Precision on Demand (Hover / Long-Press Timestamp & Date Dividers)', () {
    testWidgets('hides timestamp by default and reveals on desktop hover or mobile long-press',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatMessage(
              messageKey: 'm1',
              body: 'Low noise message',
              isMine: false,
              senderName: 'Maya',
              timestamp: '10:42 AM',
            ),
          ),
        ),
      );

      // Default: timestamp is hidden
      expect(find.text('10:42 AM'), findsNothing);

      // Desktop hover reveals timestamp
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.moveTo(tester.getCenter(find.text('Low noise message')));
      await tester.pump();
      expect(find.text('10:42 AM'), findsOneWidget);

      // Moving mouse away hides timestamp
      await mouse.moveTo(const Offset(700, 700));
      await tester.pump();
      expect(find.text('10:42 AM'), findsNothing);

      // Mobile long-press reveals timestamp
      await tester.longPress(find.text('Low noise message'));
      await tester.pump();
      expect(find.text('10:42 AM'), findsOneWidget);
    });

    testWidgets('shows date divider only when calendar date changes',
        (tester) async {
      final day1 = DateTime(2026, 11, 20, 14, 0);
      final day2 = DateTime(2026, 11, 21, 9, 30);
      final msgs = <Map<String, dynamic>>[
        {
          'id': '1',
          'is_mine': false,
          'body': 'Day 1 msg A',
          'created_at_ms': day1.millisecondsSinceEpoch,
        },
        {
          'id': '2',
          'is_mine': true,
          'body': 'Day 1 msg B',
          'created_at_ms':
              day1.add(const Duration(minutes: 5)).millisecondsSinceEpoch,
        },
        {
          'id': '3',
          'is_mine': false,
          'body': 'Day 2 msg C',
          'created_at_ms': day2.millisecondsSinceEpoch,
        },
        {
          'id': '4',
          'is_mine': true,
          'body': 'Day 2 msg D',
          'created_at_ms':
              day2.add(const Duration(minutes: 1)).millisecondsSinceEpoch,
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: ChatRoomScreen(
            conversationId: 11,
            peerName: 'Maya',
            initialMessages: msgs,
          ),
        ),
      );
      await tester.pump();

      // 4 messages across 2 days -> exactly 2 date dividers
      expect(find.byType(ChatDateDivider), findsNWidgets(2));
    });
  });

  group('Rule 3: Optimistic UI (Instant bubble, inline retry on failure, no toast, no spinner)', () {
    testWidgets('shows bubble immediately on send with no spinner, shows inline retry on failure without toast',
        (tester) async {
      final sendCompleter = Completer<ResponseBody>();
      bool shouldFail = true;

      state.api.dio = Dio(BaseOptions(baseUrl: 'https://tests.invalid'))
        ..httpClientAdapter = _TestHttpAdapter((req) {
          if (req.path == '/chat/conversations/55/messages' &&
              req.method == 'GET') {
            return _json({'status': 'success', 'messages': []});
          }
          if (req.path == '/chat/conversations/55/messages' &&
              req.method == 'POST') {
            if (!sendCompleter.isCompleted) {
              return sendCompleter.future;
            }
            if (shouldFail) {
              return _json({'status': 'error'}, 500);
            }
            return _json({
              'status': 'success',
              'message': {
                'id': 999,
                'is_mine': true,
                'body': 'Optimistic hello',
                'created_at_time': '11:00 AM',
              },
            });
          }
          return _json({'status': 'success'});
        });

      await tester.pumpWidget(
        const MaterialApp(
          home: ChatRoomScreen(
            conversationId: 55,
            peerName: 'Maya',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      await tester.enterText(
          find.byKey(const Key('chat-draft')), 'Optimistic hello');
      await tester.pump();
      await tester.tap(find.byKey(const Key('chat-send')));
      await tester.pump();

      // 1. Appears instantly before server confirmation, input cleared, no spinner
      expect(find.text('Optimistic hello'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(CupertinoActivityIndicator), findsNothing);

      // 2. Server fails -> inline Retry button on that bubble, NO SnackBar toast
      sendCompleter.complete(_json({'status': 'error'}, 500));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Optimistic hello'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);

      // 3. Tapping inline Retry button succeeds and removes Retry button
      shouldFail = false;
      await tester.tap(find.text('Retry'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Optimistic hello'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });
  });

  group('Rule 4: Scroll Anchoring ("X new messages" pill & "Jump to latest")', () {
    testWidgets('does not auto-scroll when reading history and shows "X new messages" pill with "Jump to latest"',
        (tester) async {
      tester.view.physicalSize = const Size(390, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final serverMessages = List<Map<String, dynamic>>.generate(
        40,
        (i) => {
          'id': i + 1,
          'is_mine': i.isEven,
          'body': 'History message #${i + 1}',
          'created_at_time': '10:00 AM',
        },
      );

      state.api.dio = Dio(BaseOptions(baseUrl: 'https://tests.invalid'))
        ..httpClientAdapter = _TestHttpAdapter((req) {
          if (req.path == '/chat/conversations/77/messages' &&
              req.method == 'GET') {
            return _json({'status': 'success', 'messages': serverMessages});
          }
          return _json({'status': 'success'});
        });

      await tester.pumpWidget(
        const MaterialApp(
          home: ChatRoomScreen(
            conversationId: 77,
            peerName: 'Maya',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 300));

      // Scroll up to read history (top of list)
      final scrollable = tester.widget<ListView>(
        find.byKey(const Key('chat-virtual-list')),
      );
      final scrollCtrl = scrollable.controller!;
      scrollCtrl.jumpTo(0.0);
      await tester.pump();
      expect(scrollCtrl.offset, 0.0);

      // 2 new incoming messages arrive while reading history (4s poll)
      serverMessages.addAll([
        {
          'id': 41,
          'is_mine': false,
          'body': 'New incoming 1',
          'created_at_time': '10:05 AM',
        },
        {
          'id': 42,
          'is_mine': false,
          'body': 'New incoming 2',
          'created_at_time': '10:05 AM',
        },
      ]);

      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 50));

      // Scroll stayed anchored at 0.0 (did NOT auto-scroll!)
      expect(scrollCtrl.offset, 0.0);

      // "2 new messages" pill with "Jump to latest" button is shown
      expect(find.byKey(const Key('chat-new-messages-pill')), findsOneWidget);
      expect(find.text('2 new messages'), findsOneWidget);
      expect(find.text('Jump to latest'), findsOneWidget);

      // Tapping "Jump to latest" scrolls to bottom and dismisses the pill
      await tester.tap(find.byKey(const Key('chat-new-messages-pill')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byKey(const Key('chat-new-messages-pill')), findsNothing);
      expect(scrollCtrl.offset, greaterThan(0.0));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });
  });

  group('Rule 5: Typing Indicator in Flow', () {
    test('formatLabel supports 1 and multiple typers ("Maya and 2 others are typing")', () {
      expect(ChatTypingIndicator.formatLabel([]), '');
      expect(ChatTypingIndicator.formatLabel(['Maya']), 'Maya is typing...');
      expect(
        ChatTypingIndicator.formatLabel(['Maya', 'Karim']),
        'Maya and 1 other are typing',
      );
      expect(
        ChatTypingIndicator.formatLabel(['Maya', 'Karim', 'Salma']),
        'Maya and 2 others are typing',
      );
    });

    testWidgets('renders inline in message flow attached to avatar, not in top header',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChatRoomScreen(
            conversationId: 88,
            peerName: 'Maya',
            initialMessages: [
              {
                'id': 1,
                'is_mine': false,
                'body': 'Hey!',
                'created_at_time': '10:00 AM',
              },
            ],
            initialTypingUsers: ['Maya', 'Karim', 'Salma'],
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('chat-typing-indicator-flow')), findsOneWidget);
      expect(find.byKey(const Key('chat-typing-avatar')), findsOneWidget);
      expect(find.text('Maya and 2 others are typing'), findsOneWidget);
    });
  });

  group('Rule 6: Composer Behavior (<ChatInput />)', () {
    testWidgets('auto-expands up to 5 lines, renders attachments ABOVE input, and keeps Send button always visible',
        (tester) async {
      final ctrl = TextEditingController();
      addTearDown(ctrl.dispose);

      final attachments = <ChatAttachment>[
        const ChatAttachment(
          id: 'a1',
          name: 'contract.pdf',
          type: ChatAttachmentType.file,
          subtitle: '120 KB',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: ChatInput(
                controller: ctrl,
                attachments: attachments,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // 1. Send button is visible even when text is empty
      expect(find.byKey(const Key('chat-send')), findsOneWidget);

      // 2. Attachments strip renders physically ABOVE the text input
      final attachRect =
          tester.getRect(find.byKey(const Key('chat-attachments-above')));
      final inputRect = tester.getRect(find.byKey(const Key('chat-draft')));
      expect(
        attachRect.bottom,
        lessThanOrEqualTo(inputRect.top),
        reason: 'Attachments must appear ABOVE the text input, never below',
      );

      // 3. TextField is configured with minLines: 1, maxLines: 5 and grows up to 5 lines then caps
      final tf = tester.widget<TextField>(find.byKey(const Key('chat-draft')));
      expect(tf.minLines, 1);
      expect(tf.maxLines, 5);

      final h1 = tester.getSize(find.byKey(const Key('chat-draft'))).height;
      ctrl.text = 'Line 1\nLine 2\nLine 3\nLine 4\nLine 5';
      await tester.pump();
      final h5 = tester.getSize(find.byKey(const Key('chat-draft'))).height;
      expect(h5, greaterThan(h1));

      ctrl.text = 'Line 1\nLine 2\nLine 3\nLine 4\nLine 5\nLine 6\nLine 7\nLine 8';
      await tester.pump();
      final h8 = tester.getSize(find.byKey(const Key('chat-draft'))).height;
      expect(
        h8,
        closeTo(h5, 1.0),
        reason: 'Composer must stop growing after 5 lines and scroll internally',
      );
    });
  });

  group('Performance & Accessibility: Virtual List for 1000+ Messages', () {
    testWidgets('virtualizes 1,200 messages efficiently by mounting only visible viewport items',
        (tester) async {
      final base = DateTime(2026, 11, 22, 8, 0);
      final largeHistory = List<Map<String, dynamic>>.generate(
        1200,
        (i) => {
          'id': 'msg_$i',
          'is_mine': i % 3 == 0,
          'sender_id': i % 3 == 0 ? '9' : '2',
          'sender_name': i % 3 == 0 ? 'Amine' : 'Maya',
          'body': 'Message payload #$i',
          'created_at_ms':
              base.add(Duration(seconds: i * 40)).millisecondsSinceEpoch,
          'created_at_time': '08:00',
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatRoomScreen(
            conversationId: 1000,
            peerName: 'Maya',
            initialMessages: largeHistory,
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      final mountedCount = find.byType(ChatMessage).evaluate().length;
      expect(mountedCount, greaterThan(0));
      expect(
        mountedCount,
        lessThan(35),
        reason: 'Virtual list must only build visible items out of 1,200 messages',
      );
    });
  });
}
