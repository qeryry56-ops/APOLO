import 'dart:math' as math;

import 'package:apolo_mobile/core/services/chat_realtime_client.dart';
import 'package:apolo_mobile/features/chat/models/chat_ack_models.dart';
import 'package:apolo_mobile/features/chat/state/chat_ack_notifier_registry.dart';
import 'package:apolo_mobile/features/chat/theme/apolo_chat_dl_tokens.dart';
import 'package:apolo_mobile/features/chat/widgets/chat_ack_indicator.dart';
import 'package:apolo_mobile/screens/chat_room_screen.dart';
import 'package:apolo_mobile/widgets/ios26_imessage_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Zero-Polling Persistent WebSocket Reconnect Backoff', () {
    test('computeReconnectDelayMs grows exponentially with bounded jitter (1s..30s)', () {
      final rng = math.Random(42);
      final d1 = ChatRealtimeClient.computeReconnectDelayMs(1, random: rng);
      final d2 = ChatRealtimeClient.computeReconnectDelayMs(2, random: rng);
      final d4 = ChatRealtimeClient.computeReconnectDelayMs(4, random: rng);
      final d6 = ChatRealtimeClient.computeReconnectDelayMs(6, random: rng);

      expect(d1, inInclusiveRange(1000, 1300));
      expect(d2, inInclusiveRange(2000, 2600));
      expect(d4, inInclusiveRange(8000, 10500));
      expect(d6, lessThanOrEqualTo(30000));
    });
  });

  group('3-Stage WhatsApp-Style Message ACK Registry (Zero-Jitter ValueNotifier)', () {
    test('transitions monotonically sending -> sent -> delivered -> read and never downgrades', () {
      final registry = ChatAckNotifierRegistry();
      addTearDown(registry.dispose);

      final listenable = registry.listenableFor(
        'opt_1',
        initial: ChatAckStatus.sending,
      );
      final observed = <ChatAckStatus>[listenable.value];
      listenable.addListener(() => observed.add(listenable.value));

      // Stage 1: Server ACK (`sent` ✓)
      registry.applyServerAck(
        clientMessageId: 'opt_1',
        serverMessageId: '900001',
      );
      expect(listenable.value, ChatAckStatus.sent);

      // Stage 2: Recipient Device ACK (`delivered` ✓✓)
      registry.applyReceipt(
        status: ChatAckStatus.delivered,
        messageIds: const ['900001'],
      );
      expect(listenable.value, ChatAckStatus.delivered);

      // Stage 3: Active Conversation Read ACK (`read` ✓✓ highlighted)
      registry.applyReceipt(
        status: ChatAckStatus.read,
        upToMessageId: '900005',
      );
      expect(listenable.value, ChatAckStatus.read);

      // Out-of-order delayed `delivered` packet must NOT downgrade `read`
      registry.applyReceipt(
        status: ChatAckStatus.delivered,
        messageIds: const ['900001'],
      );
      expect(listenable.value, ChatAckStatus.read);
      expect(
        observed,
        [
          ChatAckStatus.sending,
          ChatAckStatus.sent,
          ChatAckStatus.delivered,
          ChatAckStatus.read,
        ],
      );
    });

    testWidgets('ChatAckIndicator repaints only the tick icon on live ACK updates', (tester) async {
      final registry = ChatAckNotifierRegistry();
      addTearDown(registry.dispose);

      final listenable = registry.listenableFor(
        'm_live',
        initial: ChatAckStatus.sent,
        serverMessageId: '5001',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatAckIndicator(statusListenable: listenable),
          ),
        ),
      );

      // Single gray checkmark (Server ACK)
      final sentIcon = tester.widget<Icon>(find.byType(Icon));
      expect(sentIcon.icon, Icons.done_rounded);
      expect(sentIcon.color, ApoloChatDlTokens.ackSentColor);

      // Flip to Delivered (Double gray checkmarks)
      registry.applyReceipt(
        status: ChatAckStatus.delivered,
        messageIds: const ['5001'],
      );
      await tester.pump();
      final delivIcon = tester.widget<Icon>(find.byType(Icon));
      expect(delivIcon.icon, Icons.done_all_rounded);
      expect(delivIcon.color, ApoloChatDlTokens.ackDeliveredColor);

      // Flip to Read (Double Apolo Red #E31B23 checkmarks)
      registry.applyReceipt(
        status: ChatAckStatus.read,
        upToMessageId: '5001',
      );
      await tester.pump();
      final readIcon = tester.widget<Icon>(find.byType(Icon));
      expect(readIcon.icon, Icons.done_all_rounded);
      expect(readIcon.color, ApoloChatDlTokens.primaryRed);
    });
  });

  group('Dynamic Layer v5.1 Chat Colors (#0D8BFF / #EEEEEE / #FFFFFF) & RTL ChatRoomScreen', () {
    testWidgets('uses #0D8BFF outgoing bubbles + #EEEEEE incoming + #FFFFFF canvas with 3-stage ACK ticks in Arabic RTL',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      expect(Ios26IMessageTokens.bubbleMine, const Color(0xFF0D8BFF));
      expect(Ios26IMessageTokens.bubbleOther, const Color(0xFFEEEEEE));
      expect(Ios26IMessageTokens.bubbleMineText, const Color(0xFFFFFFFF));
      expect(Ios26IMessageTokens.canvasWhite, const Color(0xFFFFFFFF));

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: ChatRoomScreen(
              conversationId: 88,
              peerName: 'تاجر الدار البيضاء',
              adTitle: 'iPhone 16 Pro Max 256GB',
              adPrice: '13 500 DH',
              initialMessages: [
                {
                  'id': '1001',
                  'message_id': '1001',
                  'body': 'السلام عليكم، واش باقي متوفر؟',
                  'is_mine': true,
                  'ack_status': 'sent',
                  'created_at_time': '10:01',
                },
                {
                  'id': '1002',
                  'message_id': '1002',
                  'body': 'بغيت نشوفو اليوم فـ المعاريف',
                  'is_mine': true,
                  'ack_status': 'delivered',
                  'delivered': true,
                  'created_at_time': '10:02',
                },
                {
                  'id': '1003',
                  'message_id': '1003',
                  'body': 'مرحباً، متفقين على 13 500 DH؟',
                  'is_mine': true,
                  'ack_status': 'read',
                  'read': true,
                  'created_at_time': '10:03',
                },
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('chat-ack-tick-id_1001')), findsOneWidget);
      expect(find.byKey(const Key('chat-ack-tick-id_1002')), findsOneWidget);
      expect(find.byKey(const Key('chat-ack-tick-id_1003')), findsOneWidget);

      // Verify listing price uses Dynamic Layer Chat Blue (#0D8BFF)
      final priceText = tester.widget<Text>(
        find.byKey(const Key('chat-ad-context-price')),
      );
      expect(priceText.style?.color, const Color(0xFF0D8BFF));
    });
  });
}
