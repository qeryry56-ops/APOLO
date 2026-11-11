import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../core/state/app_state.dart';
import 'ad_detail_screen.dart';
import 'auth_screen.dart';
import 'seller_profile_screen.dart';
import 'widgets/app_image.dart';
import 'widgets/price_text.dart';

/// Photo-first discovery. Every action maps to a real listing or account flow.
class AdReelsScreen extends StatefulWidget {
  final int initialIndex;
  const AdReelsScreen({super.key, this.initialIndex = 0});

  @override
  State<AdReelsScreen> createState() => _AdReelsScreenState();
}

class _AdReelsScreenState extends State<AdReelsScreen> {
  final AppState _state = AppState();
  final PageController _pageController = PageController(keepPage: false);
  final Set<int> _pendingFavorites = {};
  List<Map<String, dynamic>> _ads = [];
  bool _loading = true;
  bool _failed = false;
  bool _initialPageApplied = false;
  int _filter = 0;
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChanged);
    _load();
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  List<Map<String, dynamic>> get _filtered {
    final ads = _ads
        .where((ad) =>
            _filter != 2 || ad['is_vip'] == true || ad['is_featured'] == true)
        .toList();
    if (_filter == 1) {
      ads.sort((a, b) => _id(b['id']).compareTo(_id(a['id'])));
    }
    return ads;
  }

  static int _id(dynamic value) => int.tryParse('$value') ?? 0;

  static List<String> _images(Map<String, dynamic> ad) {
    final source = ad['images'] ?? ad['photos'] ?? ad['gallery'];
    final images = source is List
        ? source
            .map((image) => image is Map
                ? '${image['url'] ?? image['image_url'] ?? ''}'
                : '$image')
            .where((image) => image.trim().isNotEmpty)
            .toList()
        : <String>[];
    if (images.isNotEmpty) return images;
    final main = ad['main_image'] ?? ad['primary_image'] ?? ad['image_url'];
    return main == null || '$main'.isEmpty ? [] : ['$main'];
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _failed = false;
      });
    }
    try {
      final response =
          await _state.api.dio.get('/ads', queryParameters: {'per_page': 30});
      if (response.data is! Map ||
          response.data['status'] != 'success' ||
          response.data['data'] is! List) {
        throw const FormatException('Invalid ads response');
      }
      final ads = (response.data['data'] as List)
          .whereType<Map>()
          .map((ad) => Map<String, dynamic>.from(ad))
          .where((ad) => _id(ad['id']) > 0 && _images(ad).isNotEmpty)
          .toList();
      if (!mounted) return;
      setState(() {
        _ads = ads;
        _loading = false;
        _revision++;
      });
      final page = !_initialPageApplied && _filtered.isNotEmpty
          ? widget.initialIndex.clamp(0, _filtered.length - 1)
          : 0;
      _initialPageApplied = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(page);
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  void _selectFilter(int filter) {
    if (_filter == filter) return;
    setState(() {
      _filter = filter;
      _revision++;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageController.hasClients) _pageController.jumpToPage(0);
    });
  }

  Future<void> _favorite(Map<String, dynamic> ad,
      {bool likeOnly = false}) async {
    final id = _id(ad['id']);
    if (_pendingFavorites.contains(id)) return;
    if (!_state.isLoggedIn) {
      await Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AuthScreen()));
      return;
    }
    final previous = _state.favoriteAdIds.contains(id);
    if (likeOnly && previous) return;
    setState(() => _pendingFavorites.add(id));
    try {
      final result = await _state.toggleFavorite(id,
          categoryId: _state.extractAdCategoryId(ad));
      if (!mounted) return;
      if (result == previous) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_state.s.tr('تعذر تحديث المفضلة. حاول مرة أخرى.',
                'Impossible de modifier les favoris. Réessayez.'))));
      } else {
        HapticFeedback.selectionClick();
      }
    } finally {
      if (mounted) setState(() => _pendingFavorites.remove(id));
    }
  }

  void _detail(Map<String, dynamic> ad, {bool contact = false}) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => AdDetailScreen(
                  adId: _id(ad['id']),
                  initialAd: ad,
                  openChatOnLoad: contact,
                )));
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final ads = _filtered;
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Column(children: [
          SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 12, 8),
                child: Row(children: [
                  IconButton(
                    tooltip: s.tr('رجوع', 'Retour'),
                    onPressed: () => Navigator.maybePop(context),
                    icon: const BackButtonIcon(),
                    color: Colors.white,
                  ),
                  Expanded(
                      child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                        children: List.generate(
                            3,
                            (index) => Padding(
                                  padding:
                                      const EdgeInsetsDirectional.only(end: 8),
                                  child: ChoiceChip(
                                    label: Text([
                                      s.tr('الكل', 'Tout'),
                                      s.tr('الأحدث', 'Récents'),
                                      'VIP'
                                    ][index]),
                                    selected: _filter == index,
                                    onSelected: (_) => _selectFilter(index),
                                    showCheckmark: false,
                                    selectedColor: Colors.white,
                                    backgroundColor: const Color(0xFF1E293B),
                                    labelStyle: TextStyle(
                                        color: _filter == index
                                            ? const Color(0xFF0B1220)
                                            : Colors.white),
                                    side: BorderSide.none,
                                  ),
                                ))),
                  )),
                  IconButton(
                      tooltip: s.tr('تحديث', 'Actualiser'),
                      onPressed: _loading ? null : _load,
                      icon: const Icon(CupertinoIcons.refresh),
                      color: Colors.white),
                ]),
              )),
          Expanded(
              child: _loading
                  ? const Center(
                      child: CupertinoActivityIndicator(color: Colors.white))
                  : _failed || ads.isEmpty
                      ? Center(
                          child: SingleChildScrollView(
                              child: Padding(
                          padding: const EdgeInsets.all(24),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(
                                _failed
                                    ? CupertinoIcons.wifi_exclamationmark
                                    : CupertinoIcons.photo_on_rectangle,
                                size: 48,
                                color: Colors.white54),
                            const SizedBox(height: 16),
                            Text(
                                _failed
                                    ? s.tr('تعذر تحميل الإعلانات',
                                        'Impossible de charger les annonces')
                                    : s.tr('لا توجد إعلانات في هذا التبويب',
                                        'Aucune annonce dans cet onglet'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            Text(
                                _failed
                                    ? s.tr('تحقق من الاتصال وحاول مرة أخرى.',
                                        'Vérifiez votre connexion et réessayez.')
                                    : s.tr(
                                        'اختر تبويباً آخر أو حدّث الإعلانات.',
                                        'Choisissez un autre onglet ou actualisez.'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 20),
                            FilledButton(
                                onPressed: _load,
                                child: Text(_failed
                                    ? s.tr('إعادة المحاولة', 'Réessayer')
                                    : s.tr('تحديث', 'Actualiser'))),
                          ]),
                        )))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: PageView.builder(
                            key: ValueKey('$_filter-$_revision'),
                            controller: _pageController,
                            scrollDirection: Axis.vertical,
                            physics: const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics()),
                            itemCount: ads.length,
                            itemBuilder: (context, index) {
                              final ad = ads[index];
                              final seller = ad['seller'] is Map
                                  ? ad['seller'] as Map
                                  : const {};
                              final sellerId = _id(seller['id'] ??
                                  ad['seller_id'] ??
                                  ad['user_id']);
                              return _ReelCard(
                                key:
                                    ValueKey('$_filter-$_revision-${ad['id']}'),
                                ad: ad,
                                images: _images(ad),
                                isLiked: _state.favoriteAdIds
                                    .contains(_id(ad['id'])),
                                isSaving:
                                    _pendingFavorites.contains(_id(ad['id'])),
                                onFavorite: () => _favorite(ad),
                                onDoubleTap: () =>
                                    _favorite(ad, likeOnly: true),
                                onDetails: () => _detail(ad),
                                onContact: () => _detail(ad, contact: true),
                                onSeller: sellerId <= 0
                                    ? null
                                    : () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => SellerProfileScreen(
                                                  sellerId: sellerId,
                                                  sellerName:
                                                      '${seller['name'] ?? s.tr('بائع', 'Vendeur')}',
                                                  sellerAvatar:
                                                      seller['avatar_url']
                                                          ?.toString(),
                                                  sellerPhone:
                                                      (ad['phone_call'] ??
                                                              seller['phone'])
                                                          ?.toString(),
                                                  isVerified:
                                                      seller['is_verified'] ==
                                                          true,
                                                  isOnline:
                                                      seller['is_online'] ==
                                                          true,
                                                  initialAd: ad,
                                                ))),
                              );
                            },
                          ),
                        )),
        ]),
      ),
    );
  }
}

class _ReelCard extends StatefulWidget {
  final Map<String, dynamic> ad;
  final List<String> images;
  final bool isLiked;
  final bool isSaving;
  final VoidCallback onFavorite;
  final VoidCallback onDoubleTap;
  final VoidCallback onDetails;
  final VoidCallback onContact;
  final VoidCallback? onSeller;

  const _ReelCard(
      {super.key,
      required this.ad,
      required this.images,
      required this.isLiked,
      required this.isSaving,
      required this.onFavorite,
      required this.onDoubleTap,
      required this.onDetails,
      required this.onContact,
      this.onSeller});

  @override
  State<_ReelCard> createState() => _ReelCardState();
}

class _ReelCardState extends State<_ReelCard> {
  final PageController _photos = PageController(keepPage: false);
  int _photo = 0;
  bool _showInfo = true;

  @override
  void dispose() {
    _photos.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState().s;
    final ad = widget.ad;
    final seller = ad['seller'] is Map ? ad['seller'] as Map : const {};
    final city = ad['city'] is Map ? ad['city'] as Map : const {};
    final cityName =
        '${city[s.isAr ? 'name_ar' : 'name_fr'] ?? city['name'] ?? ad['city_name'] ?? ''}';
    final price =
        '${ad['price_formatted'] ?? (ad['price'] != null ? '${ad['price']} DH' : '')}';
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(fit: StackFit.expand, children: [
        AppImage(url: widget.images[_photo], fit: BoxFit.cover),
        ClipRect(
            child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child:
                    ColoredBox(color: Colors.black.withValues(alpha: 0.65)))),
        GestureDetector(
          onTap: () => setState(() => _showInfo = !_showInfo),
          onDoubleTap: widget.onDoubleTap,
          child: PageView.builder(
            controller: _photos,
            itemCount: widget.images.length,
            onPageChanged: (index) => setState(() => _photo = index),
            itemBuilder: (_, index) =>
                AppImage(url: widget.images[index], fit: BoxFit.contain),
          ),
        ),
        if (widget.images.length > 1)
          PositionedDirectional(
              top: 12,
              end: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20)),
                child: Text('${_photo + 1} / ${widget.images.length}',
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(color: Colors.white)),
              )),
        if (_showInfo)
          Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Container(
                  constraints:
                      BoxConstraints(maxHeight: constraints.maxHeight * 0.65),
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: const Color(0xFF0B1220).withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20)),
                  child: SingleChildScrollView(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(children: [
                        Expanded(
                            child: TextButton(
                          onPressed: widget.onSeller,
                          style: TextButton.styleFrom(
                              alignment: AlignmentDirectional.centerStart,
                              padding: EdgeInsets.zero,
                              foregroundColor: Colors.white70,
                              disabledForegroundColor: Colors.white70),
                          child: Text(
                              '${seller['name'] ?? s.tr('بائع', 'Vendeur')}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        )),
                        IconButton(
                            tooltip: s.tr('المفضلة', 'Favoris'),
                            onPressed:
                                widget.isSaving ? null : widget.onFavorite,
                            icon: Icon(
                                widget.isLiked
                                    ? CupertinoIcons.heart_fill
                                    : CupertinoIcons.heart,
                                color: widget.isLiked
                                    ? const Color(0xFFE31B23)
                                    : Colors.white)),
                        IconButton(
                            tooltip: s.tr('مشاركة', 'Partager'),
                            onPressed: () => Share.share(
                                '${ad['title']}\n$price\nhttps://apolo.ma/ads/${ad['id']}'),
                            icon: const Icon(CupertinoIcons.share,
                                color: Colors.white)),
                      ]),
                      Text('${ad['title'] ?? ''}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      if (price.isNotEmpty)
                        PriceText(price,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.w800)),
                      if (cityName.isNotEmpty)
                        Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(cityName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white70))),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(
                            child: FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFE31B23),
                              foregroundColor: Colors.white),
                          onPressed: widget.onDetails,
                          child: Text(s.tr('التفاصيل', 'Détails'),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        )),
                        const SizedBox(width: 8),
                        Expanded(
                            child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white),
                          onPressed: widget.onContact,
                          child: Text(s.tr('رسالة', 'Message'),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        )),
                      ]),
                    ],
                  )),
                ),
              )),
      ]);
    });
  }
}
