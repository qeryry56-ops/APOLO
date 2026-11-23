import 'package:apolo_mobile/core/services/chat_realtime_client.dart';
import 'package:apolo_mobile/screens/chat_room_screen.dart';
import 'package:apolo_mobile/widgets/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
      expect(find.byKey(const Key('chat-attach-button')), findsOneWidget);
      expect(find.byKey(const Key('chat-draft')), findsOneWidget);

      // Clean presence status subtitle (does not fake online when no presence event arrived)
      expect(find.byKey(const Key('chat-peer-presence-text')), findsOneWidget);

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
}
