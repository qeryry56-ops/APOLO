import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/state/app_state.dart';
import 'auth_screen.dart';
import 'main_shell.dart';
import 'widgets/kinetic_widgets.dart';

/// 2026 High-UI Welcome Screen:
/// - Bespoke 2026 3D Octane Rendered Artwork (`welcome_burst_bg.jpg`):
///   Apolo luminous red emblem at the center with high-speed 3D products
///   exploding outward (supercar, fashion, smartphone, laptop, villa, watch, gift boxes,
///   and subtle floating Moroccan Dirham banknotes and coins).
/// - 60fps kinetic pulse, lens-flare glow, and ambient floating sparkles.
/// - Conversion-optimized Apple Whitespace action deck with Email, Google, and Guest entry.
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
    with SingleTickerProviderStateMixin {
  final AppState _state = AppState();
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChanged);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
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
      backgroundColor: const Color(0xFF070A11),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Bespoke 3D Octane Rendered Artwork (Apolo Emblem + High-Speed Category Burst)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + (_pulseController.value * 0.025);
                return Transform.scale(
                  scale: scale,
                  alignment: const Alignment(0.0, -0.28),
                  child: child,
                );
              },
              child: Image.asset(
                'assets/images/welcome_burst_bg.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/images/welcome_burst_bg.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
          ),

          // 2. Dynamic 2026 Kinetic Energy Flares & Sparkles on the Central Core
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                final t = _pulseController.value;
                return CustomPaint(
                  painter: _ApoloEnergyGlowPainter(pulseProgress: t),
                );
              },
            ),
          ),

          // 3. Deep Vignette at Bottom to Guarantee 100% Contrast for Buttons & Text
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: size.height * 0.54,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF070A11).withValues(alpha: 0.0),
                      const Color(0xFF070A11).withValues(alpha: 0.72),
                      const Color(0xFF070A11).withValues(alpha: 0.94),
                      const Color(0xFF070A11),
                    ],
                    stops: const [0.0, 0.32, 0.65, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // 4. Floating UI Controls & Conversion Deck
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 22.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Row: Language Toggle + Live Morocco Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLanguagePill(isAr),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.40),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF10B981),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 7),
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

                  // Value Proposition Copy
                  ScrollReveal(
                    delay: const Duration(milliseconds: 60),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE31B23).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color(0xFFE31B23).withValues(alpha: 0.45),
                            ),
                          ),
                          child: Text(
                            isAr
                                ? '⚡ بيع وشري بسرعة البرق وبلا عمولة'
                                : '⚡ Vendez et achetez à la vitesse de l\'éclair',
                            style: const TextStyle(
                              color: Color(0xFFFF9AA0),
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
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                            height: 1.22,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isAr
                              ? 'طوموبيلات، هواتف، حوايج، عقارات وجميع الفئات بين يديك بأمان وسرعة'
                              : 'Voitures, smartphones, mode, immobilier et toutes les catégories à portée de main',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.74),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Primary Button: Continue with Email/Phone (Apolo Crimson Glow)
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
                          colors: [Color(0xFFE31B23), Color(0xFFB80D15)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE31B23).withValues(alpha: 0.50),
                            blurRadius: 24,
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

                  // Secondary Button: Continue with Google (Clean White Surface)
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
                            color: Colors.black.withValues(alpha: 0.28),
                            blurRadius: 18,
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

                  // Ghost Button: Guest Mode
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

                  // Legal Footer
                  Text(
                    s.tr(
                      'بمتابعتك، أنت توافق على شروط الاستخدام وسياسة الخصوصية لـ Apolo.ma',
                      'En continuant, vous acceptez les conditions d\'utilisation d\'Apolo.ma',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
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

  Widget _buildLanguagePill(bool isAr) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _state.toggleLanguage();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
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

/// Kinetic Energy Flare Overlay Painter:
/// Adds dynamic breathing glow and light refraction directly on the Apolo logo burst core
class _ApoloEnergyGlowPainter extends CustomPainter {
  final double pulseProgress;

  const _ApoloEnergyGlowPainter({required this.pulseProgress});

  @override
  void paint(Canvas canvas, Size size) {
    // The core logo is centered horizontally at roughly 32% from the top
    final center = Offset(size.width * 0.5, size.height * 0.32);
    final radius = size.width * 0.42;

    // Breathing radiant crimson glow
    final glowAlpha = (0.16 + (0.10 * pulseProgress)).clamp(0.0, 1.0);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFE31B23).withValues(alpha: glowAlpha),
          const Color(0xFFE31B23).withValues(alpha: glowAlpha * 0.35),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, glowPaint);

    // Subtle orbiting light particles
    final rnd = math.Random(42);
    for (int i = 0; i < 14; i++) {
      final baseAngle = rnd.nextDouble() * 2 * math.pi;
      final angle = baseAngle + (pulseProgress * 0.3);
      final dist = (size.width * 0.20) + (rnd.nextDouble() * size.width * 0.35);
      final p = Offset(
        center.dx + math.cos(angle) * dist,
        center.dy + math.sin(angle) * dist * 0.9,
      );
      final pAlpha = (0.2 + 0.4 * math.sin(pulseProgress * math.pi + i)).clamp(0.0, 0.7);
      final dotPaint = Paint()
        ..color = (i % 2 == 0 ? Colors.white : const Color(0xFFFF5252))
            .withValues(alpha: pAlpha);
      canvas.drawCircle(p, 1.5 + (i % 3) * 0.8, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ApoloEnergyGlowPainter oldDelegate) {
    return oldDelegate.pulseProgress != pulseProgress;
  }
}
