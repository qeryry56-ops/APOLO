import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/screens/ad_detail_screen.dart';

class _StubDetailHttpAdapter implements HttpClientAdapter {
  final Map<String, dynamic> adPayload;

  _StubDetailHttpAdapter(this.adPayload);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final payload = options.path.contains('/ads/')
        ? {
            'status': 'success',
            'ad': adPayload,
            'related_ads': const [],
          }
        : {
            'status': 'success',
            'categories': const [],
            'cities': const [],
            'data': const [],
          };
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
    AppState().favoriteAdIds.clear();
    AppState().sellerUserReviews.clear();
  });

  testWidgets(
      'AdDetailScreen reproduces Casa Oliva Villa reference specs, hero height, 4 spec cards, host card, and removes sticky bottom bar',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final sampleAd = <String, dynamic>{
      'id': 9101,
      'title': 'Casa Oliva Villa',
      'badge_label': 'Villa',
      'rating': '4.8',
      'reviews_count': 128,
      'highlight_label': 'Guest favourite',
      'photo_count_total': 24,
      'video_duration': '0:45',
      'has_video': true,
      'location_display': 'Quinta da Marinha, Cascais, Portugal',
      'price': 212,
      'nightly_price_display': '\$212',
      'price_frequency': 'per night',
      'guests': 6,
      'bedrooms': 3,
      'beds': 4,
      'baths': 2,
      'host_title': 'Hosted by Marta',
      'host_subtitle': 'Superhost · 4 years hosting · replies in 1 h',
      'host_initials': 'MR',
      'total_price_display': '\$933',
      'total_unit_label': 'total',
      'total_subtitle': 'May 20–24 · taxes incl.',
      'cta_label': 'Book now',
      'seller': {
        'id': 77,
        'name': 'Marta Ribeiro',
        'is_verified': true,
      },
      'images': [
        'assets/images/cat_realestate.png',
        'assets/images/cat_home.png',
      ],
    };

    final state = AppState();
    final previousAdapter = state.api.dio.httpClientAdapter;
    final previousLocale = state.locale;
    state.api.dio.httpClientAdapter = _StubDetailHttpAdapter(sampleAd);
    await tester.runAsync(() => state.setLocale(const Locale('en')));
    addTearDown(() async {
      await tester.runAsync(() => state.setLocale(previousLocale));
      state.api.dio.httpClientAdapter = previousAdapter;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: AdDetailScreen(adId: 9101, initialAd: sampleAd),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Dynamic Layer v5.1 Top Nav, Hero tags & video tour pill (no sticky bottom bar)
    expect(find.byKey(const Key('dl-detail-top-nav')), findsOneWidget);
    expect(find.byKey(const Key('dl-detail-back-btn')), findsOneWidget);
    expect(find.byKey(const Key('dl-detail-fav-btn')), findsOneWidget);
    expect(find.byKey(const Key('dl-detail-more-btn')), findsOneWidget);
    expect(find.byKey(const Key('dl-detail-bottom-bar')), findsNothing);
    expect(find.byKey(const Key('dl-detail-primary-cta')), findsNothing);
    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Video tour'), findsOneWidget);
    expect(find.text('0:45'), findsOneWidget);
    expect(find.text('Villa'), findsWidgets);
    expect(find.text('4.8 · 128'), findsOneWidget);
    expect(find.text('Guest favourite'), findsOneWidget);
    expect(find.text('1/24'), findsOneWidget);

    // Title, pricing row, and Message quick action
    expect(find.text('Casa Oliva Villa'), findsOneWidget);
    expect(find.text('Quinta da Marinha, Cascais, Portugal'), findsOneWidget);
    expect(find.text('\$212'), findsOneWidget);
    expect(find.text('per night'), findsOneWidget);
    expect(find.text('Message'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.heart), findsOneWidget);

    // Scroll below Message Seller & 4 Actions to inspect 4 spec cards & Seller section
    await tester.drag(find.byType(ListView).first, const Offset(0, -420));
    await tester.pump(const Duration(milliseconds: 250));

    // 4 horizontal spec cards
    expect(find.text('6'), findsOneWidget);
    expect(find.text('Guests'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Bedrooms'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('Beds'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Baths'), findsOneWidget);

    // Host card inside Seller section
    expect(find.text('MR'), findsOneWidget);
    expect(find.text('Hosted by Marta'), findsOneWidget);
    expect(
      find.text('Superhost · 4 years hosting · replies in 1 h'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'AdDetailScreen renders real Apolo Arabic classified ad with preserved specs, phone, and safety actions cleanly',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final realAd = <String, dynamic>{
      'id': 108,
      'title': 'حامل الهاتف المغناطيسي للسيارة',
      'price': 99,
      'price_formatted': '99 MAD',
      'negotiable': true,
      'is_vip': true,
      'views_count': 167,
      'condition': 'جديد',
      'phone_call': '0612345678',
      'description': 'حامل هاتف مغناطيسي قوي ومناسب لجميع السيارات في المغرب.',
      'category': {'id': 15, 'name_ar': 'أقسام أخرى', 'name_fr': 'Autres'},
      'city': {'id': 4, 'name_ar': 'سلا', 'name_fr': 'Salé'},
      'seller': {'id': 12, 'name': 'Amine K', 'is_verified': true},
      'images': ['assets/images/cat_other.png'],
    };

    final state = AppState();
    final previousAdapter = state.api.dio.httpClientAdapter;
    final previousLocale = state.locale;
    state.api.dio.httpClientAdapter = _StubDetailHttpAdapter(realAd);
    await tester.runAsync(() => state.setLocale(const Locale('ar')));
    addTearDown(() async {
      await tester.runAsync(() => state.setLocale(previousLocale));
      state.api.dio.httpClientAdapter = previousAdapter;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: AdDetailScreen(adId: 108, initialAd: realAd),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('حامل الهاتف المغناطيسي للسيارة'), findsOneWidget);
    expect(find.text('تفاصيل الإعلان'), findsOneWidget);
    expect(find.byKey(const Key('dl-detail-bottom-bar')), findsNothing);
    expect(
      find.byKey(const Key('dl-detail-call-btn'), skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('99 MAD'), findsWidgets);
    expect(find.text('رسالة'), findsOneWidget);
    expect(find.text('167', skipOffstage: false), findsOneWidget);
    // Fake Video Tour should not appear when listing has no video
    expect(find.text('Video tour'), findsNothing);
    expect(find.text('فيديو الإعلان'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'AdDetailScreen renders Facebook Marketplace layout below Hero, opens All Reviews, and supports Follow & Related searches',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mpAd = <String, dynamic>{
      'id': 2026,
      'title': 'iPhone 14 Pro piece',
      'price': 450,
      'price_formatted': '450 MAD',
      'listed_label': 'Just listed · 19 hours ago',
      'description': 'iPhone 14 Pro for parts iCloud.',
      'city': {'id': 14, 'name_ar': 'بوزنيقة', 'name_fr': 'Bouznika'},
      'category': {'id': 5, 'name_ar': 'هواتف', 'name_fr': 'Téléphones'},
      'seller': {
        'id': 55,
        'name': 'Simo El Kadmiri',
        'rating': 4.5,
        'reviews_count': 2,
        'joined_label': 'Joined Apolo in 2024',
        'reviews': [
          {
            'author': 'Adam',
            'date': 'Jul 6, 2025',
            'rating': 5,
            'comment': 'Great communication',
          },
          {
            'author': 'Amina',
            'date': 'Jun 15, 2026',
            'rating': 4,
            'comment': 'Fast pickup',
          },
        ],
      },
      'images': ['assets/images/cat_phones.png'],
    };

    final state = AppState();
    final previousAdapter = state.api.dio.httpClientAdapter;
    final previousLocale = state.locale;
    state.api.dio.httpClientAdapter = _StubDetailHttpAdapter(mpAd);
    await tester.runAsync(() => state.setLocale(const Locale('en')));
    addTearDown(() async {
      await tester.runAsync(() => state.setLocale(previousLocale));
      state.api.dio.httpClientAdapter = previousAdapter;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: AdDetailScreen(adId: 2026, initialAd: mpAd),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Marketplace Header + Inline Message Seller Card + 4 Action Circles (no sticky Contact seller bar)
    expect(find.text('iPhone 14 Pro piece'), findsOneWidget);
    expect(find.text('450 MAD'), findsWidgets);
    expect(find.text('Just listed · 19 hours ago'), findsOneWidget);
    expect(find.text('Message seller'), findsOneWidget);
    expect(find.text('Contact seller'), findsNothing);
    expect(find.byKey(const Key('dl-detail-bottom-bar')), findsNothing);
    expect(find.byKey(const Key('detail-quick-msg')), findsOneWidget);
    expect(find.byKey(const Key('detail-quick-send')), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);

    expect(find.text('Alerts'), findsOneWidget);
    expect(find.text('Message'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Description', skipOffstage: false), findsOneWidget);
    expect(
      find.text('iPhone 14 Pro for parts iCloud.', skipOffstage: false),
      findsOneWidget,
    );

    // Scroll down to inspect Seller, Location map, Related searches & Hide listing
    await tester.drag(find.byType(ListView), const Offset(0, -650));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Seller'), findsOneWidget);
    expect(find.text('Simo El Kadmiri'), findsOneWidget);
    expect(find.text('Joined Apolo in 2024'), findsOneWidget);
    expect(find.byKey(const Key('detail-follow-seller')), findsOneWidget);
    expect(find.byKey(const Key('detail-rate-seller-card')), findsOneWidget);
    expect(find.byKey(const Key('detail-write-review-btn')), findsOneWidget);
    expect(find.text('Follow'), findsOneWidget);

    await tester.tap(find.byKey(const Key('detail-follow-seller')));
    await tester.pump();
    expect(find.text('Following'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Location is approximate'), findsOneWidget);
    expect(find.text('Related searches'), findsOneWidget);
    expect(find.byKey(const Key('detail-hide-listing')), findsOneWidget);
    expect(find.text('Hide listing'), findsOneWidget);

    // Scroll back up to tap "See reviews" -> opens All Reviews page
    await tester.drag(find.byType(ListView), const Offset(0, 500));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.byKey(const Key('detail-see-reviews')));
    await tester.tap(find.byKey(const Key('detail-see-reviews')));
    await tester.pumpAndSettle();

    expect(find.text('All Reviews'), findsOneWidget);
    expect(find.text('Seller rating'), findsOneWidget);
    expect(find.text('5 stars'), findsOneWidget);
    expect(find.text('Filters'), findsOneWidget);
    expect(find.text('Sort'), findsOneWidget);
    expect(find.text('Adam'), findsOneWidget);
    expect(find.text('Amina'), findsOneWidget);
    expect(find.byKey(const Key('all-reviews-write-btn')), findsOneWidget);

    // Submit a new 5-star review directly from All Reviews
    await tester.tap(find.byKey(const Key('all-reviews-write-btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('review-star-5')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('review-comment-input')),
      'Super honest seller, clean iPhone parts!',
    );
    await tester.tap(find.byKey(const Key('review-submit-btn')));
    await tester.pumpAndSettle();

    expect(find.text('Super honest seller, clean iPhone parts!'), findsOneWidget);
    expect(find.text('Seller reviews (3)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
