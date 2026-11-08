import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../core/state/app_state.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'post_ad_screen.dart';
import 'chat_list_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final AppState _state = AppState();
  int _currentIndex = 0;
  int? _searchInitialCategory;

  static const Color _ink = Color(0xFF0F1B2D);
  static const Color _blue = Color(0xFFE31B23); // Apolo Brand Primary Red

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
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
          setState(() {
            _searchInitialCategory = catId;
            _currentIndex = 2;
          });
        },
        onOpenPostAd: () {
          setState(() => _currentIndex = 1);
        },
      ),
      PostAdScreen(
        onSuccess: () => setState(() => _currentIndex = 0),
      ),
      SearchScreen(
        key: ValueKey(_searchInitialCategory),
        initialCategoryId: _searchInitialCategory,
      ),
      const ChatListScreen(),
      const ProfileScreen(),
    ];

    final items = [
      _TabSpec(
        icon: CupertinoIcons.house,
        activeIcon: CupertinoIcons.house_fill,
        label: s.tr('الرئيسية', 'Accueil'),
      ),
      _TabSpec(
        icon: CupertinoIcons.plus_circle,
        activeIcon: CupertinoIcons.plus_circle_fill,
        label: s.tr('نشر إعلان', 'Publier'),
      ),
      _TabSpec(
        icon: CupertinoIcons.search,
        activeIcon: CupertinoIcons.search,
        label: s.tr('إعلانات', 'Annonces'),
      ),
      _TabSpec(
        icon: CupertinoIcons.chat_bubble_2,
        activeIcon: CupertinoIcons.chat_bubble_2_fill,
        label: s.tr('رسائل', 'Messages'),
      ),
      _TabSpec(
        icon: CupertinoIcons.person,
        activeIcon: CupertinoIcons.person_fill,
        label: s.tr('حسابي', 'Profil'),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
          // Floating iOS 26 Liquid-Glass Pill Tab Bar (exact triply-ai style)
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom > 0
                ? MediaQuery.of(context).padding.bottom
                : 16,
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: _ink.withValues(alpha: 0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(
                        color: const Color(0xFFE7EAF0),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: List.generate(items.length, (idx) {
                        final item = items[idx];
                        final selected = _currentIndex == idx;
                        return Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(() => _currentIndex = idx),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFFFEECEE)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    selected ? item.activeIcon : item.icon,
                                    size: 24,
                                    color: selected ? _blue : _ink,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: selected ? _blue : _ink,
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
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
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _TabSpec({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
