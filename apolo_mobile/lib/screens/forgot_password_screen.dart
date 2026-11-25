import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../account/account_helpers.dart';
import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import '../theme/app_typography.dart';
import '../theme/dl_share_profile_tokens.dart';
import '../widgets/custom_auth_input_field.dart';
import '../widgets/dl_settings_kit.dart';
import 'main_shell.dart';
import 'support_screen.dart';

enum _RecoveryStep {
  email,
  otp,
  newPassword,
}

/// Premium 2026 APOLO 3-Step Forgot Password & Account Recovery Screen.
///
/// Flow:
/// 1. Email step -> sends 6-digit verification code to the user's email.
/// 2. OTP step -> verifies the 6-digit code with the backend before unlocking step 3.
/// 3. New Password step -> saves the new password, signs the user in automatically,
///    and navigates directly to the Home app (`MainShell`).
class ForgotPasswordScreen extends StatefulWidget {
  final String? initialEmail;
  @visibleForTesting
  final AccountAuth? auth;

  const ForgotPasswordScreen({
    super.key,
    this.initialEmail,
    this.auth,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _state = AppState();
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _emailFocus = FocusNode();
  final _code = TextEditingController();
  final _codeFocus = FocusNode();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  late final AccountAuth _auth;
  _RecoveryStep _step = _RecoveryStep.email;
  bool _busy = false;
  String? _error;
  String? _notice;

  Timer? _timer;
  int _cooldownRemaining = 0;

  @override
  void initState() {
    super.initState();
    _auth = widget.auth ?? AccountAuth(locale: _state.locale.languageCode);
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _email.text = widget.initialEmail!;
    }
    _email.addListener(() {
      if (mounted) {
        setState(() {
          if (_step == _RecoveryStep.email && _error != null) _error = null;
        });
      }
    });
    _codeFocus.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _auth.close();
    _email.dispose();
    _emailFocus.dispose();
    _code.dispose();
    _codeFocus.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldownRemaining = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_cooldownRemaining <= 1) {
        timer.cancel();
        setState(() => _cooldownRemaining = 0);
      } else {
        setState(() => _cooldownRemaining--);
      }
    });
  }

  void _handleBack() {
    HapticFeedback.lightImpact();
    if (_busy) return;
    if (_step == _RecoveryStep.otp) {
      setState(() {
        _step = _RecoveryStep.email;
        _error = null;
        _notice = null;
        _code.clear();
      });
      return;
    }
    if (_step == _RecoveryStep.newPassword) {
      setState(() {
        _step = _RecoveryStep.otp;
        _error = null;
        _notice = null;
      });
      return;
    }
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    }
  }

  /// Step 1: Send OTP code to email and navigate to OTP step.
  Future<void> _submitEmailRequest({bool isResend = false}) async {
    if (_busy) return;
    if (!isResend) {
      final trimmed = _email.text.trim();
      if (trimmed.isEmpty) {
        _emailFocus.requestFocus();
        return;
      }
      if (!AccountValidation.email(trimmed)) {
        HapticFeedback.heavyImpact();
        setState(() {
          _error = _state.s.tr(
            'يرجى إدخال بريد إلكتروني صحيح',
            'Veuillez saisir une adresse e-mail valide',
            'Please enter a valid email address',
          );
        });
        return;
      }
    }

    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });

    try {
      final email = _email.text.trim();
      await _auth.requestPasswordReset(email);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _step = _RecoveryStep.otp;
        if (isResend) {
          _code.clear();
          _notice = _state.s.tr(
            'تم إرسال رمز جديد إلى $email.',
            'Un nouveau code a été envoyé à $email.',
            'A new verification code was sent to $email.',
          );
        } else {
          _notice = _state.s.tr(
            'أرسلنا رمز التحقق إلى $email.',
            'Nous avons envoyé un code de vérification à $email.',
            'We sent a verification code to $email.',
          );
        }
      });
      _startCooldown();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _codeFocus.requestFocus();
      });
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.vibrate();
      setState(() {
        _error = accountError(e, _state.s.isAr);
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Step 2: Verify the 6-digit OTP code with the backend before showing Step 3.
  Future<void> _verifyOtpCode() async {
    if (_busy) return;
    final code = _code.text.trim();
    if (code.length < 6) {
      HapticFeedback.heavyImpact();
      setState(() {
        _error = _state.s.tr(
          'يرجى إدخال رمز التحقق المكون من 6 أرقام.',
          'Veuillez saisir le code à 6 chiffres.',
          'Please enter the 6-digit verification code.',
        );
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });

    try {
      await _auth.verifyPasswordResetCode(
        email: _email.text.trim(),
        code: code,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _step = _RecoveryStep.newPassword;
        _error = null;
        _notice = _state.s.tr(
          'تم التحقق من الرمز بنجاح. اختر كلمة مرور جديدة لحسابك.',
          'Code vérifié avec succès. Choisissez votre nouveau mot de passe.',
          'Code verified. Choose a new password for your account.',
        );
      });
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.vibrate();
      setState(() {
        _error = accountError(e, _state.s.isAr);
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Step 3: Confirm new password, sign in automatically, and go straight to Home.
  Future<void> _submitNewPassword() async {
    if (_busy) return;
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });

    try {
      final email = _email.text.trim();
      final newPassword = _password.text;

      AccountSession? session = await _auth.resetPasswordWithToken(
        email: email,
        token: _code.text.trim(),
        password: newPassword,
        confirmation: _confirmation.text,
      );

      // Fallback auto-login if backend didn't return a token
      session ??= await _auth.login(email, newPassword);

      if (!mounted) return;
      await _state.setAuthSession(session.token, session.user);
      if (!mounted) return;

      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _state.s.tr(
              'تم تحديث كلمة المرور وتسجيل الدخول بنجاح!',
              'Mot de passe mis à jour. Bienvenue !',
              'Password updated and signed in successfully!',
            ),
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.vibrate();
      setState(() {
        _error = accountError(e, _state.s.isAr);
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _headerTitle(dynamic s) {
    switch (_step) {
      case _RecoveryStep.email:
        return s.tr('استعادة الحساب', 'Mot de passe oublié', 'Forgot password');
      case _RecoveryStep.otp:
        return s.tr('التحقق من الرمز', 'Code de vérification', 'Verify code');
      case _RecoveryStep.newPassword:
        return s.tr('كلمة مرور جديدة', 'Nouveau mot de passe', 'New password');
    }
  }

  String _headline(dynamic s) {
    switch (_step) {
      case _RecoveryStep.email:
        return s.tr('نسيت كلمة المرور؟', 'Mot de passe oublié ?', 'Forgot password?');
      case _RecoveryStep.otp:
        return s.tr('أدخل رمز التحقق', 'Entrez le code OTP', 'Enter verification code');
      case _RecoveryStep.newPassword:
        return s.tr('إنشاء كلمة مرور جديدة', 'Nouveau mot de passe', 'Create new password');
    }
  }

  String _subtitle(dynamic s) {
    switch (_step) {
      case _RecoveryStep.email:
        return s.tr(
          'أدخل بريدك الإلكتروني المرتبط بحسابك وسنرسل لك رمز تحقق مكون من 6 أرقام.',
          'Saisissez l’adresse e-mail de votre compte pour recevoir un code à 6 chiffres.',
          'Enter the email associated with your account and we\'ll send you a 6-digit code.',
        );
      case _RecoveryStep.otp:
        return s.tr(
          'أدخل الرمز المكون من 6 أرقام الذي أرسلناه إلى ${_email.text.trim()}.',
          'Saisissez le code à 6 chiffres envoyé à ${_email.text.trim()}.',
          'Enter the 6-digit code we sent to ${_email.text.trim()}.',
        );
      case _RecoveryStep.newPassword:
        return s.tr(
          'اختر كلمة مرور قوية جديدة (8 أحرف على الأقل) وسنقوم بتسجيل دخولك مباشرة.',
          'Choisissez un nouveau mot de passe sécurisé (8 caractères minimum).',
          'Choose a strong new password (at least 8 characters) to sign straight in.',
        );
    }
  }

  String _primaryButtonLabel(dynamic s) {
    switch (_step) {
      case _RecoveryStep.email:
        return s.tr('إرسال رمز التحقق', 'Envoyer le code', 'Send verification code');
      case _RecoveryStep.otp:
        return s.tr('تأكيد الرمز', 'Vérifier le code', 'Verify code');
      case _RecoveryStep.newPassword:
        return s.tr('تأكيد والدخول للتطبيق', 'Confirmer et continuer', 'Confirm & continue');
    }
  }

  VoidCallback? get _primaryAction {
    if (_busy) return null;
    switch (_step) {
      case _RecoveryStep.email:
        return () => _submitEmailRequest(isResend: false);
      case _RecoveryStep.otp:
        return _verifyOtpCode;
      case _RecoveryStep.newPassword:
        return _submitNewPassword;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final isAr = s.isAr;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_step == _RecoveryStep.email) {
      return _buildDynamicLayerEmailScaffold(
        context,
        s: s,
        isAr: isAr,
        isDark: isDark,
      );
    }

    final Color bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final Color inkColor =
        isDark ? Colors.white : const Color(0xFF111827);
    final Color mutedColor =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final Color pillBg =
        isDark ? const Color(0xFF262629) : const Color(0xFFEEEEEE);
    final backIcon =
        isAr ? CupertinoIcons.chevron_right : CupertinoIcons.chevron_left;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: Column(
              children: [
                // Clean 56px TopNavigation (40×40 #EEEEEE circle back button, no separator line)
                SizedBox(
                  height: DlShareProfileLayout.topNavHeight,
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DlShareProfileLayout.topNavHorizontalPadding,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: ApoloDlIconCircleButton(
                            key: const Key('forgot-dismiss'),
                            icon: backIcon,
                            backgroundColor: pillBg,
                            iconColor: isDark
                                ? Colors.white
                                : const Color(0xFF000000),
                            tooltip: MaterialLocalizations.of(context)
                                .backButtonTooltip,
                            onPressed: _handleBack,
                          ),
                        ),
                        Text(
                          _headerTitle(s),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: inkColor,
                            letterSpacing:
                                AppTypography.trackingForContext(context, -0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Scrollable Body (Steps 2 & 3: OTP & New Password)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    physics: const BouncingScrollPhysics(),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),

                          // Large Headline
                          Text(
                            _headline(s),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: inkColor,
                              letterSpacing: AppTypography.trackingForContext(
                                  context, -0.4),
                              height: AppTypography.lineHeightForContext(
                                context,
                                1.15,
                                arabicMin: 1.32,
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Subtitle explanation
                          Text(
                            _subtitle(s),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: mutedColor,
                              height: 1.45,
                              letterSpacing: AppTypography.trackingForContext(
                                  context, -0.1),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Error Banner
                          if (_error != null) ...[
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 18),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFFCA5A5),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Color(0xFFDC2626),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFFB91C1C),
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Notice / Success Banner
                          if (_notice != null) ...[
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFF86EFAC),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    color: Color(0xFF15803D),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _notice!,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF166534),
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Step Content
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 240),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            child: _buildStepBody(s),
                          ),

                          const SizedBox(height: 16),

                          // Primary Action Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              key: const Key('forgot-submit'),
                              onPressed: _primaryAction,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark
                                    ? Colors.white
                                    : const Color(0xFF000000),
                                foregroundColor: isDark
                                    ? const Color(0xFF000000)
                                    : Colors.white,
                                shape: const StadiumBorder(),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                              ),
                              child: _busy
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: isDark
                                            ? const Color(0xFF000000)
                                            : Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _primaryButtonLabel(s),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? const Color(0xFF000000)
                                            : Colors.white,
                                        letterSpacing:
                                            AppTypography.trackingForContext(
                                                context, -0.2),
                                      ),
                                    ),
                            ),
                          ),

                          // Step 2 (OTP): Resend & Change email actions
                          if (_step == _RecoveryStep.otp) ...[
                            const SizedBox(height: 16),
                            Center(
                              child: _cooldownRemaining > 0
                                  ? Text(
                                      s.tr(
                                        'يمكنك إعادة إرسال الرمز بعد $_cooldownRemaining ثانية',
                                        'Renvoyer le code dans $_cooldownRemaining s',
                                        'Resend code in ${_cooldownRemaining}s',
                                      ),
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        color: mutedColor,
                                      ),
                                    )
                                  : TextButton(
                                      onPressed: _busy
                                          ? null
                                          : () => _submitEmailRequest(
                                              isResend: true),
                                      child: Text(
                                        s.tr(
                                          'لم يصلك الرمز؟ إعادة الإرسال',
                                          'Code non reçu ? Renvoyer',
                                          'Didn\'t receive the code? Resend',
                                        ),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppConfig.brandRed,
                                        ),
                                      ),
                                    ),
                            ),
                            Center(
                              child: TextButton(
                                onPressed: _busy ? null : _handleBack,
                                child: Text(
                                  s.tr(
                                    'تغيير البريد الإلكتروني',
                                    'Modifier l’adresse e-mail',
                                    'Change email address',
                                  ),
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: mutedColor,
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Need help / Support
                          Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const SupportScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                s.tr(
                                  'واجهت صعوبة؟ تواصل مع الدعم',
                                  'Besoin d’aide ? Contacter le support',
                                  'Having trouble? Contact support',
                                ),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Exact Figma `dynamic-layer-core-v5.1` `Forgot password` Step 1 (`45786:56733`, `45786:57262`, `21414:22440`):
  /// - `56px` TopNavigation (`40×40` circular `#EEEEEE` `<` button, no separator line)
  /// - `wrapper` (`padding: 32 top/bottom, 16 left/right`, `gap: 32`)
  /// - Centered `16px Bold` `"Enter your email"`, borderless `28px Bold` centered input, centered `12.5px #757575` helper text
  /// - Fixed bottom `ButtonDock` (`56px` stadium `Continue`: `#EEEEEE` when empty -> `#000000` when filled).
  Widget _buildDynamicLayerEmailScaffold(
    BuildContext context, {
    required dynamic s,
    required bool isAr,
    required bool isDark,
  }) {
    final screenSize = MediaQuery.sizeOf(context);
    final mediaPadding = MediaQuery.paddingOf(context);
    final topInset = mediaPadding.top;
    final viewRef = View.maybeOf(context);
    final rawViewKb = viewRef != null && viewRef.devicePixelRatio > 0
        ? viewRef.viewInsets.bottom / viewRef.devicePixelRatio
        : 0.0;
    final bool keyboardOpen =
        MediaQuery.viewInsetsOf(context).bottom > 0 || rawViewKb > 0;
    final bottomSafe =
        DlShareProfileLayout.resolveBottomSafeInset(screenSize, mediaPadding);
    final double bottomDockPad =
        keyboardOpen ? 16.0 : math.max(20.0, bottomSafe + 8.0);

    final Color bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final Color ink = isDark ? Colors.white : const Color(0xFF000000);
    final Color pillBg =
        isDark ? const Color(0xFF262629) : const Color(0xFFEEEEEE);
    final Color mutedText =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF757575);
    const Color errorRed = Color(0xFFE31B23);

    final bool isFilled = _email.text.trim().isNotEmpty;
    final Color continueBg =
        isFilled ? (isDark ? Colors.white : const Color(0xFF000000)) : pillBg;
    final Color continueFg =
        isFilled ? (isDark ? const Color(0xFF000000) : Colors.white) : mutedText;

    final int emailLen = _email.text.length;
    final double dynamicInputFontSize =
        emailLen > 28 ? 19.0 : (emailLen > 20 ? 23.0 : 28.0);

    final backIcon =
        isAr ? CupertinoIcons.chevron_right : CupertinoIcons.chevron_left;

    return PopScope(
      canPop: true,
      child: Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: bgColor,
          resizeToAvoidBottomInset: true,
          body: Column(
            children: [
              // Fixed 56px TopNavigation (40×40 #EEEEEE `<` circle, no separator)
              SizedBox(
                key: const Key('dl-forgot-top-nav'),
                height: topInset + DlShareProfileLayout.topNavHeight,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    height: DlShareProfileLayout.topNavHeight,
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DlShareProfileLayout.topNavHorizontalPadding,
                      ),
                      child: Row(
                        children: [
                          ApoloDlIconCircleButton(
                            key: const Key('forgot-dismiss'),
                            icon: backIcon,
                            backgroundColor: pillBg,
                            iconColor: ink,
                            tooltip: MaterialLocalizations.of(context)
                                .backButtonTooltip,
                            onPressed: _handleBack,
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Scrollable `wrapper` (`padding: 32 top/bottom, 16 left/right`, `gap: 32`)
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460.0),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          key: const Key('dl-forgot-wrapper'),
                          padding: const EdgeInsets.fromLTRB(
                            16.0,
                            32.0,
                            16.0,
                            32.0,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                s.tr(
                                  'أدخل بريدك الإلكتروني',
                                  'Entrez votre e-mail',
                                  'Enter your email',
                                ),
                                key: const Key('dl-forgot-prompt-label'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: ink,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w700,
                                  height: 24.0 / 16.0,
                                ),
                              ),
                              const SizedBox(height: 32.0),

                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: TextField(
                                  key: const Key('forgot-email'),
                                  controller: _email,
                                  focusNode: _emailFocus,
                                  enabled: !_busy,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.email],
                                  textAlign: TextAlign.center,
                                  textDirection: TextDirection.ltr,
                                  cursorColor: ink,
                                  cursorWidth: 2.5,
                                  cursorHeight: 30.0,
                                  style: TextStyle(
                                    color: ink,
                                    fontSize: dynamicInputFontSize,
                                    fontWeight: FontWeight.w700,
                                    height: 36.0 / 28.0,
                                    letterSpacing: -0.4,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'example@gmail.com',
                                    hintStyle: TextStyle(
                                      color: isDark
                                          ? const Color(0xFF52525B)
                                          : const Color(0xFFC7C7CC),
                                      fontSize: dynamicInputFontSize,
                                      fontWeight: FontWeight.w700,
                                      height: 36.0 / 28.0,
                                      letterSpacing: -0.4,
                                    ),
                                    filled: false,
                                    fillColor: Colors.transparent,
                                    hoverColor: Colors.transparent,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                    ),
                                  ),
                                  onSubmitted: (_) =>
                                      _submitEmailRequest(isResend: false),
                                ),
                              ),

                              if (_error != null) ...[
                                const SizedBox(height: 18.0),
                                Text(
                                  _error!,
                                  key: const Key('dl-forgot-error-text'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: errorRed,
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w400,
                                    height: 18.0 / 13.0,
                                  ),
                                ),
                              ],

                              SizedBox(height: _error != null ? 20.0 : 32.0),

                              Text(
                                s.tr(
                                  'ستتوصل برسالة في بريدك الإلكتروني لتعيين كلمة مرور جديدة',
                                  'Vous recevrez un e-mail pour définir un nouveau mot de passe',
                                  'You will receive an email to set a new password',
                                ),
                                key: const Key('dl-forgot-helper-text'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: mutedText,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w400,
                                  height: 18.0 / 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Fixed Bottom `ButtonDock` (`56px` stadium pill `Continue`)
              Padding(
                key: const Key('dl-forgot-button-dock'),
                padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, bottomDockPad),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56.0,
                      child: Material(
                        color: continueBg,
                        shape: const StadiumBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: const Key('forgot-submit'),
                          customBorder: const StadiumBorder(),
                          onTap: _busy
                              ? null
                              : () => _submitEmailRequest(isResend: false),
                          child: Center(
                            child: _busy
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: continueFg,
                                    ),
                                  )
                                : Text(
                                    s.tr('متابعة', 'Continuer', 'Continue'),
                                    style: TextStyle(
                                      color: continueFg,
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w600,
                                      height: 24.0 / 16.0,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepBody(dynamic s) {
    switch (_step) {
      case _RecoveryStep.email:
        return KeyedSubtree(
          key: const ValueKey('step-email'),
          child: CustomAuthInputField(
            keyName: 'forgot-email',
            controller: _email,
            label: s.tr('البريد الإلكتروني', 'Adresse e-mail', 'Email'),
            type: TextInputType.emailAddress,
            autofill: const [AutofillHints.email],
            enabled: !_busy,
            validator: (v) => AccountValidation.email(v ?? '')
                ? null
                : s.tr(
                    'أدخل بريداً إلكترونياً صحيحاً',
                    'Saisissez une adresse e-mail valide',
                    'Enter a valid email address',
                  ),
          ),
        );

      case _RecoveryStep.otp:
        return KeyedSubtree(
          key: const ValueKey('step-otp'),
          child: _buildOtpBoxes(),
        );

      case _RecoveryStep.newPassword:
        return KeyedSubtree(
          key: const ValueKey('step-new-password'),
          child: Column(
            children: [
              CustomAuthInputField(
                keyName: 'forgot-password',
                controller: _password,
                label: s.tr(
                  'كلمة المرور الجديدة',
                  'Nouveau mot de passe',
                  'New password',
                ),
                secret: true,
                enabled: !_busy,
                validator: (v) => AccountValidation.password(v ?? '')
                    ? null
                    : s.tr(
                        'استخدم 8 أحرف على الأقل',
                        'Minimum 8 caractères requis',
                        'Must be at least 8 characters',
                      ),
              ),
              CustomAuthInputField(
                keyName: 'forgot-confirmation',
                controller: _confirmation,
                label: s.tr(
                  'تأكيد كلمة المرور الجديدة',
                  'Confirmer le nouveau mot de passe',
                  'Confirm new password',
                ),
                secret: true,
                enabled: !_busy,
                validator: (v) => (v ?? '').isNotEmpty && v == _password.text
                    ? null
                    : s.tr(
                        'كلمتا المرور غير متطابقتين',
                        'Les mots de passe ne correspondent pas',
                        'Passwords do not match',
                      ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildOtpBoxes() {
    final code = _code.text;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Visual 6-digit boxes
            GestureDetector(
              onTap: () => _codeFocus.requestFocus(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  final hasChar = index < code.length;
                  final char = hasChar ? code[index] : '';
                  final isActive = _codeFocus.hasFocus &&
                      (index == code.length ||
                          (code.length == 6 && index == 5));
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 48,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: hasChar
                          ? const Color(0xFFF9FAFB)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isActive
                            ? AppConfig.brandRed
                            : (hasChar
                                ? const Color(0xFF111827)
                                : const Color(0xFFD1D5DB)),
                        width: isActive ? 2 : 1.3,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppConfig.brandRed.withValues(alpha: 0.14),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      char,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Transparent numeric input capturing keyboard & paste
            Positioned.fill(
              child: Opacity(
                opacity: 0.01,
                child: TextField(
                  key: const Key('forgot-code'),
                  controller: _code,
                  focusNode: _codeFocus,
                  enabled: !_busy,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onChanged: (value) {
                    setState(() {
                      if (_error != null) _error = null;
                    });
                    if (value.length == 6 && !_busy) {
                      _verifyOtpCode();
                    }
                  },
                  onSubmitted: (_) => _verifyOtpCode(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
