import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/services/firebase_chat_service.dart';
import '../core/state/app_state.dart';
import '../theme/app_typography.dart';
import '../widgets/notification_badge.dart';
import '../widgets/pull_to_refresh.dart';
import 'call_screen.dart';
import 'chat_room_screen.dart';
import 'post_ad_screen.dart';
import 'auth_screen.dart';
import 'widgets/apolo_safety_sheet.dart';
import 'widgets/app_image.dart';
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
  static const Color _surfaceGrey = Color(0xFFF2F3F7);
  static const Color _textBlack = Color(0xFF0A0A0A);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _textSubtle = Color(0xFF9CA3AF);
  static const Color _chatBlue = Color(0xFF0A0A0A);
  static const Color _chatBlueSoft = Color(0xFFF2F3F7);

  List<Map<String, dynamic>> _conversations = [];
  final Map<String, int> _optimisticallyReadAtMs = {};
  final Set<int> _pinnedIds = {};
  final Set<int> _mutedIds = {};
  bool _isLoading = true;
  bool _unreadFirst = false;
  String _searchQuery = '';
  int _selectedFilterIndex = 0; // 0: All, 1: Unread
  final TextEditingController _searchController = TextEditingController();

  // Active conversation for desktop 2-column web view
  Map<String, dynamic>? _activeWebConversation;
  StreamSubscription<List<Map<String, dynamic>>>? _convSub;
  StreamSubscription<Map<String, dynamic>?>? _incomingCallSub;
  String? _lastHandledCallId;
  int? _subscribedUserId;
  String? _loadedAuthKey;

  String? get _currentAuthKey =>
      _state.isLoggedIn ? '${_state.currentUser?['id'] ?? ''}' : null;

  @override
  void initState() {
    super.initState();
    _loadedAuthKey = _currentAuthKey;
    _state.addListener(_onStateChanged);
    _loadConversations();
  }

  void _onStateChanged() {
    if (!mounted) return;
    final nextKey = _currentAuthKey;
    if (nextKey != _loadedAuthKey) {
      _loadedAuthKey = nextKey;
      _optimisticallyReadAtMs.clear();
      _loadConversations();
    }
  }

  String _convKey(Map<String, dynamic> conv) =>
      (conv['firestore_doc_id'] ?? conv['id'] ?? '').toString();

  int _effectiveUnread(Map<String, dynamic> conv) {
    final rawUnread = int.tryParse('${conv['unread_count'] ?? 0}') ?? 0;
    if (rawUnread <= 0) return 0;
    final readAtMs = _optimisticallyReadAtMs[_convKey(conv)];
    if (readAtMs != null) {
      final updatedMs = int.tryParse('${conv['updated_at_ms'] ?? 0}') ?? 0;
      if (updatedMs <= readAtMs) return 0;
    }
    return rawUnread;
  }

  @override
  void dispose() {
    _convSub?.cancel();
    _incomingCallSub?.cancel();
    _state.removeListener(_onStateChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    if (!_state.isLoggedIn) {
      _convSub?.cancel();
      _convSub = null;
      _incomingCallSub?.cancel();
      _incomingCallSub = null;
      _subscribedUserId = null;
      if (mounted) {
        setState(() {
          _conversations = [];
          _activeWebConversation = null;
          _isLoading = false;
        });
      }
      return;
    }

    final myUserId = int.tryParse('${_state.currentUser?['id'] ?? ''}') ?? 0;
    if (FirebaseChatService.instance.isReady && myUserId > 0) {
      if (_subscribedUserId == myUserId && _convSub != null) {
        return;
      }
      _convSub?.cancel();
      _subscribedUserId = myUserId;
      if (mounted && _conversations.isEmpty) {
        setState(() => _isLoading = true);
      }
      _convSub = FirebaseChatService.instance
          .watchConversations(myUserId)
          .listen((list) {
        if (!mounted) return;
        setState(() {
          _conversations = list;
          if (_activeWebConversation != null) {
            final activeDocId =
                _activeWebConversation!['firestore_doc_id']?.toString();
            final updated = list.where(
              (c) => c['firestore_doc_id']?.toString() == activeDocId,
            );
            _activeWebConversation =
                updated.isNotEmpty ? updated.first : (list.isNotEmpty ? list.first : null);
          } else {
            _activeWebConversation = list.isNotEmpty ? list.first : null;
          }
          _isLoading = false;
        });
      }, onError: (_) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      });
      _incomingCallSub?.cancel();
      _incomingCallSub = FirebaseChatService.instance
          .watchIncomingCalls(myUserId)
          .listen((callData) {
        if (!mounted || callData == null) return;
        final callId = (callData['id'] ?? '').toString();
        if (callId.isEmpty || callId == _lastHandledCallId) return;
        _lastHandledCallId = callId;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CallScreen(
              peerName: (callData['caller_name'] ?? 'Apolo User').toString(),
              peerAvatar: callData['caller_avatar']?.toString(),
              peerId: int.tryParse('${callData['caller_id'] ?? ''}'),
              conversationDocId: callData['conversation_doc_id']?.toString(),
              isVideo: callData['is_video'] == true,
              incomingCallId: callId,
              incomingOfferJson: (callData['offer'] ?? '').toString(),
            ),
          ),
        );
      });
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
            .map((e) =>
                _normalizeBackendConversation(Map<String, dynamic>.from(e)))
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
      'ad_price':
          (raw['ad_price'] ?? ad['price_formatted'] ?? ad['price'] ?? '')
              .toString(),
      'ad_image': (raw['ad_image'] ?? ad['primary_image'] ?? ad['image'] ?? '')
          .toString(),
      'peer_id': raw['peer_id'] ?? peer['id'] ?? 0,
      'peer_name':
          (raw['peer_name'] ?? peer['name'] ?? 'Jenny Wilson').toString(),
      'peer_avatar':
          (raw['peer_avatar'] ?? peer['avatar_url'] ?? peer['avatar'] ?? '')
              .toString(),
      'peer_online': raw['peer_online'] == true,
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
        return _effectiveUnread(conv) > 0;
      }
      return true;
    }).toList();

    // Sort: pinned conversations first (and optionally unread conversations first)
    list.sort((a, b) {
      final aPinned = _pinnedIds.contains(a['id']);
      final bPinned = _pinnedIds.contains(b['id']);
      if (aPinned != bPinned) return aPinned ? -1 : 1;
      if (_unreadFirst) {
        final aUnread = _effectiveUnread(a) > 0;
        final bUnread = _effectiveUnread(b) > 0;
        if (aUnread != bUnread) return aUnread ? -1 : 1;
      }
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
                                    _conversations
                                        .removeWhere((c) => c['id'] == convId);
                                  });
                                  _showActionSnackBar(
                                      'تم نقل المحادثة إلى الأرشيف');
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
                                  final myUserId = int.tryParse(
                                          '${_state.currentUser?['id'] ?? 0}') ??
                                      0;
                                  final peerKey =
                                      '${conv['peer_id'] ?? convId}'.trim();
                                  FirebaseChatService.instance.blockTarget(
                                    myUserId: myUserId,
                                    targetId:
                                        peerKey.isNotEmpty ? peerKey : peerName,
                                    targetName: peerName,
                                    targetAvatar: avatarUrl ?? '',
                                  );
                                  setState(() {
                                    _conversations
                                        .removeWhere((c) => c['id'] == convId);
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
                                  showApoloReportSheet(
                                    context,
                                    targetType: 'chat',
                                    targetId:
                                        '${conv['firestore_doc_id'] ?? convId}',
                                    targetName: peerName,
                                    reportedUserId: '${conv['peer_id'] ?? ''}',
                                    reportedUserAvatar: avatarUrl,
                                  );
                                },
                              ),
                              _buildAppleMenuItem(
                                icon: CupertinoIcons.trash,
                                label: 'Delete',
                                isDestructive: true,
                                onTap: () {
                                  Navigator.pop(dialogCtx);
                                  HapticFeedback.heavyImpact();
                                  final docId =
                                      conv['firestore_doc_id']?.toString();
                                  final myUserId = int.tryParse(
                                          '${_state.currentUser?['id'] ?? ''}') ??
                                      0;
                                  if (FirebaseChatService.instance.isReady &&
                                      docId != null &&
                                      docId.isNotEmpty &&
                                      myUserId > 0) {
                                    FirebaseChatService.instance
                                        .deleteConversationForMe(
                                      docId: docId,
                                      myUserId: myUserId,
                                    );
                                  }
                                  setState(() {
                                    _conversations
                                        .removeWhere((c) => c['id'] == convId);
                                  });
                                  _showActionSnackBar(
                                      'تم حذف المحادثة نهائياً');
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 2. Active Chat Preview Row Card (Exact match to screenshot)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
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
                                  child: avatarUrl != null &&
                                          avatarUrl.isNotEmpty
                                      ? AppImage(
                                          url: avatarUrl,
                                          fit: BoxFit.cover,
                                          fallback:
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
                                      style: TextStyle(
                                        color: const Color(0xFF0F172A),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing:
                                            AppTypography.trackingForContext(
                                                context, -0.2),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _state.s.tr(
                                        'أُرسلت $lastTime',
                                        'Envoyé $lastTime',
                                        'Sent $lastTime',
                                      ),
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
                letterSpacing: AppTypography.trackingForContext(context, -0.2),
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
                  border: Border(
                      right: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
                ),
                child: _buildChatsListPane(isDesktop: true),
              ),
            ),

            // Right Column: Active Chat Room
            Expanded(
              child: _activeWebConversation != null
                  ? ChatRoomScreen(
                      key: ValueKey(
                          'active_web_${_activeWebConversation!['firestore_doc_id'] ?? _activeWebConversation!['id']}'),
                      conversationId:
                          int.tryParse('${_activeWebConversation!['id']}') ??
                              101,
                      firestoreDocId: _activeWebConversation!['firestore_doc_id']
                          ?.toString(),
                      peerId: int.tryParse(
                          '${_activeWebConversation!['peer_id'] ?? ''}'),
                      peerName: (_activeWebConversation!['peer_name'] ??
                              'Apolo User')
                          .toString(),
                      adTitle:
                          _activeWebConversation!['ad_title']?.toString() ?? '',
                      peerAvatar:
                          _activeWebConversation!['peer_avatar']?.toString(),
                      adImage:
                          _activeWebConversation!['ad_image']?.toString(),
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

  void _openMoreSheet() {
    HapticFeedback.selectionClick();
    final s = _state.s;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _selectedFilterIndex = 0;
                _unreadFirst = false;
              });
            },
            child: Text(
              s.tr('عرض كل المحادثات', 'Toutes les discussions',
                  'Show all chats'),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _unreadFirst = !_unreadFirst);
            },
            child: Text(
              _unreadFirst
                  ? s.tr('الترتيب الافتراضي', 'Tri par défaut', 'Default order')
                  : s.tr('غير المقروءة أولاً', 'Non lus en premier',
                      'Unread first'),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _loadConversations();
            },
            child: Text(s.tr('تحديث المحادثات', 'Actualiser', 'Refresh chats')),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: Text(s.tr('إلغاء', 'Annuler', 'Cancel')),
        ),
      ),
    );
  }

  void _openCameraSheet() {
    HapticFeedback.selectionClick();
    final s = _state.s;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(s.tr('مشاركة صور', 'Partager des photos', 'Share photos')),
        message: Text(
          s.tr(
            'أنشئ إعلاناً جديداً بالصور أو افتح أي محادثة للمراسلة.',
            'Publiez une annonce avec photos ou ouvrez une discussion.',
            'Create a listing with photos or open a chat to message.',
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _openPostAd();
            },
            child: Text(s.tr('نشر إعلان بالصور', 'Publier avec photo',
                'Post listing with photos')),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: Text(s.tr('إلغاء', 'Annuler', 'Cancel')),
        ),
      ),
    );
  }

  Widget _buildChatsListPane({required bool isDesktop}) {
    final filtered = _filteredConversations;
    final s = _state.s;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Top Action Bar: `...` pill on start, bare Camera & Sky-Blue `+` on end
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PressableScale(
                onTap: _openMoreSheet,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: _surfaceGrey,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    CupertinoIcons.ellipsis,
                    color: _textBlack,
                    size: 18,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PressableScale(
                    onTap: _openCameraSheet,
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Center(
                        child: Icon(
                          CupertinoIcons.camera,
                          color: _textBlack,
                          size: 21,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PressableScale(
                    onTap: _openPostAd,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _chatBlue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _chatBlue.withValues(alpha: 0.28),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        CupertinoIcons.plus,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 2. Bold Chats Title
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
          child: Text(
            s.tr('المحادثات', 'Messages', 'Chats'),
            style: TextStyle(
              color: _textBlack,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: AppTypography.trackingForContext(context, -0.6),
            ),
          ),
        ),

        // 3. Compact Rounded Search Bar (`Search chat`)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: _surfaceGrey,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(
                color: _textBlack,
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: s.tr('ابحث في المحادثات', 'Rechercher', 'Search chat'),
                hintStyle: const TextStyle(
                  color: _textSubtle,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: const Icon(
                  CupertinoIcons.search,
                  color: _textSubtle,
                  size: 18,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          CupertinoIcons.xmark_circle_fill,
                          color: _textSubtle,
                          size: 17,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 4. Filter Pills (`All` / `Unread`) + trailing sort icon
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _buildTabPill(0, s.tr('الكل', 'Tous', 'All')),
              const SizedBox(width: 8),
              _buildTabPill(1, s.tr('غير مقروءة', 'Non lus', 'Unread')),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _unreadFirst = !_unreadFirst);
                },
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 32,
                  height: 28,
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Icon(
                      Icons.filter_list_rounded,
                      color: _unreadFirst ? _chatBlue : _textMuted,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

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
                                color: _chatBlueSoft,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.chat_bubble_2_fill,
                                color: _chatBlue,
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
                                  color: _chatBlue,
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _chatBlue.withValues(alpha: 0.30),
                                      blurRadius: 12,
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
                                      color: _chatBlue,
                                    ),
                                    label: const Text(
                                      'تصفح الإعلانات',
                                      style: TextStyle(
                                        color: _chatBlue,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      : PullToRefresh(
                          onRefresh: _loadConversations,
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final conv = filtered[index];
                              final isSelected = isDesktop &&
                                  _activeWebConversation?['id'] == conv['id'];
                              return _buildChatRow(conv, isSelected, isDesktop);
                            },
                          ),
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
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? _textBlack : _surfaceGrey,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : _textMuted,
            fontSize: 12.5,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
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
    final int unread = _effectiveUnread(conv);
    final bool isOnline = conv['peer_online'] == true;
    final bool isPinned = _pinnedIds.contains(convId);
    final bool isMuted = _mutedIds.contains(convId);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        final prevUnread = _effectiveUnread(conv);
        final updatedMs = int.tryParse('${conv['updated_at_ms'] ?? 0}') ?? 0;
        _optimisticallyReadAtMs[_convKey(conv)] = updatedMs;
        setState(() {
          conv['unread_count'] = 0;
          _activeWebConversation = conv;
        });
        _state.decrementUnreadChatCountOptimistically(prevUnread);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(
              key: ValueKey(
                  'chat_${conv['firestore_doc_id'] ?? convId}_${DateTime.now().millisecondsSinceEpoch}'),
              conversationId: convId,
              firestoreDocId: conv['firestore_doc_id']?.toString(),
              peerId: int.tryParse('${conv['peer_id'] ?? ''}'),
              peerName: peerName,
              adTitle: conv['ad_title']?.toString() ?? '',
              peerAvatar: avatarUrl,
              adImage: conv['ad_image']?.toString(),
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
        color: isSelected ? _chatBlueSoft.withValues(alpha: 0.45) : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        child: Row(
          children: [
            // Avatar (46x46) with optional Green Online Status Dot
            NotificationBadge(
              count: isOnline ? 1 : 0,
              type: NotificationBadgeType.dot,
              variant: NotificationBadgeVariant.green,
              top: 0,
              right: 0,
              child: Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _surfaceGrey,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: avatarUrl != null && avatarUrl.isNotEmpty
                      ? AppImage(
                          url: avatarUrl,
                          width: 46,
                          height: 46,
                          fit: BoxFit.cover,
                          fallback: _buildAvatarFallback(peerName),
                        )
                      : _buildAvatarFallback(peerName),
                ),
              ),
            ),
            const SizedBox(width: 12),

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
                          style: TextStyle(
                            color: _textBlack,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing:
                                AppTypography.trackingForContext(context, -0.2),
                          ),
                        ),
                      ),
                      if (isPinned) ...[
                        const SizedBox(width: 5),
                        const Icon(
                          CupertinoIcons.pin_fill,
                          color: _chatBlue,
                          size: 12.5,
                        ),
                      ],
                      if (isMuted) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          CupertinoIcons.bell_slash_fill,
                          color: _textSubtle,
                          size: 12.5,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lastMsg,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: unread > 0 ? _textBlack : _textMuted,
                      fontSize: 13,
                      fontWeight:
                          unread > 0 ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Right Column: Timestamp & Sky-Blue Unread Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  lastTime,
                  style: const TextStyle(
                    color: _textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 20,
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: NotificationBadge(
                      count: unread,
                      type: NotificationBadgeType.number,
                      variant: NotificationBadgeVariant.red,
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

  Widget _buildAvatarFallback(String name) {
    return Container(
      color: _chatBlueSoft,
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'A',
        style: const TextStyle(
          color: _chatBlue,
          fontSize: 16.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
