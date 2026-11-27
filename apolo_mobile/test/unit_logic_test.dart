import 'package:apolo_mobile/account/account_helpers.dart';
import 'package:apolo_mobile/core/config/app_config.dart';
import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/screens/widgets/chat_utils.dart';
import 'package:apolo_mobile/theme/app_typography.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppState().categories = [
      {'id': 1, 'name_ar': 'سيارات', 'name_fr': 'Voitures', 'slug': 'auto'},
      {'id': 2, 'name_ar': 'عقارات', 'name_fr': 'Immobilier', 'slug': 'immo'},
      {'id': 3, 'name_ar': 'هواتف', 'name_fr': 'Téléphones', 'slug': 'phones'},
    ];
    AppState().categoryInterestWeights = {};
    AppState().preferredCityId = null;
    await AppState().setLocale(const Locale('ar'));
  });

  group('AccountValidation unit & edge-case tests', () {
    test('normalizeDigits handles empty, Arabic, Persian, and negative inputs', () {
      expect(AccountValidation.normalizeDigits(''), '');
      expect(AccountValidation.normalizeDigits('٠١٢٣٤٥٦٧٨٩'), '0123456789');
      expect(AccountValidation.normalizeDigits('۰۱۲۳۴۵۶۷۸۹'), '0123456789');
      expect(AccountValidation.normalizeDigits('-٥٠٠'), '-500');
    });

    test('email rejects empty, whitespace, long >254, and malformed values', () {
      expect(AccountValidation.email(''), isFalse);
      expect(AccountValidation.email('   '), isFalse);
      expect(AccountValidation.email('${'a' * 246}@apolo.ma'), isFalse);
      expect(AccountValidation.email('a..b@apolo.ma'), isFalse);
      expect(AccountValidation.email('user.@apolo.ma'), isFalse);
      expect(AccountValidation.email('valid.user+1@apolo.ma'), isTrue);
    });

    test('phone rejects empty, negative, invalid prefix, and short/long numbers', () {
      expect(AccountValidation.phone(''), isNull);
      expect(AccountValidation.phone('   '), isNull);
      expect(AccountValidation.phone('-0612345678'), isNull);
      expect(AccountValidation.phone('0812345678'), isNull);
      expect(AccountValidation.phone('061234567890'), isNull);
      expect(AccountValidation.phone('0712345678'), '+212712345678');
      expect(AccountValidation.phone('612345678'), '+212612345678');
    });

    test('password and otp reject edge inputs', () {
      expect(AccountValidation.password(''), isFalse);
      expect(AccountValidation.password('        '), isFalse);
      expect(AccountValidation.password('1234567'), isFalse);
      expect(AccountValidation.password('12345678'), isTrue);

      expect(AccountValidation.otp(''), isFalse);
      expect(AccountValidation.otp('-12345'), isFalse);
      expect(AccountValidation.otp('12345'), isFalse);
      expect(AccountValidation.otp('1234567'), isFalse);
      expect(AccountValidation.otp('٠١٢٣٤٥'), isTrue);
    });

    test('maskEmail handles single char, multi char, and empty/malformed strings', () {
      expect(AccountValidation.maskEmail(null), isNull);
      expect(AccountValidation.maskEmail(''), isNull);
      expect(AccountValidation.maskEmail('@apolo.ma'), isNull);
      expect(AccountValidation.maskEmail('a@b.ma'), 'a***@b.ma');
      expect(AccountValidation.maskEmail('amine@apolo.ma'), 'am***@apolo.ma');
    });
  });

  group('accountError localization mapping', () {
    test('maps AccountFailure and DioException HTTP status codes', () {
      expect(accountError(const AccountFailure('verification'), true),
          contains('رمز التحقق'));
      expect(accountError(const AccountFailure('rejected', 'Custom msg'), false),
          'Custom msg');

      final req = RequestOptions(path: '/test');
      Response<dynamic> resp(int code, [dynamic data]) =>
          Response(requestOptions: req, statusCode: code, data: data);

      expect(
        accountError(
            DioException(requestOptions: req, response: resp(429)), true),
        contains('محاولات كثيرة'),
      );
      expect(
        accountError(
            DioException(requestOptions: req, response: resp(401)), false),
        contains('Identifiants'),
      );
      expect(
        accountError(
            DioException(
              requestOptions: req,
              response: resp(422, {'message': 'Email pris'}),
            ),
            false),
        'Email pris',
      );
      expect(
        accountError(
          DioException(
              requestOptions: req, type: DioExceptionType.connectionTimeout),
          true,
        ),
        contains('تعذر الاتصال'),
      );
      expect(
        accountError(StateError('unknown'), true),
        contains('تعذر إتمام العملية'),
      );
    });
  });

  group('AppState smart ranking & taxonomy edge cases', () {
    test('extractAdCategoryId rejects zero, negative, and empty values', () {
      final state = AppState();
      expect(state.extractAdCategoryId({}), isNull);
      expect(state.extractAdCategoryId({'category_id': 0}), isNull);
      expect(state.extractAdCategoryId({'category_id': -10}), isNull);
      expect(state.extractAdCategoryId({'category': {'id': -2}}), isNull);
      expect(state.extractAdCategoryId({'category_name': 'سيارات'}), 1);
      expect(state.extractAdCategoryId({'category': {'id': 2}}), 2);
    });

    test('rankAdsForUser handles empty list, negative views, city & VIP boosts', () {
      final state = AppState();
      expect(state.rankAdsForUser([]), isEmpty);

      state.categoryInterestWeights = {1: 3};
      state.preferredCityId = 2;

      final ranked = state.rankAdsForUser([
        {'id': 1, 'category_id': 3, 'city_id': 9, 'views': -100},
        {'id': 2, 'category_id': 1, 'city_id': 2, 'is_vip': true, 'views': 250},
        'invalid-non-map',
      ]);

      expect(ranked.length, 2);
      expect(ranked.first['id'], 2);
    });

    test('adMatchesCategory handles null target and fallback asset match', () {
      final state = AppState();
      expect(state.adMatchesCategory({'id': 1}, null), isTrue);
      expect(state.adMatchesCategory({'category_id': 1}, 1), isTrue);
      expect(state.adMatchesCategory({'category_id': 2}, 1), isFalse);
      expect(
          state.adMatchesCategory({'category_name': 'voiture'}, 1), isTrue);
    });
  });

  group('Chat utils & AppTypography unit tests', () {
    test('parseChatDate and chatAdImage handle null, empty, and malformed inputs', () {
      expect(parseChatDate(null), isNull);
      expect(parseChatDate('invalid'), isNull);
      expect(parseChatDate('2026-11-14T10:30:00Z'), isNotNull);

      expect(chatAdImage(null), isNull);
      expect(chatAdImage({'main_image': '   '}), isNull);
      expect(chatAdImage({'thumbnail': 'https://apolo.ma/img.jpg'}),
          'https://apolo.ma/img.jpg');
    });

    test('formatChatClock, formatChatListTime, and formatChatDayLabel format accurately', () {
      final sAr = AppStrings('ar');
      final sFr = AppStrings('fr');
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final oldDate = DateTime(2024, 3, 5, 8, 4);

      expect(formatChatClock(DateTime(2026, 1, 1, 9, 5)), '09:05');
      expect(formatChatListTime(yesterday, sAr), 'أمس');
      expect(formatChatListTime(yesterday, sFr), 'Hier');
      expect(formatChatDayLabel(now, sAr), 'اليوم');
      expect(formatChatListTime(oldDate, sFr), '05/03/24');
    });

    test('AppTypography tracking and lineHeight handle null and non-Arabic locales', () {
      expect(AppTypography.isArabicLocale(null), isFalse);
      expect(AppTypography.tracking(null, -0.5), -0.5);
      expect(AppTypography.tracking(const Locale('ar'), -0.5), 0.0);
      expect(AppTypography.lineHeight(const Locale('ar'), 1.1, arabicMin: 1.45),
          1.45);
    });
  });
}
