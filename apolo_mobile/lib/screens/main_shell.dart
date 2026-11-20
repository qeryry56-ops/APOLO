import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/state/app_state.dart';
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
  int _lastPillSlot = 0;
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
            _lastPillSlot = 1;
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
          _lastPillSlot = 0;
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
          _lastPillSlot = 1;
        }),
      ),
      const ProfileScreen(),
    ];

    final pillItems = [
      _TabSpec(
        pageIndex: 0,
        icon: CupertinoIcons.house,
        activeIcon: CupertinoIcons.house_fill,
        label: s.tr('الرئيسية', 'Accueil'),
      ),
      _TabSpec(
        pageIndex: 2,
        icon: CupertinoIcons.compass,
        activeIcon: CupertinoIcons.compass_fill,
        label: s.tr('إعلانات', 'Annonces'),
      ),
      _TabSpec(
        pageIndex: 3,
        icon: CupertinoIcons.chat_bubble_2,
        activeIcon: CupertinoIcons.chat_bubble_2_fill,
        label: s.tr('رسائل', 'Messages'),
      ),
      _TabSpec(
        pageIndex: 4,
        icon: CupertinoIcons.person,
        activeIcon: CupertinoIcons.person_fill,
        label: s.tr('حسابي', 'Profil'),
      ),
    ];

    final activePillSlot =
        pillItems.indexWhere((e) => e.pageIndex == _currentIndex);
    final displaySlot = activePillSlot >= 0 ? activePillSlot : _lastPillSlot;
    final showBottomBar = _currentIndex != 2 || _searchChromeVisible;
    final isPostAdSelected = _currentIndex == 1;

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
          // Floating iOS Split Pill Dock + Detached Plus Button (auto-hides during Explore scroll)
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom > 0
                ? MediaQuery.of(context).padding.bottom
                : 16,
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
                  child: SizedBox(
                    height: 62,
                    child: Row(
                      textDirection: TextDirection.ltr,
                      children: [
                        // Left Expanded Translucent Glass Capsule Pill (4 main tabs)
                        Expanded(
                          child: Container(
                            height: 62,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: _ink.withValues(alpha: 0.10),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.76),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: const Color(0xFFE7EAF0)
                                          .withValues(alpha: 0.85),
                                      width: 1,
                                    ),
                                  ),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final slotWidth = constraints.maxWidth /
                                          pillItems.length;
                                      final slotHeight = constraints.maxHeight;
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
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 180),
                                              decoration: BoxDecoration(
                                                color: activePillSlot >= 0
                                                    ? const Color(0xFFE9EBF0)
                                                        .withValues(alpha: 0.85)
                                                    : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                            ),
                                          ),
                                          Row(
                                            textDirection: TextDirection.ltr,
                                            children: List.generate(
                                              pillItems.length,
                                              (idx) {
                                                final item = pillItems[idx];
                                                final selected =
                                                    _currentIndex ==
                                                        item.pageIndex;
                                                return Expanded(
                                                  child: PressableScale(
                                                    onTap: () {
                                                      HapticFeedback
                                                          .selectionClick();
                                                      if (_currentIndex ==
                                                          item.pageIndex) {
                                                        _state
                                                            .notifyTabReselected();
                                                      } else {
                                                        setState(() {
                                                          _searchChromeVisible =
                                                              true;
                                                          _currentIndex =
                                                              item.pageIndex;
                                                          _lastPillSlot = idx;
                                                        });
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
                                                          height: slotHeight,
                                                          child: Center(
                                                            child: Icon(
                                                              selected
                                                                  ? item
                                                                      .activeIcon
                                                                  : item.icon,
                                                              size: 24,
                                                              color: selected
                                                                  ? _blue
                                                                  : _ink,
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
                        const SizedBox(width: 12),
                        // Right Detached Circular Glass "+" Button (Post Ad)
                        PressableScale(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            if (_currentIndex == 1) {
                              _state.notifyTabReselected();
                            } else {
                              setState(() {
                                _searchChromeVisible = true;
                                _currentIndex = 1;
                              });
                            }
                          },
                          child: Semantics(
                            button: true,
                            selected: isPostAdSelected,
                            label: s.tr('نشر إعلان', 'Publier'),
                            child: Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _ink.withValues(alpha: 0.10),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.76),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFE7EAF0)
                                            .withValues(alpha: 0.85),
                                        width: 1,
                                      ),
                                    ),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 220),
                                      curve: Curves.easeOutCubic,
                                      decoration: BoxDecoration(
                                        color: isPostAdSelected
                                            ? const Color(0xFFE9EBF0)
                                                .withValues(alpha: 0.85)
                                            : Colors.transparent,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        CupertinoIcons.add,
                                        size: 26,
                                        color: isPostAdSelected ? _blue : _ink,
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
