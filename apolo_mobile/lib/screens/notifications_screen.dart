import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import '../core/services/media_rtc_bridge.dart';
import '../core/state/app_state.dart';
import '../theme/dl_share_profile_tokens.dart';
import '../widgets/dl_settings_kit.dart';
import '../widgets/notification_badge.dart';
import '../widgets/pull_to_refresh.dart';
import 'ad_detail_screen.dart';
import 'chat_room_screen.dart';
import 'post_ad_screen.dart';
import 'search_screen.dart';
import 'stores_screen.dart';
import 'widgets/app_image.dart';
import 'widgets/chat_utils.dart';
import 'widgets/kinetic_widgets.dart';
import 'widgets/skeleton_loader.dart';

/// Dynamic Layer v5.1 Two-Stage Notification Flow:
/// 1. **Stage 1 — `Notification / Default` (`45849:25601`)**:
///    Shown whenever notifications are NOT verified active (`Notification.permission != 'granted'`).
///    Renders the `330 × 240 px` `# notification-img` illustration + `56px` black pill `Continue` CTA.
///    On tap, requests & verifies real notification permission (`MediaRtcBridge.requestNotificationPermissionWithResult()`):
///    - Only if verified active (`granted` or verified in-app fallback on unsupported WebKit tabs)
///      does it transition to Stage 2.
///    - If `denied`, displays a clear Dynamic Layer sheet instructing the user how to enable permissions.
/// 2. **Stage 2 — `Notifications` Feed (`47390:2792`)**:
///    Exact Figma `Main Container` (`padding: 32px top/bottom, 16px left/right`, `1px` `#EEEEEE` header separator),
///    grouped into **`Today` (`اليوم`)** and **`This week` (`هذا الأسبوع`)** (`32px` section gap, `16px` header-to-row gap,
///    `20px` row gap), `44×44` circular avatars with `18×18` mini category badges, and inline `14px/20px`
///    `Bold + Regular + Bold + muted time` copy tailored to **Apolo.ma**.
class NotificationsScreen extends StatefulWidget {
  final bool initialSimulateOffline;
  const NotificationsScreen({super.key, this.initialSimulateOffline = false});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const String _prefActivatedKey = 'apolo_notifications_activated_v1';

  final AppState _state = AppState();
  late bool _isOffline;
  bool _isLoading = true;
  bool _isReconnecting = false;
  bool _prefsActivated = false;
  bool _prefsLoaded = false;
  bool _isActivating = false;
  String _permissionStatus = 'unsupported';

  List<Map<String, dynamic>> _items = [];

  static const Color _bg = Color(0xFFFFFFFF);
  static const Color _cardBg = Color(0xFFF7F7F7);
  static const Color _ink = Color(0xFF000000);
  static const Color _bodyInk = Color(0xFF525252);
  static const Color _red = Color(0xFFE31B23);
  static const Color _violet = Color(0xFF7C3AED);
  static const Color _blue = Color(0xFF0866FF);
  static const Color _pillGrey = Color(0xFFEEEEEE);
  static const Color _muted = Color(0xFF757575);
  static const Color _timeMuted = Color(0xFF9E9E9E);
  static const Color _divider = Color(0xFFEEEEEE);

  @override
  void initState() {
    super.initState();
    _isOffline = widget.initialSimulateOffline;
    _permissionStatus = MediaRtcBridge.getNotificationPermissionStatus();
    // Rule 5: Clear badge immediately on screen open without waiting for API.
    _state.clearUnreadNotificationsOptimistically(syncRemote: false);
    _state.addListener(_onStateChanged);
    _loadActivationState();
    _loadNotifications();
  }

  /// Verifies whether notifications are genuinely active on this device/browser:
  /// - When browser `Notification` API is available (`granted` / `denied` / `default`),
  ///   strictly requires `_permissionStatus == 'granted'`.
  /// - When `Notification` API is `'unsupported'` (e.g. iOS Chrome/Safari non-PWA tab or test stub),
  ///   uses verified Apolo activation state (`_prefsActivated || _items.isNotEmpty`).
  bool get _isNotificationsTrulyActive {
    final liveStatus = MediaRtcBridge.getNotificationPermissionStatus();
    final effectiveStatus =
        liveStatus != 'unsupported' ? liveStatus : _permissionStatus;
    if (effectiveStatus == 'granted') return true;
    if (effectiveStatus == 'denied' || effectiveStatus == 'default') {
      return false;
    }
    return _prefsActivated || _items.isNotEmpty;
  }

  Future<void> _loadActivationState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool(_prefActivatedKey) ?? false;
      final liveStatus = MediaRtcBridge.getNotificationPermissionStatus();
      if (mounted) {
        setState(() {
          _prefsActivated = saved;
          _permissionStatus = liveStatus;
          _prefsLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _prefsLoaded = true);
      }
    }
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    super.dispose();
  }

  Future<void> _showBlockedPermissionSheet() async {
    final s = _state.s;
    final palette = ApoloDlPalette.of(context);
    await showApoloDlBottomSheet<void>(
      context,
      headerTitle: s.tr(
        'تفعيل الإشعارات',
        'Activer les notifications',
        'Enable notifications',
      ),
      media: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: palette.dangerSoft,
          shape: BoxShape.circle,
        ),
        child: Icon(
          CupertinoIcons.bell_slash_fill,
          size: 26,
          color: palette.danger,
        ),
      ),
      contentTitle: s.tr(
        'الإشعارات غير مفعّلة في المتصفح',
        'Notifications bloquées par le navigateur',
        'Notifications are blocked',
      ),
      contentDescription: s.tr(
        'يرجى السماح بالإشعارات من أيقونة القفل/الإعدادات بجانب رابط الموقع في المتصفح ثم الضغط على "متابعة" مرة أخرى.',
        'Autorisez les notifications depuis l’icône cadenas/réglages de votre navigateur puis appuyez à nouveau sur Continuer.',
        'Please allow notifications in your browser or device settings, then tap Continue again.',
      ),
      actions: [
        ApoloDlButton(
          key: const Key('dl-notification-blocked-dismiss'),
          label: s.tr('حسناً، فهمت', 'Compris', 'Got it'),
          variant: ApoloDlButtonVariant.primary,
          borderRadius: 999,
          fullWidth: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Future<void> _activateAndVerifyNotifications() async {
    if (_isActivating) return;
    HapticFeedback.mediumImpact();
    setState(() => _isActivating = true);

    String status = 'unsupported';
    try {
      status = await MediaRtcBridge.requestNotificationPermissionWithResult();
    } catch (_) {
      status = MediaRtcBridge.getNotificationPermissionStatus();
    }

    if (!mounted) return;

    // Strictly verify permission result before navigating to the Notifications feed
    if (status == 'denied') {
      setState(() {
        _permissionStatus = 'denied';
        _isActivating = false;
      });
      await _showBlockedPermissionSheet();
      return;
    }

    if (status == 'default') {
      setState(() {
        _permissionStatus = 'default';
        _isActivating = false;
      });
      final s = _state.s;
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: _ink,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            duration: const Duration(seconds: 2),
            content: Text(
              s.tr(
                'يرجى الضغط على "سماح / Allow" لتفعيل الإشعارات',
                'Veuillez appuyer sur « Autoriser » pour activer les alertes',
                'Please allow notifications to continue',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      return;
    }

    // Verified active (`status == 'granted'` or verified in-app fallback `'unsupported'`)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefActivatedKey, true);
      MediaRtcBridge.playNotificationSound();
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _permissionStatus = status;
      _prefsActivated = true;
      _isActivating = false;
    });

    if (_state.isLoggedIn) {
      await _loadNotifications();
    }
  }

  Future<void> _loadNotifications() async {
    if (_isOffline) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    if (!_state.isLoggedIn) {
      if (!mounted) return;
      setState(() {
        _items = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await _state.api.dio.get('/notifications');
      if (!mounted) return;
      if (res.data is Map && res.data['status'] == 'success') {
        final list = (res.data['notifications'] ?? res.data['data'] ?? [])
            as List<dynamic>;
        final parsed = list
            .whereType<Map>()
            .map((e) => _normalizeNotification(Map<String, dynamic>.from(e)))
            .toList();
        setState(() {
          _items = parsed;
          _isLoading = false;
          _isOffline = false;
        });
        if (parsed.any((e) => e['unread'] == true)) {
          unawaited(
            _state.api.dio
                .post('/notifications/read-all')
                .then<void>((_) {}, onError: (_) {}),
          );
        }
        return;
      }
      setState(() {
        _items = [];
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _normalizeNotification(Map<String, dynamic> raw) {
    final type =
        (raw['type'] ?? raw['category'] ?? '').toString().toLowerCase();
    int category = 2; // Activity / Listing update
    String badgeKind = 'update';
    if (type.contains('offer') ||
        type.contains('order') ||
        type.contains('approved') ||
        type.contains('عرض') ||
        type.contains('طلب')) {
      category = 1;
      badgeKind = 'offer';
    } else if (type.contains('chat') ||
        type.contains('message') ||
        type.contains('comment') ||
        type.contains('reply') ||
        type.contains('رسال') ||
        type.contains('رد')) {
      category = 1;
      badgeKind = 'chat';
    }

    final timeStr =
        (raw['created_at_human'] ?? raw['time'] ?? '').toString().trim();
    final createdRaw = (raw['created_at'] ?? '').toString().trim();
    final parsedDt = createdRaw.isNotEmpty ? DateTime.tryParse(createdRaw) : null;
    bool isToday = true;
    if (parsedDt != null) {
      final now = DateTime.now();
      final local = parsedDt.toLocal();
      isToday = now.year == local.year &&
          now.month == local.month &&
          now.day == local.day;
    } else if (timeStr.isNotEmpty) {
      final lower = timeStr.toLowerCase();
      if (lower.contains('day') ||
          lower.contains('week') ||
          lower.contains('aug') ||
          lower.contains('jul') ||
          lower.contains('sep') ||
          lower.contains('أمس') ||
          lower.contains('أيام') ||
          lower.contains('أسبوع') ||
          lower.contains('hier') ||
          lower.contains('jour')) {
        isToday = false;
      }
    }

    return {
      'id': raw['id'] ?? DateTime.now().millisecondsSinceEpoch,
      'category': category,
      'badge_kind': badgeKind,
      'bucket': isToday ? 'today' : 'week',
      'actionable': AppState.isActionableNotification(raw),
      'unread': raw['is_read'] != true && raw['read_at'] == null,
      'title':
          (raw['title'] ?? raw['data']?['title'] ?? 'إشعار جديد').toString(),
      'body': (raw['body'] ?? raw['message'] ?? raw['data']?['message'] ?? '')
          .toString(),
      'time': timeStr.isNotEmpty ? timeStr : '4h',
      'avatar_url': (raw['sender_avatar'] ??
              raw['avatar'] ??
              raw['data']?['sender_avatar'] ??
              raw['ad_image'] ??
              '')
          .toString()
          .trim(),
      'ad_id': raw['ad_id'] ?? raw['data']?['ad_id'],
      'conversation_id':
          raw['conversation_id'] ?? raw['data']?['conversation_id'],
      'sender_id': raw['sender_id'] ??
          raw['data']?['sender_id'] ??
          raw['from_user_id'] ??
          raw['data']?['from_user_id'],
      'sender_name':
          (raw['sender_name'] ?? raw['data']?['sender_name'] ?? '').toString(),
      'firestore_doc_id':
          raw['firestore_doc_id'] ?? raw['data']?['firestore_doc_id'],
    };
  }

  /// Apolo-tailored notifications matching Figma `47390:2792` (`Today` + `This week`)
  /// shown on the verified `Notifications` screen when the user has 0 server items yet.
  List<Map<String, dynamic>> _buildApoloShowcaseItems(AppStrings s) {
    return <Map<String, dynamic>>[
      {
        'id': 'apolo_welcome_live',
        'bucket': 'today',
        'badge_kind': 'offer',
        'actionable': false,
        'unread': false,
        'avatar_initial': 'A',
        'nav_target': 'explore',
        'spans': <Map<String, dynamic>>[
          {
            'text': s.tr('أنت', 'Vous', 'You'),
            'bold': true,
          },
          {
            'text': s.tr(
              ' قمت بتفعيل التنبيهات الفورية لـ ',
              ' avez activé les alertes en direct sur ',
              ' activated instant alerts for ',
            ),
            'bold': false,
          },
          {
            'text': s.tr(
              'Apolo.ma — الرسائل والعروض',
              'Apolo.ma — Messages & Offres',
              'Apolo.ma — Buyer Messages & Offers',
            ),
            'bold': true,
          },
        ],
        'time': s.tr('الآن', 'maintenant', 'just now'),
      },
      {
        'id': 'apolo_seller_tip',
        'bucket': 'today',
        'badge_kind': 'chat',
        'actionable': false,
        'unread': false,
        'avatar_initial': 'M',
        'nav_target': 'post_ad',
        'spans': <Map<String, dynamic>>[
          {
            'text': s.tr('فريق Apolo', 'Équipe Apolo', 'Apolo Team'),
            'bold': true,
          },
          {
            'text': s.tr(
              ' شارك معك نصيحة: أضف صوراً واضحة وثمناً مناسباً لبيع إعلانك بسرعة! 🔥',
              ' : Ajoutez des photos nettes à votre annonce pour vendre plus vite ! 🔥',
              ' shared a tip: Add clear photos to your listing to close deals faster! 🔥',
            ),
            'bold': false,
          },
        ],
        'time': s.tr('اليوم', "Aujourd'hui", '2h ago'),
      },
      {
        'id': 'apolo_stores_weekly',
        'bucket': 'week',
        'badge_kind': 'update',
        'actionable': false,
        'unread': false,
        'avatar_initial': 'S',
        'nav_target': 'stores',
        'spans': <Map<String, dynamic>>[
          {
            'text': s.tr(
              'متاجر Apolo الرسمية',
              'Boutiques Apolo PRO',
              'Apolo Official Stores',
            ),
            'bold': true,
          },
          {
            'text': s.tr(
              ' قامت بتحديث ',
              ' a mis à jour ',
              ' updated ',
            ),
            'bold': false,
          },
          {
            'text': s.tr(
              'عروض السيارات، العقارات والإلكترونيات الموثقة',
              'les annonces vérifiées Auto, Immo & Tech',
              'Verified Cars, Real Estate & Tech Listings',
            ),
            'bold': true,
          },
          {
            'text': s.tr(
              ' في جميع مدن المغرب.',
              ' dans toutes les villes du Maroc.',
              ' across all Moroccan cities.',
            ),
            'bold': false,
          },
        ],
        'time': s.tr('هذا الأسبوع', 'Cette semaine', 'This week'),
      },
    ];
  }

  void _updateUnreadBadge() {
    _state.setUnreadNotificationsCount(0);
  }

  Future<void> _markAllRead() async {
    HapticFeedback.mediumImpact();
    setState(() {
      for (final item in _items) {
        item['unread'] = false;
      }
    });
    _updateUnreadBadge();
    try {
      await _state.api.dio.post('/notifications/read-all');
    } catch (_) {}
  }

  void _openNotification(Map<String, dynamic> item) {
    HapticFeedback.selectionClick();

    final String navTarget = (item['nav_target'] ?? '').toString();
    if (navTarget == 'explore') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SearchScreen()),
      );
      return;
    }
    if (navTarget == 'post_ad') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PostAdScreen()),
      );
      return;
    }
    if (navTarget == 'stores') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StoresScreen()),
      );
      return;
    }

    setState(() => item['unread'] = false);
    _updateUnreadBadge();

    final int? adId = int.tryParse('${item['ad_id'] ?? ''}');
    final int? convId = int.tryParse('${item['conversation_id'] ?? ''}');
    final int? senderId = int.tryParse('${item['sender_id'] ?? ''}');
    final String senderName = (item['sender_name'] ?? '').toString().trim();
    final String? firestoreDocId = item['firestore_doc_id']?.toString();
    final bool isChatNotif = item['category'] == 1;

    if ((convId != null && convId > 0) ||
        (isChatNotif && senderId != null && senderId > 0)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            conversationId: convId ?? senderId!,
            backendConversationId:
                (convId != null && convId > 0) ? convId : null,
            adId: adId,
            peerId: senderId,
            firestoreDocId: firestoreDocId,
            peerName: senderName.isNotEmpty
                ? senderName
                : (item['title'] ?? 'Apolo').toString(),
            adTitle: '',
          ),
        ),
      );
    } else if (adId != null && adId > 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdDetailScreen(
            adId: adId,
            openChatOnLoad: isChatNotif,
          ),
        ),
      );
    }

    try {
      final notifId = item['id'];
      if (notifId != null) {
        _state.api.dio.post('/notifications/$notifId/read');
      }
    } catch (_) {}
  }

  Future<void> _retryConnection() async {
    setState(() => _isReconnecting = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _isReconnecting = false;
      _isOffline = false;
    });
    await _loadNotifications();
  }

  /// Dynamic Layer `TopNavigation` (`height: topInset + 56px`):
  /// - Stage 1 (`showFeedHeader == false`): `40×40` circular `#EEEEEE` back button only, no separator
  /// - Stage 2 (`showFeedHeader == true`, Figma `47390:2792`): `40×40` `#EEEEEE` back button +
  ///   centered `16px Bold` `Notifications` title + `1px` `#EEEEEE` bottom separator (`y = 104px`).
  Widget _buildDlTopBar({
    required bool isAr,
    required bool showFeedHeader,
  }) {
    final s = _state.s;
    final topInset = MediaQuery.paddingOf(context).top;
    final backIcon =
        isAr ? CupertinoIcons.chevron_right : CupertinoIcons.chevron_left;
    final hasUnread = !_isOffline &&
        _state.isLoggedIn &&
        _items.any((e) => e['unread'] == true);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          key: const Key('dl-notification-top-nav'),
          height: topInset + DlShareProfileLayout.topNavHeight,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: DlShareProfileLayout.topNavHeight,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DlShareProfileLayout.topNavHorizontalPadding,
                ),
                child: Row(
                  children: [
                    ApoloDlIconCircleButton(
                      key: const Key('dl-notification-back-button'),
                      icon: backIcon,
                      backgroundColor: _pillGrey,
                      iconColor: _ink,
                      tooltip:
                          MaterialLocalizations.of(context).backButtonTooltip,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: showFeedHeader
                          ? Text(
                              s.tr('الإشعارات', 'Notifications',
                                  'Notifications'),
                              key: const Key('dl-notifications-header-title'),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 16.0,
                                fontWeight: FontWeight.w700,
                                height: 24.0 / 16.0,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(width: 16),
                    if (showFeedHeader && hasUnread)
                      ApoloDlIconCircleButton(
                        key: const Key('dl-notification-mark-all-read'),
                        icon: CupertinoIcons.checkmark_alt,
                        backgroundColor: _pillGrey,
                        iconColor: _ink,
                        tooltip: s.tr(
                          'تحديد الكل كمقروء',
                          'Tout marquer comme lu',
                          'Mark all as read',
                        ),
                        onPressed: _markAllRead,
                      )
                    else if (kDebugMode && showFeedHeader)
                      ApoloDlIconCircleButton(
                        icon: _isOffline
                            ? CupertinoIcons.wifi_slash
                            : CupertinoIcons.wifi,
                        backgroundColor:
                            _isOffline ? const Color(0xFFFEF2F2) : _pillGrey,
                        iconColor: _isOffline ? _red : _muted,
                        onPressed: () {
                          setState(() => _isOffline = !_isOffline);
                          if (!_isOffline) _loadNotifications();
                        },
                      )
                    else
                      const SizedBox(width: 40, height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showFeedHeader)
          const SizedBox(
            key: Key('dl-notifications-header-separator'),
            width: double.infinity,
            height: 1.0,
            child: ColoredBox(color: _divider),
          ),
      ],
    );
  }

  /// Stage 1 Hero Illustration (`# notification-img`, `330 × 240 px`).
  Widget _buildDlNotificationIllustration(bool isAr) {
    final s = _state.s;
    final previewTitle = s.tr(
      'مرحباً، معك Apolo!',
      'Bonjour, c’est Apolo !',
      "Hey, it's Apolo!",
    );
    final previewBody = s.tr(
      'أنا جاهز لتنبيهك فور وصول رسائل وعروض المشترين. ماذا عنك؟',
      'Je suis prêt à vous alerter dès qu’un message arrive. Et vous ?',
      'I am ready to help you out. How about you?',
    );
    final nowLabel = s.tr('الآن', 'maintenant', 'now');

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 330.0),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            key: const Key('dl-notification-img'),
            width: 330.0,
            height: 240.0,
            child: Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 206.0,
                  height: 240.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(34.0),
                    ),
                    border: Border.all(
                      color: const Color(0xFFE4E4E4),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4D4D4),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 52,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _bg.withValues(alpha: 0.0),
                            _bg.withValues(alpha: 0.86),
                            _bg,
                          ],
                          stops: const [0.0, 0.65, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 76.0,
                  left: 0,
                  right: 0,
                  child: Container(
                    key: const Key('dl-notification-preview-card'),
                    constraints: const BoxConstraints(minHeight: 96.0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 16.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                        color: const Color(0xFFEBEBEB),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.055),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 44.0,
                          height: 44.0,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E5E5),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      previewTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: _ink,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        height: 1.25,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    nowLabel,
                                    style: const TextStyle(
                                      color: _muted,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w400,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3.0),
                              Text(
                                previewBody,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF4B5563),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w400,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Stage 1: Exact Figma `Notification / Default` (`45849:25601`) activation gate.
  Widget _buildDlDefaultActivationLayout({
    required bool isAr,
    required Size screenSize,
    required EdgeInsets mediaPadding,
  }) {
    final s = _state.s;
    final bottomSafe =
        DlShareProfileLayout.resolveBottomSafeInset(screenSize, mediaPadding);
    final bottomDockPad = math.max(20.0, bottomSafe + 8.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableH = constraints.maxHeight;
        final topIllustrationGap =
            ((availableH - 460.0) * 0.40).clamp(20.0, 101.0);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: availableH),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: topIllustrationGap),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22.5),
                    child: _buildDlNotificationIllustration(isAr),
                  ),
                  const Spacer(),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          s.tr('الإشعارات', 'Notifications', 'Notification'),
                          key: const Key('dl-notification-title'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 24.0,
                            fontWeight: FontWeight.w700,
                            height: 32.0 / 24.0,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 280.0),
                          child: Text(
                            s.tr(
                              'فعّل الإشعارات للتوصل بالرسائل',
                              'Activez les notifications pour recevoir des messages',
                              'Activate notifications to receive messages',
                            ),
                            key: const Key('dl-notification-subtitle'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w400,
                              height: 22.0 / 15.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28.0),
                  Padding(
                    key: const Key('dl-notification-button-dock'),
                    padding: EdgeInsets.fromLTRB(16.0, 0, 16.0, bottomDockPad),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56.0,
                          child: Material(
                            color: _ink,
                            shape: const StadiumBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              key: const Key('dl-notification-continue-button'),
                              customBorder: const StadiumBorder(),
                              onTap: _isActivating
                                  ? null
                                  : _activateAndVerifyNotifications,
                              child: Center(
                                child: Text(
                                  s.tr('متابعة', 'Continuer', 'Continue'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w600,
                                    height: 24.0 / 16.0,
                                  ),
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
        );
      },
    );
  }

  /// Builds the `44 × 44 px` circular avatar + `18 × 18 px` overlapping bottom-end
  /// category badge matching Figma `47390:2792`.
  Widget _buildDlAvatarWithMiniBadge(Map<String, dynamic> item) {
    final bool unread = item['unread'] == true;
    final bool showActionBadge = unread && (item['actionable'] == true);
    final String badgeKind = (item['badge_kind'] ?? 'update').toString();
    final String avatarUrl = (item['avatar_url'] ?? '').toString().trim();
    final String senderName = (item['sender_name'] ??
            item['avatar_initial'] ??
            item['title'] ??
            'A')
        .toString()
        .trim();

    final Color miniBadgeColor;
    final IconData miniBadgeIcon;
    switch (badgeKind) {
      case 'offer':
        miniBadgeColor = _red;
        miniBadgeIcon = CupertinoIcons.tag_fill;
        break;
      case 'chat':
        miniBadgeColor = _violet;
        miniBadgeIcon = CupertinoIcons.chat_bubble_fill;
        break;
      default:
        miniBadgeColor = _blue;
        miniBadgeIcon = CupertinoIcons.sparkles;
        break;
    }

    Widget avatarCircle;
    if (avatarUrl.isNotEmpty) {
      avatarCircle = ClipOval(
        child: SizedBox(
          width: 44.0,
          height: 44.0,
          child: AppImage(
            url: avatarUrl,
            width: 44.0,
            height: 44.0,
            fit: BoxFit.cover,
            fallback: ChatInitialAvatar(name: senderName, size: 44.0),
          ),
        ),
      );
    } else {
      avatarCircle = ClipOval(
        child: ChatInitialAvatar(name: senderName, size: 44.0),
      );
    }

    return NotificationBadge(
      count: showActionBadge ? 1 : 0,
      type: NotificationBadgeType.dot,
      variant: NotificationBadgeVariant.red,
      top: 0,
      right: 0,
      child: SizedBox(
        width: 44.0,
        height: 44.0,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            avatarCircle,
            PositionedDirectional(
              bottom: -1.0,
              end: -2.0,
              child: Container(
                width: 18.0,
                height: 18.0,
                decoration: BoxDecoration(
                  color: miniBadgeColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Icon(
                  miniBadgeIcon,
                  size: 9.5,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Single row inside Figma `47390:2792` `Main Container`:
  /// `44×44` avatar + `14px` gap + `14px / 20px` Dynamic Layer inline rich text + muted timestamp.
  Widget _buildDlFeedItemRow(Map<String, dynamic> item) {
    final spansRaw = item['spans'];
    final String time = (item['time'] ?? '').toString().trim();

    Widget textColumn;
    if (spansRaw is List && spansRaw.isNotEmpty) {
      final textSpans = <InlineSpan>[];
      for (final part in spansRaw) {
        if (part is Map) {
          final isBold = part['bold'] == true;
          textSpans.add(
            TextSpan(
              text: (part['text'] ?? '').toString(),
              style: TextStyle(
                color: isBold ? _ink : _bodyInk,
                fontSize: 14.0,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
                height: 20.0 / 14.0,
              ),
            ),
          );
        }
      }
      if (time.isNotEmpty) {
        textSpans.add(
          TextSpan(
            text: '  $time',
            style: const TextStyle(
              color: _timeMuted,
              fontSize: 13.0,
              fontWeight: FontWeight.w400,
              height: 20.0 / 13.0,
            ),
          ),
        );
      }
      textColumn = Text.rich(TextSpan(children: textSpans));
    } else {
      final String title = (item['title'] ?? '').toString().trim();
      final String body = (item['body'] ?? '').toString().trim();
      textColumn = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title.isNotEmpty)
            Text(
              title,
              style: const TextStyle(
                color: _ink,
                fontSize: 14.0,
                fontWeight: FontWeight.w700,
                height: 20.0 / 14.0,
              ),
            ),
          if (body.isNotEmpty || time.isNotEmpty) ...[
            if (title.isNotEmpty) const SizedBox(height: 1.5),
            Text.rich(
              TextSpan(
                children: [
                  if (body.isNotEmpty)
                    TextSpan(
                      text: body,
                      style: const TextStyle(
                        color: _bodyInk,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w400,
                        height: 20.0 / 14.0,
                      ),
                    ),
                  if (time.isNotEmpty)
                    TextSpan(
                      text: body.isNotEmpty ? '  $time' : time,
                      style: const TextStyle(
                        color: _timeMuted,
                        fontSize: 13.0,
                        fontWeight: FontWeight.w400,
                        height: 20.0 / 13.0,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      );
    }

    final bool isServerItem = item['spans'] == null;
    final rowBody = InkWell(
      key: Key('dl-notification-row-${item['id']}'),
      borderRadius: BorderRadius.circular(12.0),
      onTap: () => _openNotification(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDlAvatarWithMiniBadge(item),
            const SizedBox(width: 14.0),
            Expanded(child: textColumn),
          ],
        ),
      ),
    );

    if (!isServerItem) return rowBody;

    return Dismissible(
      key: ValueKey(item['id']),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        setState(() {
          _items.removeWhere((e) => e['id'] == item['id']);
        });
        _updateUnreadBadge();
      },
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          CupertinoIcons.trash_fill,
          color: _red,
          size: 19,
        ),
      ),
      child: rowBody,
    );
  }

  Widget _buildDlSectionBlock({
    required Key sectionKey,
    required String heading,
    required List<Map<String, dynamic>> rows,
  }) {
    return Column(
      key: sectionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          heading,
          style: const TextStyle(
            color: _ink,
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            height: 24.0 / 18.0,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 16.0),
        for (int i = 0; i < rows.length; i++) ...[
          _buildDlFeedItemRow(rows[i]),
          if (i < rows.length - 1) const SizedBox(height: 20.0),
        ],
      ],
    );
  }

  /// Stage 2: Exact Figma `47390:2792` `Notifications` screen (`Main Container`
  /// with `top: 32px, right: 16px, bottom: 32px, left: 16px`, `Today` & `This week` sections
  /// separated by `32px`).
  Widget _buildVerifiedNotificationsFeed(AppStrings s) {
    if (_isOffline) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: IllustratedStateView(
              assetPath: 'assets/images/state_no_internet.png',
              fallbackIcon: CupertinoIcons.wifi_slash,
              imageSize: 156,
              title: s.tr(
                'لا يوجد اتصال بالإنترنت',
                'Aucune connexion Internet',
                'No Internet connection',
              ),
              subtitle: s.tr(
                'تأكد من اتصالك بشبكة Wi-Fi أو بيانات الهاتف لتحميل آخر الإشعارات والرسائل.',
                'Vérifiez votre connexion Wi-Fi ou mobile pour actualiser vos notifications.',
                'Check your Wi-Fi or mobile data to refresh your notifications.',
              ),
              actionLabel: _isReconnecting
                  ? s.tr('جاري الاتصال...', 'Connexion...', 'Connecting...')
                  : s.tr(
                      'إعادة المحاولة الآن',
                      'Réessayer maintenant',
                      'Try again',
                    ),
              onAction: _retryConnection,
            ),
          ),
        ],
      );
    }

    if (_isLoading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
        children: const [NotificationsSkeleton()],
      );
    }

    final effectiveItems =
        _items.isNotEmpty ? _items : _buildApoloShowcaseItems(s);
    final todayItems =
        effectiveItems.where((e) => e['bucket'] == 'today').toList();
    final weekItems =
        effectiveItems.where((e) => e['bucket'] != 'today').toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480.0),
        child: PullToRefresh(
          brandColor: _ink,
          backgroundColor: _bg,
          onRefresh: _loadNotifications,
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: EdgeInsets.zero,
            children: [
              // Exact Figma `47390:2792` `Main Container` (`Haut: 32px, Droite: 16px, Bas: 32px, Gauche: 16px`)
              Padding(
                key: const Key('dl-notifications-main-container'),
                padding: const EdgeInsets.fromLTRB(16.0, 32.0, 16.0, 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (todayItems.isNotEmpty)
                      _buildDlSectionBlock(
                        sectionKey: const Key('dl-notifications-section-today'),
                        heading: s.tr('اليوم', "Aujourd'hui", 'Today'),
                        rows: todayItems,
                      ),
                    if (todayItems.isNotEmpty && weekItems.isNotEmpty)
                      const SizedBox(height: 32.0),
                    if (weekItems.isNotEmpty)
                      _buildDlSectionBlock(
                        sectionKey: const Key('dl-notifications-section-week'),
                        heading:
                            s.tr('هذا الأسبوع', 'Cette semaine', 'This week'),
                        rows: weekItems,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final isAr = s.isAr;
    final screenSize = MediaQuery.sizeOf(context);
    final mediaPadding = MediaQuery.paddingOf(context);
    final bool isActive = _isNotificationsTrulyActive;
    final bool showActivationGate = !_isOffline && !isActive && (_prefsLoaded || !_isLoading);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        body: Column(
          children: [
            _buildDlTopBar(
              isAr: isAr,
              showFeedHeader: !showActivationGate,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: showActivationGate
                    ? KeyedSubtree(
                        key: const ValueKey<String>('dl-stage-activation'),
                        child: _buildDlDefaultActivationLayout(
                          isAr: isAr,
                          screenSize: screenSize,
                          mediaPadding: mediaPadding,
                        ),
                      )
                    : KeyedSubtree(
                        key: const ValueKey<String>('dl-stage-feed'),
                        child: _buildVerifiedNotificationsFeed(s),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
