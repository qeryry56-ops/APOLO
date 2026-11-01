import 'package:flutter_test/flutter_test.dart';
import 'package:apolo_mobile/core/config/app_config.dart';

void main() {
  test('AppStrings bilingual Arabic and French localization check', () {
    final ar = AppStrings('ar');
    final fr = AppStrings('fr');

    expect(ar.isAr, true);
    expect(fr.isAr, false);
    expect(ar.home, 'الرئيسية');
    expect(fr.home, 'Accueil');
  });
}
