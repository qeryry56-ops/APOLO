import 'package:apolo_mobile/core/services/chat_realtime_client.dart';
import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/screens/chat_room_screen.dart';
import 'package:apolo_mobile/widgets/chat_message.dart';
import 'package:apolo_mobile/widgets/ios26_imessage_kit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('ChatMessage.detectTextDirection handles Arabic RTL and Latin LTR cleanly', () {
    expect(
      ChatMessage.detectTextDirection('السلام عليكم، واش الساعة متوفرة؟'),
      TextDirection.rtl,
    );
    expect(
      ChatMessage.detectTextDirection('Tissot watch black'),
      TextDirection.ltr,
    );
    expect(
      ChatMessage.detectTextDirection('DH 110.00', fallback: TextDirection.ltr),
      TextDirection.ltr,
    );
  });

  test('ChatRealtimeClient.deduplicateMessages prevents duplicates by client_message_id and message_id', () {
    final merged = ChatRealtimeClient.deduplicateMessages([
      {'message_id': '1001', 'client_message_id': 'c-1', 'body': 'First'},
      {'message_id': '1001', 'client_message_id': 'c-1', 'body': 'First dup'},
      {'id': 'opt-1', 'client_message_id': 'c-1', 'body': 'Pending dup'},
      {'message_id': '1002', 'client_message_id': 'c-2', 'body': 'Second'},
    ]);

    expect(merged.length, 2);
    expect(merged[0]['body'], 'First');
    expect(merged[1]['body'], 'Second');
  });

  testWidgets(
    'ChatRoomScreen renders listing banner (Tissot watch black / DH 110.00), sender/receiver bubbles, and clean presence',
    (tester) async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: ChatRoomScreen(
              conversationId: 1,
              adId: 5501,
              peerId: 202,
              peerName: 'أمين',
              adTitle: 'Tissot watch black',
              adPrice: 'DH 110.00',
              initialMessages: [
                {
                  'id': 'm1',
                  'message_id': '1001',
                  'client_message_id': 'c-1',
                  'body': 'السلام عليكم، واش الساعة باقية؟',
                  'is_mine': true,
                  'sender_id': '101',
                  'sender_name': 'Me',
                  'type': 'text',
                  'read': true,
                  'created_at_ms': yesterday.millisecondsSinceEpoch,
                  'created_at_time': '21:10',
                },
                {
                  'id': 'm2',
                  'message_id': '1002',
                  'client_message_id': 'c-2',
                  'body': 'Yes, Tissot watch black is available!',
                  'is_mine': false,
                  'sender_id': '202',
                  'sender_name': 'أمين',
                  'type': 'text',
                  'read': true,
                  'created_at_ms': now.millisecondsSinceEpoch,
                  'created_at_time': '10:15',
                },
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Listing context banner present with exact title & LTR price
      expect(find.byKey(const Key('chat-ad-context-banner')), findsOneWidget);
      expect(find.text('Tissot watch black'), findsOneWidget);
      expect(find.byKey(const Key('chat-ad-context-price')), findsOneWidget);
      expect(find.text('DH 110.00'), findsOneWidget);

      // iOS 26 iMessage floating Liquid Glass controls & composer
      expect(find.byKey(const Key('chat-ios26-back-button')), findsOneWidget);
      expect(find.byKey(const Key('chat-ios26-call-button')), findsOneWidget);
      expect(find.byKey(const Key('chat-ios26-avatar-glass')), findsOneWidget);
      expect(find.byKey(const Key('chat-ios26-name-pill')), findsOneWidget);
      expect(find.byKey(const Key('chat-attach-button')), findsOneWidget);
      expect(find.byKey(const Key('chat-draft')), findsOneWidget);

      // Tapping Video Call button reveals presence status & video/voice/safety options
      await tester.tap(find.byKey(const Key('chat-ios26-call-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-peer-presence-text')), findsOneWidget);
      await tester.tap(find.byKey(const Key('chat-ios26-call-button')));
      await tester.pumpAndSettle();

      // Sender and receiver bubbles rendered distinctly
      expect(find.text('السلام عليكم، واش الساعة باقية؟'), findsOneWidget);
      expect(find.text('Yes, Tissot watch black is available!'), findsOneWidget);

      // Tap '+' opens iOS 26 Half-Height Liquid Glass Apps & Stickers Drawer
      await tester.tap(find.byKey(const Key('chat-attach-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ios26-imessage-drawer')), findsOneWidget);
      expect(find.byKey(const Key('ios26-app-photos')), findsOneWidget);
      expect(find.byKey(const Key('ios26-app-camera')), findsOneWidget);
      expect(find.byKey(const Key('ios26-app-stickers')), findsOneWidget);
      expect(find.byKey(const Key('ios26-app-offer')), findsOneWidget);

      // Switch to 3-column Sticker Pack Grid
      await tester.tap(find.byKey(const Key('ios26-drawer-tab-stickers')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ios26-sticker-salam')), findsOneWidget);
      expect(find.byKey(const Key('ios26-sticker-deal')), findsOneWidget);
    },
  );

  testWidgets(
    'Native iOS refactor: embedded scrollable ad card, clipped frosted header, inline image bubble without raw filename, and iOS voice capsule',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      // Valid 1x1 transparent PNG base64
      const tinyPngBase64 =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
      // Ensure English strings so "Delivered" label is verified directly
      await tester.runAsync(() => AppState().setLocale(const Locale('en')));
      addTearDown(
        () => tester.runAsync(() => AppState().setLocale(const Locale('ar'))),
      );

      final now = DateTime.now();
      final messages = <Map<String, dynamic>>[
        {
          'id': 'img_1',
          'body': 'scaled_IMG_0865.png',
          'type': 'image',
          'image_base64': tinyPngBase64,
          'is_mine': true,
          'sender_id': '101',
          'sender_name': 'Me',
          'read': false,
          'created_at_ms': now.millisecondsSinceEpoch,
          'created_at_time': '10:20',
        },
        for (int i = 0; i < 18; i++)
          {
            'id': 'm_$i',
            'body': 'Conversation message #$i to make list scrollable',
            'is_mine': i.isEven,
            'sender_id': i.isEven ? '101' : '202',
            'sender_name': i.isEven ? 'Me' : 'Amine',
            'type': 'text',
            'created_at_ms':
                now.add(Duration(minutes: i + 1)).millisecondsSinceEpoch,
            'created_at_time': '10:${(21 + i).toString().padLeft(2, '0')}',
          },
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: ChatRoomScreen(
            conversationId: 77,
            adId: 5501,
            peerId: 202,
            peerName: 'Amine',
            adTitle: 'Tissot watch black',
            adPrice: '110.00 DH',
            initialMessages: messages,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // 1. Product card is embedded inside the scrollable ListView (NOT sticky under header)
      final adBannerFinder = find.byKey(const Key('chat-ad-context-banner'));
      final listFinder = find.byKey(const Key('chat-virtual-list'));
      expect(
        find.descendant(of: listFinder, matching: adBannerFinder),
        findsOneWidget,
      );
      final adTopBeforeScroll = tester.getTopLeft(adBannerFinder).dy;

      // 2. Exact Figma `1:2` White Header Gradient Overlay (`0%: 2% -> 26.504%: 70% -> 61.221%: 90% -> 100%: 100%`)
      expect(find.byType(Ios26HeaderGradientOverlay), findsOneWidget);
      final gradientBox = tester.widget<DecoratedBox>(
        find.byKey(const Key('ios26-header-gradient-box')),
      );
      final gradientDeco = gradientBox.decoration as BoxDecoration;
      final headerGrad = gradientDeco.gradient! as LinearGradient;
      expect(headerGrad.colors, Ios26IMessageTokens.headerGradientColors);
      expect(headerGrad.stops, Ios26IMessageTokens.headerGradientStops);

      // 3. Inline image bubble renders actual image with 18px radius, hides raw `scaled_IMG_0865.png`, and shows "Delivered"
      expect(find.byKey(const Key('chat-image-bubble-id_img_1')), findsOneWidget);
      expect(find.text('scaled_IMG_0865.png'), findsNothing);
      expect(find.byKey(const Key('chat-status-id_img_1')), findsOneWidget);
      expect(find.text('Delivered'), findsWidgets);

      // Verify embedded ad card scrolls away naturally when scrolling down the chat
      await tester.drag(listFinder, const Offset(0, -420));
      await tester.pumpAndSettle();
      if (adBannerFinder.evaluate().isNotEmpty) {
        expect(tester.getTopLeft(adBannerFinder).dy, lessThan(adTopBeforeScroll));
      }

      // 4. Native iOS Voice Message Capsule (tap mic -> ✕ cancel, Play/Pause, wave bars, timer, blue ↑ Send)
      await tester.tap(find.byKey(const Key('voice-recorder-mic-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byKey(const Key('chat-draft')), findsNothing);
      expect(find.byKey(const Key('voice-recorder-active-bar')), findsOneWidget);
      expect(find.byKey(const Key('voice-recorder-locked-cancel-button')), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.xmark), findsOneWidget);
      expect(find.byKey(const Key('voice-recorder-play-pause-button')), findsOneWidget);
      expect(find.byKey(const Key('voice-recorder-waveform')), findsOneWidget);
      expect(find.byKey(const Key('voice-recorder-timer')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('voice-recorder-stop-button')),
          matching: find.byIcon(CupertinoIcons.arrow_up),
        ),
        findsOneWidget,
      );

      // Toggle Play/Pause preview cleanly & close via ✕
      await tester.tap(find.byKey(const Key('voice-recorder-play-pause-button')));
      await tester.pump();
      expect(find.byIcon(CupertinoIcons.play_fill), findsOneWidget);

      await tester.tap(find.byKey(const Key('voice-recorder-locked-cancel-button')));
      await tester.pump();
      expect(find.byKey(const Key('chat-draft')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
