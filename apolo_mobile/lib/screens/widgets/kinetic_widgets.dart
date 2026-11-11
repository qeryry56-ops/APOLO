import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Spring-physics entrance + scroll-staggered reveal widget.
/// Ensures screens feel alive as the user scrolls through sections and cards.
class ScrollReveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset beginOffset;
  final double beginScale;

  const ScrollReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 520),
    this.beginOffset = const Offset(0, 22),
    this.beginScale = 0.96,
  });

  @override
  State<ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<ScrollReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curved;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _curved = CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.22, 1.0, 0.36, 1.0),
    );
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _curved,
      child: widget.child,
      builder: (context, child) {
        final t = _curved.value;
        final dx = widget.beginOffset.dx * (1.0 - t);
        final dy = widget.beginOffset.dy * (1.0 - t);
        final scale = widget.beginScale + (1.0 - widget.beginScale) * t;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Tactile pressable wrapper with spring-back micro-interaction.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.965,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: widget.onLongPress,
      onTapDown:
          widget.onTap != null ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.onTap != null
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap?.call();
            }
          : null,
      onTapCancel:
          widget.onTap != null ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 150),
        curve: const Cubic(0.22, 1.0, 0.36, 1.0),
        child: widget.child,
      ),
    );
  }
}

/// Large 3D PNG illustration with perpetual floating/breathing animation,
/// subtle orbital halo, and dynamic contact shadow so it feels like a live 3D GIF.
class Floating3DIllustration extends StatefulWidget {
  final String assetPath;
  final double size;
  final Color accentColor;
  final IconData fallbackIcon;
  final bool showPulseRings;

  const Floating3DIllustration({
    super.key,
    required this.assetPath,
    this.size = 156,
    this.accentColor = const Color(0xFFE31B23),
    this.fallbackIcon = CupertinoIcons.sparkles,
    this.showPulseRings = true,
  });

  @override
  State<Floating3DIllustration> createState() => _Floating3DIllustrationState();
}

class _Floating3DIllustrationState extends State<Floating3DIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOutSine.transform(_controller.value);
        final floatY = -10.0 * t;
        final tiltAngle = (t - 0.5) * 0.035;
        final shadowScale = 1.0 - (0.18 * t);
        final shadowOpacity = 0.14 - (0.06 * t);

        return SizedBox(
          width: widget.size + 36,
          height: widget.size + 34,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (widget.showPulseRings) ...[
                // Outer breathing aura ring
                Transform.scale(
                  scale: 0.88 + (0.14 * t),
                  child: Container(
                    width: widget.size * 0.92,
                    height: widget.size * 0.92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          widget.accentColor
                              .withValues(alpha: 0.10 * (1.0 - t * 0.3)),
                          widget.accentColor.withValues(alpha: 0.03),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Orbiting subtle dot 1
                Transform.translate(
                  offset: Offset(
                    math.cos(t * math.pi) * (widget.size * 0.44),
                    -widget.size * 0.28 + math.sin(t * math.pi) * 8,
                  ),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.accentColor.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Orbiting subtle dot 2
                Transform.translate(
                  offset: Offset(
                    -math.cos(t * math.pi) * (widget.size * 0.42),
                    widget.size * 0.18 - math.sin(t * math.pi) * 6,
                  ),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF94A3B8),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],

              // Dynamic ground contact shadow
              Positioned(
                bottom: 4,
                child: Transform.scale(
                  scaleX: shadowScale,
                  scaleY: shadowScale * 0.35,
                  child: Container(
                    width: widget.size * 0.62,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A)
                              .withValues(alpha: shadowOpacity),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Floating 3D PNG Cutout
              Transform.translate(
                offset: Offset(0, floatY),
                child: Transform.rotate(
                  angle: tiltAngle,
                  child: Image.asset(
                    widget.assetPath,
                    width: widget.size,
                    height: widget.size,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) => Container(
                      width: widget.size * 0.68,
                      height: widget.size * 0.68,
                      decoration: BoxDecoration(
                        color: widget.accentColor.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.fallbackIcon,
                        size: widget.size * 0.34,
                        color: widget.accentColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// High-craft composed state card for No-Internet, Empty Notifications, or Empty Search.
class IllustratedStateView extends StatelessWidget {
  final String assetPath;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final IconData fallbackIcon;
  final double imageSize;

  const IllustratedStateView({
    super.key,
    required this.assetPath,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
    this.fallbackIcon = CupertinoIcons.wifi_slash,
    this.imageSize = 168,
  });

  @override
  Widget build(BuildContext context) {
    return ScrollReveal(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Floating3DIllustration(
                assetPath: assetPath,
                size: imageSize,
                fallbackIcon: fallbackIcon,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.4,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 310),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 24),
                PressableScale(
                  onTap: onAction,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE31B23),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFFE31B23).withValues(alpha: 0.22),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      actionLabel!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
              if (secondaryLabel != null && onSecondary != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onSecondary,
                  child: Text(
                    secondaryLabel!,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
