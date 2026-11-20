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

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  final AppState _state = AppState();
  int _currentIndex = 0;
  int _lastPillSlot = 0;
  int? _searchInitialCategory;
  bool _searchChromeVisible = true;

  late final AnimationController _squashCtrl;
  late final Animation<double> _pillScaleX;
  late final Animation<double> _pillScaleY;

  // Monochrome Obsidian Black + Neutral Gray Dock Palette
  static const Color _ink = Color(0xFF0A0A0A);
  static const Color _inactive = Color(0xFF6B7280);
  static const Color _activePill = Color(0xFFE8EAEE);

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChanged);
    _squashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _pillScaleX = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.18)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.18, end: 0.94)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.94, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_squashCtrl);
    _pillScaleY = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.85)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.85, end: 1.06)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.06, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_squashCtrl);
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    _squashCtrl.dispose();
    super.dispose();
  }

  void _triggerSquashStretch() {
    if (!MediaQuery.disableAnimationsOf(context)) {
      _squashCtrl.forward(from: 0.0);
    }
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
          _triggerSquashStretch();
          setState(() {
            _searchInitialCategory = catId;
            _searchChromeVisible = true;
            _currentIndex = 2;
            _lastPillSlot = 1;
          });
        },
        onOpenPostAd: () {
          _triggerSquashStretch();
          setState(() {
            _searchChromeVisible = true;
            _currentIndex = 1;
          });
        },
      ),
      PostAdScreen(
        onSuccess: () {
          _triggerSquashStretch();
          setState(() {
            _searchChromeVisible = true;
            _currentIndex = 0;
            _lastPillSlot = 0;
          });
        },
      ),
      SearchScreen(
        key: ValueKey(_searchInitialCategory),
        initialCategoryId: _searchInitialCategory,
        onChromeVisibilityChanged: _handleSearchChromeVisibility,
      ),
      ChatListScreen(
        onExploreAds: () {
          _triggerSquashStretch();
          setState(() {
            _searchChromeVisible = true;
            _currentIndex = 2;
            _lastPillSlot = 1;
          });
        },
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
    final safeBottom = MediaQuery.of(context).padding.bottom;

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
          // Responsive Floating Translucent Pill Dock + Borderless "+" Button with Squash & Stretch
          Positioned(
            left: 20,
            right: 20,
            bottom: safeBottom > 0 ? safeBottom + 4 : 16,
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
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: SizedBox(
                        height: 58,
                        child: Row(
                          textDirection: TextDirection.ltr,
                          children: [
                            // Left Expanded Translucent Glass Capsule Pill (4 main tabs)
                            Expanded(
                              child: Container(
                                height: 58,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _ink.withValues(alpha: 0.09),
                                      blurRadius: 22,
                                      offset: const Offset(0, 7),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 24, sigmaY: 24),
                                    child: Container(
                                      padding: const EdgeInsets.all(4.5),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.78),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.72),
                                          width: 1,
                                        ),
                                      ),
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          final slotWidth =
                                              constraints.maxWidth /
                                                  pillItems.length;
                                          final slotHeight =
                                              constraints.maxHeight;
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
                                                child: AnimatedBuilder(
                                                  animation: _squashCtrl,
                                                  builder: (context, child) {
                                                    final sx =
                                                        _squashCtrl.isAnimating
                                                            ? _pillScaleX.value
                                                            : 1.0;
                                                    final sy =
                                                        _squashCtrl.isAnimating
                                                            ? _pillScaleY.value
                                                            : 1.0;
                                                    return Transform(
                                                      alignment:
                                                          Alignment.center,
                                                      transform: Matrix4
                                                          .diagonal3Values(
                                                              sx, sy, 1.0),
                                                      child: child,
                                                    );
                                                  },
                                                  child: AnimatedContainer(
                                                    duration: const Duration(
                                                        milliseconds: 180),
                                                    decoration: BoxDecoration(
                                                      color: activePillSlot >= 0
                                                          ? _activePill
                                                              .withValues(
                                                                  alpha: 0.90)
                                                          : Colors.transparent,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              999),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Row(
                                                textDirection:
                                                    TextDirection.ltr,
                                                children: List.generate(
                                                  pillItems.length,
                                                  (idx) {
                                                    final item = pillItems[idx];
                                                    final selected =
                                                        _currentIndex ==
                                                            item.pageIndex;
                                                    return Expanded(
                                                      child: PressableScale(
                                                        pressedScale: 0.90,
                                                        onTap: () {
                                                          HapticFeedback
                                                              .selectionClick();
                                                          _triggerSquashStretch();
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
                                                              _lastPillSlot =
                                                                  idx;
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
                                                              height:
                                                                  slotHeight,
                                                              child: Center(
                                                                child:
                                                                    AnimatedScale(
                                                                  scale: selected
                                                                      ? 1.06
                                                                      : 1.0,
                                                                  duration:
                                                                      const Duration(
                                                                          milliseconds:
                                                                              220),
                                                                  curve: const Cubic(
                                                                      0.22,
                                                                      1.0,
                                                                      0.36,
                                                                      1.0),
                                                                  child: Icon(
                                                                    selected
                                                                        ? item
                                                                            .activeIcon
                                                                        : item
                                                                            .icon,
                                                                    size: 22.5,
                                                                    color: selected
                                                                        ? _ink
                                                                        : _inactive,
                                                                  ),
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
                            const SizedBox(width: 10),
                            // Right Detached Borderless Circular Glass "+" Button (Post Ad)
                            PressableScale(
                              pressedScale: 0.88,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _triggerSquashStretch();
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
                                child: AnimatedBuilder(
                                  animation: _squashCtrl,
                                  builder: (context, child) {
                                    final active = isPostAdSelected &&
                                        _squashCtrl.isAnimating;
                                    final sx =
                                        active ? _pillScaleX.value : 1.0;
                                    final sy =
                                        active ? _pillScaleY.value : 1.0;
                                    return Transform(
                                      alignment: Alignment.center,
                                      transform:
                                          Matrix4.diagonal3Values(sx, sy, 1.0),
                                      child: child,
                                    );
                                  },
                                  child: Container(
                                    width: 58,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _ink.withValues(alpha: 0.09),
                                          blurRadius: 22,
                                          offset: const Offset(0, 7),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                            sigmaX: 24, sigmaY: 24),
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 220),
                                          curve: Curves.easeOutCubic,
                                          decoration: BoxDecoration(
                                            color: isPostAdSelected
                                                ? _ink.withValues(alpha: 0.90)
                                                : Colors.white
                                                    .withValues(alpha: 0.78),
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Icon(
                                            CupertinoIcons.add,
                                            size: 24,
                                            color: isPostAdSelected
                                                ? Colors.white
                                                : _ink,
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
