import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'main_shell.dart';
import 'welcome_screen.dart';

/// A premium, modern, and minimalist splash screen for the APOLO marketplace application.
///
/// Design Specifications:
/// - Solid, vibrant APOLO red background (#E31828) with absolutely NO gradients.
/// - Original pure white APOLO logo, perfectly centered horizontally and vertically.
/// - Large, clearly visible logo preserving exact proportions and transparency.
/// - Subtle, elegant white curved wave shape at the bottom (~10–15% of screen).
/// - Clean, smooth shapes and premium visual appearance.
/// - Responsive across different smartphone screen sizes.
/// - Shows when the app launches and transitions directly into the main application.
class SplashScreen extends StatefulWidget {
  final bool? hasSeenWelcome;
  final bool targetWelcome;
  final VoidCallback? onCompleteWelcome;
  final Duration duration;

  const SplashScreen({
    super.key,
    this.hasSeenWelcome,
    this.targetWelcome = false,
    this.onCompleteWelcome,
    this.duration = const Duration(milliseconds: 1800),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navigateTimer;

  static const Color _apoloRed = Color(0xFFE31828);

  @override
  void initState() {
    super.initState();
    _navigateTimer = Timer(widget.duration, _proceedToNext);
  }

  @override
  void dispose() {
    _navigateTimer?.cancel();
    super.dispose();
  }

  void _proceedToNext() {
    if (!mounted) return;

    final target = (widget.targetWelcome && widget.hasSeenWelcome == false)
        ? WelcomeScreen(onContinueAsGuest: widget.onCompleteWelcome)
        : const MainShell();

    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) => target,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;

    // Responsive metrics:
    // Wave height occupies ~12-13% of screen height (within the 10-15% target range)
    final waveHeight = (size.height * 0.13).clamp(80.0, 130.0);
    // Logo width is calibrated to be prominently visible without distortion
    final logoWidth = (size.width * 0.62).clamp(210.0, 290.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _apoloRed,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Solid APOLO red background (#E31828) - Absolutely NO gradients
            const ColoredBox(color: _apoloRed),

            // Large, clearly visible white APOLO logo, perfectly centered
            Center(
              child: SizedBox(
                width: logoWidth,
                child: Image.asset(
                  'assets/images/apolo_logo_white_transparent.png',
                  fit: BoxFit.contain,
                  semanticLabel: 'APOLO',
                ),
              ),
            ),

            // Subtle, elegant white curved wave shape at the bottom (~10-15% of screen)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: waveHeight,
              child: const CustomPaint(
                painter: _BottomWavePainter(),
                size: Size.infinite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter rendering a clean, smooth, and elegant white wave at the bottom.
class _BottomWavePainter extends CustomPainter {
  const _BottomWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path();
    // Start at left edge, midway up the wave area
    path.moveTo(0, size.height * 0.52);

    // Smooth cubic bezier wave sweeping across with an elegant curve
    path.cubicTo(
      size.width * 0.32,
      size.height * 0.16,
      size.width * 0.68,
      size.height * 0.84,
      size.width,
      size.height * 0.40,
    );

    // Complete the path along the bottom corners
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
