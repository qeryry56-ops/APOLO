import 'dart:typed_data';

import 'package:apolo_mobile/core/config/app_config.dart';
import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/screens/auth_screen.dart';
import 'package:apolo_mobile/screens/intent_onboarding_screen.dart';
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
    supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
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

  for (final language in ['en', 'fr', 'ar']) {
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
          await tester.runAsync(() => AppState().setLocale(Locale(language)));
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

  testWidgets(
      'WelcomeScreen matches Dynamic Layer v5.1 (45786:49327): falling notifications hero, 56px Google + or + Create account + I have an account without Apple',
      (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(const WelcomeScreen()));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('welcome-apple')), findsNothing);
    expect(find.byKey(const Key('dl-welcome-hero')), findsOneWidget);
    expect(find.byKey(const Key('dl-welcome-notif-card-1')), findsOneWidget);
    expect(find.byKey(const Key('dl-welcome-notif-card-2')), findsOneWidget);
    expect(find.byKey(const Key('dl-welcome-chat-bubble-3')), findsOneWidget);
    expect(find.byKey(const Key('dl-welcome-or-divider')), findsOneWidget);

    final googleBtn = find.byKey(const ValueKey('welcome-google'));
    final createBtn = find.byKey(const ValueKey('welcome-create-account'));
    final signInBtn = find.byKey(const ValueKey('welcome-sign-in'));
    expect(googleBtn, findsOneWidget);
    expect(createBtn, findsOneWidget);
    expect(signInBtn, findsOneWidget);

    expect(tester.getSize(googleBtn).height, closeTo(56.0, 0.1));
    expect(tester.getSize(createBtn).height, closeTo(56.0, 0.1));
    expect(tester.getSize(signInBtn).height, closeTo(56.0, 0.1));
    expect(tester.getSize(googleBtn).width, closeTo(343.0, 0.1));
    expect(tester.takeException(), isNull);

    // Tapping Create an account opens AuthScreen in Sign-up mode
    await tester.tap(createBtn);
    await tester.pumpAndSettle();
    final registerAuth = tester.widget<AuthScreen>(find.byType(AuthScreen));
    expect(registerAuth.initialRegisterMode, isTrue);
    expect(registerAuth.initialIsLogin, isFalse);
  });

  testWidgets('sign in opens auth and cancellation returns to welcome', (
    tester,
  ) async {
    var completed = 0;
    await tester.pumpWidget(_app(
      WelcomeScreen(onContinueAsGuest: () => completed++),
      reducedMotion: true,
    ));
    final emailBtn = find.byKey(const ValueKey('welcome-sign-in'));
    await tester.ensureVisible(emailBtn);
    await tester.tap(emailBtn);
    await tester.pumpAndSettle();
    final auth = tester.widget<AuthScreen>(find.byType(AuthScreen));
    expect(auth.initialIsLogin, isTrue);
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

  testWidgets(
      'ApoloIntentOnboardingScreen matches Figma 45952:346 (64/32 margins, tilted pills, + / - toggle, 56px Continue) and saves AppState intents',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    AppState().userIntents = <String>{};
    AppState().hasCompletedIntentOnboarding = false;
    AppState().categoryInterestWeights = <int, int>{};

    Set<String>? completedIntents;
    await tester.pumpWidget(
      _app(
        ApoloIntentOnboardingScreen(
          nextBuilder: (_, chosen) {
            completedIntents = chosen;
            return const Scaffold(body: Center(child: Text('DONE_MAIN')));
          },
        ),
        reducedMotion: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    // Exact Figma `Main Container` margins on 375px width: left 64, top 32, right 64, bottom 32
    final mainContainer = tester.widget<Padding>(
      find.byKey(const Key('dl-intent-main-container')),
    );
    expect(
      mainContainer.padding,
      const EdgeInsets.fromLTRB(64.0, 32.0, 64.0, 32.0),
    );

    // 40x40 back circle & 56px Continue stadium button
    final backSize =
        tester.getSize(find.byKey(const Key('dl-intent-back-button')));
    expect(backSize, const Size(40.0, 40.0));
    final continueSize =
        tester.getSize(find.byKey(const Key('dl-intent-continue-button')));
    expect(continueSize.height, closeTo(56.0, 0.01));

    // Toggle `auto_immo` pill ON in addition to default `selling`
    await tester.tap(find.byKey(const Key('dl-intent-pill-auto_immo')));
    await tester.pumpAndSettle();

    // Tap Continue -> persists to AppState & boosts Vehicles/RealEstate weights
    await tester.tap(find.byKey(const Key('dl-intent-continue-button')));
    await tester.pumpAndSettle();

    expect(find.text('DONE_MAIN'), findsOneWidget);
    expect(completedIntents, containsAll(<String>['selling', 'auto_immo']));
    expect(AppState().hasCompletedIntentOnboarding, isTrue);
    expect(AppState().categoryInterestWeights[2], greaterThanOrEqualTo(10));
    expect(AppState().categoryInterestWeights[5], greaterThanOrEqualTo(10));
  });
}
