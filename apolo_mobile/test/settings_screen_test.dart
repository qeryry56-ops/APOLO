import 'dart:async';
import 'dart:convert';

import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/features/bug_report/services/bug_report_controller.dart';
import 'package:apolo_mobile/screens/account_security_screen.dart';
import 'package:apolo_mobile/screens/forgot_password_screen.dart';
import 'package:apolo_mobile/screens/privacy_compliance_screen.dart';
import 'package:apolo_mobile/screens/settings/settings_app_data_screen.dart';
import 'package:apolo_mobile/screens/settings/settings_blocked_accounts_screen.dart';
import 'package:apolo_mobile/screens/settings/settings_bug_report_screen.dart';
import 'package:apolo_mobile/screens/settings/settings_language_screen.dart';
import 'package:apolo_mobile/screens/settings/settings_rate_app_screen.dart';
import 'package:apolo_mobile/screens/settings/settings_share_app_screen.dart';
import 'package:apolo_mobile/screens/settings/settings_suggestion_screen.dart';
import 'package:apolo_mobile/screens/settings/settings_zone_screen.dart';
import 'package:apolo_mobile/screens/settings_screen.dart';
import 'package:apolo_mobile/screens/support_screen.dart';
import 'package:apolo_mobile/theme/app_theme.dart';
import 'package:apolo_mobile/widgets/dl_settings_kit.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockDioAdapter implements HttpClientAdapter {
  final FutureOr<ResponseBody> Function(RequestOptions options) handler;
  final List<RequestOptions> requests = <RequestOptions>[];

  _MockDioAdapter(this.handler);

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

ResponseBody _jsonReply(Object payload, [int statusCode = 200]) {
  return ResponseBody.fromString(
    jsonEncode(payload),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final state = AppState();
  late Dio originalDio;
  late Locale originalLocale;
  late bool originalShakeEnabled;
  late _MockDioAdapter adapter;

  const sensorsMethodChannel =
      MethodChannel('dev.fluttercommunity.plus/sensors/method');
  const sensorsEventChannel =
      MethodChannel('dev.fluttercommunity.plus/sensors/accelerometer');

  setUpAll(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(sensorsMethodChannel, (_) async => null);
    messenger.setMockMethodCallHandler(sensorsEventChannel, (_) async => null);
  });

  tearDownAll(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(sensorsMethodChannel, null);
    messenger.setMockMethodCallHandler(sensorsEventChannel, null);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    originalDio = state.api.dio;
    originalLocale = state.locale;
    originalShakeEnabled =
        BugReportController.instance.shakeService.enabled.value;

    adapter = _MockDioAdapter((options) {
      if (options.path.contains('/taxonomy')) {
        return _jsonReply({
          'status': 'success',
          'categories': <dynamic>[],
          'cities': <dynamic>[],
        });
      }
      return _jsonReply({'status': 'success'});
    });

    state.api.dio = Dio(BaseOptions(baseUrl: 'https://tests.invalid'))
      ..httpClientAdapter = adapter;
    state.currentUser = null;
    await state.api.setToken(null);
    await state.setLocale(const Locale('ar'));
  });

  tearDown(() async {
    if (BugReportController.instance.shakeService.enabled.value !=
        originalShakeEnabled) {
      await BugReportController.instance.shakeService
          .setEnabled(originalShakeEnabled);
    }
    state.currentUser = null;
    await state.api.setToken(null);
    await state.setLocale(originalLocale);
    state.api.dio = originalDio;
  });

  Future<void> pumpSettings(
    WidgetTester tester, {
    Size viewport = const Size(390, 844),
  }) async {
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          return MaterialApp(
            theme: AppTheme.light(state.locale).copyWith(
              splashFactory: NoSplash.splashFactory,
            ),
            home: const SettingsScreen(),
          );
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> scrollAndTap(WidgetTester tester, Key key) async {
    final target = find.byKey(key);
    await tester.scrollUntilVisible(
      target,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  group('SettingsScreen Dynamic Layer layout & constraints', () {
    for (final lang in ['ar', 'en']) {
      for (final size in [const Size(390, 844), const Size(1280, 800)]) {
        testWidgets(
            'renders cleanly in $lang at ${size.width.toInt()}x${size.height.toInt()}',
            (tester) async {
          await tester.runAsync(() => state.setLocale(Locale(lang)));
          await pumpSettings(tester, viewport: size);

          expect(tester.takeException(), isNull);
          expect(find.byType(Switch), findsNothing);
          expect(find.byIcon(Icons.verified), findsNothing);
          expect(find.text('Amine'), findsNothing);
          expect(find.byType(ApoloDlTopNav), findsOneWidget);
          expect(
            find.descendant(
              of: find.byType(ApoloDlTopNav),
              matching: find.byType(ApoloDlSeparator),
            ),
            findsNothing,
          );
          expect(find.byType(ApoloDlSettingsGroup), findsAtLeastNWidgets(2));

          final scrollable = find.byType(Scrollable).first;
          await tester.scrollUntilVisible(
            find.byKey(const Key('settings-row-security')),
            250,
            scrollable: scrollable,
          );
          await tester.pumpAndSettle();
          expect(find.byIcon(Icons.lock_outline), findsOneWidget);

          await tester.scrollUntilVisible(
            find.byKey(const Key('settings-row-support')),
            250,
            scrollable: scrollable,
          );
          await tester.pumpAndSettle();
          expect(find.byIcon(Icons.help_outline), findsOneWidget);

          final dangerTitle = lang == 'ar' ? 'منطقة الخطر' : 'Danger Zone';
          await tester.scrollUntilVisible(
            find.text(dangerTitle),
            250,
            scrollable: scrollable,
          );
          await tester.pumpAndSettle();
          expect(find.text(dangerTitle), findsOneWidget);
        });
      }
    }
  });

  group('SettingsScreen dedicated sub-screen navigation', () {
    testWidgets(
        'language row opens SettingsLanguageScreen and updates AppState locale to fr',
        (tester) async {
      await pumpSettings(tester);

      await scrollAndTap(tester, const Key('settings-row-language'));
      expect(find.byType(SettingsLanguageScreen), findsOneWidget);

      await tester.tap(find.byKey(const Key('lang-option-fr')));
      await tester.pumpAndSettle();

      expect(state.locale.languageCode, 'fr');
      expect(tester.takeException(), isNull);
    });

    testWidgets('zone row opens SettingsZoneScreen', (tester) async {
      await pumpSettings(tester);

      final zoneRow = find.byKey(const Key('settings-row-zone'));
      await tester.scrollUntilVisible(
        zoneRow,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      await tester.tap(zoneRow);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(SettingsZoneScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('blocked accounts row opens SettingsBlockedAccountsScreen',
        (tester) async {
      await pumpSettings(tester);

      await scrollAndTap(tester, const Key('settings-row-blocked'));
      expect(find.byType(SettingsBlockedAccountsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'bug report row opens SettingsBugReportScreen and shake toggle updates service',
        (tester) async {
      await BugReportController.instance.shakeService.setEnabled(true);
      await pumpSettings(tester);

      await scrollAndTap(tester, const Key('settings-row-bug-report'));
      expect(find.byType(SettingsBugReportScreen), findsOneWidget);
      expect(BugReportController.instance.shakeService.enabled.value, isTrue);

      await tester.tap(find.byKey(const Key('settings-bug-shake-toggle')));
      await tester.pumpAndSettle();

      expect(BugReportController.instance.shakeService.enabled.value, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('app data row opens SettingsAppDataScreen with licenses',
        (tester) async {
      await pumpSettings(tester);

      await scrollAndTap(tester, const Key('settings-row-app-data'));
      expect(find.byType(SettingsAppDataScreen), findsOneWidget);
      expect(find.byKey(const Key('settings-sync-now')), findsOneWidget);
      expect(find.byKey(const Key('settings-open-licenses')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'forgot password, suggestion, share app, and rate app open dedicated screens',
        (tester) async {
      await pumpSettings(tester);

      await scrollAndTap(tester, const Key('settings-row-forgot-password'));
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      Navigator.of(tester.element(find.byType(ForgotPasswordScreen))).pop();
      await tester.pumpAndSettle();

      await scrollAndTap(tester, const Key('settings-row-suggestion'));
      expect(find.byType(SettingsSuggestionScreen), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('suggestion-input')),
        'Add dark mode schedule option',
      );
      await tester.ensureVisible(find.byKey(const Key('suggestion-submit')));
      await tester.tap(find.byKey(const Key('suggestion-submit')));
      await tester.pumpAndSettle();
      expect(find.byType(ApoloDlAlert), findsOneWidget);
      Navigator.of(tester.element(find.byType(SettingsSuggestionScreen)))
          .pop();
      await tester.pumpAndSettle();

      await scrollAndTap(tester, const Key('settings-row-share-app'));
      expect(find.byType(SettingsShareAppScreen), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('share-app-copy-link')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('share-app-copy-link')));
      await tester.pumpAndSettle();
      expect(find.byType(ApoloDlAlert), findsOneWidget);
      Navigator.of(tester.element(find.byType(SettingsShareAppScreen))).pop();
      await tester.pumpAndSettle();

      await scrollAndTap(tester, const Key('settings-row-rate-app'));
      expect(find.byType(SettingsRateAppScreen), findsOneWidget);
      await tester.tap(find.byKey(const Key('rate-star-4')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('rate-app-submit')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('rate-app-submit')));
      await tester.pumpAndSettle();
      expect(find.byType(ApoloDlAlert), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'security, privacy, and support rows open their dedicated screens',
        (tester) async {
      await pumpSettings(tester);

      await scrollAndTap(tester, const Key('settings-row-security'));
      expect(find.byType(AccountSecurityScreen), findsOneWidget);
      Navigator.of(tester.element(find.byType(AccountSecurityScreen))).pop();
      await tester.pumpAndSettle();

      await scrollAndTap(tester, const Key('settings-row-privacy'));
      expect(find.byType(PrivacyComplianceScreen), findsOneWidget);
      Navigator.of(tester.element(find.byType(PrivacyComplianceScreen))).pop();
      await tester.pumpAndSettle();

      await scrollAndTap(tester, const Key('settings-row-support'));
      expect(find.byType(SupportScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'logged-in logout button opens Dynamic Layer confirmation bottom sheet',
        (tester) async {
      state.currentUser = {
        'id': 99,
        'name': 'Karim',
        'username': 'karim_casa',
      };
      await state.api.setToken('valid-test-token');

      await pumpSettings(tester);

      await scrollAndTap(tester, const ValueKey('settings-logout'));
      expect(find.byKey(const Key('settings-confirm-logout')), findsOneWidget);

      await tester.tap(find.byKey(const Key('settings-confirm-logout')));
      await tester.pumpAndSettle();

      expect(state.isLoggedIn, isFalse);
      expect(tester.takeException(), isNull);
    });
  });
}
