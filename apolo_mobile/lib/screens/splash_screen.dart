import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../account/account_helpers.dart';
import '../core/services/qr_web_bridge.dart';
import '../core/state/app_state.dart';
import '../features/bug_report/services/bug_report_controller.dart';
import '../widgets/dl_qr_code.dart';
import 'main_shell.dart';
import 'scan_profile_code_screen.dart';
import 'welcome_screen.dart';

/// Dynamic Layer v5.1 Splash Screen for the APOLO marketplace application:
/// - Pure `#FFFFFF` background matching `web/index.html` (`#apolo-splash`) for zero flash.
/// - Centered crisp APOLO brand mark + `apolo.ma` `#000000` subtitle.
/// - Static, instant, and respects Reduce Motion (`Duration.zero`).
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
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navigateTimer;
  ApoloQrTarget? _initialDeepLink;

  static const Color _dlBg = Color(0xFFFFFFFF);
  static const Color _dlInk = Color(0xFF000000);

  @override
  void initState() {
    super.initState();
    _initialDeepLink =
        kIsWeb ? ApoloProfileQrParser.parseInitialDeepLink(Uri.base) : null;
    if (_initialDeepLink != null) {
      QrWebBridge.clearDeepLinkPathFromAddressBar();
    }

    final googleCode = kIsWeb
        ? Uri.base.queryParameters['google_auth_code']?.trim()
        : null;
    if (googleCode != null && googleCode.isNotEmpty) {
      _completeGoogleCallback(googleCode);
    } else {
      _navigateTimer = Timer(
        _initialDeepLink != null
            ? const Duration(milliseconds: 450)
            : widget.duration,
        _proceedToNext,
      );
    }
  }

  Future<void> _completeGoogleCallback(String code) async {
    final auth = AccountAuth(locale: AppState().locale.languageCode);
    try {
      final session = await auth.exchangeGoogleCode(code);
      await AppState().setAuthSession(session.token, session.user);
      if (!mounted) return;
      _proceedToNext();
    } catch (_) {
      if (!mounted) return;
      _proceedToNext();
    } finally {
      auth.close();
    }
  }

  @override
  void dispose() {
    _navigateTimer?.cancel();
    super.dispose();
  }

  void _proceedToNext() {
    if (!mounted) return;

    final pendingTarget = _initialDeepLink;
    final target = (AppState().isLoggedIn || pendingTarget != null)
        ? const MainShell()
        : WelcomeScreen(onContinueAsGuest: widget.onCompleteWelcome);

    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 260),
        pageBuilder: (context, animation, secondaryAnimation) => target,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );

    if (pendingTarget != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navCtx = BugReportController.navigatorKey.currentContext;
        if (navCtx != null && navCtx.mounted) {
          ScanProfileCodeScreen.navigateToQrTarget(
            navCtx,
            pendingTarget,
            replaceCurrentRoute: false,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final logoSize = (size.width * 0.30).clamp(104.0, 136.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: _dlBg,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _dlBg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: logoSize,
                height: logoSize,
                child: Image.asset(
                  'assets/images/apolo_logo.png',
                  fit: BoxFit.contain,
                  semanticLabel: 'APOLO',
                  errorBuilder: (_, __, ___) => Container(
                    width: logoSize,
                    height: logoSize,
                    decoration: BoxDecoration(
                      color: _dlInk,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'A',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'apolo.ma',
                style: TextStyle(
                  color: _dlInk,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
