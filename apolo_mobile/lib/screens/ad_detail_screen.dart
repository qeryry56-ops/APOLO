import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../core/config/app_config.dart';
import '../core/location/marketplace_location.dart';
import '../core/services/firebase_chat_service.dart';
import '../core/state/app_state.dart';
import '../theme/app_typography.dart';
import '../widgets/apolo_badges_kit.dart';
import '../widgets/dl_settings_kit.dart';
import 'widgets/price_text.dart';
import 'widgets/apolo_safety_sheet.dart';
import 'widgets/app_image.dart';
import 'widgets/boost_sheet.dart';
import 'widgets/chat_utils.dart';
import 'widgets/explore_listing_card.dart';
import 'widgets/kinetic_widgets.dart';
import 'widgets/marketplace_zone_sheet.dart';
import 'widgets/real_marketplace_map.dart';
import 'widgets/skeleton_loader.dart';
import 'chat_room_screen.dart';
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
  bool _followingSellerLocal = false;
  bool _hiddenListing = false;

  // Dynamic Layer v5.1 Strict Palette Tokens
  static const Color _dlBg = Color(0xFFFFFFFF);
  static const Color _dlSurface = Color(0xFFF6F6F6);
  static const Color _dlPill = Color(0xFFEEEEEE);
  static const Color _dlSeparator = Color(0xFFEEEEEE);
  static const Color _dlBorder = Color(0xFFE4E4E7);
  static const Color _dlInk = Color(0xFF000000);
  static const Color _dlMuted = Color(0xFF757575);
  static const Color _dlSubtle = Color(0xFF9E9E9E);
  static const Color _dlFollowBlue = Color(0xFF2997FF);
  static const Color _dlHeartRed = Color(0xFFFF3B30);
  static const Color _dlStarAmber = Color(0xFFFFB800);

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
      final initSellerId = _extractSellerIdFromAdMap(_ad);
      if (initSellerId > 0) {
        _followingSellerLocal = _state.isFollowingSeller(initSellerId);
      }
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

  bool _isFollowingSeller(int sellerId) {
    if (sellerId > 0) {
      return _state.isFollowingSeller(sellerId) || _followingSellerLocal;
    }
    return _followingSellerLocal;
  }

  void _toggleFollowSeller(int sellerId) {
    HapticFeedback.selectionClick();
    if (sellerId > 0) {
      final next = !_isFollowingSeller(sellerId);
      setState(() => _followingSellerLocal = next);
      if (_state.isFollowingSeller(sellerId) != next) {
        _state.toggleFollowSeller(sellerId);
      }
    } else {
      setState(() => _followingSellerLocal = !_followingSellerLocal);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_savingFavorite) return;
    HapticFeedback.selectionClick();
    if (!_state.isLoggedIn) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
      return;
    }
    _savingFavorite = true;
    final previous = _state.favoriteAdIds.contains(widget.adId);
    try {
      final result = await _state.toggleFavorite(
        widget.adId,
        categoryId: _ad == null ? null : _state.extractAdCategoryId(_ad!),
      );
      if (mounted && result == previous) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: _dlInk,
            content: Text(
              _state.s.tr(
                'تعذر تحديث المفضلة. حاول مرة أخرى.',
                'Impossible de modifier les favoris. Réessayez.',
                'Could not update favorites. Please try again.',
              ),
            ),
          ),
        );
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
            _ad = loadedAd is Map
                ? Map<String, dynamic>.from(loadedAd)
                : _ad;
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
      backgroundColor: _dlBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _dlPill,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: _dlPill,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.phone_fill,
                    color: _dlInk,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  sellerName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _dlInk,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  phone,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _dlInk,
                    letterSpacing:
                        AppTypography.trackingForContext(context, 0.6),
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
                              backgroundColor: _dlInk,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              content: Text(
                                s.tr(
                                  'تم نسخ رقم الهاتف',
                                  'Numéro copié',
                                  'Phone number copied',
                                ),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: _dlPill,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                CupertinoIcons.doc_on_doc,
                                size: 16,
                                color: _dlInk,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                s.tr('نسخ الرقم', 'Copier', 'Copy'),
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: _dlInk,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PressableScale(
                        onTap: () async {
                          Navigator.pop(ctx);
                          final cleanPhone =
                              phone.replaceAll(RegExp(r'[^0-9+]'), '');
                          if (cleanPhone.isEmpty) return;
                          final uri = Uri.parse('tel:$cleanPhone');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: _dlInk,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                CupertinoIcons.phone_fill,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                s.tr('اتصال الآن', 'Appeler', 'Call'),
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
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

  int _extractSellerIdFromAdMap(Map<String, dynamic>? ad) {
    if (ad == null) return 0;
    final direct = int.tryParse(
          '${ad['user_id'] ?? ad['seller_id'] ?? ad['seller']?['id'] ?? ad['user']?['id'] ?? ad['store']?['user_id'] ?? ''}',
        ) ??
        0;
    if (direct > 0) return direct;
    final slug = (ad['slug'] ?? '').toString().trim();
    final match = RegExp(r'-(\d+)-\d+$').firstMatch(slug);
    if (match != null) {
      final fromSlug = int.tryParse(match.group(1) ?? '') ?? 0;
      if (fromSlug > 0) return fromSlug;
    }
    return 0;
  }

  Future<void> _openInAppChat({
    String? presetMessage,
    bool autoSendPreset = false,
  }) async {
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
    try {
      if (_extractSellerIdFromAdMap(_ad) <= 0) {
        await _fetchDetails();
      }

      String peerName = (_ad?['store']?['name'] ??
              _ad?['seller_name'] ??
              _ad?['seller']?['name'] ??
              _ad?['user']?['name'] ??
              'Apolo Seller')
          .toString();
      String? peerAvatar = (_ad?['store']?['logo_url'] ??
              _ad?['seller_avatar'] ??
              _ad?['seller']?['avatar_url'] ??
              _ad?['seller']?['avatar'] ??
              _ad?['user']?['avatar_url'] ??
              _ad?['user']?['avatar'])
          ?.toString();
      final adTitle = (_ad?['title'] ?? '').toString();
      final adPrice =
          (_ad?['price_formatted'] ?? '${_ad?['price'] ?? ''} MAD').toString();
      final adImage = chatAdImage(_ad);

      final myUserId = int.tryParse('${_state.currentUser?['id'] ?? ''}') ?? 0;
      int rawPeerId = _extractSellerIdFromAdMap(_ad);
      int backendConvId = 0;

      try {
        final res = await _state.api.dio
            .post('/chat/start', data: {'ad_id': widget.adId});
        if (res.data is Map && res.data['status'] == 'success') {
          final conv = res.data['conversation'];
          if (conv is Map) {
            backendConvId = int.tryParse('${conv['id'] ?? 0}') ?? 0;
            final otherUser = conv['other_user'] is Map
                ? conv['other_user'] as Map
                : (conv['peer'] is Map ? conv['peer'] as Map : null);
            final backendPeerId =
                int.tryParse('${otherUser?['id'] ?? conv['peer_id'] ?? ''}') ??
                    0;
            if (backendPeerId > 0 && backendPeerId != myUserId) {
              rawPeerId = backendPeerId;
            }
            final backendPeerName =
                (otherUser?['name'] ?? '').toString().trim();
            if (backendPeerName.isNotEmpty) {
              peerName = backendPeerName;
            }
            final backendPeerAvatar =
                (otherUser?['avatar_url'] ?? otherUser?['avatar'] ?? '')
                    .toString()
                    .trim();
            if (backendPeerAvatar.isNotEmpty) {
              peerAvatar = backendPeerAvatar;
            }
          }
        }
      } catch (_) {}

      int peerId = rawPeerId > 0 ? rawPeerId : (1000000 + widget.adId);

      if (FirebaseChatService.instance.isReady &&
          myUserId > 0 &&
          peerId == myUserId) {
        final buyerConv =
            await FirebaseChatService.instance.findLatestBuyerConversationForAd(
          sellerUserId: myUserId,
          adId: widget.adId,
        );
        if (buyerConv != null && (buyerConv['peer_id'] as int? ?? 0) > 0) {
          peerId = buyerConv['peer_id'] as int;
          peerName = (buyerConv['peer_name'] ?? peerName).toString();
          final bAvatar = (buyerConv['peer_avatar'] ?? '').toString();
          if (bAvatar.isNotEmpty) peerAvatar = bAvatar;
        }
      }

      if (FirebaseChatService.instance.isReady && myUserId > 0) {
        final myName = (_state.currentUser?['name'] ??
                _state.currentUser?['full_name'] ??
                'Apolo User')
            .toString();
        final myAvatar = (_state.currentUser?['avatar_url'] ??
                _state.currentUser?['avatar'] ??
                '')
            .toString();
        final docId = await FirebaseChatService.instance.ensureConversation(
          myUserId: myUserId,
          myName: myName,
          myAvatar: myAvatar,
          peerUserId: peerId,
          peerName: peerName,
          peerAvatar: peerAvatar ?? '',
          adId: widget.adId,
          adTitle: adTitle,
          adPrice: adPrice,
          adImage: adImage ?? '',
        );

        final trimmedPreset = (presetMessage ?? '').trim();
        bool sentImmediately = false;
        if (autoSendPreset && trimmedPreset.isNotEmpty && peerId != myUserId) {
          await FirebaseChatService.instance.sendTextMessage(
            docId: docId,
            myUserId: myUserId,
            myName: myName,
            myAvatar: myAvatar,
            peerUserId: peerId,
            peerName: peerName,
            peerAvatar: peerAvatar ?? '',
            body: trimmedPreset,
            adId: widget.adId,
            adTitle: adTitle,
            adPrice: adPrice,
            adImage: adImage ?? '',
          );
          sentImmediately = true;
          if (backendConvId > 0) {
            try {
              await _state.api.dio.post(
                '/chat/conversations/$backendConvId/messages',
                data: {'body': trimmedPreset, 'message': trimmedPreset},
              );
            } catch (_) {}
          }
        }

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatRoomScreen(
                conversationId:
                    backendConvId > 0 ? backendConvId : docId.hashCode.abs(),
                backendConversationId: backendConvId > 0 ? backendConvId : null,
                adId: widget.adId,
                firestoreDocId: docId,
                peerId: peerId,
                peerName: peerName,
                adTitle: adTitle,
                peerAvatar: peerAvatar,
                adImage: adImage,
                adPrice: adPrice,
                initialDraft: sentImmediately ? null : presetMessage,
              ),
            ),
          );
          return;
        }
      }

      if (mounted && backendConvId > 0) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(
              conversationId: backendConvId,
              backendConversationId: backendConvId,
              adId: widget.adId,
              peerId: peerId,
              peerName: peerName,
              adTitle: adTitle,
              peerAvatar: peerAvatar,
              adImage: adImage,
              adPrice: adPrice,
              initialDraft: presetMessage,
              autoSendInitialDraft: autoSendPreset,
            ),
          ),
        );
        return;
      }
    } catch (_) {
    } finally {
      _openingChat = false;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _dlInk,
          content: Text(
            _state.s.tr(
              'تعذر فتح المحادثة. حاول مرة أخرى.',
              'Impossible de démarrer la conversation. Réessayez.',
              'Could not start conversation. Please try again.',
            ),
          ),
        ),
      );
    }
  }

  void _openFullScreenImage(String imgUrl, String caption) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.96),
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Center(
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 4.0,
            child: imgUrl.startsWith('assets/')
                ? Image.asset(imgUrl, fit: BoxFit.contain)
                : AppImage(url: imgUrl, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  Future<void> _blockSeller(int sellerId) async {
    final myUserId = int.tryParse('${_state.currentUser?['id'] ?? 0}') ?? 0;
    final sellerName = (_ad?['store']?['name'] ??
            _ad?['seller_name'] ??
            _ad?['seller']?['name'] ??
            'Apolo Seller')
        .toString();
    final sellerAvatar = (_ad?['store']?['logo_url'] ??
            _ad?['seller_avatar'] ??
            _ad?['seller']?['avatar_url'] ??
            '')
        .toString();
    await FirebaseChatService.instance.blockTarget(
      myUserId: myUserId,
      targetId: sellerId > 0 ? '$sellerId' : sellerName,
      targetName: sellerName,
      targetAvatar: sellerAvatar,
    );
    if (_state.isLoggedIn && sellerId > 0) {
      try {
        await _state.api.dio
            .post('/users/block', data: {'blocked_user_id': sellerId});
      } catch (_) {}
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _dlInk,
          content: Text(
            _state.s.tr(
              'تم حظر هذا المستخدم بنجاح',
              'Utilisateur bloqué',
              'User blocked',
            ),
          ),
        ),
      );
      Navigator.pop(context);
    }
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
      backgroundColor: _dlBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _dlPill,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 18),
                _SheetActionRow(
                  icon: CupertinoIcons.flag_fill,
                  iconColor: _dlHeartRed,
                  title: s.tr(
                    'الإبلاغ عن هذا الإعلان أو محتوى AI',
                    'Signaler cette annonce / contenu IA',
                    'Report this listing or AI content',
                  ),
                  subtitle: s.tr(
                    'مراجعة فورية من فريق الثقة والأمان',
                    'Vérification rapide par notre équipe',
                    'Quick review by our Trust & Safety team',
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    showApoloReportSheet(
                      context,
                      targetType: 'ad',
                      targetId: '${widget.adId}',
                      targetName: (ad['title'] ?? '').toString(),
                      reportedUserId: '${seller?['id'] ?? ''}',
                    );
                  },
                ),
                if (seller != null && !isOwner) ...[
                  const SizedBox(height: 10),
                  _SheetActionRow(
                    icon: CupertinoIcons.nosign,
                    iconColor: _dlInk,
                    title: s.blockUser,
                    subtitle: s.tr(
                      'إخفاء جميع إعلانات هذا البائع',
                      'Masquer les annonces de ce vendeur',
                      'Hide all listings from this seller',
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

  Future<void> _openVideoTour(
    String? videoUrl,
    List<String> images,
    String title,
  ) async {
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
      _openFullScreenImage(
        images[_currentImgIndex.clamp(0, images.length - 1)],
        title,
      );
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
      backgroundColor: _dlBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _dlPill,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 18),
                _SheetActionRow(
                  icon: CupertinoIcons.chat_bubble_2_fill,
                  iconColor: _dlInk,
                  title: s.tr(
                    'محادثة فورية عبر Apolo',
                    'Message sur Apolo',
                    'Message on Apolo',
                  ),
                  subtitle: s.tr(
                    'تواصل مباشرة مع $sellerDisplayName داخل التطبيق',
                    'Discuter directement avec $sellerDisplayName',
                    'Chat directly with $sellerDisplayName',
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
                    iconColor: _dlInk,
                    title: s.tr(
                      'اتصال هاتفي مباشر',
                      'Appeler $sellerDisplayName',
                      'Call $sellerDisplayName',
                    ),
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
        backgroundColor: _dlBg,
        body: AdDetailSkeleton(),
      );
    }
    if (ad == null) {
      return Scaffold(
        backgroundColor: _dlBg,
        body: SafeArea(
          child: Column(
            children: [
              ApoloDlTopNav(
                title: s.tr('تفاصيل الإعلان', 'Détails', 'Details'),
              ),
              Expanded(
                child: IllustratedStateView(
                  assetPath: 'assets/images/state_empty_ads.png',
                  title: s.tr(
                    'الإعلان غير متوفر',
                    'Annonce introuvable',
                    'Listing unavailable',
                  ),
                  subtitle: s.tr(
                    'ربما تم بيع هذا المنتج أو حذفه من طرف البائع.',
                    'Cet article a peut-être été vendu ou retiré.',
                    'This item may have been sold or removed by the seller.',
                  ),
                  actionLabel: s.tr('العودة', 'Retour', 'Go back'),
                  onAction: () => Navigator.pop(context),
                ),
              ),
            ],
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
          '${seller?['id'] ?? ad['seller_id'] ?? ad['user_id'] ?? ''}',
        ) ??
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

    final String locationSubtitle =
        (ad['location_display'] ?? ad['location'] ?? '')
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

    final bool isNegotiable = ad['negotiable'] == true ||
        ad['is_negotiable'] == true ||
        metadata['negotiable'] == true;
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
        _buildQuickSpecCards(
      ad,
      s,
      isStayListing,
      viewsCount,
      cityName,
      metadata,
      rawSpecs,
    );

    final List<MapEntry<String, String>> structuredSpecs = [
      MapEntry(s.tr('القسم', 'Catégorie', 'Category'), categoryName),
      MapEntry(s.tr('المدينة', 'Ville', 'City'), cityName),
      MapEntry(
        s.tr('الحالة', 'État', 'Condition'),
        (ad['condition'] ??
                metadata['condition'] ??
                s.tr('غير محددة', 'Non précisé', 'Not specified'))
            .toString(),
      ),
      MapEntry(
        s.tr('رقم الإعلان', 'Référence', 'Reference'),
        '#AP-${widget.adId}',
      ),
      ...rawSpecs,
    ];

    return Scaffold(
      key: const Key('dl-ad-detail-screen'),
      backgroundColor: _dlBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Dynamic Layer v5.1 Top Navigation Bar (`52px`, `40×40` `#EEEEEE` buttons)
            _buildDlTopNav(
              s: s,
              ad: ad,
              seller: seller,
              isOwner: isOwner,
              isFav: isFav,
            ),

            // 2. Scrollable Dynamic Layer v5.1 Content Canvas
            Expanded(
              child: ListView(
                scrollCacheExtent: const ScrollCacheExtent.pixels(700),
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 120),
                children: [
                  // Hero Media Gallery Card (`24px` radius, crisp flat frame)
                  _buildHeroImageCard(
                    s: s,
                    ad: ad,
                    images: images,
                    categoryAsset: categoryAsset,
                    heroTypeTag: heroTypeTag,
                    viewsCount: viewsCount,
                    isNegotiable: isNegotiable,
                    metadata: metadata,
                  ),

                  // Multi-image thumbnail selector (`52×52` `12px` radius, `2px` `#000000` active ring)
                  if (images.length > 1)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                                  duration: const Duration(milliseconds: 240),
                                  curve: Curves.easeOutCubic,
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 52,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: active ? _dlInk : _dlPill,
                                    width: active ? 2 : 1,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: images[idx].startsWith('assets/')
                                      ? Image.asset(
                                          images[idx],
                                          fit: BoxFit.cover,
                                        )
                                      : AppImage(
                                          url: images[idx],
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  // Title, Price & Location Meta Header
                  _buildMarketplaceHeader(
                    s: s,
                    ad: ad,
                    title: (ad['title'] ?? '').toString(),
                    locationSubtitle: locationSubtitle,
                    priceFormatted: priceFormatted,
                    priceFrequency: priceFrequency,
                  ),

                  // Inline Dynamic Layer Quick Message Card (or Boost card for Owner)
                  _buildMessageSellerCard(
                    s: s,
                    ad: ad,
                    isOwner: isOwner,
                  ),

                  // 4 Dynamic Layer `#EEEEEE` Circular Quick Actions
                  _buildQuickActionCircleRow(
                    s: s,
                    ad: ad,
                    isFav: isFav,
                    priceFormatted: priceFormatted,
                  ),

                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: ApoloDlSeparator(indentStart: 16, indentEnd: 16),
                  ),

                  // Description + 2×2 Spec Cards + Structured Metadata + Direct Phone Row
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
                    padding: EdgeInsets.only(top: 16),
                    child: ApoloDlSeparator(indentStart: 16, indentEnd: 16),
                  ),

                  // Seller Profile Card with ApoloVerifiedBadge, ApoloRankBadge & `#2997FF` Follow Pill
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
                    padding: EdgeInsets.only(top: 16),
                    child: ApoloDlSeparator(indentStart: 16, indentEnd: 16),
                  ),

                  // Approximate Location Map Preview
                  _buildLocationSection(
                    s: s,
                    ad: ad,
                    cityName: cityName,
                    locationSubtitle: locationSubtitle,
                  ),

                  // `#EEEEEE` Related Search Chips
                  _buildRelatedSearchesSection(
                    s: s,
                    ad: ad,
                    categoryName: categoryName,
                    cityName: cityName,
                  ),

                  // Hide Listing & Trust/Safety Card
                  _buildHideListingCard(
                    s: s,
                    ad: ad,
                    seller: seller,
                    isOwner: isOwner,
                  ),

                  // Similar Listings Feed
                  if (_relatedAds.isNotEmpty) _buildRelatedExploreFeed(s),
                ],
              ),
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

  Widget _buildDlTopNav({
    required AppStrings s,
    required Map<String, dynamic> ad,
    required Map<String, dynamic>? seller,
    required bool isOwner,
    required bool isFav,
  }) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Container(
      key: const Key('dl-detail-top-nav'),
      height: 52,
      color: _dlBg,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          ApoloDlIconCircleButton(
            key: const Key('dl-detail-back-btn'),
            icon: isRtl
                ? CupertinoIcons.chevron_forward
                : CupertinoIcons.chevron_back,
            iconSize: 19,
            tooltip: s.tr('رجوع', 'Retour', 'Back'),
            onPressed: () => Navigator.maybePop(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              s.tr('تفاصيل الإعلان', 'Détails', 'Details'),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _dlInk,
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ApoloDlIconCircleButton(
            key: const Key('dl-detail-fav-btn'),
            icon: isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
            iconSize: 19,
            iconColor: isFav ? _dlHeartRed : _dlInk,
            tooltip: s.tr('المفضلة', 'Favori', 'Favorite'),
            onPressed: _toggleFavorite,
          ),
          const SizedBox(width: 8),
          ApoloDlIconCircleButton(
            key: const Key('dl-detail-more-btn'),
            icon: CupertinoIcons.ellipsis,
            iconSize: 19,
            tooltip: s.tr('المزيد', 'Plus', 'More'),
            onPressed: () => _showMoreActionsSheet(s, ad, seller, isOwner),
          ),
        ],
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
          .map(
            (m) => (
              value: (m['value'] ?? '—').toString(),
              label: (m['label'] ?? '').toString(),
            ),
          )
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
    required String categoryAsset,
    required String heroTypeTag,
    required int viewsCount,
    required bool isNegotiable,
    required Map<String, dynamic> metadata,
  }) {
    final String videoUrl =
        (ad['video_url'] ?? metadata['video_url'] ?? ad['video'] ?? '')
            .toString()
            .trim();
    final String videoDuration =
        (ad['video_duration'] ?? metadata['video_duration'] ?? '')
            .toString()
            .trim();
    final bool showVideoTour = videoUrl.isNotEmpty ||
        ad['has_video'] == true ||
        videoDuration.isNotEmpty;

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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: SizedBox(
        height: 312,
        child: Container(
          decoration: BoxDecoration(
            color: _dlSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _dlSeparator, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (images.isNotEmpty)
                PageView.builder(
                  controller: _pageCtrl,
                  physics: const BouncingScrollPhysics(),
                  itemCount: images.length,
                  onPageChanged: (i) => setState(() => _currentImgIndex = i),
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
                                  size: 130,
                                ),
                              ),
                            )
                          : AppImage(
                              url: imgUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              fallback: Container(
                                color: _dlSurface,
                                alignment: Alignment.center,
                                child: Floating3DIllustration(
                                  assetPath: categoryAsset,
                                  size: 130,
                                ),
                              ),
                            ),
                    );
                  },
                )
              else
                Container(
                  color: _dlSurface,
                  alignment: Alignment.center,
                  child: Floating3DIllustration(
                    assetPath: categoryAsset,
                    size: 140,
                  ),
                ),

              // Subtle bottom gradient scrim for clean pill contrast
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 80,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.28),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

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
                bottom: 12,
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
                            if (heroTypeTag.isNotEmpty) ...[
                              _ImageTagPill(label: heroTypeTag),
                              const SizedBox(width: 6),
                            ],
                            _ImageTagPill(
                              leadingIcon: Icons.star_rounded,
                              leadingIconColor: _dlStarAmber,
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
                          images[
                              _currentImgIndex.clamp(0, images.length - 1)],
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _dlInk,
              letterSpacing: AppTypography.trackingForContext(context, -0.4),
              height: 1.22,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: PriceText(
                  priceFormatted,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: _dlInk,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (priceFrequency.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _dlPill,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    priceFrequency,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _dlInk,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 5,
            runSpacing: 2,
            children: [
              Text(
                listedLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: _dlMuted,
                ),
              ),
              if (locationSubtitle.isNotEmpty) ...[
                const Text(
                  '·',
                  style: TextStyle(
                    fontSize: 13,
                    color: _dlMuted,
                  ),
                ),
                Text(
                  locationSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _dlMuted,
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
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _dlSurface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: _dlInk,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    CupertinoIcons.bolt_fill,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    s.tr(
                      'ترقية الإعلان ومضاعفة المشاهدات (Boost ⚡)',
                      'Booster cette annonce ⚡',
                      'Boost this listing ⚡',
                    ),
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: _dlInk,
                    ),
                  ),
                ),
                Icon(
                  s.isAr
                      ? CupertinoIcons.chevron_left
                      : CupertinoIcons.chevron_right,
                  size: 16,
                  color: _dlMuted,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
        decoration: BoxDecoration(
          color: _dlSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: _dlInk,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    CupertinoIcons.chat_bubble_fill,
                    size: 13.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.tr(
                      'راسل البائع',
                      'Contacter le vendeur',
                      'Message seller',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _dlInk,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _dlBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    s.tr('رد سريع', 'Réponse rapide', 'Fast reply'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _dlInk,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            Row(
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _dlBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: AlignmentDirectional.centerStart,
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        inputDecorationTheme: const InputDecorationTheme(
                          filled: false,
                          fillColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      child: TextField(
                        key: const Key('detail-quick-msg'),
                        controller: _quickMsgCtrl,
                        minLines: 1,
                        maxLines: 2,
                        cursorColor: _dlInk,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: _dlInk,
                          height: 1.3,
                          fontWeight: FontWeight.w400,
                        ),
                        decoration: InputDecoration(
                          filled: false,
                          fillColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          isDense: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 8),
                          hintText: s.tr(
                            'اكتب رسالتك هنا...',
                            'Écrivez votre message...',
                            'Write a message...',
                          ),
                          hintStyle: const TextStyle(
                            fontSize: 13.5,
                            color: _dlSubtle,
                          ),
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
                      autoSendPreset: draft.isNotEmpty,
                    );
                  },
                  child: Container(
                    height: 44,
                    constraints: const BoxConstraints(minWidth: 76),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: _dlInk,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      s.tr('إرسال', 'Envoyer', 'Send'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
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
        await _state.api.dio.post(
          '/saved-searches',
          data: {'query': (ad['title'] ?? '').toString().trim()},
        );
      } catch (_) {}
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _dlInk,
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
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _DlActionCircle(
              icon: _alertEnabled
                  ? CupertinoIcons.bell_fill
                  : CupertinoIcons.bell,
              label: s.tr('تنبيهات', 'Alertes', 'Alerts'),
              active: _alertEnabled,
              onTap: () => _handleAlertsTap(s, ad),
            ),
          ),
          Expanded(
            child: _DlActionCircle(
              icon: CupertinoIcons.chat_bubble_fill,
              label: s.tr('رسالة', 'Message', 'Message'),
              onTap: () => _openInAppChat(),
            ),
          ),
          Expanded(
            child: _DlActionCircle(
              icon: CupertinoIcons.share,
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
            child: _DlActionCircle(
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
    EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(16, 12, 16, 0),
  }) {
    if (cards.isEmpty) return const SizedBox.shrink();
    final rows = <Widget>[];
    for (int i = 0; i < cards.length; i += 2) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 8));
      rows.add(
        Row(
          children: [
            Expanded(
              child: _SpecStatCard(
                value: cards[i].value,
                label: cards[i].label,
                icon: _specIconForLabel(cards[i].label),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: i + 1 < cards.length
                  ? _SpecStatCard(
                      value: cards[i + 1].value,
                      label: cards[i + 1].label,
                      icon: _specIconForLabel(cards[i + 1].label),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: padding,
      child: Column(children: rows),
    );
  }

  IconData _specIconForLabel(String label) {
    final l = label.toLowerCase();
    if (l.contains('guest') || l.contains('ضيف') || l.contains('voyageur')) {
      return CupertinoIcons.person_2_fill;
    }
    if (l.contains('bed') ||
        l.contains('غرف') ||
        l.contains('سري') ||
        l.contains('chambre')) {
      return CupertinoIcons.bed_double_fill;
    }
    if (l.contains('bath') || l.contains('حمام') || l.contains('bain')) {
      return Icons.bathtub_outlined;
    }
    if (l.contains('view') || l.contains('مشاهد') || l.contains('vue')) {
      return CupertinoIcons.eye_fill;
    }
    if (l.contains('city') || l.contains('مدين') || l.contains('ville')) {
      return CupertinoIcons.location_solid;
    }
    if (l.contains('cond') || l.contains('حال') || l.contains('état')) {
      return CupertinoIcons.checkmark_seal_fill;
    }
    return CupertinoIcons.tag_fill;
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
            decoration: BoxDecoration(
              color: _dlSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.tr('الوصف', 'Description', 'Description'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _dlInk,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  fullDescription,
                  maxLines: _descExpanded ? 50 : 4,
                  overflow: _descExpanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.48,
                    color: _dlInk,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (fullDescription.length > 140) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => setState(() => _descExpanded = !_descExpanded),
                    child: Text(
                      _descExpanded
                          ? s.tr('عرض أقل', 'Voir moins', 'See less')
                          : s.tr('قراءة المزيد', 'Lire la suite', 'See more'),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: _dlFollowBlue,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 2×2 Dynamic Layer Spec Grid
          _buildQuickSpecGrid(
            quickSpecCards,
            padding: const EdgeInsets.only(top: 10),
          ),

          // Extra Key-Value Metadata Group
          if (rawSpecs.length > 2) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _dlSurface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: structuredSpecs.skip(2).take(6).toList().asMap().entries.map((entry) {
                  final isLast =
                      entry.key == structuredSpecs.skip(2).take(6).length - 1;
                  final e = entry.value;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                e.key,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _dlMuted,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                e.value,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: _dlInk,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLast) const ApoloDlSeparator(),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],

          // Direct Phone Row
          if (!isOwner && phone != null && phone.isNotEmpty) ...[
            const SizedBox(height: 10),
            PressableScale(
              onTap: () => _showCallSheetOrDial(phone, sellerDisplayName),
              child: Container(
                width: double.infinity,
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: _dlSurface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: _dlInk,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        CupertinoIcons.phone_fill,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        s.tr(
                          'اتصال هاتفي بالبائع',
                          'Appeler le vendeur',
                          'Call seller',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _dlInk,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _dlBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          phone,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _dlInk,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
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
    final String hostTitle =
        (ad['host_title'] ?? '').toString().trim().isNotEmpty
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
                ? s.tr(
                    'متجر على Apolo · $cityName',
                    'Boutique Apolo · $cityName',
                    'Apolo Store · $cityName',
                  )
                : s.tr(
                    'بائع على Apolo · $cityName',
                    'Vendeur Apolo · $cityName',
                    'Apolo Seller · $cityName',
                  )));

    final String hostInitials =
        (ad['host_initials'] ?? _initialsFromName(sellerDisplayName))
            .toString()
            .trim();
    final String? avatarUrl =
        (store?['logo_url'] ?? seller?['avatar_url'])?.toString().trim();

    final double? ratingVal = double.tryParse(
      (seller?['rating'] ?? seller?['avg_rating'] ?? ad['seller_rating'] ?? '')
          .toString(),
    );
    final int? reviewsCountVal = int.tryParse(
      (seller?['reviews_count'] ?? ad['seller_reviews_count'] ?? '').toString(),
    );

    final bool isVerifiedSeller =
        seller?['is_verified'] == true || store != null;
    final bool isProPlusSeller =
        store?['is_pro_plus'] == true || seller?['is_pro_plus'] == true;
    final sellerRank = ApoloSellerRank.resolve(
      user: seller,
      isProPlus: isProPlusSeller,
      isBusiness: store != null,
      isVerified: isVerifiedSeller,
    );
    final bool isFollowing = _isFollowingSeller(sellerId);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                        color: _dlInk,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      s.isAr
                          ? CupertinoIcons.chevron_left
                          : CupertinoIcons.chevron_right,
                      size: 15,
                      color: _dlMuted,
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
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _dlPill,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: _dlInk,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        s.tr('عرض التقييمات', 'Voir les avis', 'See reviews'),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _dlInk,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _dlSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
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
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: _dlPill,
                            shape: BoxShape.circle,
                          ),
                          clipBehavior: Clip.antiAlias,
                          alignment: Alignment.center,
                          child: (avatarUrl != null && avatarUrl.isNotEmpty)
                              ? AppImage(
                                  url: avatarUrl,
                                  width: 52,
                                  height: 52,
                                  fit: BoxFit.cover,
                                  fallback: _InitialsCircle(
                                    initials: hostInitials,
                                  ),
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
                                        fontWeight: FontWeight.w700,
                                        color: _dlInk,
                                      ),
                                    ),
                                  ),
                                  if (isVerifiedSeller) ...[
                                    const SizedBox(width: 5),
                                    ApoloVerifiedBadge(
                                      size: 16,
                                      interactive: true,
                                      rank: sellerRank,
                                      isProPlus: isProPlusSeller,
                                      isBusiness: store != null,
                                    ),
                                  ],
                                  const SizedBox(width: 5),
                                  ApoloRankBadge(
                                    rank: sellerRank,
                                    size: 17,
                                    isVerified: isVerifiedSeller,
                                    isProPlus: isProPlusSeller,
                                    isBusiness: store != null,
                                    interactive: true,
                                  ),
                                ],
                              ),
                              if (ratingVal != null && ratingVal > 0) ...[
                                const SizedBox(height: 3),
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    ...List.generate(5, (i) {
                                      final filled = i + 1 <= ratingVal.floor();
                                      final half =
                                          !filled && (ratingVal - i) >= 0.4;
                                      return Icon(
                                        half
                                            ? Icons.star_half_rounded
                                            : (filled
                                                ? Icons.star_rounded
                                                : Icons.star_outline_rounded),
                                        size: 13.5,
                                        color: _dlStarAmber,
                                      );
                                    }),
                                    const SizedBox(width: 4),
                                    Text(
                                      ratingVal.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: _dlInk,
                                      ),
                                    ),
                                    if (reviewsCountVal != null)
                                      Text(
                                        ' ($reviewsCountVal)',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: _dlMuted,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 3),
                              Text(
                                hostSubtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w400,
                                  color: _dlMuted,
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
                    onTap: () => _toggleFollowSeller(sellerId),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isFollowing ? _dlPill : _dlFollowBlue,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        isFollowing
                            ? s.tr('متابَع', 'Suivi', 'Following')
                            : s.tr('متابعة', 'Suivre', 'Follow'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isFollowing ? _dlInk : Colors.white,
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
    );
  }

  Widget _buildLocationSection({
    required AppStrings s,
    required Map<String, dynamic> ad,
    required String cityName,
    required String locationSubtitle,
  }) {
    final loc = MarketplaceLocation.resolveAdLocation(ad);
    final distKm = MarketplaceLocation.distanceBetweenAdAndZone(
      ad,
      _state.userLat,
      _state.userLng,
    );
    final bool inZone = distKm != null &&
        (!_state.hasActiveZone || distKm <= _state.zoneRadiusKm);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.tr('موقع الإعلان', 'Localisation', 'Location'),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _dlInk,
                ),
              ),
              MarketplaceZonePill(
                state: _state,
                compact: true,
                onTap: () => showMarketplaceZoneSheet(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RealMarketplaceMap(
            lat: loc.lat,
            lng: loc.lng,
            cityLabel: cityName,
            circleRadiusKm: 3.4,
            userLat: _state.userLat,
            userLng: _state.userLng,
            height: 188,
            borderRadius: 20,
            interactive: true,
            topOverlay: distKm == null
                ? null
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: inZone
                                ? const Color(0xFF15803D)
                                : _dlFollowBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          inZone
                              ? s.tr(
                                  'في منطقتك · ${distKm.round()} كم',
                                  'Dans votre zone · ${distKm.round()} km',
                                  'In your zone · ${distKm.round()} km',
                                )
                              : s.tr(
                                  'يبعد ${distKm.round()} كم',
                                  'À ${distKm.round()} km',
                                  '${distKm.round()} km away',
                                ),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _dlInk,
                          ),
                        ),
                      ],
                    ),
                  ),
            onExpandTap: () => showFullMarketplaceMapDialog(
              context: context,
              s: s,
              lat: loc.lat,
              lng: loc.lng,
              cityLabel: cityName,
              locationSubtitle: locationSubtitle,
              userLat: _state.userLat,
              userLng: _state.userLng,
              onFilterToListingZone: () {
                final match = loc.match;
                if (match != null) {
                  _state.setUserZone(
                    lat: loc.lat,
                    lng: loc.lng,
                    nameAr: match.nameAr,
                    nameFr: match.nameFr,
                    radiusKm: _state.zoneRadiusKm > 0
                        ? _state.zoneRadiusKm
                        : MarketplaceLocation.defaultZoneRadiusKm,
                    enabled: true,
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cityName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: _dlInk,
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
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: _dlMuted,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => showFullMarketplaceMapDialog(
                  context: context,
                  s: s,
                  lat: loc.lat,
                  lng: loc.lng,
                  cityLabel: cityName,
                  locationSubtitle: locationSubtitle,
                  userLat: _state.userLat,
                  userLng: _state.userLng,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _dlPill,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    s.tr('عرض الخريطة', 'Voir la carte', 'Full map'),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _dlInk,
                    ),
                  ),
                ),
              ),
            ],
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
      final words =
          rawTitle.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
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
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.tr(
              'عمليات بحث ذات صلة',
              'Recherches similaires',
              'Related searches',
            ),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _dlInk,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: _dlPill,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.search,
                        size: 14.5,
                        color: _dlInk,
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
                            color: _dlInk,
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
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _dlSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text.rich(
              TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  color: _dlMuted,
                  height: 1.42,
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _dlInk,
                    ),
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
                    backgroundColor: _dlInk,
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
                height: 42,
                decoration: BoxDecoration(
                  color: _dlBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _hiddenListing
                          ? CupertinoIcons.eye
                          : CupertinoIcons.eye_slash,
                      size: 16,
                      color: _dlInk,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      _hiddenListing
                          ? s.tr('تم الإخفاء', 'Masquée', 'Hidden')
                          : s.tr(
                              'إخفاء الإعلان',
                              'Masquer l’annonce',
                              'Hide listing',
                            ),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: _dlInk,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
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
                        size: 13.5,
                        color: _dlMuted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        s.tr(
                          'الإبلاغ أو الأمان',
                          'Signaler / Sécurité',
                          'Report & Safety',
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _dlMuted,
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

  Widget _buildRelatedExploreFeed(AppStrings s) {
    final rawRelated = _relatedAds
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final related = _state.applyZoneToAds(
      rawRelated,
      enforceRadiusFilter: false,
    );
    if (related.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 14),
          child: Text(
            s.tr(
              'إعلانات مشابهة فـ نفس القسم',
              'Annonces similaires',
              'Similar listings',
            ),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _dlInk,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 680;
            if (isWide) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 400,
                  mainAxisExtent: 374,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemCount: related.length,
                itemBuilder: (_, idx) => ExploreListingCard(ad: related[idx]),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: related.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (_, idx) => ExploreListingCard(ad: related[idx]),
            );
          },
        ),
      ],
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
    final String totalUnit = (ad['total_unit_label'] ??
            (ad.containsKey('total_price_display') ? 'total' : ''))
        .toString()
        .trim();
    final String totalSubtitle = (ad['total_subtitle'] ??
                ad['stay_dates_label'] ??
                '')
            .toString()
            .trim()
            .isNotEmpty
        ? (ad['total_subtitle'] ?? ad['stay_dates_label']).toString().trim()
        : (isStayListing
            ? 'taxes incl.'
            : '${isNegotiable ? s.tr('ثمن قابل للنقاش', 'Prix négociable', 'Negotiable') : s.tr('معاينة مباشرة', 'Remise directe', 'Meetup / Delivery')} · $cityName');
    final String ctaLabel =
        (ad['cta_label'] ?? '').toString().trim().isNotEmpty
            ? ad['cta_label'].toString().trim()
            : (isOwner
                ? s.tr('ترقية الإعلان ⚡', 'Booster ⚡', 'Boost ⚡')
                : (isStayListing
                    ? s.tr('احجز الآن', 'Réserver', 'Book now')
                    : s.tr('تواصل للشراء', 'Contacter', 'Contact seller')));

    return Container(
      key: const Key('dl-detail-bottom-bar'),
      decoration: const BoxDecoration(
        color: _dlBg,
        border: Border(
          top: BorderSide(color: _dlSeparator, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                                fontSize: 18.5,
                                fontWeight: FontWeight.w800,
                                color: _dlInk,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            if (totalUnit.isNotEmpty)
                              TextSpan(
                                text: ' $totalUnit',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: _dlMuted,
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
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: _dlMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isOwner && phone != null && phone.isNotEmpty) ...[
                const SizedBox(width: 8),
                PressableScale(
                  key: const Key('dl-detail-call-btn'),
                  onTap: () => _showCallSheetOrDial(phone, sellerDisplayName),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: _dlPill,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      CupertinoIcons.phone_fill,
                      size: 19,
                      color: _dlInk,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 10),
              PressableScale(
                key: const Key('dl-detail-primary-cta'),
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
                  constraints: const BoxConstraints(
                    minWidth: 140,
                    minHeight: 48,
                  ),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: _dlInk,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      ctaLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
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
              color: Colors.black.withValues(alpha: 0.42),
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
                    color: Colors.black,
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
                          color: Colors.white.withValues(alpha: 0.76),
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
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isLight
                ? Colors.white
                : Colors.black.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(999),
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
                      (isLight ? Colors.black : Colors.white),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isLight ? FontWeight.w700 : FontWeight.w600,
                  color: isLight ? Colors.black : Colors.white,
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
  final IconData icon;

  const _SpecStatCard({
    required this.value,
    required this.label,
    this.icon = CupertinoIcons.tag_fill,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 15,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF757575),
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    height: 1.15,
                  ),
                ),
              ],
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
          color: Colors.black,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
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
          color: const Color(0xFFF6F6F6),
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
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF757575),
                      fontWeight: FontWeight.w400,
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

class _DlActionCircle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _DlActionCircle({
    required this.icon,
    required this.label,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: active ? Colors.black : const Color(0xFFEEEEEE),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 19,
              color: active ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
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
  int _minStarsFilter = 0;
  bool _highestFirst = false;
  final Set<int> _helpfulIndices = {};

  static const Color _dlBg = Color(0xFFFFFFFF);
  static const Color _dlSurface = Color(0xFFF6F6F6);
  static const Color _dlPill = Color(0xFFEEEEEE);
  static const Color _dlInk = Color(0xFF000000);
  static const Color _dlMuted = Color(0xFF757575);
  static const Color _dlStarAmber = Color(0xFFFFB800);

  List<Map<String, dynamic>> get _reviews {
    final raw = (widget.rawReviews ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((r) {
      if (_minStarsFilter == 0) return true;
      final stars = int.tryParse((r['rating'] ?? 0).toString()) ?? 0;
      return _minStarsFilter == 5 ? stars == 5 : stars >= _minStarsFilter;
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

    final Map<int, int> counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in (widget.rawReviews ?? []).whereType<Map>()) {
      final st = int.tryParse((r['rating'] ?? 0).toString()) ?? 0;
      if (counts.containsKey(st)) counts[st] = counts[st]! + 1;
    }
    final int maxCount = counts.values.fold<int>(1, (m, c) => c > m ? c : m);

    return Scaffold(
      backgroundColor: _dlBg,
      body: SafeArea(
        child: Column(
          children: [
            ApoloDlTopNav(
              title: s.tr('جميع التقييمات', 'Tous les avis', 'All Reviews'),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  // Dynamic Layer v5.1 Rating Summary Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _dlSurface,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                s.tr(
                                  'تقييم البائع',
                                  'Note du vendeur',
                                  'Seller rating',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _dlInk,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                widget.sellerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: _dlMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  ratingValue > 0
                                      ? ratingValue.toStringAsFixed(1)
                                      : '—',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    color: _dlInk,
                                    height: 1.0,
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(5, (i) {
                                    final filled = i + 1 <= ratingValue.floor();
                                    final half =
                                        !filled && (ratingValue - i) >= 0.4;
                                    return Icon(
                                      half
                                          ? Icons.star_half_rounded
                                          : (filled
                                              ? Icons.star_rounded
                                              : Icons.star_outline_rounded),
                                      size: 15,
                                      color: _dlStarAmber,
                                    );
                                  }),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '($totalCount)',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: _dlMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Container(
                              width: 1,
                              height: 92,
                              color: _dlPill,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                children: [
                                  for (int star = 5; star >= 1; star--)
                                    GestureDetector(
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        setState(() {
                                          _minStarsFilter =
                                              _minStarsFilter == star
                                                  ? 0
                                                  : star;
                                        });
                                      },
                                      behavior: HitTestBehavior.opaque,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 3.5,
                                        ),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 54,
                                              child: Text(
                                                s.tr(
                                                  '$star نجوم',
                                                  '$star é.',
                                                  star == 1
                                                      ? '1 star'
                                                      : '$star stars',
                                                ),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight:
                                                      _minStarsFilter == star
                                                          ? FontWeight.w700
                                                          : FontWeight.w500,
                                                  color: _dlInk,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(99),
                                                child: LinearProgressIndicator(
                                                  value: (counts[star] ?? 0) /
                                                      maxCount,
                                                  minHeight: 6,
                                                  backgroundColor: _dlPill,
                                                  valueColor:
                                                      const AlwaysStoppedAnimation<
                                                          Color>(_dlInk),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            SizedBox(
                                              width: 18,
                                              child: Text(
                                                '${counts[star] ?? 0}',
                                                textAlign: TextAlign.end,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: _dlMuted,
                                                  fontFeatures: [
                                                    FontFeature
                                                        .tabularFigures(),
                                                  ],
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
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.tr(
                            'تقييمات البائع ($totalCount)',
                            'Avis sur le vendeur ($totalCount)',
                            'Seller reviews ($totalCount)',
                          ),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: _dlInk,
                          ),
                        ),
                      ),
                      if (_minStarsFilter != 0)
                        GestureDetector(
                          onTap: () => setState(() => _minStarsFilter = 0),
                          child: Text(
                            s.tr('عرض الكل', 'Tout afficher', 'Show all'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _dlInk,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Dynamic Layer Filter & Sort Pills (`#000000` active / `#EEEEEE` idle)
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _minStarsFilter = _minStarsFilter == 0 ? 5 : 0;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: _minStarsFilter != 0 ? _dlInk : _dlPill,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                size: 16,
                                color: _minStarsFilter != 0
                                    ? Colors.white
                                    : _dlInk,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _minStarsFilter == 5
                                    ? s.tr(
                                        '5 نجوم فقط',
                                        '5 étoiles',
                                        '5 stars',
                                      )
                                    : s.tr('تصفية', 'Filtres', 'Filters'),
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: _minStarsFilter != 0
                                      ? Colors.white
                                      : _dlInk,
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
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: _highestFirst ? _dlInk : _dlPill,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.swap_vert_rounded,
                                size: 16,
                                color: _highestFirst ? Colors.white : _dlInk,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _highestFirst
                                    ? s.tr(
                                        'الأعلى تقييماً',
                                        'Meilleurs',
                                        'Highest',
                                      )
                                    : s.tr('ترتيب', 'Trier', 'Sort'),
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: _highestFirst ? Colors.white : _dlInk,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  if (items.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _dlSurface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            CupertinoIcons.star_circle,
                            size: 36,
                            color: _dlMuted,
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
                              color: _dlMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    for (int idx = 0; idx < items.length; idx++)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: _dlSurface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    color: _dlPill,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    CupertinoIcons.person_fill,
                                    color: _dlInk,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (items[idx]['author'] ??
                                                items[idx]['name'] ??
                                                '')
                                            .toString(),
                                        style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: _dlInk,
                                        ),
                                      ),
                                      if ((items[idx]['date'] ?? '')
                                          .toString()
                                          .isNotEmpty)
                                        Text(
                                          items[idx]['date'].toString(),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: _dlMuted,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _dlBg,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 13.5,
                                        color: _dlStarAmber,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${int.tryParse((items[idx]['rating'] ?? 5).toString()) ?? 5}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: _dlInk,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: List.generate(5, (i) {
                                final st = int.tryParse(
                                      (items[idx]['rating'] ?? 5).toString(),
                                    ) ??
                                    5;
                                return Icon(
                                  i < st
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  size: 15,
                                  color: _dlStarAmber,
                                );
                              }),
                            ),
                            if ((items[idx]['comment'] ?? '')
                                .toString()
                                .isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                items[idx]['comment'].toString(),
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  color: _dlInk,
                                  height: 1.45,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  if (_helpfulIndices.contains(idx)) {
                                    _helpfulIndices.remove(idx);
                                  } else {
                                    _helpfulIndices.add(idx);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: _helpfulIndices.contains(idx)
                                      ? _dlInk
                                      : _dlBg,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _helpfulIndices.contains(idx)
                                          ? CupertinoIcons.hand_thumbsup_fill
                                          : CupertinoIcons.hand_thumbsup,
                                      size: 13,
                                      color: _helpfulIndices.contains(idx)
                                          ? Colors.white
                                          : _dlMuted,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      s.tr('مفيد', 'Utile', 'Helpful'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _helpfulIndices.contains(idx)
                                            ? Colors.white
                                            : _dlMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
