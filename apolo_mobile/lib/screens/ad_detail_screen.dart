import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import '../theme/app_typography.dart';
import 'widgets/price_text.dart';
import 'widgets/ad_card.dart';
import 'widgets/app_image.dart';
import 'widgets/boost_sheet.dart';
import 'widgets/chat_utils.dart';
import 'widgets/kinetic_widgets.dart';
import 'widgets/skeleton_loader.dart';
import 'chat_room_screen.dart';
import 'privacy_compliance_screen.dart';
import 'search_screen.dart';
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
  final TextEditingController _quickMsgCtrl = TextEditingController();
  Map<String, dynamic>? _ad;
  List<dynamic> _relatedAds = [];
  bool _loading = true;
  int _currentImgIndex = 0;
  bool _descExpanded = false;
  bool _openingChat = false;
  bool _savingFavorite = false;
  bool _alertEnabled = false;
  bool _followingSeller = false;
  bool _hiddenListing = false;

  // Calibrated Apple / Marketplace Light Tokens
  static const Color _ink = Color(0xFF050505);
  static const Color _red = Color(0xFFE31B23);
  static const Color _redSoft = Color(0xFFFEECEE);
  static const Color _surface = Color(0xFFF0F2F5);
  static const Color _pillGrey = Color(0xFFE4E6EB);
  static const Color _fbBlue = Color(0xFF0866FF);
  static const Color _fbBlueSoft = Color(0xFFE7F3FF);
  static const Color _mutedText = Color(0xFF65676B);
  static const Color _starOrange = Color(0xFFE87A24);

  @override
  void initState() {
    super.initState();
    _ad = widget.initialAd ?? widget.initialData;
    _quickMsgCtrl.text = _state.s.tr(
      'مرحباً، هل هذا الإعلان ما زال متوفراً؟',
      'Cet article est-il toujours disponible ?',
      'Hi, is this still available?',
    );
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
    _quickMsgCtrl.dispose();
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
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: _red,
                    letterSpacing:
                        AppTypography.trackingForContext(context, 0.8),
                    fontFeatures: const [FontFeature.tabularFigures()],
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

  Future<void> _openVideoTour(String? videoUrl, List<String> images, String title) async {
    HapticFeedback.lightImpact();
    final trimmed = (videoUrl ?? '').trim();
    if (trimmed.isNotEmpty) {
      final uri = Uri.tryParse(trimmed);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      }
    }
    if (!mounted) return;
    if (images.isNotEmpty) {
      _openFullScreenImage(images[_currentImgIndex.clamp(0, images.length - 1)], title);
    }
  }

  void _showContactOptionsSheet(
    AppStrings s,
    String sellerDisplayName,
    String? phone,
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
                const SizedBox(height: 18),
                _SheetActionRow(
                  icon: CupertinoIcons.chat_bubble_2_fill,
                  iconColor: const Color(0xFF4A4EED),
                  title: s.tr('محادثة فورية عبر Apolo', 'Message sur Apolo'),
                  subtitle: s.tr(
                    'تواصل مباشرة مع $sellerDisplayName داخل التطبيق',
                    'Discuter directement avec $sellerDisplayName',
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openInAppChat();
                  },
                ),
                if (phone != null && phone.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _SheetActionRow(
                    icon: CupertinoIcons.phone_fill,
                    iconColor: _red,
                    title: s.tr('اتصال هاتفي مباشر', 'Appeler $sellerDisplayName'),
                    subtitle: phone,
                    onTap: () {
                      Navigator.pop(ctx);
                      _showCallSheetOrDial(phone, sellerDisplayName);
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

  List<String> _extractImages(Map<String, dynamic> ad) {
    final urls = <String>[];
    void addUrl(dynamic candidate) {
      final cleaned = (candidate ?? '').toString().trim();
      if (cleaned.isNotEmpty && !urls.contains(cleaned)) {
        urls.add(cleaned);
      }
    }

    for (final key in ['images', 'gallery']) {
      final raw = ad[key];
      if (raw is List) {
        for (final item in raw) {
          if (item is String) {
            addUrl(item);
          } else if (item is Map) {
            addUrl(item['image_url'] ?? item['url'] ?? item['path']);
          }
        }
      }
    }
    addUrl(ad['main_image']);
    addUrl(ad['primary_image']);
    addUrl(ad['image_url']);
    return urls;
  }

  String _initialsFromName(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'AP';
    if (parts.length == 1) {
      final word = parts.first;
      return word.length >= 2
          ? word.substring(0, 2).toUpperCase()
          : word.toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final ad = _ad;
    if (ad == null && _loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: AdDetailSkeleton(),
      );
    }
    if (ad == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F9FA),
          elevation: 0,
        ),
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

    final images = _extractImages(ad);
    final bool isFav = _state.favoriteAdIds.contains(widget.adId) ||
        ad['is_favorite'] == true ||
        ad['isFavorite'] == true;
    final Map<String, dynamic> metadata =
        ad['metadata'] is Map ? Map<String, dynamic>.from(ad['metadata']) : {};
    final Map<String, dynamic>? seller =
        ad['seller'] is Map ? Map<String, dynamic>.from(ad['seller']) : null;
    final Map<String, dynamic>? store =
        ad['store'] is Map ? Map<String, dynamic>.from(ad['store']) : null;
    final String? phone =
        (ad['phone_call'] ?? ad['phone_whatsapp'])?.toString().trim();
    final bool isOwner = _state.currentUser != null &&
        seller != null &&
        _state.currentUser!['id'].toString() == seller['id'].toString();
    final int sellerId = int.tryParse(
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

    final String locationSubtitle = (ad['location_display'] ??
            ad['location'] ??
            '')
        .toString()
        .trim()
        .isNotEmpty
        ? (ad['location_display'] ?? ad['location']).toString().trim()
        : cityName;

    final Map<String, dynamic> catMap = ad['category'] is Map
        ? Map<String, dynamic>.from(ad['category'])
        : {'name': ad['category_name'] ?? ad['category_ar'] ?? ''};
    final String categoryName = _state.formatCategoryLabel(catMap);
    final String categoryAsset = _state.assetForCategory(catMap, categoryName);
    final String heroTypeTag = (ad['badge_label'] ??
            ad['property_type'] ??
            ad['type_label'] ??
            '')
        .toString()
        .trim()
        .isNotEmpty
        ? (ad['badge_label'] ?? ad['property_type'] ?? ad['type_label'])
            .toString()
            .trim()
        : categoryName;

    final bool isNegotiable =
        ad['negotiable'] == true || ad['is_negotiable'] == true || metadata['negotiable'] == true;
    final int viewsCount =
        int.tryParse((ad['views_count'] ?? ad['views'] ?? 0).toString()) ?? 0;

    final bool isStayListing = ad.containsKey('nightly_price_display') ||
        ad.containsKey('price_unit') ||
        ad.containsKey('guests') ||
        ad.containsKey('bedrooms') ||
        ad.containsKey('total_price_display') ||
        ad['quick_specs'] is List;

    final String priceFormatted = _resolveHeaderPrice(ad, s, isStayListing);
    final String priceFrequency = _resolvePriceFrequency(
      ad,
      s,
      isStayListing,
      isNegotiable,
    );

    final rawSpecs = metadata.entries
        .where(
          (e) =>
              e.value != null &&
              e.value.toString().trim().isNotEmpty &&
              ![
                'additional_images',
                'negotiable',
                'free',
                'hide_phone',
                'internal_chat',
                'video_url',
                'video_duration',
              ].contains(e.key),
        )
        .map((e) => MapEntry(e.key.toString(), e.value.toString()))
        .toList();

    final List<({String value, String label})> quickSpecCards =
        _buildQuickSpecCards(ad, s, isStayListing, viewsCount, cityName, metadata, rawSpecs);

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
      MapEntry(s.tr('رقم الإعلان', 'Référence'), '#AP-${widget.adId}'),
      ...rawSpecs,
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: ListView(
          scrollCacheExtent: const ScrollCacheExtent.pixels(700),
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            // 1. Hero Image Card (UNTOUCHED per user instruction)
            _buildHeroImageCard(
              s: s,
              ad: ad,
              images: images,
              isFav: isFav,
              categoryAsset: categoryAsset,
              heroTypeTag: heroTypeTag,
              viewsCount: viewsCount,
              isNegotiable: isNegotiable,
              metadata: metadata,
              priceFormatted: priceFormatted,
            ),

            // 2. Title, Price & "Just listed" Header
            _buildMarketplaceHeader(
              s: s,
              ad: ad,
              title: (ad['title'] ?? '').toString(),
              locationSubtitle: locationSubtitle,
              priceFormatted: priceFormatted,
              priceFrequency: priceFrequency,
            ),

            // Optional compact gallery thumbnails when multiple images exist
            if (images.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: SizedBox(
                  height: 52,
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
                          width: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: active ? _fbBlue : const Color(0xFFE5E7EB),
                              width: active ? 2 : 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: images[idx].startsWith('assets/')
                                ? Image.asset(images[idx], fit: BoxFit.cover)
                                : AppImage(url: images[idx], fit: BoxFit.cover),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // 3. Inline "Message seller" Card (or Boost banner for Owner)
            _buildMessageSellerCard(
              s: s,
              ad: ad,
              isOwner: isOwner,
            ),

            // 4. 4 Circular Quick Action Buttons (Alerts, Message, Share, Save)
            _buildQuickActionCircleRow(
              s: s,
              ad: ad,
              isFav: isFav,
              priceFormatted: priceFormatted,
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
            ),

            // 5. Description + Key Specs + Optional Direct Phone Row
            _buildDescriptionSection(
              s: s,
              ad: ad,
              quickSpecCards: quickSpecCards,
              rawSpecs: rawSpecs,
              structuredSpecs: structuredSpecs,
              isOwner: isOwner,
              phone: phone,
              sellerDisplayName: sellerDisplayName,
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
            ),

            // 6. Seller Header ("Seller >" + "See reviews") + Profile + Follow
            _buildSellerSection(
              s: s,
              ad: ad,
              seller: seller,
              store: store,
              sellerId: sellerId,
              sellerDisplayName: sellerDisplayName,
              cityName: cityName,
              phone: phone,
              isOwner: isOwner,
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
            ),

            // 7. Approximate Location Map Preview
            _buildLocationSection(
              s: s,
              cityName: cityName,
              locationSubtitle: locationSubtitle,
            ),

            // 8. Related Searches Chips
            _buildRelatedSearchesSection(
              s: s,
              ad: ad,
              categoryName: categoryName,
              cityName: cityName,
            ),

            // 9. Hide Listing & Safety Footer Card
            _buildHideListingCard(
              s: s,
              ad: ad,
              seller: seller,
              isOwner: isOwner,
            ),

            // 10. Related Ads Strip (when present)
            if (_relatedAds.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                child: _SectionHeader(
                  icon: CupertinoIcons.square_grid_2x2_fill,
                  title:
                      s.tr('إعلانات مشابهة فـ نفس القسم', 'Annonces similaires'),
                ),
              ),
              SizedBox(
                height: 242,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
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
      bottomNavigationBar: _buildStickyBottomBar(
        s: s,
        ad: ad,
        isOwner: isOwner,
        isStayListing: isStayListing,
        isNegotiable: isNegotiable,
        cityName: cityName,
        fallbackPrice: priceFormatted,
        sellerDisplayName: sellerDisplayName,
        phone: phone,
      ),
    );
  }

  String _resolveHeaderPrice(
    Map<String, dynamic> ad,
    AppStrings s,
    bool isStayListing,
  ) {
    final explicitNightly =
        (ad['nightly_price_display'] ?? ad['price_display'] ?? '')
            .toString()
            .trim();
    if (explicitNightly.isNotEmpty) return explicitNightly;

    final formatted = (ad['price_formatted'] ?? '').toString().trim();
    if (formatted.isNotEmpty) return formatted;

    if (ad['is_free'] == true) {
      return s.tr('مجاني', 'Gratuit', 'Free');
    }

    final rawPrice = ad['price'];
    final numVal = double.tryParse((rawPrice ?? '').toString());
    if (numVal != null && numVal > 0) {
      final intVal = numVal.round();
      final currency = (ad['currency_symbol'] ?? (isStayListing ? '\$' : 'DH'))
          .toString()
          .trim();
      return currency == '\$' ? '\$$intVal' : '$intVal $currency';
    }
    return s.tr('عند الطلب', 'Sur demande', 'On request');
  }

  String _resolvePriceFrequency(
    Map<String, dynamic> ad,
    AppStrings s,
    bool isStayListing,
    bool isNegotiable,
  ) {
    final explicitFreq =
        (ad['price_frequency'] ?? ad['price_unit'] ?? '').toString().trim();
    if (explicitFreq.isNotEmpty) return explicitFreq;
    if (isStayListing) return 'per night';
    if (isNegotiable) return s.tr('قابل للتفاوض', 'Négociable', 'Negotiable');
    return s.tr('السعر المعلن', 'Prix affiché', 'Fixed price');
  }

  List<({String value, String label})> _buildQuickSpecCards(
    Map<String, dynamic> ad,
    AppStrings s,
    bool isStayListing,
    int viewsCount,
    String cityName,
    Map<String, dynamic> metadata,
    List<MapEntry<String, String>> rawSpecs,
  ) {
    if (ad['quick_specs'] is List) {
      final custom = (ad['quick_specs'] as List)
          .whereType<Map>()
          .take(4)
          .map((m) => (
                value: (m['value'] ?? '—').toString(),
                label: (m['label'] ?? '').toString(),
              ))
          .toList();
      if (custom.length == 4) return custom;
    }

    if (isStayListing) {
      return [
        (
          value: (ad['guests'] ?? 6).toString(),
          label: s.tr('ضيوف', 'Voyageurs', 'Guests'),
        ),
        (
          value: (ad['bedrooms'] ?? 3).toString(),
          label: s.tr('غرف', 'Chambres', 'Bedrooms'),
        ),
        (
          value: (ad['beds'] ?? 4).toString(),
          label: s.tr('أسرّة', 'Lits', 'Beds'),
        ),
        (
          value: (ad['baths'] ?? 2).toString(),
          label: s.tr('حمامات', 'Bains', 'Baths'),
        ),
      ];
    }

    final conditionVal =
        (ad['condition'] ?? metadata['condition'] ?? s.tr('جيد', 'Bon', 'Good'))
            .toString()
            .trim();
    final thirdSpec = rawSpecs.isNotEmpty
        ? (value: rawSpecs[0].value, label: rawSpecs[0].key)
        : (value: cityName, label: s.tr('المدينة', 'Ville', 'City'));
    final fourthSpec = rawSpecs.length > 1
        ? (value: rawSpecs[1].value, label: rawSpecs[1].key)
        : (value: '#${widget.adId}', label: s.tr('المرجع', 'Réf.', 'Ref'));

    return [
      (value: conditionVal, label: s.tr('الحالة', 'État', 'Condition')),
      (
        value: ad['views_count'] == null && ad['views'] == null
            ? '—'
            : '$viewsCount',
        label: s.tr('مشاهدة', 'Vues', 'Views'),
      ),
      thirdSpec,
      fourthSpec,
    ];
  }

  Widget _buildHeroImageCard({
    required AppStrings s,
    required Map<String, dynamic> ad,
    required List<String> images,
    required bool isFav,
    required String categoryAsset,
    required String heroTypeTag,
    required int viewsCount,
    required bool isNegotiable,
    required Map<String, dynamic> metadata,
    required String priceFormatted,
  }) {
    final String videoUrl =
        (ad['video_url'] ?? metadata['video_url'] ?? ad['video'] ?? '')
            .toString()
            .trim();
    final String videoDuration =
        (ad['video_duration'] ?? metadata['video_duration'] ?? '')
            .toString()
            .trim();
    final bool showVideoTour =
        videoUrl.isNotEmpty || ad['has_video'] == true || videoDuration.isNotEmpty;

    final String ratingRaw =
        (ad['rating'] ?? ad['stars'] ?? '').toString().trim();
    final String reviewsOrViews =
        (ad['reviews_count'] ?? ad['review_count'] ?? '').toString().trim();
    final String ratingPillLabel = ratingRaw.isNotEmpty
        ? (reviewsOrViews.isNotEmpty
            ? '$ratingRaw · $reviewsOrViews'
            : (viewsCount > 0 ? '$ratingRaw · $viewsCount' : ratingRaw))
        : (viewsCount > 0 ? '4.8 · $viewsCount' : '4.8');

    final String explicitHighlight =
        (ad['highlight_label'] ?? ad['guest_favorite_label'] ?? '')
            .toString()
            .trim();
    final String? highlightLabel = explicitHighlight.isNotEmpty
        ? explicitHighlight
        : ((ad['is_guest_favorite'] == true ||
                ad['is_vip'] == true ||
                ad['is_featured'] == true ||
                ad['is_highlighted'] == true ||
                viewsCount >= 50)
            ? s.tr('إعلان مميز', 'En vedette', 'Guest favourite')
            : (isNegotiable
                ? s.tr('قابل للتفاوض', 'Négociable', 'Negotiable')
                : null));

    final String totalCountLabel = (ad['photo_count_total'] != null)
        ? '${_currentImgIndex + 1}/${ad['photo_count_total']}'
        : '${_currentImgIndex + 1}/${images.isNotEmpty ? images.length : 1}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: SizedBox(
        height: 380,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (images.isNotEmpty)
                  PageView.builder(
                    controller: _pageCtrl,
                    physics: const BouncingScrollPhysics(),
                    itemCount: images.length,
                    onPageChanged: (i) =>
                        setState(() => _currentImgIndex = i),
                    itemBuilder: (_, idx) {
                      final imgUrl = images[idx];
                      return GestureDetector(
                        onTap: () => _openFullScreenImage(
                          imgUrl,
                          (ad['title'] ?? '').toString(),
                        ),
                        child: imgUrl.startsWith('assets/')
                            ? Image.asset(
                                imgUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Floating3DIllustration(
                                    assetPath: categoryAsset,
                                    size: 135,
                                  ),
                                ),
                              )
                            : AppImage(
                                url: imgUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                fallback: Container(
                                  color: const Color(0xFFE2E8F0),
                                  alignment: Alignment.center,
                                  child: Floating3DIllustration(
                                    assetPath: categoryAsset,
                                    size: 135,
                                  ),
                                ),
                              ),
                      );
                    },
                  )
                else
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Floating3DIllustration(
                      assetPath: categoryAsset,
                      size: 145,
                    ),
                  ),

                // Top & bottom subtle gradient scrims for crisp overlay contrast
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 88,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.22),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 84,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.26),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Top-start Back Button + Top-end Share & Favorite Buttons (38x38 glass)
                PositionedDirectional(
                  top: 14,
                  start: 14,
                  end: 14,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _GlassCircleButton(
                        icon: s.isAr
                            ? CupertinoIcons.chevron_right
                            : CupertinoIcons.chevron_left,
                        tooltip: s.tr('رجوع', 'Retour', 'Back'),
                        onTap: () => Navigator.pop(context),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _GlassCircleButton(
                            icon: CupertinoIcons.share,
                            tooltip: s.tr('مشاركة', 'Partager', 'Share'),
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
                          _GlassCircleButton(
                            icon: isFav
                                ? CupertinoIcons.heart_fill
                                : CupertinoIcons.heart,
                            iconColor:
                                isFav ? const Color(0xFFFF3B5C) : Colors.white,
                            tooltip: s.tr('المفضلة', 'Favori', 'Favorite'),
                            onTap: _toggleFavorite,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Center Floating Video Tour Pill (when video metadata exists)
                if (showVideoTour)
                  Center(
                    child: _VideoTourPill(
                      label: s.tr('فيديو الإعلان', 'Visite vidéo', 'Video tour'),
                      duration:
                          videoDuration.isNotEmpty ? videoDuration : '0:45',
                      onTap: () => _openVideoTour(
                        videoUrl,
                        images,
                        (ad['title'] ?? '').toString(),
                      ),
                    ),
                  ),

                // Bottom Overlay Image Tags (Type pill, Rating/Views pill, Highlight pill, Counter pill)
                PositionedDirectional(
                  bottom: 14,
                  start: 12,
                  end: 12,
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ImageTagPill(label: heroTypeTag),
                              const SizedBox(width: 6),
                              _ImageTagPill(
                                leadingIcon: Icons.star_rounded,
                                leadingIconColor: const Color(0xFFFBBF24),
                                label: ratingPillLabel,
                              ),
                              if (highlightLabel != null) ...[
                                const SizedBox(width: 6),
                                _ImageTagPill(
                                  label: highlightLabel,
                                  isLight: true,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (images.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _openFullScreenImage(
                            images[_currentImgIndex.clamp(0, images.length - 1)],
                            (ad['title'] ?? '').toString(),
                          ),
                          child: _ImageTagPill(
                            label: totalCountLabel,
                            tabular: true,
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
      ),
    );
  }

  String _resolveListedTimeLabel(Map<String, dynamic> ad, AppStrings s) {
    final explicit = (ad['listed_label'] ??
            ad['created_at_human'] ??
            ad['time_ago'] ??
            ad['published_ago'] ??
            '')
        .toString()
        .trim();
    if (explicit.isNotEmpty) return explicit;

    final rawDate = (ad['created_at'] ?? '').toString().trim();
    if (rawDate.isNotEmpty) {
      final parsed = DateTime.tryParse(rawDate);
      if (parsed != null) {
        final diff = DateTime.now().difference(parsed.toLocal());
        if (diff.inMinutes < 60) {
          final m = diff.inMinutes.clamp(1, 59);
          return s.tr(
            'نُشر للتو · منذ $m د',
            'Publié · il y a $m min',
            'Just listed · ${m}m ago',
          );
        }
        if (diff.inHours < 24) {
          final h = diff.inHours;
          return s.tr(
            'نُشر للتو · منذ $h ساعة',
            'Publié · il y a ${h}h',
            'Just listed · $h hours ago',
          );
        }
        final d = diff.inDays;
        return s.tr(
          'منذ $d يوم',
          'Il y a ${d}j',
          '$d days ago',
        );
      }
    }
    return s.tr('نُشر للتو', 'Vient d’être publié', 'Just listed');
  }

  Widget _buildMarketplaceHeader({
    required AppStrings s,
    required Map<String, dynamic> ad,
    required String title,
    required String locationSubtitle,
    required String priceFormatted,
    required String priceFrequency,
  }) {
    final String listedLabel = _resolveListedTimeLabel(ad, s);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: _ink,
              letterSpacing: AppTypography.trackingForContext(context, -0.35),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 5),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 2,
            children: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: PriceText(
                  priceFormatted,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (priceFrequency.isNotEmpty)
                Text(
                  priceFrequency,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: _mutedText,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 2,
            children: [
              Text(
                listedLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: _mutedText,
                ),
              ),
              if (locationSubtitle.isNotEmpty) ...[
                const Text(
                  '·',
                  style: TextStyle(
                    fontSize: 13,
                    color: _mutedText,
                  ),
                ),
                Text(
                  locationSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: _mutedText,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageSellerCard({
    required AppStrings s,
    required Map<String, dynamic> ad,
    required bool isOwner,
  }) {
    if (isOwner) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        child: PressableScale(
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(14),
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
                      fontWeight: FontWeight.w700,
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
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: _fbBlue,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    CupertinoIcons.chat_bubble_fill,
                    size: 11,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  s.tr('راسل البائع', 'Contacter le vendeur', 'Message seller'),
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 42),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: AlignmentDirectional.centerStart,
                    child: TextField(
                      key: const Key('detail-quick-msg'),
                      controller: _quickMsgCtrl,
                      minLines: 1,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: _ink,
                        height: 1.3,
                        fontWeight: FontWeight.w400,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 4),
                        hintText: s.tr(
                          'اكتب رسالتك هنا...',
                          'Écrivez votre message...',
                          'Write a message...',
                        ),
                        hintStyle: const TextStyle(
                          fontSize: 13.5,
                          color: _mutedText,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PressableScale(
                  key: const Key('detail-quick-send'),
                  onTap: () {
                    final draft = _quickMsgCtrl.text.trim();
                    _openInAppChat(
                      presetMessage: draft.isNotEmpty ? draft : null,
                    );
                  },
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: _fbBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      s.tr('إرسال', 'Envoyer', 'Send'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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
  }

  Future<void> _handleAlertsTap(AppStrings s, Map<String, dynamic> ad) async {
    HapticFeedback.selectionClick();
    final next = !_alertEnabled;
    setState(() => _alertEnabled = next);
    if (next && _state.api.isAuthenticated) {
      try {
        await _state.api.dio.post('/saved-searches', data: {
          'query': (ad['title'] ?? '').toString().trim(),
        });
      } catch (_) {}
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          next
              ? s.tr(
                  'تم تفعيل تنبيهات الإعلانات المشابهة',
                  'Alertes activées pour des annonces similaires',
                  'Alerts enabled for similar listings',
                )
              : s.tr(
                  'تم إيقاف التنبيهات لهذا البحث',
                  'Alertes désactivées',
                  'Alerts paused',
                ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCircleRow({
    required AppStrings s,
    required Map<String, dynamic> ad,
    required bool isFav,
    required String priceFormatted,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _MarketplaceActionCircle(
              icon: _alertEnabled
                  ? CupertinoIcons.bell_fill
                  : CupertinoIcons.bell,
              label: s.tr('تنبيهات', 'Alertes', 'Alerts'),
              active: _alertEnabled,
              onTap: () => _handleAlertsTap(s, ad),
            ),
          ),
          Expanded(
            child: _MarketplaceActionCircle(
              icon: CupertinoIcons.chat_bubble_fill,
              label: s.tr('رسالة', 'Message', 'Message'),
              onTap: () => _openInAppChat(),
            ),
          ),
          Expanded(
            child: _MarketplaceActionCircle(
              icon: CupertinoIcons.arrowshape_turn_up_right_fill,
              label: s.tr('مشاركة', 'Partager', 'Share'),
              onTap: () {
                HapticFeedback.selectionClick();
                final shareUrl = ad['share_url'] ?? 'https://apolo.ma';
                Share.share(
                  '${ad['title']} - $priceFormatted\n$shareUrl',
                );
              },
            ),
          ),
          Expanded(
            child: _MarketplaceActionCircle(
              icon: isFav
                  ? CupertinoIcons.bookmark_fill
                  : CupertinoIcons.bookmark,
              label: s.tr('حفظ', 'Enregistrer', 'Save'),
              active: isFav,
              onTap: _toggleFavorite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSpecGrid(
    List<({String value, String label})> cards, {
    EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(20, 20, 20, 0),
  }) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _SpecStatCard(
                value: cards[i].value,
                label: cards[i].label,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescriptionSection({
    required AppStrings s,
    required Map<String, dynamic> ad,
    required List<({String value, String label})> quickSpecCards,
    required List<MapEntry<String, String>> rawSpecs,
    required List<MapEntry<String, String>> structuredSpecs,
    required bool isOwner,
    required String? phone,
    required String sellerDisplayName,
  }) {
    final String rawDesc = (ad['description'] ?? '').toString().trim();
    final String fullDescription = rawDesc.isEmpty
        ? s.tr(
            'لم يضف البائع وصفاً لهذا الإعلان. تواصل معه لمعرفة التفاصيل.',
            'Le vendeur n’a pas ajouté de description. Contactez-le pour en savoir plus.',
            'No description provided. Message the seller for details.',
          )
        : rawDesc;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.tr('الوصف', 'Description', 'Description'),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            fullDescription,
            maxLines: _descExpanded ? 50 : 4,
            overflow:
                _descExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.45,
              color: _ink,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (fullDescription.length > 140) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => setState(() => _descExpanded = !_descExpanded),
              child: Text(
                _descExpanded
                    ? s.tr('عرض أقل', 'Voir moins', 'See less')
                    : s.tr('قراءة المزيد', 'Lire la suite', 'See more'),
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: _fbBlue,
                ),
              ),
            ),
          ],

          // Compact 4-stat Specs row
          _buildQuickSpecGrid(
            quickSpecCards,
            padding: const EdgeInsets.only(top: 14),
          ),

          // Additional specs when ad has rich metadata
          if (rawSpecs.length > 2) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: structuredSpecs.skip(2).take(6).map((e) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${e.key}: ${e.value}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _ink,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          if (!isOwner && phone != null && phone.isNotEmpty) ...[
            const SizedBox(height: 14),
            PressableScale(
              onTap: () => _showCallSheetOrDial(phone, sellerDisplayName),
              child: Container(
                width: double.infinity,
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.phone_fill,
                      size: 16,
                      color: _ink,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${s.tr('اتصال هاتفي بالبائع', 'Appeler le vendeur', 'Call seller')} · $phone',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: _ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openSellerOrStore({
    required Map<String, dynamic> ad,
    required Map<String, dynamic>? seller,
    required Map<String, dynamic>? store,
    required int sellerId,
    required String sellerDisplayName,
    required String cityName,
    required String? phone,
    required String? avatarUrl,
  }) {
    if (store != null && store['subdomain'] != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StoreDetailScreen(
            subdomain: store['subdomain'].toString(),
          ),
        ),
      );
      return;
    }
    if (sellerId > 0) {
      HapticFeedback.lightImpact();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SellerProfileScreen(
            sellerId: sellerId,
            sellerName: sellerDisplayName,
            sellerAvatar: avatarUrl,
            sellerPhone: phone,
            sellerCity: cityName,
            isVerified: seller?['is_verified'] == true,
            isOnline: seller?['is_online'] == true,
            initialAd: ad,
          ),
        ),
      );
    }
  }

  Widget _buildSellerSection({
    required AppStrings s,
    required Map<String, dynamic> ad,
    required Map<String, dynamic>? seller,
    required Map<String, dynamic>? store,
    required int sellerId,
    required String sellerDisplayName,
    required String cityName,
    required String? phone,
    required bool isOwner,
  }) {
    final String hostTitle = (ad['host_title'] ?? '').toString().trim().isNotEmpty
        ? ad['host_title'].toString().trim()
        : sellerDisplayName;

    final String hostSubtitle = (ad['host_subtitle'] ?? '')
            .toString()
            .trim()
            .isNotEmpty
        ? ad['host_subtitle'].toString().trim()
        : (seller?['joined_label']?.toString().trim().isNotEmpty == true
            ? seller!['joined_label'].toString().trim()
            : (store != null
                ? s.tr('متجر على Apolo · $cityName', 'Boutique Apolo · $cityName')
                : s.tr('بائع على Apolo · $cityName',
                    'Vendeur Apolo · $cityName')));

    final String hostInitials =
        (ad['host_initials'] ?? _initialsFromName(sellerDisplayName))
            .toString()
            .trim();
    final String? avatarUrl =
        (store?['logo_url'] ?? seller?['avatar_url'])?.toString().trim();

    final double? ratingVal = double.tryParse(
        (seller?['rating'] ?? seller?['avg_rating'] ?? ad['seller_rating'] ?? '')
            .toString());
    final int? reviewsCountVal = int.tryParse(
        (seller?['reviews_count'] ?? ad['seller_reviews_count'] ?? '')
            .toString());

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => _openSellerOrStore(
                  ad: ad,
                  seller: seller,
                  store: store,
                  sellerId: sellerId,
                  sellerDisplayName: sellerDisplayName,
                  cityName: cityName,
                  phone: phone,
                  avatarUrl: avatarUrl,
                ),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s.tr('البائع', 'Vendeur', 'Seller'),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      s.isAr
                          ? CupertinoIcons.chevron_left
                          : CupertinoIcons.chevron_right,
                      size: 15,
                      color: _mutedText,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                key: const Key('detail-see-reviews'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _SellerReviewsScreen(
                        s: s,
                        sellerName: sellerDisplayName,
                        rating: ratingVal,
                        reviewsCount: reviewsCountVal ?? 0,
                        rawReviews: (seller?['reviews'] ?? ad['reviews'])
                            as List<dynamic>?,
                      ),
                    ),
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    s.tr('عرض التقييمات', 'Voir les avis', 'See reviews'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _fbBlue,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _openSellerOrStore(
                    ad: ad,
                    seller: seller,
                    store: store,
                    sellerId: sellerId,
                    sellerDisplayName: sellerDisplayName,
                    cityName: cityName,
                    phone: phone,
                    avatarUrl: avatarUrl,
                  ),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF39C12),
                          shape: BoxShape.circle,
                        ),
                        clipBehavior: Clip.antiAlias,
                        alignment: Alignment.center,
                        child: (avatarUrl != null && avatarUrl.isNotEmpty)
                            ? AppImage(
                                url: avatarUrl,
                                width: 46,
                                height: 46,
                                fit: BoxFit.cover,
                                fallback:
                                    _InitialsCircle(initials: hostInitials),
                              )
                            : _InitialsCircle(initials: hostInitials),
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
                                    hostTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w600,
                                      color: _ink,
                                    ),
                                  ),
                                ),
                                if (seller?['is_verified'] == true) ...[
                                  const SizedBox(width: 4),
                                  const Icon(
                                    CupertinoIcons.checkmark_seal_fill,
                                    size: 14,
                                    color: _fbBlue,
                                  ),
                                ],
                              ],
                            ),
                            if (ratingVal != null && ratingVal > 0) ...[
                              const SizedBox(height: 3),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  ...List.generate(5, (i) {
                                    final filled = i + 1 <= ratingVal.floor();
                                    final half = !filled &&
                                        (ratingVal - i) >= 0.4;
                                    return Icon(
                                      half
                                          ? Icons.star_half_rounded
                                          : (filled
                                              ? Icons.star_rounded
                                              : Icons.star_outline_rounded),
                                      size: 14.5,
                                      color: _starOrange,
                                    );
                                  }),
                                  const SizedBox(width: 4),
                                  Text(
                                    ratingVal.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: _ink,
                                    ),
                                  ),
                                  if (reviewsCountVal != null)
                                    Text(
                                      ' ($reviewsCountVal)',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: _mutedText,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 2),
                            Text(
                              hostSubtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w400,
                                color: _mutedText,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isOwner) ...[
                const SizedBox(width: 10),
                PressableScale(
                  key: const Key('detail-follow-seller'),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _followingSeller = !_followingSeller);
                  },
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: _followingSeller ? _fbBlueSoft : _pillGrey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _followingSeller
                          ? s.tr('متابَع', 'Suivi', 'Following')
                          : s.tr('متابعة', 'Suivre', 'Follow'),
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: _followingSeller ? _fbBlue : _ink,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection({
    required AppStrings s,
    required String cityName,
    required String locationSubtitle,
  }) {
    final mapDisplayCity = cityName;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.tr('موقع الإعلان', 'Localisation', 'Location'),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final q = Uri.encodeComponent('$locationSubtitle, Morocco');
              final uri = Uri.parse('https://maps.google.com/?q=$q');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 164,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const CustomPaint(painter: _ApproxMapPainter()),
                    Center(
                      child: Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          color: _fbBlue.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _fbBlue.withValues(alpha: 0.45),
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            mapDisplayCity,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      bottom: 10,
                      end: 10,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          CupertinoIcons.info,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            cityName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: _ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            s.tr(
              'الموقع تقريبي',
              'La localisation est approximative',
              'Location is approximate',
            ),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: _mutedText,
            ),
          ),
        ],
      ),
    );
  }

  List<String> _buildRelatedSearchTerms(
    Map<String, dynamic> ad,
    String categoryName,
    String cityName,
  ) {
    final terms = <String>[];
    void addTerm(String candidate) {
      final clean = candidate.trim();
      if (clean.length >= 2 && !terms.contains(clean)) {
        terms.add(clean);
      }
    }

    final rawTitle = (ad['title'] ?? '').toString().trim();
    if (rawTitle.isNotEmpty) {
      final words = rawTitle.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      addTerm(words.length > 4 ? words.take(4).join(' ') : rawTitle);
      if (words.length >= 2) {
        addTerm('${words.first} $cityName');
      }
    }
    if (categoryName.isNotEmpty && cityName.isNotEmpty) {
      addTerm('$categoryName $cityName');
    }
    addTerm(categoryName);
    addTerm(cityName);
    return terms.take(5).toList();
  }

  Widget _buildRelatedSearchesSection({
    required AppStrings s,
    required Map<String, dynamic> ad,
    required String categoryName,
    required String cityName,
  }) {
    final terms = _buildRelatedSearchTerms(ad, categoryName, cityName);
    if (terms.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.tr('عمليات بحث ذات صلة', 'Recherches similaires', 'Related searches'),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: terms.map((term) {
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SearchScreen(initialQuery: term),
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: _pillGrey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.search,
                        size: 15,
                        color: _ink,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          term,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: _ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHideListingCard({
    required AppStrings s,
    required Map<String, dynamic> ad,
    required Map<String, dynamic>? seller,
    required bool isOwner,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text.rich(
              TextSpan(
                style: const TextStyle(
                  fontSize: 13.5,
                  color: _ink,
                  height: 1.35,
                ),
                children: [
                  TextSpan(
                    text: s.tr(
                      'إذا لم يعجبك هذا الإعلان، يمكنك ',
                      'Si vous n’aimez pas ceci, vous pouvez ',
                      "If you don't like this, you can ",
                    ),
                  ),
                  TextSpan(
                    text: s.tr(
                      'إخفاء هذا الإعلان',
                      'masquer cette annonce',
                      'hide this listing',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: s.tr(
                      ' وسنعرض لك إعلانات أقل مشابهة له.',
                      ' et nous vous en montrerons moins de ce type.',
                      " and we'll show you fewer listings like this.",
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PressableScale(
              key: const Key('detail-hide-listing'),
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _hiddenListing = !_hiddenListing);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text(
                      _hiddenListing
                          ? s.tr(
                              'تم إخفاء الإعلان من توصياتك',
                              'Annonce masquée de vos recommandations',
                              'Listing hidden from your feed',
                            )
                          : s.tr(
                              'تم إلغاء الإخفاء',
                              'Affichage rétabli',
                              'Listing restored',
                            ),
                    ),
                  ),
                );
                if (_hiddenListing && Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: _pillGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  _hiddenListing
                      ? s.tr('تم الإخفاء', 'Masquée', 'Hidden')
                      : s.tr('إخفاء الإعلان', 'Masquer l’annonce',
                          'Hide listing'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: GestureDetector(
                onTap: () => _showMoreActionsSheet(s, ad, seller, isOwner),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.shield_lefthalf_fill,
                        size: 13,
                        color: _mutedText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        s.tr('الإبلاغ أو الأمان', 'Signaler / Sécurité',
                            'Report & Safety'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _mutedText,
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
    );
  }

  Widget _buildStickyBottomBar({
    required AppStrings s,
    required Map<String, dynamic> ad,
    required bool isOwner,
    required bool isStayListing,
    required bool isNegotiable,
    required String cityName,
    required String fallbackPrice,
    required String sellerDisplayName,
    required String? phone,
  }) {
    final String totalMain =
        (ad['total_price_display'] ?? '').toString().trim().isNotEmpty
            ? ad['total_price_display'].toString().trim()
            : fallbackPrice;
    final String totalUnit =
        (ad['total_unit_label'] ?? (ad.containsKey('total_price_display') ? 'total' : ''))
            .toString()
            .trim();
    final String totalSubtitle =
        (ad['total_subtitle'] ?? ad['stay_dates_label'] ?? '').toString().trim().isNotEmpty
            ? (ad['total_subtitle'] ?? ad['stay_dates_label']).toString().trim()
            : (isStayListing
                ? 'taxes incl.'
                : '${isNegotiable ? s.tr('ثمن قابل للنقاش', 'Prix négociable') : s.tr('توصيل / معاينة مباشرة', 'Remise en main propre')} · $cityName');
    final String ctaLabel = (ad['cta_label'] ?? '').toString().trim().isNotEmpty
        ? ad['cta_label'].toString().trim()
        : (isOwner
            ? s.tr('ترقية الإعلان ⚡', 'Booster ⚡')
            : (isStayListing
                ? s.tr('احجز الآن', 'Réserver', 'Book now')
                : s.tr('تواصل للشراء', 'Contacter', 'Book now')));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: totalMain,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A),
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            if (totalUnit.isNotEmpty)
                              TextSpan(
                                text: ' $totalUnit',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      totalSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              PressableScale(
                onTap: () {
                  if (isOwner) {
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
                    return;
                  }
                  if (phone != null && phone.isNotEmpty) {
                    _showContactOptionsSheet(s, sellerDisplayName, phone);
                  } else {
                    _openInAppChat();
                  }
                },
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 140, minHeight: 48),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF4444F0), Color(0xFF5B54F6)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4A4EED).withValues(alpha: 0.28),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      ctaLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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

class _GlassCircleButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String? tooltip;
  final VoidCallback onTap;

  const _GlassCircleButton({
    required this.icon,
    this.iconColor = Colors.white,
    this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: PressableScale(
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                      width: 0.8,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 16, color: iconColor),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoTourPill extends StatelessWidget {
  final String label;
  final String duration;
  final VoidCallback onTap;

  const _VideoTourPill({
    required this.label,
    required this.duration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.24),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 13,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.05,
                        ),
                      ),
                      Text(
                        duration,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.70),
                          fontSize: 9,
                          fontWeight: FontWeight.w400,
                          height: 1.05,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageTagPill extends StatelessWidget {
  final String label;
  final IconData? leadingIcon;
  final Color? leadingIconColor;
  final bool isLight;
  final bool tabular;

  const _ImageTagPill({
    required this.label,
    this.leadingIcon,
    this.leadingIconColor,
    this.isLight = false,
    this.tabular = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isLight
                ? Colors.white
                : Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingIcon != null) ...[
                Icon(
                  leadingIcon,
                  size: 13,
                  color: leadingIconColor ??
                      (isLight ? const Color(0xFF1A1A1A) : Colors.white),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isLight ? FontWeight.w600 : FontWeight.w500,
                  color: isLight ? const Color(0xFF1A1A1A) : Colors.white,
                  fontFeatures:
                      tabular ? const [FontFeature.tabularFigures()] : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpecStatCard extends StatelessWidget {
  final String value;
  final String label;

  const _SpecStatCard({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECECEC), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
              height: 1.15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: Color(0xFF8E8E93),
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialsCircle extends StatelessWidget {
  final String initials;

  const _InitialsCircle({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
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
        Icon(icon, size: 17, color: const Color(0xFF4A4EED)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
              letterSpacing: AppTypography.trackingForContext(context, -0.3),
            ),
          ),
        ),
      ],
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

class _MarketplaceActionCircle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _MarketplaceActionCircle({
    required this.icon,
    required this.label,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color:
                  active ? const Color(0xFFE7F3FF) : const Color(0xFFE4E6EB),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 20,
              color: active ? const Color(0xFF0866FF) : const Color(0xFF050505),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: active ? const Color(0xFF0866FF) : const Color(0xFF050505),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApproxMapPainter extends CustomPainter {
  const _ApproxMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Land base
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFE8F1E1),
    );

    // Coastal sea strip (matches screenshot soft blue ocean edge)
    final seaPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.72, 0)
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.25,
        0,
        size.height * 0.62,
      )
      ..close();
    canvas.drawPath(
      seaPath,
      Paint()..color = const Color(0xFF9CD4FF),
    );

    // Park / terrain patch
    final parkPath = Path()
      ..moveTo(size.width * 0.56, size.height * 0.30)
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.36,
        size.width,
        size.height * 0.72,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * 0.48, size.height)
      ..close();
    canvas.drawPath(
      parkPath,
      Paint()..color = const Color(0xFFD6ECC8),
    );

    // Subtle roads
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.90)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final highway = Path()
      ..moveTo(0, size.height * 0.82)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.52,
        size.width,
        size.height * 0.14,
      );
    canvas.drawPath(highway, roadPaint);

    final crossRoad = Path()
      ..moveTo(size.width * 0.28, size.height)
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * 0.48,
        size.width * 0.56,
        0,
      );
    canvas.drawPath(
      crossRoad,
      roadPaint..strokeWidth = 2.0,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SellerReviewsScreen extends StatefulWidget {
  final AppStrings s;
  final String sellerName;
  final double? rating;
  final int reviewsCount;
  final List<dynamic>? rawReviews;

  const _SellerReviewsScreen({
    required this.s,
    required this.sellerName,
    this.rating,
    this.reviewsCount = 0,
    this.rawReviews,
  });

  @override
  State<_SellerReviewsScreen> createState() => _SellerReviewsScreenState();
}

class _SellerReviewsScreenState extends State<_SellerReviewsScreen> {
  int _minStarsFilter = 0; // 0: All, 5: 5 stars, 4: 4+ stars
  bool _highestFirst = false;

  static const Color _ink = Color(0xFF050505);
  static const Color _muted = Color(0xFF65676B);
  static const Color _fbBlue = Color(0xFF0866FF);
  static const Color _fbBlueSoft = Color(0xFFE7F3FF);
  static const Color _starOrange = Color(0xFFE87A24);

  List<Map<String, dynamic>> get _reviews {
    final raw = (widget.rawReviews ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((r) {
      if (_minStarsFilter == 0) return true;
      final stars = int.tryParse((r['rating'] ?? 0).toString()) ?? 0;
      return stars >= _minStarsFilter;
    }).toList();
    if (_highestFirst) {
      raw.sort((a, b) {
        final sa = int.tryParse((a['rating'] ?? 0).toString()) ?? 0;
        final sb = int.tryParse((b['rating'] ?? 0).toString()) ?? 0;
        return sb.compareTo(sa);
      });
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final items = _reviews;
    final double ratingValue = widget.rating ?? 0.0;
    final int totalCount =
        widget.reviewsCount > 0 ? widget.reviewsCount : items.length;

    // Distribution counts (5 -> 1 stars) computed from real review items
    final Map<int, int> counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in (widget.rawReviews ?? []).whereType<Map>()) {
      final st = int.tryParse((r['rating'] ?? 0).toString()) ?? 0;
      if (counts.containsKey(st)) counts[st] = counts[st]! + 1;
    }
    final int maxCount =
        counts.values.fold<int>(1, (m, c) => c > m ? c : m);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            s.isAr
                ? CupertinoIcons.chevron_right
                : CupertinoIcons.chevron_left,
            color: _ink,
          ),
        ),
        centerTitle: true,
        title: Text(
          s.tr('جميع التقييمات', 'Tous les avis', 'All Reviews'),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            s.tr('تقييم البائع', 'Note du vendeur', 'Seller rating'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ...List.generate(5, (i) {
                final filled = i + 1 <= ratingValue.floor();
                final half = !filled && (ratingValue - i) >= 0.4;
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 2),
                  child: Icon(
                    half
                        ? Icons.star_half_rounded
                        : (filled
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded),
                    size: 20,
                    color: _starOrange,
                  ),
                );
              }),
              const SizedBox(width: 8),
              Text(
                ratingValue > 0 ? ratingValue.toStringAsFixed(1) : '—',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '($totalCount)',
                style: const TextStyle(
                  fontSize: 15,
                  color: _muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 5-to-1 Stars Horizontal Breakdown Bars
          for (int star = 5; star >= 1; star--) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 58,
                    child: Text(
                      s.tr(
                        '$star نجوم',
                        '$star étoiles',
                        star == 1 ? '1 star' : '$star stars',
                      ),
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: _ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (counts[star] ?? 0) / maxCount,
                        minHeight: 7,
                        backgroundColor: const Color(0xFFF0F2F5),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(_starOrange),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${counts[star] ?? 0}',
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _muted,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 22),
          Text(
            s.tr(
              'تقييمات البائع ($totalCount)',
              'Avis sur le vendeur ($totalCount)',
              'Seller reviews ($totalCount)',
            ),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 12),

          // Filters & Sort Soft Blue Pills (matching Screenshot 2)
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _minStarsFilter = _minStarsFilter == 0 ? 5 : 0;
                  });
                },
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: _fbBlueSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tune_rounded, size: 17, color: _fbBlue),
                      const SizedBox(width: 6),
                      Text(
                        _minStarsFilter == 5
                            ? s.tr('5 نجوم فقط', '5 étoiles', '5 stars')
                            : s.tr('تصفية', 'Filtres', 'Filters'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _fbBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _highestFirst = !_highestFirst);
                },
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: _fbBlueSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.swap_vert_rounded,
                        size: 17,
                        color: _fbBlue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _highestFirst
                            ? s.tr('الأعلى تقييماً', 'Meilleurs', 'Highest')
                            : s.tr('ترتيب', 'Trier', 'Sort'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _fbBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  const Icon(
                    CupertinoIcons.star_circle,
                    size: 32,
                    color: _muted,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.tr(
                      'لا توجد تقييمات نصية منشورة لـ ${widget.sellerName} حالياً',
                      'Aucun avis publié pour ${widget.sellerName} pour le moment',
                      'No written reviews for ${widget.sellerName} yet',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: _muted,
                    ),
                  ),
                ],
              ),
            )
          else
            for (final rev in items) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE4E6EB),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            CupertinoIcons.person_fill,
                            color: Color(0xFF9CA3AF),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (rev['author'] ?? rev['name'] ?? '')
                                    .toString(),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _ink,
                                ),
                              ),
                              if ((rev['date'] ?? '').toString().isNotEmpty)
                                Text(
                                  rev['date'].toString(),
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: _muted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(5, (i) {
                        final st =
                            int.tryParse((rev['rating'] ?? 5).toString()) ?? 5;
                        return Icon(
                          i < st
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 16,
                          color: _starOrange,
                        );
                      }),
                    ),
                    if ((rev['comment'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        rev['comment'].toString(),
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: _muted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }
}
