import 'dart:async';
import 'dart:typed_data';

import 'package:apolo_mobile/core/config/app_config.dart';
import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/screens/pro_plus_screen.dart';
import 'package:apolo_mobile/screens/search_screen.dart';
import 'package:apolo_mobile/theme/app_theme.dart';
import 'package:apolo_mobile/widgets/apolo_infeed_upgrade_card.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _OfflineExploreAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final state = AppState();
  late Dio originalDio;
  late Locale originalLocale;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppConfig.enablePremiumAndBusinessTiers = true;
    originalDio = state.api.dio;
    originalLocale = state.locale;
    state.api.dio = Dio(BaseOptions(baseUrl: 'https://offline.invalid'))
      ..httpClientAdapter = _OfflineExploreAdapter();
    state.currentUser = {
      'id': 33,
      'name': 'Amine Elas',
      'username': 'elas_amine',
      'is_pro_plus': false,
      'account_type': 'individual',
    };
    state.resetInFeedUpgradePromoForTesting();
    await state.api.setToken('tok-33');
    await state.setLocale(const Locale('en'));
  });

  tearDown(() async {
    state.resetInFeedUpgradePromoForTesting();
    state.currentUser = null;
    await state.api.setToken(null);
    await state.setLocale(originalLocale);
    state.api.dio = originalDio;
  });

  testWidgets(
      'Scrolling Explore reveals Instagram-style Upgrade your profile card with user handle + verified preview, opens 99 MAD Paywall, and dismisses on Not now / ×',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      AnimatedBuilder(
        animation: state,
        builder: (context, _) => MaterialApp(
          theme: AppTheme.light(state.locale)
              .copyWith(splashFactory: NoSplash.splashFactory),
          darkTheme: AppTheme.dark(state.locale)
              .copyWith(splashFactory: NoSplash.splashFactory),
          themeMode: ThemeMode.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: const SearchScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));

    // Scroll down past the first 2 listings -> Instagram-style Upgrade card appears inline!
    await tester.drag(
      find.byType(CustomScrollView),
      const Offset(0, -680),
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byKey(const Key('apolo-infeed-upgrade-card')), findsOneWidget);
    // Cardless open section: root is a transparent SizedBox (not a boxed card Container)
    expect(
      tester.widget(find.byKey(const Key('apolo-infeed-upgrade-card'))),
      isA<SizedBox>(),
    );
    // Uses Dynamic Layer monochrome stadium CTA (`#FFFFFF` in Dark Mode)
    final ctaDec = tester
        .widget<Container>(find.byKey(const Key('infeed-upgrade-cta-btn')))
        .decoration as BoxDecoration;
    expect(ctaDec.color, const Color(0xFFFFFFFF));
    expect(ctaDec.borderRadius, BorderRadius.circular(999));
    expect(find.byType(ApoloInFeedUpgradePromoCard), findsOneWidget);
    expect(find.text('Apolo Premium'), findsOneWidget);
    expect(find.text('elas_amine'), findsOneWidget);
    expect(
      find.byKey(const Key('infeed-upgrade-verified-preview')),
      findsOneWidget,
    );
    expect(find.text('Upgrade your profile'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);

    // Tapping "Upgrade your profile" opens ProPlusScreen (99 MAD/mo • Google Pay)
    await tester.ensureVisible(find.byKey(const Key('infeed-upgrade-cta-btn')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('infeed-upgrade-cta-btn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(ProPlusScreen), findsOneWidget);
    expect(find.textContaining('99'), findsWidgets);
    expect(find.textContaining('Google Pay'), findsWidgets);

    // Dismiss paywall, then tap "Not now" -> card disappears smoothly from feed
    await tester.tap(find.byKey(const Key('dl-paywall-no-thanks-btn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('apolo-infeed-upgrade-card')), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('infeed-upgrade-not-now-btn')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('infeed-upgrade-not-now-btn')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('apolo-infeed-upgrade-card')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Active Apolo Premium subscribers never see the in-feed Upgrade card; Arabic RTL renders cleanly',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(() => state.setLocale(const Locale('ar')));

    await tester.pumpWidget(
      AnimatedBuilder(
        animation: state,
        builder: (context, _) => MaterialApp(
          theme: AppTheme.light(const Locale('ar')),
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: ApoloInFeedUpgradePromoCard(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ترقية ملفك الشخصي'), findsOneWidget);
    expect(find.text('ليس الآن'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Upgrade user to Premium -> card hides automatically
    state.currentUser = {
      ...state.currentUser!,
      'is_pro_plus': true,
      'account_type': 'pro_plus',
    };
    state.notifyListeners();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('apolo-infeed-upgrade-card')), findsNothing);
  });
}
