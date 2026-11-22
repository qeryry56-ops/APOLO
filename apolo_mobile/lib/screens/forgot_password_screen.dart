import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../account/account_helpers.dart';
import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import '../theme/app_typography.dart';
import '../widgets/custom_auth_input_field.dart';
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
    _codeFocus.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _auth.close();
    _email.dispose();
    _code.dispose();
    _codeFocus.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  int get _stepIndex {
    switch (_step) {
      case _RecoveryStep.email:
        return 1;
      case _RecoveryStep.otp:
        return 2;
      case _RecoveryStep.newPassword:
        return 3;
    }
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
      final valid = _formKey.currentState?.validate() ?? false;
      if (!valid) {
        HapticFeedback.heavyImpact();
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

    return PopScope(
      canPop: _step == _RecoveryStep.email,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: SizedBox(
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: _buildBackButton(),
                        ),
                        Text(
                          _headerTitle(s),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111827),
                            letterSpacing:
                                AppTypography.trackingForContext(context, -0.2),
                          ),
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$_stepIndex / 3',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Step Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: List.generate(3, (index) {
                      final active = (index + 1) <= _stepIndex;
                      return Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          height: 4,
                          margin: EdgeInsetsDirectional.only(
                            end: index < 2 ? 6 : 0,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(0xFFE31B23)
                                : const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                // Scrollable Body
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
                              color: const Color(0xFF111827),
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
                              color: const Color(0xFF6B7280),
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
                            height: 54,
                            child: ElevatedButton(
                              key: const Key('forgot-submit'),
                              onPressed: _primaryAction,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0A0A0A),
                                foregroundColor: Colors.white,
                                shape: const StadiumBorder(),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                              ),
                              child: _busy
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _primaryButtonLabel(s),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
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
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        color: Color(0xFF6B7280),
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
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Return to Sign In Link (on Step 1)
                          if (_step == _RecoveryStep.email)
                            Center(
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.of(context).pop();
                                },
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  child: Text.rich(
                                    TextSpan(
                                      style: const TextStyle(fontSize: 14.5),
                                      children: [
                                        TextSpan(
                                          text: s.tr(
                                            'تذكرت كلمة المرور؟ ',
                                            'Mot de passe retrouvé ? ',
                                            'Remember your password? ',
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                        TextSpan(
                                          text: s.tr(
                                            'تسجيل الدخول',
                                            'Se connecter',
                                            'Sign in',
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppConfig.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),

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

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: _handleBack,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.arrow_back,
            size: 19,
            color: Color(0xFF111827),
          ),
        ),
      ),
    );
  }
}
