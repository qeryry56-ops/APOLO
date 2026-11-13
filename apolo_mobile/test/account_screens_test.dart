import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apolo_mobile/account/account_helpers.dart';
import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/screens/auth_screen.dart';
import 'package:apolo_mobile/screens/settings_screen.dart';
import 'package:apolo_mobile/theme/app_theme.dart';
import 'package:apolo_mobile/widgets/custom_auth_input_field.dart';
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
    await tester.enterText(find.byKey(const Key('auth-password')), 'password');
    await tester.ensureVisible(find.byKey(const Key('auth-submit')));
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
    expect(
        tester
            .widget<EditableText>(find.descendant(
                of: find.byKey(const Key('auth-password')),
                matching: find.byType(EditableText)))
            .textDirection,
        TextDirection.ltr);
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();
    expect(adapter.requests, isEmpty);
    expect(AppState().isLoggedIn, isFalse);
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
    await tester.enterText(find.byKey(const Key('auth-password')), 'password');
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

  testWidgets('login fields have no grey inner fill and float label on focus',
      (tester) async {
    final adapter = MockAccountAdapter((_) => json('{}'));
    final client = Dio()..httpClientAdapter = adapter;
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(const Locale('en')),
        home: AuthScreen(auth: AccountAuth(client: client))));

    final emailField = tester.widget<TextField>(find.descendant(
        of: find.byKey(const Key('auth-email')),
        matching: find.byType(TextField)));
    final passwordField = tester.widget<TextField>(find.descendant(
        of: find.byKey(const Key('auth-password')),
        matching: find.byType(TextField)));
    expect(emailField.decoration?.filled, isFalse);
    expect(passwordField.decoration?.filled, isFalse);

    final emailWrapper = find.ancestor(
        of: find.byKey(const Key('auth-email')),
        matching: find.byType(CustomAuthInputField));
    final initialLabelPos = tester.widget<AnimatedPositionedDirectional>(
        find.descendant(
            of: emailWrapper,
            matching: find.byType(AnimatedPositionedDirectional)));
    expect(initialLabelPos.top, 18.0);

    await tester.tap(find.byKey(const Key('auth-email')));
    await tester.pumpAndSettle();

    final focusedLabelPos = tester.widget<AnimatedPositionedDirectional>(
        find.descendant(
            of: emailWrapper,
            matching: find.byType(AnimatedPositionedDirectional)));
    expect(focusedLabelPos.top, 8.0);
  });
}
