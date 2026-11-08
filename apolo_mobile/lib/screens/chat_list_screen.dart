import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/state/app_state.dart';
import 'auth_screen.dart';
import 'chat_room_screen.dart';
import 'widgets/kinetic_widgets.dart';

/// 2026 Apple Whitespace Messages / Conversations Screen:
/// - Pure #FFFFFF canvas + #F5F6F8 search & filter pills
/// - Real-time backend conversations + interactive 2026 demo conversations fallback
///   so the user can test and experience full buyer/seller messaging anytime
/// - Filter tabs: الكل (All), غير مقروءة (Unread), عروض الأسعار 💰 (Price Offers)
/// - 1-tap open into ChatRoomScreen with instant offer & reply support
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

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
  bool _usingDemoFallback = false;
  String _searchQuery = '';
  int _selectedFilterIndex = 0; // 0: All, 1: Unread, 2: Offers
  final TextEditingController _searchController = TextEditingController();

  static final List<Map<String, dynamic>> _demoConversations = [
    {
      'id': 9001,
      'ad_id': 101,
      'ad_title': 'Range Rover Sport SVR 2024 - حالة الوكالة',
      'ad_price': '890,000 DH',
      'ad_image': 'assets/images/hero_car.png',
      'peer_id': 501,
      'peer_name': 'ياسين العلمي',
      'peer_verified': true,
      'peer_online': true,
      'last_message': '💰 عرض سعر جديد: واش تقدر تخليها ليا بـ 865,000 درهم؟',
      'last_message_time': 'منذ دقيقتين',
      'unread_count': 2,
      'is_offer': true,
      'is_demo': true,
    },
    {
      'id': 9002,
      'ad_id': 102,
      'ad_title': 'iPhone 16 Pro Max 256GB Desert Titanium',
      'ad_price': '13,200 DH',
      'ad_image': 'assets/images/cat_phones.png',
      'peer_id': 502,
      'peer_name': 'سلمى بنجلون',
      'peer_verified': true,
      'peer_online': true,
      'last_message':
          'سلام خويا أمين، التليفون باقي متوفر؟ أنا فكازا نقدر نجي نشوفو اليوم',
      'last_message_time': 'منذ 15 دقيقة',
      'unread_count': 1,
      'is_offer': false,
      'is_demo': true,
    },
    {
      'id': 9003,
      'ad_id': 103,
      'ad_title': 'MacBook Pro M3 Max 16" - 36GB RAM / 1TB SSD',
      'ad_price': '27,500 DH',
      'ad_image': 'assets/images/cat_computers.png',
      'peer_id': 503,
      'peer_name': 'كريم التازي',
      'peer_verified': false,
      'peer_online': false,
      'last_message':
          'شكراً بزاف! نتلاقاو غدا فالمعاريف حدا توين سنتر مع 5 العشية.',
      'last_message_time': 'أمس',
      'unread_count': 0,
      'is_offer': false,
      'is_demo': true,
    },
    {
      'id': 9004,
      'ad_id': 104,
      'ad_title': 'شقة فاخرة بإقامة محروسة - تامسنا / الرباط',
      'ad_price': '950,000 DH',
      'ad_image': 'assets/images/cat_realestate.png',
      'peer_id': 504,
      'peer_name': 'عمر المراكشي',
      'peer_verified': true,
      'peer_online': false,
      'last_message': '💰 عرض شراء: واش ك تقبل الدفع عن طريق البنك؟',
      'last_message_time': 'منذ يومين',
      'unread_count': 0,
      'is_offer': true,
      'is_demo': true,
    },
  ];

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
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    if (!_state.isLoggedIn) {
      if (!mounted) return;
      setState(() {
        _conversations =
            _demoConversations.map((e) => Map<String, dynamic>.from(e)).toList();
        _usingDemoFallback = true;
        _isLoading = false;
      });
      return;
    }

    try {
      final res = await _state.api.dio.get('/chat/conversations');
      if (!mounted) return;
      if (res.data is Map && res.data['status'] == 'success') {
        final rawList = (res.data['conversations'] ?? res.data['data'] ?? [])
            as List<dynamic>;
        if (rawList.isNotEmpty) {
          setState(() {
            _conversations = rawList
                .whereType<Map>()
                .map((e) => _normalizeBackendConversation(Map<String, dynamic>.from(e)))
                .toList();
            _usingDemoFallback = false;
            _isLoading = false;
          });
          return;
        }
      }
      // Fallback to interactive demo conversations when inbox has no backend messages yet
      setState(() {
        _conversations =
            _demoConversations.map((e) => Map<String, dynamic>.from(e)).toList();
        _usingDemoFallback = true;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _conversations =
            _demoConversations.map((e) => Map<String, dynamic>.from(e)).toList();
        _usingDemoFallback = true;
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _normalizeBackendConversation(Map<String, dynamic> raw) {
    final peer = raw['peer'] is Map ? raw['peer'] as Map : const {};
    final ad = raw['ad'] is Map ? raw['ad'] as Map : const {};
    final lastMsgObj =
        raw['last_message'] is Map ? raw['last_message'] as Map : null;

    final String lastBody = lastMsgObj != null
        ? (lastMsgObj['body'] ?? '').toString()
        : (raw['last_message'] ?? '').toString();

    return {
      'id': int.tryParse('${raw['id'] ?? 9001}') ?? 9001,
      'ad_id': raw['ad_id'] ?? ad['id'] ?? 0,
      'ad_title': (raw['ad_title'] ?? ad['title'] ?? '').toString(),
      'ad_price': (raw['ad_price'] ?? ad['price_formatted'] ?? ad['price'] ?? '')
          .toString(),
      'ad_image':
          (raw['ad_image'] ?? ad['primary_image'] ?? ad['image'] ?? '').toString(),
      'peer_id': raw['peer_id'] ?? peer['id'] ?? 0,
      'peer_name':
          (raw['peer_name'] ?? peer['name'] ?? 'مستخدم Apolo').toString(),
      'peer_avatar': (raw['peer_avatar'] ?? peer['avatar'] ?? '').toString(),
      'peer_verified': raw['peer_verified'] == true || peer['is_verified'] == true,
      'peer_online': raw['peer_online'] ?? true,
      'last_message': lastBody,
      'last_message_time':
          (raw['last_message_time'] ?? raw['updated_at_human'] ?? 'الآن')
              .toString(),
      'unread_count': int.tryParse('${raw['unread_count'] ?? 0}') ?? 0,
      'is_offer': raw['is_offer'] == true || lastBody.contains('عرض'),
      'is_demo': false,
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
        final isOffer = conv['is_offer'] == true ||
            (conv['last_message'] ?? '').toString().contains('عرض');
        return isOffer;
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

  void _markAllRead() {
    HapticFeedback.mediumImpact();
    setState(() {
      _conversations = _conversations.map((c) {
        final copy = Map<String, dynamic>.from(c);
        copy['unread_count'] = 0;
        return copy;
      }).toList();
    });
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
            // 1. Minimalist Apple Whitespace Header
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
                              ? 'تواصل مباشرة داخل Apolo بأمان وبلا وسطاء'
                              : 'Discutez directement dans Apolo en toute sécurité',
                          style: const TextStyle(
                            color: _textMuted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_totalUnreadCount > 0)
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

            // 2. Search Bar (#F5F6F8 Apple Whitespace pill)
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
                        ? 'قلب فالمحادثات، البائعين أو الإعلانات...'
                        : 'Rechercher une conversation ou annonce...',
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

            // 3. Filter Pills (الكل | غير مقروءة | عروض الأسعار 💰)
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

            // 4. Interactive Demo / Guest Banner
            if (!_state.isLoggedIn || _usingDemoFallback)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _apoloRed.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: _apoloRed.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.sparkles,
                          color: _apoloRed,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          !_state.isLoggedIn
                              ? (isAr
                                  ? 'جرب الشات التفاعلي وعروض الأسعار دابا، أو سجل الدخول لمزامنة رسائلك!'
                                  : 'Testez le chat interactif et les offres ou connectez-vous !')
                              : (isAr
                                  ? 'محادثات تفاعلية — كليكي على أي محادثة باش تجرب الشات وتقديم العروض!'
                                  : 'Conversations interactives — appuyez pour tester le chat et les offres !'),
                          style: const TextStyle(
                            color: _textInk,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),
                      ),
                      if (!_state.isLoggedIn) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AuthScreen(initialIsLogin: true),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _apoloRed,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              isAr ? 'دخول' : 'Connexion',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // 5. Conversations List
            Expanded(
              child: _isLoading
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
                              : 'Impossible de charger les messages',
                          subtitle: isAr
                              ? 'تأكد من اتصالك بالأنترنت وحاول مرة أخرى'
                              : 'Vérifiez votre connexion internet et réessayez',
                          actionLabel:
                              isAr ? 'إعادة المحاولة' : 'Réessayer',
                          onAction: _loadConversations,
                        )
                      : filtered.isEmpty
                          ? IllustratedStateView(
                              assetPath: 'assets/images/state_empty_ads.png',
                              title: isAr
                                  ? 'ما كايناش محادثات فهاد الفلتر'
                                  : 'Aucune conversation trouvée',
                              subtitle: isAr
                                  ? 'جرب تبدل الفلتر أو تواصل مع أي بائع من صفحة الإعلان'
                                  : 'Changez de filtre ou contactez un vendeur depuis une annonce',
                              actionLabel: isAr ? 'عرض الكل' : 'Afficher tout',
                              onAction: () {
                                setState(() {
                                  _selectedFilterIndex = 0;
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                              },
                            )
                          : RefreshIndicator(
                              color: _apoloRed,
                              backgroundColor: _bgWhite,
                              onRefresh: _loadConversations,
                              child: ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 4, 20, 110),
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final conv = filtered[index];
                                  return ScrollReveal(
                                    delay: Duration(milliseconds: 35 * index),
                                    child: _buildConversationTile(conv, isAr),
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
    final int convId = int.tryParse('${conv['id'] ?? 9001}') ?? 9001;
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
    final isOffer = conv['is_offer'] == true || lastMsg.contains('عرض');

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
        );
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
                  width: 54,
                  height: 54,
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
                  child: Text(
                    peerName.isNotEmpty ? peerName[0].toUpperCase() : 'A',
                    style: const TextStyle(
                      color: _textInk,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (isOnline)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.2),
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
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          CupertinoIcons.checkmark_seal_fill,
                          color: Color(0xFF2563EB),
                          size: 15,
                        ),
                      ],
                      const Spacer(),
                      Text(
                        lastTime,
                        style: TextStyle(
                          color: unread > 0 ? _apoloRed : _textMuted,
                          fontSize: 11.5,
                          fontWeight:
                              unread > 0 ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Ad Context Mini Pill
                  if (adTitle.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
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
                            size: 11,
                            color: _apoloRed,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              adTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _textInk,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (adPrice.isNotEmpty) ...[
                            const SizedBox(width: 6),
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
                  const SizedBox(height: 6),

                  // Last Message + Unread Badge
                  Row(
                    children: [
                      if (isOffer) ...[
                        Container(
                          margin: const EdgeInsets.only(left: 6, right: 2),
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
                          lastMsg,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: unread > 0 ? _textInk : _textMuted,
                            fontSize: 13,
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

            // Product Cutout Thumbnail on the far side
            if (adImage.isNotEmpty) ...[
              const SizedBox(width: 10),
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: _surfaceSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: adImage.startsWith('assets/')
                    ? Image.asset(
                        adImage,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          CupertinoIcons.photo,
                          size: 20,
                          color: _textMuted,
                        ),
                      )
                    : Image.network(
                        adImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          CupertinoIcons.photo,
                          size: 20,
                          color: _textMuted,
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
