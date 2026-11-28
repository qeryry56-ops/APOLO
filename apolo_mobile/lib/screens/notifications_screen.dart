import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import '../core/services/media_rtc_bridge.dart';
import '../core/services/push_notification_service.dart';
import '../core/state/app_state.dart';
import '../theme/dl_share_profile_tokens.dart';
import '../widgets/apolo_badges_kit.dart';
import '../widgets/dl_settings_kit.dart';
import '../widgets/notification_badge.dart';
import '../widgets/pull_to_refresh.dart';
import 'ad_detail_screen.dart';
import 'chat_room_screen.dart';
import 'post_ad_screen.dart';
import 'search_screen.dart';
import 'stores_screen.dart';
import 'widgets/app_image.dart';
import 'widgets/skeleton_loader.dart';
import '../l10n/l10n.dart';

/// Dynamic Layer v5.1 Two-Stage Notification Center:
/// 1. **Stage 1 — `Notification / Default` (`45849:25601`)**:
///    Shown whenever notifications are NOT verified active (`Notification.permission != 'granted'`).
///    Renders the `330 × 240 px` `# notification-img` illustration + `56px` `#000000` capsule `Continue` CTA.
/// 2. **Stage 2 — `Notifications` Feed (`47390:2792`)**:
///    Pure `#FFFFFF` canvas, `#EEEEEE` / `#000000` capsule category filters, `#F6F6F6` flat unread surfaces,
///    `#EEEEEE` monochrome monogram avatars with `#000000` / `#2997FF` mini category badges,
///    `ApoloVerifiedBadge` on official/verified senders, and a Dynamic Layer Notification Preferences sheet.
class NotificationsScreen extends StatefulWidget {
  final bool initialSimulateOffline;
  const NotificationsScreen({super.key, this.initialSimulateOffline = false});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const String _prefActivatedKey = 'apolo_notifications_activated_v1';
  static const String _prefMessagesKey = 'apolo_notif_pref_messages_v1';
  static const String _prefSavedKey = 'apolo_notif_pref_saved_v1';
  static const String _prefStoresKey = 'apolo_notif_pref_stores_v1';

  final AppState _state = AppState();
  late bool _isOffline;
  bool _isLoading = true;
  bool _isReconnecting = false;
  bool _prefsActivated = false;
  bool _prefsLoaded = false;
  bool _isActivating = false;
  String _permissionStatus = 'unsupported';

  /// 0 = All, 1 = Messages & Offers, 2 = Updates
  int _selectedFilter = 0;

  bool _prefMessages = true;
  bool _prefSaved = true;
  bool _prefStores = true;

  List<Map<String, dynamic>> _items = [];

  // Strict Dynamic Layer v5.1 Palette Tokens
  Color get _dlBg => ApoloDlPalette.of(context).bg;
  Color get _dlSurface => ApoloDlPalette.of(context).surfaceSubtle;
  Color get _dlPill => ApoloDlPalette.of(context).pill;
  Color get _dlSeparator => ApoloDlPalette.of(context).separator;
  Color get _dlInk => ApoloDlPalette.of(context).ink;
  Color get _dlOnInk => ApoloDlPalette.of(context).onInk;
  Color get _dlBodyInk => (Theme.of(context).brightness == Brightness.dark ? const Color(0xFFD4D4D8) : const Color(0xFF525252));
  Color get _dlMuted => ApoloDlPalette.of(context).muted;
  Color get _dlTimeMuted => ApoloDlPalette.of(context).subtle;
  static const Color _dlFollowBlue = Color(0xFF2997FF);

  @override
  void initState() {
    super.initState();
    _isOffline = widget.initialSimulateOffline;
    _permissionStatus =
        ApoloPushNotificationService.instance.getPermissionStatusSync();
    // Rule 5: Clear badge immediately on screen open without waiting for API.
    _state.clearUnreadNotificationsOptimistically(syncRemote: false);
    _state.addListener(_onStateChanged);
    _loadActivationState();
    _loadNotifications();
  }

  bool get _isNotificationsTrulyActive {
    final liveStatus =
        ApoloPushNotificationService.instance.getPermissionStatusSync();
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
      final prefMsg = prefs.getBool(_prefMessagesKey) ?? true;
      final prefSav = prefs.getBool(_prefSavedKey) ?? true;
      final prefStr = prefs.getBool(_prefStoresKey) ?? true;
      final liveStatus = await ApoloPushNotificationService.instance
          .getPermissionStatusAsync();
      if (mounted) {
        setState(() {
          _prefsActivated = saved;
          _prefMessages = prefMsg;
          _prefSaved = prefSav;
          _prefStores = prefStr;
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

  Future<void> _saveAlertPref(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
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

  Future<void> _showBlockedPermissionSheet() async {
    final s = _state.s;
    await showApoloDlBottomSheet<void>(
      context,
      headerTitle: s.tr(
        'تفعيل الإشعارات',
        'Activer les notifications',
        appL10n.notificationsEnableNotifications,
      ),
      media: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _dlPill,
          shape: BoxShape.circle,
        ),
        child: Icon(
          CupertinoIcons.bell_slash_fill,
          size: 25,
          color: _dlInk,
        ),
      ),
      contentTitle: s.tr(
        'الإشعارات غير مفعّلة على الجهاز',
        'Notifications désactivées',
        appL10n.notificationsAreBlocked,
      ),
      contentDescription: s.tr(
        'يرجى تفعيل الإشعارات من إعدادات التطبيق في الهاتف أو أيقونة القفل في المتصفح ثم الضغط على "متابعة" مرة أخرى.',
        'Autorisez les notifications dans les réglages de votre appareil ou navigateur puis appuyez sur Continuer.',
        appL10n.notificationsPleaseEnableNotificationsPhoneBrowser,
      ),
      actions: [
        ApoloDlButton(
          key: const Key('dl-notification-blocked-dismiss'),
          label: s.tr('حسناً، فهمت', 'Compris', appL10n.notificationsGotIt),
          variant: ApoloDlButtonVariant.primary,
          borderRadius: 999,
          fullWidth: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Future<void> _openPreferencesSheet() async {
    HapticFeedback.selectionClick();
    final s = _state.s;
    final hasUnread = _items.any((e) => e['unread'] == true);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _dlBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
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
                          color: _dlPill,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _dlPill,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            CupertinoIcons.bell_fill,
                            size: 18,
                            color: _dlInk,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.tr(
                                  'إعدادات التنبيهات',
                                  'Préférences d’alertes',
                                  appL10n.notificationsNotificationPreferences,
                                ),
                                style: TextStyle(
                                  color: _dlInk,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                s.tr(
                                  'اختر التنبيهات التي تهمك على Apolo',
                                  'Choisissez les alertes à recevoir sur Apolo',
                                  appL10n.notificationsChooseWhichApoloAlertsYou,
                                ),
                                style: TextStyle(
                                  color: _dlMuted,
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
                          backgroundColor: _dlPill,
                          iconColor: _dlInk,
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      decoration: BoxDecoration(
                        color: _dlSurface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildPrefToggleRow(
                            rowKey: const Key('dl-notif-pref-messages'),
                            icon: CupertinoIcons.chat_bubble_2_fill,
                            title: s.tr(
                              'رسائل وعروض المشترين',
                              'Messages & offres acheteurs',
                              appL10n.notificationsMessagesBuyerOffers,
                            ),
                            subtitle: s.tr(
                              'تنبيه فوري عند وصول رسالة أو عرض سعر',
                              'Alerte instantanée dès qu’un acheteur écrit',
                              appL10n.notificationsInstantAlertWhenBuyerMessages,
                            ),
                            value: _prefMessages,
                            onChanged: (val) {
                              HapticFeedback.selectionClick();
                              setState(() => _prefMessages = val);
                              setSheetState(() {});
                              _saveAlertPref(_prefMessagesKey, val);
                            },
                          ),
                          Padding(
                            padding: EdgeInsetsDirectional.only(start: 56),
                            child: SizedBox(
                              height: 1,
                              width: double.infinity,
                              child: DecoratedBox(
                                decoration: BoxDecoration(color: _dlSeparator),
                              ),
                            ),
                          ),
                          _buildPrefToggleRow(
                            rowKey: const Key('dl-notif-pref-saved'),
                            icon: CupertinoIcons.bookmark_fill,
                            title: s.tr(
                              'تخفيضات الأسعار والمحفوظات',
                              'Baisses de prix & favoris',
                              appL10n.notificationsPriceDropsSavedListings,
                            ),
                            subtitle: s.tr(
                              'إشعارات الإعلانات التي حفظتها في المفضلة',
                              'Mises à jour sur vos annonces enregistrées',
                              appL10n.notificationsUpdatesListingsYouBookmarked,
                            ),
                            value: _prefSaved,
                            onChanged: (val) {
                              HapticFeedback.selectionClick();
                              setState(() => _prefSaved = val);
                              setSheetState(() {});
                              _saveAlertPref(_prefSavedKey, val);
                            },
                          ),
                          Padding(
                            padding: EdgeInsetsDirectional.only(start: 56),
                            child: SizedBox(
                              height: 1,
                              width: double.infinity,
                              child: DecoratedBox(
                                decoration: BoxDecoration(color: _dlSeparator),
                              ),
                            ),
                          ),
                          _buildPrefToggleRow(
                            rowKey: const Key('dl-notif-pref-stores'),
                            icon: CupertinoIcons.checkmark_seal_fill,
                            title: s.tr(
                              'تحديثات المتاجر الرسمية',
                              'Boutiques officielles & actus',
                              appL10n.notificationsOfficialStoresUpdates,
                            ),
                            subtitle: s.tr(
                              'جديد المتاجر الموثقة التي تتابعها',
                              'Nouveautés des vendeurs vérifiés suivis',
                              appL10n.notificationsNewArrivalsFromVerifiedSellers,
                            ),
                            value: _prefStores,
                            onChanged: (val) {
                              HapticFeedback.selectionClick();
                              setState(() => _prefStores = val);
                              setSheetState(() {});
                              _saveAlertPref(_prefStoresKey, val);
                            },
                          ),
                        ],
                      ),
                    ),
                    if (hasUnread) ...[
                      const SizedBox(height: 14),
                      ApoloDlButton(
                        label: s.tr(
                          'تحديد الكل كمقروء',
                          'Tout marquer comme lu',
                          appL10n.notificationsMarkAllAsRead,
                        ),
                        variant: ApoloDlButtonVariant.secondary,
                        borderRadius: 999,
                        fullWidth: true,
                        height: 48,
                        leadingIcon: CupertinoIcons.checkmark_alt,
                        onPressed: () {
                          _markAllRead();
                          Navigator.of(ctx).pop();
                        },
                      ),
                    ],
                    const SizedBox(height: 12),
                    ApoloDlButton(
                      key: const Key('dl-notif-pref-done'),
                      label: s.tr('تم', 'Terminé', appL10n.doneButton),
                      variant: ApoloDlButtonVariant.primary,
                      borderRadius: 999,
                      fullWidth: true,
                      height: 52,
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrefToggleRow({
    required Key rowKey,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      key: rowKey,
      borderRadius: BorderRadius.circular(20),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _dlBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 16, color: _dlInk),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: _dlInk,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: _dlMuted,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _DlNotificationSwitch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }

  Future<void> _activateAndVerifyNotifications() async {
    if (_isActivating) return;
    HapticFeedback.mediumImpact();
    setState(() => _isActivating = true);

    String status = 'unsupported';
    try {
      status = await ApoloPushNotificationService.instance.requestPermission();
    } catch (_) {
      status = ApoloPushNotificationService.instance.getPermissionStatusSync();
    }

    if (!mounted) return;

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
            backgroundColor: _dlInk,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            duration: const Duration(seconds: 2),
            content: Text(
              s.tr(
                'يرجى الضغط على "سماح / Allow" لتفعيل الإشعارات',
                'Veuillez appuyer sur « Autoriser » pour activer les alertes',
                appL10n.notificationsPleaseAllowNotificationsContinue,
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
    int category = 2; // Updates & Stores
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
    final parsedDt =
        createdRaw.isNotEmpty ? DateTime.tryParse(createdRaw) : null;
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

    final bool isVerifiedSender = raw['is_verified'] == true ||
        raw['sender_verified'] == true ||
        raw['data']?['is_verified'] == true;

    return {
      'id': raw['id'] ?? DateTime.now().millisecondsSinceEpoch,
      'category': category,
      'badge_kind': badgeKind,
      'bucket': isToday ? 'today' : 'week',
      'actionable': AppState.isActionableNotification(raw),
      'unread': raw['is_read'] != true && raw['read_at'] == null,
      'is_verified': isVerifiedSender,
      'title':
          (raw['title'] ?? raw['data']?['title'] ?? 'إشعار جديد').toString(),
      'body': (raw['body'] ?? raw['message'] ?? raw['data']?['message'] ?? '')
          .toString(),
      'time': timeStr.isNotEmpty ? timeStr : '4h',
      'avatar_url': (raw['sender_avatar'] ??
              raw['avatar'] ??
              raw['data']?['sender_avatar'] ??
              '')
          .toString()
          .trim(),
      'ad_image':
          (raw['ad_image'] ?? raw['data']?['ad_image'] ?? '').toString().trim(),
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
  /// shown when the user has 0 server items yet.
  List<Map<String, dynamic>> _buildApoloShowcaseItems(AppStrings s) {
    return <Map<String, dynamic>>[
      {
        'id': 'apolo_welcome_live',
        'category': 1,
        'bucket': 'today',
        'badge_kind': 'offer',
        'actionable': false,
        'unread': false,
        'is_verified': false,
        'avatar_initial': 'A',
        'system_icon': 'bell',
        'nav_target': 'explore',
        'spans': <Map<String, dynamic>>[
          {
            'text': s.tr('أنت', 'Vous', appL10n.meetingYou),
            'bold': true,
          },
          {
            'text': s.tr(
              ' قمت بتفعيل التنبيهات الفورية لـ ',
              ' avez activé les alertes en direct sur ',
              appL10n.notificationsActivatedInstantAlerts,
            ),
            'bold': false,
          },
          {
            'text': s.tr(
              'Apolo.ma — الرسائل والعروض',
              'Apolo.ma — Messages & Offres',
              appL10n.notificationsApoloMaBuyerMessagesOffers,
            ),
            'bold': true,
          },
        ],
        'time': s.tr('الآن', 'maintenant', appL10n.notificationsJustNow),
      },
      {
        'id': 'apolo_seller_tip',
        'category': 1,
        'bucket': 'today',
        'badge_kind': 'chat',
        'actionable': false,
        'unread': false,
        'is_verified': true,
        'avatar_initial': 'A',
        'system_icon': 'sparkles',
        'nav_target': 'post_ad',
        'spans': <Map<String, dynamic>>[
          {
            'text': s.tr('فريق Apolo', 'Équipe Apolo', appL10n.notificationsApoloTeam),
            'bold': true,
            'verified': true,
          },
          {
            'text': s.tr(
              ' شارك معك نصيحة: أضف صوراً واضحة وثمناً مناسباً لبيع إعلانك بسرعة.',
              ' : Ajoutez des photos nettes à votre annonce pour vendre plus vite.',
              appL10n.notificationsSharedTipAddClearPhotos,
            ),
            'bold': false,
          },
        ],
        'time': s.tr('اليوم', "Aujourd'hui", appL10n.notifications2hAgo),
      },
      {
        'id': 'apolo_stores_weekly',
        'category': 2,
        'bucket': 'week',
        'badge_kind': 'update',
        'actionable': false,
        'unread': false,
        'is_verified': true,
        'avatar_initial': 'S',
        'system_icon': 'store',
        'nav_target': 'stores',
        'spans': <Map<String, dynamic>>[
          {
            'text': s.tr(
              'متاجر Apolo الرسمية',
              'Boutiques Apolo PRO',
              appL10n.notificationsApoloOfficialStores,
            ),
            'bold': true,
            'verified': true,
          },
          {
            'text': s.tr(
              ' قامت بتحديث ',
              ' a mis à jour ',
              appL10n.notificationsUpdated,
            ),
            'bold': false,
          },
          {
            'text': s.tr(
              'عروض السيارات، العقارات والإلكترونيات الموثقة',
              'les annonces vérifiées Auto, Immo & Tech',
              appL10n.notificationsVerifiedCarsRealEstateTech,
            ),
            'bold': true,
          },
          {
            'text': s.tr(
              ' في جميع مدن المغرب.',
              ' dans toutes les villes du Maroc.',
              appL10n.notificationsAcrossAllMoroccanCities,
            ),
            'bold': false,
          },
        ],
        'time': s.tr('هذا الأسبوع', 'Cette semaine', appL10n.notificationsThisWeek),
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

  /// Dynamic Layer v5.1 `TopNavigation` (`height: topInset + 56px`):
  /// - Stage 1 (`showFeedHeader == false`): `40×40` circular `#EEEEEE` back button only
  /// - Stage 2 (`showFeedHeader == true`, Figma `47390:2792`): `40×40` `#EEEEEE` back button +
  ///   centered `16px Bold` `Notifications` title + `40×40` `#EEEEEE` preferences button.
  Widget _buildDlTopBar({
    required bool isAr,
    required bool showFeedHeader,
  }) {
    final s = _state.s;
    final topInset = MediaQuery.paddingOf(context).top;
    final backIcon =
        isAr ? CupertinoIcons.chevron_right : CupertinoIcons.chevron_left;

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
                      backgroundColor: _dlPill,
                      iconColor: _dlInk,
                      tooltip:
                          MaterialLocalizations.of(context).backButtonTooltip,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: showFeedHeader
                          ? Text(
                              s.tr('الإشعارات', 'Notifications',
                                  appL10n.notificationsNotifications),
                              key: const Key('dl-notifications-header-title'),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _dlInk,
                                fontSize: 16.0,
                                fontWeight: FontWeight.w700,
                                height: 24.0 / 16.0,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(width: 16),
                    if (showFeedHeader)
                      ApoloDlIconCircleButton(
                        key: const Key('dl-notification-prefs-button'),
                        icon: CupertinoIcons.slider_horizontal_3,
                        iconSize: 18,
                        backgroundColor: _dlPill,
                        iconColor: _dlInk,
                        tooltip: s.tr(
                          'إعدادات التنبيهات',
                          'Préférences',
                          appL10n.notificationsNotificationPreferences,
                        ),
                        onPressed: _openPreferencesSheet,
                      )
                    else
                      const SizedBox(width: 40, height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Stage 1 Hero Illustration (`# notification-img`, `330 × 240 px`) in flat Dynamic Layer v5.1.
  Widget _buildDlNotificationIllustration(bool isAr) {
    final s = _state.s;
    final previewTitle = s.tr(
      'مرحباً، معك Apolo!',
      'Bonjour, c’est Apolo !',
      appL10n.notificationsHeyItSApolo,
    );
    final previewBody = s.tr(
      'أنا جاهز لتنبيهك فور وصول رسائل وعروض المشترين. ماذا عنك؟',
      'Je suis prêt à vous alerter dès qu’un message arrive. Et vous ?',
      appL10n.notificationsIAmReadyHelpYou,
    );
    final nowLabel = s.tr('الآن', 'maintenant', appL10n.notificationsNow);

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
                    color: _dlPill,
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
                            _dlBg.withValues(alpha: 0.0),
                            _dlBg.withValues(alpha: 0.88),
                            _dlBg,
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
                      color: _dlBg,
                      borderRadius: BorderRadius.circular(18.0),
                      border: Border.all(
                        color: _dlSeparator,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 44.0,
                          height: 44.0,
                          decoration: BoxDecoration(
                            color: _dlSurface,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            CupertinoIcons.bell_fill,
                            size: 20,
                            color: _dlInk,
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
                                  Flexible(
                                    child: Text(
                                      previewTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: _dlInk,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        height: 1.25,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const ApoloVerifiedBadge(size: 14),
                                  const Spacer(),
                                  const SizedBox(width: 6),
                                  Text(
                                    nowLabel,
                                    style: TextStyle(
                                      color: _dlMuted,
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
                                style: TextStyle(
                                  color: _dlMuted,
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
                          s.tr('الإشعارات', 'Notifications', appL10n.notificationsNotification),
                          key: const Key('dl-notification-title'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _dlInk,
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
                              appL10n.notificationsActivateNotificationsReceiveMessages,
                            ),
                            key: const Key('dl-notification-subtitle'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _dlMuted,
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
                            color: _dlInk,
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
                                  s.tr('متابعة', 'Continuer', appL10n.continueButton),
                                  style: TextStyle(
                                    color: _dlOnInk,
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

  Widget _buildDlMonogramAvatar(Map<String, dynamic> item) {
    final String systemIcon = (item['system_icon'] ?? '').toString();
    final String senderName = (item['sender_name'] ??
            item['avatar_initial'] ??
            item['title'] ??
            'A')
        .toString()
        .trim();
    final String initial =
        senderName.isNotEmpty ? senderName.characters.first.toUpperCase() : 'A';

    IconData? iconData;
    if (systemIcon == 'bell') {
      iconData = CupertinoIcons.bell_fill;
    } else if (systemIcon == 'sparkles') {
      iconData = CupertinoIcons.sparkles;
    } else if (systemIcon == 'store') {
      iconData = CupertinoIcons.bag_fill;
    }

    return Container(
      width: 44.0,
      height: 44.0,
      decoration: BoxDecoration(
        color: _dlPill,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: iconData != null
          ? Icon(iconData, size: 19, color: _dlInk)
          : Text(
              initial,
              style: TextStyle(
                color: _dlInk,
                fontSize: 16.0,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }

  /// Builds the `44 × 44 px` `#EEEEEE` circular avatar + `18 × 18 px` overlapping
  /// Dynamic Layer mini category badge (`#000000` / `#2997FF`).
  Widget _buildDlAvatarWithMiniBadge(Map<String, dynamic> item) {
    final bool unread = item['unread'] == true;
    final bool showActionBadge = unread && (item['actionable'] == true);
    final String badgeKind = (item['badge_kind'] ?? 'update').toString();
    final String avatarUrl = (item['avatar_url'] ?? '').toString().trim();

    final Color miniBadgeColor;
    final IconData miniBadgeIcon;
    switch (badgeKind) {
      case 'chat':
        miniBadgeColor = _dlFollowBlue;
        miniBadgeIcon = CupertinoIcons.chat_bubble_fill;
        break;
      case 'offer':
        miniBadgeColor = _dlInk;
        miniBadgeIcon = CupertinoIcons.tag_fill;
        break;
      default:
        miniBadgeColor = _dlInk;
        miniBadgeIcon = CupertinoIcons.sparkles;
        break;
    }

    final fallbackAvatar = _buildDlMonogramAvatar(item);
    final Widget avatarCircle = avatarUrl.isNotEmpty
        ? ClipOval(
            child: SizedBox(
              width: 44.0,
              height: 44.0,
              child: AppImage(
                url: avatarUrl,
                width: 44.0,
                height: 44.0,
                fit: BoxFit.cover,
                fallback: fallbackAvatar,
              ),
            ),
          )
        : fallbackAvatar;

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
                  border: Border.all(color: _dlBg, width: 1.5),
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

  /// Single row inside Figma `47390:2792` `Main Container` with Dynamic Layer v5.1 styling.
  Widget _buildDlFeedItemRow(Map<String, dynamic> item) {
    final spansRaw = item['spans'];
    final String time = (item['time'] ?? '').toString().trim();
    final bool isServerItem = spansRaw == null;
    final bool isUnread = isServerItem && item['unread'] == true;
    final bool isVerified = item['is_verified'] == true;
    final String adImage = (item['ad_image'] ?? '').toString().trim();

    Widget textColumn;
    if (spansRaw is List && spansRaw.isNotEmpty) {
      final textSpans = <InlineSpan>[];
      for (final part in spansRaw) {
        if (part is Map) {
          final isBold = part['bold'] == true;
          final showVerified = part['verified'] == true;
          textSpans.add(
            TextSpan(
              text: (part['text'] ?? '').toString(),
              style: TextStyle(
                color: isBold ? _dlInk : _dlBodyInk,
                fontSize: 14.0,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
                height: 20.0 / 14.0,
              ),
            ),
          );
          if (showVerified) {
            textSpans.add(
              const WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3),
                  child: ApoloVerifiedBadge(size: 14),
                ),
              ),
            );
          }
        }
      }
      if (time.isNotEmpty) {
        textSpans.add(
          TextSpan(
            text: '  $time',
            style: TextStyle(
              color: _dlTimeMuted,
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _dlInk,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w700,
                      height: 20.0 / 14.0,
                    ),
                  ),
                ),
                if (isVerified) ...[
                  const SizedBox(width: 4),
                  const ApoloVerifiedBadge(size: 14),
                ],
              ],
            ),
          if (body.isNotEmpty || time.isNotEmpty) ...[
            if (title.isNotEmpty) const SizedBox(height: 1.5),
            Text.rich(
              TextSpan(
                children: [
                  if (body.isNotEmpty)
                    TextSpan(
                      text: body,
                      style: TextStyle(
                        color: _dlBodyInk,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w400,
                        height: 20.0 / 14.0,
                      ),
                    ),
                  if (time.isNotEmpty)
                    TextSpan(
                      text: body.isNotEmpty ? '  $time' : time,
                      style: TextStyle(
                        color: _dlTimeMuted,
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

    final rowBody = Material(
      color: isUnread ? _dlSurface : Colors.transparent,
      borderRadius: BorderRadius.circular(16.0),
      child: InkWell(
        key: Key('dl-notification-row-${item['id']}'),
        borderRadius: BorderRadius.circular(16.0),
        onTap: () => _openNotification(item),
        child: Padding(
          padding: isUnread
              ? const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0)
              : const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDlAvatarWithMiniBadge(item),
              const SizedBox(width: 14.0),
              Expanded(child: textColumn),
              if (adImage.isNotEmpty) ...[
                const SizedBox(width: 10.0),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: Container(
                    width: 42.0,
                    height: 42.0,
                    color: _dlPill,
                    child: AppImage(
                      url: adImage,
                      width: 42.0,
                      height: 42.0,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ],
          ),
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
          color: _dlPill,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          CupertinoIcons.trash_fill,
          color: _dlInk,
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
          style: TextStyle(
            color: _dlInk,
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            height: 24.0 / 18.0,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 14.0),
        for (int i = 0; i < rows.length; i++) ...[
          _buildDlFeedItemRow(rows[i]),
          if (i < rows.length - 1) const SizedBox(height: 16.0),
        ],
      ],
    );
  }

  Widget _buildDlFilterBar(AppStrings s) {
    final bool hasUnread =
        _state.isLoggedIn && _items.any((e) => e['unread'] == true);

    final filters = <(int, Key, String)>[
      (
        0,
        const Key('dl-notif-filter-all'),
        s.tr('الكل', 'Tout', appL10n.chatListAll),
      ),
      (
        1,
        const Key('dl-notif-filter-messages'),
        s.tr('الرسائل', 'Messages', appL10n.navMessages),
      ),
      (
        2,
        const Key('dl-notif-filter-updates'),
        s.tr('التحديثات', 'Activité', appL10n.notificationsUpdates),
      ),
    ];

    return SingleChildScrollView(
      key: const Key('dl-notifications-filter-bar'),
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (int i = 0; i < filters.length; i++) ...[
            _buildDlFilterPill(
              pillKey: filters[i].$2,
              label: filters[i].$3,
              selected: _selectedFilter == filters[i].$1,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedFilter = filters[i].$1);
              },
            ),
            if (i < filters.length - 1) const SizedBox(width: 8),
          ],
          if (hasUnread) ...[
            const SizedBox(width: 8),
            Material(
              color: _dlPill,
              shape: const StadiumBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: const Key('dl-notification-mark-all-read'),
                customBorder: const StadiumBorder(),
                onTap: _markAllRead,
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
                        color: _dlInk,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        s.tr('قراءة الكل', 'Tout lire', appL10n.chatListMarkAllRead),
                        style: TextStyle(
                          color: _dlInk,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDlFilterPill({
    required Key pillKey,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? _dlInk : _dlPill,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: pillKey,
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? _dlBg : _dlInk,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDlFilterEmptyCard(AppStrings s) {
    return Container(
      key: const Key('dl-notifications-filter-empty'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: _dlSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _dlBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              CupertinoIcons.bell,
              size: 22,
              color: _dlInk,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            s.tr(
              'لا توجد إشعارات في هذا القسم',
              'Aucune notification dans cet onglet',
              appL10n.notificationsNoNotificationsThisCategory,
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _dlInk,
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s.tr(
              'ستظهر هنا رسائل وعروض المشترين وتحديثات الإعلانات فور وصولها.',
              'Les messages acheteurs et mises à jour apparaîtront ici.',
              appL10n.notificationsBuyerMessagesOffersListingUpdates,
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _dlMuted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ApoloDlButton(
            key: const Key('dl-notifications-filter-reset'),
            label: s.tr('عرض الكل', 'Tout afficher', appL10n.adDetailShowAll),
            variant: ApoloDlButtonVariant.primary,
            size: ApoloDlButtonSize.sm,
            borderRadius: 999,
            onPressed: () => setState(() => _selectedFilter = 0),
          ),
        ],
      ),
    );
  }

  Widget _buildDlOfflineCard(AppStrings s) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            key: const Key('dl-notifications-offline-card'),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: _dlSurface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _dlBg,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    CupertinoIcons.wifi_slash,
                    size: 24,
                    color: _dlInk,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  s.tr(
                    'لا يوجد اتصال بالإنترنت',
                    'Aucune connexion Internet',
                    appL10n.notificationsNoInternetConnection,
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _dlInk,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.tr(
                    'تأكد من اتصالك بشبكة Wi-Fi أو بيانات الهاتف لتحميل آخر الإشعارات والرسائل.',
                    'Vérifiez votre connexion Wi-Fi ou mobile pour actualiser vos notifications.',
                    appL10n.notificationsCheckWiFiMobileData,
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _dlMuted,
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                ApoloDlButton(
                  key: const Key('dl-notifications-retry-btn'),
                  label: _isReconnecting
                      ? s.tr('جاري الاتصال...', 'Connexion...', appL10n.callConnecting)
                      : s.tr('إعادة المحاولة', 'Réessayer', appL10n.tryAgainButton),
                  variant: ApoloDlButtonVariant.primary,
                  borderRadius: 999,
                  height: 48,
                  isLoading: _isReconnecting,
                  onPressed: _isReconnecting ? null : _retryConnection,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Stage 2: Exact Figma `47390:2792` `Notifications` screen (`Main Container`
  /// with `top: 32px, right: 16px, bottom: 32px, left: 16px`, `Today` & `This week` sections).
  Widget _buildVerifiedNotificationsFeed(AppStrings s) {
    if (_isOffline) {
      return _buildDlOfflineCard(s);
    }

    if (_isLoading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
        children: const [NotificationsSkeleton()],
      );
    }

    final allItems = _items.isNotEmpty ? _items : _buildApoloShowcaseItems(s);
    final effectiveItems = _selectedFilter == 0
        ? allItems
        : allItems
            .where((e) => (e['category'] ?? 2) == _selectedFilter)
            .toList();
    final todayItems =
        effectiveItems.where((e) => e['bucket'] == 'today').toList();
    final weekItems =
        effectiveItems.where((e) => e['bucket'] != 'today').toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480.0),
        child: PullToRefresh(
          brandColor: _dlInk,
          backgroundColor: _dlBg,
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
                    _buildDlFilterBar(s),
                    const SizedBox(height: 20.0),
                    if (effectiveItems.isEmpty)
                      _buildDlFilterEmptyCard(s)
                    else ...[
                      if (todayItems.isNotEmpty)
                        _buildDlSectionBlock(
                          sectionKey:
                              const Key('dl-notifications-section-today'),
                          heading: s.tr('اليوم', "Aujourd'hui", appL10n.notificationsToday),
                          rows: todayItems,
                        ),
                      if (todayItems.isNotEmpty && weekItems.isNotEmpty)
                        const SizedBox(height: 28.0),
                      if (weekItems.isNotEmpty)
                        _buildDlSectionBlock(
                          sectionKey:
                              const Key('dl-notifications-section-week'),
                          heading: s.tr(
                            'هذا الأسبوع',
                            'Cette semaine',
                            appL10n.notificationsThisWeek,
                          ),
                          rows: weekItems,
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

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final isAr = s.isAr;
    final screenSize = MediaQuery.sizeOf(context);
    final mediaPadding = MediaQuery.paddingOf(context);
    final bool isActive = _isNotificationsTrulyActive;
    final bool showActivationGate =
        !_isOffline && !isActive && (_prefsLoaded || !_isLoading);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _dlBg,
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

/// Crisp `#000000` / `#DCDCDC` Dynamic Layer v5.1 capsule toggle switch.
class _DlNotificationSwitch extends StatelessWidget {
  const _DlNotificationSwitch({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: 48,
        height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? const Color(0xFF000000) : const Color(0xFFDCDCDC),
          borderRadius: BorderRadius.circular(999),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: value
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
