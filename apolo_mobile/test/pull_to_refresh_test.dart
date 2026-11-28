import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apolo_mobile/widgets/pull_to_refresh.dart';

void main() {
  group('Rule 1 & Rule 2: 85px Threshold & Elastic Resistance (drag_distance = pull_distance * 0.5)', () {
    testWidgets(
        'pulling < 85px snaps back without reload; pulling >= 85px applies 0.5x elastic resistance and triggers refresh',
        (tester) async {
      int refreshCount = 0;
      final stateKey = GlobalKey<PullToRefreshState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PullToRefresh(
              key: stateKey,
              onRefresh: () async {
                refreshCount++;
              },
              child: ListView.builder(
                itemCount: 25,
                itemBuilder: (_, i) => ListTile(title: Text('Inbox Item #$i')),
              ),
            ),
          ),
        ),
      );

      // 1. Pull down 60px (< 85px threshold):
      // drag_distance = 60 * 0.5 = 30px; releasing snaps back with NO reload
      final center = tester.getCenter(find.byType(ListView));
      final gesture1 = await tester.startGesture(center);
      await gesture1.moveBy(const Offset(0, 60));
      await tester.pump();

      expect(stateKey.currentState!.pullDistance, closeTo(60.0, 0.01));
      expect(
        stateKey.currentState!.dragDistance,
        closeTo(30.0, 0.01),
        reason: 'Rule 2: drag_distance = pull_distance * 0.5 (60 * 0.5 = 30)',
      );
      expect(stateKey.currentState!.hasCrossedThreshold, isFalse);

      await gesture1.up();
      await tester.pumpAndSettle();

      expect(refreshCount, 0, reason: 'Rule 1: No reload before 85px threshold');
      expect(stateKey.currentState!.dragDistance, closeTo(0.0, 0.5));

      // 2. Pull down 120px (>= 85px threshold):
      // drag_distance = 120 * 0.5 = 60px; releasing triggers reload
      final gesture2 = await tester.startGesture(center);
      await gesture2.moveBy(const Offset(0, 120));
      await tester.pump();

      expect(stateKey.currentState!.pullDistance, closeTo(120.0, 0.01));
      expect(
        stateKey.currentState!.dragDistance,
        closeTo(60.0, 0.01),
        reason: 'Rule 2: drag_distance = pull_distance * 0.5 (120 * 0.5 = 60)',
      );
      expect(stateKey.currentState!.hasCrossedThreshold, isTrue);

      await gesture2.up();
      await tester.pumpAndSettle();

      expect(refreshCount, 1, reason: 'Rule 1: Reload triggered past 85px threshold');
    });
  });

  group('Rule 3 & Rule 4: Seamless Handoff & Pre-Release Haptic at 85px Threshold', () {
    testWidgets(
        'fires haptic tick the instant pull crosses 85px BEFORE finger is released and keeps same spinner element',
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

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PullToRefresh(
              onRefresh: () async {},
              child: ListView(
                children: const [ListTile(title: Text('Message 1'))],
              ),
            ),
          ),
        ),
      );

      final gesture =
          await tester.startGesture(tester.getCenter(find.byType(ListView)));

      // Pull 70px (< 85px): indicator visible, no threshold haptic yet
      await gesture.moveBy(const Offset(0, 70));
      await tester.pump();
      expect(find.byKey(const Key('pull-to-refresh-indicator')), findsOneWidget);
      expect(haptics, isEmpty);

      final indicatorElementBefore = tester
          .element(find.byKey(const Key('pull-to-refresh-spinner')));

      // Pull another 25px (total 95px >= 85px) while finger is STILL HELD DOWN:
      await gesture.moveBy(const Offset(0, 25));
      await tester.pump();

      // Rule 4: Haptic fired BEFORE finger is released!
      expect(
        haptics,
        isNotEmpty,
        reason: 'Rule 4: Haptic tick must fire on crossing 85px before release',
      );

      // Rule 3: Seamless handoff — exact same spinner Element stays mounted
      final indicatorElementAfter = tester
          .element(find.byKey(const Key('pull-to-refresh-spinner')));
      expect(indicatorElementAfter, same(indicatorElementBefore));

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });

  group('Rule 5 & Rule 6: Overshoot Bounce (10-15px, Spring Damping 0.7) & Scroll Alive During Reload', () {
    test('springDamping07 has exact damping ratio 0.70 and bounceOvershootPx is within 10-15px', () {
      const s = PullToRefresh.springDamping07;
      final zeta = s.damping / (2 * math.sqrt(s.mass * s.stiffness));
      expect(zeta, closeTo(0.70, 0.01));
      expect(
        PullToRefresh.defaultBounceOvershootPx,
        inInclusiveRange(10.0, 15.0),
      );
    });

    testWidgets(
        'overshoots by 12px on release past threshold and keeps list scrollable & interactive while spinner is active',
        (tester) async {
      final refreshCompleter = Completer<void>();
      final scrollCtrl = ScrollController();
      addTearDown(scrollCtrl.dispose);
      final stateKey = GlobalKey<PullToRefreshState>();
      int tappedItemCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PullToRefresh(
              key: stateKey,
              onRefresh: () => refreshCompleter.future,
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: 40,
                itemBuilder: (_, i) => ListTile(
                  title: Text('Row #$i'),
                  onTap: () => tappedItemCount++,
                ),
              ),
            ),
          ),
        ),
      );

      // Pull 100px (resisted drag = 50px) and release
      final gesture =
          await tester.startGesture(tester.getCenter(find.byType(ListView)));
      await gesture.moveBy(const Offset(0, 100));
      await tester.pump();
      expect(stateKey.currentState!.dragDistance, closeTo(50.0, 0.1));

      await gesture.up();
      await tester.pump();

      // Rule 5: Immediately overshoots 10-15px above refreshHoldOffset (54 + 12 = 66px)
      expect(
        stateKey.currentState!.dragDistance,
        greaterThanOrEqualTo(
          PullToRefresh.defaultRefreshHoldOffset + 10.0,
        ),
      );
      expect(stateKey.currentState!.isRefreshing, isTrue);

      // Rule 6 (SCROLL ALIVE): List remains scrollable and tappable while spinner is active!
      await tester.tap(find.text('Row #1'));
      await tester.pump();
      expect(tappedItemCount, 1, reason: 'Rule 6: Items remain interactive while refreshing');

      await tester.drag(find.byType(ListView), const Offset(0, -180));
      await tester.pump();
      expect(
        scrollCtrl.offset,
        greaterThan(50.0),
        reason: 'Rule 6: List must not freeze during reload',
      );

      // Finish refresh and settle back to 0
      refreshCompleter.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(stateKey.currentState!.isRefreshing, isFalse);
    });
  });
}
