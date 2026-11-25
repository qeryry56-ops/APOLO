import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/media_rtc_bridge.dart';
import '../core/state/app_state.dart';
import '../theme/dl_share_profile_tokens.dart';
import '../widgets/dl_settings_kit.dart';
import '../widgets/notification_badge.dart';
import '../widgets/pull_to_refresh.dart';
import 'ad_detail_screen.dart';
import 'chat_room_screen.dart';
import 'widgets/kinetic_widgets.dart';
import 'widgets/skeleton_loader.dart';

/// Dynamic Layer v5.1 Notification Screen (`Notification / Default`, `45849:25601`):
/// - Pure `#FFFFFF` canvas with `56px` top navigation (`40×40` `#EEEEEE` circular back button)
/// - Exact `330 × 240 px` `# notification-img` phone & floating message banner illustration
/// - Bottom-anchored `Notification` heading, subtitle, and `56px` pill `ButtonDock` (`Continue`)
///   that activates real browser/OS notifications (`MediaRtcBridge.requestBrowserNotificationPermission`)
/// - Seamless Dynamic Layer grouped notification feed when `/notifications` items arrive
class NotificationsScreen extends StatefulWidget {
  final bool initialSimulateOffline;
  const NotificationsScreen({super.key, this.initialSimulateOffline = false});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const String _prefActivatedKey = 'apolo_notifications_activated_v1';

  final AppState _state = AppState();
  int _selectedFilter = 0; // 0: All, 1: Messages & Offers, 2: Activity
  late bool _isOffline;
  bool _isLoading = true;
  bool _isReconnecting = false;
  bool _isActivated = false;
  bool _isActivating = false;

  List<Map<String, dynamic>> _items = [];

  static const Color _bg = Color(0xFFFFFFFF);
  static const Color _cardBg = Color(0xFFF7F7F7);
  static const Color _ink = Color(0xFF000000);
  static const Color _red = Color(0xFFE31B23);
  static const Color _pillGrey = Color(0xFFEEEEEE);
  static const Color _muted = Color(0xFF757575);
  static const Color _timeMuted = Color(0xFF8E8E93);
  static const Color _divider = Color(0xFFEEEEEE);

  @override
  void initState() {
    super.initState();
    _isOffline = widget.initialSimulateOffline;
    // Rule 5: Clear badge immediately on screen open without waiting for API.
    _state.clearUnreadNotificationsOptimistically(syncRemote: false);
    _state.addListener(_onStateChanged);
    _loadActivationState();
    _loadNotifications();
  }

  Future<void> _loadActivationState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool(_prefActivatedKey) ?? false;
      if (mounted && saved != _isActivated) {
        setState(() => _isActivated = saved);
      }
    } catch (_) {}
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    super.dispose();
  }

  Future<void> _activateNotifications() async {
    if (_isActivating) return;
    HapticFeedback.mediumImpact();
    setState(() => _isActivating = true);

    try {
      MediaRtcBridge.requestBrowserNotificationPermission();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefActivatedKey, true);
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _isActivated = true;
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
              'تم تفعيل الإشعارات بنجاح',
              'Notifications activées avec succès',
              'Notifications activated',
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
    int category = 2; // Default: Activity
    if (type.contains('chat') ||
        type.contains('message') ||
        type.contains('offer') ||
        type.contains('رسال') ||
        type.contains('عرض')) {
      category = 1;
    }

    return {
      'id': raw['id'] ?? DateTime.now().millisecondsSinceEpoch,
      'category': category,
      'actionable': AppState.isActionableNotification(raw),
      'unread': raw['is_read'] != true && raw['read_at'] == null,
      'title':
          (raw['title'] ?? raw['data']?['title'] ?? 'إشعار جديد').toString(),
      'body': (raw['body'] ?? raw['message'] ?? raw['data']?['message'] ?? '')
          .toString(),
      'time': (raw['created_at_human'] ?? raw['time'] ?? 'منذ قليل').toString(),
      'ad_id': raw['ad_id'] ?? raw['data']?['ad_id'],
      'conversation_id':
          raw['conversation_id'] ?? raw['data']?['conversation_id'],
      'sender_id': raw['sender_id'] ??
          raw['data']?['sender_id'] ??
          raw['from_user_id'] ??
          raw['data']?['from_user_id'],
      'sender_name':
          raw['sender_name'] ?? raw['data']?['sender_name'] ?? '',
      'firestore_doc_id':
          raw['firestore_doc_id'] ?? raw['data']?['firestore_doc_id'],
      'asset': _assetForNotification(raw),
      'accent': category == 1 ? _red : _ink,
    };
  }

  String _assetForNotification(Map<String, dynamic> raw) {
    final title = (raw['title'] ?? '').toString().toLowerCase();
    final body = (raw['body'] ?? '').toString().toLowerCase();
    final combined = '$title $body';
    if (combined.contains('سيار') ||
        combined.contains('auto') ||
        combined.contains('car')) {
      return 'assets/images/hero_car.png';
    }
    if (combined.contains('هاتف') ||
        combined.contains('iphone') ||
        combined.contains('phone')) {
      return 'assets/images/cat_phones.png';
    }
    if (combined.contains('حاسوب') ||
        combined.contains('mac') ||
        combined.contains('pc')) {
      return 'assets/images/cat_computers.png';
    }
    if (combined.contains('عقار') ||
        combined.contains('شقة') ||
        combined.contains('villa')) {
      return 'assets/images/cat_realestate.png';
    }
    return 'assets/images/state_notifications.png';
  }

  void _updateUnreadBadge() {
    _state.setUnreadNotificationsCount(0);
  }

  List<Map<String, dynamic>> get _filteredItems {
    if (_selectedFilter == 0) return _items;
    return _items.where((item) => item['category'] == _selectedFilter).toList();
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
            peerName:
                senderName.isNotEmpty ? senderName : item['title'].toString(),
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

  /// Exact Figma `TopNavigation` (`56px` height, `16px` horizontal padding,
  /// `40×40` circular `#EEEEEE` back button, optional centered title & trailing action
  /// when notification feed items exist).
  Widget _buildDlTopBar({
    required bool isAr,
    required bool hasFeedItems,
  }) {
    final s = _state.s;
    final topInset = MediaQuery.paddingOf(context).top;
    final backIcon =
        isAr ? CupertinoIcons.chevron_right : CupertinoIcons.chevron_left;
    final hasUnread =
        !_isOffline && _state.isLoggedIn && _items.any((e) => e['unread'] == true);

    return SizedBox(
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
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: hasFeedItems
                      ? Text(
                          s.tr('الإشعارات', 'Notifications', 'Notifications'),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.5,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 16),
                if (hasUnread)
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
                else if (kDebugMode && hasFeedItems)
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
    );
  }

  /// Exact Figma `# notification-img` (`330 × 240 px`, `top: 205px`, `left: 23px` on `375×812`):
  /// - Centered rounded matte-grey iOS phone silhouette (`206 × 240 px`) with top speaker pill
  ///   and soft bottom white fade
  /// - Overlapping floating `#FFFFFF` notification banner card (`borderRadius: 16px`, `1px` border,
  ///   `16px` vertical padding, `44×44` rounded icon placeholder, bold title + `"now"` + 2-line preview).
  Widget _buildDlNotificationIllustration(bool isAr) {
    final s = _state.s;
    final previewTitle = s.tr(
      'مرحباً، معك Apolo!',
      'Bonjour, c’est Apolo !',
      "Hey, it's Apolo!",
    );
    final previewBody = s.tr(
      'أنا جاهز لمساعدتك في رسائلك وعروضك الجديدة. ماذا عنك؟',
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
                // Phone top silhouette (`206 × 240 px`)
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

                // Soft bottom fade into white canvas matching Figma `Notification / Default`
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

                // Floating Notification Banner Card (`330 × 96..100 px`, `radius: 16`, `1px` border)
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

  /// Exact Figma `Notification / Default` (`45849:25601`) full-screen layout:
  /// - `# notification-img` (`330 × 240 px`) positioned cleanly in upper-center (`~101px` below TopNav on `812` height)
  /// - Bottom `wrapper` (`Notification` + `Activate notifications to receive messages`)
  /// - Bottom `ButtonDock` (`56px` full-width pill `#000000` `Continue` CTA).
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
        // On a 812px screen (`availableH ≈ 708px` below 104px header), top gap is ~101px (`205 - 104`).
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
                  // `wrapper`: Title + Subtitle above `ButtonDock`
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
                            _isActivated
                                ? s.tr(
                                    'الإشعارات مفعّلة. ستتوصل بالرسائل والعروض فور وصولها',
                                    'Notifications activées. Vous recevrez vos nouveaux messages ici',
                                    'Activate notifications to receive messages',
                                  )
                                : s.tr(
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
                  // `ButtonDock` (`16px` horizontal padding, `56px` black `roundedFull` pill CTA)
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
                              onTap: _isActivating ? null : _activateNotifications,
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

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final isAr = s.isAr;
    final screenSize = MediaQuery.sizeOf(context);
    final mediaPadding = MediaQuery.paddingOf(context);
    final filtered = _filteredItems;
    final unreadItems = filtered.where((e) => e['unread'] == true).toList();
    final readItems = filtered.where((e) => e['unread'] != true).toList();
    final bool showDefaultDlScreen =
        !_isOffline && !_isLoading && _items.isEmpty;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        body: Column(
          children: [
            _buildDlTopBar(
              isAr: isAr,
              hasFeedItems: !showDefaultDlScreen,
            ),
            Expanded(
              child: showDefaultDlScreen
                  ? _buildDlDefaultActivationLayout(
                      isAr: isAr,
                      screenSize: screenSize,
                      mediaPadding: mediaPadding,
                    )
                  : Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: PullToRefresh(
                          brandColor: _ink,
                          backgroundColor: _bg,
                          onRefresh: _loadNotifications,
                          child: ListView(
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
                            children: [
                              if (!_isOffline &&
                                  _state.isLoggedIn &&
                                  _items.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    child: Row(
                                      children: [
                                        _buildFilterChip(
                                          0,
                                          s.tr('الكل', 'Tout', 'All'),
                                        ),
                                        const SizedBox(width: 8),
                                        _buildFilterChip(
                                          1,
                                          s.tr(
                                            'الرسائل والعروض',
                                            'Messages & Offres',
                                            'Messages & Offers',
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _buildFilterChip(
                                          2,
                                          s.tr(
                                            'نشاط الحساب',
                                            'Activité',
                                            'Activity',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (_isOffline)
                                _buildStateCard(
                                  IllustratedStateView(
                                    assetPath:
                                        'assets/images/state_no_internet.png',
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
                                        ? s.tr(
                                            'جاري الاتصال...',
                                            'Connexion...',
                                            'Connecting...',
                                          )
                                        : s.tr(
                                            'إعادة المحاولة الآن',
                                            'Réessayer maintenant',
                                            'Try again',
                                          ),
                                    onAction: _retryConnection,
                                  ),
                                )
                              else if (_isLoading)
                                const NotificationsSkeleton()
                              else if (filtered.isEmpty)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 48),
                                  child: Center(
                                    child: Text(
                                      s.tr(
                                        'لا توجد إشعارات في هذا التصنيف',
                                        'Aucune notification dans cette catégorie',
                                        'No notifications in this category',
                                      ),
                                      style: const TextStyle(
                                        color: _muted,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                )
                              else ...[
                                if (unreadItems.isNotEmpty) ...[
                                  _buildSectionHeader(
                                    s.tr('جديد', 'Nouveau', 'New'),
                                  ),
                                  _buildNotificationGroup(unreadItems, isAr),
                                ],
                                if (readItems.isNotEmpty) ...[
                                  _buildSectionHeader(
                                    s.tr('الأقدم', 'Plus ancien', 'Earlier'),
                                  ),
                                  _buildNotificationGroup(readItems, isAr),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateCard(Widget child) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: 4,
        end: 4,
        top: 8,
        bottom: 6,
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: _muted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildNotificationGroup(
      List<Map<String, dynamic>> items, bool isAr) {
    final rows = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      rows.add(_buildNotificationRow(items[i], isAr));
      if (i < items.length - 1) {
        rows.add(
          const Padding(
            padding: EdgeInsetsDirectional.only(start: 70, end: 16),
            child: Divider(height: 1, thickness: 1, color: _divider),
          ),
        );
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _divider, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: rows),
    );
  }

  Widget _buildNotificationRow(Map<String, dynamic> item, bool isAr) {
    final bool unread = item['unread'] == true;
    final bool showActionBadge = unread && (item['actionable'] == true);
    final bool hasLink = (int.tryParse('${item['ad_id'] ?? ''}') ?? 0) > 0 ||
        (int.tryParse('${item['conversation_id'] ?? ''}') ?? 0) > 0;

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
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: const Color(0xFFFEF2F2),
        child: const Icon(
          CupertinoIcons.trash_fill,
          color: _red,
          size: 20,
        ),
      ),
      child: Material(
        color: showActionBadge
            ? NotificationBadge.actionRedDotColor.withValues(alpha: 0.04)
            : Colors.transparent,
        child: InkWell(
          onTap: () => _openNotification(item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                NotificationBadge(
                  count: showActionBadge ? 1 : 0,
                  type: NotificationBadgeType.dot,
                  variant: NotificationBadgeVariant.red,
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(
                      color: _pillGrey,
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      item['asset'] as String,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        item['category'] == 1
                            ? CupertinoIcons.chat_bubble_fill
                            : CupertinoIcons.bell_fill,
                        color: item['category'] == 1 ? _red : _ink,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight:
                              unread ? FontWeight.w700 : FontWeight.w500,
                          color: _ink,
                        ),
                      ),
                      if ((item['body'] as String).isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item['body'] as String,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: _muted,
                            height: 1.35,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        item['time'] as String,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          color: _timeMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasLink) ...[
                  const SizedBox(width: 8),
                  Icon(
                    isAr
                        ? CupertinoIcons.chevron_left
                        : CupertinoIcons.chevron_right,
                    size: 14,
                    color: _timeMuted,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final bool selected = _selectedFilter == index;
    return PressableScale(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilter = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _ink : _pillGrey,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? Colors.white : _ink,
          ),
        ),
      ),
    );
  }
}
