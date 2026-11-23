import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'perceived_performance.dart';

/// Exact design tokens extracted from Figma `iOS 26 (Community)` — iMessage
/// screens (`1:2` and `4:1052`, file key `2KKhnxTaSWpI8CQhUz7f8J`).
class Ios26IMessageTokens {
  Ios26IMessageTokens._();

  // Canvas & Surfaces
  static const Color canvasWhite = Color(0xFFFFFFFF);
  static const Color glassFillBase = Color(0xADFFFFFF); // rgba(255,255,255,0.68)
  static const Color glassNamePillFill = Color(0xCCFFFFFF); // rgba(255,255,255,0.80)
  static const Color glassBorderHighlight = Color(0xE6FFFFFF);
  static const Color glassBorderOuter = Color(0x14000000);

  // Bubbles (exact Figma hexes)
  static const Color bubbleMine = Color(0xFF0088FF); // Figma #08f
  static const Color bubbleMineText = Color(0xFFF2F2F7); // Figma --grays/gray-6
  static const Color bubbleOther = Color(0xFFCFD1D4); // Figma #cfd1d4
  static const Color bubbleOtherText = Color(0xFF333333); // Figma --labels---vibrant/primary

  // Labels & Controls
  static const Color labelPrimary = Color(0xFF000000);
  static const Color controlIconPrimary = Color(0xFF404040); // Figma #404040
  static const Color chevronTertiary = Color(0xFFBFBFBF); // Figma #bfbfbf
  static const Color dateGray = Color(0xFF8E8E93); // Figma --grays/gray
  static const Color placeholderGray = Color(0xFFCCCCCC); // Figma --fills---vibrant/primary
  static const Color onlineGreen = Color(0xFF34C759); // iOS System Green
  static const Color errorRed = Color(0xFFFF3B30);

  // Tapback Reaction Badge (Figma 4:1047)
  static const Color tapbackBlue = Color(0xFF0088FF);

  // Dimensions (exact Figma geometry)
  static const double controlCircleSize = 45.0; // Figma size-[45px]
  static const double controlRadius = 22.5; // Figma rounded-[22.5px]
  static const double composerMinHeight = 45.0; // Figma h-[45px]
  static const double avatarSize = 62.0; // Figma Photo profil circle
  static const double namePillHeight = 29.0; // Figma h-[29px]
  static const double bubbleRadius = 18.0; // Figma rounded-[18px]
  static const double bubbleTailWidth = 6.5;

  // Typography (exact Figma SF Pro specs)
  static const double messageFontSize = 15.2;
  static const double messageLineHeight = 22.0 / 15.2;
  static const double messageTracking = -0.43;
  static const double dateFontSize = 12.0;
  static const double composerFontSize = 17.0;
  static const double nameFontSize = 16.0;
}

/// Authentic iOS 26 **Liquid Glass — Clear/Light** surface matching the Figma
/// `LiquidGlassClearLight` component used on the Back button, Call button,
/// floating Name pill, `+` button, and `iMessage` input capsule.
class LiquidGlassSurface extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color tintColor;
  final double blurSigma;
  final bool elevated;

  const LiquidGlassSurface({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.constraints,
    this.borderRadius =
        const BorderRadius.all(Radius.circular(Ios26IMessageTokens.controlRadius)),
    this.padding,
    this.onTap,
    this.tintColor = Ios26IMessageTokens.glassFillBase,
    this.blurSigma = 22.0,
    this.elevated = true,
  });

  @override
  State<LiquidGlassSurface> createState() => _LiquidGlassSurfaceState();
}

class _LiquidGlassSurfaceState extends State<LiquidGlassSurface> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disableAnim = MediaQuery.disableAnimationsOf(context);
    final duration = disableAnim ? Duration.zero : ApoloMotion.microDuration;

    Widget surface = Container(
      width: widget.width,
      height: widget.height,
      constraints: widget.constraints,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        boxShadow: widget.elevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.09),
                  blurRadius: 20,
                  spreadRadius: -2,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: widget.blurSigma,
            sigmaY: widget.blurSigma,
          ),
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.88),
                  widget.tintColor,
                  Colors.white.withValues(alpha: 0.80),
                ],
                stops: const [0.0, 0.52, 1.0],
              ),
              border: Border.all(
                color: Ios26IMessageTokens.glassBorderOuter,
                width: 0.8,
              ),
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              border: Border.all(
                color: Ios26IMessageTokens.glassBorderHighlight,
                width: 1.0,
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.onTap == null) return surface;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _pressed = true);
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () {
        if (_pressed) setState(() => _pressed = false);
      },
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: duration,
        curve: ApoloMotion.easeOutCurve,
        child: surface,
      ),
    );
  }
}

/// Builds the exact iOS 26 iMessage speech-bubble path with a smooth curved
/// swooping tail on the bottom-outer corner (matching Figma `Union` / `Vector 3` / `Vector 4`).
Path buildIMessageBubblePath(
  Size size, {
  required bool tailOnRight,
  required bool showTail,
  double radius = Ios26IMessageTokens.bubbleRadius,
  double tailWidth = Ios26IMessageTokens.bubbleTailWidth,
}) {
  final w = size.width;
  final h = size.height;
  final r = radius.clamp(0.0, (h / 2).clamp(0.0, radius));
  final tw = showTail ? tailWidth : 0.0;

  if (!showTail) {
    return Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, w, h),
          Radius.circular(r),
        ),
      );
  }

  final path = Path();

  if (tailOnRight) {
    // Outgoing/right-aligned bubble: body sits in [0 .. w - tw], tail swoops out to x = w at bottom-right.
    final bodyRight = (w - tw).clamp(r * 2, w);
    path.moveTo(r, 0);
    path.lineTo(bodyRight - r, 0);
    path.quadraticBezierTo(bodyRight, 0, bodyRight, r);
    path.lineTo(bodyRight, h - 11.5);
    // Smooth organic iMessage tail curve pointing bottom-right
    path.cubicTo(
      bodyRight,
      h - 5.0,
      bodyRight + tw * 0.48,
      h - 1.2,
      w,
      h,
    );
    path.cubicTo(
      bodyRight + tw * 0.15,
      h + 0.3,
      bodyRight - 3.8,
      h - 0.8,
      bodyRight - 8.2,
      h - 3.6,
    );
    // Smooth merge into bottom edge
    path.quadraticBezierTo(
      bodyRight - 12.2,
      h,
      (bodyRight - 17.0).clamp(r, bodyRight),
      h,
    );
    path.lineTo(r, h);
    path.quadraticBezierTo(0, h, 0, h - r);
    path.lineTo(0, r);
    path.quadraticBezierTo(0, 0, r, 0);
    path.close();
  } else {
    // Incoming/left-aligned bubble: body sits in [tw .. w], tail swoops out to x = 0 at bottom-left.
    final bodyLeft = tw.clamp(0.0, (w - r * 2).clamp(0.0, w));
    path.moveTo(bodyLeft + r, 0);
    path.lineTo(w - r, 0);
    path.quadraticBezierTo(w, 0, w, r);
    path.lineTo(w, h - r);
    path.quadraticBezierTo(w, h, w - r, h);
    path.lineTo((bodyLeft + 17.0).clamp(bodyLeft, w - r), h);
    path.quadraticBezierTo(
      bodyLeft + 12.2,
      h,
      bodyLeft + 8.2,
      h - 3.6,
    );
    path.cubicTo(
      bodyLeft + 3.8,
      h - 0.8,
      bodyLeft - tw * 0.15,
      h + 0.3,
      0,
      h,
    );
    path.cubicTo(
      bodyLeft - tw * 0.48,
      h - 1.2,
      bodyLeft,
      h - 5.0,
      bodyLeft,
      h - 11.5,
    );
    path.lineTo(bodyLeft, r);
    path.quadraticBezierTo(bodyLeft, 0, bodyLeft + r, 0);
    path.close();
  }

  return path;
}

/// CustomPainter for solid iOS 26 iMessage bubbles (`#0088FF` / `#CFD1D4`).
class IMessageBubblePainter extends CustomPainter {
  final Color color;
  final Color? borderColor;
  final bool tailOnRight;
  final bool showTail;
  final double radius;

  const IMessageBubblePainter({
    required this.color,
    this.borderColor,
    required this.tailOnRight,
    required this.showTail,
    this.radius = Ios26IMessageTokens.bubbleRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = buildIMessageBubblePath(
      size,
      tailOnRight: tailOnRight,
      showTail: showTail,
      radius: radius,
    );

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawPath(path, fillPaint);

    if (borderColor != null) {
      final strokePaint = Paint()
        ..color = borderColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..isAntiAlias = true;
      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant IMessageBubblePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.tailOnRight != tailOnRight ||
        oldDelegate.showTail != showTail ||
        oldDelegate.radius != radius;
  }
}

/// CustomClipper for photo message bubbles (`OtherChat3` in Figma — photo itself
/// gets the rounded 18px corners + curved iMessage tail at the bottom corner).
class IMessageBubbleClipper extends CustomClipper<Path> {
  final bool tailOnRight;
  final bool showTail;
  final double radius;

  const IMessageBubbleClipper({
    required this.tailOnRight,
    required this.showTail,
    this.radius = Ios26IMessageTokens.bubbleRadius,
  });

  @override
  Path getClip(Size size) {
    return buildIMessageBubblePath(
      size,
      tailOnRight: tailOnRight,
      showTail: showTail,
      radius: radius,
    );
  }

  @override
  bool shouldReclip(covariant IMessageBubbleClipper oldClipper) {
    return oldClipper.tailOnRight != tailOnRight ||
        oldClipper.showTail != showTail ||
        oldClipper.radius != radius;
  }
}

/// Exact Figma `Dégardé` (`4:1051` / `1:2708`) top progressive white fade
/// sitting directly underneath the floating Liquid Glass header so messages
/// glide seamlessly behind the top controls.
class Ios26TopEdgeFade extends StatelessWidget {
  final double height;

  const Ios26TopEdgeFade({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFF), // 100% opaque white at top
              Color(0xE6FFFFFF), // 90%
              Color(0xB3FFFFFF), // 70%
              Color(0x05FFFFFF), // 2% transparent bottom edge
            ],
            stops: [0.0, 0.42, 0.74, 1.0],
          ),
        ),
      ),
    );
  }
}

/// Soft progressive bottom fade behind the floating Liquid Glass composer bar.
class Ios26BottomEdgeFade extends StatelessWidget {
  final double height;

  const Ios26BottomEdgeFade({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x00FFFFFF),
              Color(0xCCFFFFFF),
              Color(0xF5FFFFFF),
              Color(0xFFFFFFFF),
            ],
            stops: [0.0, 0.45, 0.78, 1.0],
          ),
        ),
      ),
    );
  }
}

/// Exact Figma Tapback badge (`OtherChat2` node `4:1047`):
/// Floating `#0088FF` pill/circle with diffuse shadow `0 0 20px rgba(0,0,0,0.25)`.
class Ios26TapbackBadge extends StatelessWidget {
  final List<String> reactions;
  final VoidCallback? onTap;

  const Ios26TapbackBadge({
    super.key,
    required this.reactions,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cleaned = reactions
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) return const SizedBox.shrink();

    final uniqueEmojis = cleaned.toSet().take(3).join('');
    final isSingle = cleaned.length == 1;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        padding: EdgeInsets.symmetric(
          horizontal: isSingle ? 5 : 7,
          vertical: 2.5,
        ),
        decoration: BoxDecoration(
          color: Ios26IMessageTokens.tapbackBlue,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 16,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              uniqueEmojis,
              style: const TextStyle(fontSize: 12, height: 1.1),
            ),
            if (cleaned.length > 1) ...[
              const SizedBox(width: 3),
              Text(
                '${cleaned.length}',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
