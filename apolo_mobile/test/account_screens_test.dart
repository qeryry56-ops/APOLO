import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apolo_mobile/account/account_helpers.dart';
import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/screens/auth_screen.dart';
import 'package:apolo_mobile/screens/forgot_password_screen.dart';
import 'package:apolo_mobile/screens/settings_screen.dart';
import 'package:apolo_mobile/theme/app_theme.dart';
import 'account_helpers_test.dart' show MockAccountAdapter, json;

class DeferredAuth extends AccountAuth {
  final completer = Completer<AccountSession>();
  @override
  Future<AccountSession> login(String email, String password) =>
      completer.future;
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppState().currentUser = null;
    await AppState().api.setToken(null);
  });

  Future<void> credentials(WidgetTester tester) async {
    await tester.enterText(
        find.byKey(const Key('auth-email')), 'test@example.ma');
    await tester.pump();
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('auth-password')), 'password');
    await tester.pump();
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();
  }

  testWidgets('Arabic credentials stay LTR and invalid input makes no request',
      (tester) async {
    final adapter = MockAccountAdapter((_) => json('{}'));
    final client = Dio()..httpClientAdapter = adapter;
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: AuthScreen(auth: AccountAuth(client: client))));

    expect(
        tester
            .widget<EditableText>(find.descendant(
                of: find.byKey(const Key('auth-email')),
                matching: find.byType(EditableText)))
            .textDirection,
        TextDirection.ltr);

    // Invalid email on Step 1 shows error and sends zero requests
    await tester.enterText(find.byKey(const Key('auth-email')), 'not-an-email');
    await tester.pump();
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dl-login-error-text')), findsOneWidget);
    expect(adapter.requests, isEmpty);
    expect(AppState().isLoggedIn, isFalse);

    // Valid email advances to Step 2 where password also stays LTR
    await tester.enterText(
        find.byKey(const Key('auth-email')), 'test@example.ma');
    await tester.pump();
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<EditableText>(find.descendant(
                of: find.byKey(const Key('auth-password')),
                matching: find.byType(EditableText)))
            .textDirection,
        TextDirection.ltr);
  });

  testWidgets('OTP failure stays pending without persisting a token',
      (tester) async {
    final adapter = MockAccountAdapter((options) => options.path ==
            '/auth/login'
        ? json('{"token":"pending","user":{"id":7,"email_verified_at":null}}')
        : json('{"status":"error"}'));
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: AuthScreen(
            auth: AccountAuth(client: Dio()..httpClientAdapter = adapter))));
    await credentials(tester);
    expect(find.byKey(const Key('auth-code')), findsOneWidget);
    expect(AppState().api.isAuthenticated, isFalse);
    expect((await SharedPreferences.getInstance()).getString('auth_token'),
        isNull);
    await tester.enterText(find.byKey(const Key('auth-code')), '123456');
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('auth-code')), findsOneWidget);
    expect(AppState().isLoggedIn, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'successful callback pushes destination after auth route is popped',
      (tester) async {
    final state = AppState();
    final original = state.api.dio;
    state.api.dio = Dio()
      ..httpClientAdapter =
          MockAccountAdapter((_) => json('{"status":"success","data":[]}'));
    addTearDown(() {
      state.api.dio = original;
    });
    final auth = AccountAuth(
        client: Dio()
          ..httpClientAdapter = MockAccountAdapter((_) => json(
              '{"token":"verified","user":{"id":7,"email_verified_at":"2026-01-01","onboarding_completed":true}}')));
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        navigatorKey: navigator,
        home: const Scaffold(body: Text('Root'))));
    navigator.currentState!.push(MaterialPageRoute(
        builder: (_) => AuthScreen(
            auth: auth,
            onSuccess: () {
              navigator.currentState!.push(MaterialPageRoute(
                  builder: (_) => const Scaffold(body: Text('Destination'))));
            })));
    await tester.pumpAndSettle();
    await credentials(tester);
    expect(find.text('Destination'), findsOneWidget);
    expect(find.byType(AuthScreen), findsNothing);
    expect(state.isLoggedIn, isTrue);
  });

  testWidgets('late response after leaving never creates an account',
      (tester) async {
    final auth = DeferredAuth();
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: AuthScreen(auth: auth)));
    await tester.enterText(
        find.byKey(const Key('auth-email')), 'test@example.ma');
    await tester.pump();
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('auth-password')), 'password');
    await tester.pump();
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    auth.completer
        .complete(const AccountSession('late', {'id': 7}, requiresOtp: false));
    await tester.pump();
    expect(AppState().isLoggedIn, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'settings has no misleading local privacy switches or verification badge',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: SettingsScreen()));
    expect(find.byType(Switch), findsNothing);
    expect(find.byIcon(Icons.verified), findsNothing);
    expect(find.text('Amine'), findsNothing);
    expect(find.byIcon(Icons.help_outline), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });

  group('Dynamic Layer v5.1 2-Step Login UI', () {
    testWidgets(
        'matches Figma 375x812 geometry across Enter Email, Enter Password, Filled, Error, and Forgot Password pill',
        (tester) async {
      await tester.runAsync(() => AppState().setLocale(const Locale('en')));
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final adapter = MockAccountAdapter((_) => json('{}'));
      final client = Dio()..httpClientAdapter = adapter;

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(const Locale('en')),
        home: AuthScreen(auth: AccountAuth(client: client)),
      ));
      await tester.pumpAndSettle();

      // 1. Clean 56px TopNavigation with 40x40 circular #EEEEEE back button & no Divider
      expect(find.byKey(const Key('dl-login-top-nav')), findsOneWidget);
      expect(tester.getSize(find.byKey(const Key('auth-dismiss'))),
          const Size(40.0, 40.0));
      expect(find.byType(Divider), findsNothing);

      // 2. Wrapper margins match Figma (top 32, right 16, bottom 32, left 16)
      final wrapperPad =
          tester.widget<Padding>(find.byKey(const Key('dl-login-wrapper')));
      expect(wrapperPad.padding, const EdgeInsets.fromLTRB(16, 32, 16, 32));

      // 3. Step 1 Default: "Enter your email", borderless 28px centered input, #EEEEEE 56px Continue pill
      expect(find.text('Enter your email'), findsOneWidget);
      final emailField =
          tester.widget<TextField>(find.byKey(const Key('auth-email')));
      expect(emailField.textAlign, TextAlign.center);
      expect(emailField.style?.fontSize, 28.0);
      expect(emailField.decoration?.hintText, 'example@gmail.com');
      expect(emailField.decoration?.filled, isFalse);
      expect(emailField.decoration?.border, InputBorder.none);

      final submitSize = tester.getSize(find.byKey(const Key('auth-submit')));
      expect(submitSize.height, 56.0);
      Material submitMat() => tester.widget<Material>(
            find.ancestor(
              of: find.byKey(const Key('auth-submit')),
              matching: find.byType(Material),
            ).first,
          );
      expect(submitMat().color, const Color(0xFFEEEEEE));

      // 4. Filled state turns ButtonDock solid #000000 black
      await tester.enterText(
          find.byKey(const Key('auth-email')), 'mail@gmail.com');
      await tester.pump();
      expect(submitMat().color, const Color(0xFF000000));

      // 5. Tapping Continue advances to Step 2 ("Enter your password" + "Forgot password?" pill)
      await tester.tap(find.byKey(const Key('auth-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Enter your password'), findsOneWidget);
      expect(find.byKey(const Key('auth-password')), findsOneWidget);
      expect(find.byKey(const Key('auth-forgot-password-pill')), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(submitMat().color, const Color(0xFFEEEEEE));

      final pwdField =
          tester.widget<TextField>(find.byKey(const Key('auth-password')));
      expect(pwdField.obscureText, isTrue);
      expect(pwdField.textAlign, TextAlign.center);
      expect(pwdField.style?.fontSize, 28.0);
      expect(pwdField.decoration?.hintText, '••••••••');

      // 6. Tapping Forgot password? pill opens Dynamic Layer ForgotPasswordScreen
      await tester.tap(find.byKey(const Key('auth-forgot-password-pill')));
      await tester.pumpAndSettle();
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);

      await tester.tap(find.byKey(const Key('forgot-dismiss')));
      await tester.pumpAndSettle();
      expect(find.byType(ForgotPasswordScreen), findsNothing);

      // 7. Tapping `<` on Step 2 returns cleanly to Step 1
      await tester.tap(find.byKey(const Key('auth-dismiss')));
      await tester.pumpAndSettle();
      expect(find.text('Enter your email'), findsOneWidget);
      expect(find.byKey(const Key('auth-email')), findsOneWidget);
    });

    testWidgets('Dark mode renders #121212 scaffold and #262629 -> #FFFFFF pill cleanly',
        (tester) async {
      await tester.runAsync(() => AppState().setLocale(const Locale('ar')));
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final adapter = MockAccountAdapter((_) => json('{}'));
      final client = Dio()..httpClientAdapter = adapter;

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark(const Locale('ar')),
        home: AuthScreen(auth: AccountAuth(client: client)),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFF121212));

      Material submitMat() => tester.widget<Material>(
            find.ancestor(
              of: find.byKey(const Key('auth-submit')),
              matching: find.byType(Material),
            ).first,
          );
      expect(submitMat().color, const Color(0xFF262629));

      await tester.enterText(
          find.byKey(const Key('auth-email')), '0612345678');
      await tester.pump();
      expect(submitMat().color, Colors.white);
    });
  });
}
