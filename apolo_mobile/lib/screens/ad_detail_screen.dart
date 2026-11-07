import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import 'widgets/ad_card.dart';
import 'widgets/app_image.dart';
import 'widgets/boost_sheet.dart';
import 'widgets/chat_utils.dart';
import 'widgets/skeleton_loader.dart';
import 'chat_room_screen.dart';
import 'privacy_compliance_screen.dart';
import 'store_detail_screen.dart';
import 'auth_screen.dart';

class AdDetailScreen extends StatefulWidget {
  final int adId;
  final Map<String, dynamic>? initialAd;
  final Map<String, dynamic>? initialData;

  const AdDetailScreen({
    super.key,
    required this.adId,
    this.initialAd,
    this.initialData,
  });

  @override
  State<AdDetailScreen> createState() => _AdDetailScreenState();
}

class _AdDetailScreenState extends State<AdDetailScreen> {
  final AppState _state = AppState();
  final PageController _pageCtrl = PageController();
  Map<String, dynamic>? _ad;
  List<dynamic> _relatedAds = [];
  bool _loading = true;
  int _currentImgIndex = 0;

  static const Color _ink = Color(0xFF0F1B2D);
  static const Color _red = Color(0xFFE31B23);
  static const Color _redSoft = Color(0xFFFEECEE);
  static const Color _muted = Color(0xFF8A94A6);
  static const Color _border = Color(0xFFE7EAF0);
  static const Color _surface = Color(0xFFF7F9FC);
  static const Color _emerald = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _ad = widget.initialAd ?? widget.initialData;
    if (_ad != null) {
      final catId = _state.extractAdCategoryId(_ad!);
      _state.recordCategoryInterest(catId, weight: 2);
    }
    _fetchDetails();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchDetails() async {
    try {
      final res = await _state.api.dio.get('/ads/${widget.adId}');
      if (res.data is Map && res.data['status'] == 'success') {
        if (mounted) {
          final loadedAd = res.data['ad'];
          if (loadedAd is Map) {
            final catId = _state.extractAdCategoryId(loadedAd);
            _state.recordCategoryInterest(catId, weight: 2);
          }
          setState(() {
            _ad = loadedAd;
            _relatedAds = res.data['related_ads'] ?? [];
            _loading = false;
          });
        }
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phone, String title) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final intlPhone =
        clean.startsWith('0') ? '212${clean.substring(1)}' : clean;
    final text = Uri.encodeComponent(
      '${_state.s.tr('السلام عليكم، بخصوص إعلانك على Apolo.ma:', 'Bonjour, concernant votre annonce sur Apolo.ma :')} $title',
    );
    final uri = Uri.parse('https://wa.me/$intlPhone?text=$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openInAppChat() async {
    if (!_state.isLoggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
      return;
    }
    try {
      final res = await _state.api.dio
          .post('/chat/start', data: {'ad_id': widget.adId});
      if (res.data is Map && res.data['status'] == 'success') {
        final conv = res.data['conversation'] ?? {};
        final int convId = int.tryParse(conv['id'].toString()) ?? 0;
        if (mounted && convId > 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatRoomScreen(
                conversationId: convId,
                peerName: (conv['other_user']?['name'] ??
                        _ad?['seller']?['name'] ??
                        'Apolo User')
                    .toString(),
                adTitle: (_ad?['title'] ?? '').toString(),
                peerAvatar: (conv['other_user']?['avatar_url'] ??
                        _ad?['seller']?['avatar_url'] ??
                        _ad?['seller']?['avatar'])
                    ?.toString(),
                adImage: chatAdImage(_ad),
                adPrice: (_ad?['price_formatted'] ?? '').toString(),
              ),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _state.s.tr(
                'لا يمكنك مراسلة نفسك أو المستخدم غير متاح',
                'Impossible de démarrer la conversation',
              ),
            ),
          ),
        );
      }
    }
  }

  void _openFullScreenImage(String imgUrl, String caption) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (ctx) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),
        body: Center(
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 4.0,
            child: AppImage(url: imgUrl, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  Future<void> _blockSeller(int sellerId) async {
    if (!_state.isLoggedIn) return;
    try {
      await _state.api.dio
          .post('/users/block', data: {'blocked_user_id': sellerId});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _state.s.tr('تم حظر هذا المستخدم بنجاح', 'Utilisateur bloqué'),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final ad = _ad;
    if (ad == null && _loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: AdDetailSkeleton(),
      );
    }
    if (ad == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: Center(
          child: Text(
            s.tr('الإعلان غير موجود', 'Annonce introuvable'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
        ),
      );
    }

    final List images =
        (ad['images'] is List && (ad['images'] as List).isNotEmpty)
            ? ad['images']
            : (ad['main_image'] != null
                ? [ad['main_image']]
                : (ad['primary_image'] != null ? [ad['primary_image']] : []));
    final bool isFav = _state.favoriteAdIds.contains(widget.adId);
    final Map<String, dynamic> metadata =
        ad['metadata'] is Map ? Map<String, dynamic>.from(ad['metadata']) : {};
    final Map<String, dynamic>? seller =
        ad['seller'] is Map ? Map<String, dynamic>.from(ad['seller']) : null;
    final Map<String, dynamic>? store =
        ad['store'] is Map ? Map<String, dynamic>.from(ad['store']) : null;
    final String? phone =
        (ad['phone_call'] ?? ad['phone_whatsapp'])?.toString();
    final bool isOwner = _state.currentUser != null &&
        seller != null &&
        _state.currentUser!['id'].toString() == seller['id'].toString();

    final String cityName = ad['city'] is Map
        ? (s.isAr
                ? (ad['city']['name_ar'] ?? ad['city']['name'])
                : (ad['city']['name_fr'] ?? ad['city']['name']))
            .toString()
        : (s.isAr
                ? (ad['city_ar'] ?? ad['city_name'] ?? 'المغرب')
                : (ad['city_fr'] ?? ad['city_name'] ?? 'Maroc'))
            .toString();

    final Map<String, dynamic> catMap = ad['category'] is Map
        ? Map<String, dynamic>.from(ad['category'])
        : {'name': ad['category_name'] ?? ad['category_ar'] ?? ''};
    final String categoryName = _state.formatCategoryLabel(catMap);
    final String categoryAsset = _state.assetForCategory(catMap, categoryName);

    final String priceFormatted =
        (ad['price_formatted'] ?? '${ad['price'] ?? ''} MAD').toString();
    final bool isNegotiable =
        ad['negotiable'] == true || metadata['negotiable'] == true;
    final int viewsCount =
        int.tryParse((ad['views_count'] ?? ad['views'] ?? 1).toString()) ?? 1;
    final topInset = MediaQuery.of(context).padding.top;

    final specEntries = metadata.entries
        .where(
          (e) =>
              e.value != null &&
              e.value.toString().isNotEmpty &&
              ![
                'additional_images',
                'negotiable',
                'free',
                'hide_phone',
                'internal_chat',
              ].contains(e.key),
        )
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          // 1. 2026 Immersive Gallery with Fullscreen Zoom & Thumbnail Strip
          SizedBox(
            height: topInset + 310,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                images.isNotEmpty
                    ? PageView.builder(
                        controller: _pageCtrl,
                        itemCount: images.length,
                        onPageChanged: (i) =>
                            setState(() => _currentImgIndex = i),
                        itemBuilder: (_, idx) {
                          final imgUrl = images[idx].toString();
                          return GestureDetector(
                            onTap: () => _openFullScreenImage(
                              imgUrl,
                              (ad['title'] ?? '').toString(),
                            ),
                            child: AppImage(
                              url: imgUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: const Color(0xFF1E293B),
                        child: Center(
                          child: Image.asset(
                            categoryAsset,
                            width: 110,
                            height: 110,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                // Top & Bottom Subtle Gradients
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.35, 0.72, 1.0],
                        colors: [
                          Colors.black.withValues(alpha: 0.38),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                  ),
                ),

                // Floating Top Action Bar
                Positioned(
                  top: topInset + 10,
                  left: 18,
                  right: 18,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CircleGlassButton(
                        icon: s.isAr
                            ? CupertinoIcons.chevron_right
                            : CupertinoIcons.chevron_left,
                        onTap: () => Navigator.pop(context),
                      ),
                      Row(
                        children: [
                          _CircleGlassButton(
                            icon: isFav
                                ? CupertinoIcons.heart_fill
                                : CupertinoIcons.heart,
                            iconColor: isFav ? _red : _ink,
                            onTap: () async {
                              final catId = _state.extractAdCategoryId(ad);
                              await _state.toggleFavorite(
                                widget.adId,
                                categoryId: catId,
                              );
                              if (mounted) setState(() {});
                            },
                          ),
                          const SizedBox(width: 8),
                          _CircleGlassButton(
                            icon: CupertinoIcons.share,
                            onTap: () {
                              final shareUrl =
                                  ad['share_url'] ?? 'https://apolo.ma';
                              Share.share(
                                '${ad['title']} - $priceFormatted\n$shareUrl',
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          _CircleGlassButton(
                            icon: CupertinoIcons.flag,
                            iconColor: _red,
                            onTap: () => showAiContentReportSheet(
                              context,
                              featureContext:
                                  '${s.tr('بلاغ عن إعلان', 'Signalement annonce')}: ${(ad['title'] ?? '').toString()}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Image Counter & Fullscreen Hint Badge
                if (images.isNotEmpty)
                  PositionedDirectional(
                    bottom: 16,
                    end: 18,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.photo_on_rectangle,
                            size: 13,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${_currentImgIndex + 1} / ${images.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Category Pill on Bottom-Start of Cover
                PositionedDirectional(
                  bottom: 16,
                  start: 18,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Image.asset(
                            categoryAsset,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          categoryName,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Interactive Thumbnail Strip if multiple photos exist
          if (images.length > 1)
            SizedBox(
              height: 68,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, idx) {
                  final active = idx == _currentImgIndex;
                  return GestureDetector(
                    onTap: () {
                      _pageCtrl.animateToPage(
                        idx,
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: active ? _red : _border,
                          width: active ? 2.2 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AppImage(
                          url: images[idx].toString(),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // 2. Price, Title & Location Header (2026 Editorial Style)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        priceFormatted,
                        style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                          color: _red,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                    if (isNegotiable)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: _emerald.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.checkmark_seal_fill,
                              size: 13,
                              color: _emerald,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              s.tr('قابل للتفاوض', 'Négociable'),
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: _emerald,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  (ad['title'] ?? '').toString(),
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                    height: 1.25,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.location_solid,
                      size: 15,
                      color: _red,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      cityName,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Icon(
                      CupertinoIcons.eye,
                      size: 15,
                      color: _muted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$viewsCount ${s.tr('مشاهدة', 'vues')}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. 2026 Bento Overview Cards (Category + City + Views)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: _BentoInfoTile(
                    iconWidget: Image.asset(
                      categoryAsset,
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                    ),
                    label: s.tr('القسم', 'Catégorie'),
                    value: categoryName,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _BentoInfoTile(
                    iconWidget: const Icon(
                      CupertinoIcons.placemark_fill,
                      color: _red,
                      size: 20,
                    ),
                    label: s.tr('المدينة', 'Ville'),
                    value: cityName,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _BentoInfoTile(
                    iconWidget: const Icon(
                      CupertinoIcons.chart_bar_alt_fill,
                      color: Color(0xFF3B82F6),
                      size: 20,
                    ),
                    label: s.tr('المشاهدات', 'Vues'),
                    value: '$viewsCount',
                  ),
                ),
              ],
            ),
          ),

          if (isOwner)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.vipGold,
                  foregroundColor: _ink,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => BoostSheet(
                      adId: widget.adId,
                      adTitle: (ad['title'] ?? '').toString(),
                    ),
                  ).then((boosted) {
                    if (boosted == true) _fetchDetails();
                  });
                },
                icon: const Icon(CupertinoIcons.bolt_fill, size: 18),
                label: Text(
                  s.tr('ترقية الإعلان ومضاعفة المشاهدات (Boost ⚡)', 'Booster cette annonce ⚡'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),

          // 4. Technical Specs Grid (if metadata exists)
          if (specEntries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.tr('المواصفات والخصائص', 'Caractéristiques techniques'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _border),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Column(
                      children: specEntries.map((e) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Color(0xFFEAECEF)),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                e.key.toString(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _muted,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  e.value.toString(),
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: _ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

          // 5. Description Card
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.tr('تفاصيل ووصف الإعلان', 'Description détaillée'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _border),
                  ),
                  child: Text(
                    (ad['description'] ?? '').toString().trim().isEmpty
                        ? s.tr(
                            'تواصل مع البائع مباشرة لمعرفة المزيد من التفاصيل.',
                            'Contactez directement le vendeur pour plus d\'informations.',
                          )
                        : (ad['description'] ?? '').toString(),
                    style: const TextStyle(
                      fontSize: 14.5,
                      height: 1.6,
                      color: _ink,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 6. Seller & Store Trust Card
          if (seller != null || store != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _border),
                  boxShadow: [
                    BoxShadow(
                      color: _ink.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        AppAvatar(
                          url: (store?['logo_url'] ?? seller?['avatar_url'])
                              ?.toString(),
                          radius: 26,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      (store?['name'] ??
                                              seller?['name'] ??
                                              'Apolo Seller')
                                          .toString(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w800,
                                        color: _ink,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Icon(
                                    CupertinoIcons.checkmark_seal_fill,
                                    size: 16,
                                    color: _red,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                store != null
                                    ? s.tr(
                                        'متجر احترافي موثق • سريع التجاوب',
                                        'Boutique Pro Vérifiée • Réponse rapide',
                                      )
                                    : s.tr(
                                        'عضو موثق على Apolo.ma',
                                        'Membre vérifié sur Apolo.ma',
                                      ),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: _muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (store != null)
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StoreDetailScreen(
                                    subdomain: store['subdomain'].toString(),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _redSoft,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                s.tr('زيارة المتجر', 'Boutique'),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: _red,
                                ),
                              ),
                            ),
                          )
                        else if (seller != null && !isOwner)
                          IconButton(
                            tooltip: s.blockUser,
                            onPressed: () => _blockSeller(
                              int.tryParse(seller['id'].toString()) ?? 0,
                            ),
                            icon: const Icon(
                              CupertinoIcons.nosign,
                              size: 18,
                              color: _muted,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // 7. Related Ads Section
          if (_relatedAds.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                s.tr('إعلانات مشابهة فـ نفس القسم', 'Annonces similaires'),
                style: const TextStyle(
                  fontSize: 18.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: _ink,
                ),
              ),
            ),
            SizedBox(
              height: 242,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _relatedAds.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (_, idx) => SizedBox(
                  width: 185,
                  child: AdCard(
                    ad: Map<String, dynamic>.from(_relatedAds[idx]),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(top: BorderSide(color: _border)),
            boxShadow: [
              BoxShadow(
                color: _ink.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              if (phone != null && phone.isNotEmpty) ...[
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      onPressed: () => _callPhone(phone),
                      icon: const Icon(CupertinoIcons.phone_fill, size: 17),
                      label: Text(
                        s.callSeller,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 50,
                  width: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const CircleBorder(),
                    ),
                    onPressed: () =>
                        _openWhatsApp(phone, (ad['title'] ?? '').toString()),
                    child: const Icon(
                      CupertinoIcons.chat_bubble_text_fill,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _ink,
                      side: const BorderSide(color: _border, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    onPressed: _openInAppChat,
                    icon: const Icon(
                      CupertinoIcons.chat_bubble_2_fill,
                      size: 17,
                      color: _red,
                    ),
                    label: Text(
                      s.chatInApp,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
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

class _CircleGlassButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _CircleGlassButton({
    required this.icon,
    this.iconColor = const Color(0xFF0F1B2D),
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 19, color: iconColor),
      ),
    );
  }
}

class _BentoInfoTile extends StatelessWidget {
  final Widget iconWidget;
  final String label;
  final String value;

  const _BentoInfoTile({
    required this.iconWidget,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Column(
        children: [
          SizedBox(height: 28, child: Center(child: iconWidget)),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F1B2D),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8A94A6),
            ),
          ),
        ],
      ),
    );
  }
}
