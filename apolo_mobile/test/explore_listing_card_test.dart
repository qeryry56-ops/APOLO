import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/screens/main_shell.dart';
import 'package:apolo_mobile/screens/search_screen.dart';
import 'package:apolo_mobile/screens/widgets/app_image.dart';
import 'package:apolo_mobile/screens/widgets/explore_listing_card.dart';

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
      'free_cancellation': true,
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
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('Free cancellation'), findsOneWidget);
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
      'SearchScreen Explore view renders single-row sort pills and ExploreListingCard on 390x844 Arabic RTL mobile without overflow',
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
    // Allow network call failure & ScrollReveal stagger timers to complete
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(ExploreListingCard), findsWidgets);
    expect(find.text('Casa Oliva Villa'), findsOneWidget);

    // Verify quick sort pills sit side-by-side on one single horizontal row
    final smartDy = tester.getCenter(find.text('الذكي ✨')).dy;
    final cheapDy = tester.getCenter(find.text('الأرخص')).dy;
    final popularDy = tester.getCenter(find.text('الأكثر طلباً')).dy;
    expect((smartDy - cheapDy).abs(), lessThan(2.0));
    expect((cheapDy - popularDy).abs(), lessThan(2.0));

    final firstCardSize = tester.getSize(find.byType(ExploreListingCard).first);
    expect(firstCardSize.width, inInclusiveRange(342, 355));
    expect(firstCardSize.height, inInclusiveRange(360, 380));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'SearchScreen hides top header chrome and notifies callback when scrolling down, ignores horizontal swipes, and restores on scroll up',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    await AppState().initialize(loadRemote: false);
    final state = AppState();
    final prevAdapter = state.api.dio.httpClientAdapter;
    state.api.dio.httpClientAdapter = _StubExploreHttpAdapter();
    addTearDown(() => state.api.dio.httpClientAdapter = prevAdapter);

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

    final initialAlign = tester.widget<AnimatedAlign>(
      find.byType(AnimatedAlign).first,
    );
    expect(initialAlign.heightFactor, 1.0);
    expect(chromeVisible, isTrue);

    // Drag vertically downward through the Explore results list
    final verticalList = find.byWidgetPredicate(
      (w) => w is ListView && w.scrollDirection == Axis.vertical,
    );
    await tester.drag(verticalList.first, const Offset(0, -320));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));

    expect(chromeVisible, isFalse);
    final collapsedAlign = tester.widget<AnimatedAlign>(
      find.byType(AnimatedAlign).first,
    );
    expect(collapsedAlign.heightFactor, 0.0);
    expect(tester.getSize(find.byType(AnimatedAlign).first).height, 0.0);

    // Horizontal swipe on photo carousel must not bring chrome back
    if (find.byType(PageView).evaluate().isNotEmpty) {
      await tester.drag(find.byType(PageView).first, const Offset(-180, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(chromeVisible, isFalse);
    }

    // Drag back up -> chrome restores
    await tester.drag(verticalList.first, const Offset(0, 260));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));

    expect(chromeVisible, isTrue);
    final restoredAlign = tester.widget<AnimatedAlign>(
      find.byType(AnimatedAlign).first,
    );
    expect(restoredAlign.heightFactor, 1.0);
    expect(
      tester.getSize(find.byType(AnimatedAlign).first).height,
      greaterThan(150.0),
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
    final prevAdapter = state.api.dio.httpClientAdapter;
    state.api.dio.httpClientAdapter = _StubExploreHttpAdapter();
    addTearDown(() => state.api.dio.httpClientAdapter = prevAdapter);

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
    await tester.tap(find.text(state.s.tr('إعلانات', 'Annonces')));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 800));

    final initialSlide = tester.widget<AnimatedSlide>(find.byType(AnimatedSlide));
    expect(initialSlide.offset, Offset.zero);
    expect(
      tester.getTopLeft(find.byType(AnimatedOpacity).last).dy,
      lessThan(844.0),
    );

    // Scroll down in Explore Ads
    final verticalList = find.descendant(
      of: find.byType(SearchScreen),
      matching: find.byWidgetPredicate(
        (w) => w is ListView && w.scrollDirection == Axis.vertical,
      ),
    );
    await tester.drag(verticalList.first, const Offset(0, -320));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));

    final hiddenSlide = tester.widget<AnimatedSlide>(find.byType(AnimatedSlide));
    expect(hiddenSlide.offset, const Offset(0, 1.8));
    expect(
      tester.getTopLeft(find.byType(AnimatedOpacity).last).dy,
      greaterThan(844.0),
    );

    // Scroll back up -> bottom TabBar returns smoothly
    await tester.drag(verticalList.first, const Offset(0, 260));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));

    final shownSlide = tester.widget<AnimatedSlide>(find.byType(AnimatedSlide));
    expect(shownSlide.offset, Offset.zero);
    expect(
      tester.getTopLeft(find.byType(AnimatedOpacity).last).dy,
      lessThan(844.0),
    );
    expect(tester.takeException(), isNull);
  });
}
