import { describe, it, expect } from 'vitest';
import {
  normalizeDigits,
  validateEmail,
  normalizeMoroccanPhone,
  validatePassword,
  validateOtp,
  maskEmail,
  parseAdPrice,
  extractAdCategoryId,
  calculateAdScore,
  rankAdsForUser,
  filterAndSortAds,
  formatCategoryLabel,
  assetForCategory,
  formatChatTime,
  normalizeNotification,
  mapAccountError,
} from '../src/apolo_core_logic.mjs';

describe('1. Digit Normalization & Input Validation', () => {
  it('normalizes Arabic and Persian digits while preserving non-digit chars', () => {
    expect(normalizeDigits('٠١٢٣٤٥٦٧٨٩')).toBe('0123456789');
    expect(normalizeDigits('۰۱۲۳۴۵۶۷۸۹')).toBe('0123456789');
    expect(normalizeDigits('٠٦-١٢-٣٤-٥٦-٧٨')).toBe('06-12-34-56-78');
  });

  it('handles empty, null, undefined, and non-string inputs in normalizeDigits', () => {
    expect(normalizeDigits('')).toBe('');
    expect(normalizeDigits(null)).toBe('');
    expect(normalizeDigits(undefined)).toBe('');
    expect(normalizeDigits(-42)).toBe('-42');
    expect(normalizeDigits(0)).toBe('0');
  });

  it('validates legitimate emails including plus tags and trimmed whitespace', () => {
    expect(validateEmail('amine@apolo.ma')).toBe(true);
    expect(validateEmail(' user+ads@sub.apolo.ma ')).toBe(true);
    expect(validateEmail('a1.b2_c3@domain.co.uk')).toBe(true);
  });

  it('rejects empty, malformed, oversized, and injection-style emails', () => {
    const invalidEmails = [
      '',
      '   ',
      null,
      undefined,
      12345,
      'plainaddress',
      'a@',
      '@apolo.ma',
      'a @b.ma',
      'a..b@example.ma',
      'a.@example.ma',
      'a@-host.ma',
      'a@host',
      'a\n@host.ma',
      `${'a'.repeat(246)}@apolo.ma`, // > 254 chars
      "<script>alert(1)</script>@test.ma",
    ];
    for (const email of invalidEmails) {
      expect(validateEmail(email), `Expected false for ${String(email)}`).toBe(false);
    }
  });

  it('normalizes valid Moroccan phone numbers across all accepted formats', () => {
    expect(normalizeMoroccanPhone('0612345678')).toBe('+212612345678');
    expect(normalizeMoroccanPhone('0712345678')).toBe('+212712345678');
    expect(normalizeMoroccanPhone('0522123456')).toBe('+212522123456');
    expect(normalizeMoroccanPhone('00212612345678')).toBe('+212612345678');
    expect(normalizeMoroccanPhone('+212 6 12-34.56(78)')).toBe('+212612345678');
    expect(normalizeMoroccanPhone('212712345678')).toBe('+212712345678');
    expect(normalizeMoroccanPhone('612345678')).toBe('+212612345678');
    expect(normalizeMoroccanPhone('٠٦ ١٢ ٣٤ ٥٦ ٧٨')).toBe('+212612345678');
    expect(normalizeMoroccanPhone('۰۷۱۲۳۴۵۶۷۸')).toBe('+212712345678');
  });

  it('rejects invalid, negative, foreign, or empty phone numbers', () => {
    const invalidPhones = [
      '',
      '   ',
      null,
      undefined,
      '-0612345678',
      '-212612345678',
      '0812345678',
      '0912345678',
      '0412345678',
      '061234',
      '061234567890',
      '+33612345678',
      '+2120612345678',
      'abcdefghij',
    ];
    for (const phone of invalidPhones) {
      expect(normalizeMoroccanPhone(phone), `Expected null for ${String(phone)}`).toBeNull();
    }
  });

  it('validates passwords and rejects empty/whitespace/short inputs', () => {
    expect(validatePassword('Secret123!')).toBe(true);
    expect(validatePassword('12345678')).toBe(true);
    expect(validatePassword('')).toBe(false);
    expect(validatePassword('        ')).toBe(false);
    expect(validatePassword('1234567')).toBe(false);
    expect(validatePassword(null)).toBe(false);
  });

  it('validates 6-digit OTPs including Arabic/Persian numerals and rejects edge cases', () => {
    expect(validateOtp('123456')).toBe(true);
    expect(validateOtp(' ١٢٣٤٥٦ ')).toBe(true);
    expect(validateOtp('۱۲۳۴۵۶')).toBe(true);
    expect(validateOtp('')).toBe(false);
    expect(validateOtp('12345')).toBe(false);
    expect(validateOtp('1234567')).toBe(false);
    expect(validateOtp('-12345')).toBe(false);
    expect(validateOtp('123abc')).toBe(false);
    expect(validateOtp(null)).toBe(false);
  });

  it('masks emails safely and returns null for malformed inputs', () => {
    expect(maskEmail('amine@gmail.com')).toBe('am***@gmail.com');
    expect(maskEmail('ab@apolo.ma')).toBe('a***@apolo.ma');
    expect(maskEmail('a@b.ma')).toBe('a***@b.ma');
    expect(maskEmail('')).toBeNull();
    expect(maskEmail('invalid')).toBeNull();
    expect(maskEmail('@apolo.ma')).toBeNull();
    expect(maskEmail('user@')).toBeNull();
    expect(maskEmail(null)).toBeNull();
  });
});

describe('2. Price Parsing & Financial Calculations', () => {
  it('parses valid prices with spaces, commas, decimals, and Arabic digits', () => {
    expect(parseAdPrice('150000')).toBe(150000);
    expect(parseAdPrice('150 000')).toBe(150000);
    expect(parseAdPrice('1 250,50')).toBe(1250.5);
    expect(parseAdPrice('١٢٥٠٠')).toBe(12500);
    expect(parseAdPrice('۱۲۵۰۰٫۷۵')).toBe(12500.75);
    expect(parseAdPrice(99.9)).toBe(99.9);
  });

  it('returns 0 when isFree is true regardless of text', () => {
    expect(parseAdPrice('', { isFree: true })).toBe(0);
    expect(parseAdPrice('-500', { isFree: true })).toBe(0);
  });

  it('rejects zero, negative prices, empty strings, NaN, Infinity, and garbage text', () => {
    const invalidPrices = ['', '   ', null, undefined, 0, '0', -1, '-150', '-0.01', NaN, Infinity, -Infinity, '12abc', '100 DH'];
    for (const p of invalidPrices) {
      expect(parseAdPrice(p), `Expected null for ${String(p)}`).toBeNull();
    }
  });
});

describe('3. Smart Feed Ranking, Category Extraction & Search Filtering', () => {
  const categories = [
    { id: 1, name_ar: 'سيارات', name_fr: 'Voitures', slug: 'auto' },
    { id: 2, name_ar: 'عقارات', name_fr: 'Immobilier', slug: 'immo' },
    { id: 3, name_ar: 'هواتف', name_fr: 'Téléphones', slug: 'phones' },
  ];

  it('extracts category ID from direct field, nested object, or localized name', () => {
    expect(extractAdCategoryId({ category_id: 2 }, categories)).toBe(2);
    expect(extractAdCategoryId({ category_id: '3' }, categories)).toBe(3);
    expect(extractAdCategoryId({ category: { id: 1 } }, categories)).toBe(1);
    expect(extractAdCategoryId({ category_name: 'Immobilier' }, categories)).toBe(2);
    expect(extractAdCategoryId({ category_name: 'سيارات فاخرة' }, categories)).toBe(1);
  });

  it('returns null for negative, zero, empty, or malformed category values', () => {
    expect(extractAdCategoryId(null, categories)).toBeNull();
    expect(extractAdCategoryId({}, categories)).toBeNull();
    expect(extractAdCategoryId({ category_id: 0 }, categories)).toBeNull();
    expect(extractAdCategoryId({ category_id: -5 }, categories)).toBeNull();
    expect(extractAdCategoryId({ category: { id: -1 } }, categories)).toBeNull();
    expect(extractAdCategoryId({ category_name: '   ' }, categories)).toBeNull();
  });

  it('calculates Smart Feed score accurately and guards against negative views/weights', () => {
    const ad = { id: 1, category_id: 1, city_id: 2, is_vip: true, views: 55 };
    const score = calculateAdScore(ad, {
      categoryInterestWeights: { 1: 4 },
      preferredCityId: 2,
    });
    // 4*15 (60) + city (25) + vip (18) + floor(55/10) (5) = 108
    expect(score).toBe(108);

    // Caps views bonus at 10 when views > 100
    expect(calculateAdScore({ views: 9999 })).toBe(10);

    // Clamps negative views & negative weights to 0
    expect(
      calculateAdScore(
        { category_id: 1, views: -500 },
        { categoryInterestWeights: { 1: -10 } }
      )
    ).toBe(0);
    expect(calculateAdScore(null)).toBe(0);
  });

  it('ranks ads by preference and handles empty/non-array lists safely', () => {
    expect(rankAdsForUser([])).toEqual([]);
    expect(rankAdsForUser(null)).toEqual([]);
    const ads = [
      { id: 10, category_id: 2, city_id: 1, views: 5 },
      { id: 20, category_id: 1, city_id: 3, is_vip: true, views: 30 },
      'invalid-entry',
      null,
    ];
    const ranked = rankAdsForUser(ads, {
      categoryInterestWeights: { 1: 5 },
      preferredCityId: 3,
    });
    expect(ranked).toHaveLength(2);
    expect(ranked[0].id).toBe(20);
    expect(ranked[1].id).toBe(10);
  });

  it('filters ads by category, city, price range, negotiable flag, and query', () => {
    const ads = [
      { id: 1, title: 'Mercedes C220', description: 'Diesel clean', price: 180000, category_id: 1, city_id: 1, negotiable: true, views: 120 },
      { id: 2, title: 'Dacia Logan', description: 'Economique', price: 75000, category_id: 1, city_id: 2, negotiable: false, views: 40 },
      { id: 3, title: 'iPhone 16 Pro', description: '256GB neuf', price: 12000, category_id: 3, city_id: 1, negotiable: true, views: 200 },
    ];

    expect(filterAndSortAds(ads, { categoryId: 1, cityId: 1 })).toHaveLength(1);
    expect(filterAndSortAds(ads, { minPrice: 10000, maxPrice: 80000 })).toHaveLength(2);
    expect(filterAndSortAds(ads, { onlyNegotiable: true, sortBy: 'price_asc' }).map((a) => a.id)).toEqual([3, 1]);
    expect(filterAndSortAds(ads, { query: 'dacia' }).map((a) => a.id)).toEqual([2]);
    expect(filterAndSortAds(ads, { sortBy: 'popular' }).map((a) => a.id)).toEqual([3, 1, 2]);
    expect(filterAndSortAds(ads, { sortBy: 'newest' }).map((a) => a.id)).toEqual([3, 2, 1]);
    expect(filterAndSortAds(ads, { query: 'nonexistent' })).toEqual([]);
  });
});

describe('4. Category Localization & Asset Mapping', () => {
  it('formats category labels cleanly in Arabic, French, and English', () => {
    const car = { name_ar: 'سيارات ومركبات', name_fr: 'Voitures', slug: 'auto' };
    expect(formatCategoryLabel(car, 'ar')).toBe('وسائل النقل');
    expect(formatCategoryLabel(car, 'fr')).toBe('Véhicules');
    expect(formatCategoryLabel(car, 'en')).toBe('Vehicles');

    const jobs = { slug: 'emploi' };
    expect(formatCategoryLabel(jobs, 'ar')).toBe('وظائف وخدمات');
    expect(formatCategoryLabel(jobs, 'en')).toBe('Jobs & Services');
  });

  it('handles null or unknown categories gracefully', () => {
    expect(formatCategoryLabel(null, 'ar')).toBe('');
    expect(formatCategoryLabel({ name_ar: 'قسم مخصص' }, 'ar')).toBe('قسم مخصص');
    expect(assetForCategory(null)).toBe('assets/images/cat_other.png');
    expect(assetForCategory({ asset: 'assets/images/custom.png' })).toBe('assets/images/custom.png');
    expect(assetForCategory({ slug: 'immobilier' })).toBe('assets/images/cat_realestate.png');
  });
});

describe('5. Chat Timestamps, Notifications & Error Mapping', () => {
  it('formats chat timestamps for today, yesterday, weekday, and older dates', () => {
    const now = new Date(2026, 10, 14, 15, 30); // Saturday Nov 14, 2026
    expect(formatChatTime(new Date(2026, 10, 14, 9, 5), now, 'ar')).toBe('09:05');
    expect(formatChatTime(new Date(2026, 10, 13, 12, 0), now, 'ar')).toBe('أمس');
    expect(formatChatTime(new Date(2026, 10, 13, 12, 0), now, 'fr')).toBe('Hier');
    expect(formatChatTime(new Date(2026, 10, 12, 12, 0), now, 'en')).toBe('Thursday');
    expect(formatChatTime(new Date(2026, 0, 5, 12, 0), now, 'fr')).toBe('05/01/26');
    expect(formatChatTime('invalid-date', now, 'ar')).toBe('');
  });

  it('normalizes notifications and handles missing/malformed data', () => {
    const chatNotif = normalizeNotification({
      id: 5,
      type: 'chat_message',
      title: 'رسالة جديدة',
      body: 'بكم السعر؟',
      conversation_id: 42,
      is_read: false,
    });
    expect(chatNotif.category).toBe(1);
    expect(chatNotif.unread).toBe(true);
    expect(chatNotif.conversation_id).toBe(42);

    const readActivity = normalizeNotification({
      id: 6,
      type: 'ad_approved',
      read_at: '2026-11-14T10:00:00Z',
    });
    expect(readActivity.category).toBe(2);
    expect(readActivity.unread).toBe(false);

    const emptyNotif = normalizeNotification(null);
    expect(emptyNotif.id).toBe(0);
    expect(emptyNotif.title).toBe('إشعار جديد');
  });

  it('maps HTTP status codes, network errors, and domain failures in Arabic & French', () => {
    expect(mapAccountError({ kind: 'verification' }, true)).toContain('رمز التحقق');
    expect(mapAccountError({ kind: 'rejected', message: 'Custom error' }, true)).toBe('Custom error');
    expect(mapAccountError({ status: 429 }, false)).toContain('Trop de tentatives');
    expect(mapAccountError({ status: 401 }, true)).toContain('تعذر تأكيد بيانات الدخول');
    expect(mapAccountError({ status: 422, response: { data: { message: 'البريد مستخدم' } } }, true)).toBe('البريد مستخدم');
    expect(mapAccountError({ type: 'connectionTimeout' }, true)).toContain('تعذر الاتصال');
    expect(mapAccountError(null, false)).toContain('pas été confirmée');
  });
});
