import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/services/firebase_chat_service.dart';
import '../core/state/app_state.dart';
import '../theme/app_typography.dart';
import '../widgets/chat_message.dart';
import '../widgets/dl_settings_kit.dart';
import '../widgets/pull_to_refresh.dart';
import 'auth_screen.dart';
import 'call_screen.dart';
import 'chat_room_screen.dart';
import 'widgets/apolo_safety_sheet.dart';
import 'widgets/app_image.dart';
import 'widgets/kinetic_widgets.dart';
import 'widgets/skeleton_loader.dart';

/// Dynamic Layer v5.1 `Inbox` / `Chats` Screen (`21768:49231`):
/// - Large `Chats` title (`16px` horizontal padding, pure `#FFFFFF` / `#121212` canvas).
/// - `#EEEEEE` stadium `Search` bar:
///   - `Default`: `#EEEEEE` fill, `#757575` magnifying glass + `Search` hint, no border.
///   - `Search / Active` (focused): `#EEEEEE` fill + `1.5px` `#000000` solid border + trailing `×` button.
///   - `Search / Filled` (unfocused with query): `#EEEEEE` fill, no border, `#000000` text + `#757575` trailing `×`.
/// - `All` / `Unread` `36px` stadium filter pills (`#000000` + `#FFFFFF` active, `#EEEEEE` + `#000000` inactive).
/// - `48 × 48` circular avatars, 2-line message previews (`#757575` read, `#000000` semi-bold unread + `#E31B23` red count badge),
///   `1px` `#EEEEEE` divider between rows (none after last row), and `🔒 Your personal messages are end-to-end encrypted` footer.
/// - Responsive Desktop / Web view (`>= 800px`): 2-column split view (`380px` Inbox list + `ChatRoomScreen`).
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

  static const List<Color> _avatarPastels = <Color>[
    Color(0xFFEDE9FE),
    Color(0xFFDBEAFE),
    Color(0xFFFCE7F3),
    Color(0xFFFEF3C7),
    Color(0xFFD1FAE5),
  ];

  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _firestoreConversations = [];
  List<Map<String, dynamic>> _backendConversations = [];
  final Map<String, int> _optimisticallyReadAtMs = {};
  final Set<int> _pinnedIds = {};
  final Set<int> _mutedIds = {};
  bool _isLoading = true;
  String _searchQuery = '';
  int _selectedFilterIndex = 0; // 0: All, 1: Unread
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

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
    _searchFocusNode.addListener(_onSearchFocusChanged);
    _loadConversations();
  }

  void _onSearchFocusChanged() {
    if (mounted) setState(() {});
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
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _mergeFirestoreAndBackendConversations(
    List<Map<String, dynamic>> firestoreList,
    List<Map<String, dynamic>> backendList,
  ) {
    if (backendList.isEmpty) {
      return List<Map<String, dynamic>>.from(firestoreList);
    }
    if (firestoreList.isEmpty) {
      return List<Map<String, dynamic>>.from(backendList);
    }

    final merged = List<Map<String, dynamic>>.from(firestoreList);
    for (final bConv in backendList) {
      final bPeerId = int.tryParse('${bConv['peer_id'] ?? 0}') ?? 0;
      final bAdId = int.tryParse('${bConv['ad_id'] ?? 0}') ?? 0;
      final bConvId = int.tryParse('${bConv['id'] ?? 0}') ?? 0;

      final existingIdx = merged.indexWhere((fConv) {
        final fPeerId = int.tryParse('${fConv['peer_id'] ?? 0}') ?? 0;
        final fAdId = int.tryParse('${fConv['ad_id'] ?? 0}') ?? 0;
        if (bPeerId > 0 && fPeerId == bPeerId) {
          if (bAdId <= 0 || fAdId <= 0 || bAdId == fAdId) return true;
        }
        return false;
      });

      if (existingIdx >= 0) {
        final existing = Map<String, dynamic>.from(merged[existingIdx]);
        if (bConvId > 0) {
          existing['backend_id'] = bConvId;
        }
        if ((existing['last_message'] ?? '').toString().trim().isEmpty &&
            (bConv['last_message'] ?? '').toString().trim().isNotEmpty) {
          existing['last_message'] = bConv['last_message'];
        }
        merged[existingIdx] = existing;
      } else {
        merged.add({
          ...bConv,
          if (bConvId > 0) 'backend_id': bConvId,
        });
      }
    }
    return merged;
  }

  Future<void> _fetchBackendConversationsInBackground() async {
    if (!_state.isLoggedIn) return;
    try {
      final res = await _state.api.dio.get('/chat/conversations');
      if (!mounted) return;
      if (res.data is Map && res.data['status'] == 'success') {
        final rawList = (res.data['conversations'] ?? res.data['data'] ?? [])
            as List<dynamic>;
        final parsed = rawList
            .whereType<Map>()
            .map((e) =>
                _normalizeBackendConversation(Map<String, dynamic>.from(e)))
            .toList();
        setState(() {
          _backendConversations = parsed;
          _conversations = _mergeFirestoreAndBackendConversations(
            _firestoreConversations,
            _backendConversations,
          );
          _activeWebConversation ??=
              _conversations.isNotEmpty ? _conversations.first : null;
          _isLoading = false;
        });
      }
    } catch (_) {}
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
          _firestoreConversations = [];
          _backendConversations = [];
          _activeWebConversation = null;
          _isLoading = false;
        });
      }
      return;
    }

    final myUserId = int.tryParse('${_state.currentUser?['id'] ?? ''}') ?? 0;
    if (FirebaseChatService.instance.isReady && myUserId > 0) {
      unawaited(_fetchBackendConversationsInBackground());
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
          _firestoreConversations = list;
          _conversations = _mergeFirestoreAndBackendConversations(
            _firestoreConversations,
            _backendConversations,
          );
          if (_activeWebConversation != null) {
            final activeDocId =
                _activeWebConversation!['firestore_doc_id']?.toString();
            final updated = _conversations.where(
              (c) => c['firestore_doc_id']?.toString() == activeDocId,
            );
            _activeWebConversation = updated.isNotEmpty
                ? updated.first
                : (_conversations.isNotEmpty ? _conversations.first : null);
          } else {
            _activeWebConversation =
                _conversations.isNotEmpty ? _conversations.first : null;
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
          (raw['last_message_time'] ?? raw['updated_at_human'] ?? '9:41')
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

    list.sort((a, b) {
      final aPinned = _pinnedIds.contains(a['id']);
      final bPinned = _pinnedIds.contains(b['id']);
      if (aPinned != bPinned) return aPinned ? -1 : 1;
      return 0;
    });

    return list;
  }

  void _showAppleContextMenu(Map<String, dynamic> conv) {
    HapticFeedback.heavyImpact();
    final int convId = int.tryParse('${conv['id'] ?? 0}') ?? 0;
    final String peerName = (conv['peer_name'] ?? 'Jenny Wilson').toString();
    final String? avatarUrl = conv['peer_avatar']?.toString();
    final String lastTime = (conv['last_message_time'] ?? '9:41').toString();
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
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                              Container(
                                width: 48,
                                height: 48,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFEEEEEE),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: avatarUrl != null &&
                                          avatarUrl.isNotEmpty
                                      ? AppImage(
                                          url: avatarUrl,
                                          fit: BoxFit.cover,
                                          fallback: _buildAvatarFallback(
                                              peerName, convId),
                                        )
                                      : _buildAvatarFallback(peerName, convId),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      peerName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: const Color(0xFF000000),
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
                                        color: Color(0xFF757575),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
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
        isDestructive ? const Color(0xFFE31B23) : const Color(0xFF000000);

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
        backgroundColor: const Color(0xFF000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final Color mutedText =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF757575);
    final Color borderColor =
        isDark ? const Color(0xFF262629) : const Color(0xFFEEEEEE);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopWeb = screenWidth >= 800;

    if (isDesktopWeb) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Row(
          children: [
            SizedBox(
              width: 380,
              child: Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border(
                    right: BorderSide(color: borderColor, width: 1),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: _buildChatsListPane(
                    isDesktop: true,
                    isDark: isDark,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _activeWebConversation != null
                  ? ChatRoomScreen(
                      key: ValueKey(
                          'active_web_${_activeWebConversation!['firestore_doc_id'] ?? _activeWebConversation!['id']}'),
                      conversationId:
                          int.tryParse('${_activeWebConversation!['id']}') ??
                              101,
                      backendConversationId: int.tryParse(
                          '${_activeWebConversation!['backend_id'] ?? ''}'),
                      adId: int.tryParse(
                          '${_activeWebConversation!['ad_id'] ?? ''}'),
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
                  : Center(
                      child: Text(
                        _state.s.tr(
                          'حدد محادثة لبدء المراسلة',
                          'Sélectionnez une discussion',
                          'Select a conversation to start messaging',
                        ),
                        style: TextStyle(color: mutedText, fontSize: 15),
                      ),
                    ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: _buildChatsListPane(
          isDesktop: false,
          isDark: isDark,
        ),
      ),
    );
  }

  Widget _buildChatsListPane({
    required bool isDesktop,
    required bool isDark,
  }) {
    final filtered = _filteredConversations;
    final s = _state.s;

    final Color ink = isDark ? Colors.white : const Color(0xFF000000);
    final Color pillBg =
        isDark ? const Color(0xFF262629) : const Color(0xFFEEEEEE);
    final Color mutedText =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF757575);
    final Color dividerColor =
        isDark ? const Color(0xFF262629) : const Color(0xFFEEEEEE);

    final bool searchFocused = _searchFocusNode.hasFocus;
    final bool showSearchClear = searchFocused || _searchQuery.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Dynamic Layer v5.1 Large `Chats` Title (`16px` horizontal padding, clean top)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Text(
            s.tr('المحادثات', 'Discussions', 'Chats'),
            key: const Key('inbox-title'),
            style: TextStyle(
              color: ink,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 36.0 / 28.0,
              letterSpacing: AppTypography.trackingForContext(context, -0.5),
            ),
          ),
        ),

        // 2. Dynamic Layer v5.1 Stadium `Search` Bar (`#EEEEEE` fill, `1.5px` `#000000` border on focus)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AnimatedContainer(
            key: const Key('inbox-search-container'),
            duration: const Duration(milliseconds: 140),
            height: 46,
            decoration: BoxDecoration(
              color: pillBg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: searchFocused ? ink : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(
                  CupertinoIcons.search,
                  color: searchFocused ? ink : mutedText,
                  size: 19,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    key: const Key('inbox-search-field'),
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    textAlignVertical: TextAlignVertical.center,
                    cursorColor: ink,
                    cursorWidth: 2.0,
                    style: TextStyle(
                      color: ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 20.0 / 15.0,
                    ),
                    decoration: InputDecoration(
                      hintText: s.tr('بحث', 'Rechercher', 'Search'),
                      hintStyle: TextStyle(
                        color: mutedText,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        height: 20.0 / 15.0,
                      ),
                      filled: false,
                      fillColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                if (showSearchClear)
                  GestureDetector(
                    key: const Key('inbox-search-clear'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      if (_searchController.text.isNotEmpty) {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      } else {
                        _searchFocusNode.unfocus();
                      }
                    },
                    child: SizedBox(
                      width: 40,
                      height: 44,
                      child: Center(
                        child: Icon(
                          CupertinoIcons.xmark,
                          color: searchFocused ? ink : mutedText,
                          size: 16,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 14),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // 3. Filter Pills (`All` | `Unread` — `36px` stadium pills)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildFilterPill(
                index: 0,
                key: const Key('inbox-filter-all'),
                label: s.tr('الكل', 'Tout', 'All'),
                ink: ink,
                pillBg: pillBg,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildFilterPill(
                index: 1,
                key: const Key('inbox-filter-unread'),
                label: s.tr('غير مقروءة', 'Non lus', 'Unread'),
                ink: ink,
                pillBg: pillBg,
                isDark: isDark,
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // 4. Conversations List / States
        Expanded(
          child: _isLoading
              ? const ChatListSkeleton()
              : !_state.isLoggedIn
                  ? ApoloDlEmptyState(
                      icon: CupertinoIcons.bubble_left_bubble_right,
                      headline: s.tr(
                        'سجّل الدخول لعرض محادثاتك',
                        'Connectez-vous pour voir vos discussions',
                        'Sign in to view your chats',
                      ),
                      description: s.tr(
                        'تواصل مباشرة مع البائعين والمشترين وتابع رسائلك بأمان.',
                        'Échangez directement avec les vendeurs et acheteurs en toute sécurité.',
                        'Message buyers and sellers directly and securely.',
                      ),
                      actionLabel: s.tr(
                        'تسجيل الدخول',
                        'Se connecter',
                        'Sign in',
                      ),
                      onAction: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AuthScreen(),
                          ),
                        ).then((_) => _loadConversations());
                      },
                    )
                  : filtered.isEmpty
                      ? ApoloDlEmptyState(
                          icon: CupertinoIcons.bubble_left_bubble_right,
                          headline: _selectedFilterIndex == 1
                              ? s.tr(
                                  'لا توجد رسائل غير مقروءة',
                                  'Aucun message non lu',
                                  'No unread chats',
                                )
                              : s.tr(
                                  'لا توجد محادثات بعد',
                                  'Aucune discussion pour le moment',
                                  'No chats yet',
                                ),
                          description: s.tr(
                            'تصفح الإعلانات وتواصل مع البائعين مباشرة بأمان تام.',
                            'Parcourez les annonces et discutez directement avec les vendeurs.',
                            'Browse listings and message sellers directly.',
                          ),
                          actionLabel: (widget.onExploreAds != null &&
                                  _selectedFilterIndex == 0 &&
                                  _searchQuery.trim().isEmpty)
                              ? s.tr(
                                  'تصفح الإعلانات',
                                  'Parcourir les annonces',
                                  'Explore listings',
                                )
                              : null,
                          onAction: (widget.onExploreAds != null &&
                                  _selectedFilterIndex == 0 &&
                                  _searchQuery.trim().isEmpty)
                              ? widget.onExploreAds
                              : null,
                        )
                      : PullToRefresh(
                          onRefresh: _loadConversations,
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            padding: const EdgeInsets.only(top: 2, bottom: 130),
                            itemCount: filtered.length + 1,
                            itemBuilder: (context, index) {
                              if (index == filtered.length) {
                                return _buildEncryptedFooter(s, mutedText);
                              }
                              final conv = filtered[index];
                              final isSelected = isDesktop &&
                                  _activeWebConversation?['id'] == conv['id'];
                              final isLast = index == filtered.length - 1;
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildChatRow(
                                    conv,
                                    isSelected: isSelected,
                                    ink: ink,
                                    mutedText: mutedText,
                                    pillBg: pillBg,
                                  ),
                                  if (!isLast)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Container(
                                        height: 1,
                                        color: dividerColor,
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildFilterPill({
    required int index,
    required Key key,
    required String label,
    required Color ink,
    required Color pillBg,
    required bool isDark,
  }) {
    final bool active = _selectedFilterIndex == index;
    final Color bg =
        active ? (isDark ? Colors.white : const Color(0xFF000000)) : pillBg;
    final Color fg =
        active ? (isDark ? const Color(0xFF000000) : Colors.white) : ink;

    return Material(
      color: bg,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: key,
        customBorder: const StadiumBorder(),
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedFilterIndex = index);
        },
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 20.0 / 14.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEncryptedFooter(dynamic s, Color mutedText) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.lock_fill,
              size: 12,
              color: mutedText,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                s.tr(
                  'رسائلك الشخصية مشفرة تماماً بين الطرفين',
                  'Vos messages personnels sont chiffrés de bout en bout',
                  'Your personal messages are end-to-end encrypted',
                ),
                key: const Key('inbox-e2ee-caption'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: mutedText,
                  fontSize: 12.0,
                  fontWeight: FontWeight.w400,
                  height: 16.0 / 12.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatRow(
    Map<String, dynamic> conv, {
    required bool isSelected,
    required Color ink,
    required Color mutedText,
    required Color pillBg,
  }) {
    final int convId = int.tryParse('${conv['id'] ?? 0}') ?? 0;
    final String peerName = (conv['peer_name'] ?? 'Jenny Wilson').toString();
    final String lastMsg = (conv['last_message'] ?? '').toString();
    final String lastTime = (conv['last_message_time'] ?? '').toString();
    final String? avatarUrl = conv['peer_avatar']?.toString();
    final int unread = _effectiveUnread(conv);
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
              backendConversationId:
                  int.tryParse('${conv['backend_id'] ?? ''}'),
              adId: int.tryParse('${conv['ad_id'] ?? ''}'),
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
      child: Container(
        color: isSelected ? pillBg.withValues(alpha: 0.65) : Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 48x48 Circular Avatar (Figma `Inbox` spec)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _avatarPastelFor(peerName, convId),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? AppImage(
                        url: avatarUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        fallback: _buildAvatarFallback(peerName, convId),
                      )
                    : _buildAvatarFallback(peerName, convId),
              ),
            ),
            const SizedBox(width: 12),

            // Middle + Right Column: Top (Name + Time), Bottom (2-line Preview + Red Unread Badge)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                peerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textDirection: ChatMessage.detectTextDirection(
                                  peerName,
                                  fallback: Directionality.of(context),
                                ),
                                style: TextStyle(
                                  color: ink,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  height: 20.0 / 15.0,
                                  letterSpacing:
                                      AppTypography.trackingForContext(
                                          context, -0.2),
                                ),
                              ),
                            ),
                            if (isPinned) ...[
                              const SizedBox(width: 5),
                              Icon(
                                CupertinoIcons.pin_fill,
                                color: ink,
                                size: 12,
                              ),
                            ],
                            if (isMuted) ...[
                              const SizedBox(width: 4),
                              Icon(
                                CupertinoIcons.bell_slash_fill,
                                color: mutedText,
                                size: 12,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        lastTime,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: RegExp(r'^\d').hasMatch(lastTime.trim())
                            ? TextDirection.ltr
                            : null,
                        style: TextStyle(
                          color: mutedText,
                          fontSize: 13.0,
                          fontWeight: FontWeight.w400,
                          height: 18.0 / 13.0,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          lastMsg,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textDirection: ChatMessage.detectTextDirection(
                            lastMsg,
                            fallback: Directionality.of(context),
                          ),
                          style: TextStyle(
                            color: unread > 0 ? ink : mutedText,
                            fontSize: 14.0,
                            fontWeight: unread > 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                            height: 19.5 / 14.0,
                          ),
                        ),
                      ),
                      if (unread > 0) ...[
                        const SizedBox(width: 10),
                        Container(
                          key: Key('inbox-unread-badge-$convId'),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE31B23),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            unread > 99 ? '99+' : '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _avatarPastelFor(String name, int seedId) {
    final hash = (name.hashCode.abs() + seedId.abs());
    return _avatarPastels[hash % _avatarPastels.length];
  }

  Widget _buildAvatarFallback(String name, int seedId) {
    return Container(
      color: _avatarPastelFor(name, seedId),
      alignment: Alignment.center,
      child: Text(
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'A',
        style: const TextStyle(
          color: Color(0xFF111827),
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
