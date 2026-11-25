import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'perceived_performance.dart';

/// Exact design tokens extracted from Figma `iOS 26 (Community)` — iMessage
/// screen (`1:2`, `375 × 812` reference frame).
class Ios26IMessageTokens {
  Ios26IMessageTokens._();

  // Canvas & Surfaces
  static const Color canvasWhite = Color(0xFFFFFFFF);
  static const Color edgeMistTint = Color(0xFFFFFFFF);
  static const Color tabGlassInk = Color(0xFF000000);

  // Header Frosted / Gradient Overlay tokens
  static const Color headerFrostedLight = Color(0xBFFFFFFF);
  static const Color headerFrostedDark = Color(0xC71C1C1E);
  static const Color headerBorderLight = Color(0x14000000);
  static const Color headerBorderDark = Color(0x1FFFFFFF);

  /// Exact Figma `1:2` White Header Gradient Overlay stops (top -> bottom):
  /// Bottom-to-top in Figma:
  /// - 0%: white at 2% opacity (`0x05FFFFFF`) -> stop `1.0`
  /// - 26.504%: white at 70% opacity (`0xB3FFFFFF`) -> stop `0.73496`
  /// - 61.221%: white at 90% opacity (`0xE6FFFFFF`) -> stop `0.38779`
  /// - 100%: white at 100% opacity (`0xFFFFFFFF`) -> stop `0.0`
  static const List<Color> headerGradientColors = <Color>[
    Color(0xFFFFFFFF), // 100% white at top
    Color(0xE6FFFFFF), // 90% white at 61.221% from bottom
    Color(0xB3FFFFFF), // 70% white at 26.504% from bottom
    Color(0x05FFFFFF), // 2% white at bottom
  ];
  static const List<double> headerGradientStops = <double>[
    0.0,
    0.38779,
    0.73496,
    1.0,
  ];

  /// Standard Rec. 709 `saturate(180%)` 5x4 color matrix.
  static const List<double> saturationMatrix180 = <double>[
    1.62992, -0.57216, -0.05776, 0.0, 0.0,
    -0.17008, 1.22784, -0.05776, 0.0, 0.0,
    -0.17008, -0.57216, 1.74224, 0.0, 0.0,
    0.0, 0.0, 0.0, 1.0, 0.0,
  ];

  // Exact Figma `1:2` Chat Bubbles
  // Outgoing: solid #0088FF, text #F2F2F7
  // Incoming: solid #D0D2D5, text #333333
  static const Color bubbleMineTop = Color(0xFF0088FF);
  static const Color bubbleMine = Color(0xFF0088FF);
  static const LinearGradient bubbleMineGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bubbleMineTop, bubbleMine],
  );
  static const Color bubbleMineText = Color(0xFFF2F2F7);
  static const Color bubbleOther = Color(0xFFD0D2D5);
  static const Color bubbleOtherText = Color(0xFF333333);

  // Labels & Controls (exact Figma `1:2` tokens)
  static const Color labelPrimary = Color(0xFF000000);
  static const Color labelSecondary = Color(0x993C3C43);
  static const Color controlIconPrimary = Color(0xFF404040); // Back & Video icons
  static const Color composerPlusIcon = Color(0xFF000000); // Composer `+` icon
  static const Color nameChevron = Color(0xFFBFBFBF); // Profile pill right chevron
  static const Color chevronTertiary = Color(0xFFBFBFBF);
  static const Color dateGray = Color(0xFF8E8E93); // Timestamps #8E8E93
  static const Color placeholderGray = Color(0xFFCCCCCC); // "iMessage" & mic #CCCCCC
  static const Color onlineGreen = Color(0xFF34C759);
  static const Color errorRed = Color(0xFFFF3B30);

  // Tapback Reaction Badge (`20 × 20` circular `#0088FF`)
  static const Color tapbackBlue = Color(0xFF0088FF);

  // Exact Figma `1:2` / `4:1061` Dimensions
  static const double controlCircleSize = 45.0;
  static const double controlRadius = 22.5;
  static const double composerBarWidth = 326.0; // `4:1061` (326 × 45 px)
  static const double composerInputWidth = 262.0; // `I4:1061;1:2659;1:76` (262 × 45 px)
  static const double composerMinHeight = 45.0; // Exact 45 px height
  static const double composerRadius = 22.5;
  static const double composerControlGap = 19.0; // 326 - 45 - 262 = 19 px
  static const double composerBottomOffset = 41.0; // Closed keyboard: 41 px from screen bottom
  static const double composerKeyboardGap = 14.0; // Open keyboard (`1:2660` / `1:989`): 14 px above keyboard (Y = 411 px)
  static const double keyboardReferenceHeight = 343.0; // Figma `1:989` (375 × 343 px, visible 342 px at y = 470..812)
  static const double headerButtonFillAlpha = 0.68;
  static const double namePillFillAlpha = 0.80;
  static const double composerFillAlpha = 0.78;
  static const double avatarOuterGlassSize = 65.0; // (155, 61, 65, 65)
  static const double avatarSize = 63.0; // (156, 62, 63, 63)
  static const double namePillHeight = 29.0; // (142, 121, 91, 29)
  static const double bubbleBodyHeight = 36.0;
  static const double bubbleRadius = 18.0;
  static const double bubbleTailDrop = 6.0; // Total bubble height = 42.0
  static const double photoBubbleWidth = 170.0; // (25, -58, 170, 222)
  static const double photoBubbleBodyHeight = 216.0;

  // Exact Figma `1:2` Typography
  static const double messageFontSize = 15.2; // SF Pro Semibold 15.2px (590)
  static const double messageLineHeight = 22.0 / 15.2; // 22px line-height
  static const double messageTracking = -0.43; // -0.43px tracking
  static const double dateFontSize = 12.0; // SF Pro Medium 12px
  static const double composerFontSize = 17.0; // SF Pro Medium 17px
  static const double nameFontSize = 17.0; // SF Pro Medium 17px
}

/// Clear-glass iOS 26 surface matching Figma `1:2`:
/// - Base translucent white (`68%` for circular buttons, `80%` for Name pill)
/// - Very subtle white specular highlight & delicate soft shadow (avoids thick borders or dark shadows)
/// - Tactile press micro-interaction + subtle squash-and-stretch release.
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
    this.fillAlpha = Ios26IMessageTokens.headerButtonFillAlpha,
    this.blurSigma = 22.0,
    this.elevated = true,
    this.pressedScale = 0.92,
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
    _squashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    _scaleX = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.10)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.10, end: 0.96)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.96, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_squashCtrl);
    _scaleY = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.91)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.91, end: 1.04)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.04, end: 1.0)
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
    final effectiveBaseAlpha = _pressed
        ? (widget.fillAlpha + 0.12).clamp(0.0, 0.96)
        : widget.fillAlpha;
    final topHighlightAlpha = (effectiveBaseAlpha + 0.14).clamp(0.0, 0.97);

    Widget glassBody = Container(
      width: widget.width,
      height: widget.height,
      constraints: widget.constraints,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        boxShadow: widget.elevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.055),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.025),
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            padding: widget.padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: topHighlightAlpha),
                  Colors.white.withValues(alpha: effectiveBaseAlpha),
                ],
              ),
              borderRadius: widget.borderRadius,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.88),
                width: 0.5,
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
  final bodyH =
      showTail ? (totalH - tailDrop).clamp(radius * 2, totalH) : totalH;
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

  final leftPath = Path();
  leftPath.moveTo(w - r, 0);
  leftPath.cubicTo(
    w - r + r * 0.5523,
    0,
    w,
    r - r * 0.5523,
    w,
    r,
  );
  leftPath.lineTo(w, bodyH - r);
  leftPath.cubicTo(
    w,
    bodyH - r + r * 0.5523,
    w - r + r * 0.5523,
    bodyH,
    w - r,
    bodyH,
  );
  leftPath.lineTo(18.87.clamp(0.0, w - r), bodyH);
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
  leftPath.cubicTo(
    2.56,
    bodyH - 7.40,
    0,
    bodyH - 12.40,
    0,
    bodyH - r,
  );
  leftPath.lineTo(0, r);
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

  final mirror = Matrix4.identity()
    ..translateByDouble(w, 0.0, 0.0, 1.0)
    ..scaleByDouble(-1.0, 1.0, 1.0, 1.0);
  return leftPath.transform(mirror.storage);
}

/// CustomPainter for iOS 26 iMessage speech bubbles (`#0088FF` outgoing, `#D0D2D5` incoming).
class IMessageBubblePainter extends CustomPainter {
  final Color color;
  final Gradient? gradient;
  final Color? borderColor;
  final bool tailOnRight;
  final bool showTail;
  final double radius;

  const IMessageBubblePainter({
    required this.color,
    this.gradient,
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
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    if (gradient != null) {
      fillPaint.shader =
          gradient!.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    } else {
      fillPaint.color = color;
    }

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
        oldDelegate.gradient != gradient ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.tailOnRight != tailOnRight ||
        oldDelegate.showTail != showTail ||
        oldDelegate.radius != radius;
  }
}

/// CustomClipper for photo message bubbles (`OtherChat3` in Figma `1:2` —
/// `170 × 216` rounded `18px` body + `6px` incoming/outgoing tail at bottom).
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

/// Exact Figma `1:2` White Header Gradient Overlay (`(-8, -11, 390, 180)`):
/// Placed above the scrolling messages (including photo messages behind the header)
/// and below the floating clear-glass header controls.
///
/// Stops (bottom to top):
/// - `0%`: white at `2%` opacity
/// - `26.504%`: white at `70%` opacity
/// - `61.221%`: white at `90%` opacity
/// - `100%`: white at `100%` opacity
class Ios26HeaderGradientOverlay extends StatelessWidget {
  final double height;

  const Ios26HeaderGradientOverlay({
    super.key,
    this.height = 180.0,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        key: const Key('ios26-header-gradient-overlay'),
        height: height,
        width: double.infinity,
        child: DecoratedBox(
          key: const Key('ios26-header-gradient-box'),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: Ios26IMessageTokens.headerGradientColors,
              stops: Ios26IMessageTokens.headerGradientStops,
            ),
          ),
        ),
      ),
    );
  }
}

/// Legacy frosted header bar preserved for backwards compatibility if referenced elsewhere.
class Ios26FrostedHeaderBar extends StatelessWidget {
  final Widget child;

  const Ios26FrostedHeaderBar({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRect(
      key: const Key('ios26-frosted-header-clip'),
      clipBehavior: Clip.hardEdge,
      child: BackdropFilter(
        key: const Key('ios26-frosted-header-blur'),
        filter: ImageFilter.compose(
          outer: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
          inner: const ColorFilter.matrix(
            Ios26IMessageTokens.saturationMatrix180,
          ),
        ),
        child: Container(
          key: const Key('ios26-frosted-header-surface'),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: isDark
                ? Ios26IMessageTokens.headerFrostedDark
                : Ios26IMessageTokens.headerFrostedLight,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Ios26IMessageTokens.headerBorderDark
                    : Ios26IMessageTokens.headerBorderLight,
                width: 0.5,
              ),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Progressive top edge fade helper.
class Ios26TopEdgeFade extends StatelessWidget {
  final double height;

  const Ios26TopEdgeFade({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return Ios26HeaderGradientOverlay(height: height);
  }
}

/// Soft white bottom edge fade behind the floating clear-glass composer
/// (`+` button and `"iMessage"` capsule) so scrolling bubbles fade cleanly on `#FFFFFF`.
class Ios26BottomEdgeFade extends StatelessWidget {
  final double height;

  const Ios26BottomEdgeFade({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: height,
        child: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x00FFFFFF),
                Color(0xB3FFFFFF),
                Color(0xF2FFFFFF),
                Color(0xFFFFFFFF),
              ],
              stops: [0.0, 0.42, 0.76, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

/// Exact Figma `1:2` Tapback reaction badge (`(236, 282, 20, 20)` on Bubble B):
/// - `20 × 20` circular `#0088FF` fill for single reaction (expands cleanly to pill for multiple)
/// - `16 × 16` pink heart / emoji centered inside, overlapping the bubble's lower corner.
class Ios26TapbackBadge extends StatelessWidget {
  final List<String> reactions;
  final VoidCallback? onTap;

  const Ios26TapbackBadge({
    super.key,
    required this.reactions,
    this.onTap,
  });

  static Widget _buildReactionGlyph(String emoji) {
    // Render crisp pink heart matching Figma `(238, 283.5, 16, 16)` when reaction is a heart
    if (emoji == '❤️' ||
        emoji == '❤' ||
        emoji == '💗' ||
        emoji == '💖' ||
        emoji == '💕' ||
        emoji == '🩷') {
      return const Icon(
        Icons.favorite_rounded,
        size: 13.5,
        color: Color(0xFFFF6B9E),
      );
    }
    return Text(
      emoji,
      style: const TextStyle(fontSize: 11.5, height: 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cleaned = reactions
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) return const SizedBox.shrink();

    final uniqueList = cleaned.toSet().take(3).toList();
    final isSingle = cleaned.length == 1;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        key: const Key('ios26-tapback-badge'),
        width: isSingle ? 20.0 : null,
        height: 20.0,
        constraints: const BoxConstraints(minWidth: 20.0, minHeight: 20.0),
        padding: isSingle
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 5.5),
        decoration: BoxDecoration(
          color: Ios26IMessageTokens.tapbackBlue,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 6,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: isSingle
            ? _buildReactionGlyph(uniqueList.first)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    uniqueList.join(''),
                    style: const TextStyle(fontSize: 11, height: 1.0),
                  ),
                  const SizedBox(width: 2.5),
                  Text(
                    '${cleaned.length}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
