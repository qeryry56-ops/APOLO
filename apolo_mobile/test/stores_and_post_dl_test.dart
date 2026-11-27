import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:apolo_mobile/core/config/app_config.dart';
import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/screens/post_ad_screen.dart';
import 'package:apolo_mobile/screens/pro_plus_screen.dart';
import 'package:apolo_mobile/screens/store_detail_screen.dart';
import 'package:apolo_mobile/screens/stores_screen.dart';
import 'package:apolo_mobile/theme/app_theme.dart';
import 'package:apolo_mobile/widgets/apolo_badges_kit.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockMarketplaceAdapter implements HttpClientAdapter {
  final FutureOr<ResponseBody> Function(RequestOptions options) handler;

  _MockMarketplaceAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return await handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object payload, [int status = 200]) {
  return ResponseBody.fromString(
    jsonEncode(payload),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
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
    state.categories = [
      {'id': 1, 'name': 'Vehicles', 'name_fr': 'Véhicules', 'name_ar': 'مركبات'},
      {'id': 2, 'name': 'Phones', 'name_fr': 'Téléphones', 'name_ar': 'هواتف'},
    ];
    state.cities = [
      {'id': 1, 'name': 'Casablanca', 'name_fr': 'Casablanca', 'name_ar': 'الدار البيضاء'},
      {'id': 2, 'name': 'Rabat', 'name_fr': 'Rabat', 'name_ar': 'الرباط'},
    ];
    state.currentUser = {'id': 5, 'name': 'Amine', 'phone': '0611223344'};
    state.resetDailyAdsForTesting(0);
    await state.api.setToken('tok-store');
    await state.setLocale(const Locale('en'));
  });

  tearDown(() async {
    AppConfig.enablePremiumAndBusinessTiers = true;
    state.resetDailyAdsForTesting(0);
    state.currentUser = null;
    await state.api.setToken(null);
    await state.setLocale(originalLocale);
    state.api.dio = originalDio;
  });

  testWidgets(
      'StoresScreen and StoreDetailScreen render Dynamic Layer v5.1 verified storefronts in EN & AR RTL',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    state.api.dio = Dio(BaseOptions(baseUrl: 'https://tests.invalid'))
      ..httpClientAdapter = _MockMarketplaceAdapter((req) {
        if (req.path == '/stores') {
          return _json({
            'status': 'success',
            'meta': {'current_page': 1, 'last_page': 1, 'total': 1},
            'data': [
              {
                'id': 10,
                'name': 'Atlas Motors Pro',
                'subdomain': 'atlas-motors',
                'business_category': 'vehicles',
                'location': 'Casablanca',
                'average_rating': 4.9,
                'active_products_count': 12,
                'is_pro_plus': true,
                'is_verified': true,
              },
            ],
          });
        }
        if (req.path == '/stores/atlas-motors') {
          return _json({
            'status': 'success',
            'store': {
              'id': 10,
              'name': 'Atlas Motors Pro',
              'subdomain': 'atlas-motors',
              'business_category': 'vehicles',
              'location': 'Casablanca, Maarif',
              'working_hours': '09:00 - 20:00',
              'is_open_now': true,
              'phone': '+212600000000',
              'is_pro_plus': true,
              'direct_order_enabled': true,
            },
            'products': [
              {
                'id': 501,
                'title': 'Mercedes C220 AMG',
                'price': 320000,
                'price_formatted': '320,000 MAD',
                'negotiable': true,
                'city_en': 'Casablanca',
              },
            ],
          });
        }
        return _json({'status': 'success'});
      });

    await tester.pumpWidget(
      AnimatedBuilder(
        animation: state,
        builder: (context, _) => MaterialApp(
          theme: AppTheme.light(state.locale)
              .copyWith(splashFactory: NoSplash.splashFactory),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: const StoresScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Atlas Motors Pro'), findsOneWidget);
    expect(find.byType(ApoloVerifiedBadge), findsWidgets);

    // Navigate into StoreDetailScreen
    await tester.tap(find.text('Atlas Motors Pro'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(StoreDetailScreen), findsOneWidget);
    expect(find.text('Mercedes C220 AMG'), findsOneWidget);
    expect(find.text('Store Catalog'), findsOneWidget);

    // Switch to Arabic RTL and verify zero overflow
    await tester.runAsync(() => state.setLocale(const Locale('ar')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('منتجات المتجر'), findsOneWidget);
  });

  testWidgets('PostAdScreen 4-step Dynamic Layer v5.1 wizard advances cleanly',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    state.api.dio = Dio(BaseOptions(baseUrl: 'https://tests.invalid'))
      ..httpClientAdapter = _MockMarketplaceAdapter(
        (_) => _json({'status': 'success', 'ad': {'id': 999}}),
      );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(const Locale('en'))
            .copyWith(splashFactory: NoSplash.splashFactory),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: const PostAdScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('1/4'), findsOneWidget);

    // Select city & category
    await tester.tap(find.text('Rabat'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('post-ad-scroll-view')),
      const Offset(0, -260),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Phones'));
    await tester.pumpAndSettle();

    // Step 1 -> Step 2
    await tester.tap(find.byKey(const Key('post-ad-continue-btn')));
    await tester.pumpAndSettle();
    expect(find.text('2/4'), findsOneWidget);

    // Step 2 -> Step 3
    await tester.tap(find.byKey(const Key('post-ad-continue-btn')));
    await tester.pumpAndSettle();
    expect(find.text('3/4'), findsOneWidget);

    // Enter title -> Step 4
    await tester.enterText(
      find.byKey(const Key('post-ad-title-field')),
      'iPhone 16 Pro Max 256GB',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('post-ad-continue-btn')));
    await tester.pumpAndSettle();
    expect(find.text('4/4'), findsOneWidget);

    // Enter price & publish -> Celebration screen
    await tester.enterText(
      find.byKey(const Key('post-ad-price-field')),
      '11500',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('post-ad-continue-btn')));
    await tester.pumpAndSettle();

    expect(find.text('LIVE'), findsOneWidget);
    expect(state.todayPostedAdsCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'PostAdScreen enforces 5/day limit on Personal users with 99 MAD Google Pay upgrade and allows unlimited for Premium',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    state.api.dio = Dio(BaseOptions(baseUrl: 'https://tests.invalid'))
      ..httpClientAdapter = _MockMarketplaceAdapter(
        (_) => _json({'status': 'error'}, 404),
      );

    // Personal user who already published 5 ads today
    state.resetDailyAdsForTesting(5);
    expect(state.hasReachedDailyAdLimit, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(const Locale('en'))
            .copyWith(splashFactory: NoSplash.splashFactory),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: const PostAdScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('post-ad-daily-quota-pill')), findsOneWidget);
    expect(find.textContaining('5/5'), findsOneWidget);

    // Tapping Continue triggers the 5/day limit paywall sheet
    await tester.tap(find.byKey(const Key('post-ad-continue-btn')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('post-ad-daily-limit-sheet')), findsOneWidget);
    expect(find.byKey(const Key('post-ad-upgrade-premium-btn')), findsOneWidget);

    // Tapping Upgrade opens ProPlusScreen on 99 MAD/mo with Google Pay
    await tester.tap(find.byKey(const Key('post-ad-upgrade-premium-btn')));
    await tester.pumpAndSettle();
    expect(find.byType(ProPlusScreen), findsOneWidget);
    expect(find.textContaining('99'), findsWidgets);
    expect(find.textContaining('Google Pay'), findsWidgets);

    // Upgrading user to Apolo Premium lifts the 5/day limit immediately
    await tester.tap(find.byKey(const Key('dl-paywall-no-thanks-btn')));
    await tester.pumpAndSettle();
    state.currentUser = {
      ...state.currentUser!,
      'is_pro_plus': true,
      'account_type': 'pro_plus',
    };
    state.notifyListeners();
    await tester.pumpAndSettle();

    expect(state.hasReachedDailyAdLimit, isFalse);
    expect(find.textContaining('Unlimited daily ads'), findsOneWidget);
  });
}
