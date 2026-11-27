import 'dart:convert';
import 'dart:typed_data';

import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/screens/home_screen.dart';
import 'package:apolo_mobile/screens/widgets/accommodation_card.dart';
import 'package:apolo_mobile/screens/widgets/explore_listing_card.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubHomeHttpAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    late final Map<String, dynamic> payload;
    if (path.contains('/home')) {
      payload = {
        'vip_ads': [
          {
            'id': 501,
            'title': 'حامل الهاتف',
            'price': 99,
            'price_formatted': '99 MAD',
            'is_vip': true,
            'views_count': 167,
            'main_image': 'assets/images/cat_other.png',
            'category': {'id': 15, 'name_ar': 'أقسام أخرى', 'name_fr': 'Autres'},
            'city': {'id': 4, 'name_ar': 'سلا', 'name_fr': 'Salé'},
          },
          {
            'id': 502,
            'title': 'شقة فاخرة بالدار البيضاء',
            'price': 950000,
            'price_formatted': '950 000 DH',
            'is_vip': true,
            'views_count': 84,
            'main_image': 'assets/images/cat_realestate.png',
            'category': {
              'id': 1,
              'name_ar': 'عقارات',
              'name_fr': 'Immobilier',
            },
            'city': {
              'id': 1,
              'name_ar': 'الدار البيضاء',
              'name_fr': 'Casablanca',
            },
          },
        ],
        'featured_ads': const [],
        'latest_ads': const [],
      };
    } else {
      payload = {'status': 'success', 'data': const []};
    }
    return ResponseBody.fromString(
      jsonEncode(payload),
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
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppState().initialize(loadRemote: false);
    AppState().currentUser = null;
  });

  testWidgets(
      'AccommodationCard reproduces exact reference badges, bottom panel, aspect ratio, and favorite toggle',
      (WidgetTester tester) async {
    bool? toggledState;

    final sampleAd = <String, dynamic>{
      'id': 901,
      'title': 'Lakeside Cabin',
      'badge_label': 'Cabin',
      'rating': '4.9',
      'price': 148,
      'nightly_price_display': '\$148',
      'price_unit': '/night',
      'location_display': 'Sintra, Portugal',
      'total_summary': '\$651 total · 4 nights',
      'main_image': 'assets/images/cat_realestate.png',
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 304,
              child: AccommodationCard(
                ad: sampleAd,
                onFavoriteChanged: (val) => toggledState = val,
              ),
            ),
          ),
        ),
      ),
    );

    final aspectFinder = find.byType(AspectRatio);
    expect(aspectFinder, findsOneWidget);
    final aspectWidget = tester.widget<AspectRatio>(aspectFinder);
    expect(aspectWidget.aspectRatio, closeTo(0.84, 0.001));

    expect(find.text('Cabin'), findsOneWidget);
    expect(find.text('4.9'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);

    expect(find.text('Lakeside Cabin'), findsOneWidget);
    expect(find.text('Sintra, Portugal'), findsOneWidget);
    expect(find.text('\$651 total · 4 nights'), findsOneWidget);

    expect(find.byIcon(CupertinoIcons.heart), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.heart_fill), findsNothing);

    await tester.tap(find.byIcon(CupertinoIcons.heart));
    await tester.pump();

    expect(toggledState, isTrue);
    expect(find.byIcon(CupertinoIcons.heart_fill), findsOneWidget);
  });

  testWidgets(
      'AccommodationCard formats real Apolo ad cleanly without stay suffixes',
      (WidgetTester tester) async {
    final state = AppState();
    final prevLocale = state.locale;
    await tester.runAsync(() => state.setLocale(const Locale('ar')));
    addTearDown(() async {
      await tester.runAsync(() => state.setLocale(prevLocale));
    });

    final realAd = <String, dynamic>{
      'id': 108,
      'title': 'حامل الهاتف',
      'price': 99,
      'price_formatted': '99 MAD',
      'views_count': 167,
      'category': {'id': 15, 'name_ar': 'أقسام أخرى', 'name_fr': 'Autres'},
      'city': {'id': 4, 'name_ar': 'سلا', 'name_fr': 'Salé'},
      'main_image': '',
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 304,
                child: AccommodationCard(ad: realAd),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('حامل الهاتف'), findsOneWidget);
    expect(find.text('سلا'), findsOneWidget);
    expect(find.text('167 مشاهدة'), findsOneWidget);
    expect(find.textContaining('/night'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'HomeScreen uses Dynamic Layer v5.1 tokens, Quick Search pill, and AccommodationCard inside Exclusive Deals',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState();
    final prevLocale = state.locale;
    await tester.runAsync(() => state.setLocale(const Locale('ar')));
    final previousAdapter = state.api.dio.httpClientAdapter;
    state.api.dio.httpClientAdapter = _StubHomeHttpAdapter();
    addTearDown(() async {
      state.api.dio.httpClientAdapter = previousAdapter;
      await tester.runAsync(() => state.setLocale(prevLocale));
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: HomeScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.byKey(const Key('dl-home-screen')), findsOneWidget);
    expect(find.byKey(const Key('dl-home-search-pill')), findsOneWidget);
    expect(find.byKey(const Key('dl-home-hero-card')), findsOneWidget);
    expect(find.byKey(const Key('home-notifications-bell')), findsOneWidget);
    expect(find.text('Nearby stays'), findsNothing);
    expect(find.text('عروض حصرية مميزة'), findsOneWidget);
    expect(find.byType(AccommodationCard), findsWidgets);

    final cardSize = tester.getSize(find.byType(AccommodationCard).first);
    expect(cardSize.width, closeTo(390 * 0.78, 0.5));
    expect(cardSize.width / cardSize.height, closeTo(0.84, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'HomeScreen renders ExploreListingCard feed directly below Exclusive Deals carousel and supports EN LTR cleanly',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState();
    final prevLocale = state.locale;
    await tester.runAsync(() => state.setLocale(const Locale('en')));
    final previousAdapter = state.api.dio.httpClientAdapter;
    state.api.dio.httpClientAdapter = _StubHomeHttpAdapter();
    addTearDown(() async {
      state.api.dio.httpClientAdapter = previousAdapter;
      await tester.runAsync(() => state.setLocale(prevLocale));
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: HomeScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Welcome to Apolo'), findsOneWidget);
    expect(find.text('Exclusive Deals'), findsOneWidget);
    final exclusivePos = tester.getTopLeft(find.text('Exclusive Deals'));

    // Scroll down below the Exclusive Deals carousel to reveal the Explore-style ad feed
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -520));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Latest listings'), findsOneWidget);
    expect(find.byType(ExploreListingCard), findsWidgets);

    final feedTitlePos = tester.getTopLeft(find.text('Latest listings'));
    final firstExploreCard = find.byType(ExploreListingCard).first;
    final exploreCardPos = tester.getTopLeft(firstExploreCard);
    final exploreCardSize = tester.getSize(firstExploreCard);

    expect(feedTitlePos.dy, greaterThan(exclusivePos.dy - 520));
    expect(exploreCardPos.dy, greaterThan(feedTitlePos.dy));
    expect(exploreCardSize.width, inInclusiveRange(342, 355));
    expect(tester.takeException(), isNull);
  });
}
