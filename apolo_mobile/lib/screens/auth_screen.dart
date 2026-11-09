import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import 'post_ad_screen.dart';
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

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final AppState _state = AppState();

  late bool _isLogin;
  // Flow steps:
  // Step 0: Credentials (Name, Phone, Email, Password)
  // Step 1: OTP Email Verification (6-digit code)
  // Step 2: Account Type (Individual vs Pro)
  // Step 3: Preferred City
  // Step 4: Category Interests
  int _registerStep = 0;
  bool _showCelebration = false;

  String _accountType = 'individual'; // 'individual' | 'pro'
  int _selectedCityId = 1;
  final Set<int> _selectedCategoryIds = {1, 4};

  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  String _tempToken = '';
  Map<String, dynamic> _tempUserMap = {};

  int _resendCountdown = 0;
  Timer? _countdownTimer;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  late final AnimationController _celebrationCtrl;

  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _categories = [];

  static const Color _primary = Color(0xFFE31B23);
  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF8A94A6);
  static const Color _surface = Color(0xFFF5F6F8);

  @override
  void initState() {
    super.initState();
    _celebrationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
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
    _countdownTimer?.cancel();
    _celebrationCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _countdownTimer?.cancel();
    setState(() => _resendCountdown = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown <= 1) {
        timer.cancel();
        setState(() => _resendCountdown = 0);
      } else {
        setState(() => _resendCountdown--);
      }
    });
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
        _selectedCityId = int.tryParse((_cities.first['id'] ?? 1).toString()) ?? 1;
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

  int get _passwordStrengthBars {
    final p = _passwordCtrl.text;
    if (p.isEmpty) return 0;
    int bars = 1;
    if (p.length >= 6) bars++;
    if (p.length >= 8 && RegExp(r'[0-9]').hasMatch(p)) bars++;
    if (RegExp(r'[A-Z]').hasMatch(p) || RegExp(r'[^a-zA-Z0-9]').hasMatch(p)) {
      bars++;
    }
    return bars.clamp(0, 4);
  }

  String _step3DAsset() {
    if (_isLogin) return 'assets/images/auth_hero_3d.png';
    switch (_registerStep) {
      case 0:
        return 'assets/images/auth_hero_3d.png';
      case 1:
        return 'assets/images/cat_phones.png';
      case 2:
        return 'assets/images/cat_jobs.png';
      case 3:
        return 'assets/images/cat_realestate.png';
      case 4:
        return 'assets/images/cat_vehicles.png';
      default:
        return 'assets/images/auth_hero_3d.png';
    }
  }

  bool _validateCredentials(bool isAr) {
    setState(() => _error = null);
    if (_nameCtrl.text.trim().length < 2) {
      setState(() {
        _error = isAr
            ? 'يرجى إدخال الاسم الكامل'
            : 'Veuillez saisir votre nom complet';
      });
      return false;
    }
    if (_phoneCtrl.text.trim().length < 8) {
      setState(() {
        _error = isAr
            ? 'يرجى إدخال رقم هاتف صحيح'
            : 'Veuillez saisir un numéro de téléphone valide';
      });
      return false;
    }
    if (!_emailCtrl.text.contains('@') || !_emailCtrl.text.contains('.')) {
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
            : '6 caractères minimum requis pour le mot de passe';
      });
      return false;
    }
    if (_confirmPasswordCtrl.text.isNotEmpty &&
        _confirmPasswordCtrl.text != _passwordCtrl.text) {
      setState(() {
        _error = isAr
            ? 'تأكيد كلمة المرور غير متطابق'
            : 'Les mots de passe ne correspondent pas';
      });
      return false;
    }
    return true;
  }

  void _nextStepOrSubmit(bool isAr) {
    if (_isLogin) {
      if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
        setState(() {
          _error = isAr
              ? 'يرجى إدخال البريد الإلكتروني وكلمة المرور'
              : 'Veuillez saisir votre e-mail et mot de passe';
        });
        return;
      }
      _submitLogin(isAr);
      return;
    }

    if (_registerStep == 0) {
      if (!_validateCredentials(isAr)) return;
      _submitRegister(isAr);
    } else if (_registerStep == 1) {
      _verifyOtp(isAr);
    } else if (_registerStep == 2) {
      setState(() => _registerStep = 3);
    } else if (_registerStep == 3) {
      setState(() => _registerStep = 4);
    } else if (_registerStep == 4) {
      _submitOnboarding(isAr);
    }
  }

  Future<void> _submitLogin(bool isAr) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _state.api.dio.post('/auth/login', data: {
        'login': _emailCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'password': _passwordCtrl.text,
      });

      final data = res.data is Map ? res.data as Map : const {};
      final subData = data['data'] is Map ? data['data'] as Map : data;
      final token = (subData['token'] ?? subData['access_token'] ?? data['token'] ?? data['access_token'] ?? '').toString();

      if (token.isNotEmpty) {
        final userMap = subData['user'] is Map
            ? Map<String, dynamic>.from(subData['user'] as Map)
            : (data['user'] is Map ? Map<String, dynamic>.from(data['user'] as Map) : {'email': _emailCtrl.text.trim()});

        _tempToken = token;
        _tempUserMap = userMap;

        // Check if OTP verification is required
        final bool requiresOtp = subData['requires_otp'] == true || data['requires_otp'] == true || userMap['email_verified_at'] == null;
        if (requiresOtp) {
          _state.api.setToken(token);
          setState(() {
            _loading = false;
            _isLogin = false;
            _registerStep = 1; // Go to OTP step
          });
          _startResendTimer();
          return;
        }

        // Check if onboarding is completed
        final bool onboardingDone = userMap['onboarding_completed'] == true || userMap['onboarding_completed'] == 1;
        if (!onboardingDone) {
          _state.api.setToken(token);
          setState(() {
            _loading = false;
            _isLogin = false;
            _registerStep = 2; // Go to Onboarding step
          });
          return;
        }

        await _state.setAuthSession(token, userMap);
        await _triggerCelebrationAndFinish();
      } else {
        setState(() {
          _error = (data['message'] ?? (isAr ? 'بيانات الدخول غير صحيحة' : 'Identifiants incorrects')).toString();
        });
      }
    } catch (e) {
      _handleApiError(e, isAr);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitRegister(bool isAr) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final enteredName = _nameCtrl.text.trim();
    final enteredEmail = _emailCtrl.text.trim();
    final enteredPhone = _phoneCtrl.text.trim();
    final password = _passwordCtrl.text;

    try {
      final res = await _state.api.dio.post('/auth/register', data: {
        'name': enteredName,
        'email': enteredEmail,
        'phone': enteredPhone,
        'password': password,
        'password_confirmation': _confirmPasswordCtrl.text.isNotEmpty ? _confirmPasswordCtrl.text : password,
        'referral_source': 'mobile_app',
      });

      final data = res.data is Map ? res.data as Map : const {};
      final subData = data['data'] is Map ? data['data'] as Map : data;
      final token = (subData['token'] ?? subData['access_token'] ?? data['token'] ?? data['access_token'] ?? '').toString();

      if (token.isNotEmpty) {
        final userMap = subData['user'] is Map
            ? Map<String, dynamic>.from(subData['user'] as Map)
            : {'name': enteredName, 'email': enteredEmail, 'phone': enteredPhone};

        _tempToken = token;
        _tempUserMap = userMap;
        _state.api.setToken(token);

        setState(() {
          _registerStep = 1; // Transition to OTP Verification Step!
          _loading = false;
          _error = null;
        });
        _startResendTimer();
      } else {
        setState(() {
          _error = (data['message'] ?? (isAr ? 'فشل إنشاء الحساب' : 'Échec de l’inscription')).toString();
        });
      }
    } catch (e) {
      _handleApiError(e, isAr);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp(bool isAr) async {
    final code = _otpCtrl.text.trim();
    if (code.length != 6) {
      setState(() {
        _error = isAr
            ? 'يرجى إدخال رمز التحقق المكون من 6 أرقام'
            : 'Veuillez saisir le code complet à 6 chiffres';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_tempToken.isNotEmpty) {
        _state.api.setToken(_tempToken);
      }

      final res = await _state.api.dio.post('/auth/otp/verify', data: {
        'code': code,
      });

      final data = res.data is Map ? res.data as Map : const {};
      if (data['status'] == 'success') {
        HapticFeedback.mediumImpact();
        setState(() {
          _registerStep = 2; // Advanced to Onboarding: Step 2 (Account Type)!
          _error = null;
        });
      } else {
        setState(() {
          _error = (data['message'] ?? (isAr ? 'رمز التحقق غير صحيح أو انتهت صلاحيته' : 'Code OTP incorrect ou expiré')).toString();
        });
      }
    } catch (e) {
      _handleApiError(e, isAr);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendOtp(bool isAr) async {
    if (_resendCountdown > 0) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_tempToken.isNotEmpty) {
        _state.api.setToken(_tempToken);
      }
      final res = await _state.api.dio.post('/auth/otp/resend');
      final data = res.data is Map ? res.data as Map : const {};
      final msg = (data['message'] ?? (isAr ? 'تم إرسال رمز جديد إلى بريدك الإلكتروني' : 'Un nouveau code a été envoyé')).toString();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _startResendTimer();
    } catch (e) {
      _handleApiError(e, isAr);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitOnboarding(bool isAr) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_tempToken.isNotEmpty) {
        _state.api.setToken(_tempToken);
      }

      // Persist onboarding & category interests in database
      await _state.api.dio.post('/auth/onboarding', data: {
        'account_type': _accountType,
        'preferred_city_id': _selectedCityId,
        'category_interests': _selectedCategoryIds.toList(),
      });

      // Save local preferences
      await _state.saveOnboardingPreferences(
        accType: _accountType,
        cityId: _selectedCityId,
        selectedCategories: _selectedCategoryIds,
      );

      final enteredName = _nameCtrl.text.trim().isNotEmpty
          ? _nameCtrl.text.trim()
          : (_emailCtrl.text.contains('@') ? _emailCtrl.text.split('@').first : 'Apolo User');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('apolo_profile_name', enteredName);
      if (_phoneCtrl.text.trim().isNotEmpty) {
        await prefs.setString('apolo_profile_phone', _phoneCtrl.text.trim());
      }

      _tempUserMap['account_type'] = _accountType;
      _tempUserMap['preferred_city_id'] = _selectedCityId;
      _tempUserMap['category_interests'] = _selectedCategoryIds.toList();
      _tempUserMap['onboarding_completed'] = true;

      await _state.setAuthSession(_tempToken, _tempUserMap);
      await _triggerCelebrationAndFinish();
    } catch (e) {
      _handleApiError(e, isAr);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _handleApiError(dynamic e, bool isAr) {
    if (!mounted) return;
    String errMsg = isAr ? 'تعذر إتمام العملية، يرجى المحاولة ثانية' : 'Une erreur s’est produite';
    try {
      final dynamic dynErr = e;
      if (dynErr.response?.data is Map) {
        final rData = dynErr.response.data;
        if (rData['message'] != null) {
          errMsg = rData['message'].toString();
        } else if (rData['errors'] is Map) {
          final firstKey = (rData['errors'] as Map).keys.first;
          final errList = (rData['errors'] as Map)[firstKey];
          if (errList is List && errList.isNotEmpty) {
            errMsg = errList.first.toString();
          }
        }
      }
    } catch (_) {}
    setState(() => _error = errMsg);
  }

  Future<void> _triggerCelebrationAndFinish() async {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _loading = false;
      _showCelebration = true;
    });
    _celebrationCtrl.repeat();
  }

  void _finishAndExit() {
    _celebrationCtrl.stop();
    widget.onSuccess?.call();
    if (Navigator.canPop(context)) {
      Navigator.pop(context, true);
    }
  }

  void _finishAndGoToPostAd() {
    _celebrationCtrl.stop();
    widget.onSuccess?.call();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PostAdScreen()),
    );
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
        backgroundColor: Colors.white,
        body: SafeArea(
          child: _showCelebration
              ? _buildCelebrationStage(isAr)
              : Column(
                  children: [
                    // 1. Top Bar (Back + 5-Step Indicator in Register Mode)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          PressableScale(
                            onTap: () {
                              if (!_isLogin && _registerStep > 0) {
                                setState(() {
                                  _registerStep--;
                                  _error = null;
                                });
                              } else if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: _surface,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isAr
                                    ? CupertinoIcons.chevron_right
                                    : CupertinoIcons.chevron_left,
                                color: _ink,
                                size: 19,
                              ),
                            ),
                          ),

                          // Step indicator dots for the 5-step registration wizard
                          if (!_isLogin)
                            Row(
                              children: List.generate(5, (idx) {
                                final active = idx <= _registerStep;
                                final current = idx == _registerStep;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 260),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: current ? 24 : 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: active ? _primary : _surface,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                );
                              }),
                            )
                          else
                            const SizedBox.shrink(),

                          SizedBox(
                            width: 44,
                            child: !_isLogin
                                ? Text(
                                    '${_registerStep + 1}/5',
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: _muted,
                                      fontFeatures: [FontFeature.tabularFigures()],
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),

                    // 2. Main Content Area
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Floating 3D Sculpture
                                Center(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 350),
                                    child: Floating3DIllustration(
                                      key: ValueKey('${_isLogin}_$_registerStep'),
                                      assetPath: _step3DAsset(),
                                      size: _isLogin ? 132 : 122,
                                      fallbackIcon: CupertinoIcons.shield_fill,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),

                                if (_isLogin)
                                  _buildMinimalLoginStage(s, isAr)
                                else
                                  _buildMinimalRegisterStepStage(s, isAr),
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

  /// Login View
  Widget _buildMinimalLoginStage(AppStrings s, bool isAr) {
    return ScrollReveal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isAr ? 'مرحباً بك مجدداً' : 'Bon retour sur Apolo',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: _ink,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isAr
                ? 'سجل دخولك لمتابعة إعلاناتك والرد على المشترين'
                : 'Connectez-vous pour gérer vos annonces et messages',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: _muted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),

          if (_error != null) _buildErrorBanner(_error!),

          _buildSoftField(
            label: isAr ? 'البريد الإلكتروني' : 'Adresse e-mail',
            controller: _emailCtrl,
            hint: 'nom@exemple.ma',
            icon: CupertinoIcons.mail,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildSoftField(
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

          const SizedBox(height: 28),

          _buildPrimaryAction(
            label: s.login,
            onTap: () => _nextStepOrSubmit(isAr),
          ),

          const SizedBox(height: 14),

          _buildGooglePillButton(isAr),

          const SizedBox(height: 32),

          Center(
            child: GestureDetector(
              onTap: () => setState(() {
                _isLogin = false;
                _registerStep = 0;
                _error = null;
              }),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: _muted,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppConfig.fontPrimary,
                  ),
                  children: [
                    TextSpan(
                      text: isAr ? 'ما عندكش حساب؟ ' : 'Pas encore de compte ? ',
                    ),
                    TextSpan(
                      text: isAr ? 'أنشئ حسابك الآن' : 'Créer un compte',
                      style: const TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 5-Step Registration Wizard
  Widget _buildMinimalRegisterStepStage(AppStrings s, bool isAr) {
    final titles = isAr
        ? [
            'أنشئ حسابك الجديد',
            'تأكيد البريد الإلكتروني (OTP)',
            'كيفاش بغيتي تستخدم Apolo؟',
            'مدينتك المفضلة',
            'شنو اللي كيهتم بيه؟',
          ]
        : [
            'Créer votre compte',
            'Vérification par code OTP',
            'Type de compte',
            'Votre ville principale',
            'Vos centres d’intérêt',
          ];

    final subtitles = isAr
        ? [
            'أدخل بياناتك للانضمام إلى أكبر منصة إعلانات بالمغرب',
            'أدخل رمز التحقق المكون من 6 أرقام المرسل إلى بريدك',
            'اختر نوع الحساب المناسب لنشاطك',
            'باش نظهرو ليك أفضل العروض والهمزات القريبة منك',
            'اختر الأقسام المفضلة لتدريب خوارزمية خلاصتك',
          ]
        : [
            'Rejoignez la plateforme d’annonces numéro 1 au Maroc',
            'Entrez le code à 6 chiffres envoyé à votre adresse e-mail',
            'Choisissez le profil adapté à votre activité',
            'Pour afficher en priorité les offres proches de chez vous',
            'Sélectionnez vos catégories préférées',
          ];

    final ctaLabels = isAr
        ? [
            'إنشاء الحساب ومتابعة',
            'تأكيد رمز التحقق',
            'متابعة',
            'متابعة',
            'إنهاء وحفظ الاهتمامات',
          ]
        : [
            'Créer mon compte',
            'Vérifier le code',
            'Continuer',
            'Continuer',
            'Enregistrer et Explorer',
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          titles[_registerStep],
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _ink,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitles[_registerStep],
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13.5,
            color: _muted,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 28),

        if (_error != null) _buildErrorBanner(_error!),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: _buildStepContent(isAr),
        ),

        const SizedBox(height: 28),

        _buildPrimaryAction(
          label: ctaLabels[_registerStep],
          onTap: () => _nextStepOrSubmit(isAr),
        ),

        if (_registerStep == 0) ...[
          const SizedBox(height: 14),
          _buildGooglePillButton(isAr),
        ],

        const SizedBox(height: 28),

        Center(
          child: GestureDetector(
            onTap: () => setState(() {
              _isLogin = true;
              _error = null;
            }),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 13.5,
                  color: _muted,
                  fontWeight: FontWeight.w500,
                  fontFamily: AppConfig.fontPrimary,
                ),
                children: [
                  TextSpan(
                    text: isAr ? 'عندك حساب من قبل؟ ' : 'Déjà inscrit ? ',
                  ),
                  TextSpan(
                    text: s.login,
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent(bool isAr) {
    switch (_registerStep) {
      // Step 0: User Credentials
      case 0:
        final bars = _passwordStrengthBars;
        return Column(
          key: const ValueKey('step_0_credentials'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSoftField(
              label: isAr ? 'الاسم الكامل' : 'Nom complet',
              controller: _nameCtrl,
              hint: isAr ? 'مثال: أمين العلوي' : 'Ex: Amine Alaoui',
              icon: CupertinoIcons.person,
            ),
            const SizedBox(height: 14),
            _buildSoftField(
              label: isAr ? 'رقم الهاتف / واتساب' : 'Téléphone / WhatsApp',
              controller: _phoneCtrl,
              hint: '06 00 00 00 00',
              icon: CupertinoIcons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            _buildSoftField(
              label: isAr ? 'البريد الإلكتروني' : 'Adresse e-mail',
              controller: _emailCtrl,
              hint: 'contact@exemple.ma',
              icon: CupertinoIcons.mail,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            _buildSoftField(
              label: isAr ? 'كلمة المرور' : 'Mot de passe',
              controller: _passwordCtrl,
              hint: isAr ? '6 أحرف على الأقل' : '6 caractères minimum',
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
            // Password Strength Indicator
            Row(
              children: List.generate(4, (idx) {
                final active = idx < bars;
                final barColor = bars <= 1
                    ? _primary
                    : (bars <= 2 ? const Color(0xFFF59E0B) : const Color(0xFF16A34A));
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: EdgeInsetsDirectional.only(end: idx < 3 ? 6 : 0),
                    height: 4,
                    decoration: BoxDecoration(
                      color: active ? barColor : _surface,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),
            _buildSoftField(
              label: isAr ? 'تأكيد كلمة المرور' : 'Confirmer le mot de passe',
              controller: _confirmPasswordCtrl,
              hint: isAr ? 'أعد كتابة كلمة المرور' : 'Retapez le mot de passe',
              icon: CupertinoIcons.lock_fill,
              obscure: true,
            ),
          ],
        );

      // Step 1: Email OTP Verification
      case 1:
        return Column(
          key: const ValueKey('step_1_otp'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.mail_solid,
                    color: Color(0xFF2563EB),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr ? 'تم إرسال الرمز إلى بريدك الإلكتروني:' : 'Code envoyé à votre e-mail :',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1E40AF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _emailCtrl.text.trim(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1E3A8A),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isAr ? 'رمز التحقق (6 أرقام)' : 'Code de vérification (6 chiffres)',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _muted,
              ),
            ),
            const SizedBox(height: 12),
            // Formatted 6-digit OTP Box
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
              ),
              alignment: Alignment.center,
              child: TextField(
                controller: _otpCtrl,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 16,
                  color: _ink,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  hintText: '••••••',
                  hintStyle: TextStyle(
                    fontSize: 24,
                    letterSpacing: 12,
                    color: _muted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isAr ? 'ما وصلكش الرمز؟ ' : 'Vous n’avez rien reçu ? ',
                  style: const TextStyle(fontSize: 13, color: _muted),
                ),
                GestureDetector(
                  onTap: _resendCountdown == 0 ? () => _resendOtp(isAr) : null,
                  child: Text(
                    _resendCountdown > 0
                        ? (isAr ? 'إعادة الإرسال بعد $_resendCountdownث' : 'Renvoyer dans ${_resendCountdown}s')
                        : (isAr ? 'إعادة إرسال الرمز' : 'Renvoyer le code'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _resendCountdown > 0 ? _muted : _primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );

      // Step 2: Account Type
      case 2:
        return Column(
          key: const ValueKey('step_2_account_type'),
          children: [
            _buildCleanAccountCard(
              type: 'individual',
              title: isAr ? 'حساب شخصي' : 'Compte Particulier',
              subtitle: isAr
                  ? 'للبيع والشراء الشخصي، عروض يومية وتواصل مباشر مع المشترين'
                  : 'Vendez et achetez librement entre particuliers au Maroc',
              icon: CupertinoIcons.person_fill,
            ),
            const SizedBox(height: 14),
            _buildCleanAccountCard(
              type: 'pro',
              title: isAr ? 'متجر احترافي (Boutique Pro)' : 'Boutique Pro Certifiée',
              subtitle: isAr
                  ? 'صفحة متجر موثقة، إحصائيات متقدمة، وأولوية في الظهور'
                  : 'Vitrine officielle vérifiée et statistiques avancées',
              icon: CupertinoIcons.bag_fill,
              badge: 'PRO',
            ),
          ],
        );

      // Step 3: Preferred City
      case 3:
        return Column(
          key: const ValueKey('step_3_city'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAr ? 'اختر مدينتك الرئيسية' : 'Sélectionnez votre ville',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _muted,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: _cities.map((c) {
                final cid = int.tryParse((c['id'] ?? 1).toString()) ?? 1;
                final cname = (isAr
                        ? (c['name_ar'] ?? c['name'] ?? '')
                        : (c['name_fr'] ?? c['name'] ?? ''))
                    .toString();
                final selected = _selectedCityId == cid;
                return PressableScale(
                  onTap: () => setState(() => _selectedCityId = cid),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? _ink : _surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selected ? _ink : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      cname,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: selected ? Colors.white : _ink,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );

      // Step 4: Category Interests (Interactive 3D Bento Grid)
      case 4:
      default:
        return Column(
          key: const ValueKey('step_4_categories'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAr
                  ? 'اختر الأقسام التي تهمك لتخصيص الخلاصات'
                  : 'Sélectionnez vos catégories favorites',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _muted,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: math.min(8, _categories.length),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.3,
              ),
              itemBuilder: (context, idx) {
                final cat = _categories[idx];
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? _ink : _surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? _ink : const Color(0xFFE2E8F0),
                        width: selected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 34,
                          height: 34,
                          child: Image.asset(
                            asset,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              CupertinoIcons.cube_box,
                              size: 22,
                              color: _muted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: selected ? Colors.white : _ink,
                            ),
                          ),
                        ),
                        if (selected)
                          const Icon(
                            CupertinoIcons.checkmark_circle_fill,
                            size: 16,
                            color: Color(0xFF10B981),
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

  Widget _buildCleanAccountCard({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
    String? badge,
  }) {
    final selected = _accountType == type;
    return PressableScale(
      onTap: () => setState(() => _accountType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? _ink : _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _ink : const Color(0xFFE2E8F0),
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: selected ? Colors.white.withValues(alpha: 0.14) : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : _ink,
                size: 21,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: selected ? Colors.white : _ink,
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: selected ? Colors.white.withValues(alpha: 0.78) : _muted,
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

  Widget _buildSoftField({
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _muted,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _ink,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: _muted.withValues(alpha: 0.65),
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(icon, size: 19, color: _muted),
            suffixIcon: suffix,
            filled: true,
            fillColor: _surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _ink, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryAction({
    required String label,
    required VoidCallback onTap,
  }) {
    return PressableScale(
      onTap: _loading ? null : onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: _primary,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.3,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }

  Widget _buildGooglePillButton(bool isAr) {
    return PressableScale(
      onTap: _signInWithGoogle,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
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
              isAr ? 'المتابعة السريعة بـ Google' : 'Continuer avec Google',
              style: const TextStyle(
                color: _ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_circle_fill,
            color: _primary,
            size: 17,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _primary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCelebrationStage(bool isAr) {
    final displayName = _nameCtrl.text.trim().isNotEmpty
        ? _nameCtrl.text.trim()
        : (_state.currentUser?['name']?.toString() ?? (isAr ? 'أمين' : 'Amine'));

    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _celebrationCtrl,
            builder: (context, _) {
              return CustomPaint(
                painter: _AuthCelebrationConfettiPainter(
                  progress: _celebrationCtrl.value,
                ),
                size: Size.infinite,
              );
            },
          ),
        ),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 700),
                curve: Curves.elasticOut,
                builder: (context, scaleVal, child) {
                  return Transform.scale(
                    scale: 0.82 + (0.18 * scaleVal),
                    child: child,
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 210,
                      height: 210,
                      child: AnimatedBuilder(
                        animation: _celebrationCtrl,
                        builder: (context, _) {
                          final pulse = math.sin(_celebrationCtrl.value * math.pi * 2);
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Transform.scale(
                                scale: 1.0 + (pulse.abs() * 0.14),
                                child: Container(
                                  width: 176,
                                  height: 176,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        _primary.withValues(alpha: 0.16),
                                        const Color(0xFF10B981).withValues(alpha: 0.08),
                                        Colors.white.withValues(alpha: 0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              ...List.generate(4, (i) {
                                final angle = (_celebrationCtrl.value * math.pi * 2) +
                                    (i * math.pi / 2);
                                final dx = math.cos(angle) * 78;
                                final dy = math.sin(angle) * 68;
                                const emojis = ['🎉', '✨', '🎊', '🚀'];
                                return Transform.translate(
                                  offset: Offset(dx, dy),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _ink.withValues(alpha: 0.08),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      emojis[i],
                                      style: const TextStyle(fontSize: 17),
                                    ),
                                  ),
                                );
                              }),
                              const Floating3DIllustration(
                                assetPath: 'assets/images/auth_hero_3d.png',
                                size: 146,
                              ),
                              Positioned(
                                bottom: 14,
                                right: 24,
                                child: Transform.rotate(
                                  angle: pulse * 0.18,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      borderRadius: BorderRadius.circular(999),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF10B981)
                                              .withValues(alpha: 0.35),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          CupertinoIcons.checkmark_seal_fill,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          '100%',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.checkmark_alt_circle_fill,
                            color: Color(0xFF16A34A),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isLogin
                                ? (isAr ? 'تم تسجيل الدخول بنجاح 🎉' : 'Connexion réussie 🎉')
                                : (isAr ? 'مبروك! حسابك واجد 100% 🎉' : 'Félicitations ! Compte activé 🎉'),
                            style: const TextStyle(
                              color: Color(0xFF15803D),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isAr ? 'مرحباً بك، $displayName 👋' : 'Bienvenue, $displayName 👋',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        color: _ink,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isAr
                          ? 'تجهز الـ Feed الذكي ديالك على حساب اهتماماتك ومدينتك. تقدر دابا تحط أول إعلان مجاناً أو تصفح همزات اليوم!'
                          : 'Votre flux intelligent est configuré. Publiez votre première annonce gratuitement ou explorez les offres !',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: _muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 28),
                    PressableScale(
                      onTap: _finishAndGoToPostAd,
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: _primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _primary.withValues(alpha: 0.25),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              CupertinoIcons.plus_circle_fill,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isAr ? 'إضافة إعلان جديد الآن +' : 'Publier une annonce +',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    PressableScale(
                      onTap: _finishAndExit,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          isAr ? 'تصفح الإعلانات فالـ Home' : 'Explorer l\'accueil',
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
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
      ],
    );
  }
}

class _AuthCelebrationConfettiPainter extends CustomPainter {
  final double progress;

  _AuthCelebrationConfettiPainter({required this.progress});

  static const List<Color> _palette = [
    Color(0xFFE31B23),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFF3B82F6),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    const int count = 58;

    for (int i = 0; i < count; i++) {
      final double seed = (i * 73.19) % 1.0;
      final double xBase = ((i * 37.0) % 100) / 100.0;
      final double speed = 0.65 + (seed * 0.75);
      final double t = ((progress * speed) + (seed * 0.45)) % 1.0;

      final double sway = math.sin((t * 6.0) + i) * 24.0;
      final double x = (xBase * size.width) + sway;
      final double y = (t * (size.height + 80)) - 40;

      final Color color = _palette[i % _palette.length];
      final double alpha = (1.0 - (t * 0.55)).clamp(0.0, 1.0);
      paint.color = color.withValues(alpha: alpha);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * math.pi * 4 * (i.isEven ? 1 : -1));

      if (i % 3 == 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-6, -3, 12, 6),
            const Radius.circular(2),
          ),
          paint,
        );
      } else if (i % 3 == 1) {
        canvas.drawCircle(Offset.zero, 4.2, paint);
      } else {
        canvas.drawRect(const Rect.fromLTWH(-4, -4, 8, 8), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _AuthCelebrationConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
