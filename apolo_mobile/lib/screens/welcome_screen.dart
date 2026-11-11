import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import 'auth_screen.dart';
import 'main_shell.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback? onContinueAsGuest;

  const WelcomeScreen({super.key, this.onContinueAsGuest});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final AppState _state = AppState();
  static const _ink = Colors.black;
  static const _muted = Color(0xFF626262);
  static const _surface = Color(0xFFF4F4F4);
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
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MainShell()),
    );
  }

  void _openSignIn({bool register = false}) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
        reverseTransitionDuration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
        pageBuilder: (_, animation, secondaryAnimation) => AuthScreen(
          initialIsLogin: !register,
          onSuccess: _enterMainApp,
        ),
        transitionsBuilder: (_, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final isAr = s.isAr;
    final fontFamily = isAr ? 'IBMPlexSansArabic' : AppConfig.fontPrimary;
    final buttonTextStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.4,
    );

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
                      sliver: SliverFillRemaining(
                        hasScrollBody: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: TextButton(
                                key: const ValueKey('welcome-language'),
                                onPressed: _state.toggleLanguage,
                                style: TextButton.styleFrom(
                                  foregroundColor: _ink,
                                  backgroundColor: _surface,
                                  minimumSize: const Size(48, 48),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 12,
                                  ),
                                  shape: const StadiumBorder(),
                                ),
                                child: Text(
                                  isAr ? 'Français' : 'العربية',
                                  style: const TextStyle(
                                    fontFamily: 'IBMPlexSansArabic',
                                    fontFamilyFallback: [AppConfig.fontPrimary],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(height: 40),
                            Center(
                              child: Image.asset(
                                'assets/images/apolo_logo.png',
                                width: 112,
                                height: 112,
                                fit: BoxFit.contain,
                                semanticLabel: 'Apolo',
                              ),
                            ),
                            const SizedBox(height: 48),
                            Semantics(
                              header: true,
                              child: Text(
                                s.tr(
                                  'بيع وشراء.\nبكل بساطة.',
                                  'Achetez. Vendez.\nTout simplement.',
                                ),
                                style: TextStyle(
                                  fontFamily: fontFamily,
                                  fontSize: 34,
                                  height: 1.25,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: isAr ? 0 : -1.1,
                                  color: _ink,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              s.tr(
                                'تصفح الإعلانات في المغرب، وتواصل مع البائعين مباشرة.',
                                'Explorez les annonces au Maroc et échangez directement avec les vendeurs.',
                              ),
                              style: TextStyle(
                                fontFamily: fontFamily,
                                fontSize: 16,
                                height: 1.6,
                                color: _muted,
                              ),
                            ),
                            const SizedBox(height: 36),
                            const Spacer(),
                            FilledButton(
                              key: const ValueKey('welcome-sign-in'),
                              onPressed: _openSignIn,
                              style: FilledButton.styleFrom(
                                backgroundColor: _ink,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 56),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 17,
                                ),
                                textStyle: buttonTextStyle,
                                shape: const StadiumBorder(),
                              ),
                              child: Text(
                                s.tr('تسجيل الدخول', 'Se connecter'),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              key: const ValueKey('welcome-register'),
                              onPressed: () => _openSignIn(register: true),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _ink,
                                minimumSize: const Size(0, 56),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 17,
                                ),
                                side:
                                    const BorderSide(color: Color(0xFFD6D6D6)),
                                textStyle: buttonTextStyle,
                                shape: const StadiumBorder(),
                              ),
                              child: Text(
                                s.tr('إنشاء حساب', 'Créer un compte'),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              key: const ValueKey('welcome-guest'),
                              onPressed: _enterMainApp,
                              style: TextButton.styleFrom(
                                foregroundColor: _muted,
                                minimumSize: const Size(0, 48),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                textStyle: buttonTextStyle,
                              ),
                              child: Text(
                                s.tr('تصفح بدون حساب', 'Explorer sans compte'),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
