import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../core/state/app_state.dart';
import '../theme/app_typography.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'post_ad_screen.dart';
import 'chat_list_screen.dart';
import 'profile_screen.dart';
import 'widgets/kinetic_widgets.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final AppState _state = AppState();
  int _currentIndex = 0;
  int? _searchInitialCategory;
  bool _searchChromeVisible = true;

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

  void _handleSearchChromeVisibility(bool visible) {
    if (_searchChromeVisible != visible && mounted) {
      setState(() => _searchChromeVisible = visible);
    }
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
            _searchChromeVisible = true;
            _currentIndex = 2;
          });
        },
        onOpenPostAd: () {
          setState(() {
            _searchChromeVisible = true;
            _currentIndex = 1;
          });
        },
      ),
      PostAdScreen(
        onSuccess: () => setState(() {
          _searchChromeVisible = true;
          _currentIndex = 0;
        }),
      ),
      SearchScreen(
        key: ValueKey(_searchInitialCategory),
        initialCategoryId: _searchInitialCategory,
        onChromeVisibilityChanged: _handleSearchChromeVisibility,
      ),
      ChatListScreen(
        onExploreAds: () => setState(() {
          _searchChromeVisible = true;
          _currentIndex = 2;
        }),
      ),
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

    final showBottomBar = _currentIndex != 2 || _searchChromeVisible;

    return Scaffold(
      backgroundColor: Colors.white,
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
          // Floating iOS 26 Liquid-Glass Pill Tab Bar (auto-hides during Explore scroll)
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom > 0
                ? MediaQuery.of(context).padding.bottom
                : 16,
            child: IgnorePointer(
              ignoring: !showBottomBar,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                offset: showBottomBar ? Offset.zero : const Offset(0, 1.8),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: showBottomBar ? 1.0 : 0.0,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 6,
                          ),
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
                                child: PressableScale(
                                  onTap: () {
                                    if (_currentIndex == idx) {
                                      _state.notifyTabReselected();
                                    } else {
                                      setState(() {
                                        _searchChromeVisible = true;
                                        _currentIndex = idx;
                                      });
                                    }
                                  },
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minWidth: 44,
                                      minHeight: 44,
                                    ),
                                    child: Semantics(
                                      button: true,
                                      selected: selected,
                                      label: item.label,
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        curve: Curves.easeOutCubic,
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? const Color(0xFFFEECEE)
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              selected
                                                  ? item.activeIcon
                                                  : item.icon,
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
                                                letterSpacing: AppTypography
                                                    .trackingForContext(
                                                  context,
                                                  -0.1,
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
                            }),
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
