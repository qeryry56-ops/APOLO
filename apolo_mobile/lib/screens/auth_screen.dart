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
import '../theme/dl_share_profile_tokens.dart';
import '../widgets/dl_settings_kit.dart';
import 'account_setup_screen.dart';
import 'add_friends_screen.dart';
import 'business_switch_screen.dart';
import 'forgot_password_screen.dart';

enum _OtpPhase {
  idle,
  sendingInitial,
  verifying,
  resending,
  verified,
  error,
}

/// Dynamic Layer v5.1 APOLO Authentication, Sign-Up & OTP Verification Screen.
///
/// - **Log in** (`_login == true`, 2 steps — Figma `45786:56733`, `45786:57262`, `21414:22440`):
///   1. `Enter your email` (`example@gmail.com`)
///   2. `Enter your password` (`Password`) + `Forgot password?` `#EEEEEE` pill
/// - **Sign up** (`_login == false`, 5 steps — Figma `25680:46408` + required `+212` phone):
///   1. `What's your email?` (`example@gmail.com`)
///   2. `Choose a password` (`Password` + `Your password must be at least 8 characters`)
///   3. `What's your first name?` (`Name`)
///   4. `Pick a username` (`@username` + `Others can find you with your username!`)
///   5. `What's your phone number?` (`+212` primary prefix + `650-123456` placeholder)
/// - **OTP Verification** (`_pending != null`): Dynamic Layer v5.1 centered `28px Bold`
///   6-digit input (`000000` hint) + `#EEEEEE` `Resend code` pill + `56px` `Continue` `ButtonDock`.
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

  // Shared & step controllers
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _firstName = TextEditingController();
  final _username = TextEditingController();
  final _phone = TextEditingController();
  final _code = TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _firstNameFocus = FocusNode();
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _codeFocus = FocusNode();

  // Step states
  int _loginStep = 1; // 1..2
  int _registerStep = 1; // 1..5 (6 when OTP pending)
  bool _switchedFromLogin = false;

  final int _cityId = 1;
  final String _accountType = 'individual';

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

  String get _cleanUsername =>
      _username.text.trim().replaceFirst(RegExp(r'^@+'), '');

  String get _phoneSubscriberDigits =>
      AccountValidation.normalizeDigits(_phone.text)
          .replaceAll(RegExp(r'[^0-9]'), '');

  String get _fullSignUpPhone {
    final digits = _phoneSubscriberDigits;
    if (digits.isEmpty) return '';
    return '+212$digits';
  }

  @override
  void initState() {
    super.initState();
    _login = widget.initialRegisterMode ? false : widget.initialIsLogin;
    _auth = widget.auth ?? AccountAuth(locale: _state.locale.languageCode);
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    for (final c in [_email, _password, _firstName, _username, _phone]) {
      c.addListener(_onStepInputChanged);
    }
    for (final f in [
      _emailFocus,
      _passwordFocus,
      _firstNameFocus,
      _usernameFocus,
      _phoneFocus,
    ]) {
      f.addListener(_onStepInputChanged);
    }
    _codeFocus.addListener(() {
      if (mounted) setState(() {});
    });

    if (widget.autoTriggerGoogle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _launchGoogleSignIn();
      });
    }
  }

  void _onStepInputChanged() {
    if (mounted) {
      setState(() {
        if (_pending == null && _error != null) {
          _error = null;
        }
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
            'Unable to open Google sign-in right now.',
          );
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _notice = _state.s.tr(
            'تعذر بدء تسجيل الدخول عبر Google حالياً.',
            'Impossible de démarrer la connexion Google.',
            'Unable to start Google sign-in.',
          );
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoSubmitTimer?.cancel();
    _shakeCtrl.dispose();
    for (final c in [_email, _password, _firstName, _username, _phone]) {
      c.removeListener(_onStepInputChanged);
    }
    for (final f in [
      _emailFocus,
      _passwordFocus,
      _firstNameFocus,
      _usernameFocus,
      _phoneFocus,
    ]) {
      f.removeListener(_onStepInputChanged);
      f.dispose();
    }
    _codeFocus.dispose();
    _auth.close();
    for (final controller in [
      _email,
      _password,
      _firstName,
      _username,
      _phone,
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

  void _focusRegisterStep(int step) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (step) {
        case 1:
          _emailFocus.requestFocus();
          break;
        case 2:
          _passwordFocus.requestFocus();
          break;
        case 3:
          _firstNameFocus.requestFocus();
          break;
        case 4:
          _usernameFocus.requestFocus();
          break;
        case 5:
          _phoneFocus.requestFocus();
          break;
      }
    });
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

  /// Validates and advances Sign-Up Steps 1..4; returns `true` only on Step 5
  /// when all inputs are valid and ready for `/auth/register`.
  bool _validateOrAdvanceSignUpStep() {
    final s = _state.s;
    switch (_registerStep) {
      case 1:
        final email = _email.text.trim();
        if (email.isEmpty) {
          _emailFocus.requestFocus();
          return false;
        }
        if (!AccountValidation.email(email)) {
          HapticFeedback.heavyImpact();
          setState(() {
            _error = s.tr(
              'يرجى إدخال بريد إلكتروني صحيح',
              'Veuillez saisir une adresse e-mail valide',
              'Please enter a valid email address',
            );
          });
          return false;
        }
        HapticFeedback.selectionClick();
        setState(() {
          _error = null;
          _registerStep = 2;
        });
        _focusRegisterStep(2);
        return false;

      case 2:
        final pwd = _password.text;
        if (pwd.isEmpty) {
          _passwordFocus.requestFocus();
          return false;
        }
        if (!AccountValidation.password(pwd)) {
          HapticFeedback.heavyImpact();
          setState(() {
            _error = s.tr(
              'يجب أن تتكون كلمة المرور من 8 أحرف على الأقل',
              'Votre mot de passe doit contenir au moins 8 caractères',
              'Your password must be at least 8 characters',
            );
          });
          return false;
        }
        HapticFeedback.selectionClick();
        setState(() {
          _error = null;
          _registerStep = 3;
        });
        _focusRegisterStep(3);
        return false;

      case 3:
        final first = _firstName.text.trim();
        if (first.isEmpty) {
          _firstNameFocus.requestFocus();
          return false;
        }
        if (first.length < 2) {
          HapticFeedback.heavyImpact();
          setState(() {
            _error = s.tr(
              'يرجى إدخال الاسم (حرفين على الأقل)',
              'Veuillez saisir votre nom (au moins 2 caractères)',
              'Please enter your name (at least 2 characters)',
            );
          });
          return false;
        }
        HapticFeedback.selectionClick();
        setState(() {
          _error = null;
          _registerStep = 4;
        });
        _focusRegisterStep(4);
        return false;

      case 4:
        final handle = _cleanUsername;
        if (handle.isEmpty) {
          _usernameFocus.requestFocus();
          return false;
        }
        if (!RegExp(r'^[a-zA-Z0-9._]{3,24}$').hasMatch(handle)) {
          HapticFeedback.heavyImpact();
          setState(() {
            _error = s.tr(
              'يجب أن يتكون اسم المستخدم من 3 أحرف أو أرقام على الأقل',
              'Le nom d’utilisateur doit contenir au moins 3 lettres ou chiffres',
              'Username must be at least 3 letters or numbers',
            );
          });
          return false;
        }
        HapticFeedback.selectionClick();
        setState(() {
          _error = null;
          _registerStep = 5;
        });
        _focusRegisterStep(5);
        return false;

      case 5:
        final fullPhone = _fullSignUpPhone;
        if (fullPhone.isEmpty) {
          _phoneFocus.requestFocus();
          return false;
        }
        if (AccountValidation.phone(fullPhone) == null) {
          HapticFeedback.heavyImpact();
          setState(() {
            _error = s.tr(
              'يرجى إدخال رقم هاتف مغربي صالح (مثال: 650-123456)',
              'Veuillez saisir un numéro marocain valide (ex : 650-123456)',
              'Please enter a valid Moroccan phone number (e.g. 650-123456)',
            );
          });
          return false;
        }
        return true;

      default:
        return false;
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
    } else {
      if (!_validateOrAdvanceSignUpStep()) {
        return;
      }
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
        result = await _auth.verify(_pending!, _code.text);
      } else if (_login) {
        result = await _auth.login(_email.text, _password.text);
      } else {
        final firstName = _firstName.text.trim();
        result = await _auth.register(
          name: firstName.isNotEmpty ? firstName : 'User',
          email: _email.text.trim(),
          phone: _fullSignUpPhone,
          password: _password.text,
          confirmation: _password.text,
          username: _cleanUsername,
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
          if (!_login) _registerStep = 6;
        });
        _password.clear();
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

      // Show Dynamic Layer v5.1 Account Setup (`21825:25569`) -> Add Friends (`33215:34358`) if newly registered
      if (isFromRegistration && navigator.context.mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!navigator.context.mounted) return;
          Navigator.of(navigator.context).push(
            MaterialPageRoute<void>(
              builder: (_) => AccountSetupScreen(
                auth: _auth,
                session: result,
                cityId: _cityId,
                nextBuilder: (ctx, chosenTypes) => AddFriendsScreen(
                  onContinue: () {
                    if (chosenTypes.contains('business') &&
                        !_state.isBusinessAccount) {
                      Navigator.of(ctx).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              const BusinessSwitchScreen(isEditing: false),
                        ),
                      );
                    } else {
                      Navigator.of(ctx).maybePop();
                    }
                  },
                ),
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
                'تم إرسال رمز جديد إلى $masked.',
                'Un nouveau code a été envoyé à $masked.',
                'A new verification code was sent to $masked.',
              )
            : _state.s.tr(
                'تم إرسال رمز جديد إلى بريدك الإلكتروني.',
                'Un nouveau code a été envoyé à votre boîte e-mail.',
                'A new verification code was sent to your email.',
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

  void _resetOtp() {
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
      if (!_login) _registerStep = 5;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final isAr = s.isAr;
    final otp = _pending != null || (!_login && _registerStep == 6);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF121212) : Colors.white;

    if (_login && !otp) {
      return _buildDynamicLayerLoginScaffold(
        context,
        s: s,
        isAr: isAr,
        isDark: isDark,
        bgColor: bgColor,
      );
    }

    if (!_login && !otp) {
      return _buildDynamicLayerSignUpScaffold(
        context,
        s: s,
        isAr: isAr,
        isDark: isDark,
        bgColor: bgColor,
      );
    }

    return _buildDynamicLayerOtpScaffold(
      context,
      s: s,
      isAr: isAr,
      isDark: isDark,
      bgColor: bgColor,
    );
  }

  /// Exact Figma `dynamic-layer-core-v5.1` `Log in` 2-step screen (`45786:56733`, `45786:57262`, `21414:22440`).
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
    final Color placeholderColor =
        isDark ? const Color(0xFF52525B) : const Color(0xFFC7C7CC);
    const Color errorRed = Color(0xFFE31B23);

    final bool isStep1 = _loginStep == 1;
    final bool isFilled =
        isStep1 ? _email.text.trim().isNotEmpty : _password.text.isNotEmpty;
    final Color continueBg =
        isFilled ? (isDark ? Colors.white : const Color(0xFF000000)) : pillBg;
    final Color continueFg = isFilled
        ? (isDark ? const Color(0xFF000000) : Colors.white)
        : disabledText;

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
                          if (isStep1)
                            Material(
                              color: pillBg,
                              shape: const StadiumBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                key: const Key('auth-switch-to-signup'),
                                customBorder: const StadiumBorder(),
                                onTap: _busy
                                    ? null
                                    : () {
                                        HapticFeedback.selectionClick();
                                        setState(() {
                                          _login = false;
                                          _registerStep = 1;
                                          _switchedFromLogin = true;
                                          _error = null;
                                          _notice = null;
                                          _password.clear();
                                        });
                                        _focusRegisterStep(1);
                                      },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14.0,
                                    vertical: 8.0,
                                  ),
                                  child: Text(
                                    s.tr('إنشاء حساب', 'S’inscrire', 'Sign up'),
                                    style: TextStyle(
                                      color: ink,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      height: 20.0 / 13.5,
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
                                    decoration: InputDecoration(
                                      hintText: 'example@gmail.com',
                                      hintStyle: TextStyle(
                                        color: placeholderColor,
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
                                      contentPadding:
                                          const EdgeInsets.symmetric(
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
                                    decoration: InputDecoration(
                                      hintText: 'Password',
                                      hintStyle: TextStyle(
                                        color: placeholderColor,
                                        fontSize: 28.0,
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
                                      contentPadding:
                                          const EdgeInsets.symmetric(
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
                                  style: const TextStyle(
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

  /// Exact Figma `dynamic-layer-core-v5.1` `Sign up` flow (`25680:46408`):
  /// 1. `What's your email?` (`example@gmail.com`)
  /// 2. `Choose a password` (`Password`)
  /// 3. `What's your first name?` (`Name`)
  /// 4. `Pick a username` (`@username`)
  /// 5. `What's your phone number?` (`+212` primary prefix + `650-123456`)
  Widget _buildDynamicLayerSignUpScaffold(
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
    final Color mutedText =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF757575);
    final Color placeholderColor =
        isDark ? const Color(0xFF52525B) : const Color(0xFFC7C7CC);
    const Color errorRed = Color(0xFFE31B23);

    final bool isFilled;
    final String promptLabel;
    final String? helperText;

    switch (_registerStep) {
      case 1:
        isFilled = _email.text.trim().isNotEmpty;
        promptLabel = s.tr(
          'ما هو بريدك الإلكتروني؟',
          'Quelle est votre adresse e-mail ?',
          "What's your email?",
        );
        helperText = null;
        break;
      case 2:
        isFilled = _password.text.isNotEmpty;
        promptLabel = s.tr(
          'اختر كلمة المرور',
          'Choisissez un mot de passe',
          'Choose a password',
        );
        helperText = s.tr(
          'يجب أن تتكون كلمة المرور من 8 أحرف على الأقل',
          'Votre mot de passe doit contenir au moins 8 caractères',
          'Your password must be at least 8 characters',
        );
        break;
      case 3:
        isFilled = _firstName.text.trim().isNotEmpty;
        promptLabel = s.tr(
          'ما هو اسمك الشخصي؟',
          'Quel est votre prénom ?',
          "What's your first name?",
        );
        helperText = null;
        break;
      case 4:
        isFilled = _cleanUsername.isNotEmpty;
        promptLabel = s.tr(
          'اختر اسم مستخدم',
          'Choisissez un nom d’utilisateur',
          'Pick a username',
        );
        helperText = s.tr(
          'يمكن للآخرين العثور عليك باسم المستخدم الخاص بك!',
          'Les autres peuvent vous trouver grâce à votre nom d’utilisateur !',
          'Others can find you with your username!',
        );
        break;
      case 5:
      default:
        isFilled = _phoneSubscriberDigits.isNotEmpty;
        promptLabel = s.tr(
          'ما هو رقم هاتفك؟',
          'Quel est votre numéro de téléphone ?',
          "What's your phone number?",
        );
        helperText = s.tr(
          'أدخل رقم هاتف مغربي صالح لتأكيد حسابك',
          'Entrez un numéro marocain valide pour sécuriser votre compte',
          'Enter a valid Moroccan phone number to secure your account',
        );
        break;
    }

    final Color continueBg =
        isFilled ? (isDark ? Colors.white : const Color(0xFF000000)) : pillBg;
    final Color continueFg = isFilled
        ? (isDark ? const Color(0xFF000000) : Colors.white)
        : mutedText;

    final int emailLen = _email.text.length;
    final double emailFontSize =
        emailLen > 28 ? 19.0 : (emailLen > 20 ? 23.0 : 28.0);

    final backIcon =
        isAr ? CupertinoIcons.chevron_right : CupertinoIcons.chevron_left;

    final bool canPopRoute = _registerStep == 1 && !_switchedFromLogin;

    void handleSignUpBack() {
      HapticFeedback.lightImpact();
      if (_busy) return;
      if (_registerStep > 1) {
        final prev = _registerStep - 1;
        setState(() {
          _registerStep = prev;
          _error = null;
        });
        _focusRegisterStep(prev);
        return;
      }
      if (_switchedFromLogin) {
        setState(() {
          _login = true;
          _loginStep = 1;
          _switchedFromLogin = false;
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

    InputDecoration buildCleanInputDecoration({
      required String hintText,
      double fontSize = 28.0,
      double letterSpacing = -0.4,
    }) {
      return InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: placeholderColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          height: 36.0 / 28.0,
          letterSpacing: letterSpacing,
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
        contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
      );
    }

    Widget stepInput;
    switch (_registerStep) {
      case 1:
        stepInput = Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            key: const Key('auth-email'),
            controller: _email,
            focusNode: _emailFocus,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            cursorColor: ink,
            cursorWidth: 2.5,
            cursorHeight: 30.0,
            style: TextStyle(
              color: ink,
              fontSize: emailFontSize,
              fontWeight: FontWeight.w700,
              height: 36.0 / 28.0,
              letterSpacing: -0.4,
            ),
            decoration: buildCleanInputDecoration(
              hintText: 'example@gmail.com',
              fontSize: emailFontSize,
            ),
            onSubmitted: (_) => _submit(),
          ),
        );
        break;
      case 2:
        stepInput = Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            key: const Key('auth-password'),
            controller: _password,
            focusNode: _passwordFocus,
            enabled: !_busy,
            obscureText: true,
            obscuringCharacter: '•',
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
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
            decoration: buildCleanInputDecoration(
              hintText: 'Password',
              letterSpacing: -0.4,
            ),
            onSubmitted: (_) => _submit(),
          ),
        );
        break;
      case 3:
        stepInput = TextField(
          key: const Key('reg-first-name'),
          controller: _firstName,
          focusNode: _firstNameFocus,
          enabled: !_busy,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          textAlign: TextAlign.center,
          cursorColor: ink,
          cursorWidth: 2.5,
          cursorHeight: 30.0,
          style: TextStyle(
            color: ink,
            fontSize: 28.0,
            fontWeight: FontWeight.w700,
            height: 36.0 / 28.0,
            letterSpacing: -0.4,
          ),
          decoration: buildCleanInputDecoration(
            hintText: 'Name',
          ),
          onSubmitted: (_) => _submit(),
        );
        break;
      case 4:
        stepInput = Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            key: const Key('reg-username'),
            controller: _username,
            focusNode: _usernameFocus,
            enabled: !_busy,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
            inputFormatters: const [_UsernameHandleInputFormatter()],
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
              letterSpacing: -0.4,
            ),
            decoration: buildCleanInputDecoration(
              hintText: '@username',
            ),
            onSubmitted: (_) => _submit(),
          ),
        );
        break;
      case 5:
      default:
        stepInput = Directionality(
          textDirection: TextDirection.ltr,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (!_busy) _phoneFocus.requestFocus();
            },
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '+212',
                    key: const Key('reg-phone-prefix'),
                    style: TextStyle(
                      color: ink,
                      fontSize: 26.0,
                      fontWeight: FontWeight.w700,
                      height: 36.0 / 26.0,
                      letterSpacing: -0.3,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  SizedBox(
                    width: 158.0,
                    child: AutofillGroup(
                      child: TextField(
                        key: const Key('auth-phone'),
                        controller: _phone,
                        focusNode: _phoneFocus,
                        enabled: !_busy,
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: false,
                          decimal: false,
                        ),
                        textInputAction: TextInputAction.done,
                        autofillHints: const [
                          AutofillHints.telephoneNumberNational,
                          AutofillHints.telephoneNumber,
                        ],
                        inputFormatters: const [
                          _MoroccanSubscriberPhoneFormatter(),
                        ],
                        textAlign: TextAlign.left,
                        textDirection: TextDirection.ltr,
                        cursorColor: ink,
                        cursorWidth: 2.5,
                        cursorHeight: 28.0,
                        style: TextStyle(
                          color: ink,
                          fontSize: 26.0,
                          fontWeight: FontWeight.w700,
                          height: 36.0 / 26.0,
                          letterSpacing: -0.3,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        decoration: InputDecoration(
                          hintText: '650-123456',
                          hintStyle: TextStyle(
                            color: placeholderColor,
                            fontSize: 26.0,
                            fontWeight: FontWeight.w700,
                            height: 36.0 / 26.0,
                            letterSpacing: -0.3,
                            fontFeatures: const [FontFeature.tabularFigures()],
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
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 4.0),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        break;
    }

    return PopScope(
      canPop: canPopRoute,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) handleSignUpBack();
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
                key: const Key('dl-signup-top-nav'),
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
                            onPressed: handleSignUpBack,
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
                          key: const Key('dl-signup-wrapper'),
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
                                promptLabel,
                                key: const Key('dl-signup-prompt-label'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: ink,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w700,
                                  height: 24.0 / 16.0,
                                ),
                              ),
                              const SizedBox(height: 32.0),

                              stepInput,

                              if (_error != null) ...[
                                const SizedBox(height: 18.0),
                                Text(
                                  _error!,
                                  key: const Key('dl-signup-error-text'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: errorRed,
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w400,
                                    height: 18.0 / 13.0,
                                  ),
                                ),
                              ],

                              if (helperText != null) ...[
                                SizedBox(height: _error != null ? 20.0 : 32.0),
                                Text(
                                  helperText,
                                  key: const Key('dl-signup-helper-text'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: mutedText,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w400,
                                    height: 18.0 / 12.5,
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
                key: const Key('dl-signup-button-dock'),
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

  /// Dynamic Layer v5.1 OTP Verification Scaffold (`_pending != null`):
  /// - `56px` TopNavigation (`40×40` circular `#EEEEEE` `<` button, no separator line)
  /// - `wrapper` (`padding: 32 top/bottom, 16 left/right`, `gap: 32`)
  /// - Centered `16px Bold` `"Enter verification code"`, centered borderless `28px Bold`
  ///   6-digit input (`000000` hint), centered `12.5px #757575` helper text,
  ///   centered `#EEEEEE` stadium pill `"Resend code"`, and `56px` `Continue` `ButtonDock`.
  Widget _buildDynamicLayerOtpScaffold(
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
    final Color mutedText =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF757575);
    final Color placeholderColor =
        isDark ? const Color(0xFF52525B) : const Color(0xFFC7C7CC);
    const Color errorRed = Color(0xFFE31B23);

    final digits = AccountValidation.normalizeDigits(_code.text)
        .replaceAll(RegExp(r'[^0-9]'), '');
    final bool isFilled = digits.length == 6;
    final Color continueBg =
        isFilled ? (isDark ? Colors.white : const Color(0xFF000000)) : pillBg;
    final Color continueFg = isFilled
        ? (isDark ? const Color(0xFF000000) : Colors.white)
        : mutedText;

    final backIcon =
        isAr ? CupertinoIcons.chevron_right : CupertinoIcons.chevron_left;
    final maskedEmail =
        AccountValidation.maskEmail(_pending?.user['email']?.toString());

    final bool isSending = _otpPhase == _OtpPhase.sendingInitial ||
        _otpPhase == _OtpPhase.resending;
    final bool canTapResend = !isSending && !_busy && _remaining == 0;

    final String helperText = _notice ??
        (maskedEmail != null
            ? s.tr(
                'أرسلنا رمز تحقق مكوناً من 6 أرقام إلى $maskedEmail',
                'Nous avons envoyé un code à 6 chiffres à $maskedEmail',
                'We sent a 6-digit verification code to $maskedEmail',
              )
            : s.tr(
                'أرسلنا رمز تحقق مكوناً من 6 أرقام إلى بريدك الإلكتروني',
                'Nous avons envoyé un code à 6 chiffres à votre e-mail',
                'We sent a 6-digit verification code to your email',
              ));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _resetOtp();
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
                key: const Key('dl-otp-top-nav'),
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
                            onPressed: _resetOtp,
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
                          key: const Key('dl-otp-wrapper'),
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
                                  'أدخل رمز التحقق',
                                  'Entrez le code de vérification',
                                  'Enter verification code',
                                ),
                                key: const Key('dl-otp-prompt-label'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: ink,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w700,
                                  height: 24.0 / 16.0,
                                ),
                              ),
                              const SizedBox(height: 32.0),

                              AnimatedBuilder(
                                animation: _shakeCtrl,
                                builder: (context, child) {
                                  final dx = _shakeCtrl.isAnimating
                                      ? math.sin(
                                              _shakeCtrl.value * math.pi * 6) *
                                          6.0
                                      : 0.0;
                                  return Transform.translate(
                                    offset: Offset(dx, 0),
                                    child: child,
                                  );
                                },
                                child: Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: AutofillGroup(
                                    child: TextField(
                                      key: const Key('auth-code'),
                                      controller: _code,
                                      focusNode: _codeFocus,
                                      autofocus: true,
                                      enabled: !_busy,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        signed: false,
                                        decimal: false,
                                      ),
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [
                                        AutofillHints.oneTimeCode,
                                      ],
                                      inputFormatters: const [
                                        _OtpSixDigitInputFormatter(),
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
                                        letterSpacing: 6.0,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                      decoration: InputDecoration(
                                        hintText: '000000',
                                        hintStyle: TextStyle(
                                          color: placeholderColor,
                                          fontSize: 28.0,
                                          fontWeight: FontWeight.w700,
                                          height: 36.0 / 28.0,
                                          letterSpacing: 6.0,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                        counterText: '',
                                        filled: false,
                                        fillColor: Colors.transparent,
                                        hoverColor: Colors.transparent,
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        disabledBorder: InputBorder.none,
                                        errorBorder: InputBorder.none,
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          vertical: 4.0,
                                        ),
                                      ),
                                      onChanged: _onOtpChanged,
                                      onSubmitted: (_) => _submit(),
                                    ),
                                  ),
                                ),
                              ),

                              if (_error != null) ...[
                                const SizedBox(height: 18.0),
                                Text(
                                  _error!,
                                  key: const Key('dl-otp-error-text'),
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
                                helperText,
                                key: const Key('dl-otp-helper-text'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: mutedText,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w400,
                                  height: 18.0 / 12.5,
                                ),
                              ),

                              const SizedBox(height: 20.0),

                              Material(
                                color: pillBg,
                                shape: const StadiumBorder(),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  key: const Key('otp-resend'),
                                  customBorder: const StadiumBorder(),
                                  onTap: canTapResend ? _resend : null,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18.0,
                                      vertical: 10.0,
                                    ),
                                    child: isSending
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const CupertinoActivityIndicator(
                                                radius: 7,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                s.tr(
                                                  'جاري الإرسال...',
                                                  'Envoi...',
                                                  'Sending...',
                                                ),
                                                style: TextStyle(
                                                  color: mutedText,
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Text(
                                            _remaining > 0
                                                ? s.tr(
                                                    'إعادة الإرسال ($_remaining ث)',
                                                    'Renvoyer (${_remaining}s)',
                                                    'Resend code (${_remaining}s)',
                                                  )
                                                : s.tr(
                                                    'إعادة إرسال الرمز',
                                                    'Renvoyer le code',
                                                    'Resend code',
                                                  ),
                                            style: TextStyle(
                                              color: canTapResend
                                                  ? ink
                                                  : mutedText,
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.w600,
                                              height: 20.0 / 14.0,
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
              ),

              // Fixed Bottom `ButtonDock` (`56px` stadium pill `Continue`)
              Padding(
                key: const Key('dl-otp-button-dock'),
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
                            child: _busy || _otpPhase == _OtpPhase.verifying
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: continueFg,
                                    ),
                                  )
                                : _otpPhase == _OtpPhase.verified
                                    ? Icon(
                                        Icons.check_rounded,
                                        size: 22,
                                        color: continueFg,
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
}

/// Formats Sign-Up Step 4 username input with a leading `@` (`@joshua`)
/// matching Figma `Pick a username / Filled` (`25680:46408`).
class _UsernameHandleInputFormatter extends TextInputFormatter {
  const _UsernameHandleInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final stripped = newValue.text
        .toLowerCase()
        .replaceAll(RegExp(r'^@+'), '')
        .replaceAll(RegExp(r'[^a-z0-9._]'), '');
    if (stripped.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    final capped =
        stripped.length > 24 ? stripped.substring(0, 24) : stripped;
    final formatted = '@$capped';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formats Sign-Up Step 5 Moroccan subscriber number right after `+212`
/// into `XXX-XXXXXX` (e.g. `650-123456`), stripping any pasted `+212` or leading `0`.
class _MoroccanSubscriberPhoneFormatter extends TextInputFormatter {
  const _MoroccanSubscriberPhoneFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = AccountValidation.normalizeDigits(newValue.text)
        .replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('00212')) {
      digits = digits.substring(5);
    } else if (digits.startsWith('212') && digits.length > 9) {
      digits = digits.substring(3);
    }
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    if (digits.length > 9) {
      digits = digits.substring(0, 9);
    }
    final formatted = digits.length > 3
        ? '${digits.substring(0, 3)}-${digits.substring(3)}'
        : digits;
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Extracts up to 6 numeric digits from typed or `one-time-code` auto-filled
/// SMS/Email OTP strings (even when spaced like `123 456` or prefixed).
class _OtpSixDigitInputFormatter extends TextInputFormatter {
  const _OtpSixDigitInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = AccountValidation.normalizeDigits(newValue.text)
        .replaceAll(RegExp(r'[^0-9]'), '');
    final capped = digits.length > 6 ? digits.substring(0, 6) : digits;
    return TextEditingValue(
      text: capped,
      selection: TextSelection.collapsed(offset: capped.length),
    );
  }
}
