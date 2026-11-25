import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apolo_mobile/account/account_helpers.dart';
import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/screens/auth_screen.dart';
import 'package:apolo_mobile/theme/app_theme.dart';
import 'account_helpers_test.dart' show MockAccountAdapter, json;

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppState().currentUser = null;
    await AppState().initialize();
  });

  testWidgets(
      'Dynamic Layer v5.1 5-step Sign up wizard matches Figma 25680:46408 geometry and completes OTP verification',
      (tester) async {
    await tester.runAsync(() => AppState().setLocale(const Locale('en')));
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Map<String, dynamic>? registerPayload;
    final adapter = MockAccountAdapter((options) {
      if (options.path == '/auth/register') {
        registerPayload = Map<String, dynamic>.from(options.data as Map);
        return json(
            '{"status":"success","requires_otp":true,"token":"pending_reg","user":{"id":99,"name":"Joshua","email":"mail@gmail.com"}}');
      }
      if (options.path == '/auth/otp/verify') {
        return json(
            '{"status":"success","token":"verified_reg","user":{"id":99,"name":"Joshua","username":"joshua","email":"mail@gmail.com","email_verified_at":"2026-01-01"}}');
      }
      return json('{}');
    });

    final client = Dio()..httpClientAdapter = adapter;

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(const Locale('en')),
      home: AuthScreen(
        initialRegisterMode: true,
        auth: AccountAuth(client: client),
      ),
    ));
    await tester.pumpAndSettle();

    Material submitMat() => tester.widget<Material>(
          find.ancestor(
            of: find.byKey(const Key('auth-submit')),
            matching: find.byType(Material),
          ).first,
        );

    // TopNav & wrapper geometry (375x812, 40x40 back circle, 16/32/16/32 margins, 56px Continue)
    expect(find.byKey(const Key('dl-signup-top-nav')), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('auth-dismiss'))),
        const Size(40.0, 40.0));
    expect(find.byType(Divider), findsNothing);
    final wrapperPad =
        tester.widget<Padding>(find.byKey(const Key('dl-signup-wrapper')));
    expect(wrapperPad.padding, const EdgeInsets.fromLTRB(16, 32, 16, 32));
    expect(tester.getSize(find.byKey(const Key('auth-submit'))).height, 56.0);

    // STEP 1: "What's your email?"
    expect(find.text("What's your email?"), findsOneWidget);
    expect(
        tester
            .widget<TextField>(find.byKey(const Key('auth-email')))
            .decoration
            ?.hintText,
        'example@gmail.com');
    expect(find.byKey(const Key('dl-signup-helper-text')), findsNothing);
    expect(submitMat().color, const Color(0xFFEEEEEE));

    await tester.enterText(find.byKey(const Key('auth-email')), 'bad-email');
    await tester.pump();
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dl-signup-error-text')), findsOneWidget);

    await tester.enterText(
        find.byKey(const Key('auth-email')), 'mail@gmail.com');
    await tester.pump();
    expect(submitMat().color, const Color(0xFF000000));
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();

    // STEP 2: "Choose a password" + "Your password must be at least 8 characters"
    expect(find.text('Choose a password'), findsOneWidget);
    expect(find.text('Your password must be at least 8 characters'),
        findsOneWidget);
    expect(submitMat().color, const Color(0xFFEEEEEE));

    await tester.enterText(find.byKey(const Key('auth-password')), 'short');
    await tester.pump();
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dl-signup-error-text')), findsOneWidget);

    await tester.enterText(
        find.byKey(const Key('auth-password')), 'secret123');
    await tester.pump();
    expect(submitMat().color, const Color(0xFF000000));
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();

    // STEP 3: "What's your first name?"
    expect(find.text("What's your first name?"), findsOneWidget);
    expect(find.byKey(const Key('dl-signup-helper-text')), findsNothing);
    expect(submitMat().color, const Color(0xFFEEEEEE));

    await tester.enterText(find.byKey(const Key('reg-first-name')), 'Joshua');
    await tester.pump();
    expect(submitMat().color, const Color(0xFF000000));
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();

    // STEP 4: "Pick a username" + "@joshua" prefix + "Others can find you with your username!"
    expect(find.text('Pick a username'), findsOneWidget);
    expect(
        find.text('Others can find you with your username!'), findsOneWidget);
    expect(submitMat().color, const Color(0xFFEEEEEE));

    await tester.enterText(find.byKey(const Key('reg-username')), 'Joshua');
    await tester.pump();
    final usernameField =
        tester.widget<TextField>(find.byKey(const Key('reg-username')));
    expect(usernameField.controller?.text, '@joshua');
    expect(submitMat().color, const Color(0xFF000000));
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();

    // STEP 5: "What's your phone number?" (required by /auth/register)
    expect(find.text("What's your phone number?"), findsOneWidget);
    expect(submitMat().color, const Color(0xFFEEEEEE));

    // Verify `<` back returns cleanly to Step 4 with `@joshua` preserved, then forward again
    await tester.tap(find.byKey(const Key('auth-dismiss')));
    await tester.pumpAndSettle();
    expect(find.text('Pick a username'), findsOneWidget);
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();
    expect(find.text("What's your phone number?"), findsOneWidget);

    await tester.enterText(
        find.byKey(const Key('auth-phone')), '0612345678');
    await tester.pump();
    expect(submitMat().color, const Color(0xFF000000));
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();

    // Verify /auth/register payload
    expect(registerPayload, isNotNull);
    expect(registerPayload!['name'], 'Joshua');
    expect(registerPayload!['email'], 'mail@gmail.com');
    expect(registerPayload!['username'], 'joshua');
    expect(registerPayload!['phone'], '+212612345678');

    // STEP 6: OTP Verification
    expect(find.byKey(const Key('auth-code')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('auth-code')), '123456');
    await tester.pumpAndSettle();

    expect(AppState().isLoggedIn, isTrue);
    expect(AppState().currentUser?['username'], 'joshua');
  });

  testWidgets('Login Step 1 Sign up pill switches cleanly to Sign up and back',
      (tester) async {
    await tester.runAsync(() => AppState().setLocale(const Locale('en')));
    final client = Dio()
      ..httpClientAdapter = MockAccountAdapter((_) => json('{}'));
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(const Locale('en')),
      home: AuthScreen(auth: AccountAuth(client: client)),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Enter your email'), findsOneWidget);
    await tester.tap(find.byKey(const Key('auth-switch-to-signup')));
    await tester.pumpAndSettle();

    expect(find.text("What's your email?"), findsOneWidget);
    await tester.tap(find.byKey(const Key('auth-dismiss')));
    await tester.pumpAndSettle();
    expect(find.text('Enter your email'), findsOneWidget);
  });
}
