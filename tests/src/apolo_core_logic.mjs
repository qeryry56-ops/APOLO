/**
 * Apolo.ma Core Domain Logic Module
 * Mirrors pure validation, normalization, price parsing, Smart Feed scoring,
 * filtering/sorting, category mapping, chat/notification formatting, and error mapping
 * used across the Apolo.ma platform.
 */

const ARABIC_DIGITS = '٠١٢٣٤٥٦٧٨٩';
const PERSIAN_DIGITS = '۰۱۲۳۴۵۶۷۸۹';

/**
 * Converts Arabic (٠-٩) and Persian (۰-۹) numerals to ASCII (0-9).
 * Handles null, undefined, and non-string inputs safely.
 */
export function normalizeDigits(value) {
  if (value === null || value === undefined) return '';
  const str = String(value);
  let out = '';
  for (const ch of str) {
    const arIdx = ARABIC_DIGITS.indexOf(ch);
    if (arIdx >= 0) {
      out += String(arIdx);
      continue;
    }
    const faIdx = PERSIAN_DIGITS.indexOf(ch);
    if (faIdx >= 0) {
      out += String(faIdx);
      continue;
    }
    out += ch;
  }
  return out;
}

/**
 * Validates email syntax, rejecting "..", trailing dot before "@",
 * whitespace, empty strings, and addresses > 254 characters.
 */
export function validateEmail(value) {
  if (typeof value !== 'string') return false;
  const text = value.trim();
  if (!text || text.length > 254 || text.includes('..')) return false;
  const emailRegex =
    /^[a-zA-Z0-9][a-zA-Z0-9._%+\-]*@[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?)+$/;
  if (!emailRegex.test(text)) return false;
  const localPart = text.split('@')[0];
  return !localPart.endsWith('.');
}

/**
 * Normalizes Moroccan phone numbers (05/06/07XXXXXXXX, 00212..., +212..., 212..., 6XXXXXXXX)
 * including Arabic/Persian digits and formatting characters, returning +212[5-7]XXXXXXXX or null.
 */
export function normalizeMoroccanPhone(value) {
  if (value === null || value === undefined) return null;
  const raw = normalizeDigits(value).trim();
  if (!raw || raw.startsWith('-')) return null;
  const normalized = raw.replace(/[\s().-]/g, '');

  if (/^0[5-7][0-9]{8}$/.test(normalized)) {
    return `+212${normalized.slice(1)}`;
  }
  if (/^00212[5-7][0-9]{8}$/.test(normalized)) {
    return `+${normalized.slice(2)}`;
  }
  if (/^\+212[5-7][0-9]{8}$/.test(normalized)) {
    return normalized;
  }
  if (/^212[5-7][0-9]{8}$/.test(normalized)) {
    return `+${normalized}`;
  }
  if (/^[5-7][0-9]{8}$/.test(normalized)) {
    return `+212${normalized}`;
  }
  return null;
}

/**
 * Validates password strength: at least 8 characters and not only whitespace.
 */
export function validatePassword(value) {
  if (typeof value !== 'string') return false;
  return value.length >= 8 && value.trim().length > 0;
}

/**
 * Validates 6-digit numeric OTP code (supporting Arabic/Persian digits).
 */
export function validateOtp(value) {
  if (value === null || value === undefined) return false;
  const normalized = normalizeDigits(value).trim();
  return /^[0-9]{6}$/.test(normalized);
}

/**
 * Masks an email address for safe display on OTP screens (e.g., am***@gmail.com).
 */
export function maskEmail(raw) {
  if (typeof raw !== 'string') return null;
  const text = raw.trim();
  const at = text.indexOf('@');
  if (at <= 0 || at >= text.length - 1) return null;
  const local = text.slice(0, at);
  const domain = text.slice(at);
  if (local.length <= 2) return `${local[0]}***${domain}`;
  return `${local.slice(0, 2)}***${domain}`;
}

/**
 * Parses an ad price from string/number, normalizing Arabic/Persian digits,
 * stripping spaces and commas. Rejects <= 0, NaN, Infinity, non-numeric, and empty
 * unless isFree === true (which returns 0).
 */
export function parseAdPrice(rawPrice, { isFree = false } = {}) {
  if (isFree) return 0;
  if (rawPrice === null || rawPrice === undefined) return null;
  if (typeof rawPrice === 'number') {
    return Number.isFinite(rawPrice) && rawPrice > 0 ? rawPrice : null;
  }
  const raw = normalizeDigits(String(rawPrice))
    .replace(/[\s\u00A0]/g, '')
    .replace(/٫/g, '.')
    .replace(/,/g, '.');
  if (!raw || !/^[+-]?(?:\d+\.?\d*|\.\d+)$/.test(raw)) return null;
  const value = Number(raw);
  return Number.isFinite(value) && value > 0 ? value : null;
}

function toPositiveInt(val) {
  if (val === null || val === undefined || val === '') return null;
  const num = Number(val);
  if (!Number.isInteger(num) || num <= 0) return null;
  return num;
}

/**
 * Extracts normalized positive integer category ID from an ad object.
 */
export function extractAdCategoryId(ad, categories = []) {
  if (!ad || typeof ad !== 'object') return null;

  const direct = toPositiveInt(ad.category_id);
  if (direct !== null) return direct;

  if (ad.category && typeof ad.category === 'object') {
    const nested = toPositiveInt(ad.category.id);
    if (nested !== null) return nested;
  }

  const rawName =
    ad.category_name ??
    (ad.category && typeof ad.category === 'object'
      ? (ad.category.name ?? ad.category.name_ar ?? ad.category.name_fr)
      : ad.category) ??
    '';
  const catName = String(rawName).toLowerCase().trim();
  if (catName && Array.isArray(categories)) {
    for (const c of categories) {
      if (!c || typeof c !== 'object') continue;
      const id = toPositiveInt(c.id);
      if (id === null) continue;
      const ar = String(c.name_ar ?? '').toLowerCase();
      const fr = String(c.name_fr ?? '').toLowerCase();
      const nm = String(c.name ?? '').toLowerCase();
      if (
        catName === ar ||
        catName === fr ||
        catName === nm ||
        (ar && catName.includes(ar)) ||
        (fr && catName.includes(fr))
      ) {
        return id;
      }
    }
  }
  return null;
}

/**
 * Computes the 2026 Smart Feed relevance score for an ad.
 */
export function calculateAdScore(
  ad,
  { categoryInterestWeights = {}, preferredCityId = null } = {}
) {
  if (!ad || typeof ad !== 'object') return 0;
  let score = 0;

  const catId = extractAdCategoryId(ad);
  if (catId !== null && categoryInterestWeights) {
    const rawWeight = Number(categoryInterestWeights[catId] ?? categoryInterestWeights[String(catId)] ?? 0);
    if (Number.isFinite(rawWeight) && rawWeight > 0) {
      score += Math.trunc(rawWeight) * 15;
    }
  }

  const cityRaw = ad.city_id ?? (ad.city && typeof ad.city === 'object' ? ad.city.id : null);
  const adCityId = toPositiveInt(cityRaw);
  if (preferredCityId !== null && preferredCityId !== undefined && adCityId === Number(preferredCityId)) {
    score += 25;
  }

  if (ad.is_vip === true || ad.is_featured === true) {
    score += 18;
  }

  const rawViews = Number(ad.views ?? ad.views_count ?? 0);
  const views = Number.isFinite(rawViews) && rawViews > 0 ? Math.trunc(rawViews) : 0;
  score += views > 100 ? 10 : Math.floor(views / 10);

  return score;
}

/**
 * Ranks ads descending by Smart Feed score.
 */
export function rankAdsForUser(rawAds, prefs = {}) {
  if (!Array.isArray(rawAds)) return [];
  const list = rawAds
    .filter((item) => item && typeof item === 'object' && !Array.isArray(item))
    .map((item) => ({ ...item }));
  if (list.length <= 1) return list;
  return list.sort((a, b) => calculateAdScore(b, prefs) - calculateAdScore(a, prefs));
}

/**
 * Filters and sorts ads based on search criteria and sort mode.
 */
export function filterAndSortAds(
  rawAds,
  {
    categoryId = null,
    cityId = null,
    minPrice = null,
    maxPrice = null,
    onlyNegotiable = false,
    query = '',
    sortBy = 'smart',
    categories = [],
  } = {},
  prefs = {}
) {
  if (!Array.isArray(rawAds)) return [];
  const q = typeof query === 'string' ? query.trim().toLowerCase() : '';

  const filtered = rawAds
    .filter((item) => item && typeof item === 'object' && !Array.isArray(item))
    .map((item) => ({ ...item }))
    .filter((ad) => {
      if (categoryId !== null && categoryId !== undefined) {
        const adCatId = extractAdCategoryId(ad, categories);
        if (adCatId !== Number(categoryId)) return false;
      }
      if (cityId !== null && cityId !== undefined) {
        const adCityRaw = ad.city_id ?? (ad.city && typeof ad.city === 'object' ? ad.city.id : null);
        if (toPositiveInt(adCityRaw) !== Number(cityId)) return false;
      }
      const priceVal = Number(ad.price ?? 0);
      const safePrice = Number.isFinite(priceVal) ? priceVal : 0;
      if (minPrice !== null && minPrice !== undefined && safePrice < Number(minPrice)) {
        return false;
      }
      if (maxPrice !== null && maxPrice !== undefined && safePrice > Number(maxPrice)) {
        return false;
      }
      if (onlyNegotiable) {
        const neg = ad.negotiable === true || ad.is_negotiable === true;
        if (!neg) return false;
      }
      if (q) {
        const title = String(ad.title ?? '').toLowerCase();
        const desc = String(ad.description ?? '').toLowerCase();
        if (!title.includes(q) && !desc.includes(q)) return false;
      }
      return true;
    });

  switch (sortBy) {
    case 'price_asc':
      return filtered.sort((a, b) => (Number(a.price ?? 0) || 0) - (Number(b.price ?? 0) || 0));
    case 'popular':
      return filtered.sort((a, b) => {
        const va = Number(a.views_count ?? a.views ?? 0) || 0;
        const vb = Number(b.views_count ?? b.views ?? 0) || 0;
        return vb - va;
      });
    case 'newest':
      return filtered.sort((a, b) => (Number(b.id ?? 0) || 0) - (Number(a.id ?? 0) || 0));
    case 'smart':
    default:
      return rankAdsForUser(filtered, prefs);
  }
}

/**
 * Formats a clean, balanced category label in 'ar', 'fr', or 'en'.
 */
export function formatCategoryLabel(cat, lang = 'ar') {
  if (!cat || typeof cat !== 'object') return '';
  const isAr = lang === 'ar';
  const isEn = lang === 'en';
  const raw = String(
    isAr
      ? (cat.name_ar ?? cat.name ?? '')
      : isEn
        ? (cat.name_en ?? cat.name ?? cat.name_fr ?? '')
        : (cat.name_fr ?? cat.name ?? '')
  ).trim();

  const combined = `${raw.toLowerCase()} ${String(cat.slug ?? '').toLowerCase()} ${String(cat.name_fr ?? '').toLowerCase()} ${String(cat.name_ar ?? '').toLowerCase()}`;

  if (
    combined.includes('voiture') ||
    combined.includes('vehicule') ||
    combined.includes('véhicule') ||
    combined.includes('auto') ||
    combined.includes('نقل') ||
    combined.includes('سيار')
  ) {
    return isAr ? 'وسائل النقل' : isEn ? 'Vehicles' : 'Véhicules';
  }
  if (combined.includes('immo') || combined.includes('عقار')) {
    return isAr ? 'عقارات' : isEn ? 'Real Estate' : 'Immobilier';
  }
  if (combined.includes('télé') || combined.includes('phone') || combined.includes('هواتف')) {
    return isAr ? 'هواتف وتقنية' : isEn ? 'Phones' : 'Téléphones';
  }
  if (
    combined.includes('info') ||
    combined.includes('multimedia') ||
    combined.includes('معلوماتية') ||
    combined.includes('حواسيب')
  ) {
    return isAr ? 'إعلاميات وتقنية' : isEn ? 'Computers' : 'Informatique';
  }
  if (
    combined.includes('habillement') ||
    combined.includes('mode') ||
    combined.includes('ملابس') ||
    combined.includes('أزياء')
  ) {
    return isAr ? 'أزياء وجمال' : isEn ? 'Fashion & Beauty' : 'Mode & Beauté';
  }
  if (combined.includes('voyage') || combined.includes('سفر')) {
    return isAr ? 'أدوات السفر' : isEn ? 'Travel' : 'Voyage';
  }
  if (combined.includes('parapharmacie') || combined.includes('بارافارماسي')) {
    return isAr ? 'بارافارماسي' : isEn ? 'Parapharmacy' : 'Parapharmacie';
  }
  if (combined.includes('enfant') || combined.includes('اطفال') || combined.includes('أطفال')) {
    return isAr ? 'الأطفال' : isEn ? 'Kids & Baby' : 'Enfants';
  }
  if (combined.includes('bricolage') || combined.includes('بريكولاج')) {
    return isAr ? 'بريكولاج' : isEn ? 'DIY & Tools' : 'Bricolage';
  }
  if (
    combined.includes('industriel') ||
    combined.includes('machine') ||
    combined.includes('صناعية') ||
    combined.includes('ألات') ||
    combined.includes('آلات')
  ) {
    return isAr ? 'آلات صناعية' : isEn ? 'Industrial & Pro' : 'Industrie & Pro';
  }
  if (combined.includes('bijou') || combined.includes('مجوهرات')) {
    return isAr ? 'المجوهرات' : isEn ? 'Jewelry' : 'Bijoux';
  }
  if (combined.includes('antique') || combined.includes('عتيقة')) {
    return isAr ? 'تحف وأنتيك' : isEn ? 'Antiques' : 'Antiquités';
  }
  if (combined.includes('maison') || combined.includes('meuble') || combined.includes('أثاث')) {
    return isAr ? 'أثاث وديكور' : isEn ? 'Home & Furniture' : 'Maison & Déco';
  }
  if (combined.includes('emploi') || combined.includes('service') || combined.includes('وظائف')) {
    return isAr ? 'وظائف وخدمات' : isEn ? 'Jobs & Services' : 'Emploi & Pro';
  }
  if (combined.includes('autre') || combined.includes('آخر')) {
    return isAr ? 'أقسام أخرى' : isEn ? 'Other' : 'Autres';
  }
  return raw;
}

/**
 * Centralized 3D cutout asset path resolver for categories.
 */
export function assetForCategory(cat, fallbackName = '') {
  if (cat && typeof cat.asset === 'string' && cat.asset.length > 0) {
    return cat.asset;
  }
  const combined = `${String(fallbackName).toLowerCase()} ${String(cat?.name_ar ?? '').toLowerCase()} ${String(cat?.name_fr ?? '').toLowerCase()} ${String(cat?.name ?? '').toLowerCase()} ${String(cat?.slug ?? '').toLowerCase()}`;

  if (
    combined.includes('voiture') ||
    combined.includes('auto') ||
    combined.includes('moto') ||
    combined.includes('vehicule') ||
    combined.includes('véhicule') ||
    combined.includes('نقل') ||
    combined.includes('سيار') ||
    combined.includes('مركبات')
  ) {
    return 'assets/images/cat_vehicles.png';
  }
  if (
    combined.includes('immo') ||
    combined.includes('appart') ||
    combined.includes('villa') ||
    combined.includes('عقار') ||
    combined.includes('شقق')
  ) {
    return 'assets/images/cat_realestate.png';
  }
  if (combined.includes('voyage') || combined.includes('سفر')) {
    return 'assets/images/cat_travel.png';
  }
  if (combined.includes('parapharmacie') || combined.includes('بارافارماسي')) {
    return 'assets/images/cat_parapharmacy.png';
  }
  if (combined.includes('enfant') || combined.includes('اطفال') || combined.includes('أطفال')) {
    return 'assets/images/cat_kids.png';
  }
  if (combined.includes('bricolage') || combined.includes('بريكولاج')) {
    return 'assets/images/cat_bricolage.png';
  }
  if (
    combined.includes('industriel') ||
    combined.includes('machine') ||
    combined.includes('صناعية') ||
    combined.includes('ألات') ||
    combined.includes('آلات')
  ) {
    return 'assets/images/cat_industrial.png';
  }
  if (combined.includes('bijou') || combined.includes('مجوهرات')) {
    return 'assets/images/cat_jewelry.png';
  }
  if (combined.includes('antique') || combined.includes('عتيقة')) {
    return 'assets/images/cat_antique.png';
  }
  if (combined.includes('autre') || combined.includes('آخر')) {
    return 'assets/images/cat_other.png';
  }
  if (combined.includes('télé') || combined.includes('phone') || combined.includes('هواتف')) {
    return 'assets/images/cat_phones.png';
  }
  if (
    combined.includes('info') ||
    combined.includes('multimedia') ||
    combined.includes('pc') ||
    combined.includes('معلوماتية') ||
    combined.includes('وسائط') ||
    combined.includes('حواسيب') ||
    combined.includes('إلكترون')
  ) {
    return 'assets/images/cat_computers.png';
  }
  if (
    combined.includes('maison') ||
    combined.includes('meuble') ||
    combined.includes('أثاث') ||
    combined.includes('منزل')
  ) {
    return 'assets/images/cat_home.png';
  }
  if (
    combined.includes('mode') ||
    combined.includes('habillement') ||
    combined.includes('vêt') ||
    combined.includes('أزياء') ||
    combined.includes('ملابس')
  ) {
    return 'assets/images/cat_fashion.png';
  }
  if (
    combined.includes('emploi') ||
    combined.includes('service') ||
    combined.includes('وظائف') ||
    combined.includes('خدمات')
  ) {
    return 'assets/images/cat_jobs.png';
  }
  return 'assets/images/cat_other.png';
}

function twoDigits(n) {
  return String(n).padStart(2, '0');
}

function isSameDay(a, b) {
  return (
    a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate()
  );
}

const WEEKDAYS = {
  ar: ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'],
  fr: ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'],
  en: ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
};

/**
 * Formats chat list timestamp: "HH:mm" today, "أمس"/"Hier"/"Yesterday",
 * weekday within 7 days, else dd/MM/yy.
 */
export function formatChatTime(dateInput, nowInput = new Date(), lang = 'ar') {
  const t = dateInput instanceof Date ? dateInput : new Date(dateInput);
  const now = nowInput instanceof Date ? nowInput : new Date(nowInput);
  if (Number.isNaN(t.getTime()) || Number.isNaN(now.getTime())) return '';

  if (isSameDay(t, now)) {
    return `${twoDigits(t.getHours())}:${twoDigits(t.getMinutes())}`;
  }
  const yesterday = new Date(now.getTime());
  yesterday.setDate(now.getDate() - 1);
  if (isSameDay(t, yesterday)) {
    return lang === 'ar' ? 'أمس' : lang === 'en' ? 'Yesterday' : 'Hier';
  }
  const diffDays = Math.floor((now.getTime() - t.getTime()) / (24 * 60 * 60 * 1000));
  if (diffDays >= 0 && diffDays < 7) {
    const table = WEEKDAYS[lang] ?? WEEKDAYS.fr;
    return table[t.getDay()];
  }
  return `${twoDigits(t.getDate())}/${twoDigits(t.getMonth() + 1)}/${twoDigits(t.getFullYear() % 100)}`;
}

/**
 * Normalizes a notification payload into UI-ready shape.
 * category: 1 = Messages & Offers, 2 = Activity
 */
export function normalizeNotification(raw) {
  if (!raw || typeof raw !== 'object') {
    return {
      id: 0,
      category: 2,
      unread: false,
      title: 'إشعار جديد',
      body: '',
      time: 'منذ قليل',
      ad_id: null,
      conversation_id: null,
    };
  }
  const type = String(raw.type ?? raw.category ?? '').toLowerCase();
  const isMessageOrOffer =
    type.includes('chat') ||
    type.includes('message') ||
    type.includes('offer') ||
    type.includes('رسال') ||
    type.includes('عرض');

  const data = raw.data && typeof raw.data === 'object' ? raw.data : {};
  return {
    id: raw.id ?? 0,
    category: isMessageOrOffer ? 1 : 2,
    unread: raw.is_read !== true && raw.read_at == null,
    title: String(raw.title ?? data.title ?? 'إشعار جديد'),
    body: String(raw.body ?? raw.message ?? data.message ?? ''),
    time: String(raw.created_at_human ?? raw.time ?? 'منذ قليل'),
    ad_id: raw.ad_id ?? data.ad_id ?? null,
    conversation_id: raw.conversation_id ?? data.conversation_id ?? null,
  };
}

/**
 * Maps domain failures and HTTP errors to localized Arabic or French messages.
 */
export function mapAccountError(error, isAr = true) {
  if (!error) {
    return isAr
      ? 'لم يتم تأكيد العملية. أعد المحاولة أو استخدم الموقع.'
      : 'L’opération n’a pas été confirmée. Réessayez ou utilisez le site.';
  }

  if (error.kind) {
    const msg = typeof error.message === 'string' ? error.message.trim() : '';
    if (msg) return msg;
    if (error.kind === 'verification') {
      return isAr
        ? 'رمز التحقق غير صحيح أو انتهت صلاحيته.'
        : 'Code de vérification invalide ou expiré.';
    }
  }

  const status = error.status ?? error.response?.status;
  const serverMsg = error.response?.data?.message?.toString?.().trim?.() ?? '';

  if (status === 429) {
    return isAr
      ? 'محاولات كثيرة. انتظر قليلاً ثم أعد المحاولة.'
      : 'Trop de tentatives. Patientez avant de réessayer.';
  }
  if (status === 401 || status === 403) {
    return isAr
      ? 'تعذر تأكيد بيانات الدخول أو رمز التحقق.'
      : 'Identifiants ou code de vérification refusés.';
  }
  if (status === 422) {
    if (serverMsg) return serverMsg;
    return isAr
      ? 'تحقق من البيانات المدخلة. قد يكون البريد مستخدماً بالفعل.'
      : 'Vérifiez les informations. Cette adresse est peut-être déjà utilisée.';
  }
  if (
    error.type === 'connectionError' ||
    error.type === 'connectionTimeout' ||
    error.type === 'receiveTimeout'
  ) {
    return isAr
      ? 'تعذر الاتصال. تحقق من الإنترنت وأعد المحاولة.'
      : 'Connexion impossible. Vérifiez Internet et réessayez.';
  }

  return isAr
    ? 'لم يتم تأكيد العملية. أعد المحاولة أو استخدم الموقع.'
    : 'L’opération n’a pas été confirmée. Réessayez ou utilisez le site.';
}
