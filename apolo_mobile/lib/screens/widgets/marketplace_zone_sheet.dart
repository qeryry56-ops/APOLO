import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/config/app_config.dart';
import '../../core/location/marketplace_location.dart';
import '../../core/state/app_state.dart';
import 'kinetic_widgets.dart';
import 'real_marketplace_map.dart';

/// Compact 2026 Marketplace Zone Pill (shows active city + radius or All Morocco).
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

  static const Color _ink = Color(0xFF0A0A0A);
  static const Color _activeFill = Color(0xFF0A0A0A);
  static const Color _inactiveFill = Color(0xFFF2F3F7);

  @override
  Widget build(BuildContext context) {
    final s = state.s;
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
        height: compact ? 30 : 34,
        padding: EdgeInsets.symmetric(horizontal: compact ? 11 : 13),
        decoration: BoxDecoration(
          color: active ? _activeFill : _inactiveFill,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? _ink : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.location_solid,
              size: compact ? 12.5 : 13.5,
              color: active ? Colors.white : _ink,
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
                  color: active ? Colors.white : _ink,
                ),
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              CupertinoIcons.chevron_down,
              size: compact ? 10.5 : 11.5,
              color: active ? Colors.white70 : const Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }
}

/// Interactive Marketplace Zone & Radius Bottom Sheet (2026 Monochrome Grouped UI).
Future<bool?> showMarketplaceZoneSheet(BuildContext context) {
  final state = AppState();
  HapticFeedback.selectionClick();

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFF2F3F7),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => _MarketplaceZoneSheetBody(state: state),
  );
}

class _MarketplaceZoneSheetBody extends StatefulWidget {
  final AppState state;

  const _MarketplaceZoneSheetBody({required this.state});

  @override
  State<_MarketplaceZoneSheetBody> createState() =>
      _MarketplaceZoneSheetBodyState();
}

class _MarketplaceZoneSheetBodyState extends State<_MarketplaceZoneSheetBody> {
  static const Color _ink = Color(0xFF0A0A0A);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _canvas = Color(0xFFF2F3F7);
  static const Color _cardBg = Colors.white;
  static const Color _pillGray = Color(0xFFF2F3F7);

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
      _nameAr = st.zoneCityNameAr ?? MarketplaceLocation.fallbackCasablanca.nameAr;
      _nameFr = st.zoneCityNameFr ?? MarketplaceLocation.fallbackCasablanca.nameFr;
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

    return Container(
      decoration: const BoxDecoration(
        color: _canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
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
                            style: const TextStyle(
                              fontSize: 18.5,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.tr(
                              'شاهد الإعلانات القريبة منك في منطقتك الجغرافية',
                              'Affichez uniquement les annonces autour de votre zone',
                              'Only see listings inside your local area',
                            ),
                            style:
                                const TextStyle(fontSize: 12.5, color: _muted),
                          ),
                        ],
                      ),
                    ),
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
                          color: _allMorocco ? _ink : _cardBg,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color:
                                _allMorocco ? _ink : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Text(
                          s.tr('كل المغرب 🌍', 'Tout le Maroc', 'All Morocco'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _allMorocco ? Colors.white : _ink,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 1. White Grouped Card: Search + Interactive Map + GPS Auto-Detect
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    // Place Search Input Bar
                    Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: _pillGray,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.search,
                            size: 16,
                            color: _muted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                inputDecorationTheme:
                                    const InputDecorationTheme(
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
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: _ink,
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
                                  hintStyle: const TextStyle(
                                    fontSize: 13,
                                    color: _muted,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_searching)
                            const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _ink,
                              ),
                            )
                          else if (_searchCtrl.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchCtrl.clear();
                                setState(() {
                                  _searchResults = [];
                                  _searching = false;
                                });
                              },
                              child: const Icon(
                                CupertinoIcons.xmark_circle_fill,
                                size: 17,
                                color: _muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_searchResults.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: _pillGray,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            for (int i = 0; i < _searchResults.length; i++) ...[
                              if (i > 0)
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFE5E7EB),
                                ),
                              InkWell(
                                borderRadius: BorderRadius.circular(14),
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
                                      const Icon(
                                        CupertinoIcons.location_solid,
                                        size: 14,
                                        color: _ink,
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
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: _ink,
                                              ),
                                            ),
                                            if (_searchResults[i]
                                                .subtitle
                                                .isNotEmpty)
                                              Text(
                                                _searchResults[i].subtitle,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  color: _muted,
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
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.location_solid,
                              size: 12,
                              color: _ink,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _allMorocco
                                  ? s.tr(
                                      'نطاق مفتوح', 'Sans limite', 'Nationwide')
                                  : '$activeCityLabel · ${_radiusKm.round()} ${s.tr("كم", "km")}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: _ink,
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
                          color: _pillGray,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_detecting)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _ink,
                                ),
                              )
                            else
                              const Icon(
                                CupertinoIcons.location_fill,
                                size: 16,
                                color: _ink,
                              ),
                            const SizedBox(width: 8),
                            Text(
                              s.tr(
                                'تحديد منطقتي تلقائياً (GPS)',
                                'Détecter ma position automatiquement',
                                'Detect my location automatically',
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _ink,
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

              // 2. White Grouped Card: Radius Chips + Cities Selector
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          s.tr(
                            'نطاق المسافة (كم)',
                            'Rayon de recherche (km)',
                            'Distance radius',
                          ),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                        Text(
                          _allMorocco
                              ? s.tr('كل المغرب', 'Tout le Maroc')
                              : '${_radiusKm.round()} ${s.tr("كم", "km")}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _ink,
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
                                  color: selected ? _ink : _pillGray,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${km.round()} ${s.tr("كم", "km")}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: selected ? Colors.white : _ink,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFF1F2F6)),
                    const SizedBox(height: 14),
                    Text(
                      s.tr('اختر المدينة', 'Choisir une ville', 'Select city'),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _ink,
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
                                color: selected ? _ink : _pillGray,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                c.labelForLang(s.lang),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: selected ? Colors.white : _ink,
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

              // 3. Apply Zone Pill CTA
              PressableScale(
                key: const Key('zone-apply-btn'),
                onTap: () async {
                  HapticFeedback.lightImpact();
                  if (_allMorocco) {
                    await widget.state.clearZoneFilter();
                  } else {
                    final matched = MarketplaceLocation.matchCityByName(
                        '$_nameFr $_nameAr');
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
                    color: _ink,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    s.tr('تطبيق المنطقة', 'Appliquer la zone', 'Apply zone'),
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
