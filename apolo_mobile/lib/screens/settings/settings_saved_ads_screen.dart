import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config/app_config.dart';
import '../../core/state/app_state.dart';
import '../../widgets/dl_settings_kit.dart';
import '../ad_detail_screen.dart';
import '../auth_screen.dart';
import '../widgets/app_image.dart';
import '../widgets/price_text.dart';
import '../../l10n/l10n.dart';

class SettingsSavedAdsScreen extends StatefulWidget {
  const SettingsSavedAdsScreen({super.key});

  @override
  State<SettingsSavedAdsScreen> createState() => _SettingsSavedAdsScreenState();
}

class _SettingsSavedAdsScreenState extends State<SettingsSavedAdsScreen> {
  final AppState _state = AppState();
  List<Map<String, dynamic>> _savedAds = [];
  bool _loading = false;
  bool _hasError = false;
  final Set<int> _pendingIds = <int>{};

  @override
  void initState() {
    super.initState();
    if (_state.isLoggedIn) {
      _fetchSavedAds();
    }
  }

  Future<void> _fetchSavedAds() async {
    if (!_state.isLoggedIn) {
      if (mounted) {
        setState(() {
          _savedAds = [];
          _loading = false;
          _hasError = false;
        });
      }
      return;
    }

    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final res = await _state.api.dio.get('/favorites');
      final raw = res.data is Map ? res.data['data'] : null;
      final list = raw is List
          ? raw
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        _savedAds = list;
        _loading = false;
        _hasError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _removeSaved(Map<String, dynamic> ad) async {
    final adId = int.tryParse((ad['id'] ?? '').toString());
    if (adId == null || _pendingIds.contains(adId)) return;

    setState(() => _pendingIds.add(adId));
    try {
      final stillSaved = await _state.toggleFavorite(
        adId,
        categoryId: _state.extractAdCategoryId(ad),
      );
      if (!mounted) return;
      if (!stillSaved) {
        HapticFeedback.selectionClick();
        setState(() {
          _savedAds.removeWhere((item) => item['id'].toString() == '$adId');
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              _state.s.tr(
                'تعذر إزالة الإعلان من المحفوظات. حاول مجدداً.',
                'Impossible de retirer des favoris. Réessayez.',
                appL10n.settingsSavedAdsCouldNotRemoveSavedListing,
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _pendingIds.remove(adId));
      }
    }
  }

  String _resolveCity(Map<String, dynamic> ad, AppStrings s) {
    if (ad['city'] is Map) {
      final city = ad['city'] as Map;
      final key = s.isAr ? 'name_ar' : (s.isEn ? 'name_en' : 'name_fr');
      final val = (city[key] ?? city['name_fr'] ?? city['name'] ?? '').toString().trim();
      if (val.isNotEmpty) return val;
    }
    final fallbackKey = s.isAr ? 'city_ar' : (s.isEn ? 'city_en' : 'city_fr');
    return (ad[fallbackKey] ?? ad['city_fr'] ?? ad['city_name'] ?? '').toString().trim();
  }

  String _resolvePrice(Map<String, dynamic> ad, AppStrings s) {
    final formatted = (ad['price_formatted'] ?? '').toString().trim();
    if (formatted.isNotEmpty) return formatted;
    final price = ad['price'];
    if (price == null) return '';
    return '$price ${s.tr('د.م', 'DH', appL10n.proPlusMad)}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        final s = _state.s;
        final palette = ApoloDlPalette.of(context);

        return Directionality(
          textDirection: s.isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: palette.bg,
            body: SafeArea(
              child: Column(
                children: [
                  ApoloDlTopNav(
                    title: s.tr('المحفوظات', 'Enregistrés', appL10n.profileSaved),
                    showSeparator: false,
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: _buildBody(palette, s),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(ApoloDlPalette palette, AppStrings s) {
    if (!_state.isLoggedIn) {
      return ApoloDlEmptyState(
        icon: CupertinoIcons.bookmark,
        headline: s.tr(
          'سجّل الدخول لعرض المحفوظات',
          'Connectez-vous pour voir vos favoris',
          appL10n.settingsSavedAdsSignViewSavedListings,
        ),
        description: s.tr(
          'احفظ الإعلانات التي تعجبك للرجوع إليها في أي وقت.',
          'Enregistrez des annonces pour les retrouver facilement.',
          appL10n.settingsSavedAdsSaveListingsYouLikeRevisit,
        ),
        actionLabel: s.tr('تسجيل الدخول', 'Se connecter', appL10n.logInButton),
        onAction: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AuthScreen(initialIsLogin: true),
            ),
          );
          if (mounted && _state.isLoggedIn) {
            await _fetchSavedAds();
          }
        },
      );
    }

    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: palette.ink),
      );
    }

    if (_hasError) {
      return ApoloDlEmptyState(
        icon: CupertinoIcons.exclamationmark_circle,
        headline: s.tr(
          'تعذر تحميل المحفوظات',
          'Impossible de charger les favoris',
          appL10n.settingsSavedAdsCouldNotLoadSavedListings,
        ),
        description: s.tr(
          'تحقق من اتصالك بالإنترنت وأعد المحاولة.',
          'Vérifiez votre connexion et réessayez.',
          appL10n.settingsSavedAdsCheckInternetConnectionTryAgain,
        ),
        actionLabel: s.tr('إعادة المحاولة', 'Réessayer', appL10n.tryAgainButton),
        onAction: _fetchSavedAds,
      );
    }

    if (_savedAds.isEmpty) {
      return ApoloDlEmptyState(
        icon: CupertinoIcons.bookmark,
        headline: s.tr(
          'لا توجد إعلانات محفوظة بعد',
          'Aucune annonce enregistrée',
          appL10n.searchNoSavedListingsYet,
        ),
        description: s.tr(
          'اضغط على أيقونة الحفظ في أي إعلان لإضافته هنا.',
          'Appuyez sur le cœur d’une annonce pour l’enregistrer ici.',
          appL10n.settingsSavedAdsTapFavoriteIconAnyListing,
        ),
      );
    }

    return RefreshIndicator(
      color: palette.ink,
      onRefresh: _fetchSavedAds,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.74,
        ),
        itemCount: _savedAds.length,
        itemBuilder: (context, index) {
          final ad = _savedAds[index];
          final adId = int.tryParse((ad['id'] ?? '').toString()) ?? 0;
          final title = (ad['title'] ?? '').toString();
          final imageUrl =
              (ad['main_image'] ?? ad['primary_image'] ?? '').toString();
          final city = _resolveCity(ad, s);
          final price = _resolvePrice(ad, s);
          final busy = _pendingIds.contains(adId);

          return Container(
            decoration: BoxDecoration(
              color: palette.groupCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: palette.separator),
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: adId <= 0
                    ? null
                    : () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => AdDetailScreen(
                              adId: adId,
                              initialAd: ad,
                            ),
                          ),
                        );
                        if (mounted && _state.isLoggedIn) {
                          await _fetchSavedAds();
                        }
                      },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            color: palette.pill,
                            child: AppImage(
                              url: imageUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                          PositionedDirectional(
                            top: 8,
                            end: 8,
                            child: InkWell(
                              key: Key('saved-unsave-$adId'),
                              onTap: busy ? null : () => _removeSaved(ad),
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: busy
                                    ? SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: palette.ink,
                                        ),
                                      )
                                    : Icon(
                                        CupertinoIcons.bookmark_fill,
                                        size: 15,
                                        color: palette.ink,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (price.isNotEmpty)
                            PriceText(
                              price,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: palette.ink,
                              ),
                            ),
                          const SizedBox(height: 3),
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: palette.ink,
                            ),
                          ),
                          if (city.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              city,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: palette.muted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
