import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import 'widgets/price_text.dart';
import 'widgets/ad_card.dart';
import 'widgets/app_image.dart';
import 'widgets/boost_sheet.dart';
import 'widgets/chat_utils.dart';
import 'widgets/kinetic_widgets.dart';
import 'widgets/skeleton_loader.dart';
import 'chat_room_screen.dart';
import 'privacy_compliance_screen.dart';
import 'seller_profile_screen.dart';
import 'store_detail_screen.dart';
import 'auth_screen.dart';

class AdDetailScreen extends StatefulWidget {
  final int adId;
  final Map<String, dynamic>? initialAd;
  final Map<String, dynamic>? initialData;
  final bool openChatOnLoad;

  const AdDetailScreen({
    super.key,
    required this.adId,
    this.initialAd,
    this.initialData,
    this.openChatOnLoad = false,
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
  bool _descExpanded = false;
  bool _openingChat = false;
  bool _savingFavorite = false;

  // Calibrated Apple Whitespace & Brand Palette
  static const Color _ink = Color(0xFF0F172A);
  static const Color _red = Color(0xFFE31B23);
  static const Color _redSoft = Color(0xFFFEECEE);
  static const Color _muted = Color(0xFF64748B);
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
    _state.addListener(_onStateChanged);
    _fetchDetails().then((_) {
      if (mounted && widget.openChatOnLoad && _ad != null) _openInAppChat();
    });
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    _pageCtrl.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _toggleFavorite() async {
    if (_savingFavorite) return;
    if (!_state.isLoggedIn) {
      await Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AuthScreen()));
      return;
    }
    _savingFavorite = true;
    final previous = _state.favoriteAdIds.contains(widget.adId);
    try {
      final result = await _state.toggleFavorite(widget.adId,
          categoryId: _ad == null ? null : _state.extractAdCategoryId(_ad!));
      if (mounted && result == previous) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_state.s.tr('تعذر تحديث المفضلة. حاول مرة أخرى.',
                'Impossible de modifier les favoris. Réessayez.'))));
      }
    } finally {
      _savingFavorite = false;
    }
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

  Future<void> _showCallSheetOrDial(String phone, String sellerName) async {
    HapticFeedback.lightImpact();
    final s = _state.s;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
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
                const SizedBox(height: 22),
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: _redSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.phone_fill,
                    color: _red,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  sellerName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  phone,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: _red,
                    letterSpacing: 0.8,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: PressableScale(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: phone));
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: _ink,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              content: Text(
                                s.tr('تم نسخ رقم الهاتف', 'Numéro copié'),
                              ),
                            ),
                          );
                        },
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
                                CupertinoIcons.doc_on_doc,
                                size: 17,
                                color: _ink,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                s.tr('نسخ الرقم', 'Copier'),
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: _ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PressableScale(
                        onTap: () async {
                          Navigator.pop(ctx);
                          final uri = Uri.parse('tel:$phone');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
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
                                s.tr('اتصال الآن', 'Appeler'),
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openInAppChat({String? presetMessage}) async {
    if (_openingChat) return;
    HapticFeedback.selectionClick();
    if (!_state.isLoggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
      return;
    }

    _openingChat = true;
    final peerName =
        (_ad?['store']?['name'] ?? _ad?['seller']?['name'] ?? 'Apolo Seller')
            .toString();
    final peerAvatar = (_ad?['store']?['logo_url'] ??
            _ad?['seller']?['avatar_url'] ??
            _ad?['seller']?['avatar'])
        ?.toString();
    final adTitle = (_ad?['title'] ?? '').toString();
    final adPrice =
        (_ad?['price_formatted'] ?? '${_ad?['price'] ?? ''} MAD').toString();

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
                peerName: (conv['other_user']?['name'] ?? peerName).toString(),
                adTitle: adTitle,
                peerAvatar: (conv['other_user']?['avatar_url'] ?? peerAvatar)
                    ?.toString(),
                adImage: chatAdImage(_ad),
                adPrice: adPrice,
                initialDraft: presetMessage,
              ),
            ),
          );
          return;
        }
      }
    } catch (_) {
      // Do not invent a conversation identifier when chat creation fails.
    } finally {
      _openingChat = false;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_state.s.tr(
        'تعذر فتح المحادثة. حاول مرة أخرى.',
        'Impossible de démarrer la conversation. Réessayez.',
      ))));
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
                  title: s.tr(
                    'الإبلاغ عن هذا الإعلان أو محتوى AI',
                    'Signaler cette annonce / contenu IA',
                  ),
                  subtitle: s.tr(
                    'مراجعة فورية من فريق الثقة والأمان',
                    'Vérification rapide par notre équipe',
                  ),
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
                    subtitle: s.tr(
                      'إخفاء جميع إعلانات هذا البائع',
                      'Masquer les annonces de ce vendeur',
                    ),
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

    final sellerId = int.tryParse(
            '${seller?['id'] ?? ad['seller_id'] ?? ad['user_id'] ?? ''}') ??
        0;

    final String sellerDisplayName =
        (store?['name'] ?? seller?['name'] ?? 'Apolo Seller').toString();

    final String cityName = ad['city'] is Map
        ? (s.isAr
                ? (ad['city']['name_ar'] ?? ad['city']['name'])
                : (ad['city']['name_fr'] ?? ad['city']['name']))
            .toString()
        : (s.isAr
                ? (ad['city_ar'] ?? ad['city_name'] ?? 'الدار البيضاء')
                : (ad['city_fr'] ?? ad['city_name'] ?? 'Casablanca'))
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
        int.tryParse((ad['views_count'] ?? ad['views'] ?? 0).toString()) ?? 0;

    final rawSpecs = metadata.entries
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
        .map((e) => MapEntry(e.key.toString(), e.value.toString()))
        .toList();

    // Ensure clean structured specs table for easy scanning
    final List<MapEntry<String, String>> structuredSpecs = [
      MapEntry(s.tr('القسم', 'Catégorie'), categoryName),
      MapEntry(s.tr('المدينة', 'Ville'), cityName),
      MapEntry(
        s.tr('الحالة', 'État'),
        (ad['condition'] ??
                metadata['condition'] ??
                s.tr('غير محددة', 'Non précisé'))
            .toString(),
      ),
      MapEntry(
        s.tr('رقم الإعلان', 'Référence'),
        '#AP-${widget.adId}',
      ),
      ...rawSpecs,
    ];

    final String rawDesc = (ad['description'] ?? '').toString().trim();
    final String fullDescription = rawDesc.isEmpty
        ? s.tr(
            'لم يضف البائع وصفاً لهذا الإعلان. تواصل معه لمعرفة التفاصيل.',
            'Le vendeur n’a pas ajouté de description. Contactez-le pour en savoir plus.',
          )
        : rawDesc;

    final quickQuestions = s.isAr
        ? [
            'واش باقي متوفر؟ 👋',
            'شنو هو آخر ثمن؟ 💰',
            'فين نقدر نشوف السلعة؟ 📍',
            'واش ممكن صوره إضافية؟ 📸',
          ]
        : [
            'Toujours disponible ? 👋',
            'Quel est votre dernier prix ? 💰',
            'Où peut-on voir l\'article ? 📍',
            'Plus de photos SVP ? 📸',
          ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Minimalist Top Navigation Bar
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
                  Expanded(
                      child: Container(
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
                        Flexible(
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
                  )),
                  Row(
                    children: [
                      _SoftCircleButton(
                        icon: isFav
                            ? CupertinoIcons.heart_fill
                            : CupertinoIcons.heart,
                        iconColor: isFav ? _red : _ink,
                        onTap: _toggleFavorite,
                      ),
                      const SizedBox(width: 8),
                      _SoftCircleButton(
                        icon: CupertinoIcons.share,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          final shareUrl =
                              ad['share_url'] ?? 'https://apolo.ma';
                          Share.share(
                            '${ad['title']} - $priceFormatted\n$shareUrl',
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      _SoftCircleButton(
                        icon: CupertinoIcons.ellipsis,
                        onTap: () =>
                            _showMoreActionsSheet(s, ad, seller, isOwner),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Ordered, Easy-to-Read Scrollable Body
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 130),
                children: [
                  // A. Studio Hero Gallery Card
                  Container(
                    height: 300,
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
                                  color: Colors.black.withValues(alpha: 0.65),
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
                                        fontFeatures: [
                                          FontFeature.tabularFigures(),
                                        ],
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

                  // Thumbnail Strip
                  if (images.length > 1) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 56,
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
                              width: 56,
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

                  const SizedBox(height: 22),

                  // B. Clear Price + Badges + Title Block
                  ScrollReveal(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PriceText(
                              priceFormatted,
                              style: const TextStyle(
                                fontSize: 31,
                                fontWeight: FontWeight.w900,
                                color: _red,
                                letterSpacing: -0.8,
                                fontFeatures: [FontFeature.tabularFigures()],
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
                        const SizedBox(height: 8),
                        Text(
                          (ad['title'] ?? '').toString(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                            height: 1.3,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // C. 3 Quick-Scan Summary Cards (City, Verified Status, Views)
                  Row(
                    children: [
                      Expanded(
                        child: _QuickSummaryCard(
                          icon: CupertinoIcons.location_solid,
                          iconColor: _red,
                          label: s.tr('المدينة', 'Ville'),
                          value: cityName,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickSummaryCard(
                          icon: CupertinoIcons.checkmark_shield_fill,
                          iconColor: _emerald,
                          label: s.tr('الحالة', 'Statut'),
                          value: s.tr('متوفر الآن', 'Disponible'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickSummaryCard(
                          icon: CupertinoIcons.eye_fill,
                          iconColor: const Color(0xFF3B82F6),
                          label: s.tr('المشاهدات', 'Vues'),
                          value:
                              ad['views_count'] == null && ad['views'] == null
                                  ? '—'
                                  : '$viewsCount',
                        ),
                      ),
                    ],
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

                  const SizedBox(height: 26),

                  // D. Ordered 2-Column Technical Specs Bento Grid
                  _SectionHeader(
                    icon: CupertinoIcons.square_list_fill,
                    title:
                        s.tr('معلومات ومواصفات الإعلان', 'Informations clés'),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.55,
                    ),
                    itemCount: structuredSpecs.length,
                    itemBuilder: (context, idx) {
                      final item = structuredSpecs[idx];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.key,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: _muted,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 26),

                  // E. Easy-to-Read Description Card
                  _SectionHeader(
                    icon: CupertinoIcons.doc_text_fill,
                    title: s.tr('وصف وتفاصيل المنتج', 'Description détaillée'),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullDescription,
                          maxLines: _descExpanded ? 50 : 4,
                          overflow: _descExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.7,
                            color: _ink,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (fullDescription.length > 140) ...[
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _descExpanded = !_descExpanded),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _descExpanded
                                      ? s.tr('عرض أقل', 'Voir moins')
                                      : s.tr(
                                          'قراءة الوصف كامل', 'Lire la suite'),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: _red,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  _descExpanded
                                      ? CupertinoIcons.chevron_up
                                      : CupertinoIcons.chevron_down,
                                  size: 13,
                                  color: _red,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 26),

                  // F. Seller Card + 1-Tap In-App Chat Quick Questions
                  _SectionHeader(
                    icon:
                        CupertinoIcons.person_crop_circle_fill_badge_checkmark,
                    title:
                        s.tr('البائع والتواصل السريع', 'Vendeur & Chat rapide'),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PressableScale(
                          onTap: sellerId <= 0
                              ? null
                              : () {
                                  HapticFeedback.lightImpact();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SellerProfileScreen(
                                        sellerId: sellerId,
                                        sellerName: sellerDisplayName,
                                        sellerAvatar: (store?['logo_url'] ??
                                                seller?['avatar_url'])
                                            ?.toString(),
                                        sellerPhone: phone,
                                        sellerCity: cityName,
                                        isVerified:
                                            seller?['is_verified'] == true,
                                        isOnline: seller?['is_online'] == true,
                                        initialAd: ad,
                                      ),
                                    ),
                                  );
                                },
                          child: Row(
                            children: [
                              AppAvatar(
                                url: (store?['logo_url'] ??
                                        seller?['avatar_url'])
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
                                            sellerDisplayName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 16.5,
                                              fontWeight: FontWeight.w800,
                                              color: _ink,
                                            ),
                                          ),
                                        ),
                                        if (seller?['is_verified'] == true) ...[
                                          const SizedBox(width: 5),
                                          const Icon(
                                            CupertinoIcons.checkmark_seal_fill,
                                            size: 16,
                                            color: _red,
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      store != null
                                          ? s.tr(
                                              'متجر على Apolo',
                                              'Boutique sur Apolo',
                                            )
                                          : s.tr(
                                              'بائع على Apolo',
                                              'Vendeur sur Apolo',
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
                                          subdomain:
                                              store['subdomain'].toString(),
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
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        s.tr('البروفايل', 'Profil'),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: _ink,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        s.isAr
                                            ? CupertinoIcons.chevron_left
                                            : CupertinoIcons.chevron_right,
                                        size: 11,
                                        color: _muted,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (!isOwner) ...[
                          const SizedBox(height: 16),
                          Container(
                            height: 1,
                            color: const Color(0xFFE5E9F0),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            s.tr(
                              'صيفط سؤال سريع فـ شات التطبيق بضغطة وحدة:',
                              'Envoyer une question rapide dans le chat :',
                            ),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: _muted,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: quickQuestions.map((q) {
                              return PressableScale(
                                onTap: () => _openInAppChat(presetMessage: q),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 13,
                                    vertical: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        CupertinoIcons.chat_bubble_2_fill,
                                        size: 13,
                                        color: _red,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        q,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: _ink,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // G. Safety Tip Banner
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.shield_lefthalf_fill,
                          size: 18,
                          color: _emerald,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s.tr(
                              'نصيحة أمان: تواصل عبر شات Apolo وعاين السلعة فـ مكان عام قبل الدفع.',
                              'Conseil sécurité : Discutez sur Apolo et vérifiez l\'article en personne.',
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF166534),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // H. Related Ads Section
                  if (_relatedAds.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _SectionHeader(
                      icon: CupertinoIcons.square_grid_2x2_fill,
                      title: s.tr(
                          'إعلانات مشابهة فـ نفس القسم', 'Annonces similaires'),
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

      // 3. Clean 2-Button Bottom Dock: ONLY Appel (Call) + Chat dyl App (No WhatsApp)
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: _ink.withValues(alpha: 0.06),
                blurRadius: 22,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Button 1: In-App Chat (Primary Dark Ink Pill)
              Expanded(
                child: PressableScale(
                  onTap: () => _openInAppChat(),
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: _ink,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.chat_bubble_2_fill,
                          size: 19,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 9),
                        Text(
                          s.tr('شات التطبيق', 'Chat Apolo'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (phone != null && phone.isNotEmpty) ...[
                const SizedBox(width: 12),
                // Button 2: Direct Phone Call (Vibrant Apolo Red Pill)
                Expanded(
                  child: PressableScale(
                    onTap: () => _showCallSheetOrDial(phone, sellerDisplayName),
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: _red,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: _red.withValues(alpha: 0.25),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            CupertinoIcons.phone_fill,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            s.tr('اتصال هاتفي', 'Appeler'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFE31B23)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

class _QuickSummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _QuickSummaryCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
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
              color: Color(0xFF64748B),
            ),
          ),
        ],
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
                      color: Color(0xFF64748B),
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
