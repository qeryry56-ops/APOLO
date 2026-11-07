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
import 'widgets/app_image.dart';

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

  late final AnimationController _floatCtrl;
  late final AnimationController _celebrationCtrl;

  // Brand tokens
  static const Color _ink = Color(0xFF0F1B2D);
  static const Color _red = Color(0xFFE31B23);
  static const Color _redSoft = Color(0xFFFEECEE);
  static const Color _muted = Color(0xFF8A94A6);
  static const Color _border = Color(0xFFE7EAF0);
  static const Color _fill = Color(0xFFF3F5F8);
  static const Color _emerald = Color(0xFF10B981);

  static const List<Map<String, dynamic>> _fallbackCategories = [
    {'id': 1, 'name_ar': 'سيارات ومركبات', 'name_fr': 'Auto & Véhicules'},
    {'id': 2, 'name_ar': 'عقارات وشقق', 'name_fr': 'Immobilier'},
    {'id': 3, 'name_ar': 'هواتف وإلكترونيات', 'name_fr': 'Téléphones & Tech'},
    {'id': 4, 'name_ar': 'حواسيب ومعدات', 'name_fr': 'Informatique'},
    {'id': 5, 'name_ar': 'أثاث ومنزل', 'name_fr': 'Maison & Déco'},
    {'id': 6, 'name_ar': 'أزياء وملابس', 'name_fr': 'Mode & Beauté'},
    {'id': 7, 'name_ar': 'وظائف وخدمات', 'name_fr': 'Emploi & Services'},
  ];

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

  List<dynamic> get _effectiveCategories =>
      _state.categories.isNotEmpty ? _state.categories : _fallbackCategories;

  List<dynamic> get _effectiveCities =>
      _state.cities.isNotEmpty ? _state.cities : _fallbackCities;

  bool get _isEditing => widget.initialAd != null;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

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
    } else if (_state.currentUser != null &&
        _state.currentUser!['phone'] != null) {
      _phoneCtrl.text = _state.currentUser!['phone'].toString();
    }
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _celebrationCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String _assetForCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('voiture') ||
        lower.contains('auto') ||
        lower.contains('moto') ||
        lower.contains('véhicule') ||
        lower.contains('سيار') ||
        lower.contains('مركبات')) {
      return 'assets/images/hero_car.png';
    }
    if (lower.contains('immo') ||
        lower.contains('appart') ||
        lower.contains('villa') ||
        lower.contains('عقار') ||
        lower.contains('شقق')) {
      return 'assets/images/cat_realestate.png';
    }
    if (lower.contains('télé') ||
        lower.contains('phone') ||
        lower.contains('tech') ||
        lower.contains('هواتف') ||
        lower.contains('إلكترون')) {
      return 'assets/images/cat_phones.png';
    }
    if (lower.contains('info') ||
        lower.contains('pc') ||
        lower.contains('حواسيب')) {
      return 'assets/images/cat_computers.png';
    }
    if (lower.contains('maison') ||
        lower.contains('meuble') ||
        lower.contains('أثاث') ||
        lower.contains('منزل')) {
      return 'assets/images/cat_home.png';
    }
    if (lower.contains('mode') ||
        lower.contains('vêt') ||
        lower.contains('أزياء') ||
        lower.contains('ملابس')) {
      return 'assets/images/cat_fashion.png';
    }
    return 'assets/images/cat_jobs.png';
  }

  String _selectedCategoryName() {
    if (_categoryId == null) return '';
    final s = _state.s;
    final cat = _effectiveCategories.firstWhere(
      (c) => int.tryParse(c['id'].toString()) == _categoryId,
      orElse: () => null,
    );
    if (cat == null) return '';
    return (s.isAr ? (cat['name_ar'] ?? cat['name']) : (cat['name_fr'] ?? cat['name']))
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

  bool _isStepValid(int step) {
    switch (step) {
      case 0:
        return _categoryId != null && _cityId != null;
      case 1:
        return true; // Allow continuing even if user skips photo during quick flow
      case 2:
        return _titleCtrl.text.trim().length >= 3;
      case 3:
        final hasPrice =
            _free || (double.tryParse(_priceCtrl.text.trim()) ?? 0) > 0;
        return hasPrice;
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
          'أدخل عنواناً واضحاً للإعلان (6 أحرف على الأقل)',
          'Saisissez un titre clair (au moins 6 caractères)',
        );
        break;
      default:
        msg = s.tr(
          'حدد الثمن ورقم الهاتف أو اختر مجاني / إخفاء الرقم',
          'Indiquez le prix et votre numéro de contact',
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
    HapticFeedback.mediumImpact();
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
      _cityId = null;
      _negotiable = false;
      _free = false;
      _hidePhone = false;
      _currentStep = 0;
      _showCelebration = false;
    });
  }

  Future<void> _submitAd() async {
    final s = _state.s;
    if (!_isStepValid(0) || !_isStepValid(1) || !_isStepValid(2)) {
      _showStepError(_currentStep);
      return;
    }
    if (!_state.isLoggedIn) {
      // Allow completing the wizard & experiencing the celebration screen,
      // and offer login on the celebration screen to link to account
      _triggerCelebration();
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
        'price': _free ? 0 : (double.tryParse(_priceCtrl.text.trim()) ?? 0),
        'category_id': _categoryId,
        'city_id': _cityId,
        'phone_call': _phoneCtrl.text.trim(),
        'phone_whatsapp': _phoneCtrl.text.trim(),
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
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppConfig.danger,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: Text(
              s.tr(
                'حدث خطأ أثناء حفظ الإعلان، تأكد من طول الوصف وعدم وجود أرقام بالوصف',
                'Erreur lors de l\'enregistrement de l\'annonce',
              ),
            ),
          ),
        );
      }
    }
  }

  InputDecoration _inputDecoration(String hint, {IconData? icon, Widget? suffix}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: _border, width: 1.2),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: _muted,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: icon != null ? Icon(icon, color: _muted, size: 20) : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: _red, width: 1.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;

    if (_showCelebration) {
      return _buildCelebrationScreen(s);
    }

    final topInset = MediaQuery.of(context).padding.top;
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFD),
      body: Column(
        children: [
          // Top Wizard Header + Animated Step Progress Bar
          Container(
            padding: EdgeInsets.fromLTRB(20, topInset + 10, 20, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFEDF0F5))),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    if (_currentStep > 0 || canPop)
                      GestureDetector(
                        onTap: _prevStep,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: _fill,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            s.isAr
                                ? CupertinoIcons.chevron_right
                                : CupertinoIcons.chevron_left,
                            color: _ink,
                            size: 20,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 40),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            _isEditing
                                ? s.tr('تعديل الإعلان', 'Modifier l\'annonce')
                                : s.tr('إضافة إعلان جديد', 'Nouvelle annonce'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.tr(
                              'الخطوة ${_currentStep + 1} من 4',
                              'Étape ${_currentStep + 1} sur 4',
                            ),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: _muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _redSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${((_currentStep + 1) * 25)}%',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: _red,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // 4 Interactive Step Pills
                Row(
                  children: List.generate(4, (idx) {
                    final bool done = idx < _currentStep;
                    final bool active = idx == _currentStep;
                    final List<String> labels = [
                      s.tr('القسم', 'Catégorie'),
                      s.tr('الصور', 'Photos'),
                      s.tr('التفاصيل', 'Détails'),
                      s.tr('الثمن', 'Prix'),
                    ];
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _jumpToStep(idx),
                        child: Padding(
                          padding: EdgeInsetsDirectional.only(
                            end: idx < 3 ? 8 : 0,
                          ),
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 280),
                                curve: Curves.easeOutCubic,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: done
                                      ? _emerald
                                      : (active ? _red : const Color(0xFFE4E8F0)),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (done) ...[
                                    const Icon(
                                      CupertinoIcons.check_mark_circled_solid,
                                      size: 13,
                                      color: _emerald,
                                    ),
                                    const SizedBox(width: 3),
                                  ],
                                  Flexible(
                                    child: Text(
                                      labels[idx],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: active || done
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: done
                                            ? _emerald
                                            : (active ? _red : _muted),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // Step Content with AnimatedSwitcher
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, 16, 20, canPop ? 28 : 110),
              children: [
                _buildAnimatedStepHeroBanner(s),
                const SizedBox(height: 20),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, anim) {
                    final offsetTween = Tween<Offset>(
                      begin: Offset(_goingForward ? 0.08 : -0.08, 0),
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

          // Sticky Bottom Navigation Bar
          _buildBottomWizardBar(s, canPop),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Animated Step State Hero Banner (with floating 3D asset / animated icon)
  // ---------------------------------------------------------------------------
  Widget _buildAnimatedStepHeroBanner(AppStrings s) {
    final bool valid = _isStepValid(_currentStep);

    String title;
    String subtitle;
    String statusBadge;
    IconData fallbackIcon;
    String? assetImage;

    switch (_currentStep) {
      case 0:
        final catName = _selectedCategoryName();
        final cityName = _selectedCityName();
        assetImage = catName.isNotEmpty
            ? _assetForCategory(catName)
            : 'assets/images/hero_car.png';
        fallbackIcon = CupertinoIcons.square_grid_2x2_fill;
        title = s.tr(
          'فين بغيتي تحط إعلانك؟',
          'Où souhaitez-vous publier ?',
        );
        subtitle = s.tr(
          'اختر القسم المناسب والمدينة باش المشترين القراب ليك يلقاوه بسهولة.',
          'Choisissez la bonne catégorie et votre ville pour cibler les acheteurs.',
        );
        statusBadge = valid
            ? '$catName • $cityName ✓'
            : s.tr('اختر القسم والمدينة', 'Catégorie & ville requises');
        break;

      case 1:
        final int count = _pickedImages.length + _existingImageUrls.length;
        fallbackIcon = count > 0
            ? CupertinoIcons.photo_fill_on_rectangle_fill
            : CupertinoIcons.camera_viewfinder;
        title = s.tr(
          'صور واضحة = بيع أسرع بـ 3 مرات 📸',
          'De belles photos vendent 3x plus vite 📸',
        );
        subtitle = s.tr(
          'أضف حتى 8 صور من زوايا مختلفة. الصورة الأولى غادي تكون هي صورة الغلاف.',
          'Ajoutez jusqu\'à 8 photos. La première sera la photo de couverture.',
        );
        statusBadge = count > 0
            ? s.tr('تمت إضافة $count صور ممتازة ✓', '$count photo(s) prête(s) ✓')
            : s.tr('بانتظار إضافة الصور...', 'En attente de photos...');
        break;

      case 2:
        final int tLen = _titleCtrl.text.trim().length;
        fallbackIcon = tLen >= 6
            ? CupertinoIcons.checkmark_seal_fill
            : CupertinoIcons.pencil_outline;
        title = s.tr(
          'شنو كتبيع؟ عطيه عنوان قوي ✨',
          'Décrivez votre article avec soin ✨',
        );
        subtitle = s.tr(
          'اكتب عنوان واضح (الماركة، الموديل، الحالة) ووصف كيجاوب على أسئلة المشتري.',
          'Un titre précis et une description honnête inspirent confiance.',
        );
        statusBadge = tLen >= 6
            ? s.tr('العنوان جاهز وممتاز ✓', 'Titre validé ✓')
            : s.tr(
                'باقي ${math.max(0, 6 - tLen)} أحرف للعنوان',
                'Encore ${math.max(0, 6 - tLen)} caractères min.',
              );
        break;

      default:
        fallbackIcon = CupertinoIcons.tag_fill;
        title = s.tr(
          'حدد الثمن وطريقة التواصل 💰',
          'Fixez votre prix et vos coordonnées 💰',
        );
        subtitle = s.tr(
          'حدد ثمن مناسب للسوق أو جعل الإعلان قابل للتفاوض، وراجع البطاقة قبل النشر.',
          'Indiquez un prix attractif et vérifiez l\'aperçu avant de publier.',
        );
        statusBadge = _free
            ? s.tr('إعلان مجاني ✓', 'Article gratuit ✓')
            : ((double.tryParse(_priceCtrl.text.trim()) ?? 0) > 0
                ? '${_priceCtrl.text.trim()} MAD ✓'
                : s.tr('أدخل الثمن بالدرهم', 'Saisissez le prix en MAD'));
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: valid
              ? [const Color(0xFF0F1B2D), const Color(0xFF1E2F4D)]
              : [const Color(0xFFE31B23), const Color(0xFFC21018)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (valid ? _ink : _red).withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: valid
                        ? _emerald.withValues(alpha: 0.22)
                        : Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: valid
                          ? _emerald.withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        valid
                            ? CupertinoIcons.check_mark_circled_solid
                            : CupertinoIcons.sparkles,
                        size: 13,
                        color: valid ? const Color(0xFF6EE7B7) : Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          statusBadge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color:
                                valid ? const Color(0xFFA7F3D0) : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.white.withValues(alpha: 0.86),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Animated Floating Illustration / State Orb
          AnimatedBuilder(
            animation: _floatCtrl,
            builder: (context, child) {
              final dy = math.sin(_floatCtrl.value * math.pi) * 6 - 3;
              final scale = 0.96 + (_floatCtrl.value * 0.06);
              return Transform.translate(
                offset: Offset(0, dy),
                child: Transform.scale(scale: scale, child: child),
              );
            },
            child: Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.32),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: assetImage != null
                  ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        assetImage,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Icon(
                      fallbackIcon,
                      size: 36,
                      color: Colors.white,
                    ),
            ),
          ),
        ],
      ),
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
  // STEP 1: Category Grid (with 3D Memoji icons) + City Selector
  // ---------------------------------------------------------------------------
  Widget _buildStep1CategoryAndCity(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.tr('1. اختر القسم', '1. Choisissez la catégorie'),
          style: const TextStyle(
            fontSize: 17.5,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        const SizedBox(height: 12),
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
            final String asset = _assetForCategory(label);

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _categoryId = id;
                  _dynamicValues.clear();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: active ? _redSoft : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: active ? _red : _border,
                    width: active ? 1.8 : 1.1,
                  ),
                  boxShadow: [
                    if (active)
                      BoxShadow(
                        color: _red.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: Image.asset(
                        asset,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight:
                              active ? FontWeight.w800 : FontWeight.w600,
                          color: active ? _red : _ink,
                          height: 1.2,
                        ),
                      ),
                    ),
                    if (active)
                      const Icon(
                        CupertinoIcons.check_mark_circled_solid,
                        color: _red,
                        size: 18,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Text(
          s.tr('2. اختر المدينة', '2. Choisissez votre ville'),
          style: const TextStyle(
            fontSize: 17.5,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: _cityId,
          decoration: _inputDecoration(
            s.tr('اختر المدينة', 'Sélectionnez une ville'),
            icon: CupertinoIcons.location_solid,
          ),
          items: _effectiveCities
              .map(
                (c) => DropdownMenuItem<int>(
                  value: int.tryParse(c['id'].toString()),
                  child: Text(
                    (s.isAr
                            ? (c['name_ar'] ?? c['name'])
                            : (c['name_fr'] ?? c['name']))
                        .toString(),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            HapticFeedback.selectionClick();
            setState(() => _cityId = v);
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2: Interactive Photos Picker & Cover Manager
  // ---------------------------------------------------------------------------
  Widget _buildStep2Photos(AppStrings s) {
    final int totalPhotos = _pickedImages.length + _existingImageUrls.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Big Interactive Upload Hero Card
        GestureDetector(
          onTap: () => _pickImages(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: totalPhotos > 0 ? _emerald : _red.withValues(alpha: 0.45),
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: _ink.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: totalPhotos > 0
                        ? _emerald.withValues(alpha: 0.12)
                        : _redSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    totalPhotos > 0
                        ? CupertinoIcons.photo_on_rectangle
                        : CupertinoIcons.camera_fill,
                    size: 30,
                    color: totalPhotos > 0 ? _emerald : _red,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  totalPhotos == 0
                      ? s.tr('اضغط هنا لاختيار صور الإعلان', 'Appuyez pour ajouter des photos')
                      : s.tr('إضافة المزيد من الصور ($totalPhotos/8)', 'Ajouter plus de photos ($totalPhotos/8)'),
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.tr(
                    'يمكنك إضافة حتى 8 صور واضحة من معرض الصور أو الكاميرا',
                    'Jusqu\'à 8 photos nettes depuis la galerie ou la caméra',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: _muted),
                ),
                const SizedBox(height: 14),
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
                      onTap: () => _pickImages(singleSource: ImageSource.camera),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        if (totalPhotos > 0) ...[
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.tr('الصور المختارة', 'Photos sélectionnées'),
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              Text(
                '$totalPhotos / 8',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
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
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isCover ? _red : _border,
                        width: isCover ? 2 : 1,
                      ),
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
                                    ? Image.memory(snap.data!, fit: BoxFit.cover)
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
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.68),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.xmark,
                            size: 13,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _fill,
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
  // STEP 3: Title, Description & Dynamic Category Specs
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
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: titleLen >= 6
                    ? _emerald.withValues(alpha: 0.14)
                    : _fill,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                titleLen >= 6
                    ? s.tr('ممتاز ✓', 'Parfait ✓')
                    : '$titleLen / 6+',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: titleLen >= 6 ? _emerald : _muted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _titleCtrl,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _ink,
          ),
          decoration: _inputDecoration(
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
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _descCtrl,
          maxLines: 4,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w500,
            color: _ink,
          ),
          decoration: _inputDecoration(
            s.tr(
              'اذكر الحالة، الملحقات، وسبب البيع لزيادة ثقة المشترين...',
              'Précisez l\'état, les accessoires et les détails importants...',
            ),
          ),
        ),
        if (dynamicFields.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            s.tr('مواصفات إضافية للقسم', 'Caractéristiques spécifiques'),
            style: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: dynamicFields.map((field) {
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
                      decoration: _inputDecoration(label),
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
                    decoration: _inputDecoration(label),
                    onChanged: (v) => _dynamicValues[key] = v,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 4: Price, Contact & Live Ad Preview Card
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
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _priceCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: _red,
            ),
            decoration: _inputDecoration(
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

        // Option Pills (Brand Red #E31B23)
        Wrap(
          spacing: 10,
          runSpacing: 10,
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
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _ink,
            ),
            decoration: _inputDecoration(
              s.tr('06XXXXXXXX', '06XXXXXXXX'),
              icon: CupertinoIcons.phone_fill,
            ),
          ),
        ],

        const SizedBox(height: 24),
        // Live Ad Summary Preview Card
        Text(
          s.tr('معاينة الإعلان قبل النشر', 'Aperçu de votre annonce'),
          style: const TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: _ink.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 84,
                height: 84,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: _fill,
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
                                : const Icon(CupertinoIcons.photo, color: _muted),
                          ))
                    : (_existingImageUrls.isNotEmpty
                        ? AppImage(
                            url: _existingImageUrls.first,
                            fit: BoxFit.cover,
                          )
                        : const Icon(CupertinoIcons.photo, color: _muted)),
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
  // Sticky Bottom Bar (Previous / Next or Publish)
  // ---------------------------------------------------------------------------
  Widget _buildBottomWizardBar(AppStrings s, bool canPop) {
    final bool isLast = _currentStep == 3;
    final bool stepReady = _isStepValid(_currentStep);

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + (canPop ? 14 : 92),
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEDF0F5))),
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            GestureDetector(
              onTap: _prevStep,
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: _fill,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  s.tr('السابق', 'Retour'),
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: SizedBox(
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: stepReady ? _red : _ink.withValues(alpha: 0.85),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
                onPressed: _submitting ? null : _nextStep,
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isLast
                                ? CupertinoIcons.sparkles
                                : (s.isAr
                                    ? CupertinoIcons.arrow_left_circle_fill
                                    : CupertinoIcons.arrow_right_circle_fill),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isLast
                                ? (_isEditing
                                    ? s.tr('حفظ التعديلات', 'Enregistrer')
                                    : s.tr('نشر الإعلان الآن', 'Publier mon annonce'))
                                : s.tr('الخطوة التالية', 'Continuer'),
                            style: const TextStyle(
                              fontSize: 16.5,
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

  // ---------------------------------------------------------------------------
  // FULL-SCREEN CELEBRATION ANIMATION VIEW 🎉
  // ---------------------------------------------------------------------------
  Widget _buildCelebrationScreen(AppStrings s) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Animated Confetti & Fireworks Canvas
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
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.elasticOut,
                    builder: (context, val, child) {
                      return Transform.scale(scale: val, child: child);
                    },
                    child: Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _emerald.withValues(alpha: 0.35),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Icon(
                        CupertinoIcons.check_mark_circled_solid,
                        size: 62,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isEditing
                        ? s.tr('تم تحديث إعلانك بنجاح! 🎉', 'Annonce mise à jour ! 🎉')
                        : s.tr('مبروك! تم نشر إعلانك بنجاح 🎉', 'Félicitations ! Annonce publiée 🎉'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    s.tr(
                      'إعلانك دابا واجد وغادي يبان لآلاف المشترين فـ Apolo.ma.',
                      'Votre annonce est maintenant visible par des milliers d\'acheteurs sur Apolo.ma.',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: _muted,
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Celebration Ad Card Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _redSoft,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Image.asset(
                            _assetForCategory(_selectedCategoryName()),
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _titleCtrl.text.trim().isEmpty
                                    ? s.tr('إعلانك الجديد', 'Votre nouvelle annonce')
                                    : _titleCtrl.text.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: _ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_selectedCategoryName()} • ${_selectedCityName()}',
                                style: const TextStyle(
                                  fontSize: 13,
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
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () {
                        if (_isEditing && Navigator.of(context).canPop()) {
                          Navigator.of(context).pop(true);
                          return;
                        }
                        _resetWizard();
                        widget.onSuccess?.call();
                      },
                      child: Text(
                        s.tr('العودة للرئيسية ومشاهدة الإعلانات', 'Retour à l\'accueil'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _resetWizard,
                    child: Text(
                      s.tr('إضافة إعلان آخر +', 'Publier une autre annonce +'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                  ),
                  if (!_state.isLoggedIn) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _red,
                        side: const BorderSide(color: _red, width: 1.4),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                      ).then((_) => setState(() {})),
                      icon: const Icon(CupertinoIcons.person_crop_circle, size: 18),
                      label: Text(
                        s.tr('ربط الإعلان بحسابي', 'Lier à mon compte'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
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
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: active ? red : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? red : const Color(0xFFE7EAF0),
            width: 1.3,
          ),
          boxShadow: [
            if (active)
              BoxShadow(
                color: red.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: active ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                color: active ? Colors.white : const Color(0xFF0F1B2D),
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
