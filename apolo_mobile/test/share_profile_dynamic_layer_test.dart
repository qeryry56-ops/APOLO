import 'dart:async';
import 'dart:convert';

import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/screens/profile_screen.dart';
import 'package:apolo_mobile/screens/scan_profile_code_screen.dart';
import 'package:apolo_mobile/screens/seller_profile_screen.dart';
import 'package:apolo_mobile/screens/share_profile_screen.dart';
import 'package:apolo_mobile/theme/app_theme.dart';
import 'package:apolo_mobile/widgets/dl_qr_code.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  setUpAll(() async {
    try {
      final interRegular = rootBundle.load('assets/fonts/Inter-Regular.ttf');
      final interBold = rootBundle.load('assets/fonts/Inter-Bold.ttf');
      final loader = FontLoader('Inter')
        ..addFont(interRegular)
        ..addFont(interBold);
      await loader.load();
    } catch (_) {}
  });

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
        if (options.path.contains('/my-ads')) {
          return _jsonReply({'status': 'success', 'data': <dynamic>[]});
        }
        if (options.path.contains('/ads')) {
          final sellerId = options.queryParameters['seller_id'];
          if (sellerId?.toString() == '42') {
            return _jsonReply({
              'status': 'success',
              'data': [
                {
                  'id': 501,
                  'title': 'MacBook Pro M3',
                  'user': {
                    'id': 42,
                    'name': 'Alex Michael Smith',
                    'avatar': '',
                    'phone': '+212600000042',
                    'city': 'Casablanca',
                  },
                },
              ],
            });
          }
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
    state.favoriteAdIds.clear();
    state.currentUser = null;
    await state.api.setToken(null);
    await state.setLocale(const Locale('en'));
  });

  tearDown(() async {
    state.followedSellerIds.clear();
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
    FakeViewPadding? viewPadding,
  }) async {
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    if (viewPadding != null) {
      tester.view.viewPadding = viewPadding;
      tester.view.padding = viewPadding;
      addTearDown(tester.view.resetViewPadding);
      addTearDown(tester.view.resetPadding);
    }

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

  group('ApoloProfileQrParser & ApoloDlQrCode', () {
    test('parses supported Apolo user, ad, handle, external, and plain links',
        () {
      expect(
        ApoloProfileQrParser.parse('https://apolo.ma/users/77'),
        const ApoloQrTarget(
          type: ApoloQrTargetType.user,
          rawValue: 'https://apolo.ma/users/77',
          id: 77,
        ),
      );
      expect(
        ApoloProfileQrParser.parse('http://www.apolo.ma/users/42/'),
        const ApoloQrTarget(
          type: ApoloQrTargetType.user,
          rawValue: 'http://www.apolo.ma/users/42/',
          id: 42,
        ),
      );
      expect(
        ApoloProfileQrParser.parse('apolo://users/15'),
        const ApoloQrTarget(
          type: ApoloQrTargetType.user,
          rawValue: 'apolo://users/15',
          id: 15,
        ),
      );
      expect(
        ApoloProfileQrParser.parse('https://apolo.ma/ads/901'),
        const ApoloQrTarget(
          type: ApoloQrTargetType.ad,
          rawValue: 'https://apolo.ma/ads/901',
          id: 901,
        ),
      );
      expect(
        ApoloProfileQrParser.parse('apolo://ads/901'),
        const ApoloQrTarget(
          type: ApoloQrTargetType.ad,
          rawValue: 'apolo://ads/901',
          id: 901,
        ),
      );
      expect(
        ApoloProfileQrParser.parse('https://apolo.ma/@dynamiclayer'),
        const ApoloQrTarget(
          type: ApoloQrTargetType.handle,
          rawValue: 'https://apolo.ma/@dynamiclayer',
          handle: 'dynamiclayer',
        ),
      );
      expect(
        ApoloProfileQrParser.parse('@alex_smith'),
        const ApoloQrTarget(
          type: ApoloQrTargetType.handle,
          rawValue: '@alex_smith',
          handle: 'alex_smith',
        ),
      );
      expect(
        ApoloProfileQrParser.parse('https://example.com/item'),
        const ApoloQrTarget(
          type: ApoloQrTargetType.external,
          rawValue: 'https://example.com/item',
        ),
      );
      expect(
        ApoloProfileQrParser.parse('hello world'),
        const ApoloQrTarget(
          type: ApoloQrTargetType.unknown,
          rawValue: 'hello world',
        ),
      );
    });

    test('builds valid ISO/IEC 18004 QR matrix for profile URLs', () {
      final modules = ApoloDlQrCode.moduleCountFor('https://apolo.ma/users/77');
      expect(modules, greaterThanOrEqualTo(21));
      final img = ApoloDlQrCode.buildQrImage('https://apolo.ma/users/77');
      expect(img.moduleCount, modules);
      // Finder pattern top-left outer corner (0,0) is always dark in ISO QR.
      expect(img.isDark(0, 0), isTrue);
    });
  });

  group('Dynamic Layer Share profile & Scan code flow', () {
    for (final lang in ['en', 'ar']) {
      testWidgets(
          'ProfileScreen -> ShareProfileScreen -> ScanProfileCodeScreen works in $lang without overflow',
          (tester) async {
        await tester.runAsync(() => state.setLocale(Locale(lang)));
        state.currentUser = testUser;
        await tester.runAsync(() => state.api.setToken('valid-test-token'));

        await pumpScreen(tester, const ProfileScreen());
        expect(tester.takeException(), isNull);

        await tester.tap(find.byKey(const Key('profile-share-btn')));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(ShareProfileScreen), findsOneWidget);
        expect(find.byKey(const Key('share-profile-qr-card')), findsOneWidget);
        expect(find.byKey(const Key('share-profile-qr-code')), findsOneWidget);
        expect(
            find.byKey(const Key('share-profile-native-btn')), findsOneWidget);
        expect(find.byKey(const Key('share-profile-scan-btn')), findsOneWidget);
        expect(find.text('Dynamic Layer'), findsOneWidget);
        expect(find.text('@dynamiclayer'), findsOneWidget);

        await tester.tap(find.byKey(const Key('share-profile-scan-btn')));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(ScanProfileCodeScreen), findsOneWidget);
        expect(find.byKey(const Key('scan-code-viewfinder')), findsOneWidget);
        expect(find.byKey(const Key('scan-code-hint')), findsOneWidget);
        expect(find.byKey(const Key('scan-code-flash-btn')), findsOneWidget);
        expect(find.byKey(const Key('scan-code-shutter-btn')), findsOneWidget);
        expect(find.byKey(const Key('scan-code-gallery-btn')), findsOneWidget);
        expect(find.byKey(const Key('scan-code-back-btn')), findsOneWidget);

        await tester.tap(find.byKey(const Key('scan-code-back-btn')));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(ShareProfileScreen), findsOneWidget);
        expect(find.byType(ScanProfileCodeScreen), findsNothing);
      });
    }

    testWidgets(
        'SellerProfileScreen Share profile opens ShareProfileScreen with seller name & handle',
        (tester) async {
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

      await tester.tap(find.byKey(const Key('seller-share-btn')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ShareProfileScreen), findsOneWidget);
      expect(find.text('Atlas Store Casablanca'), findsOneWidget);
      expect(find.text('@atlas_store_casablanca'), findsOneWidget);
    });

    testWidgets(
        'ScanProfileCodeScreen manual entry sheet invokes onCodeScanned callback',
        (tester) async {
      String? capturedCode;
      await pumpScreen(
        tester,
        ScanProfileCodeScreen(
          enableLiveCamera: false,
          onCodeScanned: (code) => capturedCode = code,
        ),
      );

      await tester.tap(find.byKey(const Key('scan-code-shutter-btn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('scan-manual-input')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('scan-manual-input')),
        'https://apolo.ma/users/42',
      );
      await tester.tap(find.byKey(const Key('scan-manual-submit')));
      await tester.pumpAndSettle();

      expect(capturedCode, 'https://apolo.ma/users/42');
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'ScanProfileCodeScreen manual user link navigates to SellerProfileScreen',
        (tester) async {
      await pumpScreen(
        tester,
        const ScanProfileCodeScreen(enableLiveCamera: false),
      );

      await tester.tap(find.byKey(const Key('scan-code-shutter-btn')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('scan-manual-input')),
        'https://apolo.ma/users/42',
      );
      await tester.tap(find.byKey(const Key('scan-manual-submit')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SellerProfileScreen), findsOneWidget);
      expect(find.byKey(const Key('seller-follow-btn')), findsOneWidget);
      expect(find.text('Alex Michael Smith'), findsNWidgets(2));
    });

    testWidgets('ScanProfileCodeScreen matches Figma 375x812 dimensions cleanly',
        (tester) async {
      await pumpScreen(
        tester,
        const ScanProfileCodeScreen(enableLiveCamera: false),
        viewport: const Size(375, 812),
        viewPadding: const FakeViewPadding(top: 48, bottom: 34),
      );
      expect(tester.takeException(), isNull);

      final headerRect =
          tester.getRect(find.byKey(const Key('scan-code-header')));
      final topWrapperRect =
          tester.getRect(find.byKey(const Key('scan-code-top-wrapper')));
      final titleRect =
          tester.getRect(find.byKey(const Key('scan-code-title')));
      final viewfinderRect =
          tester.getRect(find.byKey(const Key('scan-code-viewfinder')));
      final hintRect = tester.getRect(find.byKey(const Key('scan-code-hint')));
      final contentRect =
          tester.getRect(find.byKey(const Key('scan-code-content')));
      final controlsBarRect =
          tester.getRect(find.byKey(const Key('scan-code-controls-bar')));
      final flashRect =
          tester.getRect(find.byKey(const Key('scan-code-flash-btn')));
      final shutterRect =
          tester.getRect(find.byKey(const Key('scan-code-shutter-btn')));
      final shutterRingWhiteRect =
          tester.getRect(find.byKey(const Key('scan-code-shutter-ring-white')));
      final shutterCoreRect =
          tester.getRect(find.byKey(const Key('scan-code-shutter-core')));
      final galleryRect =
          tester.getRect(find.byKey(const Key('scan-code-gallery-btn')));

      expect(headerRect.top, 0);
      expect(headerRect.width, 375);
      expect(headerRect.height, 104);
      expect(topWrapperRect.width, 375);
      expect(topWrapperRect.height, 56);
      expect(titleRect.width, 231);
      expect(titleRect.height, 24);

      expect(viewfinderRect.width, 311);
      expect(viewfinderRect.height, 311);
      expect(viewfinderRect.top, closeTo(225, 2));
      expect(hintRect.width, 311);
      expect(hintRect.height, 20);
      expect(hintRect.top - viewfinderRect.bottom, closeTo(32, 1));
      expect(contentRect.height, closeTo(363, 1));

      expect(controlsBarRect.top, 634);
      expect(controlsBarRect.width, 375);
      expect(controlsBarRect.height, 144);

      expect(flashRect.width, 56);
      expect(flashRect.height, 56);
      expect(find.byIcon(Icons.flashlight_off_rounded), findsOneWidget);
      expect(galleryRect.width, 56);
      expect(galleryRect.height, 56);
      expect(find.byIcon(Icons.image_rounded), findsOneWidget);

      expect(shutterRect.width, 80);
      expect(shutterRect.height, 80);
      expect(shutterRingWhiteRect.width, 72);
      expect(shutterRingWhiteRect.height, 72);
      expect(shutterRingWhiteRect.top - shutterRect.top, 4);
      expect(shutterRingWhiteRect.left - shutterRect.left, 4.5);
      expect(shutterCoreRect.width, 64);
      expect(shutterCoreRect.height, 64);
      expect(shutterCoreRect.top - shutterRect.top, 8);
      expect(shutterCoreRect.left - shutterRect.left, 8.5);

      expect(shutterRect.left - flashRect.right, closeTo(32, 1));
      expect(galleryRect.left - shutterRect.right, closeTo(32, 1));
    });

    testWidgets(
        'ShareProfileScreen matches Figma 375x812 dimensions and fits compact 360x640',
        (tester) async {
      await pumpScreen(
        tester,
        const ShareProfileScreen(
          userId: 77,
          displayName: 'Alex Michael Smith',
          handle: '@alexsmith',
          profileUrl: 'https://apolo.ma/users/77',
          enableLiveCamera: false,
        ),
        viewport: const Size(375, 812),
        viewPadding: const FakeViewPadding(top: 48, bottom: 34),
      );
      expect(tester.takeException(), isNull);

      final headerRect =
          tester.getRect(find.byKey(const Key('share-profile-header')));
      final topWrapperRect =
          tester.getRect(find.byKey(const Key('share-profile-top-wrapper')));
      final titleRect =
          tester.getRect(find.byKey(const Key('share-profile-title')));
      final cardRect =
          tester.getRect(find.byKey(const Key('share-profile-qr-card')));
      final innerRect =
          tester.getRect(find.byKey(const Key('share-profile-qr-inner')));
      final qrBoxRect =
          tester.getRect(find.byKey(const Key('share-profile-qr-code-box')));
      final identityGroupRect =
          tester.getRect(find.byKey(const Key('share-profile-identity-group')));
      final displayNameRect =
          tester.getRect(find.byKey(const Key('share-profile-display-name')));
      final handleRect =
          tester.getRect(find.byKey(const Key('share-profile-handle')));
      final privacyRect =
          tester.getRect(find.byKey(const Key('share-profile-privacy-text')));
      final bottomBarRect =
          tester.getRect(find.byKey(const Key('share-profile-bottom-bar')));

      expect(headerRect.top, 0);
      expect(headerRect.width, 375);
      expect(headerRect.height, 104);
      expect(topWrapperRect.width, 375);
      expect(topWrapperRect.height, 56);
      expect(titleRect.width, 231);
      expect(titleRect.height, 24);

      expect(cardRect.width, 284);
      expect(cardRect.height, 364);
      expect(cardRect.left, 45.5);
      expect(cardRect.top, 175);
      expect(innerRect.width, 220);
      expect(innerRect.height, 220);
      expect(innerRect.left - cardRect.left, 32);
      expect(innerRect.top - cardRect.top, 32);

      expect(qrBoxRect.width, 160);
      expect(qrBoxRect.height, 160);
      expect(qrBoxRect.top - innerRect.top, 30);
      expect(qrBoxRect.left - innerRect.left, 30);

      expect(identityGroupRect.height, 48);
      expect(identityGroupRect.top - innerRect.bottom, 32);
      expect(displayNameRect.height, 24);
      expect(handleRect.height, 24);
      expect(handleRect.top, displayNameRect.bottom);

      expect(privacyRect.width, 311);
      expect(privacyRect.height, 60);
      expect(privacyRect.top - cardRect.bottom, 32);
      expect(
        find.text(
          'Your QR code is private. If you share it with someone, that person can scan it with their camera to add you as a contact.',
        ),
        findsOneWidget,
      );

      final scanBtnRect =
          tester.getRect(find.byKey(const Key('share-profile-scan-btn')));
      expect(bottomBarRect.width, 375);
      expect(bottomBarRect.height, 126);
      expect(bottomBarRect.top, 686);
      expect(scanBtnRect.height, 56);
      expect(scanBtnRect.top, 702);
      expect(scanBtnRect.bottom, 758);
      expect(scanBtnRect.center.dx, closeTo(187.5, 0.5));
      expect(scanBtnRect.width, greaterThanOrEqualTo(140));
      expect(scanBtnRect.width, lessThanOrEqualTo(200));

      await pumpScreen(
        tester,
        const ShareProfileScreen(
          userId: 77,
          displayName: 'Alex Michael Smith',
          handle: '@alexsmith',
          profileUrl: 'https://apolo.ma/users/77',
          enableLiveCamera: false,
        ),
        viewport: const Size(360, 640),
        viewPadding: FakeViewPadding.zero,
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('share-profile-qr-card')), findsOneWidget);
      expect(find.byKey(const Key('share-profile-scan-btn')), findsOneWidget);
    });

    testWidgets(
        'iOS Safari/PWA viewport (393x760, zero insets) and multi-phone matrix render cleanly with exact Hug proportions',
        (tester) async {
      await tester.runAsync(() => state.setLocale(const Locale('ar')));
      await pumpScreen(
        tester,
        const ShareProfileScreen(
          userId: 77,
          displayName: 'kiziGym',
          handle: '@kizigym',
          profileUrl: 'https://apolo.ma/users/77',
          enableLiveCamera: false,
        ),
        viewport: const Size(393, 760),
        viewPadding: FakeViewPadding.zero,
      );
      expect(tester.takeException(), isNull);

      final shareHeaderRect =
          tester.getRect(find.byKey(const Key('share-profile-header')));
      final shareTopWrapperRect =
          tester.getRect(find.byKey(const Key('share-profile-top-wrapper')));
      final shareCardRect =
          tester.getRect(find.byKey(const Key('share-profile-qr-card')));
      final shareBottomBarRect =
          tester.getRect(find.byKey(const Key('share-profile-bottom-bar')));
      final shareScanBtnRect =
          tester.getRect(find.byKey(const Key('share-profile-scan-btn')));

      expect(shareHeaderRect.height, 56);
      expect(shareTopWrapperRect.top, 0);
      expect(shareTopWrapperRect.width, 393);
      expect(shareCardRect.width, 284);
      expect(shareCardRect.height, 364);
      expect(shareBottomBarRect.height, 126);
      expect(shareScanBtnRect.height, 56);
      expect(shareScanBtnRect.bottom, 706);
      expect(shareScanBtnRect.center.dx, closeTo(196.5, 0.5));
      expect(shareScanBtnRect.width, greaterThanOrEqualTo(135));
      expect(shareScanBtnRect.width, lessThanOrEqualTo(240));

      await pumpScreen(
        tester,
        const ScanProfileCodeScreen(enableLiveCamera: false),
        viewport: const Size(393, 760),
        viewPadding: FakeViewPadding.zero,
      );
      expect(tester.takeException(), isNull);

      final scanHeaderRect =
          tester.getRect(find.byKey(const Key('scan-code-header')));
      final scanTopWrapperRect =
          tester.getRect(find.byKey(const Key('scan-code-top-wrapper')));
      final scanViewfinderRect =
          tester.getRect(find.byKey(const Key('scan-code-viewfinder')));
      final scanControlsBarRect =
          tester.getRect(find.byKey(const Key('scan-code-controls-bar')));

      expect(scanHeaderRect.height, 56);
      expect(scanTopWrapperRect.top, 0);
      expect(scanTopWrapperRect.width, 393);
      expect(scanViewfinderRect.width, 311);
      expect(scanControlsBarRect.height, 144);

      const phoneSizes = <Size>[
        Size(320, 568),
        Size(375, 667),
        Size(412, 915),
        Size(430, 932),
        Size(768, 1024),
      ];

      for (final lang in ['ar', 'en']) {
        await tester.runAsync(() => state.setLocale(Locale(lang)));
        for (final size in phoneSizes) {
          await pumpScreen(
            tester,
            const ShareProfileScreen(
              userId: 77,
              displayName: 'Alex Michael Smith',
              handle: '@alexsmith',
              profileUrl: 'https://apolo.ma/users/77',
              enableLiveCamera: false,
            ),
            viewport: size,
            viewPadding: FakeViewPadding.zero,
          );
          expect(tester.takeException(), isNull);

          final topW = tester
              .getRect(find.byKey(const Key('share-profile-top-wrapper')))
              .width;
          final cRect = tester
              .getRect(find.byKey(const Key('share-profile-qr-card')));
          final bRect = tester
              .getRect(find.byKey(const Key('share-profile-scan-btn')));

          expect(topW, size.width);
          expect(cRect.width, 284);
          expect(cRect.height, 364);
          expect(bRect.height, 56);
          expect(bRect.center.dx, closeTo(size.width / 2, 0.5));
          expect(bRect.width, lessThan(240));

          await pumpScreen(
            tester,
            const ScanProfileCodeScreen(enableLiveCamera: false),
            viewport: size,
            viewPadding: FakeViewPadding.zero,
          );
          expect(tester.takeException(), isNull);
          expect(
            tester
                .getRect(find.byKey(const Key('scan-code-top-wrapper')))
                .width,
            size.width,
          );
        }
      }
    });
  });
}
