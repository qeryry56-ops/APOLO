import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:apolo_mobile/core/config/app_config.dart';
import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/screens/profile_screen.dart';
import 'package:apolo_mobile/screens/seller_profile_screen.dart';
import 'package:apolo_mobile/theme/app_theme.dart';
import 'package:apolo_mobile/widgets/apolo_badges_kit.dart';
import 'package:apolo_mobile/widgets/dl_settings_kit.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockDioAdapter implements HttpClientAdapter {
  final FutureOr<ResponseBody> Function(RequestOptions options) handler;

  _MockDioAdapter(this.handler);

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

ResponseBody _jsonReply(Object payload, [int statusCode = 200]) {
  return ResponseBody.fromString(
    jsonEncode(payload),
    statusCode,
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
  late Map<String, dynamic> testUser;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    originalDio = state.api.dio;
    originalLocale = state.locale;
    testUser = <String, dynamic>{
      'id': 77,
      'name': 'Dynamic Layer',
      'username': 'dynamiclayer',
      'bio': 'Moroccan classifieds & verified stores.',
      'avatar': '',
    };

    state.api.dio = Dio(BaseOptions(baseUrl: 'https://tests.invalid'))
      ..httpClientAdapter = _MockDioAdapter((options) {
        if (options.path.contains('/auth/profile')) {
          return _jsonReply({'status': 'success', 'user': testUser});
        }
        if (options.path.contains('/my-ads') || options.path.contains('/ads')) {
          return _jsonReply({'status': 'success', 'data': <dynamic>[]});
        }
        if (options.path.contains('/taxonomy')) {
          return _jsonReply({
            'status': 'success',
            'categories': <dynamic>[],
            'cities': <dynamic>[],
          });
        }
        return _jsonReply({'status': 'success', 'data': <dynamic>[]});
      });

    state.followedSellerIds.clear();
    state.sellerUserReviews.clear();
    state.favoriteAdIds.clear();
    state.currentUser = null;
    await state.api.setToken(null);
    await state.setLocale(const Locale('en'));
  });

  tearDown(() async {
    state.followedSellerIds.clear();
    state.sellerUserReviews.clear();
    state.favoriteAdIds.clear();
    state.currentUser = null;
    await state.api.setToken(null);
    await state.setLocale(originalLocale);
    state.api.dio = originalDio;
  });

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    Size viewport = const Size(390, 844),
  }) async {
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          return MaterialApp(
            theme: AppTheme.light(state.locale).copyWith(
              splashFactory: NoSplash.splashFactory,
            ),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: screen,
          );
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  group('ProfileScreen Dynamic Layer Account / Default', () {
    for (final lang in ['ar', 'en']) {
      testWidgets('guest mode renders clean white UI in $lang', (tester) async {
        await tester.runAsync(() => state.setLocale(Locale(lang)));
        await pumpScreen(tester, const ProfileScreen());

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('profile-sign-in')), findsOneWidget);
        expect(find.byKey(const Key('guest-settings')), findsOneWidget);
      });
    }

    testWidgets(
        'logged-in Account / Default renders ApoloDlAccountHeader and opens Edit Profile',
        (tester) async {
      state.currentUser = testUser;
      await tester.runAsync(() => state.api.setToken('valid-test-token'));

      await pumpScreen(tester, const ProfileScreen());

      expect(tester.takeException(), isNull);
      expect(find.byType(ApoloDlAccountHeader), findsOneWidget);
      expect(find.byKey(const Key('profile-edit-btn')), findsOneWidget);
      expect(find.byKey(const Key('profile-share-btn')), findsOneWidget);
      expect(find.byKey(const Key('profile-settings-btn')), findsOneWidget);
      expect(find.text('Dynamic Layer'), findsOneWidget);
      expect(find.text('@dynamiclayer'), findsNWidgets(2));
      expect(find.text('+28%'), findsNothing);
      expect(find.text('Following'), findsOneWidget);
      expect(find.text('Listings'), findsOneWidget);
      expect(find.byKey(const Key('apolo-account-badge-personal')), findsOneWidget);
      expect(find.byKey(const Key('apolo-account-badge-business')), findsNothing);
      expect(find.byType(ApoloVerifiedBadge), findsNothing);
      expect(find.byKey(const Key('profile-account-mode-switcher')), findsNothing);

      await tester.tap(find.byKey(const Key('profile-edit-btn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('profile-save')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('SellerProfileScreen Dynamic Layer Account / Follow & Following', () {
    testWidgets(
        'toggles Follow -> Following -> Follow, persists in AppState, and updates follower count',
        (tester) async {
      const sellerId = 42;
      await pumpScreen(
        tester,
        const SellerProfileScreen(
          sellerId: sellerId,
          sellerName: 'Dynamic Layer',
          sellerCity: 'Casablanca',
          sellerPhone: '+212600000000',
        ),
      );

      expect(tester.takeException(), isNull);
      expect(state.isFollowingSeller(sellerId), isFalse);
      expect(find.byKey(const Key('apolo-account-badge-personal')), findsOneWidget);
      expect(find.byType(ApoloVerifiedBadge), findsNothing);
      expect(find.text('162'), findsOneWidget);

      final initialFollowBtn = tester.widget<ApoloDlButton>(
        find.byKey(const Key('seller-follow-btn')),
      );
      expect(initialFollowBtn.variant, ApoloDlButtonVariant.primary);
      expect(initialFollowBtn.label, 'Follow');
      expect(find.byKey(const Key('seller-chat-btn')), findsOneWidget);
      expect(find.byKey(const Key('seller-share-btn')), findsNothing);
      expect(find.byKey(const Key('seller-call-btn')), findsNothing);

      await tester.tap(find.byKey(const Key('seller-follow-btn')));
      await tester.pumpAndSettle();

      expect(state.isFollowingSeller(sellerId), isTrue);
      expect(find.text('163'), findsOneWidget);
      final followingBtn = tester.widget<ApoloDlButton>(
        find.byKey(const Key('seller-follow-btn')),
      );
      expect(followingBtn.variant, ApoloDlButtonVariant.tertiary);
      expect(followingBtn.label, 'Following');

      await tester.tap(find.byKey(const Key('seller-follow-btn')));
      await tester.pumpAndSettle();

      expect(state.isFollowingSeller(sellerId), isFalse);
      expect(find.text('162'), findsOneWidget);
      final revertedFollowBtn = tester.widget<ApoloDlButton>(
        find.byKey(const Key('seller-follow-btn')),
      );
      expect(revertedFollowBtn.variant, ApoloDlButtonVariant.primary);
      expect(revertedFollowBtn.label, 'Follow');
      expect(tester.takeException(), isNull);
    });

    for (final lang in ['ar', 'en']) {
      testWidgets('renders cleanly without overflow in $lang at 390x844',
          (tester) async {
        await tester.runAsync(() => state.setLocale(Locale(lang)));
        await pumpScreen(
          tester,
          const SellerProfileScreen(
            sellerId: 99,
            sellerName: 'Atlas Store Casablanca',
            sellerCity: 'Casablanca',
            sellerPhone: '+212611223344',
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(ApoloDlAccountHeader), findsOneWidget);
        expect(find.byKey(const Key('seller-follow-btn')), findsOneWidget);
        expect(find.byKey(const Key('seller-chat-btn')), findsOneWidget);
        expect(find.byKey(const Key('seller-share-btn')), findsNothing);
        expect(find.byKey(const Key('seller-call-btn')), findsNothing);
      });
    }

    testWidgets(
        'allows user to submit a star rating and review on SellerProfileScreen',
        (tester) async {
      state.currentUser = testUser;
      await tester.runAsync(() => state.api.setToken('valid-test-token'));
      await pumpScreen(
        tester,
        const SellerProfileScreen(
          sellerId: 501,
          sellerName: 'Atlas Boutique',
          sellerCity: 'Rabat',
        ),
      );

      expect(find.text('Reviews (48)'), findsOneWidget);
      await tester.tap(find.text('Reviews (48)'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('seller-write-review-btn')), findsOneWidget);
      await tester.tap(find.byKey(const Key('seller-write-review-btn')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('review-star-5')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('review-comment-input')),
        'Top seller in Rabat, super fast delivery!',
      );
      await tester.tap(find.byKey(const Key('review-submit-btn')));
      await tester.pumpAndSettle();

      expect(find.text('Reviews (49)'), findsOneWidget);
      expect(
        find.text('Top seller in Rabat, super fast delivery!'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'clearly differentiates Personal vs Business on SellerProfileScreen and ProfileScreen',
        (tester) async {
      // 1. Individual / Personal Seller
      await pumpScreen(
        tester,
        const SellerProfileScreen(
          sellerId: 701,
          sellerName: 'Youssef Casa',
          sellerCity: 'Casablanca',
          isVerified: false,
          isBusiness: false,
        ),
      );
      expect(
        find.byKey(const Key('apolo-account-badge-personal')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('seller-business-store-card')),
        findsNothing,
      );

      // 2. While enablePremiumAndBusinessTiers == false, even Business/Verified props stay Personal + unverified
      AppConfig.enablePremiumAndBusinessTiers = false;
      addTearDown(() => AppConfig.enablePremiumAndBusinessTiers = true);
      await pumpScreen(
        tester,
        const SellerProfileScreen(
          sellerId: 702,
          sellerName: 'Apolo Motors',
          sellerCity: 'Casablanca',
          isVerified: true,
          isBusiness: true,
          store: {
            'name': 'Apolo Motors',
            'subdomain': 'apolo-motors',
            'business_category': 'vehicles',
            'working_hours': '09:00 - 20:00',
          },
        ),
      );
      expect(
        find.byKey(const Key('apolo-account-badge-personal')),
        findsOneWidget,
      );
      expect(find.byType(ApoloVerifiedBadge), findsNothing);
      expect(
        find.byKey(const Key('seller-business-store-card')),
        findsNothing,
      );

      // 3. Once Premium/Business tiers are enabled, Business Store Seller renders Business badge & store card
      AppConfig.enablePremiumAndBusinessTiers = true;
      await pumpScreen(
        tester,
        const SellerProfileScreen(
          sellerId: 702,
          sellerName: 'Apolo Motors',
          sellerCity: 'Casablanca',
          isVerified: true,
          isBusiness: true,
          store: {
            'name': 'Apolo Motors',
            'subdomain': 'apolo-motors',
            'business_category': 'vehicles',
            'working_hours': '09:00 - 20:00',
          },
        ),
      );
      expect(
        find.byKey(const Key('apolo-account-badge-business')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('seller-business-store-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('seller-visit-store-btn')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
