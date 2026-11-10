import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import 'main_shell.dart';
import 'welcome_screen.dart';

/// 2026 Apple HIG Minimalist Splash Screen (واجهة البداية الأنيقة والناعمة ✨):
/// - Clean Deep Sapphire gradient background with soft ambient ruby halo.
/// - Apple spring logo reveal (scale 0.88 -> 1.0, opacity 0.0 -> 1.0) with subtle breathing pulse.
/// - Minimalist typographic badge: "Apolo" + "سوقك الأول فالمغرب 🇲🇦".
/// - Ultra-smooth 400ms cross-fade transition to WelcomeScreen or MainShell.
class SplashScreen extends StatefulWidget {
  final bool hasSeenWelcome;
  final VoidCallback? onCompleteWelcome;

  const SplashScreen({
    super.key,
    required this.hasSeenWelcome,
    this.onCompleteWelcome,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final AppState _state = AppState();
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _glowAnimation;

  Timer? _navigateTimer;

  static const Color _bgTop = Color(0xFF060E18);
  static const Color _bgMid = Color(0xFF0D1D2F);
  static const Color _bgBottom = Color(0xFF050B13);
  static const Color _crimson = Color(0xFFE31B23);

  @override
  void initState() {
    super.initState();

    // Apple fluid spring entrance
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(begin: 0.86, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.70, curve: Curves.easeOutCubic),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.50, curve: Curves.easeIn),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.20, 1.0, curve: Curves.easeInOut),
      ),
    );

    _animController.forward();

    // Haptic feedback subtle tick
    HapticFeedback.lightImpact();

    // Smooth navigation after splash reveal (~1.9 seconds total)
    _navigateTimer = Timer(const Duration(milliseconds: 1900), _proceedToNext);
  }

  @override
  void dispose() {
    _navigateTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _proceedToNext() {
    if (!mounted) return;

    final target = (widget.hasSeenWelcome || _state.isLoggedIn)
        ? const MainShell()
        : WelcomeScreen(
            onContinueAsGuest: widget.onCompleteWelcome,
          );

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 480),
        pageBuilder: (context, animation, secondaryAnimation) => target,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );
          return FadeTransition(opacity: curved, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isAr = _state.s.isAr;

    return Scaffold(
      backgroundColor: _bgBottom,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Clean Velvet Deep Sapphire Gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_bgTop, _bgMid, _bgBottom],
                  stops: [0.0, 0.48, 1.0],
                ),
              ),
            ),

            // 2. Soft Ambient Ruby Halo behind the Logo
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, _) {
                final glow = _glowAnimation.value;
                return Center(
                  child: Container(
                    width: size.width * 0.72,
                    height: size.width * 0.72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _crimson.withValues(alpha: 0.16 * glow),
                          _crimson.withValues(alpha: 0.05 * glow),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.50, 1.0],
                      ),
                    ),
                  ),
                );
              },
            ),

            // 3. Central Brand Unit: Emblem + Wordmark with Apple Spring Animation
            Center(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _opacityAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Apolo Brand Logo
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.09),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/apolo_logo_white.png',
                        height: 52,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/images/apolo_logo.png',
                          height: 52,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Text(
                            'APOLO',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Elegant Tagline Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _crimson.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: _crimson.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: _crimson,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isAr
                                ? 'سوقك الأول فالمغرب 🇲🇦'
                                : 'Marketplace #1 au Maroc 🇲🇦',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Subtle Bottom Minimal Loader & Security Footnote
            Positioned(
              left: 0,
              right: 0,
              bottom: 40,
              child: AnimatedBuilder(
                animation: _opacityAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _opacityAnimation.value,
                    child: child,
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CupertinoActivityIndicator(
                      color: Colors.white54,
                      radius: 9,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Apolo.ma • 2026',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
