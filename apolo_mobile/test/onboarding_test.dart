import 'dart:typed_data';

import 'package:apolo_mobile/core/config/app_config.dart';
import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/screens/auth_screen.dart';
import 'package:apolo_mobile/screens/main_shell.dart';
import 'package:apolo_mobile/screens/splash_screen.dart';
import 'package:apolo_mobile/screens/welcome_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
        '{"status":"success","categories":[],"cities":[],"data":[]}',
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        },
      );

  @override
  void close({bool force = false}) {}
}

Widget _app(Widget home, {double scale = 1, bool reducedMotion = false}) {
  return MaterialApp(
    locale: AppState().locale,
    supportedLocales: const [Locale('ar'), Locale('fr')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: AppConfig.buildTheme(AppState().locale)
        .copyWith(splashFactory: NoSplash.splashFactory),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale),
        disableAnimations: reducedMotion,
      ),
      child: child!,
    ),
    home: home,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpClientAdapter originalAdapter;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    originalAdapter = AppState().api.dio.httpClientAdapter;
    AppState().api.dio.httpClientAdapter = _OfflineAdapter();
    AppState().currentUser = null;
    await AppState().initialize();
  });

  tearDown(() {
    AppState().api.dio.httpClientAdapter = originalAdapter;
  });

  for (final language in ['ar', 'fr']) {
    for (final size in [
      const Size(320, 568),
      const Size(390, 844),
      const Size(844, 390),
      const Size(1024, 768),
    ]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('$language welcome fits $size at text scale $scale', (
          tester,
        ) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          if (language == 'fr') {
            await tester.runAsync(() => AppState().toggleLanguage());
          }
          var completed = 0;
          await tester.pumpWidget(_app(
            WelcomeScreen(onContinueAsGuest: () => completed++),
            scale: scale,
            reducedMotion: true,
          ));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final primary = find.byKey(const ValueKey('welcome-sign-in'));
          expect(
            Directionality.of(tester.element(primary)),
            language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          );
          final guest = find.byKey(const ValueKey('welcome-guest'));
          await tester.ensureVisible(guest);
          await tester.pumpAndSettle();
          expect(tester.getSize(primary).height, greaterThanOrEqualTo(48));
          await tester.tap(guest);
          await tester.pump();
          expect(completed, 1);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(seconds: 1));
        });
      }
    }
  }

  testWidgets('language switch changes copy and reading direction', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const WelcomeScreen()));
    await tester.pumpAndSettle();
    final language = find.byKey(const ValueKey('welcome-language'));
    await tester.tap(language);
    await tester.pumpAndSettle();
    expect(find.text('Se connecter'), findsOneWidget);
    expect(Directionality.of(tester.element(language)), TextDirection.ltr);
    await tester.tap(language);
    await tester.pumpAndSettle();
    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(Directionality.of(tester.element(language)), TextDirection.rtl);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sign in opens auth and cancellation returns to welcome', (
    tester,
  ) async {
    var completed = 0;
    await tester.pumpWidget(_app(
      WelcomeScreen(onContinueAsGuest: () => completed++),
      reducedMotion: true,
    ));
    final register = find.byKey(const ValueKey('welcome-register'));
    await tester.ensureVisible(register);
    await tester.tap(register);
    await tester.pumpAndSettle();
    final auth = tester.widget<AuthScreen>(find.byType(AuthScreen));
    expect(auth.initialIsLogin, isFalse);
    expect(auth.autoTriggerGoogle, isFalse);
    expect(completed, 0);
    final route = ModalRoute.of(tester.element(find.byType(AuthScreen)))!;
    expect(route.transitionDuration, Duration.zero);
    Navigator.of(tester.element(find.byType(AuthScreen))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(completed, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('auth success preserves onboarding completion callback', (
    tester,
  ) async {
    var completed = 0;
    await tester.pumpWidget(_app(
      WelcomeScreen(onContinueAsGuest: () => completed++),
    ));
    final primary = find.byKey(const ValueKey('welcome-sign-in'));
    await tester.ensureVisible(primary);
    await tester.tap(primary);
    await tester.pumpAndSettle();
    tester.widget<AuthScreen>(find.byType(AuthScreen)).onSuccess!();
    expect(completed, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('splash is brief, static, and forwards to target', (
    tester,
  ) async {
    var completed = 0;
    await tester.pumpWidget(_app(
      SplashScreen(
        duration: const Duration(milliseconds: 650),
        hasSeenWelcome: false,
        targetWelcome: true,
        onCompleteWelcome: () => completed++,
      ),
      reducedMotion: true,
    ));
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pump(const Duration(milliseconds: 649));
    expect(find.byType(WelcomeScreen), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
    final route = ModalRoute.of(tester.element(find.byType(WelcomeScreen)))!;
    expect(route.transitionDuration, Duration.zero);
    final guest = find.byKey(const ValueKey('welcome-guest'));
    await tester.ensureVisible(guest);
    await tester.tap(guest);
    expect(completed, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('disposing splash cancels its pending navigation',
      (tester) async {
    await tester.pumpWidget(_app(const SplashScreen(hasSeenWelcome: false)));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}
