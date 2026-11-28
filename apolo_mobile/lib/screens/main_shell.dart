import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/services/firebase_chat_service.dart';
import '../core/services/media_rtc_bridge.dart';
import '../core/services/push_notification_service.dart';
import '../core/state/app_state.dart';
import '../features/bug_report/services/bug_report_route_observer.dart';
import '../widgets/notification_badge.dart';
import 'call_screen.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'post_ad_screen.dart';
import 'chat_list_screen.dart';
import 'profile_screen.dart';
import 'widgets/kinetic_widgets.dart';
import '../l10n/l10n.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  final AppState _state = AppState();
  late int _currentIndex;
  int _lastPillSlot = 0;
  int? _searchInitialCategory;
  bool _searchChromeVisible = true;

  // Global Real-time Alerts (Messages, App Notifications & Incoming Calls)
  int _lastNotifCount = 0;
  int? _alertUserId;
  bool _initialConvSnapshotDone = false;
  final Map<String, int> _lastSeenConvMs = {};
  String? _lastHandledGlobalCallId;
  StreamSubscription<List<Map<String, dynamic>>>? _globalConvSub;
  StreamSubscription<Map<String, dynamic>?>? _globalCallSub;

  late final AnimationController _squashCtrl;
  late final Animation<double> _pillScaleX;
  late final Animation<double> _pillScaleY;

  // Dynamic Layer v5.1 Monochrome Dock Palette
  static const Color _ink = Color(0xFF000000);
  static const Color _inactive = Color(0xFF757575);
  static const Color _activePill = Color(0xFFEEEEEE);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4);
    _syncTabRoute(_currentIndex);
    _lastNotifCount = _state.unreadNotificationsCount;
    _bindGlobalAlerts(allowNotify: false);
    _state.addListener(_onStateChanged);
    _squashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _pillScaleX = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.18)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.18, end: 0.94)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.94, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_squashCtrl);
    _pillScaleY = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.85)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.85, end: 1.06)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.06, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_squashCtrl);
  }

  @override
  void dispose() {
    _globalConvSub?.cancel();
    _globalCallSub?.cancel();
    _state.removeListener(_onStateChanged);
    _squashCtrl.dispose();
    super.dispose();
  }

  void _bindGlobalAlerts({bool allowNotify = true}) {
    if (!_state.isLoggedIn) {
      _globalConvSub?.cancel();
      _globalConvSub = null;
      _globalCallSub?.cancel();
      _globalCallSub = null;
      _alertUserId = null;
      _initialConvSnapshotDone = false;
      _lastSeenConvMs.clear();
      _state.syncUnreadChatCount(0, notify: allowNotify);
      return;
    }
    if (!FirebaseChatService.instance.isReady) {
      _globalConvSub?.cancel();
      _globalConvSub = null;
      _globalCallSub?.cancel();
      _globalCallSub = null;
      _alertUserId = null;
      _initialConvSnapshotDone = false;
      _lastSeenConvMs.clear();
      return;
    }

    final myUserId = int.tryParse('${_state.currentUser?['id'] ?? ''}') ?? 0;
    if (myUserId <= 0 || _alertUserId == myUserId) return;
    _alertUserId = myUserId;
    _initialConvSnapshotDone = false;
    _lastSeenConvMs.clear();
    unawaited(ApoloPushNotificationService.instance.syncTokenWithBackend());

    _globalConvSub?.cancel();
    _globalConvSub = FirebaseChatService.instance
        .watchConversations(myUserId)
        .listen((list) {
      if (!mounted) return;
      int totalUnread = 0;
      Map<String, dynamic>? newestIncoming;
      int newestMs = 0;

      for (final conv in list) {
        totalUnread += int.tryParse('${conv['unread_count'] ?? 0}') ?? 0;
        final docId = (conv['firestore_doc_id'] ?? '').toString();
        final updatedMs = int.tryParse('${conv['updated_at_ms'] ?? 0}') ?? 0;
        final lastSender = (conv['last_sender_id'] ?? '').toString();
        final prevMs = _lastSeenConvMs[docId] ?? 0;

        if (_initialConvSnapshotDone &&
            updatedMs > prevMs &&
            lastSender.isNotEmpty &&
            lastSender != '$myUserId' &&
            FirebaseChatService.activeChatDocId != docId) {
          if (updatedMs > newestMs) {
            newestMs = updatedMs;
            newestIncoming = conv;
          }
        }
        _lastSeenConvMs[docId] = updatedMs;
      }

      _initialConvSnapshotDone = true;

      _state.syncUnreadChatCount(
        totalUnread,
        isMessagesTabActive: _currentIndex == 3,
      );

      if (newestIncoming != null) {
        final sender = (newestIncoming['peer_name'] ?? 'Apolo').toString();
        final body = (newestIncoming['last_message'] ?? '').toString();
        MediaRtcBridge.playMessageSound();
        unawaited(
          ApoloPushNotificationService.instance.showLocalNotification(
            title: sender,
            body: body,
            channel: ApoloPushNotificationService.channelMessages,
            payload: <String, dynamic>{
              'type': 'message',
              'firestore_doc_id': newestIncoming['firestore_doc_id'],
              'peer_id': newestIncoming['peer_id'],
              'peer_name': sender,
              'peer_avatar': newestIncoming['peer_avatar']?.toString() ?? '',
              'ad_title': newestIncoming['ad_title']?.toString() ?? '',
              'ad_price': newestIncoming['ad_price']?.toString(),
              'ad_image': newestIncoming['ad_image']?.toString(),
            },
          ),
        );
      }
    });

    _globalCallSub?.cancel();
    _globalCallSub = FirebaseChatService.instance
        .watchIncomingCalls(myUserId)
        .listen((callData) {
      if (!mounted || callData == null) return;
      final callId = (callData['id'] ?? '').toString();
      if (callId.isEmpty || callId == _lastHandledGlobalCallId) return;
      _lastHandledGlobalCallId = callId;
      final callerName = (callData['caller_name'] ?? 'Apolo User').toString();
      final isVideo = callData['is_video'] == true;
      unawaited(
        ApoloPushNotificationService.instance.showLocalNotification(
          title: callerName,
          body: isVideo
              ? _state.s.tr(
                  'مكالمة فيديو واردة...',
                  'Appel vidéo entrant...',
                  appL10n.callIncomingVideoCall,
                )
              : _state.s.tr(
                  'مكالمة صوتية واردة...',
                  'Appel vocal entrant...',
                  appL10n.callIncomingVoiceCall,
                ),
          channel: ApoloPushNotificationService.channelCalls,
          payload: <String, dynamic>{
            'type': 'call',
            'call_id': callId,
          },
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(
            peerName: callerName,
            peerAvatar: callData['caller_avatar']?.toString(),
            peerId: int.tryParse('${callData['caller_id'] ?? ''}'),
            conversationDocId: callData['conversation_doc_id']?.toString(),
            isVideo: isVideo,
            incomingCallId: callId,
            incomingOfferJson: (callData['offer'] ?? '').toString(),
          ),
        ),
      );
    });
  }

  void _triggerSquashStretch() {
    if (!MediaQuery.disableAnimationsOf(context)) {
      _squashCtrl.forward(from: 0.0);
    }
  }

  void _onStateChanged() {
    if (!mounted) return;
    _bindGlobalAlerts();
    final nextNotifCount = _state.unreadNotificationsCount;
    if (nextNotifCount > _lastNotifCount && _state.isLoggedIn) {
      MediaRtcBridge.playNotificationSound();
      final msg = _state.s.tr(
        'لديك إشعار جديد في Apolo',
        'Vous avez une nouvelle notification Apolo',
        appL10n.mainShellYouHaveNewApoloNotification,
      );
      unawaited(
        ApoloPushNotificationService.instance.showLocalNotification(
          title: 'Apolo.ma',
          body: msg,
          channel: ApoloPushNotificationService.channelAlerts,
          payload: const <String, dynamic>{'type': 'app'},
        ),
      );
    }
    _lastNotifCount = nextNotifCount;
    setState(() {});
  }

  void _handleSearchChromeVisibility(bool visible) {
    if (_searchChromeVisible != visible && mounted) {
      setState(() => _searchChromeVisible = visible);
    }
  }

  String _tabRouteName(int index) {
    return switch (index) {
      0 => 'main_shell/home',
      1 => 'main_shell/post_ad',
      2 => 'main_shell/explore',
      3 => 'main_shell/messages',
      4 => 'main_shell/profile',
      _ => 'main_shell/tab_$index',
    };
  }

  void _syncTabRoute(int index) {
    BugReportRouteObserver.instance.setActiveTab(_tabRouteName(index));
  }

  void _switchTab(
    int index, {
    int? pillSlot,
    bool updateSearchCategory = false,
    int? searchCategory,
  }) {
    if (index == 3) {
      _state.clearUnreadChatTabOptimistically();
    }
    setState(() {
      if (updateSearchCategory) {
        _searchInitialCategory = searchCategory;
      }
      _searchChromeVisible = true;
      _currentIndex = index;
      if (pillSlot != null) {
        _lastPillSlot = pillSlot;
      }
    });
    _syncTabRoute(index);
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;

    final pages = [
      HomeScreen(
        onOpenSearch: (catId) {
          if (catId != null) {
            _state.recordCategoryInterest(catId, weight: 3);
          }
          _triggerSquashStretch();
          _switchTab(
            2,
            pillSlot: 1,
            updateSearchCategory: true,
            searchCategory: catId,
          );
        },
        onOpenPostAd: () {
          _triggerSquashStretch();
          _switchTab(1);
        },
      ),
      PostAdScreen(
        key: ValueKey('post-ad-${_state.currentUser?['id'] ?? 'guest'}'),
        onSuccess: () {
          _triggerSquashStretch();
          _switchTab(0, pillSlot: 0);
        },
      ),
      SearchScreen(
        key: ValueKey(_searchInitialCategory),
        initialCategoryId: _searchInitialCategory,
        onChromeVisibilityChanged: _handleSearchChromeVisibility,
      ),
      ChatListScreen(
        onExploreAds: () {
          _triggerSquashStretch();
          _switchTab(2, pillSlot: 1);
        },
      ),
      const ProfileScreen(),
    ];

    final pillItems = [
      _TabSpec(
        pageIndex: 0,
        icon: CupertinoIcons.house,
        activeIcon: CupertinoIcons.house_fill,
        label: s.tr('الرئيسية', 'Accueil', appL10n.navHome),
      ),
      _TabSpec(
        pageIndex: 2,
        icon: CupertinoIcons.compass,
        activeIcon: CupertinoIcons.compass_fill,
        label: s.tr('إعلانات', 'Annonces', appL10n.mainShellBrowse),
      ),
      _TabSpec(
        pageIndex: 3,
        icon: CupertinoIcons.chat_bubble_2,
        activeIcon: CupertinoIcons.chat_bubble_2_fill,
        label: s.tr('رسائل', 'Messages', appL10n.navMessages),
      ),
      _TabSpec(
        pageIndex: 4,
        icon: CupertinoIcons.person,
        activeIcon: CupertinoIcons.person_fill,
        label: s.tr('حسابي', 'Profil', appL10n.navProfile),
      ),
    ];

    final activePillSlot =
        pillItems.indexWhere((e) => e.pageIndex == _currentIndex);
    final displaySlot = activePillSlot >= 0 ? activePillSlot : _lastPillSlot;
    final showBottomBar = _currentIndex != 2 || _searchChromeVisible;
    final isPostAdSelected = _currentIndex == 1;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final double dockBottomOffset = math.max(40.0, safeBottom + 14.0);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color shellBg = isDark ? const Color(0xFF0A0A0A) : Colors.white;
    final Color dockGlassBg =
        (isDark ? const Color(0xFF161618) : Colors.white).withValues(alpha: 0.92);
    final Color dockBorder =
        isDark ? const Color(0xFF2E2E34) : const Color(0xFFEEEEEE);
    final Color dockInk = isDark ? Colors.white : _ink;
    final Color dockOnInk = isDark ? const Color(0xFF0A0A0A) : Colors.white;
    final Color dockInactive = isDark ? const Color(0xFF8E8E93) : _inactive;
    final Color dockActivePill =
        isDark ? const Color(0xFF28282E) : _activePill;

    return Scaffold(
      backgroundColor: shellBg,
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: [
              for (var i = 0; i < pages.length; i++)
                TickerMode(enabled: _currentIndex == i, child: pages[i])
            ],
          ),
          // Responsive Floating Translucent Pill Dock + Borderless "+" Button with Squash & Stretch
          Positioned(
            key: const Key('main-shell-bottom-dock'),
            left: 20,
            right: 20,
            bottom: dockBottomOffset,
            child: IgnorePointer(
              ignoring: !showBottomBar,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 300),
                curve: const Cubic(0.22, 1.0, 0.36, 1.0),
                offset: showBottomBar ? Offset.zero : const Offset(0, 1.8),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  opacity: showBottomBar ? 1.0 : 0.0,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: SizedBox(
                        height: 58,
                        child: Row(
                          textDirection: TextDirection.ltr,
                          children: [
                            // Left Expanded Dynamic Layer Capsule Pill (4 main tabs)
                            Expanded(
                              child: Container(
                                height: 58,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: dockBorder,
                                    width: 1.5,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 20, sigmaY: 20),
                                    child: Container(
                                      padding: const EdgeInsets.all(4.5),
                                      decoration: BoxDecoration(
                                        color: dockGlassBg,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          final slotWidth =
                                              constraints.maxWidth /
                                                  pillItems.length;
                                          final slotHeight =
                                              constraints.maxHeight;
                                          return Stack(
                                            children: [
                                              AnimatedPositioned(
                                                duration: const Duration(
                                                    milliseconds: 320),
                                                curve: const Cubic(
                                                    0.22, 1.0, 0.36, 1.0),
                                                left: slotWidth * displaySlot,
                                                top: 0,
                                                width: slotWidth,
                                                height: slotHeight,
                                                child: AnimatedBuilder(
                                                  animation: _squashCtrl,
                                                  builder: (context, child) {
                                                    final sx =
                                                        _squashCtrl.isAnimating
                                                            ? _pillScaleX.value
                                                            : 1.0;
                                                    final sy =
                                                        _squashCtrl.isAnimating
                                                            ? _pillScaleY.value
                                                            : 1.0;
                                                    return Transform(
                                                      alignment:
                                                          Alignment.center,
                                                      transform: Matrix4
                                                          .diagonal3Values(
                                                              sx, sy, 1.0),
                                                      child: child,
                                                    );
                                                  },
                                                  child: AnimatedContainer(
                                                    duration: const Duration(
                                                        milliseconds: 180),
                                                    decoration: BoxDecoration(
                                                      color: activePillSlot >= 0
                                                          ? dockActivePill
                                                              .withValues(
                                                                  alpha: 0.90)
                                                          : Colors.transparent,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              999),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Row(
                                                textDirection:
                                                    TextDirection.ltr,
                                                children: List.generate(
                                                  pillItems.length,
                                                  (idx) {
                                                    final item = pillItems[idx];
                                                    final selected =
                                                        _currentIndex ==
                                                            item.pageIndex;
                                                    return Expanded(
                                                      child: PressableScale(
                                                        pressedScale: 0.90,
                                                        onTap: () {
                                                          HapticFeedback
                                                              .selectionClick();
                                                          _triggerSquashStretch();
                                                          if (_currentIndex ==
                                                              item.pageIndex) {
                                                            _state
                                                                .notifyTabReselected();
                                                          } else {
                                                            _switchTab(
                                                              item.pageIndex,
                                                              pillSlot: idx,
                                                            );
                                                          }
                                                        },
                                                        child: ConstrainedBox(
                                                          constraints:
                                                              const BoxConstraints(
                                                            minWidth: 44,
                                                            minHeight: 44,
                                                          ),
                                                          child: Semantics(
                                                            button: true,
                                                            selected: selected,
                                                            label: item.label,
                                                            child: SizedBox(
                                                              height:
                                                                  slotHeight,
                                                              child: Center(
                                                                child:
                                                                    AnimatedScale(
                                                                  scale: selected
                                                                      ? 1.06
                                                                      : 1.0,
                                                                  duration:
                                                                      const Duration(
                                                                          milliseconds:
                                                                              220),
                                                                  curve: const Cubic(
                                                                      0.22,
                                                                      1.0,
                                                                      0.36,
                                                                      1.0),
                                                                  child: NotificationBadge(
                                                                    count: item.pageIndex == 3
                                                                        ? _state.unreadChatCount
                                                                        : 0,
                                                                    type: NotificationBadgeType.number,
                                                                    variant: NotificationBadgeVariant.red,
                                                                    top: -6,
                                                                    right: -9,
                                                                    child: Icon(
                                                                      selected
                                                                          ? item.activeIcon
                                                                          : item.icon,
                                                                      size: 22.5,
                                                                      color: selected
                                                                          ? dockInk
                                                                          : dockInactive,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Right Detached Borderless Circular Glass "+" Button (Post Ad)
                            PressableScale(
                              pressedScale: 0.88,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _triggerSquashStretch();
                                if (_currentIndex == 1) {
                                  _state.notifyTabReselected();
                                } else {
                                  _switchTab(1);
                                }
                              },
                              child: Semantics(
                                button: true,
                                selected: isPostAdSelected,
                                label: s.tr('نشر إعلان', 'Publier', appL10n.sellItemButton),
                                child: AnimatedBuilder(
                                  animation: _squashCtrl,
                                  builder: (context, child) {
                                    final active = isPostAdSelected &&
                                        _squashCtrl.isAnimating;
                                    final sx =
                                        active ? _pillScaleX.value : 1.0;
                                    final sy =
                                        active ? _pillScaleY.value : 1.0;
                                    return Transform(
                                      alignment: Alignment.center,
                                      transform:
                                          Matrix4.diagonal3Values(sx, sy, 1.0),
                                      child: child,
                                    );
                                  },
                                  child: Container(
                                    width: 58,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isPostAdSelected
                                            ? dockInk
                                            : dockBorder,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                            sigmaX: 20, sigmaY: 20),
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 220),
                                          curve: Curves.easeOutCubic,
                                          decoration: BoxDecoration(
                                            color: isPostAdSelected
                                                ? dockInk
                                                : dockGlassBg,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Icon(
                                            CupertinoIcons.add,
                                            size: 24,
                                            color: isPostAdSelected
                                                ? dockOnInk
                                                : dockInk,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabSpec {
  final int pageIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _TabSpec({
    required this.pageIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
