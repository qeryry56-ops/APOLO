import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../account/account_helpers.dart';
import '../account/account_onboarding_form.dart';
import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import '../widgets/custom_auth_input_field.dart';
import 'forgot_password_screen.dart';
import 'support_screen.dart';

/// Premium 2026 APOLO Sign In & Authentication Screen.
///
/// Faithfully designed to match the reference UI:
/// - Circular back button with clean 1px border.
/// - Centered navigation header title ("Sign in").
/// - Prominent bold headline ("Welcome back").
/// - Custom outlined rounded input cards with stacked label & input.
/// - Dynamic interactive purple border (#5E48E8) on focus.
/// - Left-aligned purple "Forgot your password?" link.
/// - Solid black capsule "Sign in" action button.
/// - Subtle "or" horizontal divider.
/// - Two capsule social buttons: "Continue With Google" & "Continue With Apple".
/// - Centered bottom footer link: "First time here? Create an account".
class AuthScreen extends StatefulWidget {
  final VoidCallback? onSuccess;
  final bool initialRegisterMode;
  final bool initialIsLogin;
  final bool autoTriggerGoogle;
  @visibleForTesting
  final AccountAuth? auth;

  const AuthScreen({
    super.key,
    this.onSuccess,
    this.initialRegisterMode = false,
    this.initialIsLogin = true,
    this.autoTriggerGoogle = false,
    this.auth,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _state = AppState();
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _code = TextEditingController();
  late final AccountAuth _auth;
  late bool _login;
  bool _busy = false;
  bool _finished = false;
  String? _error;
  String? _notice;
  AccountSession? _pending;
  AccountSession? _onboarding;
  Timer? _timer;
  int _remaining = 0;

  @override
  void initState() {
    super.initState();
    _login = widget.initialRegisterMode ? false : widget.initialIsLogin;
    _auth = widget.auth ?? AccountAuth(locale: _state.locale.languageCode);

    if (widget.autoTriggerGoogle) {
      _notice = _state.s.tr(
        'الدخول عبر Google غير متاح داخل التطبيق حالياً. استخدم بريدك وكلمة المرور أو الموقع.',
        'Google sign-in is currently unavailable in-app. Please use email and password or the website.',
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _auth.close();
    for (final controller in [
      _name,
      _email,
      _phone,
      _password,
      _confirmation,
      _code,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _cooldown() {
    _timer?.cancel();
    _remaining = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _remaining <= 1) {
        timer.cancel();
        if (mounted) setState(() => _remaining = 0);
      } else {
        setState(() => _remaining--);
      }
    });
  }

  Future<void> _submit() async {
    if (_busy || _finished || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });

    try {
      final AccountSession result;
      if (_pending != null) {
        result = await _auth.verify(_pending!, _code.text);
      } else if (_login) {
        result = await _auth.login(_email.text, _password.text);
      } else {
        result = await _auth.register(
          name: _name.text,
          email: _email.text,
          phone: _phone.text,
          password: _password.text,
          confirmation: _confirmation.text,
        );
      }

      if (!mounted) return;
      if (result.requiresOtp) {
        setState(() {
          _pending = result;
          _code.clear();
        });
        _password.clear();
        _confirmation.clear();
        _cooldown();
      } else {
        if (result.user['onboarding_completed'] != true &&
            result.user['onboarding_completed'] != 1) {
          _timer?.cancel();
          setState(() {
            _pending = null;
            _onboarding = result;
          });
        } else {
          await _finish(result);
        }
      }
    } catch (error) {
      if (mounted) setState(() => _error = accountError(error, _state.s.isAr));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finish(AccountSession result) async {
    if (!mounted || _finished) return;
    try {
      await _state.setAuthSession(result.token, result.user);
      if (!mounted) return;
      _finished = true;
      final callback = widget.onSuccess;
      final navigator = Navigator.of(context);
      final route = ModalRoute.of(context);

      if (route != null && route.isCurrent && navigator.canPop()) {
        navigator.pop(true);
      } else if (route != null && !route.isCurrent) {
        navigator.removeRoute(route);
      }
      callback?.call();
    } catch (error) {
      if (mounted) setState(() => _error = accountError(error, _state.s.isAr));
    }
  }

  Future<void> _resend() async {
    if (_busy || _remaining > 0 || _pending == null) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });

    try {
      await _auth.resend(_pending!);
      if (!mounted) return;
      setState(() => _notice = _state.s.tr(
            'تم تأكيد إرسال رمز جديد. تحقق من بريدك.',
            'A new verification code was sent. Please check your email inbox.',
          ));
      _cooldown();
    } catch (error) {
      if (mounted) setState(() => _error = accountError(error, _state.s.isAr));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _reset() {
    if (_busy) return;
    _timer?.cancel();
    setState(() {
      _pending = null;
      _remaining = 0;
      _error = null;
      _notice = null;
      _code.clear();
      _password.clear();
      _confirmation.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final otp = _pending != null;

    return Directionality(
      textDirection: s.isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  // Top Navigation Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // Circular back button
                        _buildBackButton(),
                        Expanded(
                          child: Text(
                            otp
                                ? s.tr('تأكيد البريد', 'Verify email')
                                : _login
                                    ? s.tr('تسجيل الدخول', 'Sign in')
                                    : s.tr('إنشاء حساب', 'Sign up'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: AppConfig.fontPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        // Balancer spacer
                        const SizedBox(width: 44, height: 44),
                      ],
                    ),
                  ),

                  // Main Scrollable Area
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _onboarding != null
                          ? Column(
                              children: [
                                AccountOnboardingForm(
                                  auth: _auth,
                                  session: _onboarding!,
                                  onComplete: _finish,
                                ),
                                if (_error != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          : AutofillGroup(
                              child: Form(
                                key: _form,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const SizedBox(height: 20),

                                    // Headline ("Welcome back" / "Create an account")
                                    Text(
                                      _finished
                                          ? s.tr(
                                              'تم تسجيل الدخول',
                                              'Welcome back',
                                            )
                                          : otp
                                              ? s.tr(
                                                  'خطوة أخيرة لحماية حسابك',
                                                  'Verify your email',
                                                )
                                              : _login
                                                  ? s.tr(
                                                      'مرحباً بك مجدداً',
                                                      'Welcome back',
                                                    )
                                                  : s.tr(
                                                      'إنشاء حساب جديد',
                                                      'Create an account',
                                                    ),
                                      style: const TextStyle(
                                        fontFamily: AppConfig.fontPrimary,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF111827),
                                        letterSpacing: -0.4,
                                        height: 1.2,
                                      ),
                                    ),

                                    if (otp) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        s.tr(
                                          'أدخل الرمز المكون من 6 أرقام المرسل إلى بريدك الإلكتروني.',
                                          'Enter the 6-digit verification code sent to your email.',
                                        ),
                                        style: const TextStyle(
                                          fontFamily: AppConfig.fontPrimary,
                                          fontSize: 14.5,
                                          color: Color(0xFF6B7280),
                                          height: 1.45,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          _email.text.trim(),
                                          textDirection: TextDirection.ltr,
                                          style: const TextStyle(
                                            fontFamily: AppConfig.fontPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14.5,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 28),

                                    // Error message banner
                                    if (_error != null)
                                      Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 16),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 11,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF2F2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: const Color(0xFFFCA5A5),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.error_outline_rounded,
                                              color: Color(0xFFDC2626),
                                              size: 19,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                _error!,
                                                style: const TextStyle(
                                                  fontFamily:
                                                      AppConfig.fontPrimary,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF991B1B),
                                                  height: 1.35,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    // Notice message banner
                                    if (_notice != null)
                                      Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 16),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 11,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: const Color(0xFFE2E8F0),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.info_outline_rounded,
                                              color: Color(0xFF475569),
                                              size: 19,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                _notice!,
                                                style: const TextStyle(
                                                  fontFamily:
                                                      AppConfig.fontPrimary,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF334155),
                                                  height: 1.35,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    // Form Fields
                                    if (otp)
                                      _CustomInputField(
                                        controller: _code,
                                        label: s.tr(
                                          'رمز التحقق',
                                          'Verification code',
                                        ),
                                        keyName: 'auth-code',
                                        type: TextInputType.number,
                                        autofill: const [
                                          AutofillHints.oneTimeCode
                                        ],
                                        enabled: !_busy,
                                        validator: (v) =>
                                            AccountValidation.otp(v ?? '')
                                                ? null
                                                : s.tr(
                                                    'أدخل 6 أرقام',
                                                    'Enter 6 digits',
                                                  ),
                                      )
                                    else ...[
                                      if (!_login)
                                        _CustomInputField(
                                          controller: _name,
                                          label: s.tr('الاسم الكامل', 'Full name'),
                                          keyName: 'auth-name',
                                          ltr: false,
                                          autofill: const [AutofillHints.name],
                                          enabled: !_busy,
                                          validator: (v) => (v ?? '')
                                                      .trim()
                                                      .length >=
                                                  2
                                              ? null
                                              : s.tr(
                                                  'أدخل اسمك الكامل',
                                                  'Enter your full name',
                                                ),
                                        ),

                                      // Email Field
                                      _CustomInputField(
                                        controller: _email,
                                        label: s.tr('البريد الإلكتروني', 'Email'),
                                        keyName: 'auth-email',
                                        type: TextInputType.emailAddress,
                                        autofill: const [AutofillHints.email],
                                        enabled: !_busy,
                                        validator: (v) =>
                                            AccountValidation.email(v ?? '')
                                                ? null
                                                : s.tr(
                                                    'أدخل بريداً إلكترونياً صحيحاً',
                                                    'Enter a valid email address',
                                                  ),
                                      ),

                                      if (!_login)
                                        _CustomInputField(
                                          controller: _phone,
                                          label: s.tr(
                                            'رقم الهاتف المغربي',
                                            'Moroccan phone',
                                          ),
                                          keyName: 'auth-phone',
                                          type: TextInputType.phone,
                                          autofill: const [
                                            AutofillHints.telephoneNumber
                                          ],
                                          hint: '06 12 34 56 78',
                                          enabled: !_busy,
                                          validator: (v) =>
                                              AccountValidation.phone(v ?? '') !=
                                                      null
                                                  ? null
                                                  : s.tr(
                                                      'استخدم رقماً يبدأ بـ 05 أو 06 أو 07 أو ‎+212',
                                                      'Use a valid number starting with 05, 06, 07 or +212',
                                                    ),
                                        ),

                                      // Password Field
                                      _CustomInputField(
                                        controller: _password,
                                        label: s.tr('كلمة المرور', 'Password'),
                                        keyName: 'auth-password',
                                        secret: true,
                                        autofill: [
                                          _login
                                              ? AutofillHints.password
                                              : AutofillHints.newPassword
                                        ],
                                        enabled: !_busy,
                                        validator: (v) => (_login
                                                ? (v ?? '').isNotEmpty
                                                : AccountValidation.password(
                                                    v ?? ''))
                                            ? null
                                            : s.tr(
                                                _login
                                                    ? 'أدخل كلمة المرور'
                                                    : 'استخدم 8 أحرف على الأقل',
                                                _login
                                                    ? 'Please enter your password'
                                                    : 'Must be at least 8 characters',
                                              ),
                                      ),

                                      if (!_login)
                                        _CustomInputField(
                                          controller: _confirmation,
                                          label: s.tr(
                                            'تأكيد كلمة المرور',
                                            'Confirm password',
                                          ),
                                          keyName: 'auth-confirmation',
                                          secret: true,
                                          enabled: !_busy,
                                          validator: (v) => (v ?? '')
                                                      .isNotEmpty &&
                                                  v == _password.text
                                              ? null
                                              : s.tr(
                                                  'كلمتا المرور غير متطابقتين',
                                                  'Passwords do not match',
                                                ),
                                        ),
                                    ],

                                    // "Forgot your password?" Link
                                    if (_login && !otp) ...[
                                      const SizedBox(height: 2),
                                      Align(
                                        alignment:
                                            AlignmentDirectional.centerStart,
                                        child: GestureDetector(
                                          onTap: _busy
                                              ? null
                                              : () {
                                                  HapticFeedback.lightImpact();
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) => ForgotPasswordScreen(
                                                        initialEmail: _email.text.trim(),
                                                        auth: _auth,
                                                      ),
                                                    ),
                                                  );
                                                },
                                          child: Text(
                                            s.tr(
                                              'نسيت كلمة المرور؟',
                                              'Forgot your password?',
                                            ),
                                            style: const TextStyle(
                                              fontFamily: AppConfig.fontPrimary,
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF5E48E8),
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 24),

                                    // Primary Action Button ("Sign in")
                                    SizedBox(
                                      width: double.infinity,
                                      height: 54,
                                      child: ElevatedButton(
                                        key: const Key('auth-submit'),
                                        onPressed: _busy
                                            ? null
                                            : () {
                                                HapticFeedback.lightImpact();
                                                _submit();
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF0A0A0A),
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
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Text(
                                                otp
                                                    ? s.tr(
                                                        'تأكيد الرمز',
                                                        'Verify code',
                                                      )
                                                    : _login
                                                        ? s.tr(
                                                            'تسجيل الدخول',
                                                            'Sign in',
                                                          )
                                                        : s.tr(
                                                            'إنشاء حساب',
                                                            'Sign up',
                                                          ),
                                                style: const TextStyle(
                                                  fontFamily:
                                                      AppConfig.fontPrimary,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                  letterSpacing: -0.2,
                                                ),
                                              ),
                                      ),
                                    ),

                                    // Social Auth & Footer (in Login mode)
                                    if (!otp) ...[
                                      // "or" Divider
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 24,
                                        ),
                                        child: Row(
                                          children: [
                                            const Expanded(
                                              child: Divider(
                                                color: Color(0xFFF1F5F9),
                                                thickness: 1,
                                                height: 1,
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 16,
                                              ),
                                              child: Text(
                                                s.tr('أو', 'or'),
                                                style: const TextStyle(
                                                  fontFamily:
                                                      AppConfig.fontPrimary,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w400,
                                                  color: Color(0xFF6B7280),
                                                ),
                                              ),
                                            ),
                                            const Expanded(
                                              child: Divider(
                                                color: Color(0xFFF1F5F9),
                                                thickness: 1,
                                                height: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Button 1: Continue With Google
                                      _buildSocialButton(
                                        key: const Key('auth-google'),
                                        icon: const _GoogleIcon(size: 20),
                                        text: s.tr(
                                          'المتابعة باستخدام Google',
                                          'Continue With Google',
                                        ),
                                        onPressed: () {
                                          HapticFeedback.lightImpact();
                                          setState(() {
                                            _notice = s.tr(
                                              'الدخول عبر Google غير متاح داخل التطبيق حالياً. استخدم بريدك وكلمة المرور.',
                                              'Google sign-in is not available in-app yet. Please use email and password.',
                                            );
                                          });
                                        },
                                      ),

                                      const SizedBox(height: 12),

                                      // Button 2: Continue With Apple
                                      _buildSocialButton(
                                        key: const Key('auth-apple'),
                                        icon: const Icon(
                                          Icons.apple,
                                          size: 23,
                                          color: Color(0xFF111827),
                                        ),
                                        text: s.tr(
                                          'المتابعة باستخدام Apple',
                                          'Continue With Apple',
                                        ),
                                        onPressed: () {
                                          HapticFeedback.lightImpact();
                                          setState(() {
                                            _notice = s.tr(
                                              'الدخول عبر Apple غير متاح داخل التطبيق حالياً. استخدم بريدك وكلمة المرور.',
                                              'Apple sign-in is not available in-app yet. Please use email and password.',
                                            );
                                          });
                                        },
                                      ),
                                    ],

                                    if (otp) ...[
                                      const SizedBox(height: 16),
                                      TextButton(
                                        onPressed: _busy || _remaining > 0
                                            ? null
                                            : _resend,
                                        child: Text(
                                          _remaining > 0
                                              ? s.tr(
                                                  'إعادة الإرسال بعد $_remaining ثانية',
                                                  'Resend in ${_remaining}s',
                                                )
                                              : s.tr(
                                                  'إرسال رمز جديد',
                                                  'Resend code',
                                                ),
                                          style: const TextStyle(
                                            fontFamily: AppConfig.fontPrimary,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF5E48E8),
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: _busy ? null : _reset,
                                        child: Text(
                                          s.tr(
                                            'العودة لتسجيل الدخول',
                                            'Back to sign in',
                                          ),
                                          style: const TextStyle(
                                            fontFamily: AppConfig.fontPrimary,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 32),

                                    // Bottom Footer Link ("First time here? Create an account")
                                    Center(
                                      child: GestureDetector(
                                        onTap: _busy
                                            ? null
                                            : () {
                                                HapticFeedback.lightImpact();
                                                _form.currentState?.reset();
                                                setState(() {
                                                  _login = !_login;
                                                  _error = null;
                                                  _notice = null;
                                                  _password.clear();
                                                  _confirmation.clear();
                                                });
                                              },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          child: RichText(
                                            textAlign: TextAlign.center,
                                            text: TextSpan(
                                              style: const TextStyle(
                                                fontFamily:
                                                    AppConfig.fontPrimary,
                                                fontSize: 14.5,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: _login
                                                      ? s.tr(
                                                          'أول مرة هنا؟ ',
                                                          'First time here? ',
                                                        )
                                                      : s.tr(
                                                          'لديك حساب بالفعل؟ ',
                                                          'Already have an account? ',
                                                        ),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF111827),
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: _login
                                                      ? s.tr(
                                                          'إنشاء حساب',
                                                          'Create an account',
                                                        )
                                                      : s.tr(
                                                          'تسجيل الدخول',
                                                          'Sign in',
                                                        ),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF5E48E8),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Support Link
                                    Center(
                                      child: TextButton(
                                        onPressed: _busy
                                            ? null
                                            : () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const SupportScreen(),
                                                  ),
                                                );
                                              },
                                        child: Text(
                                          s.tr('المساعدة والدعم', 'Need help?'),
                                          style: const TextStyle(
                                            fontFamily: AppConfig.fontPrimary,
                                            fontSize: 13,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 16),
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

  Widget _buildSocialButton({
    required Key key,
    required Widget icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        key: key,
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF111827),
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.2),
          shape: const StadiumBorder(),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: AppConfig.fontPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Alias for the unified, high-fidelity [CustomAuthInputField].
typedef _CustomInputField = CustomAuthInputField;

/// Vector-painted official Google "G" logo
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
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double r = w / 2;

    final paintBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final paintGreen = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;
    final paintYellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;
    final paintRed = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;

    // Red arc (top)
    final pathRed = Path()
      ..moveTo(cx, cy)
      ..lineTo(cx + r * 0.95, cy - r * 0.3)
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -0.35,
        -2.5,
        false,
      )
      ..close();
    canvas.drawPath(pathRed, paintRed);

    // Yellow arc (left)
    final pathYellow = Path()
      ..moveTo(cx, cy)
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -2.85,
        -1.7,
        false,
      )
      ..close();
    canvas.drawPath(pathYellow, paintYellow);

    // Green arc (bottom)
    final pathGreen = Path()
      ..moveTo(cx, cy)
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -4.55,
        -2.0,
        false,
      )
      ..close();
    canvas.drawPath(pathGreen, paintGreen);

    // Blue arc (right)
    final pathBlue = Path()
      ..moveTo(cx, cy)
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -0.35,
        0.8,
        false,
      )
      ..lineTo(cx + r, cy)
      ..lineTo(cx, cy)
      ..close();
    canvas.drawPath(pathBlue, paintBlue);

    // Horizontal bar
    final barRect = Rect.fromLTWH(cx - 1, cy - r * 0.22, r * 1.02, r * 0.44);
    canvas.drawRect(barRect, paintBlue);

    // Inner cutout
    final innerCutout = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r * 0.58, innerCutout);

    // Right cutout wedge for "G" gap
    final gapPath = Path()
      ..moveTo(cx, cy)
      ..lineTo(cx + r, cy - r * 0.22)
      ..lineTo(cx + r, cy)
      ..lineTo(cx, cy)
      ..close();
    canvas.drawPath(gapPath, innerCutout);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}