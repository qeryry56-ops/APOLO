import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../account/account_helpers.dart';
import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import '../theme/app_typography.dart';
import '../theme/dl_share_profile_tokens.dart';
import 'auth_screen.dart';
import 'intent_onboarding_screen.dart';
import 'main_shell.dart';
import '../l10n/l10n.dart';

/// Dynamic Layer v5.1 Welcome Screen (`45786:49327`, `375 × 812` reference):
/// - Pure `#FFFFFF` canvas with dark status bar icons.
/// - Upper Interactive Hero (`Key('dl-welcome-hero')`):
///   Dynamic Layer `# notification-img` device frame silhouette paired with
///   smoothly cascading Apolo push notification & live buyer chat message cards
///   (tap to replay subtle spring cascade; respects Reduce Motion).
/// - Bottom Fixed `wrapper` (`Key('dl-welcome-wrapper')`, `padding: 16px`, `gap: 16px`):
///   1. `Continue with Google` (`56px` outlined `#FFFFFF` stadium pill, `1px` `#E2E2E2` border)
///   2. `or` divider (`1px` `#EEEEEE` hairlines + `14px` `#757575` label)
///   3. `Create an account` (`56px` `#000000` solid black stadium pill -> Sign up)
///   4. `I have an account` (`56px` `#EEEEEE` soft grey stadium pill -> Log in)
class WelcomeScreen extends StatefulWidget {
  final VoidCallback? onContinueAsGuest;

  const WelcomeScreen({super.key, this.onContinueAsGuest});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final AppState _state = AppState();
  bool _leaving = false;

  static const Color _bg = DlShareProfileColors.colorGreyWhite;
  static const Color _ink = DlShareProfileColors.colorGreyBlack;
  static const Color _pillGrey = DlShareProfileColors.colorGrey100;
  static const Color _muted = DlShareProfileColors.colorGrey500;
  static const Color _outlineBorder = Color(0xFFE2E2E2);
  static const Color _divider = Color(0xFFEEEEEE);

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

  void _enterMainApp({bool skipIntentOnboarding = false}) {
    if (!mounted || _leaving) return;
    _leaving = true;
    widget.onContinueAsGuest?.call();
    if (!skipIntentOnboarding && !_state.hasCompletedIntentOnboarding) {
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

  void _openAuth({required bool isRegister}) {
    HapticFeedback.selectionClick();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
        reverseTransitionDuration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
        pageBuilder: (_, animation, secondaryAnimation) => AuthScreen(
          initialRegisterMode: isRegister,
          initialIsLogin: !isRegister,
          onSuccess: () => _enterMainApp(skipIntentOnboarding: isRegister),
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
                appL10n.authUnableOpenGoogleSignRight,
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
                appL10n.welcomeUnableStartGoogleSignRight,
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final media = MediaQuery.of(context);
    final screenSize = media.size;
    final resolvedBottomSafe = DlShareProfileLayout.resolveBottomSafeInset(
      screenSize,
      media.padding,
    );
    // SafeArea already consumes media.padding.bottom when > 0; add extra clearance only for mobile web/PWA
    final extraWebBottom =
        media.padding.bottom > 0 ? 0.0 : resolvedBottomSafe;
    final wrapperBottomPad = math.max(10.0, 16.0 - 6.0) + extraWebBottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: _bg,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxHeight < 640.0;

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (isCompact)
                              const SizedBox(height: 16.0)
                            else
                              const Spacer(flex: 5),

                            // Upper Hero: Falling Apolo Notifications & Buyer Chat Messages
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child: _ApoloWelcomeFallingMessagesHero(
                                key: const Key('dl-welcome-hero'),
                                strings: s,
                                compact: isCompact,
                              ),
                            ),

                            if (isCompact)
                              const SizedBox(height: 16.0)
                            else
                              const Spacer(flex: 6),

                            // Bottom Dynamic Layer `wrapper` (`padding: 16px`, `gap: 16px`)
                            Padding(
                              key: const Key('dl-welcome-wrapper'),
                              padding: EdgeInsets.fromLTRB(
                                16.0,
                                16.0,
                                16.0,
                                wrapperBottomPad,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // 1. Continue with Google (`56px` outlined capsule)
                                  _buildDlWelcomeButton(
                                    key: const ValueKey('welcome-google'),
                                    backgroundColor: _bg,
                                    textColor: _ink,
                                    borderColor: _outlineBorder,
                                    icon: const _GoogleIcon(size: 20.0),
                                    text: s.tr(
                                      'المتابعة عبر Google',
                                      'Continuer avec Google',
                                      appL10n.welcomeContinueGoogle,
                                    ),
                                    onPressed: _openGoogleAuth,
                                  ),

                                  const SizedBox(height: 16.0),

                                  // 2. `or` Divider (`1px` `#EEEEEE` + `14px` `#757575`)
                                  Row(
                                    key: const Key('dl-welcome-or-divider'),
                                    children: [
                                      const Expanded(
                                        child: SizedBox(
                                          height: 1.0,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: _divider,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0,
                                        ),
                                        child: Text(
                                          s.tr('أو', 'ou', appL10n.welcomeOr),
                                          style: const TextStyle(
                                            color: _muted,
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.w400,
                                            height: 20.0 / 14.0,
                                          ),
                                        ),
                                      ),
                                      const Expanded(
                                        child: SizedBox(
                                          height: 1.0,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: _divider,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16.0),

                                  // 3. Create an account (`56px` solid `#000000` capsule)
                                  _buildDlWelcomeButton(
                                    key: const ValueKey(
                                        'welcome-create-account'),
                                    backgroundColor: _ink,
                                    textColor: _bg,
                                    text: s.tr(
                                      'إنشاء حساب جديد',
                                      'Créer un compte',
                                      appL10n.welcomeCreateAccountButton,
                                    ),
                                    onPressed: () =>
                                        _openAuth(isRegister: true),
                                  ),

                                  const SizedBox(height: 16.0),

                                  // 4. I have an account (`56px` `#EEEEEE` capsule)
                                  _buildDlWelcomeButton(
                                    key: const ValueKey('welcome-sign-in'),
                                    backgroundColor: _pillGrey,
                                    textColor: _ink,
                                    text: s.tr(
                                      'لدي حساب بالفعل',
                                      'J’ai déjà un compte',
                                      appL10n.welcomeIHaveAccount,
                                    ),
                                    onPressed: () =>
                                        _openAuth(isRegister: false),
                                  ),

                                  // Accessible guest fallback target (preserves exact 16px visual bottom margin)
                                  Align(
                                    alignment: Alignment.center,
                                    child: Semantics(
                                      button: true,
                                      label: context
                                          .l10n.welcomeContinueAsGuestLabel,
                                      child: GestureDetector(
                                        key: const ValueKey('welcome-guest'),
                                        onTap: _enterMainApp,
                                        behavior: HitTestBehavior.opaque,
                                        child: const SizedBox(
                                          width: 48.0,
                                          height: 6.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildDlWelcomeButton({
    required Key key,
    required Color backgroundColor,
    required Color textColor,
    required String text,
    required VoidCallback onPressed,
    Color? borderColor,
    Widget? icon,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56.0),
      child: TextButton(
        key: key,
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size(double.infinity, 56.0),
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: StadiumBorder(
            side: borderColor != null
                ? BorderSide(color: borderColor, width: 1.0)
                : BorderSide.none,
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon,
              const SizedBox(width: 10.0),
            ],
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w700,
                  height: 24.0 / 16.0,
                  color: textColor,
                  letterSpacing:
                      AppTypography.trackingForContext(context, -0.1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Interactive Dynamic Layer v5.1 Hero Illustration (`330 × 268 px` reference):
/// Combines the `# notification-img` device bezel with 3 staggered falling cards:
/// 1. Official Apolo push notification card (`#E31828` brand icon + live offer alert)
/// 2. Buyer incoming chat notification card (`#0D8BFF` chat badge + `#FF3B30` unread dot)
/// 3. Instant `#0D8BFF` outgoing reply bubble
class _ApoloWelcomeFallingMessagesHero extends StatefulWidget {
  final AppStrings strings;
  final bool compact;

  const _ApoloWelcomeFallingMessagesHero({
    super.key,
    required this.strings,
    this.compact = false,
  });

  @override
  State<_ApoloWelcomeFallingMessagesHero> createState() =>
      _ApoloWelcomeFallingMessagesHeroState();
}

class _ApoloWelcomeFallingMessagesHeroState
    extends State<_ApoloWelcomeFallingMessagesHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _didStartInitial = false;

  static const Color _bg = Color(0xFFFFFFFF);
  static const Color _ink = Color(0xFF000000);
  static const Color _muted = Color(0xFF757575);
  static const Color _apoloRed = Color(0xFFE31828);
  static const Color _chatBlue = Color(0xFF0D8BFF);
  static const Color _unreadRed = Color(0xFFFF3B30);
  static const Color _liveGreen = Color(0xFF16A34A);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _ctrl.value = 1.0;
      _didStartInitial = true;
    } else if (!_didStartInitial) {
      _didStartInitial = true;
      _ctrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _replayCascade() {
    if (MediaQuery.disableAnimationsOf(context)) return;
    HapticFeedback.lightImpact();
    _ctrl.forward(from: 0.0);
  }

  Widget _buildFallingItem({
    required double start,
    required double end,
    required double dropDistance,
    required Widget child,
  }) {
    final fade = CurvedAnimation(
      parent: _ctrl,
      curve: Interval(start, (start + 0.34).clamp(0.0, 1.0),
          curve: Curves.easeOut),
    );
    final slide = CurvedAnimation(
      parent: _ctrl,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    );

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, builtChild) {
        final dy = (1.0 - slide.value) * -dropDistance;
        final scale = 0.94 + (0.06 * slide.value.clamp(0.0, 1.05));
        return Opacity(
          opacity: fade.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0.0, dy),
            child: Transform.scale(
              scale: scale,
              child: builtChild,
            ),
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final nowLabel = s.tr('الآن', 'maintenant', appL10n.notificationsNow);
    final maxHeroWidth = widget.compact ? 280.0 : 330.0;

    return GestureDetector(
      onTap: _replayCascade,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxHeroWidth),
          child: MediaQuery.withNoTextScaling(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: 330.0,
                height: 268.0,
                child: Stack(
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.none,
                  children: [
                    // 1. Dynamic Layer `# notification-img` rounded phone silhouette
                    Positioned(
                      top: 8.0,
                      child: Container(
                        width: 212.0,
                        height: 256.0,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEEEE),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(36.0),
                          ),
                          border: Border.all(
                            color: const Color(0xFFE4E4E4),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 15.0),
                            Container(
                              width: 44.0,
                              height: 5.0,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4D4D4),
                                borderRadius: BorderRadius.circular(999.0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Soft bottom white fade matching `Notification / Default` (`45849:25601`)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 62.0,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                _bg.withValues(alpha: 0.0),
                                _bg.withValues(alpha: 0.88),
                                _bg,
                              ],
                              stops: const [0.0, 0.65, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 2. Card 1 (Top falling card — Official Apolo active notification)
                    Positioned(
                      top: 38.0,
                      width: 304.0,
                      child: _buildFallingItem(
                        start: 0.00,
                        end: 0.56,
                        dropDistance: 34.0,
                        child: Container(
                          key: const Key('dl-welcome-notif-card-1'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13.0,
                            vertical: 11.0,
                          ),
                          decoration: BoxDecoration(
                            color: _bg,
                            borderRadius: BorderRadius.circular(16.0),
                            border: Border.all(
                              color: const Color(0xFFEBEBEB),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.045),
                                blurRadius: 16.0,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38.0,
                                height: 38.0,
                                padding: const EdgeInsets.all(5.0),
                                decoration: BoxDecoration(
                                  color: _apoloRed,
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: Image.asset(
                                  'assets/images/apolo_logo_white_transparent.png',
                                  fit: BoxFit.contain,
                                  semanticLabel: 'Apolo',
                                ),
                              ),
                              const SizedBox(width: 11.0),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'Apolo',
                                          style: TextStyle(
                                            color: _ink,
                                            fontSize: 13.0,
                                            fontWeight: FontWeight.w700,
                                            height: 1.2,
                                          ),
                                        ),
                                        const SizedBox(width: 6.0),
                                        Container(
                                          width: 6.0,
                                          height: 6.0,
                                          decoration: const BoxDecoration(
                                            color: _liveGreen,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          nowLabel,
                                          style: const TextStyle(
                                            color: _muted,
                                            fontSize: 11.0,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3.0),
                                    Text(
                                      s.tr(
                                        'عرض جديد وصل على إعلانك الآن!',
                                        'Nouvelle offre reçue sur votre annonce !',
                                        appL10n.welcomeNewOfferReceivedListing,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF525252),
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.w400,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 3. Card 2 (Middle featured card — Incoming Buyer Message)
                    Positioned(
                      top: 112.0,
                      left: 0,
                      right: 0,
                      child: _buildFallingItem(
                        start: 0.18,
                        end: 0.78,
                        dropDistance: 38.0,
                        child: Container(
                          key: const Key('dl-welcome-notif-card-2'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 13.0,
                          ),
                          decoration: BoxDecoration(
                            color: _bg,
                            borderRadius: BorderRadius.circular(18.0),
                            border: Border.all(
                              color: const Color(0xFFE5E5E5),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.07),
                                blurRadius: 22.0,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4.0,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 42.0,
                                height: 42.0,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 42.0,
                                      height: 42.0,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF3F4F6),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        s.tr('ي', 'Y', appL10n.welcomeY),
                                        style: const TextStyle(
                                          color: _ink,
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    PositionedDirectional(
                                      bottom: -1.0,
                                      end: -1.0,
                                      child: Container(
                                        width: 18.0,
                                        height: 18.0,
                                        decoration: BoxDecoration(
                                          color: _chatBlue,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: _bg,
                                            width: 2.0,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          CupertinoIcons.chat_bubble_fill,
                                          size: 9.5,
                                          color: _bg,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12.0),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            s.tr(
                                              'ياسين • الدار البيضاء',
                                              'Yassine • Casablanca',
                                              appL10n.welcomeYassineCasablanca,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: _ink,
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              height: 1.2,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8.0),
                                        Container(
                                          width: 18.0,
                                          height: 18.0,
                                          decoration: const BoxDecoration(
                                            color: _unreadRed,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: const Text(
                                            '1',
                                            style: TextStyle(
                                              color: _bg,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              height: 1.0,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      s.tr(
                                        'السلام عليكم، واش باقي متوفر؟',
                                        'Bonjour, toujours disponible ?',
                                        appL10n.adDetailHiIsThisStillAvailable,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: _ink,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 4. Card 3 (Bottom falling bubble — Dynamic Layer `#0D8BFF` instant chat reply)
                    Positioned(
                      top: 196.0,
                      left: 12.0,
                      right: 12.0,
                      child: _buildFallingItem(
                        start: 0.36,
                        end: 1.00,
                        dropDistance: 32.0,
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Container(
                            key: const Key('dl-welcome-chat-bubble-3'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15.0,
                              vertical: 10.0,
                            ),
                            decoration: BoxDecoration(
                              color: _chatBlue,
                              borderRadius: BorderRadius.circular(18.0),
                              boxShadow: [
                                BoxShadow(
                                  color: _chatBlue.withValues(alpha: 0.22),
                                  blurRadius: 16.0,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  CupertinoIcons.checkmark_alt_circle_fill,
                                  size: 15.0,
                                  color: _bg,
                                ),
                                const SizedBox(width: 6.0),
                                Flexible(
                                  child: Text(
                                    s.tr(
                                      'مرحباً! نعم متوفر، تفضل',
                                      'Oui disponible, bienvenue !',
                                      appL10n.welcomeYesAvailableWelcome,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _bg,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
