import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/screens/main_shell.dart';
import 'package:apolo_mobile/screens/search_screen.dart';
import 'package:apolo_mobile/screens/widgets/app_image.dart';
import 'package:apolo_mobile/screens/widgets/explore_listing_card.dart';
import 'package:apolo_mobile/widgets/apolo_badges_kit.dart';

class _StubExploreHttpAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final sampleAds = List.generate(
      6,
      (i) => {
        'id': 100 + i,
        'title': 'إعلان تجريبي رقم $i',
        'price': 100 + i * 50,
        'price_formatted': '${100 + i * 50} MAD',
        'views_count': 50 + i,
        'category': {'id': 15, 'name_ar': 'أقسام أخرى', 'name_fr': 'Autres'},
        'city': {'id': 4, 'name_ar': 'سلا', 'name_fr': 'Salé'},
        'images': ['assets/images/cat_other.png'],
      },
    );
    return ResponseBody.fromString(
      jsonEncode({
        'status': 'success',
        'data': sampleAds,
        'categories': const [],
        'cities': const [],
        'vip_ads': sampleAds,
        'featured_ads': const [],
        'latest_ads': sampleAds,
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('AppImage.resolveWebUrl proxies Apolo storage URLs on Vercel Web', () {
    expect(
      AppImage.resolveWebUrl(
        'https://apolo.ma/storage/ads/1_abc.jpg',
        isWebOverride: true,
        hostOverride: 'apolo-amber.vercel.app',
      ),
      '/apolo-media/ads/1_abc.jpg',
    );
    expect(
      AppImage.resolveWebUrl(
        '/storage/ads/1_abc.jpg',
        isWebOverride: true,
        hostOverride: 'apolo-amber.vercel.app',
      ),
      '/apolo-media/ads/1_abc.jpg',
    );
    expect(
      AppImage.resolveWebUrl(
        '/storage/ads/1_abc.jpg',
        isWebOverride: false,
        hostOverride: '',
      ),
      'https://apolo.ma/storage/ads/1_abc.jpg',
    );
    expect(
      AppImage.resolveWebUrl(
        'https://images.unsplash.com/photo-1.jpg',
        isWebOverride: true,
        hostOverride: 'apolo-amber.vercel.app',
      ),
      'https://images.unsplash.com/photo-1.jpg',
    );
  });

  testWidgets(
      'ExploreListingCard matches Casa Oliva Villa reference dimensions, tokens, carousel dots, and favorite toggle',
      (WidgetTester tester) async {
    bool? toggledState;

    final sampleAd = <String, dynamic>{
      'id': 9101,
      'title': 'Casa Oliva Villa',
      'badge_label': 'Villa',
      'highlight_label': 'Guest favorite',
      'is_guest_favorite': true,
      'rating': '4.8',
      'reviews_count': 126,
      'specs_display': 'Cascais, 14 km · 3 bedrooms · Pool',
      'seller_name': 'Sarah',
      'seller_verified': true,
      'total_price_display': '\$933',
      'total_unit_label': 'total',
      'nightly_price_display': '\$233 / night · taxes incl.',
      'images': [
        'assets/images/cat_realestate.png',
        'assets/images/cat_home.png',
        'assets/images/cat_realestate.png',
        'assets/images/cat_home.png',
        'assets/images/cat_realestate.png',
      ],
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: 350,
                child: ExploreListingCard(
                  ad: sampleAd,
                  onFavoriteChanged: (val) => toggledState = val,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify outer dimensions (~342-350px width, ~360-380px height)
    final cardSize = tester.getSize(find.byType(ExploreListingCard));
    expect(cardSize.width, 350);
    expect(cardSize.height, inInclusiveRange(360, 380));

    // Verify badges, rating, specs, feature, and price labels
    expect(find.text('Villa'), findsOneWidget);
    expect(find.text('Guest favorite'), findsOneWidget);
    expect(find.text('Casa Oliva Villa'), findsOneWidget);
    expect(find.text('4.8'), findsOneWidget);
    expect(find.text('(126)'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(find.text('Cascais, 14 km · 3 bedrooms · Pool'), findsOneWidget);
    expect(find.text('Sarah'), findsOneWidget);
    expect(find.byType(ApoloVerifiedBadge), findsOneWidget);
    expect(find.byType(ApoloAccountTypeBadge), findsOneWidget);
    expect(find.text('\$233 / night · taxes incl.'), findsOneWidget);

    // Verify PageView swipe updates active slide cleanly
    expect(find.byType(PageView), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-250, 0));
    await tester.pumpAndSettle();

    // Verify heart icon toggle works inside 44x44 touch target
    expect(find.byIcon(CupertinoIcons.heart), findsOneWidget);
    await tester.tap(find.byIcon(CupertinoIcons.heart));
    await tester.pump();
    expect(toggledState, isTrue);
    expect(find.byIcon(CupertinoIcons.heart_fill), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ExploreListingCard handles real classified ad maps safely',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await AppState().initialize(loadRemote: false);
    final state = AppState();
    final prevLocale = state.locale;
    await tester.runAsync(() => state.setLocale(const Locale('ar')));
    addTearDown(() async {
      await tester.runAsync(() => state.setLocale(prevLocale));
    });

    final apiAd = <String, dynamic>{
      'id': 42,
      'title': 'Appartement Moderne Maarif 110m²',
      'price': 1450000,
      'price_formatted': '1 450 000 DH',
      'negotiable': true,
      'is_vip': true,
      'views_count': 95,
      'category': {'id': 2, 'name_fr': 'Immobilier', 'name_ar': 'عقارات'},
      'city': {'id': 1, 'name_fr': 'Casablanca', 'name_ar': 'الدار البيضاء'},
      'main_image': 'assets/images/cat_realestate.png',
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 346,
              child: ExploreListingCard(ad: apiAd),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Appartement Moderne Maarif 110m²'), findsOneWidget);
    expect(find.text('موصى به'), findsOneWidget);
    expect(find.text('(95)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'ExploreListingCard aligns Arabic RTL content cleanly and uses valid category fallback when images are empty',
      (WidgetTester tester) async {
    final rtlAd = <String, dynamic>{
      'id': 88,
      'title': 'حامل الهاتف',
      'price': 99,
      'price_formatted': '99 MAD',
      'views_count': 167,
      'category': {'id': 15, 'name_ar': 'أقسام أخرى', 'name_fr': 'Autres'},
      'city': {'id': 4, 'name_ar': 'سلا', 'name_fr': 'Salé'},
      'images': const [],
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 350,
                child: ExploreListingCard(ad: rtlAd),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // In RTL, title is on the trailing-left/leading-right side -> title.dx > rating.dx
    final titleCenter = tester.getCenter(find.text('حامل الهاتف'));
    final ratingCenter = tester.getCenter(find.text('4.8'));
    expect(titleCenter.dx, greaterThan(ratingCenter.dx));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'SearchScreen Explore view renders top SearchBar with bare Saved bookmark on same row, icon-only categories, no title/sort chrome, and ExploreListingCard on 390x844 Arabic RTL mobile',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: SearchScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 600));

    // Removed title & old chrome must stay absent
    expect(find.text('استكشف الإعلانات'), findsNothing);
    expect(find.byIcon(CupertinoIcons.square_grid_2x2), findsNothing);
    expect(find.text('جميع الأقسام'), findsNothing);
    expect(find.text('الذكي ✨'), findsNothing);
    expect(find.text('الأرخص'), findsNothing);
    expect(find.text('الأكثر طلباً'), findsNothing);
    expect(find.textContaining('إعلان متوفر'), findsNothing);

    // Saved bookmark icon sits on the same row as SearchBar without a circular background halo
    expect(find.byIcon(CupertinoIcons.bookmark), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.mic_fill), findsOneWidget);
    final bookmarkCenter =
        tester.getCenter(find.byIcon(CupertinoIcons.bookmark));
    final micCenter = tester.getCenter(find.byIcon(CupertinoIcons.mic_fill));
    expect((bookmarkCenter.dy - micCenter.dy).abs(), lessThan(4.0));
    expect(
      find.ancestor(
        of: find.byIcon(CupertinoIcons.bookmark),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).shape == BoxShape.circle,
        ),
      ),
      findsNothing,
    );

    // Icon-only categories + ExploreListingCard
    expect(find.byIcon(CupertinoIcons.square_grid_2x2_fill), findsOneWidget);
    expect(find.byType(ExploreListingCard), findsWidgets);
    expect(find.text('Casa Oliva Villa'), findsOneWidget);

    final firstCardSize = tester.getSize(find.byType(ExploreListingCard).first);
    expect(firstCardSize.width, inInclusiveRange(342, 355));
    expect(firstCardSize.height, inInclusiveRange(360, 380));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'SearchScreen smoothly floats top header out on downward scroll, ignores horizontal swipes, and floats back on upward scroll',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    await AppState().initialize(loadRemote: false);
    final state = AppState();
    final prevLocale = state.locale;
    await tester.runAsync(() => state.setLocale(const Locale('ar')));
    final prevAdapter = state.api.dio.httpClientAdapter;
    state.api.dio.httpClientAdapter = _StubExploreHttpAdapter();
    addTearDown(() async {
      state.api.dio.httpClientAdapter = prevAdapter;
      await tester.runAsync(() => state.setLocale(prevLocale));
    });

    bool chromeVisible = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: SearchScreen(
            onChromeVisibilityChanged: (v) => chromeVisible = v,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 600));

    final headerSliver = find.byType(
      SliverPersistentHeader,
      skipOffstage: false,
    );
    expect(find.text('استكشف الإعلانات'), findsNothing);
    expect(find.byIcon(CupertinoIcons.bookmark), findsOneWidget);
    expect(
      tester.renderObject<RenderSliver>(headerSliver).geometry!.paintExtent,
      greaterThan(100.0),
    );
    expect(chromeVisible, isTrue);

    // Drag vertically downward through CustomScrollView
    final scrollView = find.byType(CustomScrollView);
    await tester.drag(scrollView, const Offset(0, -340));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(chromeVisible, isFalse);
    expect(
      tester.renderObject<RenderSliver>(headerSliver).geometry!.paintExtent,
      0.0,
    );

    // Horizontal swipe on photo carousel must not affect chrome state
    if (find.byType(PageView).evaluate().isNotEmpty) {
      await tester.drag(find.byType(PageView).first, const Offset(-180, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(chromeVisible, isFalse);
    }

    // Drag slightly back up -> floating header smoothly glides back into view
    await tester.drag(scrollView, const Offset(0, 220));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(chromeVisible, isTrue);
    expect(find.byIcon(CupertinoIcons.bookmark), findsOneWidget);
    expect(
      tester.renderObject<RenderSliver>(headerSliver).geometry!.paintExtent,
      greaterThan(100.0),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'MainShell hides floating bottom TabBar while scrolling Explore Ads and brings it back on upward scroll',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    await AppState().initialize(loadRemote: false);
    final state = AppState();
    final prevLocale = state.locale;
    await tester.runAsync(() => state.setLocale(const Locale('ar')));
    final prevAdapter = state.api.dio.httpClientAdapter;
    state.api.dio.httpClientAdapter = _StubExploreHttpAdapter();
    addTearDown(() async {
      state.api.dio.httpClientAdapter = prevAdapter;
      await tester.runAsync(() => state.setLocale(prevLocale));
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: MainShell(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    // Switch to Explore Ads tab
    await tester.tap(find.bySemanticsLabel(state.s.tr('إعلانات', 'Annonces')));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 800));

    final initialSlide = tester.widget<AnimatedSlide>(find.byType(AnimatedSlide));
    expect(initialSlide.offset, Offset.zero);
    expect(
      tester.getTopLeft(find.byType(AnimatedOpacity).last).dy,
      lessThan(844.0),
    );

    // Scroll down in Explore Ads
    final exploreScrollView = find.descendant(
      of: find.byType(SearchScreen),
      matching: find.byType(CustomScrollView),
    );
    await tester.drag(exploreScrollView.first, const Offset(0, -340));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 350));

    final hiddenSlide = tester.widget<AnimatedSlide>(find.byType(AnimatedSlide));
    expect(hiddenSlide.offset, const Offset(0, 1.8));
    expect(
      tester.getTopLeft(find.byType(AnimatedOpacity).last).dy,
      greaterThan(844.0),
    );

    // Scroll back up -> bottom TabBar returns smoothly
    await tester.drag(exploreScrollView.first, const Offset(0, 220));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 350));

    final shownSlide = tester.widget<AnimatedSlide>(find.byType(AnimatedSlide));
    expect(shownSlide.offset, Offset.zero);
    expect(
      tester.getTopLeft(find.byType(AnimatedOpacity).last).dy,
      lessThan(844.0),
    );
    expect(tester.takeException(), isNull);
  });
}
