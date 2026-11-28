import 'package:apolo_mobile/core/services/listing_translation_service.dart';
import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/l10n/l10n.dart';
import 'package:apolo_mobile/screens/ad_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildLocalizedDetailApp({
  required Locale locale,
  required Map<String, dynamic> ad,
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: AdDetailScreen(
      key: ValueKey('ad-detail-${ad['id']}'),
      adId: int.tryParse('${ad['id']}') ?? 101,
      initialAd: ad,
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ListingTranslationService.instance.clearMemoryCache();
    await AppState().setLocale(const Locale('en'));
  });

  tearDown(() async {
    ListingTranslationService.instance.clearMemoryCache();
    await AppState().setLocale(const Locale('en'));
  });

  test('detectListingLanguage & shouldOfferTranslation distinguish same vs different languages', () {
    expect(
      ListingTranslationService.detectListingLanguage(
        'Appartement Moderne avec piscine à vendre',
        'Très bon état, disponible pour remise en main propre.',
      ),
      'fr',
    );
    expect(
      ListingTranslationService.detectListingLanguage(
        'آيفون 16 برو ماكس بحالة ممتازة',
        'مع العلبة الأصلية والضمان',
      ),
      'ar',
    );
    expect(
      ListingTranslationService.detectListingLanguage(
        'Mountain Bike Carbon Frame',
        'Great condition, ready to ride.',
      ),
      'en',
    );

    // Same language -> do NOT offer translation
    expect(
      ListingTranslationService.shouldOfferTranslation(
        title: 'Mountain Bike Carbon Frame',
        description: 'Great condition, ready to ride.',
        appLang: 'en',
      ),
      isFalse,
    );

    // Different language -> offer translation
    expect(
      ListingTranslationService.shouldOfferTranslation(
        title: 'Appartement Moderne avec piscine à vendre',
        description: 'Très bon état, disponible.',
        appLang: 'en',
      ),
      isTrue,
    );
  });

  test('translateListing caches locally in SharedPreferences and memory', () async {
    const title = 'Vélo de route Carbon Neuf';
    const desc = 'Disponible immédiatement avec facture.';

    final first = await translateListing(title, desc, 'en');
    expect(first.sourceLang, 'fr');
    expect(first.targetLang, 'en');
    expect(first.title, title);
    expect(first.description, desc);

    // Clear memory cache to verify SharedPreferences disk cache hit
    ListingTranslationService.instance.clearMemoryCache();
    final cached = await ListingTranslationService.instance
        .getCachedTranslation(title, desc, 'en');
    expect(cached, isNotNull);
    expect(cached!.sourceLang, 'fr');
    expect(cached.targetLang, 'en');
  });

  testWidgets(
    'AdDetailScreen hides Translate button when listing matches app language and shows it when different',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // 1. Same language (English listing in English app) -> button hidden
      await tester.runAsync(() => AppState().setLocale(const Locale('en')));
      await tester.pumpWidget(
        _buildLocalizedDetailApp(
          locale: const Locale('en'),
          ad: const {
            'id': 201,
            'title': 'MacBook Pro 14 M3 Pro',
            'description': 'Excellent condition with original charger.',
            'price': 19500,
            'price_formatted': '19 500 DH',
            'images': ['assets/images/cat_other.png'],
          },
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('ad-detail-translate-btn')), findsNothing);

      // 2. Different language (French listing in English app) -> button visible
      await tester.pumpWidget(
        _buildLocalizedDetailApp(
          locale: const Locale('en'),
          ad: const {
            'id': 202,
            'title': 'Appartement Moderne avec terrasse à vendre',
            'description': 'Très bon état, disponible pour remise en main propre.',
            'price': 1450000,
            'price_formatted': '1 450 000 DH',
            'images': ['assets/images/cat_other.png'],
          },
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('ad-detail-translate-btn')), findsOneWidget);

      // Tap Translate -> shows Translated from French + Original title & description
      await tester.tap(find.byKey(const Key('ad-detail-translate-btn')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byKey(const Key('ad-detail-translated-badge')), findsOneWidget);
      expect(find.text('Translated from French'), findsWidgets);
      expect(find.byKey(const Key('ad-detail-original-title')), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('ad-detail-desc-translated-badge')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      expect(
        find.byKey(const Key('ad-detail-desc-translated-badge')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('ad-detail-original-description')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
