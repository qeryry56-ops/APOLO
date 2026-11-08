import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import 'widgets/ad_card.dart';
import 'widgets/app_image.dart';
import 'widgets/boost_sheet.dart';
import 'widgets/chat_utils.dart';
import 'widgets/kinetic_widgets.dart';
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

  // Apple Whitespace & Brand Tokens
  static const Color _ink = Color(0xFF0F172A);
  static const Color _red = Color(0xFFE31B23);
  static const Color _muted = Color(0xFF8A94A6);
  static const Color _surface = Color(0xFFF5F6F8);
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
    HapticFeedback.lightImpact();
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phone, String title, {String? customMsg}) async {
    HapticFeedback.lightImpact();
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final intlPhone =
        clean.startsWith('0') ? '212${clean.substring(1)}' : clean;
    final prefix = customMsg ??
        _state.s.tr(
          'السلام عليكم، بخصوص إعلانك على Apolo.ma:',
          'Bonjour, concernant votre annonce sur Apolo.ma :',
        );
    final text = Uri.encodeComponent('$prefix $title');
    final uri = Uri.parse('https://wa.me/$intlPhone?text=$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openInAppChat() async {
    HapticFeedback.selectionClick();
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
            behavior: SnackBarBehavior.floating,
            backgroundColor: _ink,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
      barrierColor: Colors.black.withValues(alpha: 0.94),
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
            behavior: SnackBarBehavior.floating,
            backgroundColor: _ink,
            content: Text(
              _state.s.tr('تم حظر هذا المستخدم بنجاح', 'Utilisateur bloqué'),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (_) {}
  }

  void _showMoreActionsSheet(
    AppStrings s,
    Map<String, dynamic> ad,
    Map<String, dynamic>? seller,
    bool isOwner,
  ) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 20),
                _SheetActionRow(
                  icon: CupertinoIcons.flag_fill,
                  iconColor: _red,
                  title: s.tr('الإبلاغ عن هذا الإعلان أو محتوى AI', 'Signaler cette annonce / contenu IA'),
                  subtitle: s.tr('مراجعة فورية من فريق الثقة والأمان', 'Vérification rapide par notre équipe'),
                  onTap: () {
                    Navigator.pop(ctx);
                    showAiContentReportSheet(
                      context,
                      featureContext:
                          '${s.tr('بلاغ عن إعلان', 'Signalement annonce')}: ${(ad['title'] ?? '').toString()}',
                    );
                  },
                ),
                if (seller != null && !isOwner) ...[
                  const SizedBox(height: 10),
                  _SheetActionRow(
                    icon: CupertinoIcons.nosign,
                    iconColor: _ink,
                    title: s.blockUser,
                    subtitle: s.tr('إخفاء جميع إعلانات هذا البائع', 'Masquer les annonces de ce vendeur'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _blockSeller(int.tryParse(seller['id'].toString()) ?? 0);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
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
          child: IllustratedStateView(
            assetPath: 'assets/images/state_empty_ads.png',
            title: s.tr('الإعلان غير متوفر', 'Annonce introuvable'),
            subtitle: s.tr(
              'ربما تم بيع هذا المنتج أو حذفه من طرف البائع.',
              'Cet article a peut-être été vendu ou retiré.',
            ),
            actionLabel: s.tr('العودة للرئيسية', 'Retour'),
            onAction: () => Navigator.pop(context),
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

    final quickQuestions = s.isAr
        ? [
            'واش باقي متوفر؟ 👋',
            'شنو هو آخر ثمن؟ 💰',
            'فين نقدر نشوفو؟ 📍',
          ]
        : [
            'Toujours disponible ? 👋',
            'Quel est votre dernier prix ? 💰',
            'Où peut-on le voir ? 📍',
          ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Minimalist Apple Top Navigation Bar on Pure White
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SoftCircleButton(
                    icon: s.isAr
                        ? CupertinoIcons.chevron_right
                        : CupertinoIcons.chevron_left,
                    onTap: () => Navigator.pop(context),
                  ),
                  // Subtle Category Pill in Center
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: Image.asset(
                            categoryAsset,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 140),
                          child: Text(
                            categoryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _SoftCircleButton(
                        icon: isFav
                            ? CupertinoIcons.heart_fill
                            : CupertinoIcons.heart,
                        iconColor: isFav ? _red : _ink,
                        onTap: () async {
                          HapticFeedback.selectionClick();
                          final catId = _state.extractAdCategoryId(ad);
                          await _state.toggleFavorite(
                            widget.adId,
                            categoryId: catId,
                          );
                          if (mounted) setState(() {});
                        },
                      ),
                      const SizedBox(width: 8),
                      _SoftCircleButton(
                        icon: CupertinoIcons.share,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          final shareUrl = ad['share_url'] ?? 'https://apolo.ma';
                          Share.share(
                            '${ad['title']} - $priceFormatted\n$shareUrl',
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      _SoftCircleButton(
                        icon: CupertinoIcons.ellipsis,
                        onTap: () => _showMoreActionsSheet(s, ad, seller, isOwner),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Scrollable Apple Whitespace Content
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 6, 24, 130),
                children: [
                  // Inset Rounded-28px Studio Gallery Card
                  Container(
                    height: 310,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(28),
                    ),
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
                            : Center(
                                child: Floating3DIllustration(
                                  assetPath: categoryAsset,
                                  size: 135,
                                ),
                              ),

                        // Image counter pill + zoom hint
                        if (images.isNotEmpty)
                          PositionedDirectional(
                            bottom: 14,
                            end: 14,
                            child: GestureDetector(
                              onTap: () => _openFullScreenImage(
                                images[_currentImgIndex].toString(),
                                (ad['title'] ?? '').toString(),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.62),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      CupertinoIcons.fullscreen,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${_currentImgIndex + 1} / ${images.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        fontFeatures: [FontFeature.tabularFigures()],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Interactive Thumbnail Strip if multiple photos exist
                  if (images.length > 1) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 58,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: images.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, idx) {
                          final active = idx == _currentImgIndex;
                          return PressableScale(
                            onTap: () {
                              _pageCtrl.animateToPage(
                                idx,
                                duration: const Duration(milliseconds: 260),
                                curve: Curves.easeOutCubic,
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 58,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: active ? _red : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
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
                  ],

                  const SizedBox(height: 24),

                  // 3. Editorial Price, Negotiable Pill & Title
                  ScrollReveal(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                priceFormatted,
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: _red,
                                  letterSpacing: -0.8,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                            if (isNegotiable)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      CupertinoIcons.checkmark_seal_fill,
                                      size: 13,
                                      color: Color(0xFF15803D),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      s.tr('قابل للتفاوض', 'Négociable'),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF15803D),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          (ad['title'] ?? '').toString(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                            height: 1.28,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Unified Minimalist Metadata Strip (City • Category • Views)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.location_solid,
                                size: 15,
                                color: _red,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                cityName,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: _ink,
                                ),
                              ),
                              Container(
                                width: 4,
                                height: 4,
                                margin: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: const BoxDecoration(
                                  color: _muted,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  categoryName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _muted,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                CupertinoIcons.eye,
                                size: 14,
                                color: _muted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$viewsCount',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: _muted,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Owner Boost Banner if own ad
                  if (isOwner) ...[
                    const SizedBox(height: 18),
                    PressableScale(
                      onTap: () {
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              CupertinoIcons.bolt_fill,
                              color: Color(0xFFD97706),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                s.tr(
                                  'ترقية الإعلان ومضاعفة المشاهدات (Boost ⚡)',
                                  'Booster cette annonce ⚡',
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: _ink,
                                ),
                              ),
                            ),
                            Icon(
                              s.isAr
                                  ? CupertinoIcons.chevron_left
                                  : CupertinoIcons.chevron_right,
                              size: 16,
                              color: _ink,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // 4. Technical Specs Pills (if metadata exists)
                  if (specEntries.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Text(
                      s.tr('المواصفات', 'Caractéristiques'),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 6,
                      ),
                      child: Column(
                        children: specEntries.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final e = entry.value;
                          final isLast = idx == specEntries.length - 1;
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              border: isLast
                                  ? null
                                  : const Border(
                                      bottom: BorderSide(
                                        color: Color(0xFFE8ECF2),
                                        width: 0.8,
                                      ),
                                    ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  e.key.toString(),
                                  style: const TextStyle(
                                    fontSize: 13.5,
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

                  // 5. Clean Editorial Description (Generous Line Height)
                  const SizedBox(height: 28),
                  Text(
                    s.tr('تفاصيل الإعلان', 'Description'),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    (ad['description'] ?? '').toString().trim().isEmpty
                        ? s.tr(
                            'متوفر بحالة ممتازة على Apolo.ma. تواصل مع البائع مباشرة عبر واتساب أو المحادثة لمعرفة المزيد من التفاصيل.',
                            'Disponible en très bon état sur Apolo.ma. Contactez directement le vendeur pour plus d\'informations.',
                          )
                        : (ad['description'] ?? '').toString(),
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.65,
                      color: Color(0xFF334155),
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  // 6. Quick 1-Tap Buyer Questions (Boosts Conversion)
                  if (!isOwner) ...[
                    const SizedBox(height: 26),
                    Text(
                      s.tr('سؤال سريع للبائع بضغطة وحدة', 'Question rapide en 1 clic'),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: quickQuestions.map((q) {
                        return PressableScale(
                          onTap: () {
                            if (phone != null && phone.isNotEmpty) {
                              _openWhatsApp(
                                phone,
                                (ad['title'] ?? '').toString(),
                                customMsg: q,
                              );
                            } else {
                              _openInAppChat();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: _surface,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              q,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _ink,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // 7. Minimalist Seller & Store Profile Card
                  if (seller != null || store != null) ...[
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
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
                                          fontSize: 16,
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
                            PressableScale(
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
                                  horizontal: 14,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  s.tr('المتجر', 'Boutique'),
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: _red,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],

                  // 8. Safe Deal Tip Pill
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.shield_lefthalf_fill,
                          size: 17,
                          color: _emerald,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s.tr(
                              'نصيحة أمان: عاين السلعة فـ مكان عام وما تصيفطش تسبيق قبل ما تشوفها.',
                              'Conseil sécurité : Vérifiez l\'article en personne avant tout paiement.',
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              color: _muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 9. Related Ads Section
                  if (_relatedAds.isNotEmpty) ...[
                    const SizedBox(height: 30),
                    Text(
                      s.tr('إعلانات مشابهة فـ نفس القسم', 'Annonces similaires'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 242,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
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
            ),
          ],
        ),
      ),

      // 10. Floating Apple Action Dock (WhatsApp + Call + In-App Chat)
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: _ink.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Row(
            children: [
              if (phone != null && phone.isNotEmpty) ...[
                // Primary Call Button
                Expanded(
                  flex: 5,
                  child: PressableScale(
                    onTap: () => _callPhone(phone),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: _red,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            CupertinoIcons.phone_fill,
                            size: 17,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            s.callSeller,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Direct WhatsApp Pill
                PressableScale(
                  onTap: () =>
                      _openWhatsApp(phone, (ad['title'] ?? '').toString()),
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.chat_bubble_text_fill,
                          size: 19,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'WhatsApp',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              // In-App Chat Button
              Expanded(
                flex: phone != null && phone.isNotEmpty ? 4 : 10,
                child: PressableScale(
                  onTap: _openInAppChat,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.chat_bubble_2_fill,
                          size: 17,
                          color: _ink,
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            s.chatInApp,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
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

class _SoftCircleButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _SoftCircleButton({
    required this.icon,
    this.iconColor = const Color(0xFF0F172A),
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0xFFF5F6F8),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }
}

class _SheetActionRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetActionRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6F8),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8A94A6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
