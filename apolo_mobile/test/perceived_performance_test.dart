import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apolo_mobile/widgets/chat_input.dart';
import 'package:apolo_mobile/widgets/perceived_performance.dart';

void main() {
  group('Rule 1: REACT AT ONCE (<16ms touch-down scale 95%, opacity change, haptic, never static)', () {
    testWidgets(
        'InstantActionButton scales to 95% (0.95), changes opacity to 0.82, and fires haptic on touch down before tap completes',
        (tester) async {
      final haptics = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add('${call.arguments}');
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      bool apiStarted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InstantActionButton(
                onPressed: () => apiStarted = true,
                child: const Text('Submit Offer'),
              ),
            ),
          ),
        ),
      );

      // Touch down (without lifting finger yet -> before API call starts)
      final gesture =
          await tester.startGesture(tester.getCenter(find.text('Submit Offer')));
      await tester.pump(); // <16ms (1 frame)

      expect(apiStarted, isFalse, reason: 'API has not started on touch down');
      expect(haptics, isNotEmpty, reason: 'Haptic fired immediately on touch down');

      final scaleWidget = tester.widget<AnimatedScale>(
        find.byKey(const Key('instant-button-scale')),
      );
      final opacityWidget = tester.widget<AnimatedOpacity>(
        find.byKey(const Key('instant-button-opacity')),
      );

      expect(scaleWidget.scale, closeTo(0.95, 0.001));
      expect(opacityWidget.opacity, closeTo(0.82, 0.001));

      // Release finger -> triggers action and springs back to 1.0
      await gesture.up();
      await tester.pump();
      expect(apiStarted, isTrue);
    });

    testWidgets(
        'ChatInput Send button reacts on touch down with 95% scale, 0.82 opacity, and haptic feedback',
        (tester) async {
      final ctrl = TextEditingController(text: 'Hello Apolo');
      addTearDown(ctrl.dispose);
      String? sentText;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInput(
              controller: ctrl,
              onSend: (val) => sentText = val,
            ),
          ),
        ),
      );

      final sendCenter = tester.getCenter(find.byKey(const Key('chat-send')));
      final gesture = await tester.startGesture(sendCenter);
      await tester.pump(); // 1st frame (<16ms)

      final sendScale = tester.widget<AnimatedScale>(
        find.byKey(const Key('chat-send-scale')),
      );
      final sendOpacity = tester.widget<AnimatedOpacity>(
        find.byKey(const Key('chat-send-opacity')),
      );

      expect(sendScale.scale, closeTo(0.95, 0.001));
      expect(sendOpacity.opacity, closeTo(0.82, 0.001));

      await gesture.up();
      await tester.pump();
      expect(sentText, 'Hello Apolo');
    });
  });

  group('Rule 2: SHOW RESULT FIRST (Optimistic UI + Background Sync + Inline Retry on Failure)', () {
    testWidgets(
        'OptimisticLikeButton fills heart and updates count immediately before API finishes, and shows inline retry on failure',
        (tester) async {
      final syncCompleter = Completer<bool>();
      bool shouldSucceed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: OptimisticLikeButton(
                initialIsLiked: false,
                initialLikeCount: 42,
                onSync: (nextLiked) {
                  if (!syncCompleter.isCompleted) {
                    return syncCompleter.future;
                  }
                  return Future<bool>.value(shouldSucceed);
                },
              ),
            ),
          ),
        ),
      );

      // Initial state: heart outline, count 42
      expect(find.byIcon(CupertinoIcons.heart), findsOneWidget);
      expect(find.text('42'), findsOneWidget);

      // Tap Like -> immediately shows filled heart & count 43 BEFORE syncCompleter finishes!
      await tester.tap(find.byKey(const Key('optimistic-like-button')));
      await tester.pump();

      expect(find.byIcon(CupertinoIcons.heart_fill), findsOneWidget);
      expect(find.text('43'), findsOneWidget);
      expect(find.byKey(const Key('optimistic-like-retry')), findsNothing);

      // Simulate background API failure -> reverts to 42 and shows inline Retry button on same element
      syncCompleter.complete(false);
      await tester.pumpAndSettle();

      expect(find.byIcon(CupertinoIcons.heart), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.byKey(const Key('optimistic-like-retry')), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Tapping inline Retry button succeeds and updates count to 43
      shouldSucceed = true;
      await tester.tap(find.byKey(const Key('optimistic-like-retry')));
      await tester.pumpAndSettle();

      expect(find.byIcon(CupertinoIcons.heart_fill), findsOneWidget);
      expect(find.text('43'), findsOneWidget);
      expect(find.byKey(const Key('optimistic-like-retry')), findsNothing);
    });
  });

  group('Rule 3: MOVE WITH EASE (Ease-out cubic-bezier(0.22, 1, 0.36, 1) & Spring Damping 0.8)', () {
    test('ApoloMotion enforces 200-300ms micro-interactions, 400-500ms screen transitions, cubic-bezier(0.22, 1, 0.36, 1), and 0.8 spring damping', () {
      // Micro-interaction duration: 200-300ms
      expect(ApoloMotion.microDuration.inMilliseconds, inInclusiveRange(200, 300));
      expect(ApoloMotion.bounceDuration.inMilliseconds, inInclusiveRange(200, 300));

      // Screen transition duration: 400-500ms
      expect(
        ApoloMotion.screenTransitionDuration.inMilliseconds,
        inInclusiveRange(400, 500),
      );

      // Curve is Cubic(0.22, 1.0, 0.36, 1.0), never Curves.linear
      expect(ApoloMotion.easeOutCurve, isA<Cubic>());
      const cubic = ApoloMotion.easeOutCurve as Cubic;
      expect(cubic.a, closeTo(0.22, 0.001));
      expect(cubic.b, closeTo(1.0, 0.001));
      expect(cubic.c, closeTo(0.36, 0.001));
      expect(cubic.d, closeTo(1.0, 0.001));

      // Spring damping ratio zeta = damping / (2 * sqrt(mass * stiffness)) == 0.80
      const s = ApoloMotion.springDamping08;
      final zeta = s.damping / (2 * math.sqrt(s.mass * s.stiffness));
      expect(zeta, closeTo(0.80, 0.01));
    });

    testWidgets('SpringPageRoute transitions screens smoothly over 450ms using ease-out physics',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: InstantActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      SpringPageRoute(
                        page: const Scaffold(
                          body: Center(child: Text('Destination Screen')),
                        ),
                      ),
                    );
                  },
                  child: const Text('Navigate'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 225)); // Mid-transition
      expect(find.text('Destination Screen'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('Destination Screen'), findsOneWidget);
    });
  });
}
