import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            // 1. Hero Image Card (380px, 12px margin, 32px radius)
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

            // 2. Title & Pricing Row (Gap Y = 20px)
            _buildTitleAndPricingRow(
              title: (ad['title'] ?? '').toString(),
              locationSubtitle: locationSubtitle,
              priceFormatted: priceFormatted,
              priceFrequency: priceFrequency,
            ),

            // 3. 4-Column Quick Spec Cards (Gap Y = 20px)
            _buildQuickSpecGrid(quickSpecCards),

            // 4. Host / Seller Card (Gap Y = 20px)
            _buildHostCard(
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

            // 5. Core Apolo Details (Thumbnails, Boost, Specs, Description, Quick Chat, Call, Safety, Related)
            _buildExtraDetailsSection(
              s: s,
              ad: ad,
              seller: seller,
              images: images,
              metadata: metadata,
              structuredSpecs: structuredSpecs,
              isOwner: isOwner,
              phone: phone,
              sellerDisplayName: sellerDisplayName,
            ),
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

  Widget _buildTitleAndPricingRow({
    required String title,
    required String locationSubtitle,
    required String priceFormatted,
    required String priceFrequency,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                    letterSpacing: AppTypography.trackingForContext(context, -0.5),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: Color(0xFF8E8E93),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        locationSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: PriceText(
                  priceFormatted,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.4,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                priceFrequency,
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
        ],
      ),
    );
  }

  Widget _buildQuickSpecGrid(List<({String value, String label})> cards) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
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

  Widget _buildHostCard({
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
        : (store != null
            ? sellerDisplayName
            : s.tr('بواسطة $sellerDisplayName', 'Par $sellerDisplayName',
                'Hosted by $sellerDisplayName'));

    final String hostSubtitle = (ad['host_subtitle'] ?? '')
            .toString()
            .trim()
            .isNotEmpty
        ? ad['host_subtitle'].toString().trim()
        : (store != null
            ? s.tr('متجر على Apolo · $cityName · يرد بسرعة',
                'Boutique sur Apolo · $cityName')
            : s.tr(
                '${seller?['is_verified'] == true ? 'حساب موثق · ' : ''}بائع على Apolo · $cityName',
                '${seller?['is_verified'] == true ? 'Vérifié · ' : ''}Vendeur sur Apolo · $cityName',
              ));

    final String hostInitials =
        (ad['host_initials'] ?? _initialsFromName(sellerDisplayName))
            .toString()
            .trim();
    final String? avatarUrl =
        (store?['logo_url'] ?? seller?['avatar_url'])?.toString().trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF0F0F0), width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: PressableScale(
                onTap: () {
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
                },
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF39C12),
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.antiAlias,
                      alignment: Alignment.center,
                      child: (avatarUrl != null && avatarUrl.isNotEmpty)
                          ? AppImage(
                              url: avatarUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              fallback: _InitialsCircle(initials: hostInitials),
                            )
                          : _InitialsCircle(initials: hostInitials),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
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
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                              ),
                              if (seller?['is_verified'] == true) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  CupertinoIcons.checkmark_seal_fill,
                                  size: 14,
                                  color: Color(0xFF4A4EED),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hostSubtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF8E8E93),
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
                onTap: () => _openInAppChat(),
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFE5E5E5),
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    s.tr('رسالة', 'Message', 'Message'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExtraDetailsSection({
    required AppStrings s,
    required Map<String, dynamic> ad,
    required Map<String, dynamic>? seller,
    required List<String> images,
    required Map<String, dynamic> metadata,
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (images.length > 1) ...[
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
                          color: active ? const Color(0xFF4A4EED) : const Color(0xFFECECEC),
                          width: active ? 2 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: images[idx].startsWith('assets/')
                            ? Image.asset(images[idx], fit: BoxFit.cover)
                            : AppImage(url: images[idx], fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],

          if (isOwner) ...[
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
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    Icon(
                      s.isAr
                          ? CupertinoIcons.chevron_left
                          : CupertinoIcons.chevron_right,
                      size: 16,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Description Card
          _SectionHeader(
            icon: CupertinoIcons.doc_text_fill,
            title: s.tr('وصف وتفاصيل الإعلان', 'Description détaillée'),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFECECEC), width: 1),
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
                    fontSize: 14.5,
                    height: 1.65,
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (fullDescription.length > 140) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => setState(() => _descExpanded = !_descExpanded),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _descExpanded
                              ? s.tr('عرض أقل', 'Voir moins')
                              : s.tr('قراءة الوصف كامل', 'Lire la suite'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4A4EED),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _descExpanded
                              ? CupertinoIcons.chevron_up
                              : CupertinoIcons.chevron_down,
                          size: 13,
                          color: const Color(0xFF4A4EED),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Detailed Specs Grid
          _SectionHeader(
            icon: CupertinoIcons.square_list_fill,
            title: s.tr('معلومات ومواصفات الإعلان', 'Informations clés'),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFECECEC), width: 1),
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
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Quick Chat Questions & Phone Call Option
          if (!isOwner) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFECECEC), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.tr(
                      'صيفط سؤال سريع فـ شات التطبيق:',
                      'Envoyer une question rapide dans le chat :',
                    ),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8E8E93),
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
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFECECEC)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                CupertinoIcons.chat_bubble_2_fill,
                                size: 13,
                                color: Color(0xFF4A4EED),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  q,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (phone != null && phone.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    PressableScale(
                      onTap: () => _showCallSheetOrDial(phone, sellerDisplayName),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: _redSoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              CupertinoIcons.phone_fill,
                              size: 16,
                              color: _red,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '${s.tr('اتصال هاتفي بالبائع', 'Appeler le vendeur')} · $phone',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _red,
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
            ),
          ],

          // Safety & Report Row (keeps Trust/Report/Block accessible)
          const SizedBox(height: 16),
          PressableScale(
            onTap: () => _showMoreActionsSheet(s, ad, seller, isOwner),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFDCFCE7)),
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
                        'نصيحة أمان: تواصل عبر شات Apolo وعاين السلعة قبل الدفع.',
                        'Conseil sécurité : Discutez sur Apolo et vérifiez l\'article en personne.',
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF166534),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      s.tr('إبلاغ', 'Signaler'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Related Ads Section
          if (_relatedAds.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionHeader(
              icon: CupertinoIcons.square_grid_2x2_fill,
              title: s.tr('إعلانات مشابهة فـ نفس القسم', 'Annonces similaires'),
            ),
            const SizedBox(height: 12),
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
