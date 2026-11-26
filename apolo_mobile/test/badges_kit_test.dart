import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/theme/app_theme.dart';
import 'package:apolo_mobile/widgets/apolo_badges_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrapWithApp({
  required Locale locale,
  required Widget child,
  ThemeMode themeMode = ThemeMode.light,
}) {
  return MaterialApp(
    themeMode: themeMode,
    theme: AppTheme.light(locale),
    darkTheme: ThemeData.dark(),
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final state = AppState();
  late Locale originalLocale;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    originalLocale = state.locale;
    await state.setLocale(const Locale('en'));
  });

  tearDown(() async {
    await state.setLocale(originalLocale);
  });

  test('ApoloSellerRank.resolve covers all 6 tiers and explicit backend override', () {
    expect(
      ApoloSellerRank.resolve(
        user: {'rank': 'diamond'},
        listingsCount: 0,
        totalViews: 0,
      ),
      ApoloSellerRank.diamond,
    );
    expect(
      ApoloSellerRank.resolve(listingsCount: 0, totalViews: 0),
      ApoloSellerRank.bronze,
    );
    expect(
      ApoloSellerRank.resolve(
        listingsCount: 2,
        totalViews: 0,
        isVerified: true,
      ),
      ApoloSellerRank.silver,
    );
    expect(
      ApoloSellerRank.resolve(
        listingsCount: 5,
        totalViews: 400,
        isBusiness: true,
      ),
      ApoloSellerRank.gold,
    );
    expect(
      ApoloSellerRank.resolve(
        listingsCount: 3,
        totalViews: 200,
        isProPlus: true,
        isBusiness: true,
      ),
      ApoloSellerRank.platinum,
    );
    expect(
      ApoloSellerRank.resolve(
        listingsCount: 12,
        totalViews: 1500,
        isProPlus: true,
        isBusiness: true,
      ),
      ApoloSellerRank.diamond,
    );
    expect(
      ApoloSellerRank.resolve(
        listingsCount: 25,
        totalViews: 6000,
        isProPlus: true,
        isBusiness: true,
      ),
      ApoloSellerRank.champion,
    );
  });

  test('ApoloSellerRank.assetPath matches light and dark badge assets', () {
    for (final rank in ApoloSellerRank.values) {
      expect(
        rank.assetPath(Brightness.light),
        'assets/badges/rank_${rank.name}_light.png',
      );
      expect(
        rank.assetPath(Brightness.dark),
        'assets/badges/rank_${rank.name}_dark.png',
      );
    }
  });

  testWidgets('Verified, Rank, Identity row render cleanly in light & dark modes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrapWithApp(
        locale: state.locale,
        themeMode: ThemeMode.light,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ApoloVerifiedBadge(size: 20),
            SizedBox(height: 8),
            ApoloRankBadge(
              rank: ApoloSellerRank.gold,
              size: 22,
              showLabel: true,
            ),
            SizedBox(height: 8),
            ApoloIdentityBadgesRow(
              rank: ApoloSellerRank.champion,
              isVerified: true,
              isProPlus: true,
              isBusiness: true,
              showRankLabel: true,
              showProPill: true,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('apolo-verified-badge')), findsNWidgets(2));
    expect(find.byKey(const Key('apolo-rank-badge-gold')), findsOneWidget);
    expect(find.byKey(const Key('apolo-rank-badge-champion')), findsOneWidget);
    expect(find.byKey(const Key('apolo-identity-badges-row')), findsOneWidget);
    expect(find.text('PRO+'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      _wrapWithApp(
        locale: state.locale,
        themeMode: ThemeMode.dark,
        child: const ApoloRankBadge(
          rank: ApoloSellerRank.platinum,
          size: 24,
          showLabel: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('apolo-rank-badge-platinum')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ApoloRankProgressCard opens Trust & Rank sheet with all 6 tiers', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrapWithApp(
        locale: state.locale,
        child: const ApoloRankProgressCard(
          rank: ApoloSellerRank.gold,
          listingsCount: 6,
          totalViews: 520,
          isVerified: true,
          isProPlus: false,
          isBusiness: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cardFinder = find.byKey(const Key('apolo-rank-progress-card'));
    expect(cardFinder, findsOneWidget);

    await tester.tap(cardFinder);
    await tester.pumpAndSettle();

    expect(find.text('Trust & Seller Ranks'), findsOneWidget);
    expect(find.text('All Seller Ranks'), findsOneWidget);
    expect(find.byKey(const Key('apolo-rank-badge-bronze')), findsOneWidget);
    expect(find.byKey(const Key('apolo-rank-badge-silver')), findsOneWidget);
    expect(find.byKey(const Key('apolo-rank-badge-gold')), findsNWidgets(3));
    expect(find.byKey(const Key('apolo-rank-badge-platinum')), findsOneWidget);
    expect(find.byKey(const Key('apolo-rank-badge-diamond')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('apolo-rank-badge-champion')),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.byKey(const Key('apolo-rank-badge-champion')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
