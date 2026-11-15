import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:apolo_mobile/screens/widgets/accommodation_card.dart';

void main() {
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
      'main_image': 'assets/images/hero_3d_house.png',
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

    // Verify 0.84:1 aspect ratio
    final aspectFinder = find.byType(AspectRatio);
    expect(aspectFinder, findsOneWidget);
    final aspectWidget = tester.widget<AspectRatio>(aspectFinder);
    expect(aspectWidget.aspectRatio, closeTo(0.84, 0.001));

    // Verify top-left badges: "Cabin" and "4.9"
    expect(find.text('Cabin'), findsOneWidget);
    expect(find.text('4.9'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);

    // Verify bottom info panel text elements
    expect(find.text('Lakeside Cabin'), findsOneWidget);
    expect(find.text('Sintra, Portugal'), findsOneWidget);
    expect(find.text('\$651 total · 4 nights'), findsOneWidget);

    // Verify top-right heart outline icon initially and toggle behavior
    expect(find.byIcon(CupertinoIcons.heart), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.heart_fill), findsNothing);

    await tester.tap(find.byIcon(CupertinoIcons.heart));
    await tester.pump();

    expect(toggledState, isTrue);
    expect(find.byIcon(CupertinoIcons.heart_fill), findsOneWidget);
  });
}
