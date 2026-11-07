import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import 'privacy_compliance_screen.dart';

/// 2026 Login & 4-Step Animated Registration Wizard
/// Step 1: Account Type (Individual vs Boutique Pro)
/// Step 2: Full Name (or Store Name) + Phone / WhatsApp
/// Step 3: Email + Password (with live strength meter)
/// Step 4: City + Favorite Categories (for Smart Feed Algorithm)
class AuthScreen extends StatefulWidget {
  final bool startWithRegister;
  final bool autoTriggerGoogle;

  const AuthScreen({
    super.key,
    this.startWithRegister = false,
    this.autoTriggerGoogle = false,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AppState _state = AppState();
  late bool _isLogin = !widget.startWithRegister;
  int _regStep = 0; // 0..3 for 4-step registration
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  // Step 1: Account Type ('individual' | 'pro')
  String _accountType = 'individual';

  // Step 2: Name & Phone
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // Step 3: Email & Password
  final _loginCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  // Step 4: City & Interests
  int? _selectedCityId = 1;
  final Set<int> _selectedInterests = {3, 2, 1};

  static const Color _ink = Color(0xFF0F1B2D);
  static const Color _red = Color(0xFFE31B23);
  static const Color _redSoft = Color(0xFFFEECEE);
  static const Color _muted = Color(0xFF8A94A6);
  static const Color _border = Color(0xFFE7EAF0);
  static const Color _fill = Color(0xFFF3F5F9);
  static const Color _emerald = Color(0xFF10B981);

  static const List<Map<String, dynamic>> _fallbackCities = [
    {'id': 1, 'name_ar': 'الدار البيضاء', 'name_fr': 'Casablanca'},
    {'id': 2, 'name_ar': 'الرباط', 'name_fr': 'Rabat'},
    {'id': 3, 'name_ar': 'مراكش', 'name_fr': 'Marrakech'},
    {'id': 4, 'name_ar': 'طنجة', 'name_fr': 'Tanger'},
    {'id': 5, 'name_ar': 'أكادير', 'name_fr': 'Agadir'},
    {'id': 6, 'name_ar': 'فاس', 'name_fr': 'Fès'},
    {'id': 7, 'name_ar': 'مكناس', 'name_fr': 'Meknès'},
    {'id': 8, 'name_ar': 'وجدة', 'name_fr': 'Oujda'},
  ];

  static const List<Map<String, dynamic>> _interestShowcase = [
    {
      'id': 3,
      'name_ar': 'وسائل النقل',
      'name_fr': 'Véhicules',
      'asset': 'assets/images/hero_car.png',
    },
    {
      'id': 2,
      'name_ar': 'عقارات',
      'name_fr': 'Immobilier',
      'asset': 'assets/images/cat_realestate.png',
    },
    {
      'id': 1,
      'name_ar': 'إعلاميات وتقنية',
      'name_fr': 'Informatique',
      'asset': 'assets/images/cat_computers.png',
    },
    {
      'id': 4,
      'name_ar': 'أزياء وجمال',
      'name_fr': 'Mode & Beauté',
      'asset': 'assets/images/cat_fashion.png',
    },
    {
      'id': 5,
      'name_ar': 'أدوات السفر',
      'name_fr': 'Voyage',
      'asset': 'assets/images/cat_travel.png',
    },
    {
      'id': 6,
      'name_ar': 'بارافارماسي',
      'name_fr': 'Parapharmacie',
      'asset': 'assets/images/cat_parapharmacy.png',
    },
    {
      'id': 10,
      'name_ar': 'المجوهرات',
      'name_fr': 'Bijoux',
      'asset': 'assets/images/cat_jewelry.png',
    },
    {
      'id': 8,
      'name_ar': 'بريكولاج',
      'name_fr': 'Bricolage',
      'asset': 'assets/images/cat_bricolage.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _passCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    if (widget.autoTriggerGoogle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _signInWithGoogle();
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _loginCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
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

  int _passwordStrength(String pass) {
    if (pass.isEmpty) return 0;
    int s = 0;
    if (pass.length >= 8) s++;
    if (RegExp(r'[A-Z]').hasMatch(pass) || RegExp(r'[0-9]').hasMatch(pass)) s++;
    if (pass.length >= 10 && RegExp(r'[0-9]').hasMatch(pass)) s++;
    return s.clamp(1, 3);
  }

  bool _validateCurrentRegStep() {
    final s = _state.s;
    setState(() => _error = null);
    if (_regStep == 0) {
      return true;
    } else if (_regStep == 1) {
      if (_nameCtrl.text.trim().length < 2) {
        setState(() {
          _error = s.tr(
            'دخل الاسم الكامل أو اسم المتجر',
            'Veuillez saisir votre nom complet',
          );
        });
        return false;
      }
      if (_phoneCtrl.text.trim().length < 9) {
        setState(() {
          _error = s.tr(
            'دخل رقم الهاتف أو الواتساب الصحيح (مثال: 06XXXXXXXX)',
            'Numéro de téléphone invalide',
          );
        });
        return false;
      }
      return true;
    } else if (_regStep == 2) {
      if (!_loginCtrl.text.trim().contains('@')) {
        setState(() {
          _error = s.tr(
            'دخل بريد إلكتروني صحيح',
            'Veuillez saisir une adresse e-mail valide',
          );
        });
        return false;
      }
      if (_passCtrl.text.length < 8) {
        setState(() {
          _error = s.tr(
            'كلمة المرور خاصها 8 حروف أو أرقام على الأقل',
            'Le mot de passe doit contenir au moins 8 caractères',
          );
        });
        return false;
      }
      return true;
    }
    return true;
  }

  Future<void> _submitLogin() async {
    final s = _state.s;
    FocusScope.of(context).unfocus();
    if (_loginCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      setState(() {
        _error = s.tr(
          'دخل البريد الإلكتروني/الهاتف وكلمة المرور',
          'Entrez votre e-mail/téléphone et votre mot de passe',
        );
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _state.api.dio.post('/auth/login', data: {
        'login': _loginCtrl.text.trim(),
        'password': _passCtrl.text,
        'platform': _platform(),
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
      _error = s.tr(
        'البريد/الهاتف أو كلمة المرور غير صحيحة',
        'Identifiants incorrects',
      );
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _submitRegister() async {
    final s = _state.s;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });

    // Save onboarding preferences into Smart Feed Engine immediately
    await _state.saveOnboardingPreferences(
      accType: _accountType,
      cityId: _selectedCityId,
      selectedCategories: _selectedInterests,
    );

    try {
      final res = await _state.api.dio.post('/auth/register', data: {
        'name': _nameCtrl.text.trim(),
        'email': _loginCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'password': _passCtrl.text,
        'password_confirmation': _passCtrl.text,
        'account_type': _accountType,
        'city_id': _selectedCityId,
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
      _error = s.tr(
        'هاد الحساب مسجل من قبل أو المعلومات غير صحيحة',
        'Ce compte existe déjà ou les données sont invalides',
      );
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _signInWithGoogle() async {
    final s = _state.s;
    final Uri googleUri = Uri.parse(
      'https://accounts.google.com/o/oauth2/v2/auth'
      '?client_id=${Uri.encodeComponent(AppConfig.googleClientId)}'
      '&redirect_uri=${Uri.encodeComponent(AppConfig.googleOAuthRedirectUri)}'
      '&response_type=code'
      '&scope=${Uri.encodeComponent("openid profile email")}'
      '&prompt=select_account',
    );
    try {
      final launched = await launchUrl(
        googleUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        setState(() {
          _error = s.tr(
            'تعذر فتح نافذة Google، جرب مرة أخرى.',
            'Impossible d\'ouvrir Google Sign-In.',
          );
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = s.tr(
            'تعذر الاتصال بـ Google حالياً.',
            'Connexion Google indisponible.',
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final cities =
        _state.cities.isNotEmpty ? _state.cities : _fallbackCities;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            s.isAr ? CupertinoIcons.chevron_right : CupertinoIcons.chevron_left,
            color: _ink,
            size: 21,
          ),
          onPressed: () {
            if (!_isLogin && _regStep > 0) {
              setState(() {
                _regStep--;
                _error = null;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GestureDetector(
              onTap: () async {
                await _state.toggleLanguage();
                if (mounted) setState(() {});
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: _fill,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _border),
                ),
                alignment: Alignment.center,
                child: Text(
                  s.isAr ? 'Français' : 'العربية',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mode Switcher (Login vs 4-Step Register)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _fill,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _isLogin = true;
                                _error = null;
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 11),
                                decoration: BoxDecoration(
                                  color:
                                      _isLogin ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(13),
                                  boxShadow: _isLogin
                                      ? [
                                          BoxShadow(
                                            color: _ink.withValues(alpha: 0.06),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  s.tr('تسجيل الدخول', 'Connexion'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: _isLogin ? _red : _muted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _isLogin = false;
                                _error = null;
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 11),
                                decoration: BoxDecoration(
                                  color: !_isLogin
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(13),
                                  boxShadow: !_isLogin
                                      ? [
                                          BoxShadow(
                                            color: _ink.withValues(alpha: 0.06),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  s.tr('حساب جديد (4 خطوات)', 'Créer un compte'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: !_isLogin ? _red : _muted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (_error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _redSoft,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _red.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              CupertinoIcons.exclamationmark_circle_fill,
                              color: _red,
                              size: 19,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (_isLogin)
                      _buildLoginView(s)
                    else
                      _buildRegisterWizard(s, cities),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginView(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.tr('مرحباً بعودتك إلى Apolo.ma 👋', 'Bon retour sur Apolo.ma 👋'),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: _ink,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          s.tr(
            'دخل معلوماتك باش تتابع إعلاناتك، رسائلك ومتجرك.',
            'Connectez-vous pour gérer vos annonces, messages et boutique.',
          ),
          style: const TextStyle(
            fontSize: 14,
            color: _muted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 22),
        _buildFieldLabel(
          s.tr('البريد الإلكتروني أو رقم الهاتف', 'E-mail ou téléphone'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _loginCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'example@gmail.com / 06XXXXXXXX',
            prefixIcon: const Icon(CupertinoIcons.person, size: 19),
            filled: true,
            fillColor: _fill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildFieldLabel(s.tr('كلمة المرور', 'Mot de passe')),
        const SizedBox(height: 8),
        TextField(
          controller: _passCtrl,
          obscureText: _obscure,
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: const Icon(CupertinoIcons.lock, size: 19),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                size: 19,
                color: _muted,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            filled: true,
            fillColor: _fill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              elevation: 0,
            ),
            onPressed: _loading ? null : _submitLogin,
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.4,
                    ),
                  )
                : Text(
                    s.tr('تسجيل الدخول', 'Se connecter'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 18),
        _buildGoogleButton(s),
        const SizedBox(height: 20),
        _buildPrivacyFooterLink(s),
      ],
    );
  }

  Widget _buildRegisterWizard(AppStrings s, List<dynamic> cities) {
    final stepTitles = [
      s.tr('1. اختر نوع حسابك', '1. Choisissez votre type de compte'),
      s.tr('2. الاسم ورقم التواصل', '2. Nom & Numéro WhatsApp'),
      s.tr('3. البريد وكلمة المرور', '3. E-mail & Sécurité'),
      s.tr('4. مدينتك واهتماماتك ✨', '4. Ville & Préférences ✨'),
    ];
    final stepSubtitles = [
      s.tr(
        'واش باغي تبيع وتشري كفرد عادي أو تفتح متجر احترافي؟',
        'Souhaitez-vous vendre en tant que particulier ou ouvrir une boutique Pro ?',
      ),
      s.tr(
        'هاد المعلومات كتخلي المشترين يثيقو فـ إعلاناتك ويتواصلو معاك بسهولة.',
        'Ces informations permettent aux acheteurs de vous contacter facilement.',
      ),
      s.tr(
        'احمِ حسابك ببريد إلكتروني صحيح وكلمة مرور قوية.',
        'Sécurisez votre compte avec votre e-mail et un mot de passe fort.',
      ),
      s.tr(
        'اختر مدينتك والأقسام اللي كتهمك باش الخوارزمية تخصص ليك الـ Feed!',
        'Choisissez votre ville et vos catégories favorites pour personnaliser votre fil !',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 4-Step Progress Bar
        Row(
          children: List.generate(4, (idx) {
            final done = idx < _regStep;
            final active = idx == _regStep;
            return Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.only(end: idx < 3 ? 6 : 0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  height: 6,
                  decoration: BoxDecoration(
                    color: done
                        ? _emerald
                        : (active ? _red : const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _redSoft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            s.tr(
              'الخطوة ${_regStep + 1} من 4',
              'Étape ${_regStep + 1} sur 4',
            ),
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: _red,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          stepTitles[_regStep],
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w900,
            color: _ink,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          stepSubtitles[_regStep],
          style: const TextStyle(
            fontSize: 13.5,
            color: _muted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),

        // Animated Step Content
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: KeyedSubtree(
            key: ValueKey<int>(_regStep),
            child: _buildCurrentRegStepBody(s, cities),
          ),
        ),

        const SizedBox(height: 22),

        // Navigation Buttons (Back / Next or Finish)
        Row(
          children: [
            if (_regStep > 0) ...[
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _ink,
                      side: const BorderSide(color: _border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    onPressed: () => setState(() {
                      _regStep--;
                      _error = null;
                    }),
                    child: Text(
                      s.tr('السابق', 'Retour'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _regStep == 3 ? _emerald : _red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _loading
                      ? null
                      : () {
                          if (_regStep < 3) {
                            if (_validateCurrentRegStep()) {
                              HapticFeedback.selectionClick();
                              setState(() => _regStep++);
                            }
                          } else {
                            _submitRegister();
                          }
                        },
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _regStep < 3
                                  ? s.tr('الخطوة التالية', 'Continuer')
                                  : s.tr(
                                      'إنشاء الحساب والبدء 🎉',
                                      'Terminer l\'inscription 🎉',
                                    ),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              _regStep < 3
                                  ? (s.isAr
                                      ? CupertinoIcons.arrow_left
                                      : CupertinoIcons.arrow_right)
                                  : CupertinoIcons.check_mark_circled_solid,
                              size: 16,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),

        if (_regStep == 0) ...[
          const SizedBox(height: 18),
          _buildGoogleButton(s),
        ],
        const SizedBox(height: 18),
        _buildPrivacyFooterLink(s),
      ],
    );
  }

  Widget _buildCurrentRegStepBody(AppStrings s, List<dynamic> cities) {
    switch (_regStep) {
      case 0:
        return Column(
          children: [
            _buildAccountTypeCard(
              type: 'individual',
              icon: CupertinoIcons.person_crop_circle_fill,
              title: s.tr('حساب فردي (بائع ومشتري)', 'Compte Particulier'),
              subtitle: s.tr(
                'مثالي لنشر إعلاناتك الشخصية والتواصل المباشر مع المشترين مجاناً.',
                'Idéal pour vendre et acheter des biens personnels gratuitement.',
              ),
              badge: s.tr('مجاني 100%', '100% Gratuit'),
            ),
            const SizedBox(height: 12),
            _buildAccountTypeCard(
              type: 'pro',
              icon: CupertinoIcons.bag_fill,
              title: s.tr('حساب متجر احترافي (Boutique Pro)', 'Compte Boutique Pro'),
              subtitle: s.tr(
                'لتجار السيارات، العقارات، الإلكترونيات والماركات مع إحصائيات متقدمة وشارة توثيق.',
                'Pour les professionnels avec vitrine dédiée, statistiques et badge vérifié.',
              ),
              badge: 'PRO ⭐',
            ),
          ],
        );

      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldLabel(
              _accountType == 'pro'
                  ? s.tr('اسم المتجر أو الشركة', 'Nom de la boutique / société')
                  : s.tr('الاسم الكامل', 'Nom complet'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                hintText: _accountType == 'pro'
                    ? s.tr('مثال: Auto Prestige Maroc', 'Ex: Auto Prestige Maroc')
                    : s.tr('مثال: أمين العلوي', 'Ex: Amine Alaoui'),
                prefixIcon: Icon(
                  _accountType == 'pro'
                      ? CupertinoIcons.bag
                      : CupertinoIcons.person,
                  size: 19,
                ),
                filled: true,
                fillColor: _fill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildFieldLabel(
              s.tr('رقم الهاتف / الواتساب', 'Téléphone / WhatsApp'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '06XXXXXXXX',
                prefixIcon: const Icon(CupertinoIcons.phone, size: 19),
                filled: true,
                fillColor: _fill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        );

      case 2:
        final strength = _passwordStrength(_passCtrl.text);
        final strengthColors = [
          const Color(0xFFE2E8F0),
          const Color(0xFFF59E0B),
          const Color(0xFF3B82F6),
          _emerald,
        ];
        final strengthLabels = [
          s.tr('أدخل 8 حروف على الأقل', '8 caractères minimum'),
          s.tr('مقبولة', 'Acceptable'),
          s.tr('جيدة', 'Bon'),
          s.tr('قوية ومؤمنة ✓', 'Très sécurisé ✓'),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldLabel(s.tr('البريد الإلكتروني', 'Adresse e-mail')),
            const SizedBox(height: 8),
            TextField(
              controller: _loginCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'name@example.com',
                prefixIcon: const Icon(CupertinoIcons.mail, size: 19),
                filled: true,
                fillColor: _fill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildFieldLabel(s.tr('كلمة المرور', 'Mot de passe')),
            const SizedBox(height: 8),
            TextField(
              controller: _passCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                hintText: s.tr('8 حروف أو أرقام على الأقل', '8 caractères minimum'),
                prefixIcon: const Icon(CupertinoIcons.lock, size: 19),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                    size: 19,
                    color: _muted,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                filled: true,
                fillColor: _fill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(3, (i) {
                final active = strength > i;
                return Expanded(
                  child: Container(
                    margin: EdgeInsetsDirectional.only(end: i < 2 ? 6 : 0),
                    height: 5,
                    decoration: BoxDecoration(
                      color: active
                          ? strengthColors[strength]
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),
            Text(
              strengthLabels[strength],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: strength == 0 ? _muted : strengthColors[strength],
              ),
            ),
          ],
        );

      case 3:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldLabel(s.tr('مدينتك الرئيسية', 'Votre ville principale')),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              initialValue: _selectedCityId,
              decoration: InputDecoration(
                prefixIcon: const Icon(CupertinoIcons.location_solid, size: 18, color: _red),
                filled: true,
                fillColor: _fill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              items: cities.whereType<Map>().map((c) {
                final id = int.tryParse(c['id'].toString());
                final name = (s.isAr
                        ? (c['name_ar'] ?? c['name'])
                        : (c['name_fr'] ?? c['name']))
                    .toString();
                return DropdownMenuItem<int?>(
                  value: id,
                  child: Text(name),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedCityId = v),
            ),
            const SizedBox(height: 18),
            _buildFieldLabel(
              s.tr(
                'شنو الأقسام اللي كتهتم بيها؟ (لتخصيص الـ Feed)',
                'Quelles catégories vous intéressent ?',
              ),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.4,
              ),
              itemCount: _interestShowcase.length,
              itemBuilder: (context, idx) {
                final item = _interestShowcase[idx];
                final int id = item['id'] as int;
                final bool selected = _selectedInterests.contains(id);
                final String label =
                    s.isAr ? item['name_ar'] as String : item['name_fr'] as String;
                final String asset = item['asset'] as String;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (selected && _selectedInterests.length > 1) {
                        _selectedInterests.remove(id);
                      } else {
                        _selectedInterests.add(id);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? _redSoft : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? _red : _border,
                        width: selected ? 1.6 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: Image.asset(asset, fit: BoxFit.contain),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: selected ? _red : _ink,
                            ),
                          ),
                        ),
                        if (selected)
                          const Icon(
                            CupertinoIcons.check_mark_circled_solid,
                            size: 16,
                            color: _red,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
    }
  }

  Widget _buildAccountTypeCard({
    required String type,
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
  }) {
    final active = _accountType == type;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _accountType = type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: active ? _redSoft : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? _red : _border,
            width: active ? 1.8 : 1.1,
          ),
          boxShadow: [
            if (active)
              BoxShadow(
                color: _red.withValues(alpha: 0.10),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: active ? _red : _fill,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: active ? Colors.white : _ink,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: active ? _red : _ink,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: active ? _red : _fill,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: active ? Colors.white : _ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: _muted,
                      height: 1.38,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w800,
        color: _ink,
      ),
    );
  }

  Widget _buildGoogleButton(AppStrings s) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: _border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                s.tr('أو بضغطة واحدة عبر', 'Ou en un clic avec'),
                style: const TextStyle(
                  fontSize: 12.5,
                  color: _muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Expanded(child: Divider(color: _border)),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: _ink,
              side: const BorderSide(color: _border, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            onPressed: _signInWithGoogle,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEECEE),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'G',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: _red,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  s.tr('المتابعة باستخدام Google', 'Continuer avec Google'),
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyFooterLink(AppStrings s) {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PrivacyComplianceScreen(initialTab: 0),
          ),
        ),
        child: Text(
          s.tr(
            'بالمتابعة، أنت توافق على سياسة الخصوصية وحماية البيانات الخاصة بـ Apolo.ma',
            'En continuant, vous acceptez la Politique de confidentialité d\'Apolo.ma',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: _muted,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}
