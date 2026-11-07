import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import 'widgets/kinetic_widgets.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback? onSuccess;
  final bool initialRegisterMode;
  final bool initialIsLogin;
  final bool autoTriggerGoogle;

  const AuthScreen({
    super.key,
    this.onSuccess,
    this.initialRegisterMode = false,
    this.initialIsLogin = true,
    this.autoTriggerGoogle = false,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AppState _state = AppState();

  late bool _isLogin;
  int _registerStep = 0; // 0..3 (4 steps)
  String _accountType = 'individual'; // 'individual' | 'pro'
  int? _selectedCityId;
  final Set<int> _selectedCategoryIds = {1, 4};

  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _categories = [];

  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _primary = Color(0xFFE31B23);
  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _isLogin = widget.initialRegisterMode ? false : widget.initialIsLogin;
    _loadMetadata();
    if (widget.autoTriggerGoogle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _signInWithGoogle();
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMetadata() async {
    if (_state.categories.isEmpty || _state.cities.isEmpty) {
      await _state.fetchTaxonomy();
    }
    if (mounted) {
      setState(() {
        final rawCities = _state.cities
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        final rawCats = _state.categories
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _cities = rawCities.isNotEmpty ? rawCities : _fallbackCities();
        _categories = rawCats.isNotEmpty ? rawCats : _fallbackCategories();
        _selectedCityId ??= int.tryParse((_cities.first['id'] ?? 1).toString()) ?? 1;
      });
    }
  }

  List<Map<String, dynamic>> _fallbackCities() => [
        {'id': 1, 'name': 'Casablanca', 'name_fr': 'Casablanca', 'name_ar': 'الدار البيضاء'},
        {'id': 2, 'name': 'Rabat', 'name_fr': 'Rabat', 'name_ar': 'الرباط'},
        {'id': 3, 'name': 'Marrakech', 'name_fr': 'Marrakech', 'name_ar': 'مراكش'},
        {'id': 4, 'name': 'Tanger', 'name_fr': 'Tanger', 'name_ar': 'طنجة'},
        {'id': 5, 'name': 'Agadir', 'name_fr': 'Agadir', 'name_ar': 'أكادير'},
        {'id': 6, 'name': 'Fès', 'name_fr': 'Fès', 'name_ar': 'فاس'},
      ];

  List<Map<String, dynamic>> _fallbackCategories() => [
        {'id': 1, 'name': 'Véhicules', 'name_fr': 'Véhicules', 'name_ar': 'سيارات ومركبات'},
        {'id': 2, 'name': 'Immobilier', 'name_fr': 'Immobilier', 'name_ar': 'عقارات'},
        {'id': 3, 'name': 'Informatique', 'name_fr': 'Informatique', 'name_ar': 'معلوميات'},
        {'id': 4, 'name': 'Téléphones', 'name_fr': 'Téléphones', 'name_ar': 'هواتف ذكية'},
        {'id': 5, 'name': 'Maison & Déco', 'name_fr': 'Maison & Déco', 'name_ar': 'منزل وديكور'},
        {'id': 6, 'name': 'Mode & Beauté', 'name_fr': 'Mode & Beauté', 'name_ar': 'موضة وأزياء'},
      ];

  double get _passwordStrength {
    final p = _passwordCtrl.text;
    if (p.isEmpty) return 0;
    double score = 0.25;
    if (p.length >= 6) score += 0.25;
    if (p.length >= 8 && RegExp(r'[0-9]').hasMatch(p)) score += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(p) || RegExp(r'[^a-zA-Z0-9]').hasMatch(p)) {
      score += 0.25;
    }
    return score.clamp(0.0, 1.0);
  }

  String _step3DAsset() {
    if (_isLogin) return 'assets/images/auth_hero_3d.png';
    switch (_registerStep) {
      case 0:
        return 'assets/images/auth_hero_3d.png';
      case 1:
        return 'assets/images/cat_phones.png';
      case 2:
        return 'assets/images/auth_hero_3d.png';
      case 3:
        return 'assets/images/hero_car.png';
      default:
        return 'assets/images/auth_hero_3d.png';
    }
  }

  bool _validateCurrentRegisterStep(bool isAr) {
    setState(() => _error = null);
    if (_registerStep == 1) {
      if (_nameCtrl.text.trim().length < 2) {
        setState(() {
          _error = isAr
              ? 'يرجى إدخال الاسم الكامل أو اسم المتجر'
              : 'Veuillez saisir votre nom complet ou le nom de la boutique';
        });
        return false;
      }
      if (_phoneCtrl.text.trim().length < 8) {
        setState(() {
          _error = isAr
              ? 'يرجى إدخال رقم هاتف أو واتساب صحيح'
              : 'Veuillez saisir un numéro de téléphone valide';
        });
        return false;
      }
    } else if (_registerStep == 2) {
      if (!_emailCtrl.text.contains('@')) {
        setState(() {
          _error = isAr
              ? 'يرجى إدخال بريد إلكتروني صحيح'
              : 'Veuillez saisir une adresse e-mail valide';
        });
        return false;
      }
      if (_passwordCtrl.text.length < 6) {
        setState(() {
          _error = isAr
              ? 'كلمة المرور يجب أن تتكون من 6 أحرف على الأقل'
              : 'Le mot de passe doit contenir au moins 6 caractères';
        });
        return false;
      }
    }
    return true;
  }

  void _nextStepOrSubmit(bool isAr) {
    if (_isLogin) {
      _submitAuth(isAr);
      return;
    }
    if (!_validateCurrentRegisterStep(isAr)) return;
    if (_registerStep < 3) {
      setState(() => _registerStep++);
    } else {
      _submitAuth(isAr);
    }
  }

  Future<void> _submitAuth(bool isAr) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_isLogin) {
        final res = await _state.api.dio.post('/auth/login', data: {
          'email': _emailCtrl.text.trim(),
          'password': _passwordCtrl.text,
        });
        final data = res.data is Map ? res.data as Map : const {};
        final token = (data['token'] ?? data['access_token'] ?? '').toString();
        if (token.isNotEmpty) {
          final userMap = data['user'] is Map
              ? Map<String, dynamic>.from(data['user'] as Map)
              : {'email': _emailCtrl.text.trim()};
          await _state.setAuthSession(token, userMap);
          widget.onSuccess?.call();
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context, true);
          }
          return;
        }
      } else {
        await _state.saveOnboardingPreferences(
          accType: _accountType,
          cityId: _selectedCityId,
          selectedCategories: _selectedCategoryIds,
        );
        final res = await _state.api.dio.post('/auth/register', data: {
          'name': _nameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'password': _passwordCtrl.text,
          'password_confirmation': _passwordCtrl.text,
          'phone': _phoneCtrl.text.trim(),
          'city_id': _selectedCityId,
        });
        final data = res.data is Map ? res.data as Map : const {};
        final token = (data['token'] ?? data['access_token'] ?? '').toString();
        if (token.isNotEmpty) {
          final userMap = data['user'] is Map
              ? Map<String, dynamic>.from(data['user'] as Map)
              : {
                  'name': _nameCtrl.text.trim(),
                  'email': _emailCtrl.text.trim(),
                  'phone': _phoneCtrl.text.trim(),
                  'account_type': _accountType,
                };
          await _state.setAuthSession(token, userMap);
          widget.onSuccess?.call();
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context, true);
          }
          return;
        }
      }
      setState(() {
        _error = isAr ? 'تأكد من المعلومات المدخلة' : 'Vérifiez vos identifiants';
      });
    } catch (_) {
      setState(() {
        _error = isAr
            ? 'تعذر الاتصال بالخادم، تأكد من المعلومات أو جرب الدخول عبر Google'
            : 'Impossible de se connecter, vérifiez vos informations ou utilisez Google';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    final redirectUri = Uri.encodeComponent('https://apolo.ma/auth/google/callback');
    final googleOAuthUrl = Uri.parse(
      'https://accounts.google.com/o/oauth2/v2/auth'
      '?client_id=${AppConfig.googleClientId}'
      '&redirect_uri=$redirectUri'
      '&response_type=token'
      '&scope=email%20profile%20openid'
      '&prompt=select_account',
    );
    await launchUrl(googleOAuthUrl, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final isAr = s.isAr;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            children: [
              // 1. Minimal Quiet Chrome Top Navigation
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (Navigator.canPop(context) || (!_isLogin && _registerStep > 0))
                      PressableScale(
                        onTap: () {
                          if (!_isLogin && _registerStep > 0) {
                            setState(() {
                              _registerStep--;
                              _error = null;
                            });
                          } else {
                            Navigator.maybePop(context);
                          }
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Icon(
                            isAr
                                ? CupertinoIcons.chevron_right
                                : CupertinoIcons.chevron_left,
                            color: _ink,
                            size: 18,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 40),

                    // Segmented Switcher (Login vs 4-Step Register)
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0).withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildModeTab(
                            label: s.login,
                            selected: _isLogin,
                            onTap: () => setState(() {
                              _isLogin = true;
                              _error = null;
                            }),
                          ),
                          _buildModeTab(
                            label: s.register,
                            selected: !_isLogin,
                            onTap: () => setState(() {
                              _isLogin = false;
                              _error = null;
                            }),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 40),
                  ],
                ),
              ),

              // 2. Scrollable Main Stage with Floating 3D Hero Sculpture
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 350),
                              child: Floating3DIllustration(
                                key: ValueKey(_step3DAsset()),
                                assetPath: _step3DAsset(),
                                size: _isLogin ? 128 : 112,
                                fallbackIcon: CupertinoIcons.shield_fill,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          if (_isLogin)
                            _buildLoginStage(s, isAr)
                          else
                            _buildRegisterWizardStage(s, isAr),
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
    );
  }

  Widget _buildModeTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _ink.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? _ink : _muted,
          ),
        ),
      ),
    );
  }

  /// High-Craft Login Stage
  Widget _buildLoginStage(AppStrings s, bool isAr) {
    return ScrollReveal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isAr ? 'الدخول إلى حسابك في Apolo' : 'Accédez à votre espace Apolo',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _ink,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isAr
                ? 'تتبع إعلاناتك، تواصل مع المشترين، وادخل إلى لوحة الإحصائيات.'
                : 'Gérez vos annonces, répondez aux acheteurs et suivez vos statistiques.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: _muted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 22),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: _ink.withValues(alpha: 0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildGoogleButton(isAr),
                const SizedBox(height: 18),
                _buildDivider(isAr ? 'أو بالبريد الإلكتروني' : 'ou avec votre e-mail'),
                const SizedBox(height: 18),
                if (_error != null) _buildErrorBanner(_error!),
                _buildLabeledField(
                  label: isAr ? 'البريد الإلكتروني' : 'Adresse e-mail',
                  controller: _emailCtrl,
                  hint: 'nom@exemple.ma',
                  icon: CupertinoIcons.mail,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                _buildLabeledField(
                  label: isAr ? 'كلمة المرور' : 'Mot de passe',
                  controller: _passwordCtrl,
                  hint: '••••••••',
                  icon: CupertinoIcons.lock,
                  obscure: _obscurePassword,
                  suffix: IconButton(
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                      size: 18,
                      color: _muted,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildPrimaryButton(
                  label: s.login,
                  onTap: () => _nextStepOrSubmit(isAr),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// High-Craft 4-Step Registration Wizard
  Widget _buildRegisterWizardStage(AppStrings s, bool isAr) {
    final stepTitles = isAr
        ? [
            'اختر نوع حسابك',
            'معلومات التواصل المباشر',
            'حماية وتأمين الحساب',
            'تخصيص اهتماماتك والـ Feed',
          ]
        : [
            'Choisissez votre profil',
            'Coordonnées de contact',
            'Sécurisez votre compte',
            'Personnalisez votre flux',
          ];

    final stepSubtitles = isAr
        ? [
            'حدد ما إذا كنت تبيع كفرد أو تملك متجراً احترافياً',
            'الاسم ورقم الهاتف أو الواتساب لاستقبال رسائل المشترين',
            'بريدك الإلكتروني وكلمة مرور قوية لحماية إعلاناتك',
            'اختر مدينتك والتصنيفات التي تهمك لتدريب الخوارزمية',
          ]
        : [
            'Vendez en tant que particulier ou créez votre Boutique Pro',
            'Votre nom et numéro WhatsApp pour recevoir les offres',
            'Votre adresse e-mail et un mot de passe sécurisé',
            'Sélectionnez votre ville et vos catégories favorites',
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          stepTitles[_registerStep],
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
            color: _ink,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          stepSubtitles[_registerStep],
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: _muted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: List.generate(4, (idx) {
            final active = idx <= _registerStep;
            final current = idx == _registerStep;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                margin: EdgeInsetsDirectional.only(end: idx < 3 ? 6 : 0),
                height: 6,
                decoration: BoxDecoration(
                  color: active ? _primary : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: current
                      ? [
                          BoxShadow(
                            color: _primary.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: _ink.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) _buildErrorBanner(_error!),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: _buildRegisterStepBody(s, isAr),
              ),
              const SizedBox(height: 20),
              _buildPrimaryButton(
                label: _registerStep < 3
                    ? (isAr ? 'الخطوة التالية' : 'Continuer')
                    : (isAr ? 'إنهاء التسجيل وبدء الاستخدام' : 'Créer mon compte'),
                onTap: () => _nextStepOrSubmit(isAr),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterStepBody(AppStrings s, bool isAr) {
    switch (_registerStep) {
      case 0:
        return Column(
          key: const ValueKey('reg_step_0'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAccountTypeOption(
              type: 'individual',
              title: isAr ? 'حساب بائع ومشتري فردي' : 'Compte Particulier',
              subtitle: isAr
                  ? 'نشر مجاني وسريع للسلع الشخصية، السيارات، والعقارات.'
                  : 'Publiez gratuitement vos annonces personnelles en quelques secondes.',
              badge: isAr ? 'مجاني' : 'Gratuit',
              icon: CupertinoIcons.person_crop_circle,
            ),
            const SizedBox(height: 12),
            _buildAccountTypeOption(
              type: 'pro',
              title: isAr ? 'حساب متجر احترافي (Boutique Pro)' : 'Boutique Pro Certifiée',
              subtitle: isAr
                  ? 'شارة توثيق رسمية، لوحة إحصائيات متقدمة، وصفحة متجر خاصة.'
                  : 'Badge vérifié, statistiques avancées et vitrine dédiée.',
              badge: 'PRO',
              icon: CupertinoIcons.bag_fill,
            ),
            const SizedBox(height: 18),
            _buildDivider(isAr ? 'أو التسجيل الفوري' : 'ou inscription rapide'),
            const SizedBox(height: 14),
            _buildGoogleButton(isAr),
          ],
        );

      case 1:
        final isStore = _accountType == 'pro';
        return Column(
          key: const ValueKey('reg_step_1'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLabeledField(
              label: isStore
                  ? (isAr ? 'اسم المتجر أو الشركة' : 'Nom de la boutique')
                  : (isAr ? 'الاسم الكامل' : 'Nom complet'),
              controller: _nameCtrl,
              hint: isStore
                  ? (isAr ? 'مثال: Auto Luxury Maroc' : 'Ex: Auto Luxury Maroc')
                  : (isAr ? 'مثال: أمين العلوي' : 'Ex: Amine Alaoui'),
              icon: isStore ? CupertinoIcons.bag : CupertinoIcons.person,
            ),
            const SizedBox(height: 14),
            _buildLabeledField(
              label: isAr ? 'رقم الهاتف / الواتساب' : 'Téléphone / WhatsApp',
              controller: _phoneCtrl,
              hint: '06 00 00 00 00',
              icon: CupertinoIcons.phone,
              keyboardType: TextInputType.phone,
            ),
          ],
        );

      case 2:
        final strength = _passwordStrength;
        final strengthColor = strength < 0.5
            ? _primary
            : (strength < 0.75 ? const Color(0xFFD97706) : const Color(0xFF16A34A));
        return Column(
          key: const ValueKey('reg_step_2'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLabeledField(
              label: isAr ? 'البريد الإلكتروني' : 'Adresse e-mail',
              controller: _emailCtrl,
              hint: 'contact@exemple.ma',
              icon: CupertinoIcons.mail,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            _buildLabeledField(
              label: isAr ? 'كلمة المرور' : 'Mot de passe',
              controller: _passwordCtrl,
              hint: isAr ? '6 أحرف أو أرقام على الأقل' : '6 caractères minimum',
              icon: CupertinoIcons.lock,
              obscure: _obscurePassword,
              onChanged: (_) => setState(() {}),
              suffix: IconButton(
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                  size: 18,
                  color: _muted,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: strength,
                minHeight: 5,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
              ),
            ),
          ],
        );

      case 3:
      default:
        return Column(
          key: const ValueKey('reg_step_3'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAr ? 'مدينتك الرئيسية' : 'Votre ville principale',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _selectedCityId,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              items: _cities.map((c) {
                final cid = int.tryParse((c['id'] ?? 1).toString()) ?? 1;
                final cname = (isAr
                        ? (c['name_ar'] ?? c['name'] ?? '')
                        : (c['name_fr'] ?? c['name'] ?? ''))
                    .toString();
                return DropdownMenuItem<int>(
                  value: cid,
                  child: Text(
                    cname,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedCityId = v),
            ),
            const SizedBox(height: 16),
            Text(
              isAr
                  ? 'اختر التصنيفات التي تهمك (لتخصيص الـ Feed)'
                  : 'Vos catégories préférées (pour personnaliser le flux)',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.take(8).map((cat) {
                final catId = int.tryParse((cat['id'] ?? 1).toString()) ?? 1;
                final selected = _selectedCategoryIds.contains(catId);
                final asset = _state.assetForCategory(cat);
                final label = _state.formatCategoryLabel(cat);
                return PressableScale(
                  onTap: () {
                    setState(() {
                      if (selected && _selectedCategoryIds.length > 1) {
                        _selectedCategoryIds.remove(catId);
                      } else {
                        _selectedCategoryIds.add(catId);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected ? _ink : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? _ink : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: Image.asset(
                            asset,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              CupertinoIcons.cube_box,
                              size: 14,
                              color: selected ? Colors.white : _ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : _ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
    }
  }

  Widget _buildAccountTypeOption({
    required String type,
    required String title,
    required String subtitle,
    required String badge,
    required IconData icon,
  }) {
    final selected = _accountType == type;
    return PressableScale(
      onTap: () => setState(() => _accountType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _primary : const Color(0xFFE2E8F0),
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected ? _primary : Colors.white,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: selected ? _primary : const Color(0xFFE2E8F0),
                ),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : _ink,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: selected ? _primary : _ink,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: _muted,
                      height: 1.35,
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

  Widget _buildLabeledField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffix,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _ink,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(icon, size: 18, color: _muted),
            suffixIcon: suffix,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleButton(bool isAr) {
    return PressableScale(
      onTap: _signInWithGoogle,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: const Text(
                'G',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: _primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              isAr ? 'المتابعة السريعة بحساب Google' : 'Continuer avec Google',
              style: const TextStyle(
                color: _ink,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return PressableScale(
      onTap: _loading ? null : onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: _primary,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.2,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider(String text) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: _muted,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_circle_fill,
            color: _primary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
