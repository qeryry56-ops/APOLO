import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../account/account_helpers.dart';
import '../account/account_onboarding_form.dart';
import '../core/state/app_state.dart';
import 'account_security_screen.dart';
import 'support_screen.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback? onSuccess;
  final bool initialRegisterMode;
  final bool initialIsLogin;
  final bool autoTriggerGoogle;
  @visibleForTesting
  final AccountAuth? auth;
  const AuthScreen(
      {super.key,
      this.onSuccess,
      this.initialRegisterMode = false,
      this.initialIsLogin = true,
      this.autoTriggerGoogle = false,
      this.auth});
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
  bool _obscure = true;
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
    // A browser OAuth page cannot create a native session without a verified
    // callback contract. Keep the public flag, but never launch a dead-end flow.
    if (widget.autoTriggerGoogle) {
      _notice = _state.s.tr(
          'الدخول عبر Google غير متاح داخل التطبيق حالياً. استخدم بريدك وكلمة المرور أو الموقع.',
          'La connexion Google n’est pas disponible dans l’application. Utilisez votre e-mail et mot de passe ou le site.');
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
      _code
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
            confirmation: _confirmation.text);
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
      // The callback may push a new route, so remove only this route first.
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
          'L’envoi d’un nouveau code a été confirmé. Vérifiez votre messagerie.'));
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
          appBar: AppBar(
              backgroundColor: Colors.white,
              title: Text(otp
                  ? s.tr('تأكيد البريد', 'Vérifier votre e-mail')
                  : _login
                      ? s.login
                      : s.register)),
          body: SafeArea(
              child: Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
                        child: _onboarding != null
                            ? Column(children: [
                                AccountOnboardingForm(
                                    auth: _auth,
                                    session: _onboarding!,
                                    onComplete: _finish),
                                if (_error != null) Text(_error!),
                              ])
                            : AutofillGroup(
                                child: Form(
                                    key: _form,
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                              _finished
                                                  ? s.tr('تم تسجيل الدخول',
                                                      'Vous êtes connecté')
                                                  : otp
                                                      ? s.tr(
                                                          'خطوة أخيرة لحماية حسابك',
                                                          'Confirmez votre adresse')
                                                      : _login
                                                          ? s.tr(
                                                              'مرحباً بك في Apolo',
                                                              'Bienvenue sur Apolo')
                                                          : s.tr(
                                                              'حسابك، وإعلاناتك، في مكان واحد',
                                                              'Un compte pour vos annonces'),
                                              style: const TextStyle(
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.w800,
                                                  height: 1.3)),
                                          const SizedBox(height: 12),
                                          if (!_finished)
                                            Text(
                                                otp
                                                    ? s.tr(
                                                        'أدخل الرمز المكون من 6 أرقام المرسل إلى بريدك. لا يمكن تجاوز التحقق.',
                                                        'Saisissez le code à 6 chiffres reçu par e-mail. La vérification est obligatoire.')
                                                    : s.tr(
                                                        'سجّل الدخول لإدارة إعلاناتك ومحادثاتك.',
                                                        'Connectez-vous pour gérer vos annonces et vos messages.'),
                                                style: const TextStyle(
                                                    height: 1.6,
                                                    color: Color(0xFF536170))),
                                          if (otp)
                                            Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 8),
                                                child: Text(_email.text.trim(),
                                                    textDirection:
                                                        TextDirection.ltr)),
                                          const SizedBox(height: 28),
                                          if (!_finished) ...[
                                            if (otp)
                                              _field(
                                                  controller: _code,
                                                  label: s.tr('رمز التحقق',
                                                      'Code de vérification'),
                                                  keyName: 'auth-code',
                                                  type: TextInputType.number,
                                                  autofill: const [
                                                    AutofillHints.oneTimeCode
                                                  ],
                                                  validator: (v) =>
                                                      AccountValidation.otp(
                                                              v ?? '')
                                                          ? null
                                                          : s.tr('أدخل 6 أرقام',
                                                              'Saisissez 6 chiffres'))
                                            else ...[
                                              if (!_login)
                                                _field(
                                                    controller: _name,
                                                    label: s.tr('الاسم الكامل',
                                                        'Nom complet'),
                                                    keyName: 'auth-name',
                                                    ltr: false,
                                                    autofill: const [
                                                      AutofillHints.name
                                                    ],
                                                    validator: (v) => (v ?? '')
                                                                .trim()
                                                                .length >=
                                                            2
                                                        ? null
                                                        : s.tr(
                                                            'أدخل اسمك الكامل',
                                                            'Saisissez votre nom complet')),
                                              _field(
                                                  controller: _email,
                                                  label: s.tr(
                                                      'البريد الإلكتروني',
                                                      'Adresse e-mail'),
                                                  keyName: 'auth-email',
                                                  type: TextInputType
                                                      .emailAddress,
                                                  autofill: const [
                                                    AutofillHints.email
                                                  ],
                                                  validator: (v) => AccountValidation
                                                          .email(v ?? '')
                                                      ? null
                                                      : s.tr(
                                                          'أدخل بريداً إلكترونياً صحيحاً',
                                                          'Saisissez une adresse e-mail valide')),
                                              if (!_login)
                                                _field(
                                                    controller: _phone,
                                                    label: s.tr(
                                                        'رقم الهاتف المغربي',
                                                        'Téléphone marocain'),
                                                    keyName: 'auth-phone',
                                                    type: TextInputType.phone,
                                                    autofill: const [
                                                      AutofillHints
                                                          .telephoneNumber
                                                    ],
                                                    hint:
                                                        '06 12 34 56 78 / +212…',
                                                    validator: (v) => AccountValidation
                                                                .phone(
                                                                    v ?? '') !=
                                                            null
                                                        ? null
                                                        : s.tr(
                                                            'استخدم رقماً يبدأ بـ 05 أو 06 أو 07 أو ‎+212',
                                                            'Utilisez un numéro en 05, 06, 07 ou +212')),
                                              _field(
                                                  controller: _password,
                                                  label: s.tr('كلمة المرور',
                                                      'Mot de passe'),
                                                  keyName: 'auth-password',
                                                  secret: true,
                                                  autofill: [
                                                    _login
                                                        ? AutofillHints.password
                                                        : AutofillHints
                                                            .newPassword
                                                  ],
                                                  validator: (v) => (_login
                                                          ? (v ?? '').isNotEmpty
                                                          : AccountValidation
                                                              .password(
                                                                  v ?? ''))
                                                      ? null
                                                      : s.tr(
                                                          _login
                                                              ? 'أدخل كلمة المرور'
                                                              : 'استخدم 8 أحرف على الأقل',
                                                          _login
                                                              ? 'Saisissez votre mot de passe'
                                                              : 'Utilisez au moins 8 caractères')),
                                              if (!_login)
                                                _field(
                                                    controller: _confirmation,
                                                    label: s.tr(
                                                        'تأكيد كلمة المرور',
                                                        'Confirmer le mot de passe'),
                                                    keyName:
                                                        'auth-confirmation',
                                                    secret: true,
                                                    validator: (v) => (v ?? '')
                                                                .isNotEmpty &&
                                                            v == _password.text
                                                        ? null
                                                        : s.tr(
                                                            'كلمتا المرور غير متطابقتين',
                                                            'Les mots de passe ne correspondent pas')),
                                            ],
                                            if (_error != null)
                                              Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 16),
                                                  child: Semantics(
                                                      liveRegion: true,
                                                      child: Text(_error!,
                                                          style: TextStyle(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .error,
                                                              height: 1.5)))),
                                            if (_notice != null)
                                              Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 16),
                                                  child: Semantics(
                                                      liveRegion: true,
                                                      child: Text(_notice!,
                                                          style:
                                                              const TextStyle(
                                                                  height:
                                                                      1.5)))),
                                            FilledButton(
                                                key: const Key('auth-submit'),
                                                onPressed:
                                                    _busy ? null : _submit,
                                                child: Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 14),
                                                    child: _busy
                                                        ? const SizedBox(
                                                            width: 20,
                                                            height: 20,
                                                            child:
                                                                CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2))
                                                        : Text(otp
                                                            ? s.tr(
                                                                'تأكيد الرمز',
                                                                'Vérifier le code')
                                                            : _login
                                                                ? s.login
                                                                : s.register))),
                                            if (otp) ...[
                                              TextButton(
                                                  onPressed:
                                                      _busy || _remaining > 0
                                                          ? null
                                                          : _resend,
                                                  child: Text(_remaining > 0
                                                      ? s.tr(
                                                          'إعادة الإرسال بعد $_remaining ثانية',
                                                          'Renvoyer dans $_remaining s')
                                                      : s.tr('إرسال رمز جديد',
                                                          'Renvoyer le code'))),
                                              TextButton(
                                                  onPressed:
                                                      _busy ? null : _reset,
                                                  child: Text(s.tr(
                                                      'العودة لتسجيل الدخول',
                                                      'Revenir aux identifiants'))),
                                            ] else ...[
                                              TextButton(
                                                  onPressed: _busy
                                                      ? null
                                                      : () {
                                                          _form.currentState
                                                              ?.reset();
                                                          setState(() {
                                                            _login = !_login;
                                                            _error = null;
                                                            _password.clear();
                                                            _confirmation
                                                                .clear();
                                                          });
                                                        },
                                                  child: Text(_login
                                                      ? s.tr(
                                                          'ليس لديك حساب؟ إنشاء حساب',
                                                          'Pas encore de compte ? Inscrivez-vous')
                                                      : s.tr(
                                                          'لديك حساب؟ تسجيل الدخول',
                                                          'Déjà un compte ? Connectez-vous'))),
                                            ],
                                            const Divider(height: 32),
                                            TextButton(
                                                onPressed: _busy
                                                    ? null
                                                    : () => Navigator.of(
                                                            context)
                                                        .push(MaterialPageRoute(
                                                            builder: (_) =>
                                                                const AccountSecurityScreen())),
                                                child: Text(s.tr(
                                                    'نسيت كلمة المرور؟ إدارة عبر الموقع',
                                                    'Mot de passe oublié ? Gérer sur le site'))),
                                            TextButton(
                                                onPressed: _busy
                                                    ? null
                                                    : () => Navigator.of(
                                                            context)
                                                        .push(MaterialPageRoute(
                                                            builder: (_) =>
                                                                const SupportScreen())),
                                                child: Text(s.tr(
                                                    'المساعدة والدعم',
                                                    'Aide et assistance'))),
                                          ],
                                        ]))),
                      )))),
        ));
  }

  Widget _field(
      {required TextEditingController controller,
      required String label,
      required String keyName,
      required FormFieldValidator<String> validator,
      bool secret = false,
      bool ltr = true,
      TextInputType? type,
      Iterable<String>? autofill,
      String? hint}) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: TextFormField(
          key: Key(keyName),
          controller: controller,
          enabled: !_busy,
          textDirection: ltr ? TextDirection.ltr : null,
          keyboardType: type,
          autofillHints: autofill,
          obscureText: secret && _obscure,
          autocorrect: false,
          enableSuggestions: !secret,
          textInputAction: TextInputAction.next,
          validator: validator,
          inputFormatters: type == TextInputType.number
              ? [
                  TextInputFormatter.withFunction((oldValue, newValue) =>
                      newValue.copyWith(
                          text: AccountValidation.normalizeDigits(
                              newValue.text))),
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6)
                ]
              : null,
          decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              errorMaxLines: 3,
              suffixIcon: secret
                  ? IconButton(
                      tooltip: _state.s.tr(
                          _obscure ? 'إظهار كلمة المرور' : 'إخفاء كلمة المرور',
                          _obscure
                              ? 'Afficher le mot de passe'
                              : 'Masquer le mot de passe'),
                      onPressed: _busy
                          ? null
                          : () => setState(() => _obscure = !_obscure),
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined))
                  : null),
        ));
  }
}
