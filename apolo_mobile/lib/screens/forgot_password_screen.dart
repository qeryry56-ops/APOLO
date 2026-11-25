import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../account/account_helpers.dart';
import '../core/state/app_state.dart';
import '../theme/dl_share_profile_tokens.dart';
import '../widgets/dl_settings_kit.dart';
import 'main_shell.dart';

enum _RecoveryStep {
  email,
  otp,
  newPassword,
}

/// Dynamic Layer v5.1 APOLO 3-Step Forgot Password & Account Recovery Screen.
///
/// 1. `Enter your email` (`example@gmail.com`) -> sends 6-digit verification code.
/// 2. `Enter verification code` (`000000` + `#EEEEEE` `Resend code` pill) -> verifies OTP.
/// 3. `Choose a new password` (`Password` + `Your password must be at least 8 characters`) ->
///    saves new password, signs in, and navigates directly to `MainShell`.
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
  final _email = TextEditingController();
  final _emailFocus = FocusNode();
  final _code = TextEditingController();
  final _codeFocus = FocusNode();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();

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
    for (final c in [_email, _code, _password]) {
      c.addListener(_onInputChanged);
    }
    for (final f in [_emailFocus, _codeFocus, _passwordFocus]) {
      f.addListener(_onInputChanged);
    }
  }

  void _onInputChanged() {
    if (mounted) {
      setState(() {
        if (_error != null) _error = null;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _auth.close();
    for (final c in [_email, _code, _password]) {
      c.removeListener(_onInputChanged);
      c.dispose();
    }
    for (final f in [_emailFocus, _codeFocus, _passwordFocus]) {
      f.removeListener(_onInputChanged);
      f.dispose();
    }
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _emailFocus.requestFocus();
      });
      return;
    }
    if (_step == _RecoveryStep.newPassword) {
      setState(() {
        _step = _RecoveryStep.otp;
        _error = null;
        _notice = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _codeFocus.requestFocus();
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
      final masked = AccountValidation.maskEmail(email) ?? email;
      setState(() {
        _step = _RecoveryStep.otp;
        if (isResend) {
          _code.clear();
          _notice = _state.s.tr(
            'تم إرسال رمز جديد إلى $masked.',
            'Un nouveau code a été envoyé à $masked.',
            'A new verification code was sent to $masked.',
          );
        } else {
          _notice = _state.s.tr(
            'أرسلنا رمز تحقق مكوناً من 6 أرقام إلى $masked.',
            'Nous avons envoyé un code à 6 chiffres à $masked.',
            'We sent a 6-digit verification code to $masked.',
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
    final code = AccountValidation.normalizeDigits(_code.text)
        .replaceAll(RegExp(r'[^0-9]'), '');
    if (code.isEmpty) {
      _codeFocus.requestFocus();
      return;
    }
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
        _notice = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _passwordFocus.requestFocus();
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
    final newPassword = _password.text;
    if (newPassword.isEmpty) {
      _passwordFocus.requestFocus();
      return;
    }
    if (!AccountValidation.password(newPassword)) {
      HapticFeedback.heavyImpact();
      setState(() {
        _error = _state.s.tr(
          'يجب أن تتكون كلمة المرور من 8 أحرف على الأقل',
          'Votre mot de passe doit contenir au moins 8 caractères',
          'Your password must be at least 8 characters',
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
      final email = _email.text.trim();
      final code = AccountValidation.normalizeDigits(_code.text)
          .replaceAll(RegExp(r'[^0-9]'), '');

      AccountSession? session = await _auth.resetPasswordWithToken(
        email: email,
        token: code,
        password: newPassword,
        confirmation: newPassword,
      );

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

  VoidCallback get _stepSubmitAction {
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
    final Color placeholderColor =
        isDark ? const Color(0xFF52525B) : const Color(0xFFC7C7CC);
    const Color errorRed = Color(0xFFE31B23);

    final codeDigits = AccountValidation.normalizeDigits(_code.text)
        .replaceAll(RegExp(r'[^0-9]'), '');

    final bool isFilled;
    final String promptLabel;
    final String helperText;
    final Key wrapperKey;

    switch (_step) {
      case _RecoveryStep.email:
        isFilled = _email.text.trim().isNotEmpty;
        promptLabel = s.tr(
          'أدخل بريدك الإلكتروني',
          'Entrez votre e-mail',
          'Enter your email',
        );
        helperText = s.tr(
          'ستتوصل برسالة في بريدك الإلكتروني لتعيين كلمة مرور جديدة',
          'Vous recevrez un e-mail pour définir un nouveau mot de passe',
          'You will receive an email to set a new password',
        );
        wrapperKey = const Key('dl-forgot-wrapper');
        break;
      case _RecoveryStep.otp:
        isFilled = codeDigits.length == 6;
        promptLabel = s.tr(
          'أدخل رمز التحقق',
          'Entrez le code de vérification',
          'Enter verification code',
        );
        final masked = AccountValidation.maskEmail(_email.text.trim()) ??
            _email.text.trim();
        helperText = _notice ??
            s.tr(
              'أرسلنا رمز تحقق مكوناً من 6 أرقام إلى $masked',
              'Nous avons envoyé un code à 6 chiffres à $masked',
              'We sent a 6-digit verification code to $masked',
            );
        wrapperKey = const Key('dl-forgot-otp-wrapper');
        break;
      case _RecoveryStep.newPassword:
        isFilled = _password.text.isNotEmpty;
        promptLabel = s.tr(
          'اختر كلمة مرور جديدة',
          'Choisissez un nouveau mot de passe',
          'Choose a new password',
        );
        helperText = s.tr(
          'يجب أن تتكون كلمة المرور من 8 أحرف على الأقل',
          'Votre mot de passe doit contenir au moins 8 caractères',
          'Your password must be at least 8 characters',
        );
        wrapperKey = const Key('dl-forgot-password-wrapper');
        break;
    }

    final Color continueBg =
        isFilled ? (isDark ? Colors.white : const Color(0xFF000000)) : pillBg;
    final Color continueFg = isFilled
        ? (isDark ? const Color(0xFF000000) : Colors.white)
        : mutedText;

    final int emailLen = _email.text.length;
    final double dynamicInputFontSize =
        emailLen > 28 ? 19.0 : (emailLen > 20 ? 23.0 : 28.0);

    final backIcon =
        isAr ? CupertinoIcons.chevron_right : CupertinoIcons.chevron_left;

    Widget stepField;
    switch (_step) {
      case _RecoveryStep.email:
        stepField = Directionality(
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
              contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
            ),
            onSubmitted: (_) => _submitEmailRequest(isResend: false),
          ),
        );
        break;

      case _RecoveryStep.otp:
        stepField = Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            key: const Key('forgot-code'),
            controller: _code,
            focusNode: _codeFocus,
            enabled: !_busy,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.oneTimeCode],
            maxLength: 6,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'[0-9\u0660-\u0669\u06F0-\u06F9]'),
              ),
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
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            decoration: InputDecoration(
              hintText: '000000',
              hintStyle: TextStyle(
                color: placeholderColor,
                fontSize: 28.0,
                fontWeight: FontWeight.w700,
                height: 36.0 / 28.0,
                letterSpacing: 6.0,
                fontFeatures: const [FontFeature.tabularFigures()],
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
              contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
            ),
            onChanged: (value) {
              final clean = AccountValidation.normalizeDigits(value)
                  .replaceAll(RegExp(r'[^0-9]'), '');
              if (clean.length == 6 && !_busy) {
                _verifyOtpCode();
              }
            },
            onSubmitted: (_) => _verifyOtpCode(),
          ),
        );
        break;

      case _RecoveryStep.newPassword:
        stepField = Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            key: const Key('forgot-password'),
            controller: _password,
            focusNode: _passwordFocus,
            enabled: !_busy,
            obscureText: true,
            obscuringCharacter: '•',
            textInputAction: TextInputAction.done,
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
              contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
            ),
            onSubmitted: (_) => _submitNewPassword(),
          ),
        );
        break;
    }

    return PopScope(
      canPop: _step == _RecoveryStep.email,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
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
                          key: wrapperKey,
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

                              stepField,

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
                                helperText,
                                key: const Key('dl-forgot-helper-text'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: mutedText,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w400,
                                  height: 18.0 / 12.5,
                                ),
                              ),

                              if (_step == _RecoveryStep.otp) ...[
                                const SizedBox(height: 20.0),
                                Material(
                                  color: pillBg,
                                  shape: const StadiumBorder(),
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    key: const Key('forgot-otp-resend'),
                                    customBorder: const StadiumBorder(),
                                    onTap: (_busy || _cooldownRemaining > 0)
                                        ? null
                                        : () =>
                                            _submitEmailRequest(isResend: true),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18.0,
                                        vertical: 10.0,
                                      ),
                                      child: Text(
                                        _cooldownRemaining > 0
                                            ? s.tr(
                                                'إعادة الإرسال ($_cooldownRemaining ث)',
                                                'Renvoyer (${_cooldownRemaining}s)',
                                                'Resend code (${_cooldownRemaining}s)',
                                              )
                                            : s.tr(
                                                'إعادة إرسال الرمز',
                                                'Renvoyer le code',
                                                'Resend code',
                                              ),
                                        style: TextStyle(
                                          color: _cooldownRemaining > 0
                                              ? mutedText
                                              : ink,
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
                          onTap: _busy ? null : _stepSubmitAction,
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
}
