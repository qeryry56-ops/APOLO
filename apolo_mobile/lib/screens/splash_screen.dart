import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/state/app_state.dart';
import 'main_shell.dart';
import 'welcome_screen.dart';

/// A brief brand introduction before the existing onboarding flow.
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

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navigateTimer;

  @override
  void initState() {
    super.initState();
    _navigateTimer = Timer(const Duration(milliseconds: 650), _proceedToNext);
  }

  @override
  void dispose() {
    _navigateTimer?.cancel();
    super.dispose();
  }

  void _proceedToNext() {
    if (!mounted) return;

    final target = (widget.hasSeenWelcome || AppState().isLoggedIn)
        ? const MainShell()
        : WelcomeScreen(onContinueAsGuest: widget.onCompleteWelcome);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
        pageBuilder: (context, animation, secondaryAnimation) => target,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Image.asset(
                'assets/images/apolo_logo.png',
                width: 112,
                height: 112,
                fit: BoxFit.contain,
                semanticLabel: 'Apolo',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
