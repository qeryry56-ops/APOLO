import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

/// Visual mode for [NotificationBadge] (Rule 4: never both dot and number).
enum NotificationBadgeType {
  dot,
  number,
}

/// Semantic color variant for [NotificationBadge] (Rule 3: red = action, green = status).
enum NotificationBadgeVariant {
  red,
  green,
}

/// Reusable, accessible notification & status badge compliant with all 7 badge rules:
/// 1. Caps counts > 99 to `"99+"`.
/// 2. Pins to physical top-right corner of [child] without shifting [child] layout.
/// 3. Strictly separates Red (action required) from Green (status only).
/// 4. Renders either a dot OR a number, never both.
/// 5. Pairs with optimistic state clearing so zero renders nothing immediately.
/// 6. Smoothly scales up on count increments without flashing `0`.
/// 7. Enforces minimum 18px touch/legibility box on number badges with > 4.5:1 contrast.
class NotificationBadge extends StatefulWidget {
  final int count;
  final NotificationBadgeType type;
  final NotificationBadgeVariant variant;
  final Widget? child;
  final double? top;
  final double? bottom;
  final double? right;
  final double dotSize;
  final bool showBorder;
  final Color borderColor;
  final String? semanticsLabel;

  const NotificationBadge({
    super.key,
    this.count = 0,
    this.type = NotificationBadgeType.number,
    this.variant = NotificationBadgeVariant.red,
    this.child,
    this.top,
    this.bottom,
    this.right,
    this.dotSize = 10.0,
    this.showBorder = true,
    this.borderColor = Colors.white,
    this.semanticsLabel,
  });

  /// Exact iOS system red for dot indicators (`#FF3B30`).
  static const Color actionRedDotColor = Color(0xFFFF3B30);

  /// Calibrated action red on the same `#FF3B30` hue ensuring `#FFFFFF` text
  /// achieves > 4.5:1 WCAG AA contrast (~4.95:1).
  static const Color actionRedColor = Color(0xFFD9261C);

  /// Accessible status-only green ensuring `#FFFFFF` and surface contrast > 4.5:1 (~5.01:1).
  static const Color statusGreenColor = Color(0xFF16803C);

  /// Minimum rendered width and height for numbered badges (Rule / Accessibility).
  static const double minBadgeSize = 18.0;

  /// Formats an unread count: returns `""` for `<= 0`, `"99+"` for `> 99`, else `count`.
  static String formatCount(int count) {
    if (count <= 0) return '';
    if (count > 99) return '99+';
    return '$count';
  }

  /// Standard WCAG 2.1 contrast ratio between [foreground] and [background].
  static double contrastRatio(Color foreground, Color background) {
    final l1 = foreground.computeLuminance();
    final l2 = background.computeLuminance();
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge>
    with TickerProviderStateMixin {
  late final AnimationController _visibilityCtrl;
  late final Animation<double> _visibilityScale;
  late final AnimationController _bumpCtrl;
  late final Animation<double> _bumpScale;

  String _renderedLabel = '';

  @override
  void initState() {
    super.initState();
    _renderedLabel = NotificationBadge.formatCount(widget.count);
    _visibilityCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: widget.count > 0 ? 1.0 : 0.0,
    );
    _visibilityScale = CurvedAnimation(
      parent: _visibilityCtrl,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );
    _visibilityCtrl.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && mounted) {
        setState(() {});
      }
    });

    _bumpCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _bumpScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.24)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.24, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 55,
      ),
    ]).animate(_bumpCtrl);
  }

  @override
  void didUpdateWidget(covariant NotificationBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final wasVisible = oldWidget.count > 0;
    final isVisible = widget.count > 0;

    if (isVisible) {
      // Only update cached label when positive so exit animation never flashes '0'.
      _renderedLabel = NotificationBadge.formatCount(widget.count);
      if (reduceMotion) {
        _visibilityCtrl.value = 1.0;
        _bumpCtrl.value = 0.0;
      } else {
        if (!wasVisible || _visibilityCtrl.status != AnimationStatus.completed) {
          _visibilityCtrl.forward();
        }
        if (wasVisible && widget.count > oldWidget.count) {
          _bumpCtrl.forward(from: 0.0);
        }
      }
    } else if (wasVisible) {
      if (reduceMotion) {
        _visibilityCtrl.value = 0.0;
        _bumpCtrl.value = 0.0;
      } else {
        _visibilityCtrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _visibilityCtrl.dispose();
    _bumpCtrl.dispose();
    super.dispose();
  }

  String _resolveSemanticsLabel() {
    if (widget.semanticsLabel != null && widget.semanticsLabel!.isNotEmpty) {
      return widget.semanticsLabel!;
    }
    if (widget.type == NotificationBadgeType.dot) {
      return widget.variant == NotificationBadgeVariant.green
          ? appL10n.badgeOnlineSemantic
          : appL10n.badgeUnreadNotificationSemantic;
    }
    if (widget.count > 99) {
      return appL10n.badgeUnreadMaxSemantic;
    }
    return appL10n.badgeUnreadCountSemantic(
      widget.count,
      widget.count == 1
          ? appL10n.notificationSingular
          : appL10n.notificationPlural,
    );
  }

  Widget _buildBadgeSurface(bool reduceMotion) {
    final isDot = widget.type == NotificationBadgeType.dot;
    final Color bgColor = widget.variant == NotificationBadgeVariant.green
        ? NotificationBadge.statusGreenColor
        : (isDot
            ? NotificationBadge.actionRedDotColor
            : NotificationBadge.actionRedColor);

    final border = widget.showBorder
        ? Border.all(color: widget.borderColor, width: 1.5)
        : null;

    if (isDot) {
      return Container(
        width: widget.dotSize,
        height: widget.dotSize,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: border,
        ),
      );
    }

    final label = _renderedLabel;
    if (label.isEmpty) {
      return const SizedBox.shrink();
    }

    return MediaQuery.withClampedTextScaling(
      minScaleFactor: 1.0,
      maxScaleFactor: 1.3,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: NotificationBadge.minBadgeSize,
          minHeight: NotificationBadge.minBadgeSize,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(999),
          border: border,
        ),
        child: Center(
          widthFactor: 1.0,
          heightFactor: 1.0,
          child: AnimatedSwitcher(
            duration:
                reduceMotion ? Duration.zero : const Duration(milliseconds: 160),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) {
              if (reduceMotion) return child;
              final isIncoming = child.key == ValueKey<String>(label);
              final offsetTween = isIncoming
                  ? Tween<Offset>(
                      begin: const Offset(0, 0.35),
                      end: Offset.zero,
                    )
                  : Tween<Offset>(
                      begin: const Offset(0, -0.35),
                      end: Offset.zero,
                    );
              return FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: offsetTween.animate(anim),
                  child: child,
                ),
              );
            },
            child: Text(
              label,
              key: ValueKey<String>(label),
              textDirection: TextDirection.ltr,
              maxLines: 1,
              softWrap: false,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.0,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBadge(bool reduceMotion) {
    final surface = _buildBadgeSurface(reduceMotion);
    final semanticBadge = Semantics(
      label: _resolveSemanticsLabel(),
      excludeSemantics: true,
      child: surface,
    );

    if (reduceMotion) {
      return widget.count > 0 ? semanticBadge : const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_visibilityCtrl, _bumpCtrl]),
      child: semanticBadge,
      builder: (context, child) {
        final scale = _visibilityScale.value *
            (_bumpCtrl.isAnimating ? _bumpScale.value : 1.0);
        final opacity = _visibilityCtrl.value.clamp(0.0, 1.0);
        if (opacity <= 0.0 && widget.count <= 0) {
          return const SizedBox.shrink();
        }
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale.clamp(0.0, 1.5),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final bool shouldShow = widget.count > 0 ||
        (!reduceMotion && !_visibilityCtrl.isDismissed);

    if (widget.child == null) {
      if (!shouldShow) return const SizedBox.shrink();
      return _buildAnimatedBadge(reduceMotion);
    }

    final isDot = widget.type == NotificationBadgeType.dot;
    final bool pinBottom = widget.bottom != null;
    final double? effectiveTop =
        pinBottom ? null : (widget.top ?? (isDot ? -2.0 : -6.0));
    final double? effectiveBottom = widget.bottom;
    final double effectiveRight = widget.right ?? (isDot ? -2.0 : -8.0);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        widget.child!,
        if (shouldShow)
          Positioned(
            top: effectiveTop,
            bottom: effectiveBottom,
            right: effectiveRight,
            child: IgnorePointer(
              child: _buildAnimatedBadge(reduceMotion),
            ),
          ),
      ],
    );
  }
}
