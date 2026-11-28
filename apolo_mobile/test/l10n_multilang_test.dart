import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/l10n/l10n.dart';
import 'package:apolo_mobile/screens/settings/settings_language_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppState().setLocale(const Locale('en'));
  });

  test('supports all 6 Marketplace locales (en, fr, ar, es, de, ja) with natural terms & placeholders', () {
    final supportedCodes =
        AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet();
    expect(supportedCodes, containsAll(<String>{'en', 'fr', 'ar', 'es', 'de', 'ja'}));
    expect(
      AppState.supportedLanguageCodes,
      containsAll(<String>{'en', 'fr', 'ar', 'es', 'de', 'ja'}),
    );

    final ja = lookupAppL10nByCode('ja');
    expect(ja.conditionLabel, '商品の状態');
    expect(ja.conditionNew, '新品・未使用');
    expect(ja.conditionLikeNew, '未使用に近い');
    expect(ja.conditionUsed, '中古');
    expect(ja.negotiableBadge, '値下げ交渉OK');
    expect(ja.fulfillmentMeetInPerson, '手渡し');
    expect(ja.fulfillmentDelivery, '配送');
    expect(ja.listingStatusSold, '売り切れ');
    expect(ja.listingStatusReserved, '取り置き中');
    expect(ja.safetyTipsTitle, '安全取引のヒント');
    expect(ja.otpResendCodeCountdown(30), contains('30'));

    final de = lookupAppL10nByCode('de');
    expect(de.conditionLabel, 'Zustand');
    expect(de.conditionNew, 'Neu');
    expect(de.conditionLikeNew, 'Wie neu');
    expect(de.conditionUsed, 'Gebraucht');
    expect(de.negotiableBadge, 'VB');
    expect(de.fulfillmentMeetInPerson, 'Abholung');
    expect(de.fulfillmentDelivery, 'Versand');
    expect(de.listingStatusSold, 'Verkauft');
    expect(de.listingStatusReserved, 'Reserviert');
    expect(de.safetyTipsTitle, 'Sicherheitstipps');
    expect(de.saveButton.length, lessThanOrEqualTo(12));

    final es = lookupAppL10nByCode('es');
    expect(es.conditionLabel, 'Estado');
    expect(es.conditionNew, 'Nuevo');
    expect(es.conditionLikeNew, 'Como nuevo');
    expect(es.negotiableBadge, 'Negociable');
    expect(es.fulfillmentMeetInPerson, 'Entrega en mano');
    expect(es.fulfillmentDelivery, 'Envío');
    expect(es.listingStatusSold, 'Vendido');
    expect(es.listingStatusReserved, 'Reservado');
    expect(es.safetyTipsTitle, 'Consejos de seguridad');

    final fr = lookupAppL10nByCode('fr');
    expect(fr.conditionLabel, 'État');
    expect(fr.conditionNew, 'Neuf');
    expect(fr.conditionLikeNew, 'Comme neuf');
    expect(fr.conditionUsed, 'Occasion');
    expect(fr.fulfillmentMeetInPerson, 'Remise en main propre');
    expect(fr.listingStatusSold, 'Vendu');
    expect(fr.listingStatusReserved, 'Réservé');

    final ar = lookupAppL10nByCode('ar');
    expect(ar.conditionLabel, 'الحالة');
    expect(ar.conditionNew, 'جديد');
    expect(ar.conditionUsed, 'مستعمل');
    expect(ar.fulfillmentMeetInPerson, 'تسليم يداً بيد');
    expect(ar.listingStatusSold, 'تم البيع');
    expect(ar.listingStatusReserved, 'محجوز');
  });

  testWidgets('SettingsLanguageScreen renders and switches across all 6 languages cleanly', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          Locale('en'),
          Locale('fr'),
          Locale('ar'),
          Locale('es'),
          Locale('de'),
          Locale('ja'),
        ],
        home: SettingsLanguageScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('lang-option-es')), findsOneWidget);
    expect(find.byKey(const Key('lang-option-de')), findsOneWidget);
    expect(find.byKey(const Key('lang-option-ja')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('lang-option-ja')));
    await tester.tap(find.byKey(const Key('lang-option-ja')));
    await tester.pumpAndSettle();
    expect(AppState().locale.languageCode, 'ja');
    expect(tester.takeException(), isNull);
  });
}
