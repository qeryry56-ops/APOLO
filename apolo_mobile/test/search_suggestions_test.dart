import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/screens/search_screen.dart';
import 'package:apolo_mobile/screens/widgets/ad_card.dart';
import 'package:apolo_mobile/screens/widgets/explore_listing_card.dart';
import 'package:apolo_mobile/theme/app_theme.dart';
import 'package:apolo_mobile/widgets/apolo_badges_kit.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubSearchAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({
        'status': 'success',
        'data': const <dynamic>[],
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
  TestWidgetsFlutterBinding.ensureInitialized();

  final state = AppState();
  late Dio originalDio;
  late Locale originalLocale;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    originalDio = state.api.dio;
    originalLocale = state.locale;
    state.followedSellerIds.clear();
    state.api.dio = Dio(BaseOptions(baseUrl: 'https://tests.invalid'))
      ..httpClientAdapter = _StubSearchAdapter();
    await state.setLocale(const Locale('en'));
  });

  tearDown(() async {
    state.followedSellerIds.clear();
    state.api.dio = originalDio;
    await state.setLocale(originalLocale);
  });

  testWidgets(
    'Tapping Search bar opens Dynamic Layer Suggestions view (33215:34358), toggles Follow/Followed, filters live, and returns on Back',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: SearchScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byKey(const Key('dl-search-suggestions-screen')), findsNothing);

      // Tap into search bar -> opens Dynamic Layer Search Suggestions screen
      await tester.tap(find.byKey(const Key('explore-search-bar-field')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byKey(const Key('dl-search-suggestions-screen')), findsOneWidget);
      expect(find.byKey(const Key('dl-search-back-button')), findsOneWidget);
      expect(find.byKey(const Key('dl-search-header-title')), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Search for usernames'), findsOneWidget);
      expect(find.byKey(const Key('dl-search-suggestions-label')), findsOneWidget);
      expect(find.text('Suggestions'), findsOneWidget);

      // Verify Julia Bentz & Joshua Krane cards + blue verified seals
      expect(find.text('Julia Bentz'), findsOneWidget);
      expect(find.text('@julia.be'), findsOneWidget);
      expect(find.text('Joshua Krane'), findsOneWidget);
      expect(find.text('@uxwithjoshua'), findsOneWidget);
      expect(find.byType(ApoloVerifiedBadge), findsWidgets);

      // Unfollowed button starts sky-blue (#2997FF) with "Follow"
      final followBtnFinder = find.byKey(const Key('dl-suggestion-follow-801'));
      expect(followBtnFinder, findsOneWidget);
      final followMatBefore = tester.widget<Material>(followBtnFinder);
      expect(followMatBefore.color, const Color(0xFF2997FF));
      expect(
        find.descendant(of: followBtnFinder, matching: find.text('Follow')),
        findsOneWidget,
      );

      // Tap Follow -> flips to #EEEEEE "Followed" and persists in AppState
      await tester.tap(followBtnFinder);
      await tester.pump(const Duration(milliseconds: 200));

      expect(state.isFollowingSeller(801), isTrue);
      final followMatAfter = tester.widget<Material>(followBtnFinder);
      expect(followMatAfter.color, const Color(0xFFEEEEEE));
      expect(
        find.descendant(of: followBtnFinder, matching: find.text('Followed')),
        findsOneWidget,
      );

      // Typing filters suggested accounts live
      await tester.enterText(
        find.byKey(const Key('dl-search-input-field')),
        'joshua',
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Joshua Krane'), findsOneWidget);
      expect(find.text('Julia Bentz'), findsNothing);

      // Back button exits Search Suggestions mode back to Explore feed
      await tester.tap(find.byKey(const Key('dl-search-back-button')));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byKey(const Key('dl-search-suggestions-screen')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Search Suggestions renders cleanly without overflow in Arabic RTL on 390x844',
    (tester) async {
      await tester.runAsync(() => state.setLocale(const Locale('ar')));
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: SearchScreen(initialSearchActive: true),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byKey(const Key('dl-search-suggestions-screen')), findsOneWidget);
      expect(find.text('اقتراحات'), findsOneWidget);
      expect(find.text('متابعة'), findsWidgets);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    },
  );

  testWidgets(
    'Explore v2 supports Recent Searches, dismissible active filter chips, Feed/Grid switcher, and Dark Mode',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Use network failure adapter so curated Moroccan Explore catalog loads
      state.api.dio = Dio(BaseOptions(baseUrl: 'https://offline.invalid'))
        ..httpClientAdapter = _FailingSearchAdapter();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(const Locale('en')),
          darkTheme: AppTheme.dark(const Locale('en')),
          themeMode: ThemeMode.dark,
          home: const SearchScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byType(ExploreListingCard), findsWidgets);
      expect(find.byType(AdCard), findsNothing);

      // Toggle from full-width Feed to 2-column Compact Grid and back
      await tester.tap(find.byKey(const Key('dl-explore-view-toggle')));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byKey(const Key('dl-explore-compact-grid')), findsOneWidget);
      expect(find.byType(AdCard), findsWidgets);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('dl-explore-view-toggle')));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(ExploreListingCard), findsWidgets);

      // Enter Search Suggestions in Dark Mode and submit a query -> saves to Recent searches & shows active chip
      await tester.tap(find.byKey(const Key('explore-search-bar-field')));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byKey(const Key('dl-search-suggestions-screen')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('dl-search-input-field')),
        'Mercedes',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump(const Duration(milliseconds: 350));

      // Active query chip is shown and dismissible
      expect(find.byKey(const Key('explore-chip-query')), findsOneWidget);
      expect(find.text('Mercedes-Benz Classe C 220d AMG'), findsOneWidget);

      await tester.tap(find.byKey(const Key('explore-chip-query')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('explore-chip-query')), findsNothing);

      // Re-opening Search Suggestions displays 'Mercedes' under Recent searches and allows clearing
      await tester.tap(find.byKey(const Key('explore-search-bar-field')));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byKey(const Key('dl-recent-searches-label')), findsOneWidget);
      expect(find.byKey(const Key('dl-recent-query-Mercedes')), findsOneWidget);

      await tester.tap(find.byKey(const Key('dl-recent-clear-all')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const Key('dl-recent-query-Mercedes')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

class _FailingSearchAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException.connectionError(
      requestOptions: options,
      reason: 'offline',
    );
  }

  @override
  void close({bool force = false}) {}
}
