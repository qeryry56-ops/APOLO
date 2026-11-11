import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import 'auth_screen.dart';
import '../account/account_helpers.dart';
import 'widgets/app_image.dart';
import 'widgets/kinetic_widgets.dart';

class PostAdScreen extends StatefulWidget {
  final VoidCallback? onSuccess;
  final Map<String, dynamic>? initialAd;

  const PostAdScreen({
    super.key,
    this.onSuccess,
    this.initialAd,
  });

  @override
  State<PostAdScreen> createState() => _PostAdScreenState();
}

class _PostAdScreenState extends State<PostAdScreen>
    with TickerProviderStateMixin {
  final AppState _state = AppState();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  int _currentStep = 0; // 0..3
  bool _goingForward = true;
  bool _showCelebration = false;

  int? _categoryId;
  int? _cityId;
  bool _negotiable = false;
  bool _free = false;
  bool _hidePhone = false;
  bool _submitting = false;

  final List<XFile> _pickedImages = [];
  List<String> _existingImageUrls = [];
  final Map<String, dynamic> _dynamicValues = {};

  late final AnimationController _celebrationCtrl;

  // Apple Whitespace & Brand Tokens
  static const Color _ink = Color(0xFF0F172A);
  static const Color _red = Color(0xFFE31B23);
  static const Color _redSoft = Color(0xFFFEECEE);
  static const Color _muted = Color(0xFF8A94A6);
  static const Color _surface = Color(0xFFF5F6F8);
  static const Color _emerald = Color(0xFF10B981);

  List<dynamic> get _effectiveCategories => _state.categories;
  List<dynamic> get _effectiveCities => _state.cities;

  bool get _isEditing => widget.initialAd != null;

  @override
  void initState() {
    super.initState();
    _celebrationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );

    _titleCtrl.addListener(_onFieldChanged);
    _descCtrl.addListener(_onFieldChanged);
    _priceCtrl.addListener(_onFieldChanged);
    _phoneCtrl.addListener(_onFieldChanged);

    final ad = widget.initialAd;
    if (ad != null) {
      _titleCtrl.text = (ad['title'] ?? '').toString();
      _descCtrl.text = (ad['description'] ?? '').toString();
      final rawPrice = ad['price']?.toString() ?? '';
      _priceCtrl.text = rawPrice == '0' ? '' : rawPrice;
      _phoneCtrl.text =
          (ad['phone_call'] ?? ad['phone_whatsapp'] ?? '').toString();
      _categoryId = int.tryParse(
        (ad['category_id'] ??
                (ad['category'] is Map ? ad['category']['id'] : ''))
            .toString(),
      );
      _cityId = int.tryParse(
        (ad['city_id'] ?? (ad['city'] is Map ? ad['city']['id'] : ''))
            .toString(),
      );
      final meta = ad['metadata'] is Map
          ? Map<String, dynamic>.from(ad['metadata'])
          : <String, dynamic>{};
      _negotiable = meta['negotiable'] == true || ad['negotiable'] == true;
      _free = meta['free'] == true ||
          ad['free'] == true ||
          ad['offer_type'] == 'free';
      _hidePhone = meta['hide_phone'] == true;
      meta.forEach((k, v) {
        if (![
              'negotiable',
              'free',
              'additional_images',
              'hide_phone',
              'internal_chat',
            ].contains(k) &&
            v != null) {
          _dynamicValues[k] = v;
        }
      });
      if (ad['images'] is List) {
        _existingImageUrls =
            (ad['images'] as List).map((e) => e.toString()).toList();
      }
    } else {
      _cityId = _state.preferredCityId;
      if (_state.currentUser != null && _state.currentUser!['phone'] != null) {
        _phoneCtrl.text = _state.currentUser!['phone'].toString();
      }
    }
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _celebrationCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String _assetForCategory(String name, [Map<dynamic, dynamic>? cat]) {
    final combined =
        '${name.toLowerCase()} ${(cat?['name_ar'] ?? '').toString().toLowerCase()} ${(cat?['name_fr'] ?? '').toString().toLowerCase()} ${(cat?['slug'] ?? '').toString().toLowerCase()}';
    if (combined.contains('voiture') ||
        combined.contains('auto') ||
        combined.contains('moto') ||
        combined.contains('vehicule') ||
        combined.contains('véhicule') ||
        combined.contains('نقل') ||
        combined.contains('سيار') ||
        combined.contains('مركبات')) {
      return 'assets/images/cat_vehicles.png';
    }
    if (combined.contains('immo') ||
        combined.contains('appart') ||
        combined.contains('villa') ||
        combined.contains('عقار') ||
        combined.contains('شقق')) {
      return 'assets/images/cat_realestate.png';
    }
    if (combined.contains('voyage') || combined.contains('سفر')) {
      return 'assets/images/cat_travel.png';
    }
    if (combined.contains('parapharmacie') ||
        combined.contains('بارافارماسي')) {
      return 'assets/images/cat_parapharmacy.png';
    }
    if (combined.contains('enfant') ||
        combined.contains('اطفال') ||
        combined.contains('أطفال')) {
      return 'assets/images/cat_kids.png';
    }
    if (combined.contains('bricolage') || combined.contains('بريكولاج')) {
      return 'assets/images/cat_bricolage.png';
    }
    if (combined.contains('industriel') ||
        combined.contains('machine') ||
        combined.contains('صناعية') ||
        combined.contains('ألات') ||
        combined.contains('آلات')) {
      return 'assets/images/cat_industrial.png';
    }
    if (combined.contains('bijou') || combined.contains('مجوهرات')) {
      return 'assets/images/cat_jewelry.png';
    }
    if (combined.contains('antique') || combined.contains('عتيقة')) {
      return 'assets/images/cat_antique.png';
    }
    if (combined.contains('autre') || combined.contains('آخر')) {
      return 'assets/images/cat_other.png';
    }
    if (combined.contains('télé') ||
        combined.contains('phone') ||
        combined.contains('هواتف')) {
      return 'assets/images/cat_phones.png';
    }
    if (combined.contains('info') ||
        combined.contains('multimedia') ||
        combined.contains('pc') ||
        combined.contains('معلوماتية') ||
        combined.contains('وسائط') ||
        combined.contains('حواسيب') ||
        combined.contains('إلكترون')) {
      return 'assets/images/cat_computers.png';
    }
    if (combined.contains('maison') ||
        combined.contains('meuble') ||
        combined.contains('أثاث') ||
        combined.contains('منزل')) {
      return 'assets/images/cat_home.png';
    }
    if (combined.contains('mode') ||
        combined.contains('habillement') ||
        combined.contains('vêt') ||
        combined.contains('أزياء') ||
        combined.contains('ملابس')) {
      return 'assets/images/cat_fashion.png';
    }
    if (combined.contains('emploi') ||
        combined.contains('service') ||
        combined.contains('وظائف') ||
        combined.contains('خدمات')) {
      return 'assets/images/cat_jobs.png';
    }
    return 'assets/images/cat_other.png';
  }

  String _selectedCategoryName() {
    if (_categoryId == null) return '';
    final s = _state.s;
    final cat = _effectiveCategories.firstWhere(
      (c) => int.tryParse(c['id'].toString()) == _categoryId,
      orElse: () => null,
    );
    if (cat == null) return '';
    return (s.isAr
            ? (cat['name_ar'] ?? cat['name'])
            : (cat['name_fr'] ?? cat['name']))
        .toString();
  }

  String _selectedCityName() {
    if (_cityId == null) return '';
    final s = _state.s;
    final city = _effectiveCities.firstWhere(
      (c) => int.tryParse(c['id'].toString()) == _cityId,
      orElse: () => null,
    );
    if (city == null) return '';
    return (s.isAr
            ? (city['name_ar'] ?? city['name'])
            : (city['name_fr'] ?? city['name']))
        .toString();
  }

  String _step3DAsset() {
    switch (_currentStep) {
      case 0:
        final catName = _selectedCategoryName();
        return catName.isNotEmpty
            ? _assetForCategory(catName)
            : 'assets/images/cat_vehicles.png';
      case 1:
        return 'assets/images/cat_phones.png';
      case 2:
        return 'assets/images/cat_computers.png';
      default:
        return 'assets/images/cat_jewelry.png';
    }
  }

  Future<void> _pickImages({ImageSource? singleSource}) async {
    HapticFeedback.selectionClick();
    if (singleSource != null) {
      final XFile? file = await _picker.pickImage(
        source: singleSource,
        imageQuality: 82,
      );
      if (file != null && _pickedImages.length < 8) {
        setState(() => _pickedImages.add(file));
      }
      return;
    }
    final List<XFile> files = await _picker.pickMultiImage(imageQuality: 82);
    if (files.isNotEmpty) {
      setState(() {
        for (final f in files) {
          if (_pickedImages.length < 8) {
            _pickedImages.add(f);
          }
        }
      });
    }
  }

  List<Map<String, dynamic>> _fieldsForCategory(int? catId) {
    if (catId == null) return [];
    final cat = _effectiveCategories.firstWhere(
      (c) => int.tryParse(c['id'].toString()) == catId,
      orElse: () => null,
    );
    if (cat != null && cat['fields'] is List) {
      return (cat['fields'] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  double? get _parsedPrice {
    final raw = AccountValidation.normalizeDigits(_priceCtrl.text)
        .replaceAll(RegExp(r'[\s ]'), '')
        .replaceAll('٫', '.')
        .replaceAll(',', '.');
    final value = double.tryParse(raw);
    return value != null && value.isFinite && value > 0 ? value : null;
  }

  bool _isStepValid(int step) {
    switch (step) {
      case 0:
        return _effectiveCategories.any(
                (c) => c is Map && int.tryParse('${c['id']}') == _categoryId) &&
            _effectiveCities
                .any((c) => c is Map && int.tryParse('${c['id']}') == _cityId);
      case 1:
        return true; // Allow continuing even if user skips photo during quick flow
      case 2:
        return _titleCtrl.text.trim().length >= 3;
      case 3:
        final hasPrice = _free || _parsedPrice != null;
        return hasPrice &&
            (_phoneCtrl.text.trim().isEmpty ||
                AccountValidation.phone(_phoneCtrl.text) != null);
      default:
        return false;
    }
  }

  void _showStepError(int step) {
    final s = _state.s;
    String msg;
    switch (step) {
      case 0:
        msg = s.tr(
          'يرجى اختيار القسم والمدينة للمتابعة',
          'Veuillez choisir une catégorie et une ville',
        );
        break;
      case 1:
        msg = s.tr(
          'أضف صورة واحدة على الأقل لإعلانك',
          'Ajoutez au moins une photo de votre article',
        );
        break;
      case 2:
        msg = s.tr(
          'أدخل عنواناً واضحاً للإعلان (3 أحرف على الأقل)',
          'Saisissez un titre clair (au moins 3 caractères)',
        );
        break;
      default:
        msg = s.tr(
          'حدد ثمناً صحيحاً أو اختر مجاني، وتحقق من رقم الهاتف',
          'Indiquez un prix valide ou Gratuit et vérifiez le téléphone',
        );
    }
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(msg),
      ),
    );
  }

  void _nextStep() {
    if (!_isStepValid(_currentStep)) {
      _showStepError(_currentStep);
      return;
    }
    HapticFeedback.lightImpact();
    if (_currentStep < 3) {
      setState(() {
        _goingForward = true;
        _currentStep++;
      });
    } else {
      _submitAd();
    }
  }

  void _prevStep() {
    HapticFeedback.selectionClick();
    if (_currentStep > 0) {
      setState(() {
        _goingForward = false;
        _currentStep--;
      });
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _jumpToStep(int target) {
    if (target == _currentStep) return;
    if (target < _currentStep || _isStepValid(_currentStep)) {
      HapticFeedback.selectionClick();
      setState(() {
        _goingForward = target > _currentStep;
        _currentStep = target;
      });
    }
  }

  void _triggerCelebration() {
    HapticFeedback.heavyImpact();
    setState(() => _showCelebration = true);
    _celebrationCtrl.repeat();
  }

  void _resetWizard() {
    HapticFeedback.selectionClick();
    _celebrationCtrl.stop();
    _titleCtrl.clear();
    _descCtrl.clear();
    _priceCtrl.clear();
    setState(() {
      _pickedImages.clear();
      _dynamicValues.clear();
      _categoryId = null;
      _cityId = _state.preferredCityId ?? 1;
      _negotiable = false;
      _free = false;
      _hidePhone = false;
      _currentStep = 0;
      _showCelebration = false;
    });
  }

  Future<void> _submitAd() async {
    final s = _state.s;
    if (_submitting) return;
    for (var step = 0; step <= 3; step++) {
      if (!_isStepValid(step)) {
        setState(() => _currentStep = step);
        _showStepError(step);
        return;
      }
    }
    if (!_state.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_state.s.isAr
              ? 'يجب تسجيل الدخول أولاً لتتمكن من نشر إعلانك على المنصة'
              : 'Veuillez vous connecter pour publier votre annonce'),
          backgroundColor: const Color(0xFFE31B23),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => const AuthScreen(initialIsLogin: true)),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final desc = _descCtrl.text.trim().length >= 20
          ? _descCtrl.text.trim()
          : '${_titleCtrl.text.trim()} — ${_descCtrl.text.trim().isEmpty ? s.tr('متوفر بحالة ممتازة على أبولو', 'Disponible en très bon état sur Apolo.ma') : _descCtrl.text.trim()}';

      final map = <String, dynamic>{
        'title': _titleCtrl.text.trim(),
        'description': desc,
        'price': _free ? 0 : _parsedPrice!,
        'category_id': _categoryId,
        'city_id': _cityId,
        'phone_call': AccountValidation.phone(_phoneCtrl.text) ?? '',
        'phone_whatsapp': AccountValidation.phone(_phoneCtrl.text) ?? '',
        'negotiable': _negotiable ? 1 : 0,
        'free': _free ? 1 : 0,
        'hide_phone': _hidePhone ? 1 : 0,
        'internal_chat': 1,
        'category_fields': jsonEncode(_dynamicValues),
      };

      final List<MultipartFile> allMultipartImages = [];
      for (int i = 0; i < _pickedImages.length && i < 8; i++) {
        final bytes = await _pickedImages[i].readAsBytes();
        final fileName = _pickedImages[i].name.isNotEmpty
            ? _pickedImages[i].name
            : 'photo_${i + 1}.jpg';
        allMultipartImages.add(
          MultipartFile.fromBytes(bytes, filename: fileName),
        );
        if (i < 4) {
          map['image_${i + 1}'] =
              MultipartFile.fromBytes(bytes, filename: fileName);
        }
      }
      if (allMultipartImages.isNotEmpty) {
        map['images[]'] = allMultipartImages;
      }

      final formData = FormData.fromMap(map);
      final String endpoint =
          _isEditing ? '/ads/${widget.initialAd!['id']}' : '/ads';
      final res = await _state.api.dio.post(endpoint, data: formData);

      if (mounted) {
        setState(() => _submitting = false);
        if (res.data is Map && res.data['status'] == 'success') {
          _triggerCelebration();
          return;
        } else {
          final errMsg = res.data is Map
              ? (res.data['message'] ?? 'فشل نشر الإعلان')
              : 'فشل نشر الإعلان';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errMsg.toString()),
              backgroundColor: const Color(0xFFE31B23),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        String errMsg = _state.s.isAr
            ? 'تعذر نشر الإعلان، يرجى التأكد من البيانات والمحاولة مجدداً'
            : 'Échec de la publication de votre annonce';
        try {
          final dynamic dynErr = e;
          if (dynErr.response?.data is Map) {
            errMsg = (dynErr.response.data['message'] ?? errMsg).toString();
          }
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMsg),
            backgroundColor: const Color(0xFFE31B23),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Borderless soft Apple input decoration (#F5F6F8)
  InputDecoration _softDecoration(String hint,
      {IconData? icon, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: _muted.withValues(alpha: 0.7),
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: icon != null ? Icon(icon, color: _muted, size: 19) : null,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;

    if (_showCelebration) {
      return _buildCelebrationScreen(s);
    }

    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (_state.categories.isEmpty || _state.cities.isEmpty)
              TextButton.icon(
                onPressed: () async {
                  await _state.fetchTaxonomy();
                  if (mounted) setState(() {});
                },
                icon: const Icon(Icons.refresh),
                label: Text(s.tr('تعذر تحميل الأقسام والمدن. أعد المحاولة',
                    'Catégories et villes indisponibles. Réessayer')),
              ),
            // 1. Minimalist Apple Top Bar (Back + 4-Segment Progress Pills + Step Fraction)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0 || canPop)
                    PressableScale(
                      onTap: _prevStep,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: _surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          s.isAr
                              ? CupertinoIcons.chevron_right
                              : CupertinoIcons.chevron_left,
                          color: _ink,
                          size: 18,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 40),

                  // 4-Segment Interactive Apple Progress Pills
                  Row(
                    children: List.generate(4, (i) {
                      final active = i <= _currentStep;
                      return GestureDetector(
                        onTap: () => _jumpToStep(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.symmetric(horizontal: 3.5),
                          width: i == _currentStep ? 28 : 10,
                          height: 6,
                          decoration: BoxDecoration(
                            color: active ? _red : _surface,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      );
                    }),
                  ),

                  SizedBox(
                    width: 44,
                    child: Text(
                      '${_currentStep + 1}/4',
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _muted,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Generous Whitespace Step Stage
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(26, 8, 26, canPop ? 28 : 110),
                children: [
                  // Floating 3D Sculpture + Clean Apple Typography Header
                  _buildMinimalistStepHeader(s),
                  const SizedBox(height: 24),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, anim) {
                      final offsetTween = Tween<Offset>(
                        begin: Offset(_goingForward ? 0.06 : -0.06, 0),
                        end: Offset.zero,
                      );
                      return FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: offsetTween.animate(anim),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<int>(_currentStep),
                      child: _buildCurrentStepBody(s),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Clean Sticky Bottom Action Bar
            _buildBottomWizardBar(s, canPop),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Minimalist Apple Whitespace Step Header (Floating 3D Asset + Centered Title)
  // ---------------------------------------------------------------------------
  Widget _buildMinimalistStepHeader(AppStrings s) {
    String title;
    String subtitle;

    switch (_currentStep) {
      case 0:
        title = s.tr('فين بغيتي تحط إعلانك؟', 'Où souhaitez-vous publier ?');
        subtitle = s.tr(
          'اختر القسم المناسب والمدينة باش المشترين القراب ليك يلقاوه بسهولة',
          'Choisissez la catégorie et votre ville pour cibler les acheteurs',
        );
        break;
      case 1:
        title = s.tr('أضف صور واضحة لإعلانك', 'Ajoutez des photos nettes');
        subtitle = s.tr(
          'الإعلانات اللي فيها صور حقيقية وواضحة كتتباع أسرع بـ 3 مرات',
          'Les annonces avec photos réelles se vendent 3x plus vite',
        );
        break;
      case 2:
        title = s.tr('شنو كتبيع؟ عطيه عنوان قوي', 'Décrivez votre article');
        subtitle = s.tr(
          'اكتب الماركة، الموديل، والحالة باش تجاوب على أسئلة المشتري',
          'Un titre précis et une description honnête inspirent confiance',
        );
        break;
      default:
        title = s.tr('حدد الثمن وطريقة التواصل', 'Fixez votre prix et contact');
        subtitle = s.tr(
          'حدد ثمن مناسب للسوق وراجع معاينة الإعلان قبل النشر',
          'Indiquez un prix attractif et vérifiez l\'aperçu avant de publier',
        );
        break;
    }

    return Column(
      children: [
        Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: Floating3DIllustration(
              key: ValueKey<String>('${_currentStep}_${_step3DAsset()}'),
              assetPath: _step3DAsset(),
              size: 112,
              fallbackIcon: CupertinoIcons.cube_box_fill,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _ink,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13.5,
            height: 1.45,
            color: _muted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStepBody(AppStrings s) {
    switch (_currentStep) {
      case 0:
        return _buildStep1CategoryAndCity(s);
      case 1:
        return _buildStep2Photos(s);
      case 2:
        return _buildStep3DetailsAndSpecs(s);
      default:
        return _buildStep4PriceContactAndPreview(s);
    }
  }

  // ---------------------------------------------------------------------------
  // STEP 1: Soft City Pills + Borderless 3D Category Bento Grid
  // ---------------------------------------------------------------------------
  Widget _buildStep1CategoryAndCity(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Horizontal City Pills
        Text(
          s.tr('المدينة', 'Ville'),
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _effectiveCities.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final city = _effectiveCities[index];
              final id = int.tryParse(city['id'].toString());
              final selected = id == _cityId;
              final name = (s.isAr
                      ? (city['name_ar'] ?? city['name'])
                      : (city['name_fr'] ?? city['name']))
                  .toString();

              return PressableScale(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _cityId = id);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? _ink : _surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.location_solid,
                        size: 13,
                        color: selected ? Colors.white : _muted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : _ink,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 24),

        // 2. 2-Column Soft 3D Category Bento Grid
        Text(
          s.tr('اختر القسم', 'Catégorie'),
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: _ink,
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
            childAspectRatio: 2.35,
          ),
          itemCount: _effectiveCategories.length,
          itemBuilder: (context, index) {
            final c = _effectiveCategories[index];
            final int? id = int.tryParse(c['id'].toString());
            final bool active = _categoryId == id;
            final String label = (s.isAr
                    ? (c['name_ar'] ?? c['name'])
                    : (c['name_fr'] ?? c['name']))
                .toString();
            final String asset = _assetForCategory(label, c is Map ? c : null);

            return PressableScale(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _categoryId = id;
                  _dynamicValues.clear();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: active ? _redSoft : _surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: active ? _red : Colors.transparent,
                    width: 1.6,
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: Image.asset(
                        asset,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight:
                              active ? FontWeight.w800 : FontWeight.w700,
                          color: active ? _red : _ink,
                          height: 1.2,
                        ),
                      ),
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

  // ---------------------------------------------------------------------------
  // STEP 2: Minimalist Apple Studio Photo Uploader & Cover Grid
  // ---------------------------------------------------------------------------
  Widget _buildStep2Photos(AppStrings s) {
    final int totalPhotos = _pickedImages.length + _existingImageUrls.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PressableScale(
          onTap: () => _pickImages(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    totalPhotos > 0
                        ? CupertinoIcons.photo_on_rectangle
                        : CupertinoIcons.camera_fill,
                    size: 26,
                    color: totalPhotos > 0 ? _emerald : _red,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  totalPhotos == 0
                      ? s.tr('اضغط لإضافة صور الإعلان',
                          'Appuyez pour ajouter des photos')
                      : s.tr('إضافة المزيد من الصور ($totalPhotos/8)',
                          'Ajouter plus de photos ($totalPhotos/8)'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.tr(
                    'الصورة الأولى غادي تكون هي صورة الغلاف الرئيسية',
                    'La première photo sera la couverture principale',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12.5, color: _muted),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _miniActionChip(
                      icon: CupertinoIcons.photo_fill,
                      label: s.tr('المعرض', 'Galerie'),
                      onTap: () => _pickImages(),
                    ),
                    const SizedBox(width: 10),
                    _miniActionChip(
                      icon: CupertinoIcons.camera_fill,
                      label: s.tr('الكاميرا', 'Caméra'),
                      onTap: () =>
                          _pickImages(singleSource: ImageSource.camera),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (totalPhotos > 0) ...[
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.tr('الصور المختارة', 'Photos sélectionnées'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              Text(
                '$totalPhotos / 8',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: _pickedImages.isNotEmpty
                ? _pickedImages.length
                : _existingImageUrls.length,
            itemBuilder: (context, idx) {
              final bool isCover = idx == 0;
              return Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(18),
                      border:
                          isCover ? Border.all(color: _red, width: 2) : null,
                    ),
                    child: _pickedImages.isNotEmpty
                        ? (kIsWeb
                            ? Image.network(
                                _pickedImages[idx].path,
                                fit: BoxFit.cover,
                              )
                            : FutureBuilder(
                                future: _pickedImages[idx].readAsBytes(),
                                builder: (_, snap) => snap.hasData
                                    ? Image.memory(snap.data!,
                                        fit: BoxFit.cover)
                                    : const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: _red,
                                        ),
                                      ),
                              ))
                        : AppImage(
                            url: _existingImageUrls[idx],
                            fit: BoxFit.cover,
                          ),
                  ),
                  if (isCover)
                    PositionedDirectional(
                      bottom: 6,
                      start: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _red,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          s.tr('الغلاف', 'Principale'),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  if (_pickedImages.isNotEmpty)
                    PositionedDirectional(
                      top: 6,
                      end: 6,
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _pickedImages.removeAt(idx)),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.xmark,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _miniActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: _ink),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 3: Soft Borderless Title, Description & Dynamic Category Fields
  // ---------------------------------------------------------------------------
  Widget _buildStep3DetailsAndSpecs(AppStrings s) {
    final dynamicFields = _fieldsForCategory(_categoryId);
    final int titleLen = _titleCtrl.text.trim().length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              s.tr('عنوان الإعلان', 'Titre de l\'annonce'),
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            Text(
              titleLen >= 3 ? s.tr('ممتاز ✓', 'Parfait ✓') : '$titleLen / 3+',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: titleLen >= 3 ? _emerald : _muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleCtrl,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
          decoration: _softDecoration(
            s.tr(
              'مثال: iPhone 15 Pro Max 256GB بحالة الجديد',
              'Ex: iPhone 15 Pro Max 256Go comme neuf',
            ),
            icon: CupertinoIcons.textbox,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          s.tr('الوصف التفصيلي', 'Description détaillée'),
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descCtrl,
          maxLines: 4,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _ink,
          ),
          decoration: _softDecoration(
            s.tr(
              'اذكر الحالة، الملحقات، وسبب البيع لزيادة ثقة المشترين...',
              'Précisez l\'état, les accessoires et les détails importants...',
            ),
          ),
        ),
        if (dynamicFields.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text(
            s.tr('مواصفات إضافية', 'Caractéristiques spécifiques'),
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          const SizedBox(height: 10),
          ...dynamicFields.map((field) {
            final String key = field['key'].toString();
            final String label =
                (field['label'] ?? field['label_ar'] ?? key).toString();
            final String type = (field['type'] ?? 'text').toString();
            final List options =
                field['options'] is List ? field['options'] : [];

            if (type == 'select' && options.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  initialValue: _dynamicValues[key]?.toString(),
                  decoration: _softDecoration(label),
                  items: options.map((o) {
                    final val = (o is Map ? o['value'] : o).toString();
                    final lbl = (o is Map ? o['label'] : o).toString();
                    return DropdownMenuItem<String>(
                      value: val,
                      child: Text(lbl),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _dynamicValues[key] = v),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextFormField(
                initialValue: _dynamicValues[key]?.toString(),
                keyboardType: type == 'number'
                    ? TextInputType.number
                    : TextInputType.text,
                decoration: _softDecoration(label),
                onChanged: (v) => _dynamicValues[key] = v,
              ),
            );
          }),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 4: Soft Price Input, Option Pills & Minimalist Live Preview Card
  // ---------------------------------------------------------------------------
  Widget _buildStep4PriceContactAndPreview(AppStrings s) {
    final String previewPrice = _free
        ? s.tr('مجاني', 'Gratuit')
        : (_priceCtrl.text.trim().isNotEmpty
            ? '${_priceCtrl.text.trim()} MAD'
            : '— MAD');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_free) ...[
          Text(
            s.tr('الثمن (بالدرهم)', 'Prix (en MAD)'),
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _priceCtrl,
            textDirection: TextDirection.ltr,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: _red,
            ),
            decoration: _softDecoration(
              s.tr('أدخل الثمن بالدرهم', 'Ex: 2500'),
              icon: CupertinoIcons.tag_solid,
              suffix: Padding(
                padding: const EdgeInsetsDirectional.only(end: 14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _redSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'MAD',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _OptionPill(
              label: s.tr('قابل للتفاوض', 'Prix négociable'),
              icon: CupertinoIcons.hand_thumbsup_fill,
              active: _negotiable,
              onTap: () => setState(() => _negotiable = !_negotiable),
            ),
            _OptionPill(
              label: s.tr('مجاني', 'Gratuit'),
              icon: CupertinoIcons.gift_fill,
              active: _free,
              onTap: () => setState(() => _free = !_free),
            ),
            _OptionPill(
              label: s.tr('إخفاء الرقم (شات فقط)', 'Masquer le numéro'),
              icon: CupertinoIcons.lock_shield_fill,
              active: _hidePhone,
              onTap: () => setState(() => _hidePhone = !_hidePhone),
            ),
          ],
        ),
        if (!_hidePhone) ...[
          const SizedBox(height: 20),
          Text(
            s.tr('رقم الهاتف والواتساب', 'Téléphone & WhatsApp'),
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneCtrl,
            textDirection: TextDirection.ltr,
            keyboardType: TextInputType.phone,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
            decoration: _softDecoration(
              '06XXXXXXXX',
              icon: CupertinoIcons.phone_fill,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          s.tr('معاينة الإعلان قبل النشر', 'Aperçu de votre annonce'),
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 78,
                height: 78,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _pickedImages.isNotEmpty
                    ? (kIsWeb
                        ? Image.network(
                            _pickedImages.first.path,
                            fit: BoxFit.cover,
                          )
                        : FutureBuilder(
                            future: _pickedImages.first.readAsBytes(),
                            builder: (_, snap) => snap.hasData
                                ? Image.memory(snap.data!, fit: BoxFit.cover)
                                : const Icon(CupertinoIcons.photo,
                                    color: _muted),
                          ))
                    : (_existingImageUrls.isNotEmpty
                        ? AppImage(
                            url: _existingImageUrls.first,
                            fit: BoxFit.cover,
                          )
                        : Padding(
                            padding: const EdgeInsets.all(10),
                            child: Image.asset(
                              _step3DAsset(),
                              fit: BoxFit.contain,
                            ),
                          )),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleCtrl.text.trim().isEmpty
                          ? s.tr('عنوان الإعلان', 'Titre de l\'annonce')
                          : _titleCtrl.text.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      previewPrice,
                      textDirection: _free ? null : TextDirection.ltr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _red,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          CupertinoIcons.location_solid,
                          size: 13,
                          color: _muted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${_selectedCategoryName()} • ${_selectedCityName()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: _muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Clean Sticky Bottom Bar
  // ---------------------------------------------------------------------------
  Widget _buildBottomWizardBar(AppStrings s, bool canPop) {
    final bool isLast = _currentStep == 3;
    final bool stepReady = _isStepValid(_currentStep);

    return Container(
      padding: EdgeInsets.fromLTRB(
        26,
        12,
        26,
        MediaQuery.of(context).padding.bottom + (canPop ? 16 : 92),
      ),
      color: Colors.white,
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            PressableScale(
              onTap: _prevStep,
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  s.tr('السابق', 'Retour'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: PressableScale(
              onTap: _submitting ? null : _nextStep,
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: stepReady ? _red : _ink,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.3,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isLast
                                ? CupertinoIcons.checkmark_circle_fill
                                : (s.isAr
                                    ? CupertinoIcons.arrow_left
                                    : CupertinoIcons.arrow_right),
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isLast
                                ? (_isEditing
                                    ? s.tr('حفظ التعديلات', 'Enregistrer')
                                    : s.tr('نشر الإعلان الآن',
                                        'Publier mon annonce'))
                                : s.tr('المتابعة', 'Continuer'),
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
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

  // ---------------------------------------------------------------------------
  // FULL-SCREEN CELEBRATION ANIMATION VIEW 🎉
  // ---------------------------------------------------------------------------
  Widget _buildCelebrationScreen(AppStrings s) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _celebrationCtrl,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ConfettiCelebrationPainter(
                    progress: _celebrationCtrl.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 96),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 190,
                    height: 190,
                    child: AnimatedBuilder(
                      animation: _celebrationCtrl,
                      builder: (context, _) {
                        final pulse =
                            math.sin(_celebrationCtrl.value * math.pi * 2);
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Transform.scale(
                              scale: 1.0 + (pulse.abs() * 0.14),
                              child: Container(
                                width: 164,
                                height: 164,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      _emerald.withValues(alpha: 0.18),
                                      _red.withValues(alpha: 0.08),
                                      Colors.white.withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Floating3DIllustration(
                              assetPath: _assetForCategory(
                                _selectedCategoryName(),
                              ),
                              size: 136,
                            ),
                            Positioned(
                              bottom: 12,
                              right: 22,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: _emerald,
                                  borderRadius: BorderRadius.circular(999),
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
                                      'LIVE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _isEditing
                        ? s.tr('تم تحديث إعلانك بنجاح! 🎉',
                            'Annonce mise à jour ! 🎉')
                        : s.tr('مبروك! تم نشر إعلانك بنجاح 🎉',
                            'Félicitations ! Annonce publiée 🎉'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.tr(
                      'إعلانك دابا واجد وغادي يبان لآلاف المشترين فـ Apolo.ma.',
                      'Votre annonce est maintenant visible par des milliers d\'acheteurs sur Apolo.ma.',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: _muted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Image.asset(
                            _assetForCategory(_selectedCategoryName()),
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _titleCtrl.text.trim().isEmpty
                                    ? s.tr('إعلانك الجديد',
                                        'Votre nouvelle annonce')
                                    : _titleCtrl.text.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  color: _ink,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${_selectedCategoryName()} • ${_selectedCityName()}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: _muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  PressableScale(
                    onTap: () {
                      if (_isEditing && Navigator.of(context).canPop()) {
                        Navigator.of(context).pop(true);
                        return;
                      }
                      _resetWizard();
                      widget.onSuccess?.call();
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop(true);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        color: _red,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        s.tr('العودة للرئيسية ومشاهدة الإعلانات',
                            'Retour à l\'accueil'),
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _resetWizard,
                    child: Text(
                      s.tr('إضافة إعلان آخر +', 'Publier une autre annonce +'),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                  ),
                  if (!_state.isLoggedIn) ...[
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                      ).then((_) => setState(() {})),
                      icon: const Icon(
                        CupertinoIcons.person_crop_circle,
                        size: 17,
                        color: _red,
                      ),
                      label: Text(
                        s.tr('ربط الإعلان بحسابي', 'Lier à mon compte'),
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: _red,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _OptionPill({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color red = Color(0xFFE31B23);
    const Color surface = Color(0xFFF5F6F8);
    const Color ink = Color(0xFF0F172A);

    return PressableScale(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        decoration: BoxDecoration(
          color: active ? red : surface,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: active ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfettiCelebrationPainter extends CustomPainter {
  final double progress;

  _ConfettiCelebrationPainter({required this.progress});

  static const List<Color> _palette = [
    Color(0xFFE31B23),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    const int count = 64;

    for (int i = 0; i < count; i++) {
      final double seed = (i * 73.19) % 1.0;
      final double xBase = ((i * 37.0) % 100) / 100.0;
      final double speed = 0.65 + (seed * 0.75);
      final double t = ((progress * speed) + (seed * 0.45)) % 1.0;

      final double sway = math.sin((t * 6.0) + i) * 26.0;
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
        canvas.drawCircle(Offset.zero, 4.5, paint);
      } else {
        canvas.drawRect(const Rect.fromLTWH(-4, -4, 8, 8), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiCelebrationPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
