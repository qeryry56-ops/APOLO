import 'dart:async';
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
import '../widgets/custom_auth_input_field.dart';
import '../widgets/dl_settings_kit.dart';
import 'forgot_password_screen.dart';
import 'intent_onboarding_screen.dart';
import 'privacy_compliance_screen.dart';
import 'support_screen.dart';

enum _OtpPhase {
  idle,
  sendingInitial,
  verifying,
  resending,
  verified,
  error,
}

/// Premium 2026 APOLO Authentication & Multi-Step Registration Screen.
///
/// Features:
/// - Compact 54px input fields with smooth floating labels.
/// - Login supports either Email or Moroccan Phone number.
/// - Multi-step registration wizard:
///     Step 1: First name, Last name, Gender (with custom UI/UX cards).
///     Step 2: Date of birth, City, Role (Buyer vs Seller cards).
///     Step 3: Email, Password, Confirm password.
///     Step 4: Email OTP verification.
/// - Post-verification pop-up survey modal for category interests.
/// - High-fidelity design matching reference specifications.
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

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _state = AppState();
  final _form = GlobalKey<FormState>();

  // Login & Shared controllers
  final _email = TextEditingController(); // Holds Email OR Phone in login
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _code = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _codeFocus = FocusNode();

  // Login 2-step Dynamic Layer v5.1 state (`1`: Enter Email, `2`: Enter Password)
  int _loginStep = 1;

  // Multi-step Registration controllers & states
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _dob = TextEditingController();
  final _phone = TextEditingController();

  String _gender = 'male'; // 'male' or 'female'
  final int _cityId = 1;
  final String _accountType = 'individual'; // Personal by default (Instagram-style)
  int _registerStep = 1; // 1 to 4
  bool _acceptedTerms = false;

  late final AccountAuth _auth;
  late bool _login;
  bool _busy = false;
  bool _finished = false;
  String? _error;
  String? _notice;
  AccountSession? _pending;
  Timer? _timer;
  Timer? _autoSubmitTimer;
  int _remaining = 0;
  _OtpPhase _otpPhase = _OtpPhase.idle;
  int _resendFailures = 0;
  late final AnimationController _shakeCtrl;

  @override
  void initState() {
    super.initState();
    _login = widget.initialRegisterMode ? false : widget.initialIsLogin;
    _auth = widget.auth ?? AccountAuth(locale: _state.locale.languageCode);
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _email.addListener(_onLoginInputChanged);
    _password.addListener(_onLoginInputChanged);
    _emailFocus.addListener(_onLoginInputChanged);
    _passwordFocus.addListener(_onLoginInputChanged);
    _codeFocus.addListener(() {
      if (mounted) setState(() {});
    });

    if (widget.autoTriggerGoogle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _launchGoogleSignIn();
      });
    }
  }

  Future<void> _launchGoogleSignIn() async {
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
        setState(() {
          _notice = _state.s.tr(
            'تعذر فتح صفحة الدخول عبر Google حالياً.',
            'Impossible d’ouvrir Google sign-in pour le moment.',
          );
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _notice = _state.s.tr(
            'تعذر بدء تسجيل الدخول عبر Google حالياً.',
            'Impossible de démarrer la connexion Google.',
          );
        });
      }
    }
  }

  void _onLoginInputChanged() {
    if (mounted) {
      setState(() {
        if (_login && _pending == null && _error != null) {
          _error = null;
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoSubmitTimer?.cancel();
    _shakeCtrl.dispose();
    _email.removeListener(_onLoginInputChanged);
    _password.removeListener(_onLoginInputChanged);
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _codeFocus.dispose();
    _auth.close();
    for (final controller in [
      _email,
      _password,
      _confirmation,
      _code,
      _firstName,
      _lastName,
      _dob,
      _phone,
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

  String? _validateDob18Plus(String? raw) {
    final text = AccountValidation.normalizeDigits(raw ?? '').trim();
    if (text.isEmpty) {
      return _state.s.tr(
        'يرجى تحديد تاريخ الازدياد (YYYY-MM-DD)',
        'Veuillez saisir votre date de naissance (YYYY-MM-DD)',
        'Please enter your date of birth (YYYY-MM-DD)',
      );
    }
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);
    if (match == null) {
      return _state.s.tr(
        'أدخل التاريخ بصيغة YYYY-MM-DD (مثال: 2005-04-12)',
        'Format requis : YYYY-MM-DD (ex: 2005-04-12)',
        'Required format: YYYY-MM-DD (e.g. 2005-04-12)',
      );
    }
    final year = int.tryParse(match.group(1)!) ?? 0;
    final month = int.tryParse(match.group(2)!) ?? 0;
    final day = int.tryParse(match.group(3)!) ?? 0;
    if (year < 1900 || month < 1 || month > 12 || day < 1 || day > 31) {
      return _state.s.tr(
        'تاريخ الازدياد غير صالح',
        'Date de naissance invalide',
        'Invalid date of birth',
      );
    }
    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return _state.s.tr(
        'تاريخ الازدياد غير صالح',
        'Date de naissance invalide',
        'Invalid date of birth',
      );
    }
    final now = DateTime.now();
    int age = now.year - parsed.year;
    if (now.month < parsed.month ||
        (now.month == parsed.month && now.day < parsed.day)) {
      age--;
    }
    if (age < 18) {
      return _state.s.tr(
        'يجب أن يكون عمرك 18 سنة على الأقل للتسجيل',
        'Vous devez avoir au moins 18 ans pour vous inscrire',
        'You must be at least 18 years old to register',
      );
    }
    return null;
  }

  Future<void> _pickDateOfBirth() async {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    final adultLastDate = DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1940),
      lastDate: adultLastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppConfig.primary,
              onPrimary: Colors.white,
              onSurface: Color(0xFF111827),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dob.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _nextRegisterStep() {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);

    if (_registerStep == 1) {
      if (_firstName.text.trim().length < 2) {
        setState(() => _error = _state.s.tr(
              'أدخل الاسم الشخصي بشكل صحيح (حرفين على الأقل)',
              'Enter a valid first name (at least 2 characters)',
            ));
        return;
      }
      if (_lastName.text.trim().length < 2) {
        setState(() => _error = _state.s.tr(
              'أدخل الاسم العائلي بشكل صحيح (حرفين على الأقل)',
              'Enter a valid last name (at least 2 characters)',
            ));
        return;
      }
      HapticFeedback.lightImpact();
      setState(() => _registerStep = 2);
    } else if (_registerStep == 2) {
      final dobError = _validateDob18Plus(_dob.text);
      if (dobError != null) {
        setState(() => _error = dobError);
        return;
      }
      HapticFeedback.lightImpact();
      setState(() => _registerStep = 3);
    }
  }

  void _prevRegisterStep() {
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      if (_registerStep > 1) {
        _registerStep--;
      }
    });
  }

  void _triggerOtpErrorShake() {
    HapticFeedback.heavyImpact();
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!disableAnimations) {
      _shakeCtrl.forward(from: 0);
    }
  }

  void _onOtpChanged(String raw) {
    final normalized = AccountValidation.normalizeDigits(raw)
        .replaceAll(RegExp(r'[^0-9]'), '');
    if (normalized != raw) {
      _code.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    }
    if (_otpPhase == _OtpPhase.error || _error != null) {
      setState(() {
        _error = null;
        if (_otpPhase == _OtpPhase.error) _otpPhase = _OtpPhase.idle;
      });
    } else {
      setState(() {});
    }

    _autoSubmitTimer?.cancel();
    if (normalized.length == 6 &&
        _pending != null &&
        !_busy &&
        _otpPhase != _OtpPhase.verifying &&
        _otpPhase != _OtpPhase.verified) {
      _autoSubmitTimer = Timer(const Duration(milliseconds: 180), () {
        if (mounted &&
            _pending != null &&
            !_busy &&
            _code.text.length == 6 &&
            _otpPhase != _OtpPhase.verifying) {
          _submit();
        }
      });
    }
  }

  Future<void> _sendInitialLoginOtp(AccountSession session) async {
    final email = (session.user['email'] ?? '').toString().trim();
    if (email.isEmpty) {
      if (!mounted || _pending?.token != session.token) return;
      setState(() {
        _otpPhase = _OtpPhase.error;
        _error = _state.s.tr(
          'لا يوجد بريد إلكتروني مسجل في هذا الحساب لاستلام رمز التحقق. يرجى استخدام الموقع أو الدعم.',
          'Aucune adresse e-mail n’est associée à ce compte pour recevoir le code.',
          'No email address is linked to this account to receive the code.',
        );
      });
      return;
    }

    try {
      await _auth.resend(session);
      if (!mounted || _pending?.token != session.token) return;
      final masked = AccountValidation.maskEmail(email) ?? email;
      setState(() {
        _otpPhase = _OtpPhase.idle;
        _notice = _state.s.tr(
          'تم إرسال رمز التحقق إلى بريدك الإلكتروني ($masked).',
          'Un code de vérification a été envoyé à $masked.',
          'A verification code was sent to $masked.',
        );
      });
      _cooldown();
    } catch (error) {
      if (!mounted || _pending?.token != session.token) return;
      setState(() {
        _otpPhase = _OtpPhase.error;
        _error = accountError(error, _state.s.isAr);
      });
    }
  }

  bool _isValidLoginIdentifier(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return false;
    return AccountValidation.email(text) ||
        AccountValidation.phone(text) != null;
  }

  void _advanceLoginEmailStep() {
    if (_busy || _finished) return;
    final text = _email.text.trim();
    if (text.isEmpty) {
      _emailFocus.requestFocus();
      return;
    }
    if (!_isValidLoginIdentifier(text)) {
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
    HapticFeedback.selectionClick();
    setState(() {
      _error = null;
      _loginStep = 2;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _passwordFocus.requestFocus();
    });
  }

  Future<void> _submit() async {
    _autoSubmitTimer?.cancel();
    if (_busy || _finished) return;

    if (_pending != null) {
      if (!AccountValidation.otp(_code.text)) {
        setState(() {
          _otpPhase = _OtpPhase.error;
          _error = _state.s.tr(
            'أدخل رمز التحقق المكون من 6 أرقام.',
            'Entrez le code de vérification à 6 chiffres.',
            'Enter the 6-digit verification code.',
          );
        });
        _triggerOtpErrorShake();
        return;
      }
    } else if (_login) {
      if (_loginStep == 1) {
        _advanceLoginEmailStep();
        return;
      }
      if (!_isValidLoginIdentifier(_email.text)) {
        setState(() {
          _loginStep = 1;
          _error = _state.s.tr(
            'يرجى إدخال بريد إلكتروني صحيح',
            'Veuillez saisir une adresse e-mail valide',
            'Please enter a valid email address',
          );
        });
        return;
      }
      if (_password.text.isEmpty) {
        _passwordFocus.requestFocus();
        return;
      }
    } else if (!_form.currentState!.validate()) {
      return;
    } else if (!_login && !_acceptedTerms) {
      HapticFeedback.heavyImpact();
      setState(() {
        _error = _state.s.tr(
          'يرجى الموافقة على الشروط والأحكام وسياسة الخصوصية للمتابعة',
          'Veuillez accepter les conditions d’utilisation et la politique de confidentialité',
          'Please accept the Terms & Conditions and Privacy Policy to continue',
        );
      });
      return;
    }

    FocusScope.of(context).unfocus();
    final isVerifyingOtp = _pending != null;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
      if (isVerifyingOtp) _otpPhase = _OtpPhase.verifying;
    });

    try {
      final AccountSession result;
      if (isVerifyingOtp) {
        // Step 4 verification (or OTP in login)
        result = await _auth.verify(_pending!, _code.text);
      } else if (_login) {
        // Sign in with email or phone
        result = await _auth.login(_email.text, _password.text);
      } else {
        // Step 3 registration submission
        final fullName =
            "${_firstName.text.trim()} ${_lastName.text.trim()}".trim();
        final phone = _phone.text.trim();

        result = await _auth.register(
          name: fullName.isNotEmpty ? fullName : 'User',
          email: _email.text.trim(),
          phone: phone,
          password: _password.text,
          confirmation: _confirmation.text,
        );
      }

      if (!mounted) return;
      if (result.requiresOtp) {
        setState(() {
          _pending = result;
          _code.clear();
          _resendFailures = 0;
          _otpPhase =
              result.otpSent ? _OtpPhase.idle : _OtpPhase.sendingInitial;
          if (!_login) _registerStep = 4;
        });
        _password.clear();
        _confirmation.clear();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _codeFocus.requestFocus();
        });
        if (result.otpSent) {
          _cooldown();
        } else {
          await _sendInitialLoginOtp(result);
        }
      } else {
        if (isVerifyingOtp) {
          HapticFeedback.mediumImpact();
          setState(() => _otpPhase = _OtpPhase.verified);
        }
        await _finish(result);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = accountError(error, _state.s.isAr);
          if (isVerifyingOtp) _otpPhase = _OtpPhase.error;
        });
        if (isVerifyingOtp) {
          _triggerOtpErrorShake();
        }
      }
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

      final isFromRegistration = !_login;
      final callback = widget.onSuccess;
      final navigator = Navigator.of(context);
      final route = ModalRoute.of(context);

      if (route != null && route.isCurrent && navigator.canPop()) {
        navigator.pop(true);
      } else if (route != null && !route.isCurrent) {
        navigator.removeRoute(route);
      }
      callback?.call();

      // Show Dynamic Layer v5.1 intent onboarding screen if newly registered
      if (isFromRegistration && navigator.context.mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!navigator.context.mounted) return;
          Navigator.of(navigator.context).push(
            MaterialPageRoute<void>(
              builder: (_) => ApoloIntentOnboardingScreen(
                auth: _auth,
                session: result,
                accountType: _accountType,
                cityId: _cityId,
              ),
            ),
          );
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = accountError(error, _state.s.isAr));
    }
  }

  Future<void> _resend() async {
    if (_busy ||
        _remaining > 0 ||
        _pending == null ||
        _otpPhase == _OtpPhase.sendingInitial ||
        _otpPhase == _OtpPhase.resending ||
        _otpPhase == _OtpPhase.verifying) {
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _otpPhase = _OtpPhase.resending;
      _error = null;
      _notice = null;
    });

    try {
      await _auth.resend(_pending!);
      if (!mounted) return;
      final masked = AccountValidation.maskEmail(
        _pending?.user['email']?.toString(),
      );
      setState(() {
        _otpPhase = _OtpPhase.idle;
        _resendFailures = 0;
        _notice = masked != null
            ? _state.s.tr(
                'تم إرسال رمز جديد إلى $masked. تحقق من البريد الوارد أو الرسائل غير المرغوب فيها.',
                'Un nouveau code a été envoyé à $masked. Vérifiez votre boîte ou les spams.',
                'A new verification code was sent to $masked. Check your inbox or spam.',
              )
            : _state.s.tr(
                'تم تأكيد إرسال رمز جديد. تحقق من بريدك.',
                'Un nouveau code a été envoyé. Vérifiez votre boîte e-mail.',
                'A new verification code was sent. Please check your email inbox.',
              );
      });
      _cooldown();
    } catch (error) {
      if (!mounted) return;
      _resendFailures++;
      final now = DateTime.now();
      final hh = now.hour.toString().padLeft(2, '0');
      final mm = now.minute.toString().padLeft(2, '0');
      final base = accountError(error, _state.s.isAr);
      HapticFeedback.heavyImpact();
      setState(() {
        _otpPhase = _OtpPhase.error;
        _error = _resendFailures >= 2
            ? _state.s.tr(
                '$base (آخر محاولة: $hh:$mm)',
                '$base (Dernière tentative : $hh:$mm)',
                '$base (Tried at $hh:$mm)',
              )
            : base;
      });
    }
  }

  void _reset() {
    _timer?.cancel();
    _autoSubmitTimer?.cancel();
    setState(() {
      _pending = null;
      _code.clear();
      _remaining = 0;
      _otpPhase = _OtpPhase.idle;
      _resendFailures = 0;
      _error = null;
      _notice = null;
      if (!_login) _registerStep = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final isAr = s.isAr;
    final otp = _pending != null || (!_login && _registerStep == 4);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final Color surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color inkColor =
        isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final Color mutedColor =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final Color borderColor =
        isDark ? const Color(0xFF2D2D2D) : const Color(0xFFE5E7EB);

    if (_login && !otp) {
      return _buildDynamicLayerLoginScaffold(
        context,
        s: s,
        isAr: isAr,
        isDark: isDark,
        bgColor: bgColor,
      );
    }

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar: Single RTL-anchored dismiss/back control (no repetitive login title)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                child: SizedBox(
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: _buildBackButton(
                          isOtp: otp,
                          isDark: isDark,
                          isAr: isAr,
                        ),
                      ),
                      if (!otp && !_login)
                        Text(
                          s.tr('إنشاء حساب', 'Sign up'),
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

              // Progress Bar (when registering, hidden on OTP step)
              if (!_login && !otp) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            s.tr(
                              'الخطوة $_registerStep من 4',
                              'Step $_registerStep of 4',
                            ),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppConfig.primary,
                            ),
                          ),
                          Text(
                            _registerStep == 1
                                ? s.tr('المعلومات الشخصية', 'Personal info')
                                : _registerStep == 2
                                    ? s.tr('تاريخ الميلاد', 'Birth date')
                                    : _registerStep == 3
                                        ? s.tr('بيانات الدخول', 'Credentials')
                                        : s.tr('التحقق', 'Verification'),
                            style: TextStyle(
                              fontSize: 12.5,
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(4, (index) {
                          final stepNum = index + 1;
                          final isPassed = stepNum <= _registerStep;
                          return Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 4,
                              margin: EdgeInsetsDirectional.only(
                                start: index == 0 ? 0 : 4,
                                end: index == 3 ? 0 : 4,
                              ),
                              decoration: BoxDecoration(
                                color: isPassed
                                    ? AppConfig.primary
                                    : borderColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],

              // Scrollable Content + Anchored Footer
              Expanded(
                child: Form(
                  key: _form,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),

                              // Main Headline
                              Text(
                                otp
                                    ? s.tr(
                                        'لنتأكد من هويتك',
                                        'Confirmons votre identité',
                                        "Let's confirm it's you",
                                      )
                                    : _login
                                        ? s.tr(
                                            'مرحباً بك مجدداً',
                                            'Bon retour',
                                            'Welcome back',
                                          )
                                        : _registerStep == 1
                                            ? s.tr('لنبدأ باسمك',
                                                'Let\'s start with your name')
                                            : _registerStep == 2
                                                ? s.tr('أخبرنا عنك',
                                                    'Tell us about yourself')
                                                : s.tr('حسابك وأمانك',
                                                    'Account & Security'),
                                style: TextStyle(
                                  fontSize: otp ? 26 : 28,
                                  fontWeight: FontWeight.w800,
                                  color: inkColor,
                                  letterSpacing: AppTypography.trackingForContext(
                                      context, -0.5),
                                  height: 1.2,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Builder(
                                builder: (_) {
                                  final maskedEmail =
                                      AccountValidation.maskEmail(
                                    _pending?.user['email']?.toString(),
                                  );
                                  final subtitle = otp
                                      ? (maskedEmail != null
                                          ? s.tr(
                                              'أدخل الرمز المكون من 6 أرقام المرسل إلى $maskedEmail',
                                              'Entrez le code à 6 chiffres envoyé à $maskedEmail',
                                              'Enter the 6-digit code sent to $maskedEmail',
                                            )
                                          : s.tr(
                                              'أدخل الرمز المكون من 6 أرقام المرسل إلى بريدك الإلكتروني',
                                              'Entrez le code à 6 chiffres envoyé à votre e-mail',
                                              'Enter the 6-digit code sent to your email',
                                            ))
                                      : _login
                                          ? s.tr(
                                              'أدخل بريدك الإلكتروني أو رقم هاتفك للمتابعة',
                                              'Entrez votre e-mail ou numéro de téléphone pour continuer',
                                              'Enter your email or phone number to continue',
                                            )
                                          : _registerStep == 1
                                              ? s.tr(
                                                  'أدخل اسمك الشخصي والعائلي وحدد الجنس',
                                                  'Enter your name and select your gender',
                                                )
                                              : _registerStep == 2
                                                  ? s.tr(
                                                      'حدد تاريخ ميلادك لإعداد حسابك الشخصي',
                                                      'Set your birth date to continue',
                                                    )
                                                  : s.tr(
                                                      'أدخل بريدك الإلكتروني وكلمة مرور قوية',
                                                      'Enter your email and a strong password',
                                                    );
                                  return Text(
                                    subtitle,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: otp
                                          ? (isDark
                                              ? const Color(0xFF9CA3AF)
                                              : const Color(0xFF5B616E))
                                          : mutedColor,
                                      height: 1.45,
                                    ),
                                  );
                                },
                              ),

                              SizedBox(height: otp ? 32 : 24),

                              // Error Banner
                              if (_error != null)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF2B1215)
                                        : const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF7F1D1D)
                                          : const Color(0xFFFCA5A5),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Color(0xFFDC2626),
                                        size: 19,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? const Color(0xFFFCA5A5)
                                                : const Color(0xFFB91C1C),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Notice Banner
                              if (_notice != null)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF334155)
                                          : const Color(0xFFCBD5E1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: mutedColor,
                                        size: 19,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _notice!,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: inkColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // ============================================
                              // MODE 1: LOGIN (EMAIL OR PHONE + PASSWORD)
                              // ============================================
                              if (_login && !otp) ...[
                                CustomAuthInputField(
                                  controller: _email,
                                  label: s.tr(
                                    'البريد الإلكتروني أو رقم الهاتف',
                                    'E-mail ou numéro de téléphone',
                                    'Email or mobile number',
                                  ),
                                  keyName: 'auth-email',
                                  type: TextInputType.emailAddress,
                                  autofill: const [
                                    AutofillHints.email,
                                    AutofillHints.telephoneNumber,
                                  ],
                                  enabled: !_busy,
                                  validator: (v) {
                                    final text = (v ?? '').trim();
                                    if (text.isEmpty) {
                                      return s.tr(
                                        'أدخل البريد الإلكتروني أو رقم الهاتف',
                                        'Enter email or phone number',
                                      );
                                    }
                                    final isEmail =
                                        AccountValidation.email(text);
                                    final isPhone =
                                        AccountValidation.phone(text) != null;
                                    if (!isEmail && !isPhone) {
                                      return s.tr(
                                        'أدخل بريداً صحيحاً أو رقماً يبدأ بـ \u206605/06/07\u2069',
                                        'Enter a valid email or phone (05/06/07)',
                                      );
                                    }
                                    return null;
                                  },
                                ),

                                CustomAuthInputField(
                                  controller: _password,
                                  label: s.tr(
                                    'كلمة المرور',
                                    'Mot de passe',
                                    'Password',
                                  ),
                                  keyName: 'auth-password',
                                  secret: true,
                                  autofill: const [AutofillHints.password],
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: _busy ? null : _submit,
                                  enabled: !_busy,
                                  validator: (v) => (v ?? '').isNotEmpty
                                      ? null
                                      : s.tr(
                                          'أدخل كلمة المرور',
                                          'Please enter your password',
                                        ),
                                ),

                                // Neutral RTL-aligned "Forgot Password?" link
                                Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: GestureDetector(
                                    onTap: _busy
                                        ? null
                                        : () {
                                            HapticFeedback.lightImpact();
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    ForgotPasswordScreen(
                                                  initialEmail:
                                                      _email.text.trim(),
                                                  auth: _auth,
                                                ),
                                              ),
                                            );
                                          },
                                    behavior: HitTestBehavior.opaque,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      child: Text(
                                        s.tr(
                                          'نسيت كلمة المرور؟',
                                          'Mot de passe oublié ?',
                                          'Forgot your password?',
                                        ),
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w500,
                                          color: mutedColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 18),

                                // Primary CTA Button (2026 Monochrome: 54px height, Pill StadiumBorder)
                                _TapPressScale(
                                  enabled: !_busy,
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: ElevatedButton(
                                      key: const Key('auth-submit'),
                                      onPressed: _busy ? null : _submit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isDark
                                            ? Colors.white
                                            : const Color(0xFF0A0A0A),
                                        disabledBackgroundColor: (isDark
                                                ? Colors.white
                                                : const Color(0xFF0A0A0A))
                                            .withValues(alpha: 0.55),
                                        foregroundColor: isDark
                                            ? const Color(0xFF0A0A0A)
                                            : Colors.white,
                                        shape: const StadiumBorder(),
                                        elevation: 0,
                                      ),
                                      child: _busy
                                          ? SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: isDark
                                                    ? const Color(0xFF0A0A0A)
                                                    : Colors.white,
                                              ),
                                            )
                                          : Text(
                                              s.tr(
                                                'تسجيل الدخول',
                                                'Se connecter',
                                                'Sign in',
                                              ),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: isDark
                                                    ? const Color(0xFF0A0A0A)
                                                    : Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),

                                // High-contrast WCAG AA "أو" Divider
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 20),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                          color: borderColor,
                                          thickness: 1,
                                          height: 1,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: Text(
                                          s.tr('أو', 'ou', 'or'),
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w500,
                                            color: mutedColor,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                          color: borderColor,
                                          thickness: 1,
                                          height: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Social Login: Google Only (Apple login removed)
                                _buildSocialButton(
                                  key: const Key('auth-google'),
                                  icon: const _GoogleIcon(size: 20),
                                  text: s.tr(
                                    'المتابعة باستخدام Google',
                                    'Continuer avec Google',
                                    'Continue With Google',
                                  ),
                                  surfaceColor: surfaceColor,
                                  textColor: inkColor,
                                  borderColor: borderColor,
                                  onPressed: _launchGoogleSignIn,
                                ),
                              ],

                        // ============================================
                        // MODE 2: REGISTER STEP 1 (NAME & GENDER)
                        // ============================================
                        if (!_login && _registerStep == 1) ...[
                          CustomAuthInputField(
                            controller: _firstName,
                            label: s.tr('الاسم الشخصي', 'First name'),
                            keyName: 'reg-first-name',
                            hint: 'Amine',
                            validator: (v) => (v ?? '').trim().length >= 2
                                ? null
                                : s.tr('أدخل اسمك الشخصي', 'Enter first name'),
                          ),
                          CustomAuthInputField(
                            controller: _lastName,
                            label: s.tr('الاسم العائلي', 'Last name'),
                            keyName: 'reg-last-name',
                            hint: 'El Amrani',
                            validator: (v) => (v ?? '').trim().length >= 2
                                ? null
                                : s.tr('أدخل اسمك العائلي', 'Enter last name'),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.tr('الجنس', 'Gender'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSelectionCard(
                                  selected: _gender == 'male',
                                  icon: Icons.male_rounded,
                                  title: s.tr('ذكر', 'Homme'),
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _gender = 'male');
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSelectionCard(
                                  selected: _gender == 'female',
                                  icon: Icons.female_rounded,
                                  title: s.tr('أنثى', 'Femme'),
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _gender = 'female');
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              key: const Key('reg-step1-continue'),
                              onPressed: _nextRegisterStep,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark
                                    ? Colors.white
                                    : const Color(0xFF0A0A0A),
                                foregroundColor: isDark
                                    ? const Color(0xFF0A0A0A)
                                    : Colors.white,
                                shape: const StadiumBorder(),
                                elevation: 0,
                              ),
                              child: Text(
                                s.tr('متابعة', 'Continuer', 'Continue'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],

                        // ============================================
                        // MODE 2: REGISTER STEP 2 (DOB 18+ & BUYER/SELLER)
                        // ============================================
                        if (!_login && _registerStep == 2) ...[
                          CustomAuthInputField(
                            controller: _dob,
                            label: s.tr(
                              'تاريخ الازدياد (+18)',
                              'Date de naissance (+18)',
                              'Date of birth (18+)',
                            ),
                            keyName: 'reg-dob',
                            hint: 'YYYY-MM-DD',
                            maskPattern: 'YYYY-MM-DD',
                            type: TextInputType.datetime,
                            inputFormatters: const [_DobDateInputFormatter()],
                            trailingWidget: GestureDetector(
                              onTap: _pickDateOfBirth,
                              behavior: HitTestBehavior.opaque,
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: Center(
                                  child: Icon(
                                    CupertinoIcons.calendar,
                                    size: 19,
                                    color: mutedColor,
                                  ),
                                ),
                              ),
                            ),
                            validator: _validateDob18Plus,
                          ),

                          const SizedBox(height: 8),

                          // Clean Instagram-style Personal-by-default note
                          Container(
                            key: const Key('reg-personal-default-note'),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF141B26)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: borderColor,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  CupertinoIcons.sparkles,
                                  size: 18,
                                  color: inkColor,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    s.tr(
                                      'سيتم إنشاء حسابك كحساب شخصي للبيع والشراء بحرية. يمكنك التحويل إلى حساب أعمال (Business) مجاناً في أي وقت من الإعدادات.',
                                      'Votre compte sera créé en mode Personnel. Vous pourrez basculer gratuitement vers un compte Business à tout moment depuis les paramètres.',
                                      'Your account starts as Personal. You can switch to a free Business profile anytime in Settings.',
                                    ),
                                    style: TextStyle(
                                      fontSize: 12.8,
                                      height: 1.45,
                                      color: mutedColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: SizedBox(
                                  height: 54,
                                  child: OutlinedButton(
                                    onPressed: _prevRegisterStep,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: inkColor,
                                      side: BorderSide(
                                        color: borderColor,
                                        width: 1.2,
                                      ),
                                      shape: const StadiumBorder(),
                                    ),
                                    child: Text(
                                      s.tr('رجوع', 'Retour', 'Back'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: SizedBox(
                                  height: 54,
                                  child: ElevatedButton(
                                    key: const Key('reg-step2-continue'),
                                    onPressed: _nextRegisterStep,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDark
                                          ? Colors.white
                                          : const Color(0xFF0A0A0A),
                                      foregroundColor: isDark
                                          ? const Color(0xFF0A0A0A)
                                          : Colors.white,
                                      shape: const StadiumBorder(),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      s.tr('متابعة', 'Continuer', 'Continue'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],

                        // ============================================
                        // MODE 2: REGISTER STEP 3 (EMAIL, PASSWORD & TERMS)
                        // ============================================
                        if (!_login && _registerStep == 3) ...[
                          CustomAuthInputField(
                            controller: _email,
                            label: s.tr('البريد الإلكتروني', 'Email'),
                            keyName: 'auth-email',
                            type: TextInputType.emailAddress,
                            autofill: const [AutofillHints.email],
                            hint: 'example@apolo.ma',
                            enabled: !_busy,
                            validator: (v) => AccountValidation.email(v ?? '')
                                ? null
                                : s.tr(
                                    'أدخل بريداً إلكترونياً صحيحاً',
                                    'Enter a valid email address',
                                  ),
                          ),
                          CustomAuthInputField(
                            controller: _phone,
                            label: s.tr('رقم الهاتف', 'Téléphone', 'Phone number'),
                            keyName: 'auth-phone',
                            type: TextInputType.phone,
                            autofill: const [AutofillHints.telephoneNumber],
                            hint: '06 12 34 56 78',
                            enabled: !_busy,
                            validator: (v) => AccountValidation.phone(v ?? '') != null
                                ? null
                                : s.tr(
                                    'أدخل رقم هاتف مغربي صحيح (مثال: 0612345678)',
                                    'Numéro marocain invalide (ex: 0612345678)',
                                    'Enter a valid Moroccan phone number',
                                  ),
                          ),
                          CustomAuthInputField(
                            controller: _password,
                            label: s.tr('كلمة المرور', 'Password'),
                            keyName: 'auth-password',
                            secret: true,
                            autofill: const [AutofillHints.newPassword],
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
                            controller: _confirmation,
                            label:
                                s.tr('تأكيد كلمة المرور', 'Confirm password'),
                            keyName: 'auth-confirmation',
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
                          const SizedBox(height: 4),
                          // Terms & Conditions acceptance row
                          GestureDetector(
                            onTap: _busy
                                ? null
                                : () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _acceptedTerms = !_acceptedTerms;
                                      if (_acceptedTerms) _error = null;
                                    });
                                  },
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  AnimatedContainer(
                                    key: const Key('reg-terms-checkbox'),
                                    duration: const Duration(milliseconds: 160),
                                    curve: Curves.easeOutCubic,
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: _acceptedTerms
                                          ? (isDark
                                              ? Colors.white
                                              : const Color(0xFF0A0A0A))
                                          : surfaceColor,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: _acceptedTerms
                                            ? (isDark
                                                ? Colors.white
                                                : const Color(0xFF0A0A0A))
                                            : borderColor,
                                        width: 1.5,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: _acceptedTerms
                                        ? Icon(
                                            Icons.check_rounded,
                                            size: 15,
                                            color: isDark
                                                ? const Color(0xFF0A0A0A)
                                                : Colors.white,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          s.tr(
                                            'أوافق على ',
                                            'J’accepte les ',
                                            'I agree to the ',
                                          ),
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            color: mutedColor,
                                            height: 1.35,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            HapticFeedback.lightImpact();
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const PrivacyComplianceScreen(
                                                  initialTab: 0,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            s.tr(
                                              'الشروط والأحكام وسياسة الخصوصية',
                                              'Conditions d’utilisation et Politique de confidentialité',
                                              'Terms & Conditions and Privacy Policy',
                                            ),
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: inkColor,
                                              decoration:
                                                  TextDecoration.underline,
                                              height: 1.35,
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
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: SizedBox(
                                  height: 54,
                                  child: OutlinedButton(
                                    onPressed: _busy ? null : _prevRegisterStep,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: inkColor,
                                      side: BorderSide(
                                        color: borderColor,
                                        width: 1.2,
                                      ),
                                      shape: const StadiumBorder(),
                                    ),
                                    child: Text(
                                      s.tr('رجوع', 'Retour', 'Back'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: SizedBox(
                                  height: 54,
                                  child: ElevatedButton(
                                    key: const Key('auth-submit'),
                                    onPressed: _busy ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDark
                                          ? Colors.white
                                          : const Color(0xFF0A0A0A),
                                      foregroundColor: isDark
                                          ? const Color(0xFF0A0A0A)
                                          : Colors.white,
                                      shape: const StadiumBorder(),
                                      elevation: 0,
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
                                            s.tr(
                                                'إنشاء الحساب',
                                                'Créer un compte',
                                                'Create account'),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],

                        // ============================================
                        // MODE 3: OTP VERIFICATION (STEP 4 / 2FA)
                        // ============================================
                        if (otp) ...[
                          _buildOtpBoxesSection(s),
                          const SizedBox(height: 36),
                          _buildOtpResendRow(s),
                          const SizedBox(height: 24),
                          _buildOtpSecurityBanner(s),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              key: const Key('auth-submit'),
                              onPressed: _busy ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _code.text.trim().length == 6
                                    ? const Color(0xFF0A0B0D)
                                    : const Color(0xFFF3F5F8),
                                foregroundColor: _code.text.trim().length == 6
                                    ? Colors.white
                                    : const Color(0xFF8A94A6),
                                shape: const StadiumBorder(),
                                elevation: 0,
                              ),
                              child: _busy || _otpPhase == _OtpPhase.verifying
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _code.text.trim().length == 6
                                            ? Colors.white
                                            : const Color(0xFF0A0B0D),
                                      ),
                                    )
                                  : _otpPhase == _OtpPhase.verified
                                      ? const Icon(
                                          Icons.check_rounded,
                                          size: 22,
                                          color: Colors.white,
                                        )
                                      : Text(
                                          s.tr(
                                            'تأكيد الرمز',
                                            'Confirmer le code',
                                            'Verify code',
                                          ),
                                          style: const TextStyle(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                  // Anchored Bottom Footer (Register Toggle + Support Link)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!otp)
                            GestureDetector(
                              onTap: _busy
                                  ? null
                                  : () {
                                      HapticFeedback.lightImpact();
                                      _form.currentState?.reset();
                                      setState(() {
                                        _login = !_login;
                                        _registerStep = 1;
                                        _error = null;
                                        _notice = null;
                                        _password.clear();
                                        _confirmation.clear();
                                      });
                                    },
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Text.rich(
                                  TextSpan(
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: _login
                                            ? s.tr(
                                                'أول مرة هنا؟ ',
                                                'Nouveau ici ? ',
                                                'First time here? ',
                                              )
                                            : s.tr(
                                                'لديك حساب بالفعل؟ ',
                                                'Déjà un compte ? ',
                                                'Already have an account? ',
                                              ),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w400,
                                          color: mutedColor,
                                        ),
                                      ),
                                      TextSpan(
                                        text: _login
                                            ? s.tr(
                                                'إنشاء حساب',
                                                'Créer un compte',
                                                'Create an account',
                                              )
                                            : s.tr(
                                                'تسجيل الدخول',
                                                'Se connecter',
                                                'Sign in',
                                              ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppConfig.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          if (!otp)
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const SupportScreen(),
                                        ),
                                      );
                                    },
                              child: Text(
                                s.tr('المساعدة والدعم', 'Aide et support',
                                    'Need help?'),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: mutedColor,
                                ),
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
        ],
      ),
    ),
  ),
);
  }

  Widget _buildOtpBoxesSection(AppStrings s) {
    final digits = AccountValidation.normalizeDigits(_code.text)
        .replaceAll(RegExp(r'[^0-9]'), '');
    final isError = _otpPhase == _OtpPhase.error;
    final activeIndex = digits.length < 6 ? digits.length : -1;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: AnimatedBuilder(
        animation: _shakeCtrl,
        builder: (context, child) {
          final dx = _shakeCtrl.isAnimating
              ? math.sin(_shakeCtrl.value * math.pi * 6) * 6.0
              : 0.0;
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (!_busy) _codeFocus.requestFocus();
          },
          child: SizedBox(
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  children: List.generate(6, (index) {
                    final hasDigit = index < digits.length;
                    final digit = hasDigit ? digits[index] : '';
                    final isActive = index == activeIndex &&
                        (_codeFocus.hasFocus || digits.isEmpty);

                    final Color bgColor;
                    final Color borderColor;
                    final double borderWidth;
                    if (isError) {
                      bgColor = const Color(0xFFFEF2F2);
                      borderColor = const Color(0xFFDC2626);
                      borderWidth = 1.5;
                    } else if (isActive) {
                      bgColor = Colors.white;
                      borderColor = AppConfig.primary;
                      borderWidth = 1.8;
                    } else {
                      bgColor = const Color(0xFFF3F5F8);
                      borderColor = Colors.transparent;
                      borderWidth = 1.5;
                    }

                    return Expanded(
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(
                          start: index == 0 ? 0 : 4,
                          end: index == 5 ? 0 : 4,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          curve: Curves.easeOutCubic,
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: borderColor,
                              width: borderWidth,
                            ),
                          ),
                          child: Text(
                            digit,
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0A0B0D),
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                Positioned.fill(
                  child: TextField(
                    key: const Key('auth-code'),
                    controller: _code,
                    focusNode: _codeFocus,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    maxLength: 6,
                    enabled: !_busy,
                    showCursor: false,
                    enableInteractiveSelection: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9\u0660-\u0669\u06F0-\u06F9]'),
                      ),
                    ],
                    style: const TextStyle(
                      color: Colors.transparent,
                      fontSize: 1,
                    ),
                    cursorColor: Colors.transparent,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      filled: false,
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: _onOtpChanged,
                    onSubmitted: (_) => _submit(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpResendRow(AppStrings s) {
    final isSending = _otpPhase == _OtpPhase.sendingInitial ||
        _otpPhase == _OtpPhase.resending;
    final canTapResend = !isSending && !_busy && _remaining == 0;

    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        children: [
          Text(
            s.tr(
              'لم يصلك الرمز؟',
              'Code non reçu ?',
              "Didn't get a code?",
            ),
            style: const TextStyle(
              fontSize: 14.5,
              color: Color(0xFF5B616E),
              fontWeight: FontWeight.w400,
            ),
          ),
          if (isSending)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CupertinoActivityIndicator(radius: 7),
                const SizedBox(width: 6),
                Text(
                  s.tr('جاري الإرسال...', 'Envoi...', 'Sending...'),
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF5B616E),
                  ),
                ),
              ],
            )
          else
            GestureDetector(
              key: const Key('otp-resend'),
              onTap: canTapResend ? _resend : null,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Text(
                  _remaining > 0
                      ? s.tr(
                          'إعادة الإرسال ($_remaining ث)',
                          'Renvoyer (${_remaining}s)',
                          'Resend (${_remaining}s)',
                        )
                      : s.tr(
                          'إعادة الإرسال',
                          'Renvoyer',
                          'Resend',
                        ),
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: canTapResend
                        ? AppConfig.primary
                        : const Color(0xFFC4C8D0),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOtpSecurityBanner(AppStrings s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.info,
              size: 20,
              color: Color(0xFF717885),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              s.tr(
                'لن يطلب منك أبولو أبداً إنشاء حساب جديد أو تحويل أموال. لا تدخل أبداً أي رمز يعطيه لك شخص آخر.',
                'Apolo ne vous demandera jamais de créer un nouveau compte ou de transférer des fonds. N’entrez jamais un code fourni par un tiers.',
                'Apolo will never ask you to set up a new account or transfer funds. Never enter a code given to you by someone else.',
              ),
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF5B616E),
                height: 1.45,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Exact Figma `dynamic-layer-core-v5.1` `Log in` 2-step screen (`45786:56733`, `45786:57262`, `21414:22440`):
  /// - Step 1 (`_loginStep == 1`): `Enter Email` (`wrapper` `375 × 164`, `padding: 32 top/bottom, 16 left/right`, `gap: 32`)
  /// - Step 2 (`_loginStep == 2`): `Enter Password` (`wrapper` `375 × 236`, `Forgot password?` `#EEEEEE` pill)
  /// - Fixed bottom `ButtonDock` (`56px` stadium `Continue`: `#EEEEEE` when empty -> `#000000` when filled, lifting cleanly above keyboard).
  Widget _buildDynamicLayerLoginScaffold(
    BuildContext context, {
    required AppStrings s,
    required bool isAr,
    required bool isDark,
    required Color bgColor,
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

    final Color ink = isDark ? Colors.white : const Color(0xFF000000);
    final Color pillBg =
        isDark ? const Color(0xFF262629) : const Color(0xFFEEEEEE);
    final Color disabledText =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF757575);
    final Color errorRed = const Color(0xFFE31B23);

    final bool isStep1 = _loginStep == 1;
    final bool isFilled =
        isStep1 ? _email.text.trim().isNotEmpty : _password.text.isNotEmpty;
    final Color continueBg =
        isFilled ? (isDark ? Colors.white : const Color(0xFF000000)) : pillBg;
    final Color continueFg =
        isFilled ? (isDark ? const Color(0xFF000000) : Colors.white) : disabledText;

    final int emailLen = _email.text.length;
    final double dynamicInputFontSize = !isStep1
        ? 28.0
        : (emailLen > 28 ? 19.0 : (emailLen > 20 ? 23.0 : 28.0));

    final backIcon =
        isAr ? CupertinoIcons.chevron_right : CupertinoIcons.chevron_left;

    void handleBack() {
      HapticFeedback.lightImpact();
      if (_busy) return;
      if (_loginStep == 2) {
        setState(() {
          _loginStep = 1;
          _error = null;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _emailFocus.requestFocus();
        });
        return;
      }
      final nav = Navigator.of(context);
      if (nav.canPop()) {
        nav.pop();
      }
    }

    return PopScope(
      canPop: _loginStep == 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) handleBack();
      },
      child: Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: bgColor,
          resizeToAvoidBottomInset: true,
          body: Column(
            children: [
              // Fixed `56px` TopNavigation (`40×40` circular `#EEEEEE` `<` button, no separator)
              SizedBox(
                key: const Key('dl-login-top-nav'),
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
                            key: const Key('auth-dismiss'),
                            icon: backIcon,
                            backgroundColor: pillBg,
                            iconColor: ink,
                            tooltip: MaterialLocalizations.of(context)
                                .backButtonTooltip,
                            onPressed: handleBack,
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
                          key: const Key('dl-login-wrapper'),
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
                                isStep1
                                    ? s.tr(
                                        'أدخل بريدك الإلكتروني',
                                        'Entrez votre e-mail',
                                        'Enter your email',
                                      )
                                    : s.tr(
                                        'أدخل كلمة المرور',
                                        'Entrez votre mot de passe',
                                        'Enter your password',
                                      ),
                                key: const Key('dl-login-prompt-label'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: ink,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w700,
                                  height: 24.0 / 16.0,
                                ),
                              ),
                              const SizedBox(height: 32.0),

                              if (isStep1)
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: TextField(
                                    key: const Key('auth-email'),
                                    controller: _email,
                                    focusNode: _emailFocus,
                                    enabled: !_busy,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [
                                      AutofillHints.email,
                                      AutofillHints.telephoneNumber,
                                    ],
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
                                    decoration: const InputDecoration(
                                      filled: false,
                                      fillColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      disabledBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 4.0,
                                      ),
                                    ),
                                    onSubmitted: (_) => _submit(),
                                  ),
                                )
                              else
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: TextField(
                                    key: const Key('auth-password'),
                                    controller: _password,
                                    focusNode: _passwordFocus,
                                    enabled: !_busy,
                                    obscureText: true,
                                    obscuringCharacter: '•',
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    textAlign: TextAlign.center,
                                    textDirection: TextDirection.ltr,
                                    cursorColor: ink,
                                    cursorWidth: 2.5,
                                    cursorHeight: 30.0,
                                    style: TextStyle(
                                      color: ink,
                                      fontSize: 28.0,
                                      fontWeight: FontWeight.w700,
                                      height: 36.0 / 28.0,
                                      letterSpacing: 1.0,
                                    ),
                                    decoration: const InputDecoration(
                                      filled: false,
                                      fillColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      disabledBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 2.0,
                                      ),
                                    ),
                                    onSubmitted: (_) => _submit(),
                                  ),
                                ),

                              if (_error != null) ...[
                                const SizedBox(height: 18.0),
                                Text(
                                  _error!,
                                  key: const Key('dl-login-error-text'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: errorRed,
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w400,
                                    height: 18.0 / 13.0,
                                  ),
                                ),
                              ],

                              if (!isStep1) ...[
                                SizedBox(height: _error != null ? 20.0 : 32.0),
                                Material(
                                  color: pillBg,
                                  shape: const StadiumBorder(),
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    key: const Key('auth-forgot-password-pill'),
                                    customBorder: const StadiumBorder(),
                                    onTap: _busy
                                        ? null
                                        : () {
                                            HapticFeedback.lightImpact();
                                            Navigator.of(context).push(
                                              MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    ForgotPasswordScreen(
                                                  initialEmail:
                                                      _email.text.trim(),
                                                  auth: _auth,
                                                ),
                                              ),
                                            );
                                          },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18.0,
                                        vertical: 10.0,
                                      ),
                                      child: Text(
                                        s.tr(
                                          'نسيت كلمة المرور؟',
                                          'Mot de passe oublié ?',
                                          'Forgot password?',
                                        ),
                                        style: TextStyle(
                                          color: ink,
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.w600,
                                          height: 20.0 / 14.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
                key: const Key('dl-login-button-dock'),
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
                          key: const Key('auth-submit'),
                          customBorder: const StadiumBorder(),
                          onTap: _busy ? null : _submit,
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

  Widget _buildBackButton({
    bool isOtp = false,
    bool isDark = false,
    bool isAr = true,
  }) {
    final bool isRootLogin = _login && !isOtp;
    final Color softFill =
        isDark ? const Color(0xFF262629) : const Color(0xFFF3F4F6);
    final Color ink =
        isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);

    return GestureDetector(
      key: const Key('auth-dismiss'),
      onTap: () {
        HapticFeedback.lightImpact();
        if (_pending != null || isOtp) {
          _reset();
          return;
        }
        if (!_login && _registerStep > 1) {
          _prevRegisterStep();
          return;
        }
        final nav = Navigator.of(context);
        if (nav.canPop()) {
          nav.pop();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        button: true,
        label: isRootLogin
            ? _state.s.tr('إغلاق', 'Fermer', 'Close')
            : _state.s.tr('رجوع', 'Retour', 'Back'),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isOtp ? Colors.transparent : softFill,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                isRootLogin
                    ? CupertinoIcons.xmark
                    : (isAr
                        ? CupertinoIcons.chevron_right
                        : CupertinoIcons.chevron_left),
                size: isRootLogin ? 18 : 19,
                color: isOtp
                    ? (isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280))
                    : ink,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionCard({
    required bool selected,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 52,
        decoration: BoxDecoration(
          color: selected
              ? AppConfig.primary.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppConfig.primary : const Color(0xFFE5E7EB),
            width: selected ? 1.8 : 1.2,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? AppConfig.primary : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppConfig.primary : const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required Key key,
    required Widget icon,
    required String text,
    required Color surfaceColor,
    required Color textColor,
    required Color borderColor,
    required VoidCallback onPressed,
  }) {
    return _TapPressScale(
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          key: key,
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: surfaceColor,
            foregroundColor: textColor,
            side: BorderSide(color: borderColor, width: 1.0),
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
                  style: TextStyle(
                    fontSize: 15,
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
      ),
    );
  }
}

class _TapPressScale extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const _TapPressScale({
    required this.child,
    this.enabled = true,
  });

  @override
  State<_TapPressScale> createState() => _TapPressScaleState();
}

class _TapPressScaleState extends State<_TapPressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Listener(
      onPointerDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onPointerUp: (_) {
        if (_pressed) setState(() => _pressed = false);
      },
      onPointerCancel: (_) {
        if (_pressed) setState(() => _pressed = false);
      },
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1.0,
        duration: disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Vector-painted official Google "G" logo (transparent center works in light & dark modes)
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
    final double r = size.width * 0.40;
    final double strokeWidth = size.width * 0.19;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final Rect arcRect = Rect.fromCircle(center: center, radius: r);

    final Paint base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Red top arc
    canvas.drawArc(
      arcRect,
      -2.55,
      1.95,
      false,
      base..color = const Color(0xFFEA4335),
    );
    // Yellow left arc
    canvas.drawArc(
      arcRect,
      2.45,
      1.28,
      false,
      base..color = const Color(0xFFFBBC05),
    );
    // Green bottom arc
    canvas.drawArc(
      arcRect,
      0.55,
      1.92,
      false,
      base..color = const Color(0xFF34A853),
    );
    // Blue right arc
    canvas.drawArc(
      arcRect,
      -0.12,
      0.70,
      false,
      base..color = const Color(0xFF4285F4),
    );
    // Horizontal bar for G
    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(center.dx + r + strokeWidth * 0.45, center.dy),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DobDateInputFormatter extends TextInputFormatter {
  const _DobDateInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final normalized = AccountValidation.normalizeDigits(newValue.text);
    final digits = normalized.replaceAll(RegExp(r'[^0-9]'), '');
    final capped = digits.length > 8 ? digits.substring(0, 8) : digits;
    final isDeleting = newValue.text.length < oldValue.text.length;

    final buffer = StringBuffer();
    for (int i = 0; i < capped.length; i++) {
      if (i == 4 || i == 6) {
        buffer.write('-');
      }
      buffer.write(capped[i]);
    }
    if (!isDeleting &&
        newValue.text.endsWith('-') &&
        (capped.length == 4 || capped.length == 6)) {
      buffer.write('-');
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
