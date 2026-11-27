import 'dart:typed_data';

import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/screens/account_security_screen.dart';
import 'package:apolo_mobile/screens/pro_plus_screen.dart';
import 'package:apolo_mobile/screens/settings/apolo_account_center_screen.dart';
import 'package:apolo_mobile/screens/settings/settings_saved_ads_screen.dart';
import 'package:apolo_mobile/screens/settings_screen.dart';
import 'package:apolo_mobile/screens/support_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _OfflineAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      ResponseBody.fromString(
        '{"status":"success","data":[]}',
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpClientAdapter originalAdapter;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    originalAdapter = AppState().api.dio.httpClientAdapter;
    AppState().api.dio.httpClientAdapter = _OfflineAdapter();
    await AppState().logout();
    await AppState().setLocale(const Locale('en'));
  });

  tearDown(() {
    AppState().api.dio.httpClientAdapter = originalAdapter;
  });

  Widget buildApp(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  testWidgets('Default locale is English and Settings renders APOLO architecture',
      (tester) async {
    expect(AppState().locale.languageCode, 'en');

    await tester.pumpWidget(buildApp(const SettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Settings and activity'), findsOneWidget);
    expect(find.byKey(const Key('settings-search-field')), findsOneWidget);
    expect(find.byKey(const Key('settings-row-apolo-account')), findsOneWidget);
    expect(find.text('Apolo Account'), findsOneWidget);
    expect(find.byKey(const Key('settings-row-saved')), findsOneWidget);
    expect(find.byKey(const Key('settings-row-zone')), findsOneWidget);
    expect(find.byKey(const Key('settings-row-notifications')), findsOneWidget);
    expect(find.byKey(const Key('settings-row-language')), findsOneWidget);
    expect(find.byKey(const Key('settings-row-pro-plus')), findsOneWidget);
    expect(find.text('Not subscribed'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-login')),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings-row-add-friends')), findsOneWidget);
    expect(find.byKey(const Key('settings-row-share-app')), findsOneWidget);
    expect(find.byKey(const Key('settings-row-blocked')), findsOneWidget);
    expect(find.byKey(const Key('settings-row-privacy')), findsOneWidget);
    expect(find.byKey(const Key('settings-row-help')), findsOneWidget);
    expect(find.byKey(const Key('settings-row-bug-report')), findsOneWidget);
    expect(find.byKey(const Key('settings-row-suggestion')), findsOneWidget);
    expect(find.byKey(const Key('settings-row-app-data')), findsOneWidget);
    expect(find.byKey(const Key('settings-login')), findsOneWidget);
    expect(find.byKey(const Key('settings-register')), findsOneWidget);

    expect(find.byKey(const Key('settings-quick-replies')), findsNothing);
    expect(find.byKey(const Key('settings-row-rate-app')), findsNothing);
  });

  testWidgets('Logged-in PRO+ user sees VIP credits and Log out button',
      (tester) async {
    await tester.runAsync(() async {
      await AppState().setAuthSession('test_token', {
        'id': 42,
        'name': 'Amine Test',
        'username': 'amine',
        'email': 'amine@apolo.ma',
        'is_pro_plus': true,
        'vip_boost_credits': 3,
        'account_type': 'business',
      });
    });

    await tester.pumpWidget(buildApp(const SettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('PRO+ Active'), findsOneWidget);
    expect(find.byKey(const Key('settings-row-vip-credits')), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-logout')),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings-logout')), findsOneWidget);
    expect(find.byKey(const Key('settings-login')), findsNothing);
  });

  testWidgets('Search filters settings rows live and clears properly',
      (tester) async {
    await tester.pumpWidget(buildApp(const SettingsScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('settings-search-field')),
      'Language',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings-row-language')), findsOneWidget);
    expect(find.byKey(const Key('settings-row-saved')), findsNothing);
    expect(find.byKey(const Key('settings-row-apolo-account')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('settings-search-field')),
      'zzzznonexistent',
    );
    await tester.pumpAndSettle();
    expect(find.text('No matching settings'), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-search-clear')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-row-apolo-account')), findsOneWidget);
    expect(find.byKey(const Key('settings-row-saved')), findsOneWidget);
  });

  testWidgets('Apolo Account opens ApoloAccountCenterScreen', (tester) async {
    await tester.runAsync(() async {
      await AppState().setAuthSession('test_token', {
        'id': 7,
        'name': 'Salma Pro',
        'username': 'salma_pro',
        'email': 'salma@apolo.ma',
        'account_type': 'personal',
      });
    });

    await tester.pumpWidget(buildApp(const SettingsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings-row-apolo-account')));
    await tester.pumpAndSettle();

    expect(find.byType(ApoloAccountCenterScreen), findsOneWidget);
    expect(find.text('Personal details'), findsOneWidget);
    expect(find.text('Password & security'), findsOneWidget);
    expect(find.text('Business & Store'), findsOneWidget);
    expect(
      find.byKey(const Key('account-center-edit-profile')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('account-center-business')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Account ownership'),
      220,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Account ownership'), findsOneWidget);
  });

  testWidgets('Saved row opens SettingsSavedAdsScreen', (tester) async {
    await tester.pumpWidget(buildApp(const SettingsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings-row-saved')));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsSavedAdsScreen), findsOneWidget);
    expect(find.text('Sign in to view saved listings'), findsOneWidget);
  });

  testWidgets('Apolo Pro+ row opens SubscriptionScreen', (tester) async {
    await tester.pumpWidget(buildApp(const SettingsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings-row-pro-plus')));
    await tester.pumpAndSettle();

    expect(find.byType(SubscriptionScreen), findsOneWidget);
  });

  testWidgets(
      'Apolo Account -> Edit profile pops back through Settings and invokes callback',
      (tester) async {
    await tester.runAsync(() async {
      await AppState().setAuthSession('test_token', {
        'id': 9,
        'name': 'Nadia Edit',
        'username': 'nadia',
        'email': 'nadia@apolo.ma',
        'account_type': 'personal',
      });
    });

    var editTriggered = 0;
    await tester.pumpWidget(
      buildApp(
        Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => Navigator.of(ctx).push(
                MaterialPageRoute<void>(
                  builder: (_) => SettingsScreen(
                    onOpenEditProfile: () => editTriggered++,
                  ),
                ),
              ),
              child: const Text('Open Settings'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings-row-apolo-account')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('account-center-edit-profile')));
    await tester.pumpAndSettle();

    expect(find.byType(ApoloAccountCenterScreen), findsNothing);
    expect(find.byType(SettingsScreen), findsNothing);
    expect(find.text('Open Settings'), findsOneWidget);
    expect(editTriggered, 1);
  });

  testWidgets(
      'Dynamic Layer v5.1 AccountSecurityScreen, SupportScreen, and Arabic RTL Settings render cleanly',
      (tester) async {
    await tester.runAsync(() async {
      await AppState().setAuthSession('test_token', {
        'id': 12,
        'name': 'Karim Casa',
        'username': 'karim_casa',
        'email': 'karim@apolo.ma',
        'is_verified': true,
      });
    });

    await tester.pumpWidget(buildApp(const AccountSecurityScreen()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Account security'), findsOneWidget);
    expect(find.byKey(const Key('security-email')), findsOneWidget);
    expect(find.byKey(const Key('security-save-profile')), findsOneWidget);
    expect(find.byKey(const Key('security-save-password')), findsOneWidget);

    await tester.pumpWidget(buildApp(const SupportScreen()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Help & Support'), findsOneWidget);
    expect(find.byKey(const Key('support-report-bug-cta')), findsOneWidget);
    expect(find.text('support@apolo.ma'), findsOneWidget);

    await tester.runAsync(() => AppState().setLocale(const Locale('ar')));
    await tester.pumpWidget(buildApp(const SettingsScreen()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('الإعدادات والنشاط'), findsOneWidget);
    expect(find.text('مركز حساب أبولو'), findsOneWidget);
  });
}
