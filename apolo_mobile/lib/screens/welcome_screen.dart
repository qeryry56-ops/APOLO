import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/state/app_state.dart';
import 'auth_screen.dart';
import 'main_shell.dart';
import 'widgets/kinetic_widgets.dart';

/// 2026 Apple HIG Minimalist Welcome Screen (شاشة الترحيب الفاخرة والبسيطة ✨):
/// - Clean, deep velvety sapphire background with soft ambient ruby halo (No visual clutter).
/// - Central Apple frosted glass brand hero with official Apolo logo & 3 trust pills.
/// - Apple Whitespace layout with clear hierarchy & high-contrast typography.
/// - Conversion-optimized action deck: Email/Phone, Google, and Guest mode.
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
  late final AnimationController _ambientController;

  static const Color _bgTop = Color(0xFF060E18);
  static const Color _bgMid = Color(0xFF0C1B2E);
  static const Color _bgBottom = Color(0xFF050B13);
  static const Color _primary = Color(0xFFE31B23);

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChanged);
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    _ambientController.dispose();
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
      backgroundColor: _bgBottom,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Clean Deep Velvet Sapphire Canvas
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_bgTop, _bgMid, _bgBottom],
                  stops: [0.0, 0.42, 1.0],
                ),
              ),
            ),

            // 2. Soft Ambient Ruby Backlight Halo (Subtle, Calm, Studio-Grade)
            AnimatedBuilder(
              animation: _ambientController,
              builder: (context, _) {
                final pulse = _ambientController.value;
                return Positioned(
                  top: size.height * 0.12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: size.width * 0.85,
                      height: size.width * 0.85,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _primary.withValues(alpha: 0.14 + (pulse * 0.05)),
                            _primary.withValues(alpha: 0.04 + (pulse * 0.02)),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.52, 1.0],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // 3. Subtle Frosted Ambient Highlights
            Positioned(
              top: -size.width * 0.3,
              right: -size.width * 0.2,
              child: Container(
                width: size.width * 0.8,
                height: size.width * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
                ),
              ),
            ),

            // 4. Main Foreground UI
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22.0,
                  vertical: 14.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Bar: Language Switcher + Morocco Verification Pill
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
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.14),
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
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Spacer(flex: 1),

                    // Central Apple Glass Brand Hero (Simple, Premium, Focused)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Frosted Squircle Emblem Tile
                          ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                              child: Container(
                                width: 92,
                                height: 92,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primary.withValues(alpha: 0.22),
                                      blurRadius: 28,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Image.asset(
                                  'assets/images/apolo_logo_white.png',
                                  width: 64,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Image.asset(
                                    'assets/images/apolo_icon_white.png',
                                    width: 54,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Text(
                                      'A',
                                      style: TextStyle(
                                        fontSize: 44,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Three Clean Trust Pills
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildTrustPill(isAr ? '0% عمولة' : '0% Commission', CupertinoIcons.percent),
                              const SizedBox(width: 8),
                              _buildTrustPill(isAr ? 'شات فوري' : 'Chat direct', CupertinoIcons.chat_bubble_2_fill),
                              const SizedBox(width: 8),
                              _buildTrustPill(isAr ? 'حسابات موثقة' : 'Comptes vérifiés', CupertinoIcons.checkmark_shield_fill),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 2),

                    // Value Proposition Heading & Subtitle
                    ScrollReveal(
                      delay: const Duration(milliseconds: 60),
                      child: Column(
                        children: [
                          Text(
                            s.tr(
                              'كل ما تحتاجه للبيع والشراء في المغرب',
                              'Tout pour acheter et vendre au Maroc',
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              height: 1.24,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            isAr
                                ? 'طوموبيلات، هواتف، عقارات وأكثر من 3,000 إعلان مباشر بدون وسيط وبكل أمان.'
                                : 'Voitures, smartphones, immobilier et plus de 3 000 annonces en direct sans intermédiaire.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),

                    // Primary Button: Email / Phone
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
                            colors: [Color(0xFFE31B23), Color(0xFFBA0C13)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: _primary.withValues(alpha: 0.42),
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
                              size: 19,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              s.tr(
                                'المتابعة بالبريد أو الهاتف',
                                'Continuer avec Email ou Téléphone',
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Secondary Button: Google
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
                              offset: const Offset(0, 5),
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
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

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
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.88),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            isAr
                                ? CupertinoIcons.arrow_left_circle_fill
                                : CupertinoIcons.arrow_right_circle_fill,
                            size: 17,
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
                        color: Colors.white.withValues(alpha: 0.40),
                        fontSize: 10.5,
                        height: 1.35,
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

  Widget _buildTrustPill(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFFFF4D55)),
          const SizedBox(width: 5),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
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
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.globe,
                  color: Colors.white,
                  size: 15,
                ),
                const SizedBox(width: 6),
                Text(
                  isAr ? 'Français' : 'العربية',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
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
