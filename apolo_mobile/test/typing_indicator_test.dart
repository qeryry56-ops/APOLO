import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apolo_mobile/widgets/typing_indicator.dart';

void main() {
  group('TypingIndicatorController — Core Logic, Edge Cases & Performance', () {
    test(
        'debounces start signal (1.2s), emits {typing: true} only once on first keystroke, and suppresses rapid type+delete spam',
        () async {
      final emitted = <Map<String, dynamic>>[];
      DateTime fakeNow = DateTime(2026, 11, 23, 10, 0, 0);

      final ctrl = TypingIndicatorController(
        onEmit: emitted.add,
        startDebounce: const Duration(milliseconds: 1200),
        inactivityTimeout: const Duration(seconds: 4),
        throttleInterval: const Duration(seconds: 2),
        clock: () => fakeNow,
      );

      // Rapid type and delete within debounce window -> ZERO emits
      ctrl.onTextChanged('h');
      await Future<void>.delayed(const Duration(milliseconds: 200));
      ctrl.onTextChanged('');
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      expect(emitted, isEmpty);

      // Type multiple characters -> emits {typing: true} ONLY ONCE after 1.2s debounce
      ctrl.onTextChanged('H');
      await Future<void>.delayed(const Duration(milliseconds: 300));
      ctrl.onTextChanged('He');
      await Future<void>.delayed(const Duration(milliseconds: 300));
      ctrl.onTextChanged('Hel');
      await Future<void>.delayed(const Duration(milliseconds: 700));
      expect(emitted, [
        {'typing': true}
      ]);

      // Subsequent keystrokes while already typing must NOT emit again
      fakeNow = fakeNow.add(const Duration(seconds: 3));
      ctrl.onTextChanged('Hell');
      ctrl.onTextChanged('Hello');
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(emitted.length, 1);

      // Sending message immediately emits {typing: false}
      ctrl.onMessageSent();
      expect(emitted, [
        {'typing': true},
        {'typing': false},
      ]);

      ctrl.dispose();
    });

    test('auto-sends {typing: false} after inactivity timeout when user types 1 letter and puts phone down',
        () async {
      final emitted = <Map<String, dynamic>>[];
      DateTime fakeNow = DateTime(2026, 11, 23, 10, 0, 0);

      final ctrl = TypingIndicatorController(
        onEmit: emitted.add,
        startDebounce: const Duration(milliseconds: 150),
        inactivityTimeout: const Duration(milliseconds: 500),
        throttleInterval: const Duration(milliseconds: 100),
        clock: () => fakeNow,
      );

      ctrl.onTextChanged('a');
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(emitted, [
        {'typing': true}
      ]);

      fakeNow = fakeNow.add(const Duration(seconds: 4));
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(emitted, [
        {'typing': true},
        {'typing': false},
      ]);

      ctrl.dispose();
    });

    test('sends {typing: false} immediately when user navigates away from chat',
        () async {
      final emitted = <Map<String, dynamic>>[];
      final ctrl = TypingIndicatorController(
        onEmit: emitted.add,
        startDebounce: const Duration(milliseconds: 100),
        inactivityTimeout: const Duration(seconds: 4),
      );

      ctrl.onTextChanged('typing...');
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(emitted, [
        {'typing': true}
      ]);

      ctrl.onLeaveChat();
      expect(emitted, [
        {'typing': true},
        {'typing': false},
      ]);

      ctrl.dispose();
    });

    test('never broadcasts typing status to groups with 100+ members', () async {
      final emitted = <Map<String, dynamic>>[];
      final ctrl = TypingIndicatorController(
        onEmit: emitted.add,
        memberCount: 100,
        startDebounce: const Duration(milliseconds: 50),
      );

      expect(ctrl.isAllowedForGroup, isFalse);
      ctrl.onTextChanged('Hello large group');
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(emitted, isEmpty);

      ctrl.dispose();
    });

    test('throttles typing events to max 1 per 2 seconds per user', () async {
      final emitted = <Map<String, dynamic>>[];
      DateTime fakeNow = DateTime(2026, 11, 23, 10, 0, 0);

      final ctrl = TypingIndicatorController(
        onEmit: emitted.add,
        startDebounce: const Duration(milliseconds: 50),
        inactivityTimeout: const Duration(seconds: 4),
        throttleInterval: const Duration(seconds: 2),
        clock: () => fakeNow,
      );

      ctrl.onTextChanged('Hi');
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(emitted.length, 1);
      expect(emitted.first, {'typing': true});

      // Immediately deleting text within < 2s throttle window does NOT fire a second event right away
      fakeNow = fakeNow.add(const Duration(milliseconds: 400));
      ctrl.onTextChanged('');
      expect(emitted.length, 1);

      ctrl.dispose();
    });
  });

  group('TypingIndicatorBubble & TypingIndicatorDots — UI Display', () {
    testWidgets(
        'renders 3 sequentially fading dots on 1.5s loop when isTyping=true and hides immediately on isTyping=false or timeout',
        (tester) async {
      bool isTyping = true;
      late StateSetter outerSetState;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                outerSetState = setState;
                return TypingIndicatorBubble(
                  isTyping: isTyping,
                  label: 'Amine is typing...',
                  autoHideTimeout: const Duration(seconds: 4),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('typing-indicator-bubble')), findsOneWidget);
      expect(find.byKey(const Key('typing-dot-0')), findsOneWidget);
      expect(find.byKey(const Key('typing-dot-1')), findsOneWidget);
      expect(find.byKey(const Key('typing-dot-2')), findsOneWidget);

      // Verify 1.5s loop animates dots sequentially
      await tester.pump(const Duration(milliseconds: 350));
      final dot0 = tester.widget<Opacity>(find.byKey(const Key('typing-dot-0')));
      final dot2 = tester.widget<Opacity>(find.byKey(const Key('typing-dot-2')));
      expect(dot0.opacity, greaterThan(dot2.opacity));

      // Hide immediately when receiving {typing: false}
      outerSetState(() => isTyping = false);
      await tester.pump();
      expect(find.byKey(const Key('typing-indicator-bubble')), findsNothing);

      // Re-enable and verify auto-hide on timeout
      outerSetState(() => isTyping = true);
      await tester.pump();
      expect(find.byKey(const Key('typing-indicator-bubble')), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      expect(find.byKey(const Key('typing-indicator-bubble')), findsNothing);
    });
  });
}
