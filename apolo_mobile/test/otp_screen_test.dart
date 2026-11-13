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
    await AppState().api.setToken(null);
    await AppState().setLocale(const Locale('en'));
  });

  test('AccountValidation.maskEmail masks safely', () {
    expect(AccountValidation.maskEmail('amine@gmail.com'), 'am***@gmail.com');
    expect(AccountValidation.maskEmail('a@b.ma'), 'a***@b.ma');
    expect(AccountValidation.maskEmail(''), isNull);
    expect(AccountValidation.maskEmail('invalid'), isNull);
  });

  testWidgets(
      'phone login with unverified email auto-dispatches OTP, displays masked email, and verifies 6-digit code',
      (tester) async {
    final state = AppState();
    final original = state.api.dio;
    state.api.dio = Dio()
      ..httpClientAdapter =
          MockAccountAdapter((_) => json('{"status":"success","data":[]}'));
    addTearDown(() {
      state.api.dio = original;
    });

    final adapter = MockAccountAdapter((options) {
      if (options.path == '/auth/login') {
        return json(
            '{"token":"pending-login","user":{"id":7,"email":"amine@apolo.ma","email_verified_at":null}}');
      }
      if (options.path == '/auth/otp/resend') {
        return json('{"status":"success","message":"Sent"}');
      }
      if (options.path == '/auth/otp/verify') {
        return json(
            '{"status":"success","user":{"id":7,"email":"amine@apolo.ma","email_verified_at":"2026-11-13"}}');
      }
      return json('{"status":"success","data":[]}');
    });

    final client = Dio()..httpClientAdapter = adapter;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: AuthScreen(auth: AccountAuth(client: client)),
    ));

    await tester.enterText(find.byKey(const Key('auth-email')), '0612345678');
    await tester.enterText(find.byKey(const Key('auth-password')), 'secret123');
    await tester.ensureVisible(find.byKey(const Key('auth-submit')));
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();

    expect(
      adapter.requests.map((r) => r.path).toList(),
      ['/auth/login', '/auth/otp/resend'],
    );
    expect(adapter.requests.last.data, {'email': 'amine@apolo.ma'});
    expect(find.text("Let's confirm it's you"), findsOneWidget);
    expect(find.textContaining('am***@apolo.ma'), findsWidgets);
    expect(
      find.textContaining('Apolo will never ask you to set up a new account'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('auth-code')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('auth-code')), '741218');
    await tester.pump(const Duration(milliseconds: 220));
    await tester.pumpAndSettle();

    expect(adapter.requests.last.path, '/auth/otp/verify');
    expect(adapter.requests.last.data, {'code': '741218'});
    expect(AppState().isLoggedIn, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'failed initial OTP dispatch keeps resend immediately available without 60s lock',
      (tester) async {
    int resendCount = 0;
    final adapter = MockAccountAdapter((options) {
      if (options.path == '/auth/login') {
        return json(
            '{"token":"pending-login","user":{"id":7,"email":"amine@apolo.ma","email_verified_at":null}}');
      }
      if (options.path == '/auth/otp/resend') {
        resendCount++;
        if (resendCount == 1) {
          return json('{"status":"error","message":"SMTP timeout"}');
        }
        return json('{"status":"success"}');
      }
      return json('{}');
    });

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: AuthScreen(auth: AccountAuth(client: Dio()..httpClientAdapter = adapter)),
    ));

    await tester.enterText(find.byKey(const Key('auth-email')), '0612345678');
    await tester.enterText(find.byKey(const Key('auth-password')), 'secret123');
    await tester.ensureVisible(find.byKey(const Key('auth-submit')));
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();

    expect(resendCount, 1);
    expect(find.text('SMTP timeout'), findsOneWidget);
    expect(find.byKey(const Key('otp-resend')), findsOneWidget);
    expect(find.text('Resend'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('otp-resend')));
    await tester.tap(find.byKey(const Key('otp-resend')));
    await tester.pumpAndSettle();

    expect(resendCount, 2);
    expect(find.textContaining('am***@apolo.ma'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });
}
