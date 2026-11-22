import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

/// Premium Pull-to-Refresh component for Apolo (`apolo_mobile`) implementing all 6 UX Rules:
///
/// 1. **THRESHOLD (`85px`)**:
///    - Only triggers [onRefresh] when the user pulls past the `85px` threshold line.
///    - If released before `85px`, snaps the list back smoothly with no reload.
///
/// 2. **RESISTANCE (`drag_distance = pull_distance * 0.5`)**:
///    - Pull is never 1:1 with finger movement.
///    - Applies elastic resistance formula `drag_distance = pull_distance * 0.5`
///      so content feels like it has real physical weight.
///
/// 3. **HANDOFF**:
///    - At the threshold point, smoothly transitions the stretch arc indicator into
///      the continuous loading spinner from the exact gesture angle with zero jump.
///
/// 4. **HAPTIC FEEDBACK**:
///    - Triggers a short haptic tick the instant the user crosses the `85px` threshold
///      BEFORE the finger is released (`lightImpact` on iOS, `30ms` vibration/haptic on Android).
///
/// 5. **BOUNCE**:
///    - After release past threshold, content overshoots by `12px` (`10-15px` window)
///      and settles back using spring physics with damping ratio `0.7` (`damping = 22.57`).
///
/// 6. **SCROLL ALIVE**:
///    - Never freezes or blocks the list during reload; items remain scrollable and interactive
///      while the brand spinner is active.
class PullToRefresh extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final double threshold;
  final double resistanceFactor;
  final double refreshHoldOffset;
  final double bounceOvershootPx;
  final Color brandColor;
  final Color backgroundColor;

  const PullToRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
    this.threshold = defaultThreshold,
    this.resistanceFactor = defaultResistanceFactor,
    this.refreshHoldOffset = defaultRefreshHoldOffset,
    this.bounceOvershootPx = defaultBounceOvershootPx,
    this.brandColor = const Color(0xFFE31B23),
    this.backgroundColor = Colors.white,
  });

  /// Rule 1: Fixed 85px pull threshold required to trigger a refresh.
  static const double defaultThreshold = 85.0;

  /// Rule 2: Elastic resistance factor (`drag_distance = pull_distance * 0.5`).
  static const double defaultResistanceFactor = 0.5;

  /// Resting visual offset while refresh is actively running.
  static const double defaultRefreshHoldOffset = 54.0;

  /// Rule 5: 10-15px overshoot on release past threshold before settling back.
  static const double defaultBounceOvershootPx = 12.0;

  /// Rule 5: Spring physics with damping ratio zeta = 0.70
  /// (`damping = 2 * 0.70 * sqrt(1.0 * 260.0) = 22.574`).
  static const SpringDescription springDamping07 = SpringDescription(
    mass: 1.0,
    stiffness: 260.0,
    damping: 22.574,
  );

  /// Rule 2: Computes the resisted visual drag distance from raw finger pull distance.
  /// Formula: `drag_distance = pull_distance * 0.5`.
  static double computeDragDistance(
    double pullDistance, {
    double resistanceFactor = defaultResistanceFactor,
  }) {
    if (pullDistance <= 0) return 0.0;
    return pullDistance * resistanceFactor;
  }

  @override
  State<PullToRefresh> createState() => PullToRefreshState();
}

class PullToRefreshState extends State<PullToRefresh>
    with TickerProviderStateMixin {
  late final AnimationController _settleCtrl;
  late final AnimationController _spinCtrl;

  double _pullDistance = 0.0;
  double _visualOffset = 0.0;
  double _handoffBaseAngle = 0.0;
  double _childScrollOffset = 0.0;

  bool _isDragging = false;
  bool _hasCrossedThreshold = false;
  bool _isRefreshing = false;
  int? _activePointer;
  Offset _lastPointerPos = Offset.zero;

  /// Current raw finger pull distance in logical pixels.
  double get pullDistance => _pullDistance;

  /// Current resisted visual displacement (`drag_distance = pull_distance * 0.5` while pulling).
  double get dragDistance => _visualOffset;

  /// Whether the user has pulled past the `85px` threshold line.
  bool get hasCrossedThreshold => _hasCrossedThreshold;

  /// Whether a refresh operation is currently active.
  bool get isRefreshing => _isRefreshing;

  @override
  void initState() {
    super.initState();
    _settleCtrl = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        if (mounted) {
          setState(() {
            _visualOffset = math.max(0.0, _settleCtrl.value);
          });
        }
      });

    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
  }

  @override
  void dispose() {
    _settleCtrl.dispose();
    _spinCtrl.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.vertical) {
      _childScrollOffset = notification.metrics.pixels;
    }
    return false;
  }

  void _handlePointerDown(PointerDownEvent event) {
    _activePointer = event.pointer;
    _lastPointerPos = event.position;
    if (!_isRefreshing && _childScrollOffset <= 0.5) {
      _settleCtrl.stop();
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_activePointer != event.pointer) return;
    final dy = event.position.dy - _lastPointerPos.dy;
    _lastPointerPos = event.position;

    // Rule 6: When refreshing or scrolled down, keep list freely scrollable.
    if (_isRefreshing) return;
    if (_childScrollOffset > 0.5 && !_isDragging) return;

    if (dy > 0 && !_isDragging && _childScrollOffset <= 0.5) {
      _isDragging = true;
    }

    if (!_isDragging) return;

    final nextPull = (_pullDistance + dy).clamp(0.0, 360.0);
    final crossedNow = nextPull >= widget.threshold;

    // Rule 4: Trigger short haptic tick when user crosses 85px threshold BEFORE finger release.
    if (crossedNow && !_hasCrossedThreshold) {
      _triggerThresholdHaptic();
      // Rule 3: Smooth handoff — start spinner rotation seamlessly from current gesture angle.
      _handoffBaseAngle = (nextPull / widget.threshold) * math.pi * 1.25;
      if (!MediaQuery.disableAnimationsOf(context) && !_spinCtrl.isAnimating) {
        _spinCtrl.repeat();
      }
    } else if (!crossedNow && _hasCrossedThreshold) {
      if (_spinCtrl.isAnimating) {
        _spinCtrl.stop();
      }
    }

    setState(() {
      _pullDistance = nextPull;
      _hasCrossedThreshold = crossedNow;
      // Rule 2: Elastic resistance formula: drag_distance = pull_distance * 0.5
      _visualOffset = PullToRefresh.computeDragDistance(
        _pullDistance,
        resistanceFactor: widget.resistanceFactor,
      );
      if (_pullDistance <= 0) {
        _isDragging = false;
      }
    });
  }

  void _handlePointerUpOrCancel(PointerEvent event) {
    if (_activePointer != event.pointer) return;
    _activePointer = null;

    if (!_isDragging) return;
    _isDragging = false;

    // Rule 1: Only trigger refresh when user pulls past 85px threshold line.
    // If released before threshold, snap list back with no reload.
    if (_pullDistance < widget.threshold) {
      _spinCtrl.stop();
      _pullDistance = 0.0;
      _hasCrossedThreshold = false;
      _animateWithSpring(
        from: _visualOffset,
        to: 0.0,
        initialVelocity: -120.0,
      );
      return;
    }

    // Released past 85px threshold -> trigger refresh with bounce!
    _startRefreshWithBounce();
  }

  /// Rule 4: Short haptic tick on threshold crossing before release
  /// (light impact on iOS, 30ms vibration / light impact on Android).
  void _triggerThresholdHaptic() {
    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.android) {
      HapticFeedback.lightImpact();
      SystemChannels.platform.invokeMethod<void>(
        'HapticFeedback.vibrate',
        'HapticFeedbackType.lightImpact',
      );
    } else {
      HapticFeedback.lightImpact();
    }
  }

  /// Rule 5: After release past threshold, content overshoots 10-15px (`+12px`)
  /// then settles back using spring physics with damping ratio 0.7.
  Future<void> _startRefreshWithBounce() async {
    setState(() {
      _isRefreshing = true;
      _pullDistance = 0.0;
    });

    if (!MediaQuery.disableAnimationsOf(context) && !_spinCtrl.isAnimating) {
      _spinCtrl.repeat();
    }

    // Rule 5: Overshoot 12px (within 10-15px window) past the hold offset,
    // then settle back with 0.7 damping ratio spring physics.
    final overshootStart =
        math.max(_visualOffset, widget.refreshHoldOffset) +
            widget.bounceOvershootPx;

    setState(() {
      _visualOffset = overshootStart;
    });

    _animateWithSpring(
      from: overshootStart,
      to: widget.refreshHoldOffset,
      initialVelocity: 240.0,
    );

    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        _spinCtrl.stop();
        setState(() {
          _isRefreshing = false;
          _hasCrossedThreshold = false;
        });
        _animateWithSpring(
          from: _visualOffset,
          to: 0.0,
          initialVelocity: -80.0,
        );
      }
    }
  }

  void _animateWithSpring({
    required double from,
    required double to,
    double initialVelocity = 0.0,
  }) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _settleCtrl.stop();
      setState(() => _visualOffset = to);
      return;
    }
    final simulation = SpringSimulation(
      PullToRefresh.springDamping07,
      from,
      to,
      initialVelocity,
    );
    _settleCtrl.animateWith(simulation);
  }

  @override
  Widget build(BuildContext context) {
    final thresholdDrag = PullToRefresh.computeDragDistance(
      widget.threshold,
      resistanceFactor: widget.resistanceFactor,
    );
    final progress = _isRefreshing
        ? 1.0
        : (_pullDistance / widget.threshold).clamp(0.0, 1.0);

    final showIndicator = _visualOffset > 1.0 || _isRefreshing;

    return Semantics(
      container: true,
      label: _isRefreshing
          ? 'Refreshing list'
          : (_hasCrossedThreshold
              ? 'Release to refresh'
              : 'Pull down to refresh'),
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: Listener(
          key: const Key('pull-to-refresh-listener'),
          behavior: HitTestBehavior.translucent,
          onPointerDown: _handlePointerDown,
          onPointerMove: _handlePointerMove,
          onPointerUp: _handlePointerUpOrCancel,
          onPointerCancel: _handlePointerUpOrCancel,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Rule 5 & 6: List content translates smoothly with elastic resistance & spring bounce
              // while staying 100% interactive and scrollable during reload (never frozen).
              Transform.translate(
                key: const Key('pull-to-refresh-content-transform'),
                offset: Offset(0, _visualOffset),
                child: widget.child,
              ),

              // Rule 3: Seamless gesture-to-spinner handoff indicator
              if (showIndicator)
                Positioned(
                  top: math.max(8.0, _visualOffset - 38.0),
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _spinCtrl,
                        builder: (context, _) {
                          // Before threshold: rotation is driven directly by finger pull gesture.
                          // At/after threshold: seamlessly hands off into continuous 60fps spin.
                          final gestureAngle =
                              progress * math.pi * 1.25;
                          final spinAngle = (_hasCrossedThreshold ||
                                  _isRefreshing)
                              ? (_handoffBaseAngle +
                                  _spinCtrl.value * math.pi * 2.0)
                              : gestureAngle;
                          final scale = _isRefreshing
                              ? 1.0
                              : (0.45 + 0.55 * progress).clamp(0.45, 1.08);

                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              key: const Key('pull-to-refresh-indicator'),
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: widget.backgroundColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.10),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Transform.rotate(
                                angle: spinAngle,
                                child: CustomPaint(
                                  key: const Key('pull-to-refresh-spinner'),
                                  painter: _ApoloBrandSpinnerPainter(
                                    progress: progress,
                                    isSpinning:
                                        _hasCrossedThreshold || _isRefreshing,
                                    color: widget.brandColor,
                                    thresholdReached:
                                        _visualOffset >= thresholdDrag ||
                                            _isRefreshing,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom Apolo brand arc painter that stretches proportionally during the pull gesture
/// and seamlessly becomes the rotating loader arc at threshold handoff (Rule 3).
class _ApoloBrandSpinnerPainter extends CustomPainter {
  final double progress;
  final bool isSpinning;
  final bool thresholdReached;
  final Color color;

  const _ApoloBrandSpinnerPainter({
    required this.progress,
    required this.isSpinning,
    required this.thresholdReached,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - 1.5;

    // Subtle track ring
    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6;
    canvas.drawCircle(center, radius, trackPaint);

    // Active stretch / spinner arc
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;

    final sweepAngle = isSpinning
        ? math.pi * 1.45
        : (math.pi * 1.45 * progress.clamp(0.08, 1.0));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ApoloBrandSpinnerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isSpinning != isSpinning ||
        oldDelegate.thresholdReached != thresholdReached ||
        oldDelegate.color != color;
  }
}
