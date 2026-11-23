import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'perceived_performance.dart';

/// Exact design tokens extracted from Figma `iOS 26 (Community)` — iMessage
/// screens (`1:2` & `4:1052`, SVGs `44a4c.svg`, `62e36.svg`, `557c3.svg`)
/// unified with Apolo's Tab Bar Liquid Glass material (`main_shell.dart`).
class Ios26IMessageTokens {
  Ios26IMessageTokens._();

  // Canvas & Surfaces (sampled directly from Figma screenshot `media_0.png`)
  static const Color canvasWhite = Color(0xFFFFFFFF);
  static const Color edgeMistTint = Color(0xFFF4F5F7); // Figma subtle edge frost
  static const Color tabGlassInk = Color(0xFF0A0A0A);

  // Bubbles (exact hexes from Figma SVG `fill="#0088FF"` & `fill="#D0D2D5"`)
  static const Color bubbleMine = Color(0xFF0088FF);
  static const Color bubbleMineText = Color(0xFFF2F2F7);
  static const Color bubbleOther = Color(0xFFD0D2D5);
  static const Color bubbleOtherText = Color(0xFF333333);

  // Labels & Controls (exact Figma variables)
  static const Color labelPrimary = Color(0xFF000000);
  static const Color controlIconPrimary = Color(0xFF0A0A0A);
  static const Color chevronTertiary = Color(0xFFBFBFBF);
  static const Color dateGray = Color(0xFF8E8E93);
  static const Color placeholderGray = Color(0xFFCCCCCC);
  static const Color onlineGreen = Color(0xFF34C759);
  static const Color errorRed = Color(0xFFFF3B30);

  // Tapback Reaction Badge (Figma 4:1047)
  static const Color tapbackBlue = Color(0xFF0088FF);

  // Dimensions (exact Figma geometry)
  static const double controlCircleSize = 45.0;
  static const double controlRadius = 22.5;
  static const double composerMinHeight = 45.0;
  static const double avatarSize = 62.0;
  static const double namePillHeight = 29.0;
  static const double bubbleRadius = 18.0;
  static const double bubbleTailDrop = 6.0; // Exact SVG drop: 36 -> 42px

  // Typography (exact Figma SF Pro specs)
  static const double messageFontSize = 15.2;
  static const double messageLineHeight = 22.0 / 15.2;
  static const double messageTracking = -0.43;
  static const double dateFontSize = 12.0;
  static const double composerFontSize = 17.0;
  static const double nameFontSize = 16.0;
}

/// Floating Liquid Glass surface matching Apolo's Tab Bar (`main_shell.dart`):
/// - `BackdropFilter(sigmaX: 24, sigmaY: 24)`
/// - Borderless translucent fill `Colors.white.withValues(alpha: 0.78)`
/// - Pure luminous white edge `Colors.white.withValues(alpha: 0.72)` (no dark stroke)
/// - Exact ambient diffuse shadow `BoxShadow(alpha: 0.09, blurRadius: 22, offset: (0, 7))`
/// - Exact Tab Bar **Squash & Stretch Jelly Physics** (`360ms`) + `0.88` press-down
///   scale + `0.82` press opacity + `HapticFeedback.selectionClick()`.
class LiquidGlassSurface extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double fillAlpha;
  final double blurSigma;
  final bool elevated;
  final double pressedScale;

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
    this.fillAlpha = 0.78,
    this.blurSigma = 24.0,
    this.elevated = true,
    this.pressedScale = 0.88,
  });

  @override
  State<LiquidGlassSurface> createState() => _LiquidGlassSurfaceState();
}

class _LiquidGlassSurfaceState extends State<LiquidGlassSurface>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _squashCtrl;
  late final Animation<double> _scaleX;
  late final Animation<double> _scaleY;

  @override
  void initState() {
    super.initState();
    // Exact 360ms Tab Bar squash & stretch curve from `main_shell.dart`
    _squashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _scaleX = TweenSequence<double>([
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
    _scaleY = TweenSequence<double>([
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
    _squashCtrl.dispose();
    super.dispose();
  }

  void _triggerSquashStretch() {
    if (!MediaQuery.disableAnimationsOf(context)) {
      _squashCtrl.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final disableAnim = MediaQuery.disableAnimationsOf(context);
    final pressDuration = disableAnim ? Duration.zero : ApoloMotion.microDuration;

    Widget glassBody = Container(
      width: widget.width,
      height: widget.height,
      constraints: widget.constraints,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        boxShadow: widget.elevated
            ? [
                BoxShadow(
                  color: Ios26IMessageTokens.tabGlassInk.withValues(alpha: 0.10),
                  blurRadius: 22,
                  offset: const Offset(0, 7),
                ),
                BoxShadow(
                  color: Ios26IMessageTokens.tabGlassInk.withValues(alpha: 0.04),
                  blurRadius: 5,
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: _pressed
                    ? (widget.fillAlpha + 0.12).clamp(0.0, 0.96)
                    : widget.fillAlpha,
              ),
              borderRadius: widget.borderRadius,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.78),
                width: 1.0,
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.onTap == null) return glassBody;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        HapticFeedback.selectionClick();
        setState(() => _pressed = true);
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        _triggerSquashStretch();
        widget.onTap?.call();
      },
      onTapCancel: () {
        if (_pressed) setState(() => _pressed = false);
      },
      child: AnimatedBuilder(
        animation: _squashCtrl,
        builder: (context, child) {
          final sx = _squashCtrl.isAnimating ? _scaleX.value : 1.0;
          final sy = _squashCtrl.isAnimating ? _scaleY.value : 1.0;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(sx, sy, 1.0),
            child: child,
          );
        },
        child: AnimatedScale(
          scale: _pressed ? widget.pressedScale : 1.0,
          duration: pressDuration,
          curve: ApoloMotion.easeOutCurve,
          child: AnimatedOpacity(
            opacity: _pressed ? ApoloMotion.pressedOpacity : 1.0,
            duration: pressDuration,
            curve: ApoloMotion.easeOutCurve,
            child: glassBody,
          ),
        ),
      ),
    );
  }
}

/// Exact Figma SVG speech-bubble path (`44a4c.svg`, `62e36.svg`, `557c3.svg`).
///
/// The rounded capsule occupies `[0 .. bodyH]` with radius `18px`, and when
/// `showTail == true`, the iconic delicate iMessage tail dips `6px` BELOW the
/// capsule corner (`y: bodyH -> bodyH + 6`) — mirrored horizontally for outgoing.
Path buildIMessageBubblePath(
  Size size, {
  required bool tailOnRight,
  required bool showTail,
  double radius = Ios26IMessageTokens.bubbleRadius,
  double tailDrop = Ios26IMessageTokens.bubbleTailDrop,
}) {
  final w = size.width;
  final totalH = size.height;
  final bodyH = showTail ? (totalH - tailDrop).clamp(radius * 2, totalH) : totalH;
  final r = radius.clamp(0.0, (bodyH / 2).clamp(0.0, radius));

  if (!showTail || w < 36) {
    return Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, w, bodyH),
          Radius.circular(r),
        ),
      );
  }

  // Exact left-tail path from Figma SVG `d="M(W-18) 0 ..."` normalized to (w, bodyH)
  final leftPath = Path();
  leftPath.moveTo(w - r, 0);
  // Top-right corner
  leftPath.cubicTo(
    w - r + r * 0.5523,
    0,
    w,
    r - r * 0.5523,
    w,
    r,
  );
  leftPath.lineTo(w, bodyH - r);
  // Bottom-right corner
  leftPath.cubicTo(
    w,
    bodyH - r + r * 0.5523,
    w - r + r * 0.5523,
    bodyH,
    w - r,
    bodyH,
  );
  // Bottom edge running left to tail root (x = 18.87)
  leftPath.lineTo(18.87.clamp(0.0, w - r), bodyH);
  // Exact Figma tail outer sweep down to (7.27, bodyH + 5.67)
  leftPath.cubicTo(
    13.51,
    bodyH + 4.15,
    10.83,
    bodyH + 6.11,
    7.40,
    bodyH + 5.99,
  );
  leftPath.cubicTo(
    7.24,
    bodyH + 5.99,
    7.16,
    bodyH + 5.79,
    7.27,
    bodyH + 5.67,
  );
  // Exact Figma tail inner curve back up into bottom-left arc
  leftPath.cubicTo(
    9.48,
    bodyH + 3.16,
    10.22,
    bodyH + 1.88,
    10.0,
    bodyH + 0.94,
  );
  leftPath.cubicTo(
    9.85,
    bodyH - 0.06,
    7.94,
    bodyH - 2.58,
    6.67,
    bodyH - 4.00,
  );
  // Blend into bottom-left rounded edge
  leftPath.cubicTo(
    2.56,
    bodyH - 7.40,
    0,
    bodyH - 12.40,
    0,
    bodyH - r,
  );
  leftPath.lineTo(0, r);
  // Top-left corner
  leftPath.cubicTo(
    0,
    r - r * 0.5523,
    r - r * 0.5523,
    0,
    r,
    0,
  );
  leftPath.close();

  if (!tailOnRight) return leftPath;

  // Mirror horizontally (`x -> w - x`) for right-tail outgoing bubbles (`MyChat`)
  final mirror = Matrix4.identity()
    ..translateByDouble(w, 0.0, 0.0, 1.0)
    ..scaleByDouble(-1.0, 1.0, 1.0, 1.0);
  return leftPath.transform(mirror.storage);
}

/// CustomPainter for solid iOS 26 iMessage bubbles (`#0088FF` / `#D0D2D5`).
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
/// gets the 18px corners + delicate curved tail dipping underneath).
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

/// Real multi-stage **iOS 26 Progressive Blur + Soft Mist Veil (`Dégardé`)** at the top edge.
///
/// As messages scroll upward under the floating Liquid Glass header, they pass
/// through progressively stronger `BackdropFilter` blur bands (`2.5 -> 7 -> 16`)
/// blended with Figma's luminous cool-white mist (`#F4F5F7` -> `#FFFFFF` -> transparent),
/// giving floating white glass controls true depth & shadow separation.
class Ios26TopEdgeFade extends StatelessWidget {
  final double height;

  const Ios26TopEdgeFade({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Band 1 (full height): gentle blur entry
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                child: const SizedBox.expand(),
              ),
            ),
            // Band 2 (upper 68%): medium frosted blur
            Align(
              alignment: Alignment.topCenter,
              child: FractionallySizedBox(
                heightFactor: 0.68,
                widthFactor: 1.0,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 7.5, sigmaY: 7.5),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            // Band 3 (upper 40%): deep frosted glass blur behind top controls
            Align(
              alignment: Alignment.topCenter,
              child: FractionallySizedBox(
                heightFactor: 0.40,
                widthFactor: 1.0,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            // Exact Figma 4-stop luminous mist veil (`#F4F5F7` -> `#FFFFFF` -> transparent)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xF5F4F5F7), // Soft luminous Figma mist at top
                    Color(0xD9F7F8FA), // 85%
                    Color(0x99FFFFFF), // 60%
                    Color(0x00FFFFFF), // Smooth transparent blend into messages
                  ],
                  stops: [0.0, 0.36, 0.70, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Real progressive bottom blur + Figma `#F5F5F7` edge frost behind the floating
/// Liquid Glass `+` & `iMessage` composer so white glass controls & shadows pop.
class Ios26BottomEdgeFade extends StatelessWidget {
  final double height;

  const Ios26BottomEdgeFade({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                child: const SizedBox.expand(),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: 0.62,
                widthFactor: 1.0,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00FFFFFF),
                    Color(0xB8F6F7F9),
                    Color(0xE8F4F5F7),
                    Color(0xFAF3F4F6),
                  ],
                  stops: [0.0, 0.38, 0.72, 1.0],
                ),
              ),
            ),
          ],
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
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
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
