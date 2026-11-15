import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:apolo_mobile/screens/search_screen.dart';
import 'package:apolo_mobile/screens/widgets/explore_listing_card.dart';

void main() {
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
        'assets/images/hero_3d_house.png',
        'assets/images/cat_realestate.png',
        'assets/images/hero_3d_house.png',
        'assets/images/cat_realestate.png',
        'assets/images/hero_3d_house.png',
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
    expect(find.text('Guest favorite'), findsOneWidget);
    expect(find.text('(95)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'SearchScreen Explore view renders ExploreListingCard full-width on 390x844 mobile without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: SearchScreen(),
      ),
    );
    // Allow network call failure & ScrollReveal stagger timers to complete
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(ExploreListingCard), findsWidgets);
    expect(find.text('Casa Oliva Villa'), findsOneWidget);

    final firstCardSize = tester.getSize(find.byType(ExploreListingCard).first);
    expect(firstCardSize.width, inInclusiveRange(342, 355));
    expect(firstCardSize.height, inInclusiveRange(360, 380));
    expect(tester.takeException(), isNull);
  });
}
