import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/screens/chat_room_screen.dart';
import 'package:apolo_mobile/widgets/apolo_emoji_reaction_bar.dart';
import 'package:apolo_mobile/widgets/ios26_imessage_kit.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final state = AppState();
  late Locale originalLocale;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    originalLocale = state.locale;
    await state.setLocale(const Locale('en'));
  });

  tearDown(() async {
    await state.setLocale(originalLocale);
  });

  List<Map<String, dynamic>> sampleJoshiConversation() {
    final day1 = DateTime(2026, 6, 16, 9, 38);
    final day2 = DateTime(2026, 6, 17, 12, 6);
    return <Map<String, dynamic>>[
      {
        'id': 'm_out',
        'body': 'What are you so excited about?',
        'is_mine': true,
        'sender_id': '1',
        'sender_name': 'Me',
        'type': 'text',
        'created_at_ms': day1.millisecondsSinceEpoch,
        'created_at_time': '09:38',
      },
      {
        'id': 'm_in_1',
        'body':
            "Hey there,\nI'm really into anything new, just being spontaneous and trying things out.",
        'is_mine': false,
        'sender_id': '2',
        'sender_name': 'Joshi',
        'type': 'text',
        'created_at_ms': day2.millisecondsSinceEpoch,
        'created_at_time': '12:06',
      },
      {
        'id': 'm_in_2',
        'body': 'How about you?',
        'is_mine': false,
        'sender_id': '2',
        'sender_name': 'Joshi',
        'type': 'text',
        'created_at_ms': day2.add(const Duration(seconds: 25)).millisecondsSinceEpoch,
        'created_at_time': '12:06',
      },
    ];
  }

  testWidgets(
    'ChatRoomScreen matches Dynamic Layer v5.1 (47281:3598): start-aligned verified header, #000000/#EEEEEE 16px bubbles, bottom-of-group peer avatar',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: ChatRoomScreen(
            conversationId: 301,
            peerId: 2,
            peerName: 'Joshi',
            isPeerVerified: true,
            initialMessages: sampleJoshiConversation(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header: start-aligned avatar + Joshi + verified badge between < and •••
      expect(find.byKey(const Key('chat-header-verified-badge')), findsOneWidget);
      final backRight =
          tester.getTopRight(find.byKey(const Key('chat-ios26-back-button'))).dx;
      final avatarLeft =
          tester.getTopLeft(find.byKey(const Key('chat-ios26-avatar-glass'))).dx;
      expect(avatarLeft - backRight, closeTo(12.0, 1.0));

      // Design tokens match Figma 47281:3598
      expect(Ios26IMessageTokens.bubbleMine, const Color(0xFF000000));
      expect(Ios26IMessageTokens.bubbleOther, const Color(0xFFEEEEEE));
      expect(Ios26IMessageTokens.bubbleRadius, 16.0);

      // Incoming group shows peer avatar ONLY on last message (`How about you?`), none on outgoing
      expect(find.byKey(const Key('chat-avatar-id_m_out')), findsNothing);
      expect(find.byKey(const Key('chat-avatar-id_m_in_1')), findsNothing);
      expect(find.byKey(const Key('chat-avatar-id_m_in_2')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Double-tap (2 clicks) on a message adds ❤️ heart reaction and double-tapping again toggles it off',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: ChatRoomScreen(
            conversationId: 302,
            peerName: 'Joshi',
            initialMessages: sampleJoshiConversation(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ios26-tapback-badge')), findsNothing);

      final targetBubble = find.byKey(const Key('chat-bubble-id_m_in_2'));
      expect(targetBubble, findsOneWidget);

      // Double tap -> adds ❤️ reaction + burst animation
      await tester.tap(targetBubble);
      await tester.pump(kDoubleTapMinTime);
      await tester.tap(targetBubble);
      await tester.pump(const Duration(milliseconds: 60));

      expect(
        find.byKey(const Key('chat-double-tap-heart-id_m_in_2')),
        findsOneWidget,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ios26-tapback-badge')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('ios26-tapback-badge')),
          matching: find.text('❤️'),
        ),
        findsOneWidget,
      );

      // Double tap again -> removes ❤️ reaction
      await tester.tap(targetBubble);
      await tester.pump(kDoubleTapMinTime);
      await tester.tap(targetBubble);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ios26-tapback-badge')), findsNothing);
    },
  );

  testWidgets(
    'Long-press on iOS shows iOS emoji row (Apple Color Emoji) and reacts on tap',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: ChatRoomScreen(
            conversationId: 303,
            peerName: 'Joshi',
            initialMessages: sampleJoshiConversation(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.byKey(const Key('chat-bubble-id_m_out')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('apolo-emoji-reaction-bar')), findsOneWidget);
      for (final emoji in ApoloPlatformEmoji.iosQuickReactions) {
        expect(find.byKey(Key('chat-reaction-emoji-$emoji')), findsOneWidget);
      }
      final laughText = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const Key('chat-reaction-emoji-😂')),
          matching: find.text('😂'),
        ),
      );
      expect(laughText.style?.fontFamily, 'Apple Color Emoji');

      await tester.tap(find.byKey(const Key('chat-reaction-emoji-😂')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ios26-tapback-badge')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('ios26-tapback-badge')),
          matching: find.text('😂'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Long-press on Android shows Android emoji row (Noto Color Emoji) and + expands extended palette',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: ChatRoomScreen(
            conversationId: 304,
            peerName: 'Joshi',
            initialMessages: sampleJoshiConversation(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.byKey(const Key('chat-bubble-id_m_in_1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('apolo-emoji-reaction-bar')), findsOneWidget);
      for (final emoji in ApoloPlatformEmoji.androidQuickReactions) {
        expect(find.byKey(Key('chat-reaction-emoji-$emoji')), findsOneWidget);
      }
      final prayText = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const Key('chat-reaction-emoji-🙏')),
          matching: find.text('🙏'),
        ),
      );
      expect(prayText.style?.fontFamily, 'Noto Color Emoji');

      // Tap `+` button to expand full emoji tray
      await tester.tap(find.byKey(const Key('chat-reaction-more-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-reaction-extended-grid')), findsOneWidget);

      await tester.tap(find.byKey(const Key('chat-reaction-emoji-🔥')));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('ios26-tapback-badge')),
          matching: find.text('🔥'),
        ),
        findsOneWidget,
      );
    },
  );
}
