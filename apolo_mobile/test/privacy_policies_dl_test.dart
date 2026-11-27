import 'dart:convert';
import 'dart:typed_data';

import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/screens/privacy_compliance_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubLegalAdapter implements HttpClientAdapter {
  bool failDelete = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method == 'DELETE' && options.path == '/auth/account') {
      return ResponseBody.fromString(
        jsonEncode({'status': failDelete ? 'error' : 'success'}),
        failDelete ? 500 : 200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode({'status': 'success'}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _StubLegalAdapter stubAdapter;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppState().initialize(loadRemote: false);
    stubAdapter = _StubLegalAdapter();
    AppState().api.dio.httpClientAdapter = stubAdapter;
    AppState().currentUser = null;
  });

  testWidgets(
    'PrivacyComplianceScreen renders Dynamic Layer v5.1 Privacy, Policies, and Data & Delete tabs cleanly in EN LTR',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = AppState();
      final prevLocale = state.locale;
      await tester.runAsync(() => state.setLocale(const Locale('en')));
      addTearDown(() async {
        await tester.runAsync(() => state.setLocale(prevLocale));
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: PrivacyComplianceScreen(initialTab: 0),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byKey(const Key('dl-privacy-policies-screen')), findsOneWidget);
      expect(find.byKey(const Key('dl-legal-segmented-tabs')), findsOneWidget);
      expect(find.text('Privacy & Policies'), findsOneWidget);
      expect(find.text('Data We Collect'), findsOneWidget);

      // Switch to Policies & Terms tab (`tabId = 2`)
      await tester.tap(find.byKey(const Key('dl-legal-tab-policies')));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byKey(const Key('dl-policies-list')), findsOneWidget);
      expect(find.text('Clear rules for safe buying & selling'), findsOneWidget);
      expect(find.text('Account Integrity & Verified Badges'), findsOneWidget);

      // Switch to Data & Delete tab (`tabId = 1`)
      await tester.tap(find.byKey(const Key('dl-legal-tab-data')));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byKey(const Key('dl-delete-list')), findsOneWidget);
      expect(find.byKey(const Key('privacy-delete-account')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'PrivacyComplianceScreen renders Arabic RTL Policies, In-App AI Report sheet, and safe Account Deletion flow',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = AppState();
      final prevLocale = state.locale;
      state.currentUser = {'id': 77, 'name': 'Amine'};
      await tester.runAsync(() => state.api.setToken('test-token'));
      await tester.runAsync(() => state.setLocale(const Locale('ar')));
      addTearDown(() async {
        state.currentUser = null;
        await tester.runAsync(() => state.api.setToken(null));
        await tester.runAsync(() => state.setLocale(prevLocale));
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: PrivacyComplianceScreen(initialTab: 2),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('الخصوصية والشروط'), findsOneWidget);
      expect(find.text('قواعد واضحة لبيع وشراء آمن بالمغرب'), findsOneWidget);

      // Switch to Privacy tab, scroll down to build bottom actions, and open In-App Report sheet
      await tester.tap(find.byKey(const Key('dl-legal-tab-privacy')));
      await tester.pump(const Duration(milliseconds: 250));

      await tester.scrollUntilVisible(
        find.byKey(const Key('dl-open-ai-report')),
        350,
        scrollable: find.descendant(
          of: find.byKey(const Key('dl-privacy-list')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byKey(const Key('dl-open-ai-report')), findsOneWidget);
      await tester.tap(find.byKey(const Key('dl-open-ai-report')));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('الإبلاغ عن محتوى أو مخالفة'), findsOneWidget);
      expect(find.text('إرسال البلاغ الآن'), findsOneWidget);

      // Submit report cleanly after scrolling modal sheet into view
      await tester.ensureVisible(find.text('إرسال البلاغ الآن'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إرسال البلاغ الآن'));
      await tester.pumpAndSettle();

      // Switch to Account Data & Delete tab (`tabId = 1`) and verify safe deletion
      await tester.tap(find.byKey(const Key('dl-legal-tab-data')));
      await tester.pumpAndSettle();

      stubAdapter.failDelete = true;
      final deleteBtn = find.byKey(const Key('privacy-delete-account'));
      await tester.scrollUntilVisible(
        deleteBtn,
        250,
        scrollable: find.descendant(
          of: find.byKey(const Key('dl-delete-list')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();
      await tester.tap(find.text('حذف حسابي وبياناتي'));
      await tester.pumpAndSettle();
      expect(state.isLoggedIn, isTrue);

      stubAdapter.failDelete = false;
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();
      await tester.tap(find.text('حذف حسابي وبياناتي'));
      await tester.pumpAndSettle();
      expect(state.isLoggedIn, isFalse);

      expect(tester.takeException(), isNull);
    },
  );
}
