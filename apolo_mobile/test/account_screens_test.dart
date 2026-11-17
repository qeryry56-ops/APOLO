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

  group('Moroccan RTL Meta-style Login UI', () {
    setUp(() async {
      await AppState().setLocale(const Locale('ar'));
    });

    testWidgets(
        'renders X dismiss, Meta floating inputs, +212 phone detection, 44x44 eye toggle, neutral forgot link, #E31B23 CTA, and social 12px buttons',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final adapter = MockAccountAdapter((_) => json('{}'));
      final client = Dio()..httpClientAdapter = adapter;

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(const Locale('ar')),
        home: AuthScreen(auth: AccountAuth(client: client)),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // 1. Header: single dismiss X, no redundant 'تسجيل الدخول' title in top bar
      expect(find.byKey(const Key('auth-dismiss')), findsOneWidget);
      expect(find.text('مرحباً بك مجدداً'), findsOneWidget);
      expect(
        find.text('أدخل بريدك الإلكتروني أو رقم هاتفك للمتابعة'),
        findsOneWidget,
      );
      // 'تسجيل الدخول' should appear ONLY once (on primary CTA, not repeated in header)
      expect(find.text('تسجيل الدخول'), findsOneWidget);

      // 2. Meta-style 59px inputs, 13px border radius, 1px -> 2px #E31B23 border
      final emailContainerFinder = find.ancestor(
        of: find.byKey(const Key('auth-email')),
        matching: find.byType(AnimatedContainer),
      );
      final emailFieldContainer =
          tester.widget<AnimatedContainer>(emailContainerFinder);
      final BoxDecoration emailDec =
          emailFieldContainer.decoration as BoxDecoration;
      expect(emailDec.borderRadius, BorderRadius.circular(13));
      expect(tester.getSize(emailContainerFinder).height, 59.0);

      // 3. Automatic Moroccan +212 country code pill appears for phone numbers & hides for email
      expect(find.byKey(const Key('auth-phone-prefix')), findsNothing);
      await tester.enterText(
          find.byKey(const Key('auth-email')), '0612345678');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('auth-phone-prefix')), findsOneWidget);
      expect(find.text('+212'), findsOneWidget);

      await tester.enterText(
          find.byKey(const Key('auth-email')), 'amine@apolo.ma');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('auth-phone-prefix')), findsNothing);

      // 4. Password field trailing eye toggle has >= 44x44 tap target and toggles obscurity
      final eyeFinder = find.byIcon(Icons.visibility_outlined);
      expect(eyeFinder, findsOneWidget);
      final eyeHitBox = find.ancestor(
        of: eyeFinder,
        matching: find.byWidgetPredicate(
          (w) => w is SizedBox && w.width == 44 && w.height == 44,
        ),
      );
      expect(eyeHitBox, findsOneWidget);
      expect(
        tester
            .widget<EditableText>(find.descendant(
              of: find.byKey(const Key('auth-password')),
              matching: find.byType(EditableText),
            ))
            .obscureText,
        isTrue,
      );
      await tester.tap(eyeHitBox);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<EditableText>(find.descendant(
              of: find.byKey(const Key('auth-password')),
              matching: find.byType(EditableText),
            ))
            .obscureText,
        isFalse,
      );

      // 5. Neutral Forgot Password link (#6B7280, NOT primary error red)
      final forgotText = tester.widget<Text>(find.text('نسيت كلمة المرور؟'));
      expect(forgotText.style?.color, const Color(0xFF6B7280));

      // 6. Primary CTA: 52px high, 12px radius, solid #E31B23
      final submitBtn =
          tester.widget<ElevatedButton>(find.byKey(const Key('auth-submit')));
      final submitSize = tester.getSize(find.byKey(const Key('auth-submit')));
      expect(submitSize.height, 52.0);
      expect(
        submitBtn.style?.backgroundColor?.resolve(<WidgetState>{}),
        const Color(0xFFE31B23),
      );

      // 7. Social buttons & Divider 'أو'
      expect(find.text('أو'), findsOneWidget);
      expect(find.byKey(const Key('auth-google')), findsOneWidget);
      expect(find.byKey(const Key('auth-apple')), findsOneWidget);
      expect(find.text('المتابعة باستخدام Google'), findsOneWidget);
      expect(find.text('المتابعة باستخدام Apple'), findsOneWidget);
      expect(tester.getSize(find.byKey(const Key('auth-google'))).height, 52.0);
      expect(tester.getSize(find.byKey(const Key('auth-apple'))).height, 52.0);

      // 8. Footer: 'أول مرة هنا؟ ' muted + 'إنشاء حساب'
      expect(find.textContaining('أول مرة هنا؟'), findsOneWidget);
      expect(find.textContaining('إنشاء حساب'), findsOneWidget);
    });
  });
}
