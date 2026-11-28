import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';

/// Centralized Perceived Performance & Motion tokens implementing the 3 UX Principles:
///
/// 1. **REACT AT ONCE**:
///    - First visual feedback occurs in `<16ms` (1 frame at 60fps) on `onTapDown` / `onPointerDown`
///      before any network call or tap-up event starts.
///    - Scales interactive targets to `95%` (`0.95`) + changes opacity (`0.82`) + fires haptic feedback.
///    - Never leaves a button static while a background operation is processing.
///
/// 2. **SHOW RESULT FIRST (Optimistic UI)**:
///    - Displays the completed state immediately (e.g., chat bubble in flow, filled heart + updated count)
///      and syncs with the server in the background.
///    - If the API fails, renders an inline error with a retry button on the exact same element.
///
/// 3. **MOVE WITH EASE**:
///    - Eliminates mechanical linear animations in favor of `cubic-bezier(0.22, 1, 0.36, 1)`
///      and spring physics with damping ratio `0.8`.
///    - Micro-interactions: `200–300ms` (`220ms` / `260ms`).
///    - Screen transitions: `400–500ms` (`450ms`).
class ApoloMotion {
  ApoloMotion._();

  /// Rule 3: Exact `cubic-bezier(0.22, 1, 0.36, 1)` ease-out curve.
  /// Starts with high velocity for instant `<16ms` perceived responsiveness
  /// and decelerates smoothly without mechanical linear motion.
  static const Curve easeOutCurve = Cubic(0.22, 1.0, 0.36, 1.0);

  /// Rule 3: Spring physics configuration with damping ratio zeta = 0.80
  /// (`damping = 2 * 0.8 * sqrt(mass * stiffness)` -> `2 * 0.8 * sqrt(1 * 320) = 28.62`).
  static const SpringDescription springDamping08 = SpringDescription(
    mass: 1.0,
    stiffness: 320.0,
    damping: 28.62,
  );

  /// Rule 3: 200-300ms duration for micro-interactions (buttons, icons, toggles).
  static const Duration microDuration = Duration(milliseconds: 220);

  /// Rule 3: 200-300ms duration for heart bounce micro-interaction.
  static const Duration bounceDuration = Duration(milliseconds: 260);

  /// Rule 3: 400-500ms duration for screen transitions.
  static const Duration screenTransitionDuration = Duration(milliseconds: 450);

  /// Rule 1: Scale button down to 95% on touch down.
  static const double pressedScale = 0.95;

  /// Rule 1: Change color/element opacity on touch down.
  static const double pressedOpacity = 0.82;
}

/// Rule 1 ("REACT AT ONCE") & Rule 3 ("MOVE WITH EASE"):
/// Reusable button wrapper that gives instant visual + haptic feedback on touch down (`<16ms`),
/// before any API call begins:
/// - Scales down to `95%` (`0.95`) and changes opacity to `0.82` immediately on pointer/tap down.
/// - Fires tactile haptic feedback (`HapticFeedback.lightImpact()`) on touch down.
/// - Uses `Cubic(0.22, 1, 0.36, 1)` over `220ms` (200-300ms micro-interaction window).
/// - When [isProcessing] is `true`, animates a continuous non-static pulse so the button
///   never looks frozen while background work completes.
class InstantActionButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool isProcessing;
  final double pressedScale;
  final double pressedOpacity;
  final Duration duration;
  final String? semanticLabel;

  const InstantActionButton({
    super.key,
    required this.child,
    this.onPressed,
    this.isProcessing = false,
    this.pressedScale = ApoloMotion.pressedScale,
    this.pressedOpacity = ApoloMotion.pressedOpacity,
    this.duration = ApoloMotion.microDuration,
    this.semanticLabel,
  });

  @override
  State<InstantActionButton> createState() => _InstantActionButtonState();
}

class _InstantActionButtonState extends State<InstantActionButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late final AnimationController _processingPulseCtrl;
  late final Animation<double> _processingCurved;

  @override
  void initState() {
    super.initState();
    // Rule 1: Never leave button in static state while processing.
    _processingPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _processingCurved = CurvedAnimation(
      parent: _processingPulseCtrl,
      curve: ApoloMotion.easeOutCurve,
    );
    if (widget.isProcessing) {
      _processingPulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant InstantActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isProcessing != oldWidget.isProcessing) {
      if (widget.isProcessing) {
        _processingPulseCtrl.repeat(reverse: true);
      } else {
        _processingPulseCtrl.stop();
        _processingPulseCtrl.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _processingPulseCtrl.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.onPressed == null) return;
    // Rule 1: Trigger haptic feedback + 95% scale + opacity change on touch down (<16ms)
    // before the user even lifts their finger or starts the API call.
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onPressed == null) return;
    setState(() => _isPressed = false);
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final effectiveDuration =
        disableAnimations ? Duration.zero : widget.duration;

    final targetScale = _isPressed ? widget.pressedScale : 1.0;
    final targetOpacity = _isPressed ? widget.pressedOpacity : 1.0;

    return Semantics(
      button: true,
      enabled: widget.onPressed != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onPressed != null ? _handleTapDown : null,
        onTapUp: widget.onPressed != null ? _handleTapUp : null,
        onTapCancel: widget.onPressed != null ? _handleTapCancel : null,
        child: AnimatedBuilder(
          animation: _processingCurved,
          builder: (context, child) {
            // Subtle active breathing motion when processing so the button is never static
            final processingPulseScale = widget.isProcessing
                ? 1.0 - (0.025 * _processingCurved.value)
                : 1.0;
            final processingPulseOpacity = widget.isProcessing
                ? 1.0 - (0.14 * _processingCurved.value)
                : 1.0;

            return AnimatedScale(
              key: const Key('instant-button-scale'),
              scale: targetScale * processingPulseScale,
              duration: effectiveDuration,
              curve: ApoloMotion.easeOutCurve,
              child: AnimatedOpacity(
                key: const Key('instant-button-opacity'),
                opacity: (targetOpacity * processingPulseOpacity).clamp(0.0, 1.0),
                duration: effectiveDuration,
                curve: ApoloMotion.easeOutCurve,
                child: child,
              ),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}

/// Specific Example — Like Button implementing all 3 Perceived Performance Rules:
/// - **Rule 1 (React at Once)**: Instant `95%` scale + `0.82` opacity + haptic feedback on touch down (`<16ms`).
/// - **Rule 2 (Show Result First / Optimistic UI)**:
///   - Fills the heart icon and increments/decrements the count immediately on tap before [onSync] resolves.
///   - Syncs with the server in the background.
///   - If the API fails (`throws` or returns `false`), rolls back and displays an inline retry button
///     directly on the same element (`Key('optimistic-like-retry')`).
/// - **Rule 3 (Move with Ease)**:
///   - Uses `Cubic(0.22, 1, 0.36, 1)` over `260ms` (200-300ms range) for the heart bounce animation.
class OptimisticLikeButton extends StatefulWidget {
  final bool initialIsLiked;
  final int initialLikeCount;
  final Future<bool> Function(bool nextIsLiked)? onSync;
  final ValueChanged<bool>? onChanged;
  final bool showCount;
  final Color activeColor;
  final Color inactiveColor;

  const OptimisticLikeButton({
    super.key,
    required this.initialIsLiked,
    this.initialLikeCount = 0,
    this.onSync,
    this.onChanged,
    this.showCount = true,
    this.activeColor = const Color(0xFFFF3B5C),
    this.inactiveColor = const Color(0xFF0F172A),
  });

  @override
  State<OptimisticLikeButton> createState() => _OptimisticLikeButtonState();
}

class _OptimisticLikeButtonState extends State<OptimisticLikeButton>
    with SingleTickerProviderStateMixin {
  late bool _isLiked;
  late int _likeCount;
  bool _isPressed = false;
  bool _isSyncing = false;
  bool _hasSyncError = false;
  bool? _failedTargetState;

  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceScale;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.initialIsLiked;
    _likeCount = widget.initialLikeCount;

    // Rule 3: 260ms (within 200-300ms micro-interaction window) with ease-out cubic-bezier(0.22, 1, 0.36, 1)
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: ApoloMotion.bounceDuration,
    );

    _bounceScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.28)
            .chain(CurveTween(curve: ApoloMotion.easeOutCurve)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.28, end: 1.0)
            .chain(CurveTween(curve: ApoloMotion.easeOutCurve)),
        weight: 45,
      ),
    ]).animate(_bounceCtrl);
  }

  @override
  void didUpdateWidget(covariant OptimisticLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSyncing && !_hasSyncError) {
      if (oldWidget.initialIsLiked != widget.initialIsLiked) {
        _isLiked = widget.initialIsLiked;
      }
      if (oldWidget.initialLikeCount != widget.initialLikeCount) {
        _likeCount = widget.initialLikeCount;
      }
    }
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    // Rule 1: React at once (<16ms) — scale down to 95%, reduce opacity, fire haptic feedback
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
    _triggerOptimisticToggle(!_isLiked);
  }

  Future<void> _triggerOptimisticToggle(bool targetState) async {
    final previousLiked = _isLiked;
    final previousCount = _likeCount;
    final delta = targetState == previousLiked ? 0 : (targetState ? 1 : -1);

    // Rule 2: SHOW RESULT FIRST (Optimistic UI)
    // Update heart fill and count immediately before the API call starts.
    setState(() {
      _isLiked = targetState;
      _likeCount = (_likeCount + delta).clamp(0, 999999999);
      _hasSyncError = false;
      _failedTargetState = null;
      _isSyncing = widget.onSync != null;
    });

    // Rule 3: Bounce animation with cubic-bezier(0.22, 1, 0.36, 1)
    _bounceCtrl.forward(from: 0.0);
    widget.onChanged?.call(targetState);

    if (widget.onSync == null) return;

    try {
      final confirmed = await widget.onSync!(targetState);
      if (!mounted) return;
      if (!confirmed) {
        throw StateError('Like sync rejected');
      }
      setState(() {
        _isSyncing = false;
        _hasSyncError = false;
      });
    } catch (_) {
      if (!mounted) return;
      // Rule 2: If API fails, revert optimistic count/state and show inline error with retry on same element
      setState(() {
        _isLiked = previousLiked;
        _likeCount = previousCount;
        _isSyncing = false;
        _hasSyncError = true;
        _failedTargetState = targetState;
      });
      widget.onChanged?.call(previousLiked);
    }
  }

  void _retryFailedSync() {
    HapticFeedback.selectionClick();
    final target = _failedTargetState ?? !_isLiked;
    _triggerOptimisticToggle(target);
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final microDuration =
        disableAnimations ? Duration.zero : ApoloMotion.microDuration;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          toggled: _isLiked,
          label: _isLiked
              ? context.l10n.unlikeButtonSemantic(_likeCount)
              : context.l10n.likeButtonSemantic(_likeCount),
          child: GestureDetector(
            key: const Key('optimistic-like-button'),
            behavior: HitTestBehavior.opaque,
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              child: AnimatedScale(
                key: const Key('optimistic-like-press-scale'),
                // Rule 1: 95% scale down on press
                scale: _isPressed ? ApoloMotion.pressedScale : 1.0,
                duration: microDuration,
                curve: ApoloMotion.easeOutCurve,
                child: AnimatedOpacity(
                  key: const Key('optimistic-like-press-opacity'),
                  // Rule 1: Opacity change on press (and subtle non-static dim while syncing)
                  opacity: _isPressed
                      ? ApoloMotion.pressedOpacity
                      : (_isSyncing ? 0.92 : 1.0),
                  duration: microDuration,
                  curve: ApoloMotion.easeOutCurve,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _hasSyncError
                          ? const Color(0xFFFEF2F2)
                          : (_isLiked
                              ? widget.activeColor.withValues(alpha: 0.12)
                              : const Color(0xFFF2F3F7)),
                      borderRadius: BorderRadius.circular(999),
                      border: _hasSyncError
                          ? Border.all(
                              color: const Color(0xFFD9261C)
                                  .withValues(alpha: 0.45),
                            )
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ScaleTransition(
                          scale: _bounceScale,
                          child: Icon(
                            _isLiked
                                ? CupertinoIcons.heart_fill
                                : CupertinoIcons.heart,
                            key: const Key('optimistic-like-icon'),
                            size: 18,
                            color: _isLiked
                                ? widget.activeColor
                                : widget.inactiveColor,
                          ),
                        ),
                        if (widget.showCount) ...[
                          const SizedBox(width: 6),
                          Text(
                            '$_likeCount',
                            key: const Key('optimistic-like-count'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _isLiked
                                  ? widget.activeColor
                                  : widget.inactiveColor,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Rule 2: Inline error with retry option on the exact same element when API fails
        if (_hasSyncError) ...[
          const SizedBox(width: 6),
          Semantics(
            button: true,
            label: context.l10n.likeSyncFailedSemantic,
            child: GestureDetector(
              key: const Key('optimistic-like-retry'),
              onTap: _retryFailedSync,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.refresh_bold,
                      size: 12,
                      color: Color(0xFFD9261C),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      context.l10n.retryButton,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFD9261C),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Rule 3 ("MOVE WITH EASE") — Screen transition using spring/ease-out physics (`450ms`, within 400-500ms)
/// and `cubic-bezier(0.22, 1, 0.36, 1)` instead of a mechanical linear slide.
class SpringPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SpringPageRoute({
    required this.page,
    super.settings,
  }) : super(
          // Rule 3: 400-500ms duration for screen transitions
          transitionDuration: ApoloMotion.screenTransitionDuration,
          reverseTransitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SpringPageTransitionsBuilder.buildTransition(
              context,
              animation,
              secondaryAnimation,
              child,
            );
          },
        );
}

/// Global [PageTransitionsBuilder] applying Rule 3 (`450ms` duration + `Cubic(0.22, 1, 0.36, 1)`)
/// across all Material route transitions so no screen transition ever uses a linear curve.
class SpringPageTransitionsBuilder extends PageTransitionsBuilder {
  const SpringPageTransitionsBuilder();

  static Widget buildTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }

    // Rule 3: Easing curve cubic-bezier(0.22, 1, 0.36, 1) — never linear
    final primaryCurved = CurvedAnimation(
      parent: animation,
      curve: ApoloMotion.easeOutCurve,
      reverseCurve: Curves.easeInCubic,
    );

    final secondaryCurved = CurvedAnimation(
      parent: secondaryAnimation,
      curve: ApoloMotion.easeOutCurve,
    );

    final slideIn = Tween<Offset>(
      begin: const Offset(0.18, 0.0),
      end: Offset.zero,
    ).animate(primaryCurved);

    final scaleIn = Tween<double>(
      begin: 0.97,
      end: 1.0,
    ).animate(primaryCurved);

    final fadeIn = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(primaryCurved);

    final parallaxOut = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.06, 0.0),
    ).animate(secondaryCurved);

    return SlideTransition(
      position: parallaxOut,
      child: FadeTransition(
        opacity: fadeIn,
        child: SlideTransition(
          position: slideIn,
          child: ScaleTransition(
            scale: scaleIn,
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return buildTransition(context, animation, secondaryAnimation, child);
  }
}
