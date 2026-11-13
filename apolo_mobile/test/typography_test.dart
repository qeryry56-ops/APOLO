import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:apolo_mobile/core/config/app_config.dart';
import 'package:apolo_mobile/theme/app_theme.dart';
import 'package:apolo_mobile/theme/app_typography.dart';

void main() {
  group('AppTypography Resolution Matrix', () {
    test('iOS uses native Apple system typography (fontFamily: null)', () {
      // 1. Arabic on iOS -> null (system selects SF Arabic automatically)
      expect(
        AppTypography.resolveFontFamily(
          const Locale('ar'),
          platform: TargetPlatform.iOS,
        ),
        isNull,
      );

      // 2. English on iOS -> null (system selects SF Pro automatically)
      expect(
        AppTypography.resolveFontFamily(
          const Locale('en'),
          platform: TargetPlatform.iOS,
        ),
        isNull,
      );

      // 3. French on iOS -> null (system selects SF Pro automatically)
      expect(
        AppTypography.resolveFontFamily(
          const Locale('fr'),
          platform: TargetPlatform.iOS,
        ),
        isNull,
      );

      // Fallback on iOS must also be null to allow native OS fallback
      expect(
        AppTypography.resolveFontFamilyFallback(
          const Locale('ar'),
          platform: TargetPlatform.iOS,
        ),
        isNull,
      );
    });

    test('Android uses Tajawal for Arabic and Inter for English/French', () {
      // 4. Arabic on Android -> Tajawal
      expect(
        AppTypography.resolveFontFamily(
          const Locale('ar'),
          platform: TargetPlatform.android,
        ),
        equals(AppTypography.fontTajawal),
      );

      // 5. English on Android -> Inter
      expect(
        AppTypography.resolveFontFamily(
          const Locale('en'),
          platform: TargetPlatform.android,
        ),
        equals(AppTypography.fontInter),
      );

      // 6. French on Android -> Inter
      expect(
        AppTypography.resolveFontFamily(
          const Locale('fr'),
          platform: TargetPlatform.android,
        ),
        equals(AppTypography.fontInter),
      );

      // Fallback on Android
      final arFallback = AppTypography.resolveFontFamilyFallback(
        const Locale('ar'),
        platform: TargetPlatform.android,
      );
      expect(arFallback, contains(AppTypography.fontTajawal));

      final frFallback = AppTypography.resolveFontFamilyFallback(
        const Locale('fr'),
        platform: TargetPlatform.android,
      );
      expect(frFallback, contains(AppTypography.fontInter));
    });
  });

  group('Typography Design Specifications & Scale', () {
    test(
        'Arabic typography respects comfortable line-height and no negative letter spacing',
        () {
      final textTheme = AppTypography.buildTextTheme(
        const Locale('ar'),
        platform: TargetPlatform.android,
      );

      // Prominent display (68-72, 700)
      expect(textTheme.displayLarge?.fontSize, equals(68));
      expect(textTheme.displayLarge?.fontWeight, equals(FontWeight.w700));
      expect(textTheme.displayLarge?.fontFamily, equals('Tajawal'));
      expect(textTheme.displayLarge?.letterSpacing, greaterThanOrEqualTo(0.0));

      // Large screen heading (30, 600-700)
      expect(textTheme.headlineLarge?.fontSize, equals(30));
      expect(textTheme.headlineLarge?.fontWeight, equals(FontWeight.w700));
      expect(textTheme.headlineLarge?.letterSpacing, greaterThanOrEqualTo(0.0));

      // Section heading (24, 600)
      expect(textTheme.headlineMedium?.fontSize, equals(24));
      expect(textTheme.headlineMedium?.fontWeight, equals(FontWeight.w600));

      // Medium title (20, 600)
      expect(textTheme.titleLarge?.fontSize, equals(20));
      expect(textTheme.titleLarge?.fontWeight, equals(FontWeight.w600));

      // Primary body (17, 400)
      expect(textTheme.bodyLarge?.fontSize, equals(17));
      expect(textTheme.bodyLarge?.fontWeight, equals(FontWeight.w400));
      expect(textTheme.bodyLarge?.height, inInclusiveRange(1.4, 1.6));
      expect(textTheme.bodyLarge?.letterSpacing, greaterThanOrEqualTo(0.0));

      // Secondary body (15, 400)
      expect(textTheme.bodyMedium?.fontSize, equals(15));
      expect(textTheme.bodyMedium?.fontWeight, equals(FontWeight.w400));
      expect(textTheme.bodyMedium?.height, inInclusiveRange(1.4, 1.6));

      // Buttons (17-18, 600)
      expect(textTheme.labelLarge?.fontSize, inInclusiveRange(17, 18));
      expect(textTheme.labelLarge?.fontWeight, equals(FontWeight.w600));

      // Small labels (13-14, 400-500)
      expect(textTheme.labelMedium?.fontSize, inInclusiveRange(13, 14));
      expect(textTheme.labelMedium?.fontWeight, equals(FontWeight.w500));
    });

    test(
        'English & French typography uses Inter on Android with balanced metrics',
        () {
      final textTheme = AppTypography.buildTextTheme(
        const Locale('en'),
        platform: TargetPlatform.android,
      );

      expect(textTheme.displayLarge?.fontFamily, equals('Inter'));
      expect(textTheme.headlineLarge?.letterSpacing, lessThan(0.0));
      expect(textTheme.bodyLarge?.height, inInclusiveRange(1.2, 1.4));
      expect(textTheme.bodyLarge?.fontSize, equals(17));
      expect(textTheme.labelLarge?.fontSize, inInclusiveRange(17, 18));
    });

    test('Dedicated amountStyle provides tabular figures and large scale', () {
      final style = AppTypography.amountStyle(
        locale: const Locale('en'),
        platform: TargetPlatform.android,
        size: 70,
      );

      expect(style.fontSize, equals(70));
      expect(style.fontWeight, equals(FontWeight.w700));
      expect(style.fontFamily, equals('Inter'));
      expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
    });
  });

  group('AppTheme Integration', () {
    test('Light theme applies typography and preserves brand identity', () {
      final theme = AppTheme.light(
        const Locale('ar'),
        platform: TargetPlatform.android,
      );

      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, equals(AppConfig.primary));
      expect(theme.textTheme.bodyLarge?.fontFamily, equals('Tajawal'));
      expect(theme.textTheme.headlineLarge?.fontSize, equals(30));
    });

    test('Dark theme applies typography correctly', () {
      final theme = AppTheme.dark(
        const Locale('fr'),
        platform: TargetPlatform.android,
      );

      expect(theme.brightness, equals(Brightness.dark));
      expect(theme.textTheme.bodyLarge?.fontFamily, equals('Inter'));
    });

    test('AppConfig.buildTheme delegates cleanly to AppTheme', () {
      final theme = AppConfig.buildTheme(
        const Locale('ar'),
        platform: TargetPlatform.iOS,
      );

      // On iOS, AppTypography resolves to null so Flutter maps it to CupertinoSystemText (Native Apple System Font)
      expect(
        AppTypography.resolveFontFamily(
          const Locale('ar'),
          platform: TargetPlatform.iOS,
        ),
        isNull,
      );
      expect(
        theme.textTheme.bodyLarge?.fontFamily,
        anyOf(isNull, equals('CupertinoSystemText')),
      );
    });
  });

  group('AppStrings Multilingual Support', () {
    test('Supports Arabic, French, and English gracefully', () {
      final ar = AppStrings('ar');
      final fr = AppStrings('fr');
      final en = AppStrings('en');

      expect(ar.isAr, isTrue);
      expect(ar.isEn, isFalse);
      expect(ar.home, equals('الرئيسية'));

      expect(fr.isFr, isTrue);
      expect(fr.home, equals('Accueil'));

      expect(en.isEn, isTrue);
      expect(en.home, equals('Home'));
      expect(en.login, equals('Login'));
    });

    test('Arabic tracking helper eliminates negative/positive letterSpacing',
        () {
      expect(AppTypography.isArabicLocale(const Locale('ar')), isTrue);
      expect(AppTypography.isArabicLocale(const Locale('fr')), isFalse);
      expect(AppTypography.isArabicLocale(const Locale('en')), isFalse);

      expect(AppTypography.tracking(const Locale('ar'), -0.5), equals(0.0));
      expect(AppTypography.tracking(const Locale('ar'), 0.8), equals(0.0));
      expect(AppTypography.tracking(const Locale('fr'), -0.5), equals(-0.5));
      expect(AppTypography.tracking(const Locale('en'), 0.8), equals(0.8));
    });

    testWidgets('trackingForContext & RTL/LTR directionality react to locale', (
      tester,
    ) async {
      double? tracked;
      TextDirection? resolvedDir;

      Widget buildProbe(Locale locale) => MaterialApp(
            locale: locale,
            supportedLocales: const [Locale('ar'), Locale('fr'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: AppTheme.dark(locale, platform: TargetPlatform.iOS),
            home: Builder(
              builder: (context) {
                tracked = AppTypography.trackingForContext(context, -0.4);
                resolvedDir = Directionality.of(context);
                return const Scaffold(body: Text('Apolo 1234'));
              },
            ),
          );

      await tester.pumpWidget(buildProbe(const Locale('ar')));
      expect(tracked, equals(0.0));
      expect(resolvedDir, equals(TextDirection.rtl));

      await tester.pumpWidget(buildProbe(const Locale('en')));
      expect(tracked, equals(-0.4));
      expect(resolvedDir, equals(TextDirection.ltr));

      await tester.pumpWidget(buildProbe(const Locale('fr')));
      expect(tracked, equals(-0.4));
      expect(resolvedDir, equals(TextDirection.ltr));
    });
  });
}
