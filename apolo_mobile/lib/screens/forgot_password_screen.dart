import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../account/account_helpers.dart';
import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import '../theme/app_typography.dart';
import '../widgets/custom_auth_input_field.dart';
import 'support_screen.dart';

/// Premium 2026 APOLO Forgot Password & Account Recovery Screen.
///
/// Designed to strictly mirror the visual language of the reference Sign In screen:
/// - 44x44 circular back button with clean 1px border.
/// - Centered header navigation title.
/// - Bold 28px headline with subtle negative letter spacing.
/// - Crisp, rounded input card with no grey fill artifacts.
/// - Interactive brand crimson focus border (#E31B23).
/// - 54px solid black stadium action button.
/// - Clear, reassuring success state feedback.
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
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  late final AccountAuth _auth;
  bool _busy = false;
  bool _sent = false;
  bool _hasCodeStep = false;
  String? _error;
  String? _successMessage;

  Timer? _timer;
  int _cooldownRemaining = 0;

  @override
  void initState() {
    super.initState();
    _auth = widget.auth ?? AccountAuth(locale: _state.locale.languageCode);
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _email.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _auth.close();
    _email.dispose();
    _code.dispose();
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

  Future<void> _submitRequest() async {
    if (_busy) return;
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _successMessage = null;
    });

    try {
      await _auth.requestPasswordReset(_email.text.trim());
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _sent = true;
        _successMessage = _state.s.tr(
          'تم إرسال رابط وتعليمات استعادة كلمة المرور إلى ${_email.text.trim()}. تفقد صندوق الوارد أو البريد غير المرغوب فيه.',
          'Reset instructions have been sent to ${_email.text.trim()}. Please check your inbox or spam folder.',
        );
      });
      _startCooldown();
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

  Future<void> _submitResetWithCode() async {
    if (_busy) return;
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await _auth.resetPasswordWithToken(
        email: _email.text.trim(),
        token: _code.text.trim(),
        password: _password.text,
        confirmation: _confirmation.text,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _state.s.tr(
              'تم تغيير كلمة المرور بنجاح. يمكنك الآن تسجيل الدخول.',
              'Password reset successfully. You can now sign in.',
            ),
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final isAr = s.isAr;

    return Directionality(
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
                        s.tr('استعادة الحساب', 'Mot de passe oublié',
                            'Forgot password'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                          letterSpacing:
                              AppTypography.trackingForContext(context, -0.2),
                        ),
                      ),
                    ],
                  ),
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
                        const SizedBox(height: 20),

                        // Large Headline
                        Text(
                          s.tr('نسيت كلمة المرور؟', 'Mot de passe oublié ?',
                              'Forgot password'),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                            letterSpacing:
                                AppTypography.trackingForContext(context, -0.4),
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
                          _sent
                              ? s.tr(
                                  'تم إرسال التعليمات إلى بريدك الإلكتروني. يمكنك التحقق منه وإعادة التعيين، أو استخدام الرمز أدناه إذا وصلك في الرسالة.',
                                  'Les instructions ont été envoyées à votre e-mail. Réinitialisez votre mot de passe ou saisissez le code ci-dessous.',
                                  'Instructions have been sent to your email. You can reset your password via the link, or enter the code below if provided.',
                                )
                              : s.tr(
                                  'أدخل عنوان البريد الإلكتروني المرتبط بحسابك وسنرسل لك تعليمات إعادة تعيين كلمة المرور.',
                                  'Saisissez l’adresse e-mail associée à votre compte pour recevoir les instructions de réinitialisation.',
                                  'Enter the email associated with your account and we\'ll send you instructions to reset your password.',
                                ),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF6B7280),
                            height: 1.45,
                            letterSpacing:
                                AppTypography.trackingForContext(context, -0.1),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Error Banner
                        if (_error != null) ...[
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 20),
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

                        // Success Reassurance Card
                        if (_sent && _successMessage != null) ...[
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF86EFAC),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFDCFCE7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.mark_email_read_outlined,
                                      color: Color(0xFF15803D),
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.tr(
                                          'تحقق من بريدك الإلكتروني',
                                          'Check your email',
                                        ),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF14532D),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _successMessage!,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w400,
                                          color: Color(0xFF166534),
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Email Field
                        CustomAuthInputField(
                          keyName: 'forgot-email',
                          controller: _email,
                          label: s.tr('البريد الإلكتروني', 'Email'),
                          type: TextInputType.emailAddress,
                          autofill: const [AutofillHints.email],
                          enabled: !_busy && !_hasCodeStep,
                          validator: (v) => AccountValidation.email(v ?? '')
                              ? null
                              : s.tr(
                                  'أدخل بريداً إلكترونياً صحيحاً',
                                  'Enter a valid email address',
                                ),
                        ),

                        // Code step inputs if user toggles to enter code directly
                        if (_hasCodeStep) ...[
                          CustomAuthInputField(
                            keyName: 'forgot-code',
                            controller: _code,
                            label: s.tr('رمز التحقق', 'Reset code'),
                            type: TextInputType.number,
                            enabled: !_busy,
                            validator: (v) => AccountValidation.otp(v ?? '')
                                ? null
                                : s.tr(
                                    'أدخل رمزاً مكوناً من 6 أرقام',
                                    'Enter a 6-digit code',
                                  ),
                          ),
                          CustomAuthInputField(
                            keyName: 'forgot-password',
                            controller: _password,
                            label: s.tr('كلمة المرور الجديدة', 'New password'),
                            secret: true,
                            enabled: !_busy,
                            validator: (v) =>
                                AccountValidation.password(v ?? '')
                                    ? null
                                    : s.tr(
                                        'استخدم 8 أحرف على الأقل',
                                        'Must be at least 8 characters',
                                      ),
                          ),
                          CustomAuthInputField(
                            keyName: 'forgot-confirmation',
                            controller: _confirmation,
                            label: s.tr(
                              'تأكيد كلمة المرور الجديدة',
                              'Confirm new password',
                            ),
                            secret: true,
                            enabled: !_busy,
                            validator: (v) =>
                                (v ?? '').isNotEmpty && v == _password.text
                                    ? null
                                    : s.tr(
                                        'كلمتا المرور غير متطابقتين',
                                        'Passwords do not match',
                                      ),
                          ),
                        ],

                        const SizedBox(height: 12),

                        // Primary Action Button ("Send instructions" or "Reset password")
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            key: const Key('forgot-submit'),
                            onPressed: _busy
                                ? null
                                : (_hasCodeStep
                                    ? _submitResetWithCode
                                    : _submitRequest),
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
                                    _hasCodeStep
                                        ? s.tr(
                                            'حفظ كلمة المرور الجديدة',
                                            'Save new password',
                                          )
                                        : (_sent
                                            ? s.tr(
                                                'إعادة إرسال التعليمات',
                                                'Resend instructions',
                                              )
                                            : s.tr(
                                                'إرسال التعليمات',
                                                'Send instructions',
                                              )),
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

                        // Cooldown / Resend note
                        if (_sent && !_hasCodeStep) ...[
                          const SizedBox(height: 16),
                          Center(
                            child: _cooldownRemaining > 0
                                ? Text(
                                    s.tr(
                                      'يمكنك إعادة المحاولة بعد $_cooldownRemaining ثانية',
                                      'Réessayez dans $_cooldownRemaining s',
                                      'You can retry in ${_cooldownRemaining}s',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      color: Color(0xFF6B7280),
                                    ),
                                  )
                                : TextButton(
                                    onPressed: _busy ? null : _submitRequest,
                                    child: Text(
                                      s.tr(
                                        'لم تصلك الرسالة؟ إرسال مرة أخرى',
                                        'Renvoyer l’e-mail',
                                        'Didn\'t receive it? Send again',
                                      ),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppConfig.primary,
                                      ),
                                    ),
                                  ),
                          ),

                          const SizedBox(height: 8),

                          // Toggle code step if needed
                          Center(
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _hasCodeStep = true;
                                  _error = null;
                                });
                              },
                              child: Text(
                                s.tr(
                                  'وصلك رمز في الرسالة؟ أدخله هنا',
                                  'Vous avez reçu un code ? Saisissez-le ici',
                                  'Have a reset code? Enter it here',
                                ),
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF4B5563),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 28),

                        // Return to Sign In Link
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).pop();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text.rich(
                                TextSpan(
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                  ),
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
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        final nav = Navigator.of(context);
        if (nav.canPop()) {
          nav.pop();
        }
      },
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
