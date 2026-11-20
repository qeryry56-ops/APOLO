import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/state/app_state.dart';
import 'ad_detail_screen.dart';
import 'auth_screen.dart';
import 'chat_room_screen.dart';
import 'widgets/kinetic_widgets.dart';

/// Grouped iOS-style Notifications Screen matching SettingsScreen (#F2F3F7 canvas + white cards):
/// - Real backend integration with `GET /notifications`
/// - Mark all as read with server sync (`POST /notifications/read-all`)
/// - Direct deep-link navigation to real Ad or real Chat Room
/// - Clean Empty, Logged-Out, and Offline states
class NotificationsScreen extends StatefulWidget {
  final bool initialSimulateOffline;
  const NotificationsScreen({super.key, this.initialSimulateOffline = false});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final AppState _state = AppState();
  int _selectedFilter = 0; // 0: All, 1: Messages & Offers, 2: Activity
  late bool _isOffline;
  bool _isLoading = true;
  bool _isReconnecting = false;

  List<Map<String, dynamic>> _items = [];

  static const Color _bg = Color(0xFFF2F3F7);
  static const Color _cardBg = Colors.white;
  static const Color _ink = Color(0xFF0A0A0A);
  static const Color _red = Color(0xFFE31B23);
  static const Color _blueDot = Color(0xFF0866FF);
  static const Color _surface = Color(0xFFF5F6F8);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _timeMuted = Color(0xFF8E8E93);
  static const Color _divider = Color(0xFFF1F2F6);

  @override
  void initState() {
    super.initState();
    _isOffline = widget.initialSimulateOffline;
    _state.addListener(_onStateChanged);
    _loadNotifications();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    super.dispose();
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
        setState(() {
          _items = list
              .whereType<Map>()
              .map((e) => _normalizeNotification(Map<String, dynamic>.from(e)))
              .toList();
          _isLoading = false;
          _isOffline = false;
        });
        _updateUnreadBadge();
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
      'unread': raw['is_read'] != true && raw['read_at'] == null,
      'title':
          (raw['title'] ?? raw['data']?['title'] ?? 'إشعار جديد').toString(),
      'body': (raw['body'] ?? raw['message'] ?? raw['data']?['message'] ?? '')
          .toString(),
      'time': (raw['created_at_human'] ?? raw['time'] ?? 'منذ قليل').toString(),
      'ad_id': raw['ad_id'] ?? raw['data']?['ad_id'],
      'conversation_id':
          raw['conversation_id'] ?? raw['data']?['conversation_id'],
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
    int unread = 0;
    for (final it in _items) {
      if (it['unread'] == true) unread++;
    }
    _state.unreadNotificationsCount = unread;
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

    if (adId != null && adId > 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AdDetailScreen(adId: adId)),
      );
    } else if (convId != null && convId > 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            conversationId: convId,
            peerName: item['title'].toString(),
            adTitle: '',
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

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final isAr = s.isAr;
    final filtered = _filteredItems;
    final unreadItems = filtered.where((e) => e['unread'] == true).toList();
    final readItems = filtered.where((e) => e['unread'] != true).toList();

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 48,
          centerTitle: true,
          leading: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(
              isAr ? CupertinoIcons.chevron_right : CupertinoIcons.chevron_left,
              color: _ink,
              size: 22,
            ),
          ),
          title: Text(
            s.tr('الإشعارات', 'Notifications', 'Notifications'),
            style: const TextStyle(
              color: _ink,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            if (kDebugMode)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 6),
                child: PressableScale(
                  onTap: () {
                    setState(() => _isOffline = !_isOffline);
                    if (!_isOffline) _loadNotifications();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _isOffline ? const Color(0xFFFEF2F2) : _cardBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Icon(
                      _isOffline
                          ? CupertinoIcons.wifi_slash
                          : CupertinoIcons.wifi,
                      size: 14,
                      color: _isOffline ? _red : _muted,
                    ),
                  ),
                ),
              ),
            if (!_isOffline &&
                _state.isLoggedIn &&
                _items.any((e) => e['unread'] == true))
              IconButton(
                tooltip: s.tr('تحديد الكل كمقروء', 'Tout marquer comme lu',
                    'Mark all as read'),
                onPressed: _markAllRead,
                icon: const Icon(
                  CupertinoIcons.checkmark_alt_circle,
                  color: _blueDot,
                  size: 22,
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: RefreshIndicator(
                color: _red,
                backgroundColor: _cardBg,
                onRefresh: _loadNotifications,
                child: ListView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
                  children: [
                    // Filter Pills (Shown only when logged in, online, and has notifications)
                    if (!_isOffline && _state.isLoggedIn && _items.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
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
                                s.tr('الرسائل والعروض', 'Messages & Offres',
                                    'Messages & Offers'),
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                2,
                                s.tr('نشاط الحساب', 'Activité', 'Activity'),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // 1. Logged Out State
                    if (!_state.isLoggedIn)
                      _buildStateCard(
                        IllustratedStateView(
                          assetPath: 'assets/images/state_notifications.png',
                          fallbackIcon: CupertinoIcons.bell,
                          imageSize: 156,
                          title: s.tr(
                            'سجل الدخول لتلقي الإشعارات',
                            'Connectez-vous pour voir vos alertes',
                            'Sign in to see notifications',
                          ),
                          subtitle: s.tr(
                            'توصل فورياً بجديد الرسائل وعروض الأسعار على إعلاناتك المعروضة للبيع.',
                            'Recevez en temps réel les offres et messages sur vos annonces.',
                            'Get instant updates on messages and offers for your listings.',
                          ),
                          actionLabel: s.tr(
                            'تسجيل الدخول / إنشاء حساب',
                            'Connexion / Inscription',
                            'Sign in / Register',
                          ),
                          onAction: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AuthScreen(initialIsLogin: true),
                              ),
                            ).then((_) => _loadNotifications());
                          },
                        ),
                      )
                    // 2. Offline State
                    else if (_isOffline)
                      _buildStateCard(
                        IllustratedStateView(
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
                              ? s.tr('جاري الاتصال...', 'Connexion...',
                                  'Connecting...')
                              : s.tr('إعادة المحاولة الآن',
                                  'Réessayer maintenant', 'Try again'),
                          onAction: _retryConnection,
                        ),
                      )
                    // 3. Loading State
                    else if (_isLoading)
                      _buildStateCard(
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 64),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: _red,
                              strokeWidth: 2.5,
                            ),
                          ),
                        ),
                      )
                    // 4. Empty Notifications State
                    else if (filtered.isEmpty)
                      _buildStateCard(
                        IllustratedStateView(
                          assetPath: 'assets/images/state_notifications.png',
                          fallbackIcon: CupertinoIcons.bell_slash,
                          imageSize: 156,
                          title: s.tr(
                            'لا توجد إشعارات جديدة حالياً',
                            'Aucune notification pour le moment',
                            'No notifications yet',
                          ),
                          subtitle: s.tr(
                            'سنقوم بتنبيهك فور وصول رسالة من مشتري أو عند تلقي عرض سعر جديد على إعلانك.',
                            'Nous vous alerterons dès qu’un acheteur vous contacte ou fait une offre.',
                            'We will notify you when a buyer messages you or sends an offer.',
                          ),
                          actionLabel: s.tr(
                              'تحديث الإشعارات', 'Actualiser', 'Refresh'),
                          onAction: _loadNotifications,
                        ),
                      )
                    // 5. Grouped White Card Notifications List
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
      padding: const EdgeInsets.only(left: 4, right: 4, top: 8, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          color: _muted,
          fontSize: 13,
          fontWeight: FontWeight.w500,
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
            padding: EdgeInsetsDirectional.only(start: 68, end: 14),
            child: Divider(height: 1, thickness: 1, color: _divider),
          ),
        );
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: rows),
    );
  }

  Widget _buildNotificationRow(Map<String, dynamic> item, bool isAr) {
    final bool unread = item['unread'] == true;
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
        color: unread ? _blueDot.withValues(alpha: 0.03) : Colors.transparent,
        child: InkWell(
          onTap: () => _openNotification(item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                    color: _surface,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    item['asset'] as String,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      item['category'] == 1
                          ? CupertinoIcons.chat_bubble_fill
                          : CupertinoIcons.bell_fill,
                      color: item['category'] == 1 ? _blueDot : _ink,
                      size: 20,
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
                              unread ? FontWeight.w600 : FontWeight.w500,
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
                const SizedBox(width: 8),
                if (unread)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: _blueDot,
                      shape: BoxShape.circle,
                    ),
                  ),
                if (hasLink) ...[
                  const SizedBox(width: 6),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _ink : _cardBg,
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
