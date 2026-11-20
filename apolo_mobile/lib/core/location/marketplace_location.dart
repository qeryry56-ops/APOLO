import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'browser_geo.dart';

/// Represents a city/area center used for Apolo's Facebook Marketplace-style
/// geographic zoning and real OpenStreetMap positioning.
class MoroccanCityCoord {
  final String nameAr;
  final String nameFr;
  final String nameEn;
  final double lat;
  final double lng;
  final List<String> aliases;

  const MoroccanCityCoord({
    required this.nameAr,
    required this.nameFr,
    required this.nameEn,
    required this.lat,
    required this.lng,
    this.aliases = const [],
  });

  String labelForLang(String lang) {
    if (lang == 'ar') return nameAr;
    if (lang == 'en') return nameEn;
    return nameFr;
  }
}

/// Centralized geolocation, Haversine distance, and Marketplace Zone filtering.
class MarketplaceLocation {
  MarketplaceLocation._();

  static const double defaultZoneRadiusKm = 40.0;
  static const List<double> radiusOptionsKm = [10, 25, 40, 80, 150];

  static const MoroccanCityCoord fallbackCasablanca = MoroccanCityCoord(
    nameAr: 'الدار البيضاء',
    nameFr: 'Casablanca',
    nameEn: 'Casablanca',
    lat: 33.5731,
    lng: -7.5898,
    aliases: ['casablanca', 'casa', 'dar el beida', 'الدار البيضاء', 'كازا'],
  );

  static const List<MoroccanCityCoord> cities = [
    fallbackCasablanca,
    MoroccanCityCoord(
      nameAr: 'الرباط',
      nameFr: 'Rabat',
      nameEn: 'Rabat',
      lat: 34.0209,
      lng: -6.8416,
      aliases: ['rabat', 'الرباط', 'agdal', 'hay riad'],
    ),
    MoroccanCityCoord(
      nameAr: 'سلا',
      nameFr: 'Salé',
      nameEn: 'Sale',
      lat: 34.0531,
      lng: -6.7985,
      aliases: ['sale', 'salé', 'سلا', 'sala al jadida', 'سلا الجديدة'],
    ),
    MoroccanCityCoord(
      nameAr: 'تمارة',
      nameFr: 'Témara',
      nameEn: 'Temara',
      lat: 33.9287,
      lng: -6.9066,
      aliases: ['temara', 'témara', 'تمارة', 'harhoura'],
    ),
    MoroccanCityCoord(
      nameAr: 'بوزنيقة',
      nameFr: 'Bouznika',
      nameEn: 'Bouznika',
      lat: 33.7894,
      lng: -7.1597,
      aliases: ['bouznika', 'بوزنيقة', 'cherrat', 'بن سليمان', 'benslimane'],
    ),
    MoroccanCityCoord(
      nameAr: 'المحمدية',
      nameFr: 'Mohammedia',
      nameEn: 'Mohammedia',
      lat: 33.6866,
      lng: -7.3830,
      aliases: ['mohammedia', 'المحمدية', 'fedala'],
    ),
    MoroccanCityCoord(
      nameAr: 'الصخيرات',
      nameFr: 'Skhirat',
      nameEn: 'Skhirat',
      lat: 33.8527,
      lng: -7.0314,
      aliases: ['skhirat', 'الصخيرات'],
    ),
    MoroccanCityCoord(
      nameAr: 'القنيطرة',
      nameFr: 'Kénitra',
      nameEn: 'Kenitra',
      lat: 34.2610,
      lng: -6.5802,
      aliases: ['kenitra', 'kénitra', 'القنيطرة', 'mehdia'],
    ),
    MoroccanCityCoord(
      nameAr: 'مراكش',
      nameFr: 'Marrakech',
      nameEn: 'Marrakech',
      lat: 31.6295,
      lng: -7.9811,
      aliases: ['marrakech', 'marrakesh', 'مراكش', 'gueliz', 'palmeraie'],
    ),
    MoroccanCityCoord(
      nameAr: 'طنجة',
      nameFr: 'Tanger',
      nameEn: 'Tangier',
      lat: 35.7595,
      lng: -5.8340,
      aliases: ['tanger', 'tangier', 'طنجة', 'malabata'],
    ),
    MoroccanCityCoord(
      nameAr: 'أكادير',
      nameFr: 'Agadir',
      nameEn: 'Agadir',
      lat: 30.4278,
      lng: -9.5981,
      aliases: ['agadir', 'أكادير', 'اكادير', 'inzegane', 'anzan'],
    ),
    MoroccanCityCoord(
      nameAr: 'تغازوت',
      nameFr: 'Taghazout',
      nameEn: 'Taghazout',
      lat: 30.5446,
      lng: -9.7109,
      aliases: ['taghazout', 'تغازوت', 'تاغازوت'],
    ),
    MoroccanCityCoord(
      nameAr: 'فاس',
      nameFr: 'Fès',
      nameEn: 'Fes',
      lat: 34.0181,
      lng: -5.0078,
      aliases: ['fes', 'fès', 'fez', 'فاس'],
    ),
    MoroccanCityCoord(
      nameAr: 'مكناس',
      nameFr: 'Meknès',
      nameEn: 'Meknes',
      lat: 33.8730,
      lng: -5.5407,
      aliases: ['meknes', 'meknès', 'مكناس'],
    ),
    MoroccanCityCoord(
      nameAr: 'وجدة',
      nameFr: 'Oujda',
      nameEn: 'Oujda',
      lat: 34.6814,
      lng: -1.9086,
      aliases: ['oujda', 'وجدة'],
    ),
    MoroccanCityCoord(
      nameAr: 'تطوان',
      nameFr: 'Tétouan',
      nameEn: 'Tetouan',
      lat: 35.5889,
      lng: -5.3626,
      aliases: ['tetouan', 'tétouan', 'تطوان', 'martil', 'fnideq', 'mdiq'],
    ),
    MoroccanCityCoord(
      nameAr: 'الناظور',
      nameFr: 'Nador',
      nameEn: 'Nador',
      lat: 35.1681,
      lng: -2.9335,
      aliases: ['nador', 'الناظور'],
    ),
    MoroccanCityCoord(
      nameAr: 'الجديدة',
      nameFr: 'El Jadida',
      nameEn: 'El Jadida',
      lat: 33.2316,
      lng: -8.5007,
      aliases: ['el jadida', 'jadida', 'الجديدة', 'azemmour'],
    ),
    MoroccanCityCoord(
      nameAr: 'آسفي',
      nameFr: 'Safi',
      nameEn: 'Safi',
      lat: 32.2994,
      lng: -9.2372,
      aliases: ['safi', 'آسفي', 'اسفي'],
    ),
    MoroccanCityCoord(
      nameAr: 'سطات',
      nameFr: 'Settat',
      nameEn: 'Settat',
      lat: 33.0010,
      lng: -7.6166,
      aliases: ['settat', 'سطات'],
    ),
    MoroccanCityCoord(
      nameAr: 'برشيد',
      nameFr: 'Berrechid',
      nameEn: 'Berrechid',
      lat: 33.2655,
      lng: -7.5875,
      aliases: ['berrechid', 'برشيد', 'had soualem'],
    ),
    MoroccanCityCoord(
      nameAr: 'خريبكة',
      nameFr: 'Khouribga',
      nameEn: 'Khouribga',
      lat: 32.8811,
      lng: -6.9063,
      aliases: ['khouribga', 'خريبكة'],
    ),
    MoroccanCityCoord(
      nameAr: 'بني ملال',
      nameFr: 'Béni Mellal',
      nameEn: 'Beni Mellal',
      lat: 32.3373,
      lng: -6.3498,
      aliases: ['beni mellal', 'béni mellal', 'بني ملال'],
    ),
    MoroccanCityCoord(
      nameAr: 'الصويرة',
      nameFr: 'Essaouira',
      nameEn: 'Essaouira',
      lat: 31.5085,
      lng: -9.7595,
      aliases: ['essaouira', 'الصويرة'],
    ),
    MoroccanCityCoord(
      nameAr: 'شفشاون',
      nameFr: 'Chefchaouen',
      nameEn: 'Chefchaouen',
      lat: 35.1688,
      lng: -5.2636,
      aliases: ['chefchaouen', 'chaouen', 'شفشاون'],
    ),
    MoroccanCityCoord(
      nameAr: 'ورزازات',
      nameFr: 'Ouarzazate',
      nameEn: 'Ouarzazate',
      lat: 30.9335,
      lng: -6.9370,
      aliases: ['ouarzazate', 'ورزازات'],
    ),
    MoroccanCityCoord(
      nameAr: 'تارودانت',
      nameFr: 'Taroudant',
      nameEn: 'Taroudant',
      lat: 30.4703,
      lng: -8.8769,
      aliases: ['taroudant', 'تارودانت'],
    ),
    MoroccanCityCoord(
      nameAr: 'العرائش',
      nameFr: 'Larache',
      nameEn: 'Larache',
      lat: 35.1932,
      lng: -6.1557,
      aliases: ['larache', 'العرائش', 'ksar el kebir'],
    ),
    MoroccanCityCoord(
      nameAr: 'العيون',
      nameFr: 'Laâyoune',
      nameEn: 'Laayoune',
      lat: 27.1253,
      lng: -13.1625,
      aliases: ['laayoune', 'laâyoune', 'العيون'],
    ),
    MoroccanCityCoord(
      nameAr: 'الداخلة',
      nameFr: 'Dakhla',
      nameEn: 'Dakhla',
      lat: 23.6848,
      lng: -15.9579,
      aliases: ['dakhla', 'الداخلة'],
    ),
    // Extra coastal resort coordinate fallback used in showcase test data
    MoroccanCityCoord(
      nameAr: 'كاسكايس',
      nameFr: 'Cascais',
      nameEn: 'Cascais',
      lat: 38.6979,
      lng: -9.4215,
      aliases: ['cascais', 'quinta da marinha', 'sintra', 'portugal'],
    ),
  ];

  static String _normalizeText(String input) {
    return input
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('â', 'a')
        .replaceAll('à', 'a')
        .replaceAll('î', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('û', 'u')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .trim();
  }

  /// Finds the best matching city coordinate record from Arabic/French/English text.
  static MoroccanCityCoord? matchCityByName(String? rawName) {
    final normalized = _normalizeText((rawName ?? ''));
    if (normalized.isEmpty) return null;

    for (final city in cities) {
      if (_normalizeText(city.nameFr) == normalized ||
          _normalizeText(city.nameEn) == normalized ||
          _normalizeText(city.nameAr) == normalized) {
        return city;
      }
      for (final alias in city.aliases) {
        final normAlias = _normalizeText(alias);
        if (normalized == normAlias ||
            (normAlias.length >= 3 && normalized.contains(normAlias))) {
          return city;
        }
      }
    }
    return null;
  }

  /// Resolves real geographic coordinates for an ad map.
  static ({double lat, double lng, MoroccanCityCoord? match, bool isExact})
      resolveAdLocation(Map<dynamic, dynamic> ad) {
    double? readCoord(dynamic val) =>
        val == null ? null : double.tryParse(val.toString().trim());

    final meta = ad['metadata'] is Map ? ad['metadata'] as Map : const {};
    final cityMap = ad['city'] is Map ? ad['city'] as Map : const {};

    final directLat = readCoord(
      ad['lat'] ?? ad['latitude'] ?? meta['lat'] ?? meta['latitude'] ?? cityMap['lat'],
    );
    final directLng = readCoord(
      ad['lng'] ??
          ad['longitude'] ??
          meta['lng'] ??
          meta['longitude'] ??
          cityMap['lng'],
    );

    final candidateCityText = [
      ad['location_display'],
      ad['location'],
      cityMap['name_fr'],
      cityMap['name_ar'],
      cityMap['name'],
      ad['city_fr'],
      ad['city_ar'],
      ad['city_name'],
    ].where((e) => e != null && e.toString().trim().isNotEmpty).join(' ');

    final matched = matchCityByName(candidateCityText);

    if (directLat != null &&
        directLng != null &&
        directLat.abs() <= 90 &&
        directLng.abs() <= 180 &&
        (directLat != 0 || directLng != 0)) {
      return (
        lat: directLat,
        lng: directLng,
        match: matched ?? nearestCity(directLat, directLng),
        isExact: true,
      );
    }

    if (matched != null) {
      return (lat: matched.lat, lng: matched.lng, match: matched, isExact: false);
    }

    return (
      lat: fallbackCasablanca.lat,
      lng: fallbackCasablanca.lng,
      match: fallbackCasablanca,
      isExact: false,
    );
  }

  /// Resolves city coordinates from backend taxonomy city entry by ID or name.
  static MoroccanCityCoord? resolveTaxonomyCity(
    int? cityId,
    List<dynamic> taxonomyCities,
  ) {
    if (cityId == null) return null;
    for (final raw in taxonomyCities) {
      if (raw is Map && int.tryParse((raw['id'] ?? '').toString()) == cityId) {
        final match = matchCityByName(
          '${raw['name_fr'] ?? ''} ${raw['name_ar'] ?? ''} ${raw['name'] ?? ''}',
        );
        if (match != null) return match;
        final lat = double.tryParse((raw['lat'] ?? '').toString());
        final lng = double.tryParse((raw['lng'] ?? '').toString());
        if (lat != null && lng != null) {
          return MoroccanCityCoord(
            nameAr: (raw['name_ar'] ?? raw['name'] ?? 'مدينتي').toString(),
            nameFr: (raw['name_fr'] ?? raw['name'] ?? 'Ma ville').toString(),
            nameEn: (raw['name_en'] ?? raw['name'] ?? 'My city').toString(),
            lat: lat,
            lng: lng,
          );
        }
      }
    }
    return null;
  }

  /// Resolves matching taxonomy city ID for a `MoroccanCityCoord`.
  static int? findTaxonomyCityId(
    MoroccanCityCoord target,
    List<dynamic> taxonomyCities,
  ) {
    for (final raw in taxonomyCities) {
      if (raw is Map) {
        final candidate =
            '${raw['name_fr'] ?? ''} ${raw['name_ar'] ?? ''} ${raw['name'] ?? ''}';
        final match = matchCityByName(candidate);
        if (match != null && match.nameFr == target.nameFr) {
          return int.tryParse((raw['id'] ?? '').toString());
        }
      }
    }
    return null;
  }

  /// Great-circle Haversine distance in kilometers.
  static double haversineKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);

  /// Finds the closest Moroccan city to given coordinates.
  static MoroccanCityCoord nearestCity(double lat, double lng) {
    MoroccanCityCoord best = fallbackCasablanca;
    double bestDist = double.infinity;
    for (final city in cities) {
      // Skip non-Morocco showcase fallback unless already close
      if (city.nameFr == 'Cascais' && lat < 36.2) continue;
      final d = haversineKm(lat, lng, city.lat, city.lng);
      if (d < bestDist) {
        bestDist = d;
        best = city;
      }
    }
    return best;
  }

  static bool isWithinMoroccoBounds(double lat, double lng) {
    return lat >= 20.5 && lat <= 36.3 && lng >= -17.5 && lng <= -0.8;
  }

  /// Computes distance in km between an ad and the user's zone center.
  static double? distanceBetweenAdAndZone(
    Map<dynamic, dynamic> ad,
    double? zoneLat,
    double? zoneLng,
  ) {
    if (zoneLat == null || zoneLng == null) return null;
    final adLoc = resolveAdLocation(ad);
    return haversineKm(zoneLat, zoneLng, adLoc.lat, adLoc.lng);
  }

  /// Annotates ads with `distance_km` and filters strictly inside [radiusKm]
  /// when [enabled] is true and a valid zone is set.
  static List<Map<String, dynamic>> filterAndAnnotateByZone(
    List<Map<String, dynamic>> ads, {
    double? zoneLat,
    double? zoneLng,
    int? zoneCityId,
    String? zoneCityName,
    double radiusKm = defaultZoneRadiusKm,
    bool enabled = true,
  }) {
    if (zoneLat == null || zoneLng == null) return ads;

    final List<({Map<String, dynamic> ad, double distance})> scored = [];
    final normalizedZoneCity = _normalizeText(zoneCityName ?? '');

    for (final rawAd in ads) {
      final ad = Map<String, dynamic>.from(rawAd);
      final adLoc = resolveAdLocation(ad);
      final dist = haversineKm(zoneLat, zoneLng, adLoc.lat, adLoc.lng);

      // Attach distance_km cleanly when not explicitly fixed in raw payload
      if ((ad['distance_km'] ?? '').toString().trim().isEmpty) {
        final rounded = dist < 1 ? 1 : dist.round();
        ad['distance_km'] = '$rounded';
      }

      if (!enabled || radiusKm <= 0) {
        scored.add((ad: ad, distance: dist));
        continue;
      }

      final int? adCityId = int.tryParse(
        (ad['city_id'] ?? (ad['city'] is Map ? ad['city']['id'] : ''))
            .toString(),
      );
      final sameCityId = zoneCityId != null && adCityId == zoneCityId;
      final sameCityMatch = normalizedZoneCity.isNotEmpty &&
          adLoc.match != null &&
          (_normalizeText(adLoc.match!.nameFr) == normalizedZoneCity ||
              _normalizeText(adLoc.match!.nameAr) == normalizedZoneCity);

      if (sameCityId || sameCityMatch || dist <= radiusKm) {
        scored.add((ad: ad, distance: dist));
      }
    }

    scored.sort((a, b) => a.distance.compareTo(b.distance));
    return scored.map((e) => e.ad).toList();
  }

  /// Attempts automatic GPS (on request) or silent IP-based geolocation.
  static Future<({double lat, double lng, MoroccanCityCoord city, String? detectedCity})?>
      detectLocation({
    bool tryGps = false,
  }) async {
    if (tryGps) {
      final gps = await tryBrowserGeolocation();
      if (gps != null) {
        final city = nearestCity(gps.lat, gps.lng);
        return (
          lat: gps.lat,
          lng: gps.lng,
          city: city,
          detectedCity: city.nameFr,
        );
      }
    }

    // Silent lightweight IP geolocation lookup
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(milliseconds: 2800),
          receiveTimeout: const Duration(milliseconds: 2800),
        ),
      );
      final res = await dio.get('https://ipwho.is/');
      if (res.data is Map) {
        final data = res.data as Map;
        if (data['success'] == true) {
          final lat = double.tryParse((data['latitude'] ?? '').toString());
          final lng = double.tryParse((data['longitude'] ?? '').toString());
          final countryCode = (data['country_code'] ?? '').toString().toUpperCase();
          final rawCity = (data['city'] ?? '').toString().trim();
          if (lat != null && lng != null && countryCode == 'MA') {
            final city = matchCityByName(rawCity) ?? nearestCity(lat, lng);
            return (
              lat: lat,
              lng: lng,
              city: city,
              detectedCity: rawCity.isNotEmpty ? rawCity : city.nameFr,
            );
          }
        }
      }
    } catch (_) {}

    return null;
  }
}
