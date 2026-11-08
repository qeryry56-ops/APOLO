import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/state/app_state.dart';
import 'auth_screen.dart';
import 'chat_room_screen.dart';
import 'widgets/kinetic_widgets.dart';

/// 2026 Production Apple Whitespace Messages Screen:
/// - 100% Real API integration with `GET /chat/conversations`
/// - Zero fake/dummy bots; real seller/buyer conversations only
/// - Pure Apple Whitespace (#FFFFFF canvas, #F5F6F8 pills & search)
/// - Filter tabs: الكل (All), غير مقروءة (Unread), عروض الأسعار 💰 (Price Offers)
/// - Clean 3D Empty & Logged-Out states
class ChatListScreen extends StatefulWidget {
  final VoidCallback? onExploreAds;

  const ChatListScreen({
    super.key,
    this.onExploreAds,
  });

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final AppState _state = AppState();

  static const Color _bgWhite = Color(0xFFFFFFFF);
  static const Color _surfaceSoft = Color(0xFFF5F6F8);
  static const Color _textInk = Color(0xFF0F172A);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _apoloRed = Color(0xFFE31B23);

  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _searchQuery = '';
  int _selectedFilterIndex = 0; // 0: All, 1: Unread, 2: Offers
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChanged);
    _loadConversations();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    if (!_state.isLoggedIn) {
      if (!mounted) return;
      setState(() {
        _conversations = [];
        _isLoading = false;
        _hasError = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final res = await _state.api.dio.get('/chat/conversations');
      if (!mounted) return;
      if (res.data is Map && res.data['status'] == 'success') {
        final rawList = (res.data['conversations'] ?? res.data['data'] ?? [])
            as List<dynamic>;
        setState(() {
          _conversations = rawList
              .whereType<Map>()
              .map((e) => _normalizeBackendConversation(Map<String, dynamic>.from(e)))
              .toList();
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _conversations = [];
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _normalizeBackendConversation(Map<String, dynamic> raw) {
    final peer = raw['peer'] is Map
        ? raw['peer'] as Map
        : (raw['other_user'] is Map ? raw['other_user'] as Map : const {});
    final ad = raw['ad'] is Map ? raw['ad'] as Map : const {};
    final lastMsgObj =
        raw['last_message'] is Map ? raw['last_message'] as Map : null;

    final String lastBody = lastMsgObj != null
        ? (lastMsgObj['body'] ?? '').toString()
        : (raw['last_message'] ?? '').toString();

    final rawId = raw['id'] ?? raw['conversation_id'];
    final int convId = int.tryParse('$rawId') ?? 0;

    return {
      'id': convId,
      'ad_id': raw['ad_id'] ?? ad['id'] ?? 0,
      'ad_title': (raw['ad_title'] ?? ad['title'] ?? '').toString(),
      'ad_price': (raw['ad_price'] ?? ad['price_formatted'] ?? ad['price'] ?? '')
          .toString(),
      'ad_image':
          (raw['ad_image'] ?? ad['primary_image'] ?? ad['image'] ?? '').toString(),
      'peer_id': raw['peer_id'] ?? peer['id'] ?? 0,
      'peer_name':
          (raw['peer_name'] ?? peer['name'] ?? 'مستخدم Apolo').toString(),
      'peer_avatar': (raw['peer_avatar'] ?? peer['avatar_url'] ?? peer['avatar'] ?? '').toString(),
      'peer_verified': raw['peer_verified'] == true || peer['is_verified'] == true,
      'peer_online': raw['peer_online'] ?? true,
      'last_message': lastBody,
      'last_message_time':
          (raw['last_message_time'] ?? raw['updated_at_human'] ?? 'الآن')
              .toString(),
      'unread_count': int.tryParse('${raw['unread_count'] ?? 0}') ?? 0,
      'is_offer': raw['is_offer'] == true ||
          lastBody.contains('عرض') ||
          lastBody.contains('Offre') ||
          lastBody.contains('💰'),
    };
  }

  List<Map<String, dynamic>> get _filteredConversations {
    return _conversations.where((conv) {
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final peer = (conv['peer_name'] ?? '').toString().toLowerCase();
        final title = (conv['ad_title'] ?? '').toString().toLowerCase();
        final msg = (conv['last_message'] ?? '').toString().toLowerCase();
        if (!peer.contains(q) && !title.contains(q) && !msg.contains(q)) {
          return false;
        }
      }
      if (_selectedFilterIndex == 1) {
        final unread = int.tryParse('${conv['unread_count'] ?? 0}') ?? 0;
        return unread > 0;
      }
      if (_selectedFilterIndex == 2) {
        return conv['is_offer'] == true;
      }
      return true;
    }).toList();
  }

  int get _totalUnreadCount {
    int total = 0;
    for (final c in _conversations) {
      total += int.tryParse('${c['unread_count'] ?? 0}') ?? 0;
    }
    return total;
  }

  Future<void> _markAllRead() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _conversations = _conversations.map((c) {
        final copy = Map<String, dynamic>.from(c);
        copy['unread_count'] = 0;
        return copy;
      }).toList();
    });
    try {
      await _state.api.dio.post('/chat/conversations/read-all');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final isAr = s.isAr;
    final filtered = _filteredConversations;

    return Scaffold(
      backgroundColor: _bgWhite,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Apple Whitespace Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              s.tr('الرسائل والمحادثات', 'Messages'),
                              style: const TextStyle(
                                color: _textInk,
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                                height: 1.15,
                                letterSpacing: -0.4,
                              ),
                            ),
                            if (_totalUnreadCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _apoloRed,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '$_totalUnreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isAr
                              ? 'تواصل مباشر وآمن بين المشترين والبائعين فالمغرب'
                              : 'Messagerie directe et sécurisée sur Apolo',
                          style: const TextStyle(
                            color: _textMuted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_state.isLoggedIn && _totalUnreadCount > 0)
                    PressableScale(
                      onTap: _markAllRead,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _surfaceSoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.checkmark_seal_fill,
                              size: 15,
                              color: _apoloRed,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isAr ? 'قراءة الكل' : 'Tout lire',
                              style: const TextStyle(
                                color: _textInk,
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

            // 2. Search & Filter Bar (Shown only if logged in)
            if (_state.isLoggedIn) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: _surfaceSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(
                      color: _textInk,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: isAr
                          ? 'البحث في المحادثات أو أسماء البائعين...'
                          : 'Rechercher une conversation ou un vendeur...',
                      hintStyle: const TextStyle(
                        color: _textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      prefixIcon: const Icon(
                        CupertinoIcons.search,
                        color: _textMuted,
                        size: 19,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                CupertinoIcons.xmark_circle_fill,
                                color: _textMuted,
                                size: 18,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
              ),

              // Filter Pills
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterPill(
                        index: 0,
                        label: isAr
                            ? 'الكل (${_conversations.length})'
                            : 'Tous (${_conversations.length})',
                        icon: CupertinoIcons.chat_bubble_2_fill,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterPill(
                        index: 1,
                        label: isAr
                            ? 'غير مقروءة ($_totalUnreadCount)'
                            : 'Non lus ($_totalUnreadCount)',
                        icon: CupertinoIcons.app_badge_fill,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterPill(
                        index: 2,
                        label: isAr ? 'عروض الأسعار 💰' : 'Offres de prix 💰',
                        icon: CupertinoIcons.tag_fill,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // 3. Body: Logged Out State OR Real Conversations List
            Expanded(
              child: !_state.isLoggedIn
                  ? IllustratedStateView(
                      assetPath: 'assets/images/auth_hero_3d.png',
                      title: isAr
                          ? 'سجل الدخول للدردشة مع البائعين'
                          : 'Connectez-vous pour voir vos messages',
                      subtitle: isAr
                          ? 'تواصل بأمان داخل Apolo، قدم عروض أسعار مباشرة، وتابع مفاوضاتك في مكان واحد.'
                          : 'Discutez en direct avec les vendeurs, faites des offres et suivez vos échanges.',
                      actionLabel: isAr
                          ? 'تسجيل الدخول / إنشاء حساب'
                          : 'Connexion / Inscription',
                      onAction: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AuthScreen(
                              initialIsLogin: true,
                            ),
                          ),
                        ).then((_) => _loadConversations());
                      },
                    )
                  : _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: _apoloRed,
                            strokeWidth: 2.5,
                          ),
                        )
                      : _hasError
                          ? IllustratedStateView(
                              assetPath: 'assets/images/state_no_internet.png',
                              title: isAr
                                  ? 'تعذر تحميل المحادثات'
                                  : 'Impossible de charger vos messages',
                              subtitle: isAr
                                  ? 'تأكد من اتصالك بالإنترنت وحاول مرة أخرى.'
                                  : 'Vérifiez votre connexion internet et réessayez.',
                              actionLabel:
                                  isAr ? 'إعادة المحاولة' : 'Réessayer',
                              onAction: _loadConversations,
                            )
                          : filtered.isEmpty
                              ? IllustratedStateView(
                                  assetPath: 'assets/images/state_empty_ads.png',
                                  title: isAr
                                      ? 'صندوق الرسائل فارغ'
                                      : 'Aucune conversation pour le moment',
                                  subtitle: isAr
                                      ? 'تواصل مع أي بائع من صفحة الإعلان بالضغط على "دردشة داخل التطبيق" وستظهر محادثاتك هنا.'
                                      : 'Contactez un vendeur depuis une annonce pour démarrer une discussion.',
                                  actionLabel: isAr
                                      ? 'تصفح الإعلانات الآن'
                                      : 'Explorer les annonces',
                                  onAction: () {
                                    widget.onExploreAds?.call();
                                  },
                                )
                              : RefreshIndicator(
                                  color: _apoloRed,
                                  backgroundColor: _bgWhite,
                                  onRefresh: _loadConversations,
                                  child: ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(
                                        20, 4, 20, 110),
                                    physics: const AlwaysScrollableScrollPhysics(
                                      parent: BouncingScrollPhysics(),
                                    ),
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final conv = filtered[index];
                                      return ScrollReveal(
                                        delay: Duration(
                                            milliseconds: 35 * index),
                                        child: _buildConversationTile(
                                            conv, isAr),
                                      );
                                    },
                                  ),
                                ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedFilterIndex == index;
    return PressableScale(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilterIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _textInk : _surfaceSoft,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : _textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : _textInk,
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationTile(Map<String, dynamic> conv, bool isAr) {
    final int convId = int.tryParse('${conv['id'] ?? 0}') ?? 0;
    final peerName = conv['peer_name']?.toString() ?? 'مستخدم Apolo';
    final peerAvatar = conv['peer_avatar']?.toString();
    final adTitle = conv['ad_title']?.toString() ?? '';
    final adPrice = conv['ad_price']?.toString() ?? '';
    final adImage = conv['ad_image']?.toString() ?? '';
    final lastMsg = conv['last_message']?.toString() ?? '';
    final lastTime = conv['last_message_time']?.toString() ?? '';
    final unread = int.tryParse('${conv['unread_count'] ?? 0}') ?? 0;
    final isOnline = conv['peer_online'] == true;
    final isVerified = conv['peer_verified'] == true;
    final isOffer = conv['is_offer'] == true;

    return PressableScale(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          conv['unread_count'] = 0;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(
              conversationId: convId,
              peerName: peerName,
              adTitle: adTitle,
              peerAvatar: peerAvatar,
              adImage: adImage,
              adPrice: adPrice,
            ),
          ),
        ).then((_) => _loadConversations());
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: unread > 0 ? const Color(0xFFFFFAFA) : _bgWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: unread > 0
                ? _apoloRed.withValues(alpha: 0.25)
                : const Color(0xFFE2E8F0).withValues(alpha: 0.8),
            width: unread > 0 ? 1.3 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Peer Avatar + Online Status Dot
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _surfaceSoft,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: unread > 0
                          ? _apoloRed.withValues(alpha: 0.35)
                          : const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: peerAvatar != null && peerAvatar.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: Image.network(
                            peerAvatar,
                            fit: BoxFit.cover,
                            width: 52,
                            height: 52,
                            errorBuilder: (_, __, ___) => Text(
                              peerName.isNotEmpty
                                  ? peerName[0].toUpperCase()
                                  : 'A',
                              style: const TextStyle(
                                color: _textInk,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        )
                      : Text(
                          peerName.isNotEmpty ? peerName[0].toUpperCase() : 'A',
                          style: const TextStyle(
                            color: _textInk,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
                if (isOnline)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Message Content + Ad Pill
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: Name + Verified + Time
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          peerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _textInk,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          CupertinoIcons.checkmark_seal_fill,
                          color: Color(0xFF2563EB),
                          size: 14,
                        ),
                      ],
                      const Spacer(),
                      Text(
                        lastTime,
                        style: TextStyle(
                          color: unread > 0 ? _apoloRed : _textMuted,
                          fontSize: 11,
                          fontWeight:
                              unread > 0 ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Ad Context Mini Pill
                  if (adTitle.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: _surfaceSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.tag_fill,
                            size: 10,
                            color: _apoloRed,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              adTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _textInk,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (adPrice.isNotEmpty) ...[
                            const SizedBox(width: 5),
                            Text(
                              '• $adPrice',
                              style: const TextStyle(
                                color: _apoloRed,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 5),

                  // Last Message + Unread Badge
                  Row(
                    children: [
                      if (isOffer) ...[
                        Container(
                          margin: const EdgeInsets.only(left: 5, right: 2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isAr ? 'عرض سعر' : 'Offre',
                            style: const TextStyle(
                              color: Color(0xFFB45309),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                      Expanded(
                        child: Text(
                          lastMsg.isNotEmpty
                              ? lastMsg
                              : (isAr ? 'انقر لفتح المحادثة' : 'Appuyez pour discuter'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: unread > 0 ? _textInk : _textMuted,
                            fontSize: 12.5,
                            fontWeight:
                                unread > 0 ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (unread > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _apoloRed,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Ad Image Thumbnail
            if (adImage.isNotEmpty) ...[
              const SizedBox(width: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 46,
                  height: 46,
                  color: _surfaceSoft,
                  child: adImage.startsWith('assets/')
                      ? Image.asset(
                          adImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            CupertinoIcons.photo,
                            size: 18,
                            color: _textMuted,
                          ),
                        )
                      : Image.network(
                          adImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            CupertinoIcons.photo,
                            size: 18,
                            color: _textMuted,
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
}
