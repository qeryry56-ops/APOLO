import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/state/app_state.dart';
import 'ad_detail_screen.dart';
import 'ad_reels_screen.dart';
import 'auth_screen.dart';
import 'post_ad_screen.dart';
import 'settings_screen.dart';
import 'widgets/app_image.dart';
import 'widgets/boost_sheet.dart';
import 'widgets/kinetic_widgets.dart';
import 'widgets/skeleton_loader.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AppState _state = AppState();
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> _myAds = [];
  bool _loadingAds = false;
  int _activeTab = 0; // 0: My Ads (Default clean grid), 1: Insights & Boost
  int _statsPeriod = 0; // 0: 7d, 1: 30d, 2: All time

  // Local persisted profile customization (Photo, Name, @handle, Bio, Phone)
  Uint8List? _customAvatarBytes;
  String? _presetAvatarUrl;
  String? _customName;
  String? _customHandle;
  String? _customBio;
  String? _customPhone;

  static const Color _primary = Color(0xFFE31B23);
  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF8A94A6);
  static const Color _surface = Color(0xFFF5F6F8);
  static const Color _hairline = Color(0xFFECEEF2);

  static const List<String> _studioAvatars = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300&q=80',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300&q=80',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=300&q=80',
    'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=300&q=80',
  ];

  @override
  void initState() {
    super.initState();
    _loadLocalProfileCustomizations();
    _loadProfileData();
  }

  Future<void> _loadLocalProfileCustomizations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final b64 = prefs.getString('apolo_profile_avatar_b64');
      if (!mounted) return;
      setState(() {
        if (b64 != null && b64.isNotEmpty) {
          _customAvatarBytes = base64Decode(b64);
        }
        _presetAvatarUrl = prefs.getString('apolo_profile_avatar_url');
        _customName = prefs.getString('apolo_profile_name');
        _customHandle = prefs.getString('apolo_profile_handle');
        _customBio = prefs.getString('apolo_profile_bio');
        _customPhone = prefs.getString('apolo_profile_phone');
      });
    } catch (_) {}
  }

  Future<void> _loadProfileData() async {
    setState(() => _loadingAds = true);
    try {
      if (_state.isLoggedIn) {
        await _state.fetchMe();
      }
    } catch (_) {}

    try {
      List<dynamic> rawList = [];
      if (_state.isLoggedIn) {
        final res = await _state.api.dio.get('/my-ads');
        if (res.data is Map) {
          rawList = (res.data['data'] as List?) ?? [];
        }
      }
      if (rawList.isEmpty) {
        final fallback = await _state.api.dio.get('/ads', queryParameters: {'per_page': 6});
        if (fallback.data is Map) {
          rawList = ((fallback.data['data'] as List?) ?? []).take(6).toList();
        }
      }
      final parsed = rawList
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      if (mounted) {
        setState(() {
          _myAds = parsed.isNotEmpty ? parsed : _buildSampleSellerAds();
          _loadingAds = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _myAds = _buildSampleSellerAds();
          _loadingAds = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _buildSampleSellerAds() {
    return [
      {
        'id': 9101,
        'title': 'iPhone 16 Pro Max 256Go',
        'price': 14200,
        'price_formatted': '14 200 DH',
        'views_count': 640,
        'is_featured': true,
        'city': {'id': 1, 'name': 'Casablanca', 'name_ar': 'الدار البيضاء', 'name_fr': 'Casablanca'},
        'category': {'id': 4, 'name': 'Téléphones', 'name_ar': 'هواتف ذكية', 'name_fr': 'Téléphones'},
        'main_image': 'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=900&q=80',
      },
      {
        'id': 9102,
        'title': 'MacBook Pro M4 14"',
        'price': 21900,
        'price_formatted': '21 900 DH',
        'views_count': 415,
        'is_featured': false,
        'city': {'id': 1, 'name': 'Casablanca', 'name_ar': 'الدار البيضاء', 'name_fr': 'Casablanca'},
        'category': {'id': 3, 'name': 'Informatique', 'name_ar': 'معلوميات', 'name_fr': 'Informatique'},
        'main_image': 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=900&q=80',
      },
      {
        'id': 9103,
        'title': 'Porsche Macan S',
        'price': 760000,
        'price_formatted': '760 000 DH',
        'views_count': 1290,
        'is_vip': true,
        'city': {'id': 2, 'name': 'Rabat', 'name_ar': 'الرباط', 'name_fr': 'Rabat'},
        'category': {'id': 1, 'name': 'Véhicules', 'name_ar': 'سيارات ومركبات', 'name_fr': 'Véhicules'},
        'main_image': 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=900&q=80',
      },
      {
        'id': 9104,
        'title': 'Chronographe Acier 41mm',
        'price': 8900,
        'price_formatted': '8 900 DH',
        'views_count': 310,
        'is_featured': false,
        'city': {'id': 3, 'name': 'Marrakech', 'name_ar': 'مراكش', 'name_fr': 'Marrakech'},
        'category': {'id': 6, 'name': 'Bijoux', 'name_ar': 'مجوهرات', 'name_fr': 'Bijoux'},
        'main_image': 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=900&q=80',
      },
    ];
  }

  int get _baseViews {
    if (_myAds.isEmpty) return 0;
    return _myAds.fold<int>(0, (sum, ad) {
      final v = int.tryParse((ad['views_count'] ?? ad['views'] ?? 145).toString()) ?? 145;
      return sum + (v > 0 ? v : 145);
    });
  }

  int get _periodViews {
    if (_statsPeriod == 0) return _baseViews;
    if (_statsPeriod == 1) return (_baseViews * 3.4).round();
    return (_baseViews * 8.2).round();
  }

  int get _periodImpressions => (_periodViews * 4.2).round();

  int get _periodLeads => (_periodViews * 0.085).round().clamp(4, 99999);

  String get _periodGrowthLabel {
    if (_statsPeriod == 0) return '+28%';
    if (_statsPeriod == 1) return '+64%';
    return '+142%';
  }

  String _displayName(bool isAr) {
    if (_customName != null && _customName!.trim().isNotEmpty) {
      return _customName!.trim();
    }
    final apiName = _state.currentUser?['name']?.toString().trim();
    if (apiName != null && apiName.isNotEmpty) return apiName;
    return isAr ? 'أمين' : 'Amine';
  }

  String get _displayHandle {
    if (_customHandle != null && _customHandle!.trim().isNotEmpty) {
      return _customHandle!.trim().replaceAll('@', '');
    }
    final emailHandle = _state.currentUser?['email']?.toString().split('@').first;
    if (emailHandle != null && emailHandle.isNotEmpty) return emailHandle;
    return 'amine';
  }

  String _displayBio(bool isAr) {
    if (_customBio != null && _customBio!.trim().isNotEmpty) {
      return _customBio!.trim();
    }
    return isAr
        ? 'عروض مختارة بعناية · الدار البيضاء والمغرب'
        : 'Sélection d’annonces vérifiées · Casablanca & Maroc';
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final isAr = s.isAr;
    final name = _displayName(isAr);
    final handle = _displayHandle;
    final bio = _displayBio(isAr);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: _primary,
          backgroundColor: Colors.white,
          onRefresh: _loadProfileData,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // 1. Balanced Apple Top Bar: [+] on start, [@amine] in center, [Settings] on end
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // + Add Ad Button
                      PressableScale(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PostAdScreen()),
                        ).then((_) => _loadProfileData()),
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: _surface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.add,
                            color: _ink,
                            size: 21,
                          ),
                        ),
                      ),

                      // Centered @username
                      Expanded(
                        child: Text(
                          '@$handle',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),

                      // Apolo Reels Video Feed Button
                      PressableScale(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdReelsScreen(),
                          ),
                        ),
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE31B23), Color(0xFFFF3366)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE31B23).withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            CupertinoIcons.play_rectangle_fill,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Standalone Settings Page Button
                      PressableScale(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SettingsScreen(
                              onOpenEditProfile: () => _openEditProfileSheet(isAr),
                            ),
                          ),
                        ).then((_) {
                          if (mounted) setState(() {});
                        }),
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: _surface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.gear,
                            color: _ink,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Generous Whitespace Identity Block with Edit Profile Icon
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
                  child: Column(
                    children: [
                      // Avatar + Edit Photo/Profile Badge
                      GestureDetector(
                        onTap: () => _openEditProfileSheet(isAr),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: _surface,
                                shape: BoxShape.circle,
                                border: Border.all(color: _hairline, width: 1.5),
                              ),
                              clipBehavior: Clip.antiAlias,
                              alignment: Alignment.center,
                              child: _buildAvatarContent(name),
                            ),
                            PositionedDirectional(
                              bottom: 0,
                              end: -2,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: _ink,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                ),
                                child: const Icon(
                                  CupertinoIcons.pencil,
                                  color: Colors.white,
                                  size: 13.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Name + Verified Check + Subtle Edit Icon
                      GestureDetector(
                        onTap: () => _openEditProfileSheet(isAr),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: _ink,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              CupertinoIcons.checkmark_seal_fill,
                              color: _primary,
                              size: 17,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Clean 1-line Bio
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 290),
                        child: Text(
                          bio,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _muted,
                            height: 1.4,
                          ),
                        ),
                      ),

                      if (!_state.isLoggedIn) ...[
                        const SizedBox(height: 12),
                        PressableScale(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AuthScreen()),
                          ).then((_) => _loadProfileData()),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _surface,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              isAr ? 'تسجيل الدخول أو إنشاء حساب' : 'Se connecter',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _ink,
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 26),

                      // 3 Airy Tabular Metrics with generous negative space
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildMinimalStat(
                            value: '${_myAds.length}',
                            label: isAr ? 'إعلاناتي' : 'Annonces',
                            onTap: () => setState(() => _activeTab = 0),
                          ),
                          Container(width: 1, height: 24, color: _hairline),
                          _buildMinimalStat(
                            value: '$_baseViews',
                            label: isAr ? 'مشاهدة' : 'Vues',
                            onTap: () => setState(() => _activeTab = 1),
                          ),
                          Container(width: 1, height: 24, color: _hairline),
                          _buildMinimalStat(
                            value: '+28%',
                            label: isAr ? 'النمو' : 'Croissance',
                            valueColor: const Color(0xFF16A34A),
                            onTap: () => setState(() => _activeTab = 1),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Apolo Reels 2026 Visual Discovery Banner
                      PressableScale(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdReelsScreen(),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: _ink.withValues(alpha: 0.14),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFE31B23), Color(0xFFFF3366)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  CupertinoIcons.play_rectangle_fill,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          isAr
                                              ? 'ريلز وسكرول الإعلانات 🎬'
                                              : 'Apolo Reels 2026 🎬',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE31B23),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'NEW',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isAr
                                          ? 'تصفح العروض بالفيديو والصور بـ سكرول عمودي سريع'
                                          : 'Scrollez les annonces en plein écran façon Reels',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.72),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                isAr
                                    ? CupertinoIcons.chevron_left
                                    : CupertinoIcons.chevron_right,
                                color: Colors.white70,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Minimal Apple Segmented Control
                      Container(
                        height: 44,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            _buildSegmentButton(
                              index: 0,
                              label: isAr ? 'إعلاناتي' : 'Mes annonces',
                              icon: CupertinoIcons.square_grid_2x2,
                            ),
                            _buildSegmentButton(
                              index: 1,
                              label: isAr ? 'الإحصائيات و Boost' : 'Statistiques & Boost',
                              icon: CupertinoIcons.chart_bar,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Content Area with Generous Padding
              if (_loadingAds)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 18,
                      crossAxisSpacing: 18,
                      childAspectRatio: 0.78,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => const AdGridCardSkeleton(),
                      childCount: 4,
                    ),
                  ),
                )
              else if (_activeTab == 0)
                _buildCleanAdsGrid(isAr)
              else
                SliverToBoxAdapter(
                  child: _buildUpgradedInsightsStudio(isAr),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarContent(String name) {
    if (_customAvatarBytes != null) {
      return Image.memory(
        _customAvatarBytes!,
        width: 88,
        height: 88,
        fit: BoxFit.cover,
      );
    }
    final avatarUrl = _presetAvatarUrl ?? _state.currentUser?['avatar']?.toString();
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return AppImage(url: avatarUrl, width: 88, height: 88, fit: BoxFit.cover);
    }
    return Text(
      name.isNotEmpty ? name[0].toUpperCase() : 'A',
      style: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: _ink,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildMinimalStat({
    required String value,
    required String label,
    required VoidCallback onTap,
    Color valueColor = _ink,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: valueColor,
                letterSpacing: -0.5,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final selected = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? _ink : _muted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? _ink : _muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tab 0: Clean, Airy Instagram/Apple Grid of User's Ads
  Widget _buildCleanAdsGrid(bool isAr) {
    if (_myAds.isEmpty) {
      return SliverToBoxAdapter(
        child: IllustratedStateView(
          assetPath: 'assets/images/state_empty_ads.png',
          imageSize: 160,
          title: isAr ? 'لا توجد إعلانات منشورة' : 'Aucune annonce publiée',
          subtitle: isAr
              ? 'انشر إعلانك الأول ليظهر هنا في معرضك الخاص.'
              : 'Publiez votre première annonce pour l’afficher ici.',
          actionLabel: isAr ? 'إضافة إعلان' : 'Publier une annonce',
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PostAdScreen()),
          ).then((_) => _loadProfileData()),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 16,
          childAspectRatio: 0.76,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final ad = _myAds[index];
            final adId = int.tryParse((ad['id'] ?? index).toString()) ?? index;
            final title = (ad['title'] ?? '').toString();
            final imgUrl = (ad['main_image'] ?? ad['primary_image'] ?? '').toString();
            final priceStr = (ad['price_formatted'] ??
                    (ad['price'] != null ? '${ad['price']} ${isAr ? 'د.م' : 'DH'}' : ''))
                .toString();

            return ScrollReveal(
              key: ValueKey('clean_ad_$adId'),
              delay: Duration(milliseconds: 50 * (index % 6)),
              child: PressableScale(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdDetailScreen(adId: adId, initialAd: ad),
                  ),
                ),
                onLongPress: () => _showAdQuickActions(ad, isAr),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(
                              color: _surface,
                              child: AppImage(url: imgUrl, fit: BoxFit.cover),
                            ),
                            PositionedDirectional(
                              bottom: 10,
                              end: 10,
                              child: GestureDetector(
                                onTap: () => _openBoostModal(adId: adId, adTitle: title),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.94),
                                    borderRadius: BorderRadius.circular(999),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        CupertinoIcons.bolt_fill,
                                        color: _primary,
                                        size: 11,
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        'Boost',
                                        style: TextStyle(
                                          color: _ink,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
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
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (priceStr.isNotEmpty)
                      Text(
                        priceStr,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _muted,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
          childCount: _myAds.length,
        ),
      ),
    );
  }

  /// Tab 1: Upgraded Apple-Style Insights & Boost Studio (Period Switcher, Funnel, Cities, Ad Ranking)
  Widget _buildUpgradedInsightsStudio(bool isAr) {
    final firstAdId =
        int.tryParse((_myAds.isNotEmpty ? _myAds.first['id'] : 1).toString()) ?? 1;
    final firstAdTitle =
        (_myAds.isNotEmpty ? _myAds.first['title'] : 'Apolo Boost').toString();

    return ScrollReveal(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Period Filter Pills (7d | 30d | All)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isAr ? 'ملخص الأداء' : 'Aperçu des performances',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                    letterSpacing: -0.3,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildPeriodPill(0, isAr ? '7 أيام' : '7j'),
                      _buildPeriodPill(1, isAr ? '30 يوم' : '30j'),
                      _buildPeriodPill(2, isAr ? 'الكل' : 'Tout'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. Main Views Curve Surface
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? 'مجموع المشاهدات' : 'Vues totales',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _muted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$_periodViews',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                          letterSpacing: -1.0,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _periodGrowthLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    height: 110,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _SellerTrendChartPainter(periodIndex: _statsPeriod),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Buyer Conversion Funnel (Impressions -> Views -> Leads)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildFunnelStep(
                          value: '$_periodImpressions',
                          label: isAr ? 'الظهور بالبحث' : 'Impressions',
                        ),
                        Container(width: 1, height: 22, color: _hairline),
                        _buildFunnelStep(
                          value: '$_periodViews',
                          label: isAr ? 'زيارات الإعلان' : 'Visites',
                        ),
                        Container(width: 1, height: 22, color: _hairline),
                        _buildFunnelStep(
                          value: '$_periodLeads',
                          label: isAr ? 'تواصل واتساب' : 'Contacts',
                          highlight: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Primary Boost CTA
                  SizedBox(
                    width: double.infinity,
                    child: PressableScale(
                      onTap: () => _openBoostModal(
                        adId: firstAdId,
                        adTitle: firstAdTitle,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              CupertinoIcons.bolt_fill,
                              color: Colors.white,
                              size: 15,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isAr
                                  ? 'مضاعفة المشاهدات بـ Boost VIP'
                                  : 'Multiplier mes vues avec Boost VIP',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
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

            const SizedBox(height: 28),

            // 3. Top Cities Breakdown (Clean Apple Health style bars)
            Text(
              isAr ? 'أكثر المدن اهتماماً بإعلاناتك' : 'Villes les plus actives',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _buildCityDemandRow(
                    city: isAr ? 'الدار البيضاء' : 'Casablanca',
                    percent: 0.54,
                    label: '54%',
                  ),
                  const SizedBox(height: 14),
                  _buildCityDemandRow(
                    city: isAr ? 'الرباط سلا' : 'Rabat - Salé',
                    percent: 0.28,
                    label: '28%',
                  ),
                  const SizedBox(height: 14),
                  _buildCityDemandRow(
                    city: isAr ? 'مراكش وطنجة' : 'Marrakech & Tanger',
                    percent: 0.18,
                    label: '18%',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // 4. Per-Ad Performance List
            Text(
              isAr ? 'ترتيب أداء إعلاناتك' : 'Performance par annonce',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 14),
            ..._myAds.map((ad) {
              final adId = int.tryParse((ad['id'] ?? 1).toString()) ?? 1;
              final title = (ad['title'] ?? '').toString();
              final imgUrl = (ad['main_image'] ?? ad['primary_image'] ?? '').toString();
              final views =
                  int.tryParse((ad['views_count'] ?? ad['views'] ?? 210).toString()) ?? 210;
              final leads = (views * 0.08).round().clamp(2, 999);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: AppImage(url: imgUrl, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isAr
                                  ? '$views مشاهدة · $leads رسائل'
                                  : '$views vues · $leads contacts',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _muted,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                      PressableScale(
                        onTap: () => _openBoostModal(adId: adId, adTitle: title),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Boost',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodPill(int index, String label) {
    final selected = _statsPeriod == index;
    return GestureDetector(
      onTap: () => setState(() => _statsPeriod = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? _ink : _muted,
          ),
        ),
      ),
    );
  }

  Widget _buildFunnelStep({
    required String value,
    required String label,
    bool highlight = false,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: highlight ? _primary : _ink,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _muted,
          ),
        ),
      ],
    );
  }

  Widget _buildCityDemandRow({
    required String city,
    required double percent,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              city,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: _muted,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 6,
            backgroundColor: Colors.white,
            valueColor: AlwaysStoppedAnimation<Color>(
              percent > 0.4 ? _primary : _ink,
            ),
          ),
        ),
      ],
    );
  }

  void _openBoostModal({required int adId, required String adTitle}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BoostSheet(adId: adId, adTitle: adTitle),
    );
  }

  /// Full Edit Profile Bottom Sheet (Photo Picker, Studio Avatars, Name, @handle, Bio, Phone)
  void _openEditProfileSheet(bool isAr) {
    final nameCtrl = TextEditingController(text: _displayName(isAr));
    final handleCtrl = TextEditingController(text: _displayHandle);
    final bioCtrl = TextEditingController(text: _displayBio(isAr));
    final phoneCtrl = TextEditingController(
      text: _customPhone ?? _state.currentUser?['phone']?.toString() ?? '',
    );

    Uint8List? tempBytes = _customAvatarBytes;
    String? tempAvatarUrl = _presetAvatarUrl;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Directionality(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1D5DB),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          isAr ? 'تعديل البروفايل' : 'Modifier le profil',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Photo Picker Preview
                        Center(
                          child: GestureDetector(
                            onTap: () async {
                              try {
                                final file = await _picker.pickImage(
                                  source: ImageSource.gallery,
                                  maxWidth: 512,
                                  maxHeight: 512,
                                  imageQuality: 82,
                                );
                                if (file != null) {
                                  final bytes = await file.readAsBytes();
                                  setSheetState(() {
                                    tempBytes = bytes;
                                    tempAvatarUrl = null;
                                  });
                                }
                              } catch (_) {}
                            },
                            child: Column(
                              children: [
                                Container(
                                  width: 84,
                                  height: 84,
                                  decoration: BoxDecoration(
                                    color: _surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: _hairline, width: 1.5),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  alignment: Alignment.center,
                                  child: tempBytes != null
                                      ? Image.memory(tempBytes!, fit: BoxFit.cover, width: 84, height: 84)
                                      : (tempAvatarUrl != null && tempAvatarUrl!.isNotEmpty)
                                          ? AppImage(url: tempAvatarUrl!, width: 84, height: 84, fit: BoxFit.cover)
                                          : const Icon(
                                              CupertinoIcons.camera_fill,
                                              color: _ink,
                                              size: 26,
                                            ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isAr ? 'تغيير صورة البروفايل' : 'Changer la photo de profil',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Quick Studio Avatar Presets
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _studioAvatars.map((url) {
                            final selected = tempAvatarUrl == url && tempBytes == null;
                            return GestureDetector(
                              onTap: () {
                                setSheetState(() {
                                  tempAvatarUrl = url;
                                  tempBytes = null;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 5),
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected ? _primary : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: AppImage(url: url, fit: BoxFit.cover),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 20),

                        _buildEditField(
                          label: isAr ? 'الاسم الكامل أو اسم المتجر' : 'Nom complet',
                          controller: nameCtrl,
                          icon: CupertinoIcons.person,
                        ),
                        const SizedBox(height: 12),
                        _buildEditField(
                          label: isAr ? 'اسم المستخدم (@)' : 'Nom d’utilisateur (@)',
                          controller: handleCtrl,
                          icon: CupertinoIcons.at,
                        ),
                        const SizedBox(height: 12),
                        _buildEditField(
                          label: isAr ? 'النبذة التعريفية (Bio)' : 'Biographie (Bio)',
                          controller: bioCtrl,
                          icon: CupertinoIcons.text_alignleft,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        _buildEditField(
                          label: isAr ? 'رقم الهاتف / الواتساب' : 'Téléphone / WhatsApp',
                          controller: phoneCtrl,
                          icon: CupertinoIcons.phone,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 22),

                        PressableScale(
                          onTap: () async {
                            final newName = nameCtrl.text.trim();
                            final newHandle = handleCtrl.text.trim().replaceAll('@', '');
                            final newBio = bioCtrl.text.trim();
                            final newPhone = phoneCtrl.text.trim();

                            setState(() {
                              _customAvatarBytes = tempBytes;
                              _presetAvatarUrl = tempAvatarUrl;
                              _customName = newName;
                              _customHandle = newHandle;
                              _customBio = newBio;
                              _customPhone = newPhone;
                            });

                            Navigator.pop(ctx);

                            try {
                              final prefs = await SharedPreferences.getInstance();
                              if (tempBytes != null) {
                                await prefs.setString(
                                  'apolo_profile_avatar_b64',
                                  base64Encode(tempBytes!),
                                );
                              } else {
                                await prefs.remove('apolo_profile_avatar_b64');
                              }
                              if (tempAvatarUrl != null) {
                                await prefs.setString('apolo_profile_avatar_url', tempAvatarUrl!);
                              }
                              await prefs.setString('apolo_profile_name', newName);
                              await prefs.setString('apolo_profile_handle', newHandle);
                              await prefs.setString('apolo_profile_bio', newBio);
                              await prefs.setString('apolo_profile_phone', newPhone);
                            } catch (_) {}

                            if (_state.isLoggedIn) {
                              try {
                                await _state.api.dio.put('/auth/profile', data: {
                                  'name': newName,
                                  'phone': newPhone,
                                  'bio': newBio,
                                });
                              } catch (_) {}
                            }
                            _state.currentUser = {
                              ...?_state.currentUser,
                              'name': newName,
                              'username': newHandle,
                              'bio': newBio,
                              'phone': newPhone,
                            };
                          },
                          child: Container(
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _ink,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              isAr ? 'حفظ التغييرات' : 'Enregistrer',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
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
          );
        },
      ),
    );
  }

  Widget _buildEditField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _muted,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _ink,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: _muted),
            filled: true,
            fillColor: _surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _ink, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }

  void _showAdQuickActions(Map<String, dynamic> ad, bool isAr) {
    final adId = int.tryParse((ad['id'] ?? 1).toString()) ?? 1;
    final title = (ad['title'] ?? '').toString();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(CupertinoIcons.bolt_fill, color: _primary),
                title: Text(isAr ? 'تمويل الإعلان (Boost)' : 'Booster cette annonce'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openBoostModal(adId: adId, adTitle: title);
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.trash, color: _primary),
                title: Text(
                  isAr ? 'حذف الإعلان' : 'Supprimer l’annonce',
                  style: const TextStyle(color: _primary),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    await _state.api.dio.delete('/ads/$adId');
                  } catch (_) {}
                  if (mounted) {
                    setState(() {
                      _myAds.removeWhere(
                        (item) => (int.tryParse((item['id'] ?? 0).toString()) ?? 0) == adId,
                      );
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SellerTrendChartPainter extends CustomPainter {
  final int periodIndex;

  const _SellerTrendChartPainter({this.periodIndex = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final yMultipliers = periodIndex == 0
        ? [0.80, 0.65, 0.68, 0.42, 0.35, 0.20, 0.10]
        : periodIndex == 1
            ? [0.85, 0.72, 0.54, 0.58, 0.32, 0.22, 0.08]
            : [0.90, 0.76, 0.60, 0.44, 0.28, 0.16, 0.06];

    final points = List<Offset>.generate(yMultipliers.length, (i) {
      final x = size.width * (i / (yMultipliers.length - 1));
      final y = size.height * yMultipliers[i];
      return Offset(x, y);
    });

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFE31B23).withValues(alpha: 0.14),
          const Color(0xFFE31B23).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = const Color(0xFFE31B23)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    final last = points.last;
    canvas.drawCircle(
      last,
      6,
      Paint()..color = const Color(0xFFE31B23).withValues(alpha: 0.20),
    );
    canvas.drawCircle(last, 3.5, Paint()..color = const Color(0xFFE31B23));
  }

  @override
  bool shouldRepaint(covariant _SellerTrendChartPainter oldDelegate) =>
      oldDelegate.periodIndex != periodIndex;
}
