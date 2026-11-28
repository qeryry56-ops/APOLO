import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';

/// Display-only translation result for a marketplace listing's title and description.
/// Never persisted to Firestore or the backend database.
class ListingTranslationResult {
  final String title;
  final String description;
  final String sourceLang;
  final String targetLang;

  const ListingTranslationResult({
    required this.title,
    required this.description,
    required this.sourceLang,
    required this.targetLang,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'description': description,
        'sourceLang': sourceLang,
        'targetLang': targetLang,
      };

  factory ListingTranslationResult.fromJson(Map<String, dynamic> json) {
    return ListingTranslationResult(
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      sourceLang: (json['sourceLang'] ?? 'en').toString(),
      targetLang: (json['targetLang'] ?? 'en').toString(),
    );
  }
}

/// Clean AI translation entry point for marketplace listings (title + description only).
/// Uses [ListingTranslationService] for local caching so repeated views do not re-translate.
Future<ListingTranslationResult> translateListing(
  String title,
  String description,
  String targetLang, {
  String? sourceLangOverride,
}) {
  return ListingTranslationService.instance.translateListing(
    title,
    description,
    targetLang,
    sourceLangOverride: sourceLangOverride,
  );
}

/// Handles on-demand, display-only translation of user listings with local caching.
class ListingTranslationService {
  ListingTranslationService._();

  static final ListingTranslationService instance =
      ListingTranslationService._();

  static const String _prefsKeyPrefix = 'apolo_listing_translation_v1_';
  final Map<String, ListingTranslationResult> _memoryCache =
      <String, ListingTranslationResult>{};

  /// Clears the in-memory translation cache (primarily for tests).
  @visibleForTesting
  void clearMemoryCache() => _memoryCache.clear();

  /// Normalizes a locale/language tag (e.g. `'fr_FR'` -> `'fr'`).
  static String normalizeLang(String lang) {
    final lower = lang.trim().toLowerCase();
    if (lower.isEmpty) return 'en';
    final sep = lower.indexOf(RegExp(r'[-_]'));
    return sep > 0 ? lower.substring(0, sep) : lower;
  }

  /// Detects the primary language of a listing from explicit metadata or text heuristics.
  static String detectListingLanguage(
    String title,
    String description, {
    Map<String, dynamic>? ad,
  }) {
    final explicit = (ad?['language'] ??
            ad?['lang'] ??
            ad?['source_lang'] ??
            ad?['locale'] ??
            '')
        .toString()
        .trim();
    if (explicit.isNotEmpty) {
      return normalizeLang(explicit);
    }

    final combined = '${title.trim()} ${description.trim()}'.trim();
    if (combined.isEmpty) return 'en';

    if (RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]').hasMatch(combined)) {
      return 'ar';
    }
    if (RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF]').hasMatch(combined)) {
      return 'ja';
    }

    final lower = combined.toLowerCase();

    if (RegExp(r'[äöüß]').hasMatch(lower) ||
        RegExp(
          r'\b(und|mit|für|neu|zustand|verkauf|preis|sehr|wie|abholung|versand|zimmer|verhandelbar|originalverpackung)\b',
        ).hasMatch(lower)) {
      return 'de';
    }

    final frScore = RegExp(r'[àâçèêëîïôùûüœæ]').allMatches(lower).length * 2 +
        RegExp(
          r'\b(avec|pour|très|état|neuf|vendre|chambre|chambres|livraison|prix|boîte|remise|villa|appartement|disponible)\b',
        ).allMatches(lower).length;
    final esScore = RegExp(r'[ñíóú¿¡]').allMatches(lower).length * 2 +
        RegExp(
          r'\b(venta|estado|nuevo|precio|habitaciones|entrega|para|con|muy|envío|negociable)\b',
        ).allMatches(lower).length;

    if (esScore > frScore && esScore > 0) {
      return 'es';
    }
    if (frScore > 0) {
      return 'fr';
    }

    return 'en';
  }

  /// Returns `true` only when the listing has translatable text and its detected
  /// language differs from the user's current app language.
  static bool shouldOfferTranslation({
    required String title,
    required String description,
    required String appLang,
    Map<String, dynamic>? ad,
  }) {
    if (title.trim().isEmpty && description.trim().isEmpty) return false;
    final listingLang = detectListingLanguage(title, description, ad: ad);
    return listingLang != normalizeLang(appLang);
  }

  /// Returns a localized display name for [langCode] (e.g. `'French'`, `'Français'`).
  static String languageDisplayName(String langCode, AppLocalizations l10n) {
    switch (normalizeLang(langCode)) {
      case 'ar':
        return l10n.langNameArabic;
      case 'fr':
        return l10n.langNameFrench;
      case 'es':
        return l10n.langNameSpanish;
      case 'de':
        return l10n.langNameGerman;
      case 'ja':
        return l10n.langNameJapanese;
      case 'en':
      default:
        return l10n.langNameEnglish;
    }
  }

  static String _cacheKey(String title, String description, String targetLang) {
    final normTarget = normalizeLang(targetLang);
    final payload = '${title.trim()}\n---\n${description.trim()}';
    final hash = _fnv1aHex(payload);
    return '$_prefsKeyPrefix${normTarget}_$hash';
  }

  static String _fnv1aHex(String input) {
    var hash = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  /// Returns a cached translation synchronously if already loaded in memory.
  ListingTranslationResult? getCachedInMemory(
    String title,
    String description,
    String targetLang,
  ) {
    return _memoryCache[_cacheKey(title, description, targetLang)];
  }

  /// Checks local `SharedPreferences` cache before any translation API call.
  Future<ListingTranslationResult?> getCachedTranslation(
    String title,
    String description,
    String targetLang,
  ) async {
    final key = _cacheKey(title, description, targetLang);
    final memHit = _memoryCache[key];
    if (memHit != null) return memHit;

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final parsed = ListingTranslationResult.fromJson(decoded);
        _memoryCache[key] = parsed;
        return parsed;
      }
    } catch (_) {}
    return null;
  }

  /// Translates ONLY [title] and [description] into [targetLang] for display.
  /// Checks local cache first and caches the result locally after translation.
  Future<ListingTranslationResult> translateListing(
    String title,
    String description,
    String targetLang, {
    String? sourceLangOverride,
  }) async {
    final cleanTitle = title.trim();
    final cleanDesc = description.trim();
    final normTarget = normalizeLang(targetLang);
    final key = _cacheKey(cleanTitle, cleanDesc, normTarget);

    final cached = await getCachedTranslation(cleanTitle, cleanDesc, normTarget);
    if (cached != null) return cached;

    final sourceLang = sourceLangOverride != null && sourceLangOverride.isNotEmpty
        ? normalizeLang(sourceLangOverride)
        : detectListingLanguage(cleanTitle, cleanDesc);

    // TODO: Connect AI translation API (e.g. POST /api/ai/translate-listing or Gemini API)
    // sending only {title: cleanTitle, description: cleanDesc, source_lang: sourceLang, target_lang: normTarget}
    // and returning the translated title & description without modifying Firestore/DB.
    final translatedTitle = cleanTitle;
    final translatedDescription = cleanDesc;

    final result = ListingTranslationResult(
      title: translatedTitle,
      description: translatedDescription,
      sourceLang: sourceLang,
      targetLang: normTarget,
    );

    _memoryCache[key] = result;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(result.toJson()));
    } catch (_) {}

    return result;
  }
}
