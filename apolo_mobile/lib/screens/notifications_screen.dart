import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../core/state/app_state.dart';
import 'widgets/kinetic_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  final bool initialSimulateOffline;
  const NotificationsScreen({super.key, this.initialSimulateOffline = false});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final AppState _state = AppState();
  int _selectedFilter = 0; // 0: All, 1: Offers/Messages, 2: Activity
  late bool _isOffline;
  bool _isReconnecting = false;

  late List<Map<String, dynamic>> _items;

  @override
  void initState() {
    super.initState();
    _isOffline = widget.initialSimulateOffline;
    _items = _buildInitialNotifications();
  }

  List<Map<String, dynamic>> _buildInitialNotifications() {
    final isAr = _state.s.isAr;
    return [
      {
        'id': 'n1',
        'category': 1,
        'unread': true,
        'title': isAr ? 'عرض شراء جديد على إعلانك' : 'Nouvelle offre sur votre annonce',
        'body': isAr
            ? 'أرسل لك Yassine B. عرضاً بخصوص هاتف iPhone 16 Pro Max — اضغط للرد السريع.'
            : 'Yassine B. vous a envoyé une proposition concernant votre annonce.',
        'time': isAr ? 'منذ 4 دقائق' : 'Il y a 4 min',
        'asset': 'assets/images/cat_phones.png',
        'accent': const Color(0xFFE31B23),
      },
      {
        'id': 'n2',
        'category': 2,
        'unread': true,
        'title': isAr ? 'إعلانك يحقق تفاعلاً عالياً اليوم' : 'Votre annonce attire plus d’acheteurs',
        'body': isAr
            ? 'ارتفعت مشاهدات إعلاناتك بنسبة +28% هذا الأسبوع في الدار البيضاء والرباط.'
            : 'Vos annonces ont enregistré +28% de vues cette semaine à Casablanca.',
        'time': isAr ? 'منذ ساعتين' : 'Il y a 2 h',
        'asset': 'assets/images/cat_computers.png',
        'accent': const Color(0xFF0F172A),
      },
      {
        'id': 'n3',
        'category': 1,
        'unread': false,
        'title': isAr ? 'تخفيض السعر في اهتماماتك' : 'Baisse de prix dans vos favoris',
        'body': isAr
            ? 'تم تخفيض سعر سيارة مطابقة لبحثك في قسم السيارات بنسبة 8%.'
            : 'Un véhicule correspondant à vos recherches a baissé de 8%.',
        'time': isAr ? 'أمس' : 'Hier',
        'asset': 'assets/images/hero_car.png',
        'accent': const Color(0xFF16A34A),
      },
    ];
  }

  List<Map<String, dynamic>> get _filteredItems {
    if (_selectedFilter == 0) return _items;
    return _items.where((item) => item['category'] == _selectedFilter).toList();
  }

  Future<void> _retryConnection() async {
    setState(() => _isReconnecting = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _isReconnecting = false;
      _isOffline = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = _state.s.isAr;
    final filtered = _filteredItems;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 112,
              backgroundColor: Colors.white.withValues(alpha: 0.95),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  isAr ? CupertinoIcons.chevron_right : CupertinoIcons.chevron_left,
                  color: const Color(0xFF0F172A),
                  size: 22,
                ),
              ),
              actions: [
                // Quick toggle to test Offline / No-Internet 3D PNG state vs Live state
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: PressableScale(
                    onTap: () => setState(() => _isOffline = !_isOffline),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isOffline
                            ? const Color(0xFFFEF2F2)
                            : const Color(0xFFF1F5F9),
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
                            size: 14,
                            color: _isOffline
                                ? const Color(0xFFE31B23)
                                : const Color(0xFF475569),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isOffline
                                ? (isAr ? 'بدون أنترنت' : 'Hors-ligne')
                                : (isAr ? 'متصل' : 'En ligne'),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: _isOffline
                                  ? const Color(0xFFE31B23)
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!_isOffline && _items.isNotEmpty)
                  IconButton(
                    tooltip: isAr ? 'تحديد الكل كمقروء' : 'Tout marquer comme lu',
                    onPressed: () {
                      setState(() {
                        for (final item in _items) {
                          item['unread'] = false;
                        }
                      });
                    },
                    icon: const Icon(
                      CupertinoIcons.checkmark_circle,
                      color: Color(0xFF0F172A),
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
                  isAr ? 'الإشعارات والتنبيهات' : 'Notifications',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: const Color(0xFFE2E8F0)),
              ),
            ),

            // Filter Pills
            if (!_isOffline)
              SliverToBoxAdapter(
                child: ScrollReveal(
                  delay: const Duration(milliseconds: 60),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildFilterChip(0, isAr ? 'الكل' : 'Tout'),
                          const SizedBox(width: 8),
                          _buildFilterChip(1, isAr ? 'الرسائل والعروض' : 'Messages & Offres'),
                          const SizedBox(width: 8),
                          _buildFilterChip(2, isAr ? 'نشاط حسابي' : 'Activité'),
                          const SizedBox(width: 8),
                          if (_items.isNotEmpty)
                            PressableScale(
                              onTap: () => setState(() => _items.clear()),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Text(
                                  isAr ? 'مسح الكل' : 'Effacer tout',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
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

            // Offline / No-Internet Illustrated State
            if (_isOffline)
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
                      ? 'تأكد من اتصالك بشبكة Wi-Fi أو بيانات الهاتف لتحميل آخر الإشعارات والرسائل الفورية.'
                      : 'Vérifiez votre connexion Wi-Fi ou données mobiles pour actualiser vos notifications en temps réel.',
                  actionLabel: _isReconnecting
                      ? (isAr ? 'جاري الاتصال...' : 'Connexion...')
                      : (isAr ? 'إعادة المحاولة الآن' : 'Réessayer maintenant'),
                  onAction: _retryConnection,
                ),
              )
            // Empty Notifications Illustrated State
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
                      ? 'سنقوم بتنبيهك فور وصول رسالة من مشتري أو عند نزول عروض جديدة تناسب اهتماماتك.'
                      : 'Nous vous alerterons dès qu’un acheteur vous contacte ou qu’une offre correspond à vos favoris.',
                  actionLabel: isAr ? 'استرجاع الإشعارات التجريبية' : 'Actualiser les alertes',
                  onAction: () {
                    setState(() {
                      _items = _buildInitialNotifications();
                      _selectedFilter = 0;
                    });
                  },
                  secondaryLabel: isAr
                      ? 'معاينة حالة انقطاع الإنترنت (No Internet PNG)'
                      : 'Voir l’état Hors-ligne (No Internet PNG)',
                  onSecondary: () => setState(() => _isOffline = true),
                ),
              )
            // Notifications List with Staggered Scroll Reveal
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = filtered[index];
                      final bool unread = item['unread'] == true;
                      return ScrollReveal(
                        delay: Duration(milliseconds: 70 * index),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Dismissible(
                            key: ValueKey(item['id']),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) {
                              setState(() {
                                _items.removeWhere((e) => e['id'] == item['id']);
                              });
                            },
                            background: Container(
                              alignment: AlignmentDirectional.centerEnd,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                CupertinoIcons.trash,
                                color: Color(0xFFE31B23),
                                size: 20,
                              ),
                            ),
                            child: PressableScale(
                              onTap: () {
                                setState(() => item['unread'] = false);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: unread
                                        ? const Color(0xFFE31B23).withValues(alpha: 0.25)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFF1F5F9),
                                        ),
                                      ),
                                      child: Image.asset(
                                        item['asset'] as String,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => const Icon(
                                          CupertinoIcons.bell_fill,
                                          color: Color(0xFFE31B23),
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                                    color: const Color(0xFF0F172A),
                                                    letterSpacing: -0.2,
                                                  ),
                                                ),
                                              ),
                                              if (unread)
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFFE31B23),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item['body'] as String,
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF64748B),
                                              height: 1.45,
                                            ),
                                          ),
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
          color: selected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
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
