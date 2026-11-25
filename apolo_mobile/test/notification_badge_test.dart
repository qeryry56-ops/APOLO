import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:apolo_mobile/core/services/media_rtc_bridge.dart';
import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/screens/chat_list_screen.dart';
import 'package:apolo_mobile/screens/home_screen.dart';
import 'package:apolo_mobile/screens/main_shell.dart';
import 'package:apolo_mobile/screens/notifications_screen.dart';
import 'package:apolo_mobile/screens/settings_screen.dart';
import 'package:apolo_mobile/widgets/notification_badge.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubAdapter implements HttpClientAdapter {
  final FutureOr<ResponseBody> Function(RequestOptions) handler;
  final List<RequestOptions> requests = [];

  _StubAdapter(this.handler);

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
  TestWidgetsFlutterBinding.ensureInitialized();

  final state = AppState();
  late Dio originalDio;
  late Locale originalLocale;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    originalDio = state.api.dio;
    originalLocale = state.locale;
    state.currentUser = null;
    state.favoriteAdIds.clear();
    state.categories = [];
    state.cities = [];
    state.setUnreadNotificationsCount(0);
    state.syncUnreadChatCount(0, notify: false);
    await state.api.setToken(null);
    await state.setLocale(const Locale('en'));
  });

  tearDown(() async {
    state.api.dio = originalDio;
    state.currentUser = null;
    state.favoriteAdIds.clear();
    state.setUnreadNotificationsCount(0);
    state.syncUnreadChatCount(0, notify: false);
    await state.api.setToken(null);
    await state.setLocale(originalLocale);
  });

  Future<void> pumpBadge(
    WidgetTester tester,
    Widget child, {
    TextDirection direction = TextDirection.ltr,
    bool disableAnimations = true,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        builder: (context, w) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: disableAnimations,
          ),
          child: Directionality(textDirection: direction, child: w!),
        ),
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  group('Rule 1: Count formatting & edge cases (0, 1, 9, 10, 99, 100, 1000)', () {
    test('formatCount handles negative, zero, boundary, and >99 values', () {
      expect(NotificationBadge.formatCount(-5), '');
      expect(NotificationBadge.formatCount(-1), '');
      expect(NotificationBadge.formatCount(0), '');
      expect(NotificationBadge.formatCount(1), '1');
      expect(NotificationBadge.formatCount(9), '9');
      expect(NotificationBadge.formatCount(10), '10');
      expect(NotificationBadge.formatCount(99), '99');
      expect(NotificationBadge.formatCount(100), '99+');
      expect(NotificationBadge.formatCount(1000), '99+');
    });

    testWidgets('renders expected labels and never shows 0, 100, or 1000',
        (tester) async {
      final cases = <(int, String?)>[
        (-1, null),
        (0, null),
        (1, '1'),
        (9, '9'),
        (10, '10'),
        (99, '99'),
        (100, '99+'),
        (1000, '99+'),
      ];

      for (final (count, expected) in cases) {
        await pumpBadge(
          tester,
          NotificationBadge(
            count: count,
            type: NotificationBadgeType.number,
            variant: NotificationBadgeVariant.red,
            child: const Icon(CupertinoIcons.bell, size: 24),
          ),
        );
        await tester.pump();

        if (expected == null) {
          expect(find.text('0'), findsNothing);
          expect(find.text('-1'), findsNothing);
          expect(find.text('99+'), findsNothing);
        } else {
          expect(find.text(expected), findsOneWidget);
        }
        expect(find.text('100'), findsNothing);
        expect(find.text('1000'), findsNothing);
      }
    });
  });

  group('Rule 2: Pin top-right & icon never shifts across digit widths', () {
    for (final dir in [TextDirection.ltr, TextDirection.rtl]) {
      testWidgets(
          'icon Rect stays identical and badge stays top-right in $dir',
          (tester) async {
        Rect? baselineIconRect;
        for (final count in [0, 1, 9, 10, 99, 100, 1000]) {
          await pumpBadge(
            tester,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                NotificationBadge(
                  count: count,
                  type: NotificationBadgeType.number,
                  variant: NotificationBadgeVariant.red,
                  child: const Icon(CupertinoIcons.bell, size: 24),
                ),
                const SizedBox(width: 12),
                const Text('Neighbor'),
              ],
            ),
            direction: dir,
          );
          await tester.pump();

          final iconRect = tester.getRect(find.byIcon(CupertinoIcons.bell));
          baselineIconRect ??= iconRect;
          expect(iconRect, baselineIconRect,
              reason: 'Icon shifted for count=$count in $dir');

          if (count > 0) {
            final label = NotificationBadge.formatCount(count);
            final pillFinder = find.ancestor(
              of: find.text(label),
              matching: find.byWidgetPredicate((w) =>
                  w is Container &&
                  w.decoration is BoxDecoration &&
                  (w.decoration as BoxDecoration).color ==
                      NotificationBadge.actionRedColor),
            );
            final pillRect = tester.getRect(pillFinder);
            expect(pillRect.right, closeTo(iconRect.right + 8.0, 0.5),
                reason: 'Badge must stay pinned physically top-right in $dir');
            expect(pillRect.top, closeTo(iconRect.top - 6.0, 0.5),
                reason: 'Badge must stay pinned physically above icon in $dir');
            expect(pillRect.center.dy, lessThan(iconRect.center.dy),
                reason: 'Badge center must stay above icon center in $dir');
          }
        }
      });
    }
  });

  group('Rule 3 & Accessibility: Colors, contrast > 4.5:1, min 18px, Semantics',
      () {
    test('red and green badge colors satisfy WCAG > 4.5:1 with white text', () {
      expect(
        NotificationBadge.contrastRatio(
          Colors.white,
          NotificationBadge.actionRedColor,
        ),
        greaterThan(4.5),
      );
      expect(
        NotificationBadge.contrastRatio(
          Colors.white,
          NotificationBadge.statusGreenColor,
        ),
        greaterThan(4.5),
      );
      expect(NotificationBadge.actionRedDotColor, const Color(0xFFFF3B30));
      expect(
        NotificationBadge.contrastRatio(
          NotificationBadge.actionRedDotColor,
          Colors.white,
        ),
        greaterThanOrEqualTo(3.0),
      );
    });

    testWidgets('number badges meet >= 18px min size and use white text',
        (tester) async {
      for (final count in [1, 9, 10, 99, 100, 1000]) {
        await pumpBadge(
          tester,
          NotificationBadge(
            count: count,
            type: NotificationBadgeType.number,
            variant: NotificationBadgeVariant.red,
            child: const Icon(CupertinoIcons.bell, size: 24),
          ),
        );
        await tester.pump();

        final label = NotificationBadge.formatCount(count);
        final textFinder = find.text(label);
        final textWidget = tester.widget<Text>(textFinder);
        expect(textWidget.style?.color, Colors.white);

        final pillFinder = find.ancestor(
          of: textFinder,
          matching: find.byWidgetPredicate((w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).color ==
                  NotificationBadge.actionRedColor),
        );
        expect(pillFinder, findsOneWidget);
        final pillSize = tester.getSize(pillFinder);
        expect(pillSize.width, greaterThanOrEqualTo(18.0));
        expect(pillSize.height, greaterThanOrEqualTo(18.0));
      }
    });

    testWidgets('exposes accessible Semantics labels for number & dot variants',
        (tester) async {
      await pumpBadge(
        tester,
        const NotificationBadge(
          count: 1,
          type: NotificationBadgeType.number,
          variant: NotificationBadgeVariant.red,
        ),
      );
      expect(find.bySemanticsLabel('1 unread notification'), findsOneWidget);

      await pumpBadge(
        tester,
        const NotificationBadge(
          count: 150,
          type: NotificationBadgeType.number,
          variant: NotificationBadgeVariant.red,
        ),
      );
      expect(find.bySemanticsLabel('99+ unread notifications'), findsOneWidget);

      await pumpBadge(
        tester,
        const NotificationBadge(
          count: 1,
          type: NotificationBadgeType.dot,
          variant: NotificationBadgeVariant.green,
        ),
      );
      expect(find.bySemanticsLabel('Online'), findsOneWidget);

      await pumpBadge(
        tester,
        const NotificationBadge(
          count: 1,
          type: NotificationBadgeType.dot,
          variant: NotificationBadgeVariant.red,
        ),
      );
      expect(find.bySemanticsLabel('Unread notification'), findsOneWidget);
    });
  });

  group('Rule 4: Dot vs Number strictly mutually exclusive', () {
    testWidgets('dot type never renders text even when count > 1',
        (tester) async {
      await pumpBadge(
        tester,
        const NotificationBadge(
          count: 42,
          type: NotificationBadgeType.dot,
          variant: NotificationBadgeVariant.red,
          child: Icon(CupertinoIcons.bell, size: 24),
        ),
      );
      await tester.pump();

      expect(find.text('42'), findsNothing);
      expect(find.byType(Text), findsNothing);
      final dotFinder = find.byWidgetPredicate((w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).shape == BoxShape.circle &&
          (w.decoration as BoxDecoration).color ==
              NotificationBadge.actionRedDotColor);
      expect(dotFinder, findsOneWidget);
    });

    testWidgets('number type renders number pill only and no separate dot',
        (tester) async {
      await pumpBadge(
        tester,
        const NotificationBadge(
          count: 42,
          type: NotificationBadgeType.number,
          variant: NotificationBadgeVariant.red,
          child: Icon(CupertinoIcons.bell, size: 24),
        ),
      );
      await tester.pump();

      expect(find.text('42'), findsOneWidget);
      final circleDots = find.byWidgetPredicate((w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).shape == BoxShape.circle);
      expect(circleDots, findsNothing);
    });
  });

  group('Rule 6: Smooth scale animation on increment and never flashes 0', () {
    testWidgets('scales up smoothly on count increase and never shows 0 on exit',
        (tester) async {
      Widget harness(int count) => MaterialApp(
            home: Scaffold(
              body: Center(
                child: NotificationBadge(
                  count: count,
                  type: NotificationBadgeType.number,
                  variant: NotificationBadgeVariant.red,
                  child: const Icon(CupertinoIcons.bell, size: 24),
                ),
              ),
            ),
          );

      await tester.pumpWidget(harness(1));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);

      // Increment 1 -> 2: scale bumps above 1.0 mid-animation then settles to 1.0
      await tester.pumpWidget(harness(2));
      await tester.pump(const Duration(milliseconds: 90));
      expect(find.text('0'), findsNothing);

      final transforms = tester.widgetList<Transform>(
        find.descendant(
          of: find.byType(NotificationBadge),
          matching: find.byType(Transform),
        ),
      );
      final maxScale = transforms
          .map((t) => t.transform.getMaxScaleOnAxis())
          .fold<double>(1.0, (a, b) => a > b ? a : b);
      expect(maxScale, greaterThan(1.05));

      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('2'), findsOneWidget);
      expect(find.text('0'), findsNothing);

      // Decrement 2 -> 0: never flashes '0' at any frame during exit
      await tester.pumpWidget(harness(0));
      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 40));
        expect(find.text('0'), findsNothing);
      }
      expect(find.text('2'), findsNothing);
    });
  });

  group('Rule 5 & Rule 7: Optimistic Clear & Actionable-Only Filtering', () {
    test('isActionableNotification rejects marketing/info and accepts decisions',
        () {
      expect(
        AppState.isActionableNotification({'type': 'marketing', 'title': 'Sale'}),
        isFalse,
      );
      expect(
        AppState.isActionableNotification({'type': 'promo', 'title': 'VIP 50%'}),
        isFalse,
      );
      expect(
        AppState.isActionableNotification(
            {'type': 'newsletter', 'title': 'Weekly digest'}),
        isFalse,
      );
      expect(
        AppState.isActionableNotification(
            {'type': 'views_milestone', 'ad_id': 12}),
        isFalse,
      );
      expect(
        AppState.isActionableNotification(
            {'type': 'info', 'title': 'System info'}),
        isFalse,
      );

      expect(
        AppState.isActionableNotification({'type': 'new_message', 'conversation_id': 5}),
        isTrue,
      );
      expect(
        AppState.isActionableNotification({'type': 'offer_received', 'ad_id': 5}),
        isTrue,
      );
      expect(
        AppState.isActionableNotification({'type': 'order_request'}),
        isTrue,
      );
      expect(
        AppState.isActionableNotification({'type': 'missed_call'}),
        isTrue,
      );
      expect(
        AppState.isActionableNotification({'type': 'unknown', 'is_marketing': true}),
        isFalse,
      );
      expect(
        AppState.isActionableNotification({'type': 'promo', 'requires_action': true}),
        isTrue,
      );
    });

    test('fetchUnreadNotificationsCount ignores marketing & respects optimistic clear epoch',
        () async {
      final notificationsCompleter = Completer<ResponseBody>();
      state.api.dio = Dio(BaseOptions(baseUrl: 'https://tests.invalid'))
        ..httpClientAdapter = _StubAdapter((req) {
          if (req.path == '/notifications') {
            return notificationsCompleter.future;
          }
          return _json({'status': 'success'});
        });
      state.currentUser = {'id': 1, 'name': 'Amine'};
      await state.api.setToken('tok');

      // 1. Mixed payload counts only unread actionable items (2)
      state.api.dio = Dio(BaseOptions(baseUrl: 'https://tests.invalid'))
        ..httpClientAdapter = _StubAdapter((_) => _json({
              'status': 'success',
              'unread_count': 5,
              'notifications': [
                {'id': 1, 'type': 'marketing', 'is_read': false},
                {'id': 2, 'type': 'promo', 'is_read': false},
                {'id': 3, 'type': 'views_milestone', 'is_read': false},
                {'id': 4, 'type': 'chat_message', 'is_read': false},
                {'id': 5, 'type': 'offer', 'is_read': false},
                {'id': 6, 'type': 'chat_message', 'is_read': true},
              ],
            }));
      await state.fetchUnreadNotificationsCount();
      expect(state.unreadNotificationsCount, 2);

      // 2. Stale in-flight response cannot overwrite an optimistic clear
      state.api.dio = Dio(BaseOptions(baseUrl: 'https://tests.invalid'))
        ..httpClientAdapter = _StubAdapter((req) {
          if (req.path == '/notifications') {
            return notificationsCompleter.future;
          }
          return _json({'status': 'success'});
        });
      final inFlight = state.fetchUnreadNotificationsCount();
      state.clearUnreadNotificationsOptimistically(syncRemote: false);
      expect(state.unreadNotificationsCount, 0);

      notificationsCompleter.complete(_json({
        'status': 'success',
        'unread_count': 9,
        'notifications': [],
      }));
      await inFlight;
      expect(state.unreadNotificationsCount, 0);
    });

    testWidgets(
        'HomeScreen bell clears badge immediately on tap without waiting for API and removes marketing dot',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final pendingNotifs = Completer<ResponseBody>();
      state.api.dio = Dio(BaseOptions(baseUrl: 'https://tests.invalid'))
        ..httpClientAdapter = _StubAdapter((req) {
          if (req.path == '/home') {
            return _json({'vip_ads': [], 'featured_ads': [], 'latest_ads': []});
          }
          if (req.path == '/ads') {
            return _json({'status': 'success', 'data': []});
          }
          if (req.path == '/notifications') {
            return pendingNotifs.future;
          }
          return _json({'status': 'success', 'categories': [], 'cities': []});
        });

      state.currentUser = {'id': 1, 'name': 'Amine'};
      await state.api.setToken('tok');
      state.setUnreadNotificationsCount(7);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          builder: (context, w) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: w!,
          ),
          home: const HomeScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('7'), findsOneWidget);
      // Hero marketing pill text exists without a decorative badge dot sibling
      final heroPillText = find.text('Marketplace #1 au Maroc 🇲🇦');
      expect(heroPillText, findsOneWidget);
      final heroPillRow = find.ancestor(
        of: heroPillText,
        matching: find.byWidgetPredicate(
          (w) => w is Container && w.child is Row,
        ),
      );
      expect(heroPillRow, findsNothing);

      // Tap bell -> badge clears at 0ms even while /notifications API hangs
      await tester.tap(find.byKey(const Key('home-notifications-bell')));
      await tester.pump();
      expect(state.unreadNotificationsCount, 0);
      expect(find.text('7'), findsNothing);

      pendingNotifs.complete(_json({'status': 'success', 'notifications': []}));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets(
        'SettingsScreen shows capped red badge (99+) and clears optimistically on tap',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final pendingNotifs = Completer<ResponseBody>();
      state.api.dio = Dio(BaseOptions(baseUrl: 'https://tests.invalid'))
        ..httpClientAdapter = _StubAdapter((req) {
          if (req.path == '/notifications') {
            return pendingNotifs.future;
          }
          return _json({'status': 'success'});
        });
      state.currentUser = {'id': 1, 'name': 'Amine'};
      await state.api.setToken('tok');
      state.setUnreadNotificationsCount(150);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          builder: (context, w) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: w!,
          ),
          home: const SettingsScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('99+'), findsOneWidget);
      expect(find.text('150'), findsNothing);

      await tester.tap(find.text('Notifications'));
      await tester.pump();
      expect(state.unreadNotificationsCount, 0);
      expect(find.text('99+'), findsNothing);

      pendingNotifs.complete(_json({'status': 'success', 'notifications': []}));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets(
        'MainShell tab bar shows capped 99+ red badge on Messages and clears immediately on tab tap',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      state.api.dio = Dio(BaseOptions(baseUrl: 'https://tests.invalid'))
        ..httpClientAdapter = _StubAdapter(
          (_) => _json({'status': 'success', 'data': [], 'categories': [], 'cities': []}),
        );
      state.currentUser = {'id': 1, 'name': 'Amine'};
      await state.api.setToken('tok');
      state.syncUnreadChatCount(120, notify: false);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          builder: (context, w) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: w!,
          ),
          home: const MainShell(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('99+'), findsOneWidget);
      expect(find.text('120'), findsNothing);

      await tester.tap(find.byIcon(CupertinoIcons.chat_bubble_2));
      await tester.pump();
      expect(state.unreadChatCount, 0);
      expect(find.text('99+'), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
        'ChatListScreen list items use capped red NotificationBadge and clear row on tap',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final pendingMessages = Completer<ResponseBody>();
      state.api.dio = Dio(BaseOptions(baseUrl: 'https://tests.invalid'))
        ..httpClientAdapter = _StubAdapter((req) {
          if (req.path == '/chat/conversations') {
            return _json({
              'status': 'success',
              'conversations': [
                {
                  'id': 1,
                  'peer_name': 'Salma',
                  'last_message': 'Hello!',
                  'last_message_time': '10:00',
                  'unread_count': 2,
                  'peer_online': true,
                },
                {
                  'id': 2,
                  'peer_name': 'Karim',
                  'last_message': 'Price?',
                  'last_message_time': '09:00',
                  'unread_count': 150,
                  'peer_online': false,
                },
              ],
            });
          }
          if (req.path.contains('/messages')) {
            return pendingMessages.future;
          }
          return _json({'status': 'success'});
        });
      state.currentUser = {'id': 1, 'name': 'Amine'};
      await state.api.setToken('tok');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          builder: (context, w) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: w!,
          ),
          home: const ChatListScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('2'), findsOneWidget);
      expect(find.text('99+'), findsOneWidget);
      expect(find.text('150'), findsNothing);

      // Verify green status dot only renders for Salma (peer_online: true, not Karim)
      final greenDots = find.byWidgetPredicate((w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).shape == BoxShape.circle &&
          (w.decoration as BoxDecoration).color ==
              NotificationBadge.statusGreenColor);
      expect(greenDots, findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Online')), findsOneWidget);

      // Tap Salma -> clears '2' immediately while ChatRoomScreen API is pending
      await tester.tap(find.text('Salma'));
      await tester.pump();
      expect(find.text('2'), findsNothing);

      pendingMessages.complete(_json({'status': 'success', 'messages': []}));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets(
        'NotificationsScreen renders red dot only for actionable items and omits marketing dot',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      state.api.dio = Dio(BaseOptions(baseUrl: 'https://tests.invalid'))
        ..httpClientAdapter = _StubAdapter((req) {
          if (req.path == '/notifications' && req.method == 'GET') {
            return _json({
              'status': 'success',
              'notifications': [
                {
                  'id': 10,
                  'type': 'offer',
                  'title': 'New offer',
                  'body': 'Buyer offered 2000 DH',
                  'is_read': false,
                },
                {
                  'id': 11,
                  'type': 'marketing',
                  'title': 'Promo weekend',
                  'body': 'Boost your ads today',
                  'is_read': false,
                },
              ],
            });
          }
          return _json({'status': 'success'});
        });
      state.currentUser = {'id': 1, 'name': 'Amine'};
      await state.api.setToken('tok');
      state.setUnreadNotificationsCount(5);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          builder: (context, w) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: w!,
          ),
          home: const NotificationsScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      // Rule 5: global unread count cleared on screen open
      expect(state.unreadNotificationsCount, 0);
      expect(find.text('New offer'), findsOneWidget);
      expect(find.text('Promo weekend'), findsOneWidget);
      // Rule 7: only 1 red dot rendered (for 'offer', not 'marketing')
      final redDots = find.byWidgetPredicate((w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).shape == BoxShape.circle &&
          (w.decoration as BoxDecoration).color ==
              NotificationBadge.actionRedDotColor);
      expect(redDots, findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Unread notification')),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets(
        'NotificationsScreen verifies active permission: stays on Default gate when denied, and navigates to Figma 47390:2792 Apolo Notifications feed when granted',
        (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() {
        MediaRtcBridge.debugPermissionOverride = null;
        MediaRtcBridge.debugRequestPermissionHandler = null;
      });

      MediaRtcBridge.debugPermissionOverride = 'default';
      state.api.dio = Dio(BaseOptions(baseUrl: 'https://tests.invalid'))
        ..httpClientAdapter = _StubAdapter((_) => _json({
              'status': 'success',
              'notifications': <dynamic>[],
            }));
      state.currentUser = null;
      await tester.runAsync(() => state.api.setToken(null));
      await tester.runAsync(() => state.setLocale(const Locale('en')));

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          builder: (context, w) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: const EdgeInsets.only(top: 48, bottom: 34),
              disableAnimations: true,
            ),
            child: w!,
          ),
          home: const NotificationsScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);

      // Stage 1: `Notification / Default` (`330 × 240` `# notification-img` + `56px` `Continue` button)
      final backRect =
          tester.getRect(find.byKey(const Key('dl-notification-back-button')));
      expect(backRect.width, closeTo(40.0, 0.01));
      expect(backRect.height, closeTo(40.0, 0.01));

      final imgRect =
          tester.getRect(find.byKey(const Key('dl-notification-img')));
      expect(imgRect.width, closeTo(330.0, 0.01));
      expect(imgRect.height, closeTo(240.0, 0.01));
      expect(imgRect.left, closeTo(22.5, 1.0));
      expect(find.text('Notification'), findsOneWidget);
      expect(find.byKey(const Key('dl-notifications-main-container')), findsNothing);

      // Case 1: Permission denied -> does NOT navigate to Stage 2, shows blocked guidance sheet
      MediaRtcBridge.debugRequestPermissionHandler = () async {
        MediaRtcBridge.debugPermissionOverride = 'denied';
        return 'denied';
      };
      await tester.tap(find.byKey(const Key('dl-notification-continue-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byKey(const Key('dl-notification-blocked-dismiss')), findsOneWidget);
      await tester.tap(find.byKey(const Key('dl-notification-blocked-dismiss')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byKey(const Key('dl-notification-continue-button')), findsOneWidget);
      expect(find.byKey(const Key('dl-notifications-main-container')), findsNothing);

      // Case 2: Permission granted -> verified active -> transitions to Figma `47390:2792` Apolo Notifications feed
      MediaRtcBridge.debugRequestPermissionHandler = () async {
        MediaRtcBridge.debugPermissionOverride = 'granted';
        return 'granted';
      };
      await tester.tap(find.byKey(const Key('dl-notification-continue-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(tester.takeException(), isNull);

      expect(find.byKey(const Key('dl-notifications-header-title')), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.byKey(const Key('dl-notifications-header-separator')), findsOneWidget);

      final mainContainer = tester.widget<Padding>(
        find.byKey(const Key('dl-notifications-main-container')),
      );
      expect(mainContainer.padding, const EdgeInsets.fromLTRB(16.0, 32.0, 16.0, 32.0));
      expect(find.byKey(const Key('dl-notifications-section-today')), findsOneWidget);
      expect(find.byKey(const Key('dl-notifications-section-week')), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('This week'), findsOneWidget);

      // Verify Arabic RTL on small 320x568 viewport renders Apolo feed cleanly with zero overflow
      await tester.runAsync(() => state.setLocale(const Locale('ar')));
      tester.view.physicalSize = const Size(320, 568);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.text('الإشعارات'), findsOneWidget);
      expect(find.text('اليوم'), findsOneWidget);
      expect(find.text('هذا الأسبوع'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    });
  });

  group('Nav Bar, Tab Bar, List Item placement smoke checks', () {
    testWidgets(
        'renders cleanly without overflow in AppBar, NavigationBar, and ListTile',
        (tester) async {
      for (final count in [0, 1, 9, 10, 99, 100, 1000]) {
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, w) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: w!,
            ),
            home: Scaffold(
              appBar: AppBar(
                title: const Text('Apolo'),
                actions: [
                  IconButton(
                    onPressed: () {},
                    icon: NotificationBadge(
                      count: count,
                      type: NotificationBadgeType.number,
                      variant: NotificationBadgeVariant.red,
                      child: const Icon(CupertinoIcons.bell),
                    ),
                  ),
                ],
              ),
              body: ListTile(
                leading: NotificationBadge(
                  count: count > 0 ? 1 : 0,
                  type: NotificationBadgeType.dot,
                  variant: NotificationBadgeVariant.green,
                  child: const CircleAvatar(child: Text('A')),
                ),
                title: const Text('Item'),
                trailing: NotificationBadge(
                  count: count,
                  type: NotificationBadgeType.number,
                  variant: NotificationBadgeVariant.red,
                ),
              ),
              bottomNavigationBar: BottomNavigationBar(
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.house),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: NotificationBadge(
                      count: count,
                      type: NotificationBadgeType.number,
                      variant: NotificationBadgeVariant.red,
                      child: const Icon(CupertinoIcons.chat_bubble_2),
                    ),
                    label: 'Messages',
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    });
  });
}
