import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../account/account_helpers.dart';
import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import '../theme/app_typography.dart';
import '../widgets/custom_auth_input_field.dart';
import '../widgets/interests_survey_sheet.dart';
import 'forgot_password_screen.dart';
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
  final FocusNode _codeFocus = FocusNode();

  // Multi-step Registration controllers & states
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _dob = TextEditingController();
  final _phone = TextEditingController();

  String _gender = 'male'; // 'male' or 'female'
  int _cityId = 1;
  String _cityName = 'الدار البيضاء';
  String _accountType = 'individual'; // 'individual' (Buyer) or 'pro' (Seller)
  int _registerStep = 1; // 1 to 4

  List<Map<String, dynamic>> _cities = [];

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

  static const List<Map<String, dynamic>> _fallbackCities = [
    {'id': 1, 'name_ar': 'الدار البيضاء', 'name_fr': 'Casablanca'},
    {'id': 2, 'name_ar': 'الرباط', 'name_fr': 'Rabat'},
    {'id': 3, 'name_ar': 'مراكش', 'name_fr': 'Marrakech'},
    {'id': 4, 'name_ar': 'طنجة', 'name_fr': 'Tanger'},
    {'id': 5, 'name_ar': 'فاس', 'name_fr': 'Fès'},
    {'id': 6, 'name_ar': 'أكادير', 'name_fr': 'Agadir'},
    {'id': 7, 'name_ar': 'مكناس', 'name_fr': 'Meknès'},
    {'id': 8, 'name_ar': 'وجدة', 'name_fr': 'Oujda'},
    {'id': 9, 'name_ar': 'القنيطرة', 'name_fr': 'Kénitra'},
    {'id': 10, 'name_ar': 'تطوان', 'name_fr': 'Tétouan'},
    {'id': 11, 'name_ar': 'العيون', 'name_fr': 'Laâyoune'},
    {'id': 12, 'name_ar': 'الداخلة', 'name_fr': 'Dakhla'},
  ];

  @override
  void initState() {
    super.initState();
    _login = widget.initialRegisterMode ? false : widget.initialIsLogin;
    _auth = widget.auth ?? AccountAuth(locale: _state.locale.languageCode);
    _cities = _fallbackCities;
    _cityId = 1;
    _cityName = _cityLabel(_cities.first);
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _codeFocus.addListener(() {
      if (mounted) setState(() {});
    });

    if (!_login) {
      _loadCities();
    }

    if (widget.autoTriggerGoogle) {
      _notice = _state.s.tr(
        'الدخول عبر Google غير متاح داخل التطبيق حالياً. استخدم بريدك وكلمة المرور أو الموقع.',
        'Google sign-in is currently unavailable in-app. Please use email and password or the website.',
      );
    }
  }

  Future<void> _loadCities() async {
    try {
      final taxonomy = await _auth.taxonomy();
      if (!mounted) return;
      final raw = taxonomy['cities'];
      if (raw is List && raw.isNotEmpty) {
        final parsed = raw
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .where((item) => (int.tryParse('${item['id']}') ?? 0) > 0)
            .toList();
        if (parsed.isNotEmpty) {
          setState(() {
            _cities = parsed;
            _cityId = int.tryParse('${_cities.first['id']}') ?? 1;
            _cityName = _cityLabel(_cities.first);
          });
          return;
        }
      }
    } catch (_) {
      // Fallback
    }
    if (mounted) {
      setState(() {
        _cities = _fallbackCities;
        _cityId = 1;
        _cityName = _cityLabel(_cities.first);
      });
    }
  }

  String _cityLabel(Map<String, dynamic> city) {
    return (city[_state.s.isAr ? 'name_ar' : 'name_fr'] ?? city['name'] ?? '')
        .toString();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoSubmitTimer?.cancel();
    _shakeCtrl.dispose();
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

  Future<void> _pickDateOfBirth() async {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 12, now.month, now.day),
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

  void _showCityPicker() {
    HapticFeedback.lightImpact();
    final s = _state.s;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  s.tr('اختر مدينتك', 'Choisissez votre ville',
                      'Select your city'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  itemCount: _cities.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _cities[index];
                    final id = int.tryParse('${item['id']}') ?? 1;
                    final name = _cityLabel(item);
                    final isSelected = id == _cityId;

                    return ListTile(
                      title: Text(
                        name,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppConfig.primary
                              : const Color(0xFF111827),
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppConfig.primary,
                            )
                          : null,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _cityId = id;
                          _cityName = name;
                        });
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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
      if (_dob.text.isEmpty) {
        setState(() => _error = _state.s.tr(
              'يرجى تحديد تاريخ الازدياد',
              'Please select your date of birth',
            ));
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
    } else if (!_form.currentState!.validate()) {
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
        final rawPhone = _phone.text.trim();
        final phone = rawPhone.isNotEmpty ? rawPhone : '0612345678';

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

      // Show interests survey modal popup if newly registered
      if (isFromRegistration && navigator.context.mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          InterestsSurveySheet.show(
            navigator.context,
            auth: _auth,
            session: result,
            accountType: _accountType,
            cityId: _cityId,
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
                        child: _buildBackButton(isOtp: otp),
                      ),
                      if (!otp)
                        Text(
                          _login
                              ? s.tr('تسجيل الدخول', 'Sign in')
                              : s.tr('إنشاء حساب', 'Sign up'),
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
                                    ? s.tr('التفاصيل والموقع', 'Details & Role')
                                    : _registerStep == 3
                                        ? s.tr('بيانات الدخول', 'Credentials')
                                        : s.tr('التحقق', 'Verification'),
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF6B7280),
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
                                    : const Color(0xFFE5E7EB),
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

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  physics: const BouncingScrollPhysics(),
                  child: Form(
                    key: _form,
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
                                  ? s.tr('مرحباً بك مجدداً', 'Welcome back')
                                  : _registerStep == 1
                                      ? s.tr('لنبدأ باسمك',
                                          'Let\'s start with your name')
                                      : _registerStep == 2
                                          ? s.tr('أخبرنا عنك',
                                              'Tell us about yourself')
                                          : s.tr('حسابك وأمانك',
                                              'Account & Security'),
                          style: TextStyle(
                            fontSize: otp ? 26 : 27,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0A0B0D),
                            letterSpacing:
                                AppTypography.trackingForContext(context, -0.5),
                            height: 1.2,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Builder(
                          builder: (_) {
                            final maskedEmail = AccountValidation.maskEmail(
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
                                        'Enter your email or phone number to continue',
                                      )
                                    : _registerStep == 1
                                        ? s.tr(
                                            'أدخل اسمك الشخصي والعائلي وحدد الجنس',
                                            'Enter your name and select your gender',
                                          )
                                        : _registerStep == 2
                                            ? s.tr(
                                                'حدد تاريخ ميلادك ومدينتك وكيف ستستخدم أبولو',
                                                'Set your birth date, city, and role',
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
                                    ? const Color(0xFF5B616E)
                                    : const Color(0xFF6B7280),
                                height: 1.4,
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
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFCA5A5),
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
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFFB91C1C),
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
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Color(0xFF475569),
                                  size: 19,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _notice!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF334155),
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
                              final isEmail = AccountValidation.email(text);
                              final isPhone =
                                  AccountValidation.phone(text) != null;
                              if (!isEmail && !isPhone) {
                                return s.tr(
                                  'أدخل بريداً صحيحاً أو رقماً يبدأ بـ 05/06/07/212+',
                                  'Enter a valid email or phone (05/06/07/+212)',
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

                          const SizedBox(height: 2),

                          // Forgot password link
                          Align(
                            alignment: AlignmentDirectional.centerStart,
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
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  s.tr(
                                    'نسيت كلمة المرور؟',
                                    'Forgot your password?',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppConfig.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Primary Sign In Button
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              key: const Key('auth-submit'),
                              onPressed: _busy ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0A0A0A),
                                foregroundColor: Colors.white,
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
                                      s.tr('تسجيل الدخول', 'Se connecter',
                                          'Sign in'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),

                          // "or" Divider
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    s.tr('أو', 'or'),
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF9CA3AF),
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

                          // Social Login Buttons
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
                                  'الدخول عبر Google غير متاح حالياً داخل التطبيق. استخدم البريد أو الهاتف.',
                                  'Google sign-in is not available yet. Please use email or phone.',
                                );
                              });
                            },
                          ),

                          const SizedBox(height: 12),

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
                                  'الدخول عبر Apple غير متاح حالياً داخل التطبيق.',
                                  'Apple sign-in is not available yet.',
                                );
                              });
                            },
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
                                backgroundColor: const Color(0xFF0A0A0A),
                                foregroundColor: Colors.white,
                                shape: const StadiumBorder(),
                                elevation: 0,
                              ),
                              child: Text(
                                s.tr('متابعة', 'Continuer', 'Continue'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],

                        // ============================================
                        // MODE 2: REGISTER STEP 2 (DOB, CITY, BUYER/SELLER)
                        // ============================================
                        if (!_login && _registerStep == 2) ...[
                          CustomAuthInputField(
                            controller: _dob,
                            label: s.tr('تاريخ الازدياد', 'Date of birth'),
                            keyName: 'reg-dob',
                            hint: 'YYYY-MM-DD',
                            onTap: _pickDateOfBirth,
                            validator: (v) => (v ?? '').isNotEmpty
                                ? null
                                : s.tr('حدد تاريخ الازدياد', 'Select date'),
                          ),

                          // City Selector
                          GestureDetector(
                            onTap: _showCityPicker,
                            child: Container(
                              height: 54,
                              margin: const EdgeInsets.only(bottom: 14),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        s.tr('المدينة', 'City'),
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _cityName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Color(0xFF6B7280),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            s.tr(
                              'كيف ستستخدم Apolo؟',
                              'How will you use Apolo?',
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4B5563),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Buyer Card
                          _buildRoleCard(
                            selected: _accountType == 'individual',
                            icon: Icons.shopping_bag_outlined,
                            title: s.tr('مشتري', 'Buyer'),
                            subtitle: s.tr(
                              'أرغب في الشراء والبحث عن أفضل العروض والمنتجات',
                              'Browse and buy products at the best prices',
                            ),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _accountType = 'individual');
                            },
                          ),

                          const SizedBox(height: 10),

                          // Seller Card
                          _buildRoleCard(
                            selected: _accountType == 'pro',
                            icon: Icons.storefront_outlined,
                            title: s.tr('بائع', 'Seller'),
                            subtitle: s.tr(
                              'أرغب في عرض وبيع منتجاتي والتواصل مع الزبناء',
                              'List and sell products to customers',
                            ),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _accountType = 'pro');
                            },
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
                                      foregroundColor: const Color(0xFF111827),
                                      side: const BorderSide(
                                        color: Color(0xFFE5E7EB),
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
                                      backgroundColor: const Color(0xFF0A0A0A),
                                      foregroundColor: Colors.white,
                                      shape: const StadiumBorder(),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      s.tr('متابعة', 'Continuer', 'Continue'),
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
                        // MODE 2: REGISTER STEP 3 (EMAIL & PASSWORD)
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
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: SizedBox(
                                  height: 54,
                                  child: OutlinedButton(
                                    onPressed: _busy ? null : _prevRegisterStep,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF111827),
                                      side: const BorderSide(
                                        color: Color(0xFFE5E7EB),
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
                                      backgroundColor: const Color(0xFF0A0A0A),
                                      foregroundColor: Colors.white,
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

                        const SizedBox(height: 28),

                        // Toggle between Sign in & Sign up
                        if (!otp)
                          Center(
                            child: GestureDetector(
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
                                        if (!_login) _loadCities();
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
                                          color: AppConfig.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Support link
                        if (!otp)
                          Center(
                            child: TextButton(
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
                                s.tr('المساعدة والدعم', 'Need help?'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 20),
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

  Widget _buildBackButton({bool isOtp = false}) {
    return GestureDetector(
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
      child: isOtp
          ? const SizedBox(
              width: 40,
              height: 40,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: Color(0xFF6B7280),
                ),
              ),
            )
          : Container(
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

  Widget _buildRoleCard({
    required bool selected,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppConfig.primary.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppConfig.primary : const Color(0xFFE5E7EB),
            width: selected ? 1.8 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? AppConfig.primary.withValues(alpha: 0.12)
                    : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 22,
                  color: selected ? AppConfig.primary : const Color(0xFF4B5563),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppConfig.primary
                          : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF6B7280),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppConfig.primary : const Color(0xFFD1D5DB),
              size: 22,
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
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF111827),
                  letterSpacing:
                      AppTypography.trackingForContext(context, -0.2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
