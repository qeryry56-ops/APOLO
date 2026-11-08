import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/state/app_state.dart';
import 'auth_screen.dart';
import 'main_shell.dart';
import 'widgets/kinetic_widgets.dart';

class _BurstItemSpec {
  final String asset;
  final String labelAr;
  final String labelFr;
  final double angleDeg;
  final double maxRadiusFactor;
  final double baseSize;
  final double speedMultiplier;
  final double phaseOffset;
  final Color glowColor;

  const _BurstItemSpec({
    required this.asset,
    required this.labelAr,
    required this.labelFr,
    required this.angleDeg,
    required this.maxRadiusFactor,
    required this.baseSize,
    required this.speedMultiplier,
    required this.phaseOffset,
    required this.glowColor,
  });
}

class _SubtleParticleSpec {
  final String textOrEmoji;
  final IconData? icon;
  final double angleDeg;
  final double radiusFactor;
  final double phaseOffset;
  final double opacity;
  final double size;
  final Color color;

  const _SubtleParticleSpec({
    this.textOrEmoji = '',
    this.icon,
    required this.angleDeg,
    required this.radiusFactor,
    required this.phaseOffset,
    required this.opacity,
    required this.size,
    required this.color,
  });
}

/// 2026 High-UI Welcome Screen:
/// - Central Apolo 3D Emblem with shockwave pulse & high-speed radial speed lines
/// - All marketplace categories & flagship products (Car, Fashion, iPhone, MacBook,
///   Real Estate, Jewelry, Travel, Home) bursting outward at high speed with 3D depth
/// - Soft, subtle Gifts & Cash accents floating in the ambient depth layer
/// - Brand color palette (#090D16 obsidian, #E31B23 Apolo Crimson, #FFFFFF pure white)
class WelcomeScreen extends StatefulWidget {
  final VoidCallback? onContinueAsGuest;

  const WelcomeScreen({
    super.key,
    this.onContinueAsGuest,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  final AppState _state = AppState();
  late final AnimationController _burstController;
  late final AnimationController _pulseController;

  // High-speed 3D Marketplace Categories & Products bursting out of Apolo Logo
  static const List<_BurstItemSpec> _burstItems = [
    _BurstItemSpec(
      asset: 'assets/images/hero_car.png',
      labelAr: 'سيارات',
      labelFr: 'Auto',
      angleDeg: -38,
      maxRadiusFactor: 0.43,
      baseSize: 78,
      speedMultiplier: 1.0,
      phaseOffset: 0.00,
      glowColor: Color(0xFFE31B23),
    ),
    _BurstItemSpec(
      asset: 'assets/images/cat_fashion.png',
      labelAr: 'ملابس وموضة',
      labelFr: 'Mode',
      angleDeg: -142,
      maxRadiusFactor: 0.42,
      baseSize: 66,
      speedMultiplier: 1.0,
      phaseOffset: 0.14,
      glowColor: Color(0xFFFF4D6D),
    ),
    _BurstItemSpec(
      asset: 'assets/images/cat_phones.png',
      labelAr: 'هواتف',
      labelFr: 'Phones',
      angleDeg: 18,
      maxRadiusFactor: 0.44,
      baseSize: 64,
      speedMultiplier: 1.0,
      phaseOffset: 0.28,
      glowColor: Color(0xFF38BDF8),
    ),
    _BurstItemSpec(
      asset: 'assets/images/cat_realestate.png',
      labelAr: 'عقارات',
      labelFr: 'Immo',
      angleDeg: 158,
      maxRadiusFactor: 0.43,
      baseSize: 66,
      speedMultiplier: 1.0,
      phaseOffset: 0.42,
      glowColor: Color(0xFFF59E0B),
    ),
    _BurstItemSpec(
      asset: 'assets/images/cat_computers.png',
      labelAr: 'حواسيب',
      labelFr: 'Tech',
      angleDeg: -92,
      maxRadiusFactor: 0.39,
      baseSize: 62,
      speedMultiplier: 1.0,
      phaseOffset: 0.56,
      glowColor: Color(0xFFA855F7),
    ),
    _BurstItemSpec(
      asset: 'assets/images/cat_jewelry.png',
      labelAr: 'مجوهرات',
      labelFr: 'Bijoux',
      angleDeg: 68,
      maxRadiusFactor: 0.37,
      baseSize: 58,
      speedMultiplier: 1.0,
      phaseOffset: 0.70,
      glowColor: Color(0xFFFBBF24),
    ),
    _BurstItemSpec(
      asset: 'assets/images/cat_home.png',
      labelAr: 'أثاث وديكور',
      labelFr: 'Maison',
      angleDeg: 115,
      maxRadiusFactor: 0.37,
      baseSize: 58,
      speedMultiplier: 1.0,
      phaseOffset: 0.84,
      glowColor: Color(0xFF10B981),
    ),
    _BurstItemSpec(
      asset: 'assets/images/cat_travel.png',
      labelAr: 'أسفار وعطل',
      labelFr: 'Voyages',
      angleDeg: -168,
      maxRadiusFactor: 0.38,
      baseSize: 56,
      speedMultiplier: 1.0,
      phaseOffset: 0.92,
      glowColor: Color(0xFFEC4899),
    ),
  ];

  // Lightweight, subtle Gifts & Cash floating particles ("IKONO HTA GIFTS O FLOS MAKINOCH BAYNIIN BZZF IKONO KHFAF CHWYA")
  static const List<_SubtleParticleSpec> _subtleGiftsAndCash = [
    _SubtleParticleSpec(
      icon: CupertinoIcons.gift_fill,
      angleDeg: -65,
      radiusFactor: 0.34,
      phaseOffset: 0.10,
      opacity: 0.28,
      size: 18,
      color: Color(0xFFFF8FA3),
    ),
    _SubtleParticleSpec(
      textOrEmoji: '200 DH',
      icon: CupertinoIcons.money_dollar_circle_fill,
      angleDeg: -118,
      radiusFactor: 0.36,
      phaseOffset: 0.32,
      opacity: 0.24,
      size: 15,
      color: Color(0xFF34D399),
    ),
    _SubtleParticleSpec(
      icon: CupertinoIcons.gift,
      angleDeg: 42,
      radiusFactor: 0.35,
      phaseOffset: 0.52,
      opacity: 0.25,
      size: 17,
      color: Color(0xFFFBBF24),
    ),
    _SubtleParticleSpec(
      textOrEmoji: 'MAD',
      icon: CupertinoIcons.creditcard_fill,
      angleDeg: 138,
      radiusFactor: 0.33,
      phaseOffset: 0.73,
      opacity: 0.22,
      size: 15,
      color: Color(0xFF6EE7B7),
    ),
    _SubtleParticleSpec(
      icon: CupertinoIcons.gift_alt_fill,
      angleDeg: -12,
      radiusFactor: 0.30,
      phaseOffset: 0.88,
      opacity: 0.24,
      size: 16,
      color: Color(0xFFF43F5E),
    ),
    _SubtleParticleSpec(
      textOrEmoji: '+DH',
      angleDeg: -155,
      radiusFactor: 0.29,
      phaseOffset: 0.45,
      opacity: 0.20,
      size: 14,
      color: Color(0xFF34D399),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChanged);
    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6200),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    _burstController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _enterMainApp() {
    if (widget.onContinueAsGuest != null) {
      widget.onContinueAsGuest!();
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final isAr = s.isAr;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Deep Studio Brand Gradient Canvas (Apolo Crimson + Obsidian + Soft White Highlights)
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.26),
                radius: 0.98,
                colors: [
                  Color(0xFF4C0910), // Warm deep Apolo crimson core
                  Color(0xFF1A0A12), // Rich dark ruby midtone
                  Color(0xFF090D16), // Deep 2026 obsidian outer edge
                ],
                stops: [0.0, 0.48, 1.0],
              ),
            ),
          ),

          // 2. High-Speed Radial Warp Lines & Energy Rings (CustomPainter 60fps)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_burstController, _pulseController]),
              builder: (context, _) {
                return CustomPaint(
                  painter: _ApoloSpeedBurstPainter(
                    burstProgress: _burstController.value,
                    pulseProgress: _pulseController.value,
                    centerAlignment: const Alignment(0.0, -0.26),
                  ),
                );
              },
            ),
          ),

          // 3. Live 3D Burst Stage: Central Apolo Logo + High-Speed Flying Categories + Subtle Gifts & Cash
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.62,
            child: AnimatedBuilder(
              animation: Listenable.merge([_burstController, _pulseController]),
              builder: (context, _) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final stageW = constraints.maxWidth;
                    final stageH = constraints.maxHeight;
                    final centerX = stageW * 0.5;
                    final centerY = stageH * 0.56;
                    final minDim = math.min(stageW, stageH);

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // 3A. Subtle Lightweight Gifts & Cash Layer (Soft opacity so they don't overpower)
                        ..._subtleGiftsAndCash.map((p) {
                          final rawT =
                              (_burstController.value + p.phaseOffset) % 1.0;
                          final easedT = Curves.easeOutCubic.transform(rawT);
                          final rad = p.angleDeg * math.pi / 180.0;
                          final dist =
                              minDim * (0.12 + (p.radiusFactor * easedT));
                          final dx = centerX + math.cos(rad) * dist;
                          final dy = centerY + math.sin(rad) * dist * 0.88;

                          // Fade in from center, stay soft, fade out at edge
                          final fade = rawT < 0.18
                              ? (rawT / 0.18)
                              : (rawT > 0.82 ? (1.0 - rawT) / 0.18 : 1.0);
                          final effectiveOpacity =
                              (p.opacity * fade).clamp(0.0, 0.35);

                          return Positioned(
                            left: dx - 24,
                            top: dy - 14,
                            child: Opacity(
                              opacity: effectiveOpacity,
                              child: Transform.scale(
                                scale: 0.72 + (0.38 * easedT),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: p.color.withValues(alpha: 0.38),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (p.icon != null)
                                        Icon(
                                          p.icon,
                                          size: p.size,
                                          color: p.color,
                                        ),
                                      if (p.textOrEmoji.isNotEmpty) ...[
                                        if (p.icon != null)
                                          const SizedBox(width: 4),
                                        Text(
                                          p.textOrEmoji,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),

                        // 3B. High-Speed 3D Category & Product Burst Cutouts
                        ..._burstItems.map((item) {
                          final rawT =
                              (_burstController.value * item.speedMultiplier +
                                      item.phaseOffset) %
                                  1.0;
                          // Fast explosive launch out of logo, then smooth cruise
                          final easedT = Curves.easeOutQuart.transform(rawT);
                          final rad = item.angleDeg * math.pi / 180.0;
                          final startRadius = minDim * 0.08;
                          final endRadius = minDim * item.maxRadiusFactor;
                          final currentRadius =
                              startRadius + (endRadius - startRadius) * easedT;

                          final wobble = math.sin(
                                (_burstController.value * 2 * math.pi) +
                                    item.phaseOffset * 8,
                              ) *
                              4.0;

                          final dx = centerX + math.cos(rad) * currentRadius;
                          final dy = centerY +
                              math.sin(rad) * currentRadius * 0.86 +
                              wobble;

                          final scale = 0.32 + (0.78 * easedT);
                          final opacity = rawT < 0.10
                              ? (rawT / 0.10)
                              : (rawT > 0.86 ? (1.0 - rawT) / 0.14 : 1.0);

                          return Positioned(
                            left: dx - (item.baseSize * 0.65),
                            top: dy - (item.baseSize * 0.65),
                            child: Opacity(
                              opacity: opacity.clamp(0.0, 1.0),
                              child: Transform.scale(
                                scale: scale,
                                child: _buildFlyingCategoryCard(
                                  item: item,
                                  isAr: isAr,
                                ),
                              ),
                            ),
                          );
                        }),

                        // 3C. Central Pulsing 3D Apolo Core Hub (Everything bursts from here!)
                        Positioned(
                          left: centerX - 66,
                          top: centerY - 66,
                          child: _buildCentralApoloCore(
                            pulseValue: _pulseController.value,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // 4. Bottom Gradient Vignette for Seamless Readability
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: size.height * 0.48,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF090D16).withValues(alpha: 0.0),
                      const Color(0xFF090D16).withValues(alpha: 0.88),
                      const Color(0xFF090D16),
                    ],
                    stops: const [0.0, 0.38, 0.72],
                  ),
                ),
              ),
            ),
          ),

          // 5. Foreground Top Bar + Bottom High-Conversion 2026 Action Deck
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Bar: Language Toggle + Live 2026 Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLanguageToggle(isAr),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isAr
                                  ? 'السوق رقم #1 فالمغرب 🇲🇦'
                                  : 'Marketplace #1 au Maroc 🇲🇦',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Headline & Value Proposition
                  ScrollReveal(
                    delay: const Duration(milliseconds: 80),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFE31B23).withValues(alpha: 0.28),
                                const Color(0xFFFF6B6B).withValues(alpha: 0.14),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color(0xFFE31B23)
                                  .withValues(alpha: 0.55),
                            ),
                          ),
                          child: Text(
                            isAr
                                ? '⚡ بيع وشري بسرعة البرق وبلا عمولة'
                                : '⚡ Vendez et achetez à la vitesse de l\'éclair',
                            style: const TextStyle(
                              color: Color(0xFFFFB3B6),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          s.tr(
                            'كل ما تحتاجه للبيع والشراء في المغرب',
                            'Tout pour acheter et vendre au Maroc',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            height: 1.22,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isAr
                              ? 'طوموبيلات، حوايج، عقارات، هواتف وجميع الفئات كيتسناوك فبلاصة وحدة!'
                              : 'Voitures, mode, immobilier, téléphones et toutes les catégories en un seul endroit !',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Primary Button: Continue with Email/Phone (Apolo Red)
                  PressableScale(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AuthScreen(
                            initialIsLogin: true,
                            onSuccess: _enterMainApp,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE31B23), Color(0xFFC81018)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE31B23)
                                .withValues(alpha: 0.45),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            CupertinoIcons.envelope_fill,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            s.tr(
                              'المتابعة بالبريد أو الهاتف',
                              'Continuer avec Email ou Téléphone',
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Secondary Button: Continue with Google (Pure White)
                  PressableScale(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AuthScreen(
                            initialIsLogin: true,
                            autoTriggerGoogle: true,
                            onSuccess: _enterMainApp,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.22),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'G',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFEA4335),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            s.tr('المتابعة عبر Google', 'Continuer avec Google'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Ghost Button: Continue as Guest
                  TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _enterMainApp();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          s.tr('تصفح كزائر بدون حساب', 'Continuer en tant qu\'invité'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withValues(alpha: 0.90),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          isAr
                              ? CupertinoIcons.arrow_left_circle_fill
                              : CupertinoIcons.arrow_right_circle_fill,
                          size: 18,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Terms & Privacy Footer
                  Text(
                    s.tr(
                      'بمتابعتك، أنت توافق على شروط الاستخدام وسياسة الخصوصية لـ Apolo.ma',
                      'En continuant, vous acceptez les conditions d\'utilisation d\'Apolo.ma',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.48),
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCentralApoloCore({required double pulseValue}) {
    final ringScale = 1.0 + (pulseValue * 0.14);
    return SizedBox(
      width: 132,
      height: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glowing shockwave ring
          Transform.scale(
            scale: ringScale,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFE31B23).withValues(alpha: 0.55),
                    const Color(0xFFE31B23).withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Crisp 3D Glass Core Sphere with Apolo Logo
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE31B23),
                  Color(0xFFB30E15),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.65),
                width: 2.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE31B23).withValues(alpha: 0.65),
                  blurRadius: 32,
                  spreadRadius: 6,
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Image.asset(
                'assets/images/apolo_logo_white.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  CupertinoIcons.flame_fill,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlyingCategoryCard({
    required _BurstItemSpec item,
    required bool isAr,
  }) {
    final label = isAr ? item.labelAr : item.labelFr;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: item.baseSize,
          height: item.baseSize,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.13),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.32),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: item.glowColor.withValues(alpha: 0.36),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Image.asset(
            item.asset,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              CupertinoIcons.cube_box_fill,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 0.8,
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageToggle(bool isAr) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _state.toggleLanguage();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.24),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.globe,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  isAr ? 'Français' : 'العربية',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
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

/// CustomPainter for 2026 High-Speed Radial Warp Lines & Expanding Energy Rings
class _ApoloSpeedBurstPainter extends CustomPainter {
  final double burstProgress;
  final double pulseProgress;
  final Alignment centerAlignment;

  const _ApoloSpeedBurstPainter({
    required this.burstProgress,
    required this.pulseProgress,
    required this.centerAlignment,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width * (0.5 + centerAlignment.x * 0.5),
      size.height * (0.5 + centerAlignment.y * 0.5),
    );
    final maxRadius = math.max(size.width, size.height) * 0.68;

    // 1. Expanding Shockwave Rings in Apolo Brand Colors
    for (int i = 0; i < 3; i++) {
      final ringT = (burstProgress + (i / 3.0)) % 1.0;
      final radius = 44.0 + (maxRadius * 0.65 * ringT);
      final alpha = (1.0 - ringT) * 0.22;
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = (i.isEven ? const Color(0xFFE31B23) : Colors.white)
            .withValues(alpha: alpha.clamp(0.0, 1.0));
      canvas.drawCircle(center, radius, ringPaint);
    }

    // 2. High-Speed Radial Streak Lines shooting outward from the Apolo Logo
    const int rayCount = 28;
    for (int i = 0; i < rayCount; i++) {
      final angle = (i * 2 * math.pi / rayCount) + 0.12;
      final speedShift = ((burstProgress * 2.0) + (i * 0.17)) % 1.0;
      final innerDist = 48.0 + (maxRadius * 0.55 * speedShift);
      final streakLen = 26.0 + (48.0 * speedShift);
      final outerDist = innerDist + streakLen;

      final p1 = Offset(
        center.dx + math.cos(angle) * innerDist,
        center.dy + math.sin(angle) * innerDist * 0.88,
      );
      final p2 = Offset(
        center.dx + math.cos(angle) * outerDist,
        center.dy + math.sin(angle) * outerDist * 0.88,
      );

      final isRedRay = i % 3 == 0;
      final alpha = (1.0 - speedShift) * (isRedRay ? 0.42 : 0.22);

      final streakPaint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = isRedRay ? 2.2 : 1.3
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            (isRedRay ? const Color(0xFFFF3B42) : Colors.white)
                .withValues(alpha: alpha.clamp(0.0, 1.0)),
          ],
        ).createShader(Rect.fromPoints(p1, p2));

      canvas.drawLine(p1, p2, streakPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ApoloSpeedBurstPainter oldDelegate) {
    return oldDelegate.burstProgress != burstProgress ||
        oldDelegate.pulseProgress != pulseProgress;
  }
}
