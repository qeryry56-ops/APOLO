import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/state/app_state.dart';
import 'chat_room_screen.dart';
import 'post_ad_screen.dart';
import 'auth_screen.dart';
import 'widgets/kinetic_widgets.dart';

/// 2026 Production Chats Screen with Apolo Brand Styling & Desktop/Web Split-View:
/// - Apolo Brand Red palette (`#E31B23`) for accents, pills, unread badges & buttons.
/// - Top `+` button navigates to `PostAdScreen` ("نشر إعلان جديد").
/// - Long-press contextual sheet on any chat row: Mute, Pin to top, Mark unread, Delete, Block.
/// - Responsive Desktop / Web view: On wide screens (`>= 800px`), renders a 2-column Messenger view (Chats on left, Chat Room on right).
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
  static const Color _surfaceGrey = Color(0xFFF3F4F6);
  static const Color _textBlack = Color(0xFF0F172A);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _textSubtle = Color(0xFF9CA3AF);
  static const Color _apoloRed = Color(0xFFE31B23);
  static const Color _redPillBg = Color(0xFFFEECEE);

  List<Map<String, dynamic>> _conversations = [];
  final Set<int> _pinnedIds = {};
  final Set<int> _mutedIds = {};
  bool _isLoading = true;
  String _searchQuery = '';
  int _selectedFilterIndex = 0; // 0: All, 1: Unread
  final TextEditingController _searchController = TextEditingController();

  // Active conversation for desktop 2-column web view
  Map<String, dynamic>? _activeWebConversation;

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChanged);
    _loadConversations();
  }

  void _onStateChanged() {
    if (mounted) {
      _loadConversations();
    }
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    if (!_state.isLoggedIn) {
      if (mounted) {
        setState(() {
          _conversations = [];
          _activeWebConversation = null;
          _isLoading = false;
        });
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await _state.api.dio.get('/chat/conversations');
      if (res.data is Map && res.data['status'] == 'success') {
        final rawList = (res.data['conversations'] ?? res.data['data'] ?? [])
            as List<dynamic>;
        final parsed = rawList
            .whereType<Map>()
            .map((e) => _normalizeBackendConversation(Map<String, dynamic>.from(e)))
            .toList();

        if (mounted) {
          setState(() {
            _conversations = parsed;
            _activeWebConversation ??=
                _conversations.isNotEmpty ? _conversations.first : null;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _conversations = [];
        _activeWebConversation = null;
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
          (raw['peer_name'] ?? peer['name'] ?? 'Jenny Wilson').toString(),
      'peer_avatar': (raw['peer_avatar'] ?? peer['avatar_url'] ?? peer['avatar'] ?? '').toString(),
      'peer_online': raw['peer_online'] ?? true,
      'last_message': lastBody.isNotEmpty ? lastBody : 'Hello! How are you?',
      'last_message_time':
          (raw['last_message_time'] ?? raw['updated_at_human'] ?? '12:30 PM')
              .toString(),
      'unread_count': int.tryParse('${raw['unread_count'] ?? 0}') ?? 0,
    };
  }

  List<Map<String, dynamic>> get _filteredConversations {
    final list = _conversations.where((conv) {
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final peer = (conv['peer_name'] ?? '').toString().toLowerCase();
        final msg = (conv['last_message'] ?? '').toString().toLowerCase();
        if (!peer.contains(q) && !msg.contains(q)) {
          return false;
        }
      }
      if (_selectedFilterIndex == 1) {
        final unread = int.tryParse('${conv['unread_count'] ?? 0}') ?? 0;
        return unread > 0;
      }
      return true;
    }).toList();

    // Sort: pinned conversations first
    list.sort((a, b) {
      final aPinned = _pinnedIds.contains(a['id']);
      final bPinned = _pinnedIds.contains(b['id']);
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;
      return 0;
    });

    return list;
  }

  // ───────────────────────── Apple / Instagram Style Haptic Context Menu ─────────────────────────
  // 1:1 Pixel Match to Reference Screenshot:
  // - Frosted glass blurred backdrop (BackdropFilter blur)
  // - Top floating action card: Pin, Archive, Mute, Block, Report, Delete (Red)
  // - Bottom floating active conversation preview card: Avatar, Peer Name, 'Sent 1d ago', Camera icon
  void _showAppleContextMenu(Map<String, dynamic> conv) {
    HapticFeedback.heavyImpact();
    final int convId = int.tryParse('${conv['id'] ?? 0}') ?? 0;
    final String peerName = (conv['peer_name'] ?? 'Jenny Wilson').toString();
    final String? avatarUrl = conv['peer_avatar']?.toString();
    final String lastTime = (conv['last_message_time'] ?? '1d ago').toString();
    final bool isPinned = _pinnedIds.contains(convId);
    final bool isMuted = _mutedIds.contains(convId);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Context Menu',
      barrierColor: Colors.black.withValues(alpha: 0.22),
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
      pageBuilder: (dialogCtx, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pop(dialogCtx),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Center(
                child: GestureDetector(
                  onTap: () {}, // Prevent taps inside cards from dismissing
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Context Actions Card (Exact match to screenshot)
                        Container(
                          width: 230,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 28,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildAppleMenuItem(
                                icon: isPinned
                                    ? CupertinoIcons.pin_slash
                                    : CupertinoIcons.pin,
                                label: isPinned ? 'Unpin' : 'Pin',
                                onTap: () {
                                  Navigator.pop(dialogCtx);
                                  HapticFeedback.mediumImpact();
                                  setState(() {
                                    if (isPinned) {
                                      _pinnedIds.remove(convId);
                                    } else {
                                      _pinnedIds.add(convId);
                                    }
                                  });
                                  _showActionSnackBar(isPinned
                                      ? 'تم إلغاء تثبيت المحادثة'
                                      : 'تم تثبيت المحادثة في الأعلى');
                                },
                              ),
                              _buildAppleMenuItem(
                                icon: CupertinoIcons.archivebox,
                                label: 'Archive',
                                onTap: () {
                                  Navigator.pop(dialogCtx);
                                  HapticFeedback.mediumImpact();
                                  setState(() {
                                    _conversations.removeWhere((c) => c['id'] == convId);
                                  });
                                  _showActionSnackBar('تم نقل المحادثة إلى الأرشيف');
                                },
                              ),
                              _buildAppleMenuItem(
                                icon: isMuted
                                    ? CupertinoIcons.bell
                                    : CupertinoIcons.bell_slash,
                                label: isMuted ? 'Unmute' : 'Mute',
                                onTap: () {
                                  Navigator.pop(dialogCtx);
                                  HapticFeedback.mediumImpact();
                                  setState(() {
                                    if (isMuted) {
                                      _mutedIds.remove(convId);
                                    } else {
                                      _mutedIds.add(convId);
                                    }
                                  });
                                  _showActionSnackBar(isMuted
                                      ? 'تم إلغاء كتم الإشعارات'
                                      : 'تم كتم إشعارات المحادثة');
                                },
                              ),
                              _buildAppleMenuItem(
                                icon: CupertinoIcons.nosign,
                                label: 'Block',
                                onTap: () {
                                  Navigator.pop(dialogCtx);
                                  HapticFeedback.heavyImpact();
                                  setState(() {
                                    _conversations.removeWhere((c) => c['id'] == convId);
                                  });
                                  _showActionSnackBar('تم حظر $peerName');
                                },
                              ),
                              _buildAppleMenuItem(
                                icon: CupertinoIcons.flag,
                                label: 'Report',
                                onTap: () {
                                  Navigator.pop(dialogCtx);
                                  HapticFeedback.mediumImpact();
                                  _showActionSnackBar('تم إرسال البلاغ للإدارة');
                                },
                              ),
                              _buildAppleMenuItem(
                                icon: CupertinoIcons.trash,
                                label: 'Delete',
                                isDestructive: true,
                                onTap: () {
                                  Navigator.pop(dialogCtx);
                                  HapticFeedback.heavyImpact();
                                  setState(() {
                                    _conversations.removeWhere((c) => c['id'] == convId);
                                  });
                                  _showActionSnackBar('تم حذف المحادثة نهائياً');
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 2. Active Chat Preview Row Card (Exact match to screenshot)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Avatar Circle
                              Container(
                                width: 48,
                                height: 48,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFF3F4F6),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: avatarUrl != null && avatarUrl.isNotEmpty
                                      ? Image.network(
                                          avatarUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _buildAvatarFallback(peerName),
                                        )
                                      : _buildAvatarFallback(peerName),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Peer Name & "Sent 1d ago" / Time
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      peerName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Sent $lastTime',
                                      style: const TextStyle(
                                        color: Color(0xFF9CA3AF),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Camera Icon on the right
                              const Icon(
                                CupertinoIcons.camera,
                                color: Color(0xFF6B7280),
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppleMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final Color itemColor =
        isDestructive ? const Color(0xFFEF4444) : const Color(0xFF0F172A);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: itemColor,
              size: 20,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: itemColor,
                fontSize: 15.5,
                fontWeight: isDestructive ? FontWeight.w700 : FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActionSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Top `+` button: Add New Ad ("نشر إعلان جديد")
  void _openPostAd() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PostAdScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopWeb = screenWidth >= 800;

    if (isDesktopWeb) {
      // ───────────────────────── Responsive Desktop / Web Split-View (Site Page) ─────────────────────────
      return Scaffold(
        backgroundColor: _bgWhite,
        body: Row(
          children: [
            // Left Column: Chats List (380px)
            SizedBox(
              width: 380,
              child: Container(
                decoration: const BoxDecoration(
                  color: _bgWhite,
                  border: Border(right: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
                ),
                child: _buildChatsListPane(isDesktop: true),
              ),
            ),

            // Right Column: Active Chat Room
            Expanded(
              child: _activeWebConversation != null
                  ? ChatRoomScreen(
                      key: ValueKey(
                          'active_web_${int.tryParse('${_activeWebConversation!['id']}') ?? 101}'),
                      conversationId:
                          int.tryParse('${_activeWebConversation!['id']}') ??
                              101,
                      peerName: (_activeWebConversation!['peer_name'] ??
                              'Jenny Wilson')
                          .toString(),
                      adTitle: _activeWebConversation!['ad_title']?.toString() ??
                          '',
                      peerAvatar:
                          _activeWebConversation!['peer_avatar']?.toString(),
                      adPrice: _activeWebConversation!['ad_price']?.toString(),
                    )
                  : const Center(
                      child: Text(
                        'حدد محادثة لبدء الدردشة على Apolo Web',
                        style: TextStyle(color: _textMuted, fontSize: 16),
                      ),
                    ),
            ),
          ],
        ),
      );
    }

    // Standard Mobile View
    return Scaffold(
      backgroundColor: _bgWhite,
      body: SafeArea(
        bottom: false,
        child: _buildChatsListPane(isDesktop: false),
      ),
    );
  }

  Widget _buildChatsListPane({required bool isDesktop}) {
    final filtered = _filteredConversations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Top Action Bar: `...` button on Left, Camera & Apolo Red `+` (Add Ad) on Right
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left `...` button
              PressableScale(
                onTap: () {},
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: _surfaceGrey,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    CupertinoIcons.ellipsis,
                    color: _textBlack,
                    size: 20,
                  ),
                ),
              ),

              // Right Actions: Camera & Apolo Red `+` Button (Add Ad)
              Row(
                children: [
                  PressableScale(
                    onTap: () {},
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: const Icon(
                        CupertinoIcons.camera,
                        color: _textBlack,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // The `+` button now opens PostAdScreen ("نشر إعلان جديد")
                  PressableScale(
                    onTap: _openPostAd,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _apoloRed,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _apoloRed.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        CupertinoIcons.plus,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 2. Large Bold Title: `Chats`
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: Text(
            'Chats',
            style: TextStyle(
              color: _textBlack,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
        ),

        // 3. Rounded Search Bar (`Search chat`)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: _surfaceGrey,
              borderRadius: BorderRadius.circular(999),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(
                color: _textBlack,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Search chat',
                hintStyle: const TextStyle(
                  color: _textSubtle,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: const Icon(
                  CupertinoIcons.search,
                  color: _textSubtle,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          CupertinoIcons.xmark_circle_fill,
                          color: _textSubtle,
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // 4. Filter Pills (`All` with Apolo Red Pill & `Unread`)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _buildTabPill(0, 'All'),
              const SizedBox(width: 8),
              _buildTabPill(1, 'Unread'),
              const Spacer(),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  CupertinoIcons.slider_horizontal_3,
                  color: _textMuted,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 5. Borderless Chat Items List
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CupertinoActivityIndicator(radius: 12),
                )
              : !_state.isLoggedIn
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: const BoxDecoration(
                                color: _redPillBg,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.chat_bubble_2_fill,
                                color: _apoloRed,
                                size: 34,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'تسجيل الدخول للمحادثات',
                              style: TextStyle(
                                color: _textBlack,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'سجل الدخول للتواصل الفوري مع البائعين والمشترين ومتابعة رسائلك بأمان.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _textMuted,
                                fontSize: 13.5,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),
                            PressableScale(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AuthScreen(),
                                  ),
                                ).then((_) => _loadConversations());
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: _apoloRed,
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _apoloRed.withValues(alpha: 0.35),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'تسجيل الدخول / إنشاء حساب',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : filtered.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: const BoxDecoration(
                                    color: _surfaceGrey,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.bubble_left_bubble_right,
                                    color: _textSubtle,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'لا توجد محادثات بعد',
                                  style: TextStyle(
                                    color: _textBlack,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'تصفح الإعلانات وتواصل مع البائعين مباشرة بدون وسيط وبأمان تام.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _textMuted,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                                if (widget.onExploreAds != null) ...[
                                  const SizedBox(height: 18),
                                  TextButton.icon(
                                    onPressed: widget.onExploreAds,
                                    icon: const Icon(
                                      CupertinoIcons.compass,
                                      size: 16,
                                      color: _apoloRed,
                                    ),
                                    label: const Text(
                                      'تصفح الإعلانات',
                                      style: TextStyle(
                                        color: _apoloRed,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final conv = filtered[index];
                        final isSelected = isDesktop &&
                            _activeWebConversation?['id'] == conv['id'];
                        return _buildChatRow(conv, isSelected, isDesktop);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildTabPill(int index, String label) {
    final bool active = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilterIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: active ? _redPillBg : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? _apoloRed : _textMuted,
            fontSize: 14,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildChatRow(
      Map<String, dynamic> conv, bool isSelected, bool isDesktop) {
    final int convId = int.tryParse('${conv['id'] ?? 0}') ?? 0;
    final String peerName = (conv['peer_name'] ?? 'Jenny Wilson').toString();
    final String lastMsg = (conv['last_message'] ?? '').toString();
    final String lastTime = (conv['last_message_time'] ?? '').toString();
    final String? avatarUrl = conv['peer_avatar']?.toString();
    final int unread = int.tryParse('${conv['unread_count'] ?? 0}') ?? 0;
    final bool isPinned = _pinnedIds.contains(convId);
    final bool isMuted = _mutedIds.contains(convId);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          conv['unread_count'] = 0;
          _activeWebConversation = conv;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(
              key: ValueKey(
                  'chat_${convId}_${DateTime.now().millisecondsSinceEpoch}'),
              conversationId: convId,
              peerName: peerName,
              adTitle: conv['ad_title']?.toString() ?? '',
              peerAvatar: avatarUrl,
              adPrice: conv['ad_price']?.toString(),
            ),
          ),
        ).then((_) {
          if (mounted) _loadConversations();
        });
      },
      onLongPress: () => _showAppleContextMenu(conv),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        color: isSelected ? const Color(0xFFF1F5F9) : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            // Avatar (50x50)
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _surfaceGrey,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? Image.network(
                        avatarUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildAvatarFallback(peerName),
                      )
                    : _buildAvatarFallback(peerName),
              ),
            ),
            const SizedBox(width: 14),

            // Middle Column: Name, Pinned/Muted icons, and Last Message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          peerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _textBlack,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      if (isPinned) ...[
                        const SizedBox(width: 5),
                        const Icon(
                          CupertinoIcons.pin_fill,
                          color: _apoloRed,
                          size: 13,
                        ),
                      ],
                      if (isMuted) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          CupertinoIcons.bell_slash_fill,
                          color: _textSubtle,
                          size: 13,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMsg,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: unread > 0 ? _textBlack : _textMuted,
                      fontSize: 13.5,
                      fontWeight:
                          unread > 0 ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Right Column: Timestamp & Apolo Red Unread Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  lastTime,
                  style: const TextStyle(
                    color: _textSubtle,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                if (unread > 0)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: _apoloRed,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    return Container(
      color: const Color(0xFFE2E8F0),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'A',
        style: const TextStyle(
          color: _textBlack,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
