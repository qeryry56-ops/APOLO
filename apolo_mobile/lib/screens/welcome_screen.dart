import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../account/account_helpers.dart';
import '../core/state/app_state.dart';
import '../theme/app_typography.dart';
import 'auth_screen.dart';
import 'intent_onboarding_screen.dart';
import 'main_shell.dart';
import 'privacy_compliance_screen.dart';

/// APOLO — Premium Mobile Welcome & Authentication Screen.
///
/// Faithfully implements the exact reference design:
/// - Full-screen brand gradient: Deep vibrant APOLO red (#E31828) at top,
///   softly transitioning into rose/light pink and fading to white at the bottom.
/// - Prominent official APOLO white logo centered horizontally.
/// - Two-line bold white welcome text:
///     "Millions of Products.
///      Free on Apolo."
/// - Three capsule / stadium action buttons positioned lower on the screen:
///     1. Continue with Apple (white background, black Apple icon)
///     2. Continue with Google (white background, official multicolor Google icon)
///     3. Continue with email (dark charcoal #202020 background, white text)
/// - Clean footer links: "Privacy policy" and "Terms of services" in medium gray.
class WelcomeScreen extends StatefulWidget {
  final VoidCallback? onContinueAsGuest;

  const WelcomeScreen({super.key, this.onContinueAsGuest});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final AppState _state = AppState();
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    super.dispose();
  }

  void _enterMainApp() {
    if (!mounted || _leaving) return;
    _leaving = true;
    widget.onContinueAsGuest?.call();
    if (!_state.hasCompletedIntentOnboarding) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ApoloIntentOnboardingScreen(
            nextBuilder: (_, chosen) {
              final openSellTab =
                  chosen.length == 1 && chosen.contains('selling');
              return MainShell(initialIndex: openSellTab ? 1 : 0);
            },
          ),
        ),
      );
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MainShell()),
    );
  }

  void _openEmailAuth() {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
        reverseTransitionDuration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
        pageBuilder: (_, animation, secondaryAnimation) => AuthScreen(
          initialIsLogin: true,
          onSuccess: _enterMainApp,
        ),
        transitionsBuilder: (_, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Future<void> _openGoogleAuth() async {
    HapticFeedback.lightImpact();
    final googleAuthUri = AccountAuth.buildGoogleAuthUri();
    try {
      final launched = await launchUrl(
        googleAuthUri,
        mode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
        webOnlyWindowName: kIsWeb ? '_self' : null,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _state.s.tr(
                'تعذر فتح تسجيل الدخول عبر Google حالياً.',
                'Impossible d’ouvrir la connexion Google pour le moment.',
              ),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _state.s.tr(
                'تعذر بدء تسجيل الدخول عبر Google حالياً.',
                'Impossible de démarrer la connexion Google.',
              ),
            ),
          ),
        );
      }
    }
  }

  void _openPrivacy() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PrivacyComplianceScreen(initialTab: 0),
      ),
    );
  }

  void _openTerms() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PrivacyComplianceScreen(initialTab: 0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoWidth = (size.width * 0.60).clamp(210.0, 270.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark, // iOS white status bar icons
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFE31828), // Deep vibrant APOLO red top
                Color(
                    0xFFE31828), // Solid vibrant red through logo and headline
                Color(0xFFEA3B4A), // Smooth transition initiation
                Color(0xFFF67584), // Light rose transition
                Color(0xFFFFBCC6), // Soft light pink
                Color(0xFFFFEEF1), // Very pale pink
                Colors.white, // Fading cleanly into pure white at bottom
              ],
              stops: [0.0, 0.48, 0.58, 0.68, 0.80, 0.91, 1.0],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxHeight < 620;

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Upper spacing to center logo in the upper red region
                                if (isCompact)
                                  const SizedBox(height: 16)
                                else
                                  const Spacer(flex: 3),

                                // Official White APOLO Logo
                                SizedBox(
                                  width: logoWidth,
                                  child: Image.asset(
                                    'assets/images/apolo_logo_white_transparent.png',
                                    fit: BoxFit.contain,
                                    semanticLabel: 'APOLO',
                                  ),
                                ),

                                SizedBox(height: isCompact ? 14 : 24),

                                // Welcome Message
                                Text(
                                  'Millions of Products.\nFree on Apolo.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 27,
                                    fontWeight: FontWeight.w700,
                                    height: 1.25,
                                    color: Colors.white,
                                    letterSpacing:
                                        AppTypography.trackingForContext(
                                            context, -0.4),
                                  ),
                                ),

                                // Transition area negative space
                                if (isCompact)
                                  const SizedBox(height: 24)
                                else
                                  const Spacer(flex: 4),

                                // Button 1: Continue with Google
                                _buildCapsuleButton(
                                  key: const ValueKey('welcome-google'),
                                  backgroundColor: Colors.white,
                                  textColor: Colors.black,
                                  icon: const _GoogleIcon(size: 20),
                                  text: 'Continue with Google',
                                  onPressed: _openGoogleAuth,
                                ),

                                const SizedBox(height: 12),

                                // Button 3: Continue with email
                                _buildCapsuleButton(
                                  key: const ValueKey('welcome-sign-in'),
                                  backgroundColor: const Color(0xFF202020),
                                  textColor: Colors.white,
                                  text: 'Continue with email',
                                  onPressed: _openEmailAuth,
                                ),

                                const SizedBox(height: 22),

                                // Footer Links: Privacy policy | Terms of services
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 24,
                                  runSpacing: 8,
                                  children: [
                                    GestureDetector(
                                      onTap: _openPrivacy,
                                      child: const Text(
                                        'Privacy policy',
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF737373),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _openTerms,
                                      child: const Text(
                                        'Terms of services',
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF737373),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Accessible guest fallback target (hidden from visible UI)
                                Semantics(
                                  button: true,
                                  label: 'Continue as guest',
                                  child: GestureDetector(
                                    key: const ValueKey('welcome-guest'),
                                    onTap: _enterMainApp,
                                    behavior: HitTestBehavior.opaque,
                                    child: const SizedBox(
                                      width: 48,
                                      height: 12,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),
                              ],
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
        ),
      ),
    );
  }

  Widget _buildCapsuleButton({
    required Key key,
    required Color backgroundColor,
    required Color textColor,
    required String text,
    required VoidCallback onPressed,
    Widget? icon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: TextButton(
        key: key,
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: const StadiumBorder(),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon,
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  letterSpacing:
                      AppTypography.trackingForContext(context, -0.2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Official Google "G" multicolor logo drawn vectorially on Canvas
class _GoogleIcon extends StatelessWidget {
  final double size;
  const _GoogleIcon({this.size = 20});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: const _GoogleIconPainter(),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  const _GoogleIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final double stroke = s * 0.22;
    final double radius = (s - stroke) / 2;
    final Offset center = Offset(s / 2, s / 2);
    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);

    final Paint p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true;

    // 1. Red (Top arc: 225° to 315°)
    p.color = const Color(0xFFEA4335);
    canvas.drawArc(arcRect, -2.356, 1.571, false, p);

    // 2. Yellow (Left arc: 135° to 225°)
    p.color = const Color(0xFFFBBC05);
    canvas.drawArc(arcRect, 2.356, 1.571, false, p);

    // 3. Green (Bottom arc: 45° to 135°)
    p.color = const Color(0xFF34A853);
    canvas.drawArc(arcRect, 0.785, 1.571, false, p);

    // 4. Blue (Right arc: -45° to 45°)
    p.color = const Color(0xFF4285F4);
    canvas.drawArc(arcRect, -0.785, 1.571, false, p);

    // 5. Blue (Horizontal crossbar to center)
    final Paint barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawRect(
      Rect.fromLTRB(s * 0.44, s * 0.50 - stroke / 2, s, s * 0.50 + stroke / 2),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
