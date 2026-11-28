import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/config/app_config.dart';
import '../core/services/chat_realtime_client.dart';
import '../core/services/firebase_chat_service.dart';
import '../core/state/app_state.dart';
import '../theme/app_typography.dart';
import '../widgets/apolo_badges_kit.dart';
import '../widgets/chat_message.dart';
import '../widgets/dl_settings_kit.dart';
import '../widgets/notification_badge.dart';
import '../widgets/pull_to_refresh.dart';
import 'auth_screen.dart';
import 'call_screen.dart';
import 'chat_room_screen.dart';
import 'widgets/apolo_safety_sheet.dart';
import 'widgets/app_image.dart';
import 'widgets/chat_utils.dart';
import 'widgets/skeleton_loader.dart';
import '../l10n/l10n.dart';

/// Dynamic Layer v5.1 `Inbox` / `Chats` Screen (`21768:49231`):
/// - Large `Chats` title (`16px` horizontal padding, pure `#FFFFFF` / `#121212` canvas) + 1-tap `Mark all read` pill.
/// - `#EEEEEE` stadium `Search` bar:
///   - `Default`: `#EEEEEE` fill, `#757575` magnifying glass + `Search` hint, no border.
///   - `Search / Active` (focused): `#EEEEEE` fill + `1.5px` `#000000` solid border + trailing `×` button.
///   - `Search / Filled` (unfocused with query): `#EEEEEE` fill, no border, `#000000` text + `#757575` trailing `×`.
/// - `All` / `Unread` (+ `Pinned`) `36px` stadium filter pills (`#000000` + `#FFFFFF` active, `#EEEEEE` + `#000000` inactive).
/// - `48 × 48` `#EEEEEE` monochrome circular avatars with green online status dot, `ApoloVerifiedBadge` on verified peers,
///   `#F6F6F6` listing context tag, 2-line message previews (`#757575` read, `#000000` semi-bold unread + `#E31B23` capped count badge),
///   `1px` `#EEEEEE` divider between rows, Dynamic Layer long-press action sheet, and E2EE footer.
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

  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _firestoreConversations = [];
  List<Map<String, dynamic>> _backendConversations = [];
  final Map<String, int> _optimisticallyReadAtMs = {};
  final Set<int> _pinnedIds = {};
  final Set<int> _mutedIds = {};
  bool _isLoading = true;
  String _searchQuery = '';
  int _selectedFilterIndex = 0; // 0: All, 1: Unread, 2: Pinned
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Active conversation for desktop 2-column web view
  Map<String, dynamic>? _activeWebConversation;
  StreamSubscription<List<Map<String, dynamic>>>? _convSub;
  StreamSubscription<Map<String, dynamic>?>? _incomingCallSub;
  StreamSubscription<Map<String, dynamic>>? _wsMsgSub;
  Timer? _inboxSyncTimer;
  static const Duration _inboxPollingInterval = Duration(milliseconds: 2500);
  static const Duration _backendTimeout = Duration(seconds: 3);
  static final Options _backendTimeoutOptions = Options(
    sendTimeout: _backendTimeout,
    receiveTimeout: _backendTimeout,
  );

  bool _fetchingInboxInFlight = false;
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
    _wsMsgSub = ChatRealtimeClient.instance.incomingMessages.listen((msg) {
      if (!mounted || !_state.isLoggedIn) return;
      _applyRealtimeMessageToInbox(msg);
    });
    _inboxSyncTimer = Timer.periodic(_inboxPollingInterval, (_) {
      if (!mounted || !_state.isLoggedIn || _fetchingInboxInFlight) {
        return;
      }
      unawaited(_fetchBackendConversationsInBackground());
    });
    _loadConversations();
  }

  /// Immediately updates the inbox UI in 0ms when a WebSocket message arrives,
  /// without waiting for the 2.5s periodic sync timer.
  void _applyRealtimeMessageToInbox(Map<String, dynamic> msg) {
    final myUserId = int.tryParse('${_state.currentUser?['id'] ?? 0}') ?? 0;
    final senderId = int.tryParse('${msg['sender_id'] ?? 0}') ?? 0;
    final channelId = (msg['channel_id'] ?? '').toString().trim();
    final bodyRaw = (msg['body'] ?? '').toString().trim();
    final msgType = (msg['type'] ?? 'text').toString();
    final preview = bodyRaw.isNotEmpty
        ? bodyRaw
        : (msgType == 'image'
            ? '📷 Photo'
            : (msgType == 'audio' ? '🎤 Voice message' : ''));
    if (preview.isEmpty) return;

    final createdDt =
        DateTime.tryParse((msg['created_at'] ?? '').toString())?.toLocal() ??
            DateTime.now();
    final nowMs = createdDt.millisecondsSinceEpoch;
    final timeStr = formatChatClock(createdDt);

    final matchIdx = _conversations.indexWhere((c) {
      final docId = (c['firestore_doc_id'] ?? '').toString().trim();
      if (channelId.isNotEmpty && docId.isNotEmpty && docId == channelId) {
        return true;
      }
      final convId = int.tryParse('${c['backend_id'] ?? c['id'] ?? 0}') ?? 0;
      if (convId > 0 && channelId == 'conv_$convId') return true;
      final peerId = int.tryParse('${c['peer_id'] ?? 0}') ?? 0;
      if (senderId > 0 && senderId != myUserId && peerId == senderId) {
        return true;
      }
      return false;
    });

    if (matchIdx >= 0) {
      setState(() {
        final updated = Map<String, dynamic>.from(_conversations[matchIdx]);
        updated['last_message'] = preview;
        updated['last_message_time'] = timeStr;
        updated['updated_at_ms'] = nowMs;
        final isActiveOpenRoom = FirebaseChatService.activeChatDocId != null &&
            FirebaseChatService.activeChatDocId == updated['firestore_doc_id'];
        if (senderId > 0 && senderId != myUserId && !isActiveOpenRoom) {
          final prevUnread = _effectiveUnread(updated);
          updated['unread_count'] = prevUnread + 1;
        }
        _conversations
          ..removeAt(matchIdx)
          ..insert(0, updated);
      });
    } else {
      unawaited(_fetchBackendConversationsInBackground());
    }
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
    } else {
      setState(() {});
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
    _inboxSyncTimer?.cancel();
    _wsMsgSub?.cancel();
    _convSub?.cancel();
    _incomingCallSub?.cancel();
    _state.removeListener(_onStateChanged);
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _findMatchingActiveWebConversation(
    List<Map<String, dynamic>> list,
    Map<String, dynamic>? current,
  ) {
    if (list.isEmpty) return null;
    if (current == null) return list.first;
    final activeDocId = current['firestore_doc_id']?.toString();
    final activeBackendId = int.tryParse('${current['backend_id'] ?? 0}') ?? 0;
    final activeId = int.tryParse('${current['id'] ?? 0}') ?? 0;
    final activePeerId = int.tryParse('${current['peer_id'] ?? 0}') ?? 0;

    for (final c in list) {
      final cDoc = c['firestore_doc_id']?.toString();
      if (activeDocId != null && activeDocId.isNotEmpty && cDoc == activeDocId) {
        return c;
      }
      final cBackendId = int.tryParse('${c['backend_id'] ?? 0}') ?? 0;
      if (activeBackendId > 0 && cBackendId == activeBackendId) {
        return c;
      }
      final cId = int.tryParse('${c['id'] ?? 0}') ?? 0;
      if (activeId > 0 && (cId == activeId || cBackendId == activeId)) {
        return c;
      }
      final cPeerId = int.tryParse('${c['peer_id'] ?? 0}') ?? 0;
      if (activePeerId > 0 && cPeerId == activePeerId) {
        return c;
      }
    }
    return list.first;
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
    if (!_state.isLoggedIn || _fetchingInboxInFlight) return;
    _fetchingInboxInFlight = true;
    try {
      final res = await _state.api.dio
          .get('/chat/conversations', options: _backendTimeoutOptions)
          .timeout(_backendTimeout);
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
          _activeWebConversation = _findMatchingActiveWebConversation(
            _conversations,
            _activeWebConversation,
          );
          _isLoading = false;
        });
      }
    } catch (_) {
    } finally {
      _fetchingInboxInFlight = false;
    }
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
          _activeWebConversation = _findMatchingActiveWebConversation(
            _conversations,
            _activeWebConversation,
          );
          _isLoading = false;
        });
      }, onError: (_) {
        unawaited(_fetchBackendConversationsInBackground());
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

    if (_fetchingInboxInFlight) return;
    _fetchingInboxInFlight = true;
    setState(() => _isLoading = true);
    try {
      final res = await _state.api.dio
          .get('/chat/conversations', options: _backendTimeoutOptions)
          .timeout(_backendTimeout);
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
            _backendConversations = parsed;
            _conversations = parsed;
            _activeWebConversation ??=
                _conversations.isNotEmpty ? _conversations.first : null;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {
    } finally {
      _fetchingInboxInFlight = false;
    }

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
    final int myUserId = int.tryParse('${_state.currentUser?['id'] ?? 0}') ?? 0;

    int resolvedPeerId = int.tryParse('${raw['peer_id'] ?? peer['id'] ?? 0}') ?? 0;
    if (resolvedPeerId <= 0 || resolvedPeerId == myUserId) {
      for (final candidate in [
        raw['other_user_id'],
        raw['receiver_id'],
        raw['seller_id'],
        raw['buyer_id'],
        raw['user_two_id'],
        raw['user_one_id'],
      ]) {
        final cid = int.tryParse('${candidate ?? 0}') ?? 0;
        if (cid > 0 && cid != myUserId) {
          resolvedPeerId = cid;
          break;
        }
      }
    }

    return {
      'id': convId,
      if (convId > 0) 'backend_id': convId,
      'ad_id': raw['ad_id'] ?? ad['id'] ?? 0,
      'ad_title': (raw['ad_title'] ?? ad['title'] ?? '').toString(),
      'ad_price':
          (raw['ad_price'] ?? ad['price_formatted'] ?? ad['price'] ?? '')
              .toString(),
      'ad_image': (raw['ad_image'] ?? ad['primary_image'] ?? ad['image'] ?? '')
          .toString(),
      'peer_id': resolvedPeerId,
      'peer_name':
          (raw['peer_name'] ?? peer['name'] ?? 'Jenny Wilson').toString(),
      'peer_avatar':
          (raw['peer_avatar'] ?? peer['avatar_url'] ?? peer['avatar'] ?? '')
              .toString(),
      'peer_online': raw['peer_online'] == true || peer['is_online'] == true,
      'peer_verified': AppConfig.enablePremiumAndBusinessTiers &&
          (raw['is_pro_plus'] == true || peer['is_pro_plus'] == true),
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
        final adTitle = (conv['ad_title'] ?? '').toString().toLowerCase();
        if (!peer.contains(q) && !msg.contains(q) && !adTitle.contains(q)) {
          return false;
        }
      }
      if (_selectedFilterIndex == 1) {
        return _effectiveUnread(conv) > 0;
      }
      if (_selectedFilterIndex == 2) {
        final convId = int.tryParse('${conv['id'] ?? 0}') ?? 0;
        return _pinnedIds.contains(convId);
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

  void _markAllConversationsRead() {
    HapticFeedback.mediumImpact();
    int totalCleared = 0;
    setState(() {
      for (final conv in _conversations) {
        final prev = _effectiveUnread(conv);
        totalCleared += prev;
        final updatedMs = int.tryParse('${conv['updated_at_ms'] ?? 0}') ?? 0;
        _optimisticallyReadAtMs[_convKey(conv)] = updatedMs;
        conv['unread_count'] = 0;
      }
    });
    if (totalCleared > 0) {
      _state.decrementUnreadChatCountOptimistically(totalCleared);
    }
    try {
      unawaited(
        _state.api.dio
            .post('/chat/read-all', options: _backendTimeoutOptions)
            .timeout(_backendTimeout)
            .catchError((_) => Response(requestOptions: RequestOptions())),
      );
    } catch (_) {}
  }

  /// Dynamic Layer v5.1 Conversation Action Sheet (replaces legacy blurred shadow popup).
  Future<void> _showChatActionsSheet(Map<String, dynamic> conv) async {
    HapticFeedback.mediumImpact();
    final s = _state.s;
    final int convId = int.tryParse('${conv['id'] ?? 0}') ?? 0;
    final String peerName = (conv['peer_name'] ?? 'Jenny Wilson').toString();
    final String? avatarUrl = conv['peer_avatar']?.toString();
    final String lastTime = (conv['last_message_time'] ?? '9:41').toString();
    final bool isPinned = _pinnedIds.contains(convId);
    final bool isMuted = _mutedIds.contains(convId);
    final bool isVerified = conv['peer_verified'] == true;
    final int unread = _effectiveUnread(conv);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) {
        return Directionality(
          textDirection: s.isAr ? TextDirection.rtl : TextDirection.ltr,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFEEEEEE),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: avatarUrl != null && avatarUrl.isNotEmpty
                            ? AppImage(
                                url: avatarUrl,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                fallback: _buildAvatarFallback(peerName),
                              )
                            : _buildAvatarFallback(peerName),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    peerName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF000000),
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (isVerified) ...[
                                  const SizedBox(width: 5),
                                  const ApoloVerifiedBadge(size: 15),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              s.tr(
                                'آخر رسالة $lastTime',
                                'Dernier message $lastTime',
                                appL10n.chatListLastMessageLasttime(lastTime),
                              ),
                              style: const TextStyle(
                                color: Color(0xFF757575),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ApoloDlIconCircleButton(
                        icon: CupertinoIcons.xmark,
                        iconSize: 16,
                        backgroundColor: const Color(0xFFEEEEEE),
                        iconColor: const Color(0xFF000000),
                        onPressed: () => Navigator.of(sheetCtx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F6F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDlSheetActionRow(
                          rowKey: const Key('inbox-sheet-pin'),
                          icon: isPinned
                              ? CupertinoIcons.pin_slash
                              : CupertinoIcons.pin,
                          label: isPinned
                              ? s.tr('إلغاء التثبيت', 'Désépingler', appL10n.chatListUnpinChat)
                              : s.tr('تثبيت في الأعلى', 'Épingler', appL10n.chatListPinChat),
                          onTap: () {
                            Navigator.of(sheetCtx).pop();
                            HapticFeedback.mediumImpact();
                            setState(() {
                              if (isPinned) {
                                _pinnedIds.remove(convId);
                                if (_pinnedIds.isEmpty &&
                                    _selectedFilterIndex == 2) {
                                  _selectedFilterIndex = 0;
                                }
                              } else {
                                _pinnedIds.add(convId);
                              }
                            });
                            _showActionSnackBar(
                              isPinned
                                  ? s.tr(
                                      'تم إلغاء تثبيت المحادثة',
                                      'Discussion désépinglée',
                                      appL10n.chatListChatUnpinned,
                                    )
                                  : s.tr(
                                      'تم تثبيت المحادثة في الأعلى',
                                      'Discussion épinglée',
                                      appL10n.chatListChatPinnedTop,
                                    ),
                            );
                          },
                        ),
                        if (unread > 0) ...[
                          _buildSheetDivider(),
                          _buildDlSheetActionRow(
                            rowKey: const Key('inbox-sheet-mark-read'),
                            icon: CupertinoIcons.checkmark_alt,
                            label: s.tr(
                              'تحديد كمقروء',
                              'Marquer comme lu',
                              appL10n.chatListMarkAsRead,
                            ),
                            onTap: () {
                              Navigator.of(sheetCtx).pop();
                              HapticFeedback.selectionClick();
                              final updatedMs =
                                  int.tryParse('${conv['updated_at_ms'] ?? 0}') ??
                                      0;
                              _optimisticallyReadAtMs[_convKey(conv)] =
                                  updatedMs;
                              setState(() => conv['unread_count'] = 0);
                              _state.decrementUnreadChatCountOptimistically(
                                unread,
                              );
                            },
                          ),
                        ],
                        _buildSheetDivider(),
                        _buildDlSheetActionRow(
                          rowKey: const Key('inbox-sheet-mute'),
                          icon: isMuted
                              ? CupertinoIcons.bell
                              : CupertinoIcons.bell_slash,
                          label: isMuted
                              ? s.tr(
                                  'تفعيل الإشعارات',
                                  'Réactiver les alertes',
                                  appL10n.chatListUnmuteNotifications,
                                )
                              : s.tr(
                                  'كتم الإشعارات',
                                  'Mettre en sourdine',
                                  appL10n.chatListMuteNotifications,
                                ),
                          onTap: () {
                            Navigator.of(sheetCtx).pop();
                            HapticFeedback.mediumImpact();
                            setState(() {
                              if (isMuted) {
                                _mutedIds.remove(convId);
                              } else {
                                _mutedIds.add(convId);
                              }
                            });
                            _showActionSnackBar(
                              isMuted
                                  ? s.tr(
                                      'تم إلغاء كتم الإشعارات',
                                      'Notifications réactivées',
                                      appL10n.chatListNotificationsUnmuted,
                                    )
                                  : s.tr(
                                      'تم كتم إشعارات المحادثة',
                                      'Discussion mise en sourdine',
                                      appL10n.chatListChatMuted,
                                    ),
                            );
                          },
                        ),
                        _buildSheetDivider(),
                        _buildDlSheetActionRow(
                          rowKey: const Key('inbox-sheet-archive'),
                          icon: CupertinoIcons.archivebox,
                          label: s.tr(
                            'نقل إلى الأرشيف',
                            'Archiver la discussion',
                            appL10n.chatListArchiveChat,
                          ),
                          onTap: () {
                            Navigator.of(sheetCtx).pop();
                            HapticFeedback.mediumImpact();
                            setState(() {
                              _conversations
                                  .removeWhere((c) => c['id'] == convId);
                            });
                            _showActionSnackBar(
                              s.tr(
                                'تم نقل المحادثة إلى الأرشيف',
                                'Discussion archivée',
                                appL10n.chatListChatArchived,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F6F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDlSheetActionRow(
                          rowKey: const Key('inbox-sheet-report'),
                          icon: CupertinoIcons.flag,
                          label: s.tr(
                            'الإبلاغ عن المحادثة',
                            'Signaler la discussion',
                            appL10n.chatListReportChat,
                          ),
                          onTap: () {
                            Navigator.of(sheetCtx).pop();
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
                        _buildSheetDivider(),
                        _buildDlSheetActionRow(
                          rowKey: const Key('inbox-sheet-block'),
                          icon: CupertinoIcons.nosign,
                          label: s.tr(
                            'حظر $peerName',
                            'Bloquer $peerName',
                            appL10n.chatListBlockPeername(peerName),
                          ),
                          onTap: () {
                            Navigator.of(sheetCtx).pop();
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
                            _showActionSnackBar(
                              s.tr(
                                'تم حظر $peerName',
                                '$peerName a été bloqué',
                                appL10n.chatListBlockedPeername(peerName),
                              ),
                            );
                          },
                        ),
                        _buildSheetDivider(),
                        _buildDlSheetActionRow(
                          rowKey: const Key('inbox-sheet-delete'),
                          icon: CupertinoIcons.trash,
                          label: s.tr(
                            'حذف المحادثة',
                            'Supprimer la discussion',
                            appL10n.chatListDeleteChat,
                          ),
                          isDestructive: true,
                          onTap: () {
                            Navigator.of(sheetCtx).pop();
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
                              s.tr(
                                'تم حذف المحادثة',
                                'Discussion supprimée',
                                appL10n.chatListChatDeleted,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetDivider() {
    return const Padding(
      padding: EdgeInsetsDirectional.only(start: 56),
      child: SizedBox(
        height: 1,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(color: Color(0xFFEEEEEE)),
        ),
      ),
    );
  }

  Widget _buildDlSheetActionRow({
    required Key rowKey,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final Color fg =
        isDestructive ? const Color(0xFFE31B23) : const Color(0xFF000000);
    return InkWell(
      key: rowKey,
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 17, color: fg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fg,
                  fontSize: 14.5,
                  fontWeight: isDestructive ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActionSnackBar(String message) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF000000),
          shape: const StadiumBorder(),
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final Color ink = isDark ? Colors.white : const Color(0xFF000000);
    final Color surfaceSubtle =
        isDark ? const Color(0xFF1E1E22) : const Color(0xFFF6F6F6);
    final Color mutedText =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF757575);
    final Color borderColor =
        isDark ? const Color(0xFF262629) : const Color(0xFFEEEEEE);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopWeb = screenWidth >= 800;

    final effectiveDir = _state.s.isAr
        ? TextDirection.rtl
        : Directionality.of(context);

    if (isDesktopWeb) {
      return Directionality(
        textDirection: effectiveDir,
        child: Scaffold(
          backgroundColor: bgColor,
          body: Row(
            children: [
              SizedBox(
                width: 380,
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: BorderDirectional(
                      end: BorderSide(color: borderColor, width: 1),
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
                        firestoreDocId:
                            _activeWebConversation!['firestore_doc_id']
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
                        isPeerVerified:
                            _activeWebConversation!['peer_verified'] == true,
                      )
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: surfaceSubtle,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  CupertinoIcons.chat_bubble_2,
                                  size: 24,
                                  color: ink,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                _state.s.tr(
                                  'حدد محادثة لبدء المراسلة',
                                  'Sélectionnez une discussion',
                                  appL10n.chatListSelectConversationStartMessaging,
                                ),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: mutedText,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
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

    return Directionality(
      textDirection: effectiveDir,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          bottom: false,
          child: _buildChatsListPane(
            isDesktop: false,
            isDark: isDark,
          ),
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
    final Color surfaceSubtle =
        isDark ? const Color(0xFF1E1E22) : const Color(0xFFF6F6F6);
    final Color mutedText =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF757575);
    final Color dividerColor =
        isDark ? const Color(0xFF262629) : const Color(0xFFEEEEEE);

    final bool searchFocused = _searchFocusNode.hasFocus;
    final bool showSearchClear = searchFocused || _searchQuery.isNotEmpty;
    final bool hasAnyUnread =
        _state.isLoggedIn && _conversations.any((c) => _effectiveUnread(c) > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Dynamic Layer v5.1 Compact `Chats` Title + optional `Mark all read` capsule
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  s.tr('المحادثات', 'Discussions', appL10n.chatListChats),
                  key: const Key('inbox-title'),
                  style: TextStyle(
                    color: ink,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    height: 32.0 / 26.0,
                    letterSpacing:
                        AppTypography.trackingForContext(context, -0.5),
                  ),
                ),
              ),
              if (hasAnyUnread)
                Material(
                  color: pillBg,
                  shape: const StadiumBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: const Key('inbox-mark-all-read'),
                    customBorder: const StadiumBorder(),
                    onTap: _markAllConversationsRead,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.checkmark_alt,
                            size: 14,
                            color: ink,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            s.tr('قراءة الكل', 'Tout lire', appL10n.chatListMarkAllRead),
                            style: TextStyle(
                              color: ink,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
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

        // 2. Dynamic Layer v5.1 Stadium `Search` Bar (`#EEEEEE` fill, `1.5px` `#000000` border on focus)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AnimatedContainer(
            key: const Key('inbox-search-container'),
            duration: const Duration(milliseconds: 140),
            height: 42,
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
                      hintText: s.tr('بحث', 'Rechercher', appL10n.searchTitle),
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

        const SizedBox(height: 10),

        // 3. Filter Pills (`All` | `Unread` | `Pinned` — `34px` stadium pills)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterPill(
                  index: 0,
                  key: const Key('inbox-filter-all'),
                  label: s.tr('الكل', 'Tout', appL10n.chatListAll),
                  ink: ink,
                  pillBg: pillBg,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildFilterPill(
                  index: 1,
                  key: const Key('inbox-filter-unread'),
                  label: s.tr('غير مقروءة', 'Non lus', appL10n.chatListUnread),
                  ink: ink,
                  pillBg: pillBg,
                  isDark: isDark,
                ),
                if (_pinnedIds.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _buildFilterPill(
                    index: 2,
                    key: const Key('inbox-filter-pinned'),
                    label: s.tr('المثبتة', 'Épinglés', appL10n.chatListPinned),
                    ink: ink,
                    pillBg: pillBg,
                    isDark: isDark,
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 6),

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
                        appL10n.chatListSignViewChats,
                      ),
                      description: s.tr(
                        'تواصل مباشرة مع البائعين والمشترين وتابع رسائلك بأمان.',
                        'Échangez directement avec les vendeurs et acheteurs en toute sécurité.',
                        appL10n.chatListMessageBuyersSellersDirectlySecurely,
                      ),
                      actionLabel: s.tr(
                        'تسجيل الدخول',
                        'Se connecter',
                        appL10n.signInButton,
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
                                  appL10n.chatListNoUnreadChats,
                                )
                              : _selectedFilterIndex == 2
                                  ? s.tr(
                                      'لا توجد محادثات مثبتة',
                                      'Aucune discussion épinglée',
                                      appL10n.chatListNoPinnedChats,
                                    )
                                  : s.tr(
                                      'لا توجد محادثات بعد',
                                      'Aucune discussion pour le moment',
                                      appL10n.chatListNoChatsYet,
                                    ),
                          description: s.tr(
                            'تصفح الإعلانات وتواصل مع البائعين مباشرة بأمان تام.',
                            'Parcourez les annonces et discutez directement avec les vendeurs.',
                            appL10n.chatListBrowseListingsMessageSellersDirectly,
                          ),
                          actionLabel: (widget.onExploreAds != null &&
                                  _selectedFilterIndex == 0 &&
                                  _searchQuery.trim().isEmpty)
                              ? s.tr(
                                  'تصفح الإعلانات',
                                  'Parcourir les annonces',
                                  appL10n.chatListExploreListings,
                                )
                              : null,
                          onAction: (widget.onExploreAds != null &&
                                  _selectedFilterIndex == 0 &&
                                  _searchQuery.trim().isEmpty)
                              ? widget.onExploreAds
                              : null,
                        )
                      : PullToRefresh(
                          brandColor: ink,
                          backgroundColor: isDark
                              ? const Color(0xFF121212)
                              : Colors.white,
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
                                    isDark: isDark,
                                    ink: ink,
                                    mutedText: mutedText,
                                    pillBg: pillBg,
                                    surfaceSubtle: surfaceSubtle,
                                  ),
                                  if (!isLast)
                                    Center(
                                      child: FractionallySizedBox(
                                        widthFactor: 0.62,
                                        child: Container(
                                          key: Key('inbox-divider-$index'),
                                          height: 0.75,
                                          decoration: BoxDecoration(
                                            color: dividerColor,
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                        ),
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
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              height: 18.0 / 13.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEncryptedFooter(AppStrings s, Color mutedText) {
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
                  appL10n.chatListPersonalMessagesAreEndEnd,
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
    required bool isDark,
    required Color ink,
    required Color mutedText,
    required Color pillBg,
    required Color surfaceSubtle,
  }) {
    final int convId = int.tryParse('${conv['id'] ?? 0}') ?? 0;
    final String peerName = (conv['peer_name'] ?? 'Jenny Wilson').toString();
    final String lastMsg = (conv['last_message'] ?? '').toString();
    final String lastTime = (conv['last_message_time'] ?? '').toString();
    final String? avatarUrl = conv['peer_avatar']?.toString();
    final String adTitle = (conv['ad_title'] ?? '').toString().trim();
    final String adImage = (conv['ad_image'] ?? '').toString().trim();
    final int unread = _effectiveUnread(conv);
    final bool isPinned = _pinnedIds.contains(convId);
    final bool isMuted = _mutedIds.contains(convId);
    final bool isPeerOnline = conv['peer_online'] == true;
    final bool isPeerVerified = conv['peer_verified'] == true;

    return InkWell(
      key: Key('inbox-row-$convId'),
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
              adTitle: adTitle,
              peerAvatar: avatarUrl,
              adImage: adImage.isNotEmpty ? adImage : null,
              adPrice: conv['ad_price']?.toString(),
              isPeerVerified: isPeerVerified,
            ),
          ),
        ).then((_) {
          if (mounted) _loadConversations();
        });
      },
      onLongPress: () => _showChatActionsSheet(conv),
      child: Container(
        color: isSelected ? surfaceSubtle : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 44x44 Monochrome Dynamic Layer Avatar + Bottom Green Presence Dot
            NotificationBadge(
              key: Key('inbox-online-dot-$convId'),
              count: isPeerOnline ? 1 : 0,
              type: NotificationBadgeType.dot,
              variant: NotificationBadgeVariant.green,
              bottom: 0,
              right: 0,
              dotSize: 10.5,
              borderColor: isDark ? const Color(0xFF121212) : Colors.white,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: pillBg,
                ),
                clipBehavior: Clip.antiAlias,
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? AppImage(
                        url: avatarUrl,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        fallback: _buildAvatarFallback(
                          peerName,
                          bgColor: pillBg,
                          fgColor: ink,
                        ),
                      )
                    : _buildAvatarFallback(
                        peerName,
                        bgColor: pillBg,
                        fgColor: ink,
                      ),
              ),
            ),
            const SizedBox(width: 11),

            // Middle + Right Column: Top (Name + Verified + Pin/Mute + Time), Optional Ad Tag, Bottom (Preview + Unread Badge)
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
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  height: 19.0 / 14.5,
                                  letterSpacing:
                                      AppTypography.trackingForContext(
                                          context, -0.2),
                                ),
                              ),
                            ),
                            if (isPeerVerified) ...[
                              const SizedBox(width: 4),
                              const ApoloVerifiedBadge(size: 13.5),
                            ],
                            if (isPinned) ...[
                              const SizedBox(width: 5),
                              Icon(
                                CupertinoIcons.pin_fill,
                                color: ink,
                                size: 11.5,
                              ),
                            ],
                            if (isMuted) ...[
                              const SizedBox(width: 4),
                              Icon(
                                CupertinoIcons.bell_slash_fill,
                                color: mutedText,
                                size: 11.5,
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
                          fontSize: 12.2,
                          fontWeight: FontWeight.w400,
                          height: 16.0 / 12.2,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  if (adTitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.tag_fill,
                          size: 10,
                          color: mutedText,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            adTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: mutedText,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              height: 15.0 / 11.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 2.5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          lastMsg,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection: ChatMessage.detectTextDirection(
                            lastMsg,
                            fallback: Directionality.of(context),
                          ),
                          style: TextStyle(
                            color: unread > 0 ? ink : mutedText,
                            fontSize: 13.5,
                            fontWeight: unread > 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                            height: 18.0 / 13.5,
                          ),
                        ),
                      ),
                      if (unread > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          key: Key('inbox-unread-badge-$convId'),
                          constraints: const BoxConstraints(
                            minWidth: 19,
                            minHeight: 19,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5.5,
                            vertical: 1.5,
                          ),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE31B23),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            unread > 99 ? '99+' : '$unread',
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.0,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ] else if (adImage.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 34,
                            height: 34,
                            color: surfaceSubtle,
                            child: AppImage(
                              url: adImage,
                              width: 34,
                              height: 34,
                              fit: BoxFit.cover,
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

  Widget _buildAvatarFallback(
    String name, {
    Color bgColor = const Color(0xFFEEEEEE),
    Color fgColor = const Color(0xFF000000),
  }) {
    final trimmed = name.trim();
    final initial =
        trimmed.isNotEmpty ? trimmed.characters.first.toUpperCase() : 'A';
    return Container(
      color: bgColor,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: fgColor,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
