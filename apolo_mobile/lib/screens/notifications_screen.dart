import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/state/app_state.dart';
import '../theme/app_typography.dart';
import 'ad_detail_screen.dart';
import 'auth_screen.dart';
import 'chat_room_screen.dart';
import 'widgets/kinetic_widgets.dart';

/// 2026 Production Apple Whitespace Notifications Screen:
/// - Real backend integration with `GET /notifications`
/// - Mark all as read with server sync (`POST /notifications/read-all`)
/// - Direct deep-link navigation to real Ad or real Chat Room
/// - 3D Empty, Logged-Out, and No-Internet States
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

  static const Color _ink = Color(0xFF0F172A);
  static const Color _red = Color(0xFFE31B23);
  static const Color _surface = Color(0xFFF5F6F8);
  static const Color _muted = Color(0xFF64748B);

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
      // If network failed completely, fall back gracefully
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

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // App Bar
            SliverAppBar(
              pinned: true,
              expandedHeight: 112,
              backgroundColor: Colors.white.withValues(alpha: 0.96),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  isAr
                      ? CupertinoIcons.chevron_right
                      : CupertinoIcons.chevron_left,
                  color: _ink,
                  size: 22,
                ),
              ),
              actions: [
                if (kDebugMode)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: PressableScale(
                      onTap: () {
                        setState(() => _isOffline = !_isOffline);
                        if (!_isOffline) _loadNotifications();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _isOffline ? const Color(0xFFFEF2F2) : _surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _isOffline
                                ? const Color(0xFFFECACA)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isOffline
                                  ? CupertinoIcons.wifi_slash
                                  : CupertinoIcons.wifi,
                              size: 13,
                              color:
                                  _isOffline ? _red : const Color(0xFF475569),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _isOffline
                                  ? (isAr ? 'بدون أنترنت' : 'Hors-ligne')
                                  : (isAr ? 'متصل' : 'En ligne'),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color:
                                    _isOffline ? _red : const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (!_isOffline &&
                    _state.isLoggedIn &&
                    _items.any((e) => e['unread'] == true))
                  IconButton(
                    tooltip:
                        isAr ? 'تحديد الكل كمقروء' : 'Tout marquer comme lu',
                    onPressed: _markAllRead,
                    icon: const Icon(
                      CupertinoIcons.checkmark_circle,
                      color: _ink,
                      size: 20,
                    ),
                  ),
                const SizedBox(width: 6),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsetsDirectional.only(
                  start: 52,
                  end: 16,
                  bottom: 14,
                ),
                title: Text(
                  _state.s.tr(
                      'الإشعارات والتنبيهات', 'Notifications', 'Notifications'),
                  style: TextStyle(
                    color: _ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing:
                        AppTypography.trackingForContext(context, -0.4),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: const Color(0xFFE2E8F0)),
              ),
            ),

            // Filter Pills (Shown only if logged in & online)
            if (!_isOffline && _state.isLoggedIn && _items.isNotEmpty)
              SliverToBoxAdapter(
                child: ScrollReveal(
                  delay: const Duration(milliseconds: 60),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildFilterChip(0, isAr ? 'الكل' : 'Tout'),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            1,
                            isAr ? 'الرسائل والعروض 💰' : 'Messages & Offres',
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            2,
                            isAr ? 'نشاط الحساب والإعلانات' : 'Activité',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // 1. Logged Out State
            if (!_state.isLoggedIn)
              SliverFillRemaining(
                hasScrollBody: false,
                child: IllustratedStateView(
                  assetPath: 'assets/images/state_notifications.png',
                  fallbackIcon: CupertinoIcons.bell,
                  imageSize: 180,
                  title: isAr
                      ? 'سجل الدخول لتلقي الإشعارات'
                      : 'Connectez-vous pour voir vos alertes',
                  subtitle: isAr
                      ? 'توصل فورياً بجديد الرسائل وعروض الأسعار على إعلاناتك المعروضة للبيع.'
                      : 'Recevez en temps réel les offres et messages sur vos annonces.',
                  actionLabel: isAr
                      ? 'تسجيل الدخول / إنشاء حساب'
                      : 'Connexion / Inscription',
                  onAction: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AuthScreen(initialIsLogin: true),
                      ),
                    ).then((_) => _loadNotifications());
                  },
                ),
              )
            // 2. Offline / No Internet State
            else if (_isOffline)
              SliverFillRemaining(
                hasScrollBody: false,
                child: IllustratedStateView(
                  assetPath: 'assets/images/state_no_internet.png',
                  fallbackIcon: CupertinoIcons.wifi_slash,
                  imageSize: 184,
                  title: isAr
                      ? 'لا يوجد اتصال بالإنترنت'
                      : 'Aucune connexion Internet',
                  subtitle: isAr
                      ? 'تأكد من اتصالك بشبكة Wi-Fi أو بيانات الهاتف لتحميل آخر الإشعارات والرسائل.'
                      : 'Vérifiez votre connexion Wi-Fi ou mobile pour actualiser vos notifications.',
                  actionLabel: _isReconnecting
                      ? (isAr ? 'جاري الاتصال...' : 'Connexion...')
                      : (isAr ? 'إعادة المحاولة الآن' : 'Réessayer maintenant'),
                  onAction: _retryConnection,
                ),
              )
            // 3. Loading State
            else if (_isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(
                    color: _red,
                    strokeWidth: 2.5,
                  ),
                ),
              )
            // 4. Empty Notifications State
            else if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: IllustratedStateView(
                  assetPath: 'assets/images/state_notifications.png',
                  fallbackIcon: CupertinoIcons.bell_slash,
                  imageSize: 180,
                  title: isAr
                      ? 'لا توجد إشعارات جديدة حالياً'
                      : 'Aucune notification pour le moment',
                  subtitle: isAr
                      ? 'سنقوم بتنبيهك فور وصول رسالة من مشتري أو عند تلقي عرض سعر جديد على إعلانك.'
                      : 'Nous vous alerterons dès qu’un acheteur vous contacte ou fait une offre.',
                  actionLabel: isAr ? 'تحديث الإشعارات' : 'Actualiser',
                  onAction: _loadNotifications,
                ),
              )
            // 5. Real Notifications List
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = filtered[index];
                      final bool unread = item['unread'] == true;
                      return ScrollReveal(
                        delay: Duration(milliseconds: 60 * index),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Dismissible(
                            key: ValueKey(item['id']),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) {
                              setState(() {
                                _items
                                    .removeWhere((e) => e['id'] == item['id']);
                              });
                              _updateUnreadBadge();
                            },
                            background: Container(
                              alignment: AlignmentDirectional.centerEnd,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                CupertinoIcons.trash,
                                color: _red,
                                size: 20,
                              ),
                            ),
                            child: PressableScale(
                              onTap: () => _openNotification(item),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: unread
                                        ? _red.withValues(alpha: 0.25)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _ink.withValues(alpha: 0.03),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: _surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: Image.asset(
                                        item['asset'] as String,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                          CupertinoIcons.bell_fill,
                                          color: _red,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item['title'] as String,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: unread
                                                        ? FontWeight.w800
                                                        : FontWeight.w600,
                                                    color: _ink,
                                                    letterSpacing: AppTypography
                                                        .trackingForContext(
                                                            context, -0.2),
                                                  ),
                                                ),
                                              ),
                                              if (unread)
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: _red,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          if ((item['body'] as String)
                                              .isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              item['body'] as String,
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w500,
                                                color: _muted,
                                                height: 1.45,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 8),
                                          Text(
                                            item['time'] as String,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF94A3B8),
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
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final bool selected = _selectedFilter == index;
    return PressableScale(
      onTap: () => setState(() => _selectedFilter = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _ink : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _ink : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
