import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config/app_config.dart';
import '../../core/location/marketplace_location.dart';
import '../../core/state/app_state.dart';
import '../../widgets/dl_settings_kit.dart';
import 'kinetic_widgets.dart';
import 'real_marketplace_map.dart';

/// Compact Dynamic Layer v5.1 Marketplace Zone Pill (shows active city + radius or All Morocco).
class MarketplaceZonePill extends StatelessWidget {
  final AppState state;
  final VoidCallback onTap;
  final bool compact;

  const MarketplaceZonePill({
    super.key,
    required this.state,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = state.s;
    final palette = ApoloDlPalette.of(context);
    final active = state.hasActiveZone;
    final label = active
        ? state.activeZoneBadgeLabel(s)
        : s.tr('كل المغرب', 'Tout le Maroc', 'All Morocco');

    return PressableScale(
      key: const Key('marketplace-zone-pill'),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        height: compact ? 32 : 36,
        padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 14),
        decoration: BoxDecoration(
          color: active ? palette.ink : palette.pill,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.location_solid,
              size: compact ? 12.5 : 13.5,
              color: active ? palette.onInk : palette.ink,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 11.5 : 12.5,
                  fontWeight: FontWeight.w700,
                  color: active ? palette.onInk : palette.ink,
                ),
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              CupertinoIcons.chevron_down,
              size: compact ? 10.5 : 11.5,
              color: active
                  ? palette.onInk.withValues(alpha: 0.72)
                  : palette.muted,
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the Dynamic Layer v5.1 Marketplace Zone & Radius Bottom Sheet.
Future<bool?> showMarketplaceZoneSheet(BuildContext context) {
  final state = AppState();
  final palette = ApoloDlPalette.of(context);
  HapticFeedback.selectionClick();

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: palette.bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => MarketplaceZoneContent(state: state),
  );
}

class MarketplaceZoneContent extends StatefulWidget {
  final AppState state;
  final bool embeddedInScreen;

  const MarketplaceZoneContent({
    super.key,
    required this.state,
    this.embeddedInScreen = false,
  });

  @override
  State<MarketplaceZoneContent> createState() => _MarketplaceZoneContentState();
}

class _MarketplaceZoneContentState extends State<MarketplaceZoneContent> {
  Color get _dlBg => ApoloDlPalette.of(context).bg;
  Color get _dlSurface => ApoloDlPalette.of(context).surfaceSubtle;
  Color get _dlPill => ApoloDlPalette.of(context).pill;
  Color get _dlInk => ApoloDlPalette.of(context).ink;
  Color get _dlOnInk => ApoloDlPalette.of(context).onInk;
  Color get _dlMuted => ApoloDlPalette.of(context).muted;

  late double _lat;
  late double _lng;
  late String _nameAr;
  late String _nameFr;
  late double _radiusKm;
  late bool _allMorocco;
  bool _detecting = false;
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;
  List<
      ({
        String title,
        String subtitle,
        double lat,
        double lng,
        MoroccanCityCoord city,
      })> _searchResults = [];
  bool _searching = false;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      setState(() {
        _searching = false;
        _searchResults = [];
      });
      return;
    }
    setState(() => _searching = true);
    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      final results = await MarketplaceLocation.searchPlaces(trimmed);
      if (!mounted) return;
      setState(() {
        _searching = false;
        _searchResults = results.take(4).toList();
      });
    });
  }

  @override
  void initState() {
    super.initState();
    final st = widget.state;
    if (st.userLat != null && st.userLng != null) {
      _lat = st.userLat!;
      _lng = st.userLng!;
      _nameAr =
          st.zoneCityNameAr ?? MarketplaceLocation.fallbackCasablanca.nameAr;
      _nameFr =
          st.zoneCityNameFr ?? MarketplaceLocation.fallbackCasablanca.nameFr;
      _radiusKm = st.zoneRadiusKm > 0
          ? st.zoneRadiusKm
          : MarketplaceLocation.defaultZoneRadiusKm;
      _allMorocco = !st.zoneFilterEnabled;
    } else {
      final fallback = MarketplaceLocation.resolveTaxonomyCity(
            st.preferredCityId,
            st.cities,
          ) ??
          MarketplaceLocation.fallbackCasablanca;
      _lat = fallback.lat;
      _lng = fallback.lng;
      _nameAr = fallback.nameAr;
      _nameFr = fallback.nameFr;
      _radiusKm = MarketplaceLocation.defaultZoneRadiusKm;
      _allMorocco = !st.zoneFilterEnabled;
    }
  }

  Future<void> _detectAuto(AppStrings s) async {
    setState(() => _detecting = true);
    try {
      final detected = await MarketplaceLocation.detectLocation(tryGps: true);
      if (!mounted) return;
      if (detected != null) {
        final rev = await MarketplaceLocation.reverseGeocode(
          detected.lat,
          detected.lng,
        );
        if (!mounted) return;
        HapticFeedback.mediumImpact();
        setState(() {
          _lat = detected.lat;
          _lng = detected.lng;
          _nameAr = rev.labelAr;
          _nameFr = rev.labelFr;
          _allMorocco = false;
          _searchResults = [];
          if (_radiusKm <= 0) {
            _radiusKm = MarketplaceLocation.defaultZoneRadiusKm;
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _dlInk,
            behavior: SnackBarBehavior.floating,
            content: Text(
              s.tr(
                'تعذر تحديد موقعك تلقائياً — اختر مدينتك من القائمة أسفله',
                'Détection impossible — choisissez votre ville ci-dessous',
                'Could not auto-detect location — select your city below',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _detecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state.s;
    final activeCityLabel = s.isAr ? _nameAr : _nameFr;
    final embedded = widget.embeddedInScreen;

    final scrollBody = Directionality(
      textDirection: s.isAr ? TextDirection.rtl : TextDirection.ltr,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, embedded ? 12 : 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!embedded) ...[
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _dlPill,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.tr(
                            'تحديد منطقة الإعلانات',
                            'Zone des annonces',
                            'Marketplace Location',
                          ),
                          style: TextStyle(
                            fontSize: 18.5,
                            fontWeight: FontWeight.w800,
                            color: _dlInk,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.tr(
                            'شاهد الإعلانات القريبة منك في منطقتك الجغرافية',
                            'Affichez uniquement les annonces autour de votre zone',
                            'Only see listings inside your local area',
                          ),
                          style: TextStyle(
                            fontSize: 12.5,
                            color: _dlMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _allMorocco = !_allMorocco);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _allMorocco ? _dlInk : _dlPill,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.globe,
                            size: 13.5,
                            color: _allMorocco ? _dlOnInk : _dlInk,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            s.tr('كل المغرب', 'Tout le Maroc', 'All Morocco'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _allMorocco ? _dlOnInk : _dlInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 1. Flat #F6F6F6 Grouped Card: Search + Interactive Map + GPS Auto-Detect
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _dlSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  // Place Search Input Bar (#FFFFFF capsule)
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: _dlBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.search,
                          size: 16,
                          color: _dlMuted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              inputDecorationTheme: const InputDecorationTheme(
                                filled: false,
                                fillColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            child: TextField(
                              key: const Key('zone-place-search'),
                              controller: _searchCtrl,
                              onChanged: _onSearchChanged,
                              cursorColor: _dlInk,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: _dlInk,
                              ),
                              decoration: InputDecoration(
                                filled: false,
                                fillColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                hintText: s.tr(
                                  'ابحث عن حي، مدينة أو عنوان...',
                                  'Rechercher un quartier, une ville...',
                                  'Search neighborhood, city, address...',
                                ),
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: _dlMuted,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_searching)
                          const CupertinoActivityIndicator(radius: 8)
                        else if (_searchCtrl.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              setState(() {
                                _searchResults = [];
                                _searching = false;
                              });
                            },
                            child: Icon(
                              CupertinoIcons.xmark_circle_fill,
                              size: 17,
                              color: _dlMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_searchResults.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _dlBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          for (int i = 0; i < _searchResults.length; i++) ...[
                            if (i > 0) const ApoloDlSeparator(),
                            InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                final r = _searchResults[i];
                                HapticFeedback.selectionClick();
                                FocusScope.of(context).unfocus();
                                setState(() {
                                  _lat = r.lat;
                                  _lng = r.lng;
                                  _nameAr = r.title == r.city.nameFr ||
                                          r.title == r.city.nameAr
                                      ? r.city.nameAr
                                      : '${r.title}، ${r.city.nameAr}';
                                  _nameFr = r.title == r.city.nameFr ||
                                          r.title == r.city.nameAr
                                      ? r.city.nameFr
                                      : '${r.title}, ${r.city.nameFr}';
                                  _allMorocco = false;
                                  _searchResults = [];
                                  _searchCtrl.text = r.title;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      CupertinoIcons.location_solid,
                                      size: 14,
                                      color: _dlInk,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _searchResults[i].title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: _dlInk,
                                            ),
                                          ),
                                          if (_searchResults[i]
                                              .subtitle
                                              .isNotEmpty)
                                            Text(
                                              _searchResults[i].subtitle,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: _dlMuted,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  RealMarketplaceMap(
                    lat: _lat,
                    lng: _lng,
                    cityLabel: _allMorocco
                        ? s.tr('المغرب كامل', 'Tout le Maroc', 'All Morocco')
                        : activeCityLabel,
                    circleRadiusKm: _allMorocco ? 140 : _radiusKm,
                    height: 172,
                    borderRadius: 16,
                    interactive: true,
                    onCenterChanged: (pos) {
                      setState(() {
                        _lat = pos.lat;
                        _lng = pos.lng;
                        _allMorocco = false;
                      });
                    },
                    onPanEnd: (pos) async {
                      final rev = await MarketplaceLocation.reverseGeocode(
                        pos.lat,
                        pos.lng,
                      );
                      if (!mounted) return;
                      setState(() {
                        _nameAr = rev.labelAr;
                        _nameFr = rev.labelFr;
                      });
                    },
                    topOverlay: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _dlBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.location_solid,
                            size: 12,
                            color: _dlInk,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _allMorocco
                                ? s.tr('نطاق مفتوح', 'Sans limite', 'Nationwide')
                                : '$activeCityLabel · ${_radiusKm.round()} ${s.tr("كم", "km", "km")}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: _dlInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  PressableScale(
                    key: const Key('zone-auto-detect-btn'),
                    onTap: _detecting ? () {} : () => _detectAuto(s),
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: _dlBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_detecting)
                            const CupertinoActivityIndicator(radius: 8)
                          else
                            Icon(
                              CupertinoIcons.location_fill,
                              size: 16,
                              color: _dlInk,
                            ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              s.tr(
                                'تحديد منطقتي تلقائياً (GPS)',
                                'Détecter ma position automatiquement',
                                'Detect my location automatically',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _dlInk,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 2. Flat #F6F6F6 Grouped Card: Radius Chips + Cities Selector
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _dlSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          s.tr(
                            'نطاق المسافة (كم)',
                            'Rayon de recherche (km)',
                            'Distance radius',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: _dlInk,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _allMorocco
                            ? s.tr(
                                'كل المغرب',
                                'Tout le Maroc',
                                'All of Morocco',
                              )
                            : '${_radiusKm.round()} ${s.tr("كم", "km", "km")}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _dlInk,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: MarketplaceLocation.radiusOptionsKm.map((km) {
                        final selected = !_allMorocco && _radiusKm == km;
                        return Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: PressableScale(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _allMorocco = false;
                                _radiusKm = km;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: selected ? _dlInk : _dlBg,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${km.round()} ${s.tr("كم", "km", "km")}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: selected ? _dlOnInk : _dlInk,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const ApoloDlSeparator(),
                  const SizedBox(height: 14),
                  Text(
                    s.tr('اختر المدينة', 'Choisir une ville', 'Select city'),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _dlInk,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: MarketplaceLocation.cities.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, idx) {
                        final c = MarketplaceLocation.cities[idx];
                        if (c.nameFr == 'Cascais') {
                          return const SizedBox.shrink();
                        }
                        final selected = !_allMorocco && c.nameFr == _nameFr;
                        return PressableScale(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _lat = c.lat;
                              _lng = c.lng;
                              _nameAr = c.nameAr;
                              _nameFr = c.nameFr;
                              _allMorocco = false;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: selected ? _dlInk : _dlBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              c.labelForLang(s.lang),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: selected ? _dlOnInk : _dlInk,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. Apply Zone Capsule CTA (#000000)
            PressableScale(
              key: const Key('zone-apply-btn'),
              onTap: () async {
                HapticFeedback.lightImpact();
                if (_allMorocco) {
                  await widget.state.clearZoneFilter();
                } else {
                  final matched = MarketplaceLocation.matchCityByName(
                    '$_nameFr $_nameAr',
                  );
                  final taxId = matched != null
                      ? MarketplaceLocation.findTaxonomyCityId(
                          matched,
                          widget.state.cities,
                        )
                      : null;
                  await widget.state.setUserZone(
                    lat: _lat,
                    lng: _lng,
                    nameAr: _nameAr,
                    nameFr: _nameFr,
                    cityId: taxId,
                    radiusKm: _radiusKm,
                    enabled: true,
                  );
                }
                if (context.mounted) Navigator.pop(context, true);
              },
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: _dlInk,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  s.tr('تطبيق المنطقة', 'Appliquer la zone', 'Apply zone'),
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: _dlOnInk,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (embedded) {
      return Container(
        color: _dlBg,
        child: scrollBody,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _dlBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: scrollBody,
      ),
    );
  }
}
