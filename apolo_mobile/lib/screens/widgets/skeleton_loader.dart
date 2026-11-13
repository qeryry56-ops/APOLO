import 'package:flutter/material.dart';

/// 2026 Shimmer Skeleton Loader components for smooth loading states (>1s)
/// across Home, Search/Category Feed, Ad Detail, and Instagram-style Profile.
class ShimmerBox extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final BoxShape shape;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 16,
    this.shape = BoxShape.rectangle,
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
              colors: const [
                Color(0xFFEEF1F6),
                Color(0xFFF8FAFC),
                Color(0xFFEEF1F6),
              ],
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

/// Skeleton for Search & Category Feed Grid
class SearchGridSkeleton extends StatelessWidget {
  final bool isGrid;
  const SearchGridSkeleton({super.key, this.isGrid = true});

  @override
  Widget build(BuildContext context) {
    if (!isGrid) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          height: 114,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEDEFF3)),
          ),
          child: const Row(
            children: [
              ShimmerBox(width: 110, height: 94, borderRadius: 14),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShimmerBox(width: 90, height: 16, borderRadius: 6),
                    SizedBox(height: 8),
                    ShimmerBox(
                        width: double.infinity, height: 14, borderRadius: 6),
                    SizedBox(height: 8),
                    ShimmerBox(width: 100, height: 12, borderRadius: 6),
                  ],
                ),
              ),
            ],
          ),
        ),
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
