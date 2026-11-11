import 'package:flutter_test/flutter_test.dart';
import 'package:apolo_mobile/core/config/app_config.dart';
import 'package:apolo_mobile/core/state/app_state.dart';

void main() {
  group('AppStrings Localization Tests', () {
    test('Arabic and French localization keys return non-empty strings', () {
      final ar = AppStrings('ar');
      final fr = AppStrings('fr');

      expect(ar.isAr, true);
      expect(fr.isAr, false);
      expect(ar.home, 'الرئيسية');
      expect(fr.home, 'Accueil');
      expect(ar.messages, 'الرسائل');
      expect(fr.messages, 'Messages');
      expect(ar.profile, 'حسابي');
      expect(fr.profile, 'Profil');
    });

    test('Helper method tr returns proper language string', () {
      final ar = AppStrings('ar');
      final fr = AppStrings('fr');

      expect(ar.tr('سيارات', 'Voitures'), 'سيارات');
      expect(fr.tr('سيارات', 'Voitures'), 'Voitures');
    });
  });

  group('AppState Core Logic & Taxonomy Tests', () {
    test(
        'Category asset resolver maps automotive categories to cat_vehicles.png',
        () {
      final state = AppState();
      final catVoiture = {
        'name': 'Véhicules',
        'name_fr': 'Voiture',
        'slug': 'auto'
      };
      final catPhone = {
        'name': 'Téléphones',
        'name_ar': 'هواتف',
        'slug': 'telephones'
      };
      final catImmo = {
        'name': 'Immobilier',
        'name_ar': 'عقارات',
        'slug': 'immobilier'
      };

      expect(
          state.assetForCategory(catVoiture), 'assets/images/cat_vehicles.png');
      expect(state.assetForCategory(catPhone), 'assets/images/cat_phones.png');
      expect(
          state.assetForCategory(catImmo), 'assets/images/cat_realestate.png');
    });

    test('Category label formatting keeps clean non-overflowing text', () {
      final state = AppState();
      final catVoiture = {'name_ar': 'سيارات ومركبات', 'slug': 'auto'};
      final catImmo = {'name_ar': 'شقق ومنازل وعقارات', 'slug': 'immobilier'};

      expect(state.formatCategoryLabel(catVoiture), 'وسائل النقل');
      expect(state.formatCategoryLabel(catImmo), 'عقارات');
    });

    test('Personalized ranking algorithm ranks preferred categories higher',
        () {
      final state = AppState();
      state.categoryInterestWeights = {
        1: 5
      }; // High interest in category 1 (cars)

      final ads = [
        {'id': 101, 'category_id': 2, 'title': 'Appartement'},
        {'id': 102, 'category_id': 1, 'title': 'Mercedes C220'},
      ];

      final ranked = state.rankAdsForUser(ads);
      expect(ranked.first['id'], 102); // Car ad ranked first
    });
  });
}
