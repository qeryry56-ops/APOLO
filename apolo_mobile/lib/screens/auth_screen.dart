import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/state/app_state.dart';

/// Login / Register screen — Triply-AI / Cal-AI 2026 design system.
class AuthScreen extends StatefulWidget {
  final bool startWithRegister;
  const AuthScreen({super.key, this.startWithRegister = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AppState _state = AppState();
  late bool _isLogin = !widget.startWithRegister;
  bool _loading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;
  String? _error;

  final _nameCtrl = TextEditingController();
  final _loginCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // Design tokens (Apolo Official Brand Red #E31B23 + Pure White #FFFFFF)
  static const Color _ink = Color(0xFF0F1B2D);
  static const Color _blue = Color(0xFFE31B23);
  static const Color _muted = Color(0xFF8A94A6);
  static const Color _border = Color(0xFFE7EAF0);
  static const Color _fill = Color(0xFFF1F3F7);
  static const Color _danger = Color(0xFFE31B23);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _loginCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String _platform() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      default:
        return 'web';
    }
  }

  String? _validate() {
    final s = _state.s;
    if (!_isLogin && _nameCtrl.text.trim().length < 2) {
      return s.tr('دخل الاسم الكامل ديالك', 'Entrez votre nom complet');
    }
    if (_loginCtrl.text.trim().isEmpty) {
      return _isLogin
          ? s.tr('دخل البريد الإلكتروني أو رقم الهاتف', 'Entrez votre email ou téléphone')
          : s.tr('دخل البريد الإلكتروني', 'Entrez votre email');
    }
    if (!_isLogin && !_loginCtrl.text.contains('@')) {
      return s.tr('البريد الإلكتروني غير صحيح', 'Adresse email invalide');
    }
    if (!_isLogin && _phoneCtrl.text.trim().length < 9) {
      return s.tr('رقم الهاتف غير صحيح', 'Numéro de téléphone invalide');
    }
    if (_passCtrl.text.length < (_isLogin ? 1 : 8)) {
      return _isLogin
          ? s.tr('دخل كلمة المرور', 'Entrez votre mot de passe')
          : s.tr('كلمة المرور خاصها 8 حروف على الأقل', 'Mot de passe : 8 caractères minimum');
    }
    if (!_isLogin && _passCtrl.text != _confirmCtrl.text) {
      return s.tr('كلمتا المرور غير متطابقتين', 'Les mots de passe ne correspondent pas');
    }
    return null;
  }

  Future<void> _submit() async {
    final s = _state.s;
    FocusScope.of(context).unfocus();
    final v = _validate();
    if (v != null) {
      setState(() => _error = v);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = _isLogin
          ? await _state.api.dio.post('/auth/login', data: {
              'login': _loginCtrl.text.trim(),
              'password': _passCtrl.text,
              'platform': _platform(),
            })
          : await _state.api.dio.post('/auth/register', data: {
              'name': _nameCtrl.text.trim(),
              'email': _loginCtrl.text.trim(),
              'phone': _phoneCtrl.text.trim(),
              'password': _passCtrl.text,
              'password_confirmation': _confirmCtrl.text,
              'referral_source': 'mobile_app',
            });
      if (res.data is Map && res.data['status'] == 'success') {
        await _state.setAuthSession(
          res.data['token'].toString(),
          Map<String, dynamic>.from(res.data['user']),
        );
        if (mounted) Navigator.pop(context, true);
        return;
      }
      _error = (res.data is Map ? res.data['message'] : null)?.toString() ??
          s.tr('وقع مشكل، عاود من جديد', 'Une erreur est survenue');
    } catch (_) {
      _error = _isLogin
          ? s.tr('البريد/الهاتف أو كلمة المرور غير صحيحة', 'Identifiants incorrects')
          : s.tr('هاد الحساب كاين من قبل أو المعلومات غير صحيحة', 'Compte déjà existant ou données invalides');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _switchMode(bool login) {
    if (_isLogin == login) return;
    setState(() {
      _isLogin = login;
      _error = null;
    });
  }

  void _comingSoon(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(_state.s.tr('الدخول عبر $provider قريباً', 'Connexion $provider bientôt disponible')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header: circular back button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  if (canPop)
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(color: _fill, shape: BoxShape.circle),
                        child: const Icon(Icons.chevron_left_rounded, color: _ink, size: 26),
                      ),
                    ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () async {
                      await _state.toggleLanguage();
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(color: _fill, borderRadius: BorderRadius.circular(999)),
                      child: Text(
                        s.isAr ? 'FR' : 'عربي',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _ink),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                children: [
                  // Brand mark
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5258), Color(0xFFE31B23)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(color: _blue.withValues(alpha: 0.28), blurRadius: 16, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: const Icon(Icons.explore_rounded, color: Colors.white, size: 30),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Title
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: Column(
                      key: ValueKey(_isLogin),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isLogin
                              ? s.tr('مرحباً بعودتك 👋', 'Welcome back 👋')
                              : s.tr('أنشئ حسابك', 'Create account'),
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                            color: _ink,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isLogin
                              ? s.tr('دخل لحسابك باش تتابع إعلاناتك ورسائلك.', 'Connectez-vous pour gérer vos annonces et messages.')
                              : s.tr('انضم لآلاف المغاربة اللي كيبيعو ويشريو على Apolo.', 'Rejoignez des milliers de Marocains sur Apolo.'),
                          style: const TextStyle(fontSize: 16, height: 1.4, color: _muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),

                  // Segmented control
                  Container(
                    height: 50,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: _fill, borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      children: [
                        _segment(s.login, _isLogin, () => _switchMode(true)),
                        _segment(s.register, !_isLogin, () => _switchMode(false)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Fields
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: Column(
                      children: [
                        if (!_isLogin) ...[
                          _field(
                            label: s.tr('الاسم الكامل', 'Nom complet'),
                            controller: _nameCtrl,
                            hint: s.tr('مثال: أمين العلوي', 'ex : Amine Alaoui'),
                            icon: Icons.person_outline_rounded,
                            action: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                        ],
                        _field(
                          label: _isLogin
                              ? s.tr('البريد الإلكتروني أو الهاتف', 'Email ou téléphone')
                              : s.tr('البريد الإلكتروني', 'Email'),
                          controller: _loginCtrl,
                          hint: _isLogin ? 'email@exemple.ma / 06XXXXXXXX' : 'email@exemple.ma',
                          icon: Icons.alternate_email_rounded,
                          keyboard: TextInputType.emailAddress,
                          action: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        if (!_isLogin) ...[
                          _field(
                            label: s.tr('رقم الهاتف', 'Téléphone'),
                            controller: _phoneCtrl,
                            hint: '06 XX XX XX XX',
                            icon: Icons.phone_outlined,
                            keyboard: TextInputType.phone,
                            action: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                        ],
                        _field(
                          label: s.tr('كلمة المرور', 'Mot de passe'),
                          controller: _passCtrl,
                          hint: '••••••••',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscure,
                          onToggleObscure: () => setState(() => _obscure = !_obscure),
                          action: _isLogin ? TextInputAction.done : TextInputAction.next,
                          onSubmitted: _isLogin ? (_) => _submit() : null,
                        ),
                        if (!_isLogin) ...[
                          const SizedBox(height: 16),
                          _field(
                            label: s.tr('تأكيد كلمة المرور', 'Confirmer le mot de passe'),
                            controller: _confirmCtrl,
                            hint: '••••••••',
                            icon: Icons.lock_outline_rounded,
                            obscure: _obscureConfirm,
                            onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            action: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (_isLogin)
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: () => _comingSoon(s.tr('استرجاع كلمة المرور', 'récupération')),
                        style: TextButton.styleFrom(foregroundColor: _blue),
                        child: Text(
                          s.tr('نسيت كلمة المرور؟', 'Mot de passe oublié ?'),
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 14),

                  // Inline error
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: _danger, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: _danger, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Primary CTA
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _blue,
                        disabledBackgroundColor: _blue.withValues(alpha: 0.55),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const StadiumBorder(),
                      ),
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                            )
                          : Text(
                              _isLogin ? s.login : s.tr('إنشاء الحساب', 'Créer mon compte'),
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Divider "or"
                  Row(
                    children: [
                      const Expanded(child: Divider(color: _border, thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          s.tr('أو', 'ou'),
                          style: const TextStyle(color: _muted, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const Expanded(child: Divider(color: _border, thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Social buttons
                  _socialButton(
                    leading: const Text(
                      'G',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFEA4335)),
                    ),
                    label: s.tr('المتابعة عبر Google', 'Continuer avec Google'),
                    onTap: () => _comingSoon('Google'),
                  ),
                  const SizedBox(height: 12),
                  _socialButton(
                    leading: const Icon(Icons.apple_rounded, size: 24, color: _ink),
                    label: s.tr('المتابعة عبر Apple', 'Continuer avec Apple'),
                    onTap: () => _comingSoon('Apple'),
                  ),
                  const SizedBox(height: 26),

                  // Footer switch
                  Center(
                    child: GestureDetector(
                      onTap: () => _switchMode(!_isLogin),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 15, color: _muted),
                          children: [
                            TextSpan(
                              text: _isLogin
                                  ? s.tr('ما عندكش حساب؟ ', 'Pas encore de compte ? ')
                                  : s.tr('عندك حساب؟ ', 'Déjà un compte ? '),
                            ),
                            TextSpan(
                              text: _isLogin ? s.register : s.login,
                              style: const TextStyle(color: _blue, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    s.tr(
                      'بالمتابعة، فإنك توافق على شروط الاستخدام وسياسة الخصوصية.',
                      'En continuant, vous acceptez nos Conditions et notre Politique de confidentialité.',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, height: 1.45, color: _muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segment(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: active
                ? [BoxShadow(color: _ink.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 3))]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              color: active ? _ink : _muted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboard,
    TextInputAction? action,
    bool? obscure,
    VoidCallback? onToggleObscure,
    ValueChanged<String>? onSubmitted,
  }) {
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: _border, width: 1.2),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _ink),
          ),
        ),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          textInputAction: action,
          obscureText: obscure ?? false,
          onSubmitted: onSubmitted,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: _ink),
          cursorColor: _blue,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFB0B8C6), fontWeight: FontWeight.w400),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
            prefixIcon: Icon(icon, color: _muted, size: 22),
            suffixIcon: onToggleObscure == null
                ? null
                : IconButton(
                    onPressed: onToggleObscure,
                    icon: Icon(
                      (obscure ?? false) ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: _muted,
                      size: 21,
                    ),
                  ),
            border: outline,
            enabledBorder: outline,
            focusedBorder: outline.copyWith(borderSide: const BorderSide(color: _blue, width: 1.6)),
          ),
        ),
      ],
    );
  }

  Widget _socialButton({required Widget leading, required String label, required VoidCallback onTap}) {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _ink,
          side: const BorderSide(color: _border, width: 1.2),
          shape: const StadiumBorder(),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 26, child: Center(child: leading)),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _ink)),
          ],
        ),
      ),
    );
  }
}
