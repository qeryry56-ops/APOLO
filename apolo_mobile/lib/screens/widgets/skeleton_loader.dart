import 'package:flutter/material.dart';

/// 2026 Shimmer Skeleton Loader components for smooth loading states (>1s)
/// across all screens: Home, Search, Reels, Ad Detail, Stores, Store Detail,
/// Chat List, Chat Room, Notifications, Profile, Seller Profile, and Sheets.
class ShimmerBox extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxShape shape;
  final bool dark;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 16,
    this.shape = BoxShape.rectangle,
    this.dark = false,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.baseColor ??
        (widget.dark ? const Color(0xFF1E293B) : const Color(0xFFEEF1F6));
    final highlight = widget.highlightColor ??
        (widget.dark ? const Color(0xFF334155) : const Color(0xFFF8FAFC));

    if (MediaQuery.disableAnimationsOf(context)) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: base,
          shape: widget.shape,
          borderRadius: widget.shape == BoxShape.circle
              ? null
              : BorderRadius.circular(widget.borderRadius),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final double slide = (_ctrl.value * 2.4) - 0.7;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.circle
                ? null
                : BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(slide - 1.0, -0.3),
              end: Alignment(slide + 1.0, 0.3),
              colors: [base, highlight, base],
              stops: const [0.1, 0.5, 0.9],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton layout for the Home Screen Featured & Feed section
class HomeFeedSkeleton extends StatelessWidget {
  const HomeFeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(
              width: double.infinity, height: 215, borderRadius: 24),
          const SizedBox(height: 22),
          const ShimmerBox(width: 150, height: 20, borderRadius: 8),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.74,
            ),
            itemCount: 4,
            itemBuilder: (_, __) => const AdGridCardSkeleton(),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for a single Ad Grid Card
class AdGridCardSkeleton extends StatelessWidget {
  const AdGridCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDEFF3)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ShimmerBox(
              width: double.infinity,
              height: 120,
              borderRadius: 14,
            ),
          ),
          SizedBox(height: 10),
          ShimmerBox(width: 90, height: 15, borderRadius: 6),
          SizedBox(height: 6),
          ShimmerBox(width: double.infinity, height: 13, borderRadius: 6),
          SizedBox(height: 6),
          ShimmerBox(width: 70, height: 11, borderRadius: 6),
        ],
      ),
    );
  }
}

/// Skeleton for a single full-width Search/Explore listing card
class SearchListCardSkeleton extends StatelessWidget {
  const SearchListCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDEFF3)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(
            width: double.infinity,
            height: 218,
            borderRadius: 18,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(6, 16, 6, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBox(width: 150, height: 18, borderRadius: 6),
                    ShimmerBox(width: 72, height: 15, borderRadius: 6),
                  ],
                ),
                SizedBox(height: 8),
                ShimmerBox(width: 210, height: 13, borderRadius: 6),
                SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBox(width: 110, height: 14, borderRadius: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ShimmerBox(width: 76, height: 18, borderRadius: 6),
                        SizedBox(height: 5),
                        ShimmerBox(width: 112, height: 11, borderRadius: 6),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for Search & Category Feed Grid
class SearchGridSkeleton extends StatelessWidget {
  final bool isGrid;
  const SearchGridSkeleton({super.key, this.isGrid = true});

  @override
  Widget build(BuildContext context) {
    if (!isGrid) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, __) => const SearchListCardSkeleton(),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const AdGridCardSkeleton(),
    );
  }
}

/// Skeleton for Ad Detail Screen
class AdDetailSkeleton extends StatelessWidget {
  const AdDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const ShimmerBox(width: double.infinity, height: 340, borderRadius: 0),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShimmerBox(width: 140, height: 28, borderRadius: 8),
                  ShimmerBox(width: 85, height: 26, borderRadius: 99),
                ],
              ),
              const SizedBox(height: 12),
              const ShimmerBox(
                  width: double.infinity, height: 22, borderRadius: 8),
              const SizedBox(height: 8),
              const ShimmerBox(width: 200, height: 16, borderRadius: 6),
              const SizedBox(height: 20),
              Row(
                children: List.generate(
                  3,
                  (_) => const Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: ShimmerBox(height: 68, borderRadius: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const ShimmerBox(
                  width: double.infinity, height: 110, borderRadius: 18),
              const SizedBox(height: 20),
              const ShimmerBox(
                  width: double.infinity, height: 84, borderRadius: 20),
            ],
          ),
        ),
      ],
    );
  }
}

/// Dark-mode full-screen skeleton for Ad Reels Screen
class AdReelsSkeleton extends StatelessWidget {
  const AdReelsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Stack(
        children: [
          const Positioned.fill(
            child: ShimmerBox(
              width: double.infinity,
              height: double.infinity,
              borderRadius: 24,
              dark: true,
              baseColor: Color(0xFF111827),
              highlightColor: Color(0xFF1F2937),
            ),
          ),
          // Trailing vertical action rail
          PositionedDirectional(
            end: 14,
            bottom: 36,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                ShimmerBox(
                    width: 44, height: 44, shape: BoxShape.circle, dark: true),
                SizedBox(height: 16),
                ShimmerBox(
                    width: 40, height: 40, shape: BoxShape.circle, dark: true),
                SizedBox(height: 16),
                ShimmerBox(
                    width: 40, height: 40, shape: BoxShape.circle, dark: true),
                SizedBox(height: 16),
                ShimmerBox(
                    width: 40, height: 40, shape: BoxShape.circle, dark: true),
              ],
            ),
          ),
          // Bottom-start listing metadata
          const PositionedDirectional(
            start: 16,
            end: 78,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ShimmerBox(width: 110, height: 26, borderRadius: 99, dark: true),
                SizedBox(height: 12),
                ShimmerBox(
                    width: double.infinity,
                    height: 20,
                    borderRadius: 8,
                    dark: true),
                SizedBox(height: 8),
                ShimmerBox(width: 170, height: 15, borderRadius: 6, dark: true),
                SizedBox(height: 14),
                Row(
                  children: [
                    Flexible(
                      child: ShimmerBox(
                        width: 90,
                        height: 32,
                        borderRadius: 99,
                        dark: true,
                      ),
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: ShimmerBox(
                        width: 110,
                        height: 32,
                        borderRadius: 99,
                        dark: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for Chat List Screen conversations
class ChatListSkeleton extends StatelessWidget {
  final int itemCount;
  const ChatListSkeleton({super.key, this.itemCount = 7});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, index) => Row(
        children: [
          const ShimmerBox(width: 54, height: 54, shape: BoxShape.circle),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBox(
                      width: index.isEven ? 132 : 108,
                      height: 15,
                      borderRadius: 6,
                    ),
                    const ShimmerBox(width: 42, height: 11, borderRadius: 5),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ShimmerBox(
                        width: double.infinity,
                        height: 13,
                        borderRadius: 6,
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (index % 3 == 0)
                      const ShimmerBox(
                        width: 20,
                        height: 20,
                        shape: BoxShape.circle,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for Chat Room Screen message bubbles
class ChatRoomSkeleton extends StatelessWidget {
  const ChatRoomSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    const bubbles = <(bool isMine, double width, double height)>[
      (false, 210, 52),
      (false, 150, 42),
      (true, 195, 50),
      (false, 230, 66),
      (true, 160, 44),
      (true, 220, 58),
      (false, 175, 46),
    ];

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      itemCount: bubbles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final (isMine, width, height) = bubbles[index];
        return Align(
          alignment: isMine
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              ShimmerBox(
                width: width,
                height: height,
                borderRadius: 20,
              ),
              const SizedBox(height: 5),
              const ShimmerBox(width: 40, height: 9, borderRadius: 4),
            ],
          ),
        );
      },
    );
  }
}

/// Skeleton for Notifications Screen list (Dynamic Layer v5.1)
class NotificationsSkeleton extends StatelessWidget {
  final int itemCount;
  const NotificationsSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerBox(
              width: 44,
              height: 44,
              shape: BoxShape.circle,
              baseColor: Color(0xFFEEEEEE),
              highlightColor: Color(0xFFFFFFFF),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShimmerBox(
                        width: index.isEven ? 140 : 116,
                        height: 14,
                        borderRadius: 6,
                        baseColor: const Color(0xFFEEEEEE),
                        highlightColor: const Color(0xFFFFFFFF),
                      ),
                      const ShimmerBox(
                        width: 44,
                        height: 11,
                        borderRadius: 5,
                        baseColor: Color(0xFFEEEEEE),
                        highlightColor: Color(0xFFFFFFFF),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const ShimmerBox(
                    width: double.infinity,
                    height: 12,
                    borderRadius: 6,
                    baseColor: Color(0xFFEEEEEE),
                    highlightColor: Color(0xFFFFFFFF),
                  ),
                  const SizedBox(height: 6),
                  ShimmerBox(
                    width: index.isEven ? 180 : 140,
                    height: 12,
                    borderRadius: 6,
                    baseColor: const Color(0xFFEEEEEE),
                    highlightColor: const Color(0xFFFFFFFF),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for a single Store Card in StoresScreen
class StoreCardSkeleton extends StatelessWidget {
  const StoreCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEDEFF3)),
      ),
      child: const Row(
        children: [
          ShimmerBox(width: 62, height: 62, borderRadius: 18),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 148, height: 16, borderRadius: 6),
                SizedBox(height: 8),
                ShimmerBox(width: 105, height: 12, borderRadius: 6),
                SizedBox(height: 10),
                Row(
                  children: [
                    ShimmerBox(width: 66, height: 22, borderRadius: 99),
                    SizedBox(width: 8),
                    ShimmerBox(width: 84, height: 22, borderRadius: 99),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          ShimmerBox(width: 28, height: 28, shape: BoxShape.circle),
        ],
      ),
    );
  }
}

/// Skeleton for Stores Screen list
class StoresListSkeleton extends StatelessWidget {
  final int itemCount;
  const StoresListSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const StoreCardSkeleton(),
    );
  }
}

/// Skeleton for Store Detail Screen
class StoreDetailSkeleton extends StatelessWidget {
  const StoreDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const ShimmerBox(width: double.infinity, height: 190, borderRadius: 0),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  ShimmerBox(width: 68, height: 68, borderRadius: 20),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 160, height: 20, borderRadius: 7),
                        SizedBox(height: 8),
                        ShimmerBox(width: 110, height: 13, borderRadius: 6),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const ShimmerBox(
                  width: double.infinity, height: 14, borderRadius: 6),
              const SizedBox(height: 8),
              const ShimmerBox(width: 220, height: 14, borderRadius: 6),
              const SizedBox(height: 18),
              Row(
                children: const [
                  Expanded(
                    child: ShimmerBox(height: 44, borderRadius: 14),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ShimmerBox(height: 44, borderRadius: 14),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const ShimmerBox(width: 130, height: 18, borderRadius: 6),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.74,
                ),
                itemCount: 4,
                itemBuilder: (_, __) => const AdGridCardSkeleton(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Skeleton for Saved/Favorites bottom sheet rows
class SavedFavoritesSkeleton extends StatelessWidget {
  final int itemCount;
  const SavedFavoritesSkeleton({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        itemCount,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index == itemCount - 1 ? 0 : 12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEDEFF3)),
            ),
            child: const Row(
              children: [
                ShimmerBox(width: 64, height: 64, borderRadius: 14),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(
                          width: double.infinity, height: 14, borderRadius: 6),
                      SizedBox(height: 8),
                      ShimmerBox(width: 96, height: 13, borderRadius: 6),
                      SizedBox(height: 6),
                      ShimmerBox(width: 72, height: 11, borderRadius: 5),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton for Boost Sheet plans loading state
class BoostPlansSkeleton extends StatelessWidget {
  const BoostPlansSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: ShimmerBox(width: 40, height: 4, borderRadius: 99),
        ),
        const SizedBox(height: 18),
        const Row(
          children: [
            ShimmerBox(width: 44, height: 44, shape: BoxShape.circle),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 150, height: 16, borderRadius: 6),
                  SizedBox(height: 6),
                  ShimmerBox(width: 210, height: 12, borderRadius: 6),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        ...List.generate(
          3,
          (i) => Padding(
            padding: EdgeInsets.only(bottom: i == 2 ? 0 : 10),
            child: const ShimmerBox(
              width: double.infinity,
              height: 68,
              borderRadius: 16,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const ShimmerBox(
          width: double.infinity,
          height: 50,
          borderRadius: 16,
        ),
      ],
    );
  }
}
