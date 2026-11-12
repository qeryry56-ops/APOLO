import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apolo_mobile/account/account_helpers.dart';
import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/screens/auth_screen.dart';
import 'account_helpers_test.dart' show MockAccountAdapter, json;

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppState().currentUser = null;
    await AppState().initialize();
  });

  testWidgets('register multi-step wizard progresses through all 4 steps',
      (tester) async {
    final adapter = MockAccountAdapter((options) {
      if (options.path == '/taxonomy') {
        return json(
            '{"status":"success","cities":[{"id":1,"name_ar":"الدار البيضاء","name_fr":"Casablanca"}],"categories":[{"id":1,"name_ar":"هواتف","name_fr":"Téléphones"}]}');
      }
      if (options.path == '/auth/register') {
        return json(
            '{"status":"success","requires_otp":true,"token":"pending_reg","user":{"id":99,"name":"Amine Test","email":"amine@test.ma"}}');
      }
      if (options.path == '/auth/otp/verify') {
        return json(
            '{"status":"success","token":"verified_reg","user":{"id":99,"name":"Amine Test","email":"amine@test.ma","email_verified_at":"2026-01-01"}}');
      }
      return json('{}');
    });

    final client = Dio()..httpClientAdapter = adapter;

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: AuthScreen(
        initialRegisterMode: true,
        auth: AccountAuth(client: client),
      ),
    ));
    await tester.pumpAndSettle();

    // STEP 1: Verify Name & Gender inputs
    expect(find.byKey(const Key('reg-first-name')), findsOneWidget);
    expect(find.byKey(const Key('reg-last-name')), findsOneWidget);
    expect(find.text('ذكر'), findsOneWidget);
    expect(find.text('أنثى'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('reg-first-name')), 'Amine');
    await tester.enterText(find.byKey(const Key('reg-last-name')), 'El Amrani');
    await tester.ensureVisible(find.byKey(const Key('reg-step1-continue')));
    await tester.tap(find.byKey(const Key('reg-step1-continue')));
    await tester.pumpAndSettle();

    // STEP 2: Verify DOB & Buyer/Seller cards
    expect(find.byKey(const Key('reg-dob')), findsOneWidget);
    expect(find.text('مشتري'), findsOneWidget);
    expect(find.text('بائع'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('reg-dob')), '2000-01-01');
    await tester.ensureVisible(find.text('بائع'));
    await tester.tap(find.text('بائع'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('reg-step2-continue')));
    await tester.tap(find.byKey(const Key('reg-step2-continue')));
    await tester.pumpAndSettle();

    // STEP 3: Verify Credentials (Email, Password, Confirm)
    expect(find.byKey(const Key('auth-email')), findsOneWidget);
    expect(find.byKey(const Key('auth-password')), findsOneWidget);
    expect(find.byKey(const Key('auth-confirmation')), findsOneWidget);

    await tester.enterText(
        find.byKey(const Key('auth-email')), 'amine@test.ma');
    await tester.enterText(
        find.byKey(const Key('auth-password')), 'secret123');
    await tester.enterText(
        find.byKey(const Key('auth-confirmation')), 'secret123');
    await tester.ensureVisible(find.byKey(const Key('auth-submit')));
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();

    // STEP 4: OTP Verification
    expect(find.byKey(const Key('auth-code')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('auth-code')), '123456');
    await tester.ensureVisible(find.byKey(const Key('auth-submit')));
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();

    // Verify authentication completed
    expect(AppState().isLoggedIn, isTrue);
  });
}
