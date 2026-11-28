import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../account/account_helpers.dart';
import '../core/config/app_config.dart';
import '../core/location/marketplace_location.dart';
import '../core/state/app_state.dart';
import '../theme/app_typography.dart';
import '../widgets/dl_settings_kit.dart';
import 'auth_screen.dart';
import 'pro_plus_screen.dart';
import 'widgets/app_image.dart';
import 'widgets/kinetic_widgets.dart';
import 'widgets/real_marketplace_map.dart';
import '../l10n/l10n.dart';

/// Dynamic Layer v5.1 4-Step Post Ad / Listing Editor Wizard:
/// - Pure `#FFFFFF` canvas + `#EEEEEE` `40×40` circular back button + `#000000`/`#EEEEEE` 4-step progress pills
/// - Flat `#F6F6F6` cards, category bento tiles, photo uploader, and borderless inputs (`1.5px` `#000000` focus border)
/// - Full-capsule (`999` radius) `#000000` / `#EEEEEE` option pills & sticky bottom navigation dock
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

class _PostAdScreenState extends State<PostAdScreen> {
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
  double? _adLat;
  double? _adLng;
  bool _detectingGps = false;
  bool _negotiable = false;
  bool _free = false;
  bool _hidePhone = false;
  bool _submitting = false;

  final List<XFile> _pickedImages = [];
  List<String> _existingImageUrls = [];
  final Map<String, dynamic> _dynamicValues = {};

  // Strict Dynamic Layer v5.1 Palette Tokens
  Color get _dlBg => ApoloDlPalette.of(context).bg;
  Color get _dlSurface => ApoloDlPalette.of(context).surfaceSubtle;
  Color get _dlPill => ApoloDlPalette.of(context).pill;
  Color get _dlSeparator => ApoloDlPalette.of(context).separator;
  Color get _dlInk => ApoloDlPalette.of(context).ink;
  Color get _dlOnInk => ApoloDlPalette.of(context).onInk;
  Color get _dlMuted => ApoloDlPalette.of(context).muted;
  static const Color _dlDanger = Color(0xFFE31B23);

  List<dynamic> get _effectiveCategories => _state.categories;
  List<dynamic> get _effectiveCities => _state.cities;

  bool get _isEditing => widget.initialAd != null;

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChanged);
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
      unawaited(_restoreDraft());
    }
  }

  static const String _draftKey = 'apolo_post_ad_draft_v1';
  Timer? _draftDebounce;

  Future<void> _restoreDraft() async {
    if (_isEditing) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_draftKey);
      if (raw == null || raw.isEmpty || !mounted) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final title = (decoded['title'] ?? '').toString();
      final desc = (decoded['description'] ?? '').toString();
      final price = (decoded['price'] ?? '').toString();
      final phone = (decoded['phone'] ?? '').toString();
      if (title.isEmpty && desc.isEmpty && price.isEmpty) return;
      setState(() {
        if (_titleCtrl.text.isEmpty && title.isNotEmpty) {
          _titleCtrl.text = title;
        }
        if (_descCtrl.text.isEmpty && desc.isNotEmpty) {
          _descCtrl.text = desc;
        }
        if (_priceCtrl.text.isEmpty && price.isNotEmpty) {
          _priceCtrl.text = price;
        }
        if (_phoneCtrl.text.isEmpty && phone.isNotEmpty) {
          _phoneCtrl.text = phone;
        }
        if (decoded['category_id'] is int) {
          _categoryId = decoded['category_id'] as int;
        }
        if (decoded['city_id'] is int) {
          _cityId = decoded['city_id'] as int;
        }
        if (decoded['negotiable'] is bool) {
          _negotiable = decoded['negotiable'] as bool;
        }
        if (decoded['free'] is bool) {
          _free = decoded['free'] as bool;
        }
        if (decoded['hide_phone'] is bool) {
          _hidePhone = decoded['hide_phone'] as bool;
        }
      });
    } catch (_) {}
  }

  void _scheduleSaveDraft() {
    if (_isEditing) return;
    _draftDebounce?.cancel();
    _draftDebounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final payload = jsonEncode({
          'title': _titleCtrl.text,
          'description': _descCtrl.text,
          'price': _priceCtrl.text,
          'phone': _phoneCtrl.text,
          'category_id': _categoryId,
          'city_id': _cityId,
          'negotiable': _negotiable,
          'free': _free,
          'hide_phone': _hidePhone,
        });
        await prefs.setString(_draftKey, payload);
      } catch (_) {}
    });
  }

  Future<void> _clearDraft() async {
    _draftDebounce?.cancel();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey);
    } catch (_) {}
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  void _onFieldChanged() {
    _scheduleSaveDraft();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    _draftDebounce?.cancel();
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
            : (s.isEn
                ? (cat['name_en'] ?? cat['name'] ?? cat['name_fr'])
                : (cat['name_fr'] ?? cat['name'])))
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
            : (s.isEn
                ? (city['name_en'] ?? city['name_fr'] ?? city['name'])
                : (city['name_fr'] ?? city['name'])))
        .toString();
  }

  MoroccanCityCoord _selectedCityCoord() {
    return MarketplaceLocation.resolveTaxonomyCity(
          _cityId,
          _effectiveCities,
        ) ??
        MarketplaceLocation.matchCityByName(_selectedCityName()) ??
        MarketplaceLocation.fallbackCasablanca;
  }

  Future<void> _detectAdGps(AppStrings s) async {
    setState(() => _detectingGps = true);
    try {
      final res = await MarketplaceLocation.detectLocation(tryGps: true);
      if (!mounted) return;
      if (res != null) {
        HapticFeedback.mediumImpact();
        setState(() {
          _adLat = res.lat;
          _adLng = res.lng;
          _cityId = MarketplaceLocation.findTaxonomyCityId(
                res.city,
                _effectiveCities,
              ) ??
              _cityId;
        });
      } else {
        _showToast(
          s.tr(
            'تعذر تحديد موقعك تلقائياً — اختر المدينة من القائمة',
            'Détection GPS impossible — choisissez votre ville',
            appL10n.postAdCouldNotDetectGpsLocation,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _detectingGps = false);
    }
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

  int get _maxPhotos => _state.isProPlusAccount ? 12 : 5;

  Future<void> _pickImages({ImageSource? singleSource}) async {
    HapticFeedback.selectionClick();
    if (singleSource != null) {
      final XFile? file = await _picker.pickImage(
        source: singleSource,
        imageQuality: 82,
      );
      if (file != null && _pickedImages.length < _maxPhotos) {
        setState(() => _pickedImages.add(file));
      }
      return;
    }
    final List<XFile> files = await _picker.pickMultiImage(imageQuality: 82);
    if (files.isNotEmpty) {
      setState(() {
        for (final f in files) {
          if (_pickedImages.length < _maxPhotos) {
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
        .replaceAll(RegExp(r'[\s\u00A0]'), '')
        .replaceAll('٫', '.')
        .replaceAll(',', '.');
    final value = double.tryParse(raw);
    return value != null && value.isFinite && value > 0 ? value : null;
  }

  bool _isStepValid(int step) {
    switch (step) {
      case 0:
        return _effectiveCategories.any(
              (c) => c is Map && int.tryParse('${c['id']}') == _categoryId,
            ) &&
            _effectiveCities.any(
              (c) => c is Map && int.tryParse('${c['id']}') == _cityId,
            );
      case 1:
        return true;
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

  void _showToast(String message, {bool danger = false}) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: danger ? _dlDanger : _dlInk,
          shape: const StadiumBorder(),
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
  }

  void _showStepError(int step) {
    final s = _state.s;
    String msg;
    switch (step) {
      case 0:
        msg = s.tr(
          'يرجى اختيار القسم والمدينة للمتابعة',
          'Veuillez choisir une catégorie et une ville',
          appL10n.postAdPleaseSelectCategoryCity,
        );
        break;
      case 1:
        msg = s.tr(
          'أضف صورة واحدة على الأقل لإعلانك',
          'Ajoutez au moins une photo de votre article',
          appL10n.postAdAddAtLeastOnePhoto,
        );
        break;
      case 2:
        msg = s.tr(
          'أدخل عنواناً واضحاً للإعلان (3 أحرف على الأقل)',
          'Saisissez un titre clair (au moins 3 caractères)',
          appL10n.postAdEnterClearTitleAtLeast,
        );
        break;
      default:
        msg = s.tr(
          'حدد ثمناً صحيحاً أو اختر مجاني، وتحقق من رقم الهاتف',
          'Indiquez un prix valide ou Gratuit et vérifiez le téléphone',
          appL10n.postAdEnterValidPriceFreeVerify,
        );
    }
    HapticFeedback.heavyImpact();
    _showToast(msg);
  }

  Future<void> _showDailyLimitPaywallSheet() async {
    HapticFeedback.heavyImpact();
    final s = _state.s;
    final palette = ApoloDlPalette.of(context);
    final wantUpgrade = await showApoloDlBottomSheet<bool>(
      context,
      headerTitle: 'Apolo Premium',
      media: Container(
        key: const Key('post-ad-daily-limit-sheet'),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: palette.pill,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          CupertinoIcons.checkmark_seal_fill,
          size: 26,
          color: palette.ink,
        ),
      ),
      contentTitle: s.tr(
        'وصلت للحد اليومي المجاني (${AppConfig.maxDailyFreeAds} إعلانات فـ النهار)',
        'Limite gratuite atteinte (${AppConfig.maxDailyFreeAds} annonces/jour)',
        appL10n.postAdDailyFreeLimitReachedMaxdailyfreeads(AppConfig.maxDailyFreeAds),
      ),
      contentDescription: s.tr(
        'الحساب العادي (Personal) يسمح بنشر حتى ${AppConfig.maxDailyFreeAds} إعلانات مجانية كل يوم. اشترك فـ Apolo Premium بـ ${AppConfig.monthlyPremiumPriceMad} د.م/شهر عبر Google Pay للنشر بلا حدود والحصول على متجر Business وشارة Verified.',
        'Le compte Personnel inclut ${AppConfig.maxDailyFreeAds} annonces gratuites par jour. Passez à Apolo Premium (${AppConfig.monthlyPremiumPriceMad} DH/mois via Google Pay) pour publier en illimité avec boutique Business et badge Verified.',
        appL10n.postAdPersonalAccountsIncludeUpMaxdailyfreeads(AppConfig.maxDailyFreeAds, AppConfig.monthlyPremiumPriceMad),
      ),
      actions: [
        ApoloDlButton(
          key: const Key('post-ad-upgrade-premium-btn'),
          label: s.tr(
            'اشترك بـ ${AppConfig.monthlyPremiumPriceMad} د.م/شهر • Google Pay',
            'S’abonner (${AppConfig.monthlyPremiumPriceMad} DH/mois) • Google Pay',
            appL10n.postAdSubscribeMonthlypremiumpricemadMadMoGoogle(AppConfig.monthlyPremiumPriceMad),
          ),
          variant: ApoloDlButtonVariant.primary,
          borderRadius: 999,
          fullWidth: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        ApoloDlButton(
          label: s.tr('حسناً، غداً', 'Plus tard', appL10n.postAdMaybeLater),
          variant: ApoloDlButtonVariant.secondary,
          borderRadius: 999,
          fullWidth: true,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );

    if (wantUpgrade == true && mounted) {
      final activated = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => const ProPlusScreen(initialPlanId: 'monthly'),
        ),
      );
      if (activated == true && mounted) {
        setState(() {});
      }
    }
  }

  void _nextStep() {
    if (!_isEditing && _state.isLoggedIn && _state.hasReachedDailyAdLimit) {
      _showDailyLimitPaywallSheet();
      return;
    }
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
  }

  void _resetWizard() {
    HapticFeedback.selectionClick();
    unawaited(_clearDraft());
    _titleCtrl.clear();
    _descCtrl.clear();
    _priceCtrl.clear();
    setState(() {
      _pickedImages.clear();
      _dynamicValues.clear();
      _categoryId = null;
      _cityId = _state.preferredCityId ?? 1;
      _adLat = null;
      _adLng = null;
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
      _showToast(
        s.tr(
          'يجب تسجيل الدخول أولاً لتتمكن من نشر إعلانك على المنصة',
          'Veuillez vous connecter pour publier votre annonce',
          appL10n.postAdPleaseSignPublishListing,
        ),
        danger: true,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AuthScreen(initialIsLogin: true),
        ),
      );
      return;
    }
    if (!_isEditing && _state.hasReachedDailyAdLimit) {
      await _showDailyLimitPaywallSheet();
      return;
    }

    setState(() => _submitting = true);
    try {
      final desc = _descCtrl.text.trim().length >= 20
          ? _descCtrl.text.trim()
          : '${_titleCtrl.text.trim()} — ${_descCtrl.text.trim().isEmpty ? s.tr('متوفر بحالة ممتازة على أبولو', 'Disponible en très bon état sur Apolo.ma', appL10n.postAdAvailableGreatConditionApolo) : _descCtrl.text.trim()}';

      final map = <String, dynamic>{
        'title': _titleCtrl.text.trim(),
        'description': desc,
        'price': _free ? 0 : _parsedPrice!,
        'category_id': _categoryId,
        'city_id': _cityId,
        if (_adLat != null && _adLng != null) ...{
          'latitude': _adLat,
          'longitude': _adLng,
          'lat': _adLat,
          'lng': _adLng,
        },
        'phone_call': AccountValidation.phone(_phoneCtrl.text) ?? '',
        'phone_whatsapp': AccountValidation.phone(_phoneCtrl.text) ?? '',
        'negotiable': _negotiable ? 1 : 0,
        'free': _free ? 1 : 0,
        'hide_phone': _hidePhone ? 1 : 0,
        'internal_chat': 1,
        'category_fields': jsonEncode(_dynamicValues),
      };

      final List<MultipartFile> allMultipartImages = [];
      for (int i = 0; i < _pickedImages.length && i < _maxPhotos; i++) {
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
          if (!_isEditing) {
            await _state.recordAdPostedToday();
          }
          unawaited(_clearDraft());
          _triggerCelebration();
          return;
        } else {
          final errMsg = res.data is Map
              ? (res.data['message'] ?? 'فشل نشر الإعلان')
              : 'فشل نشر الإعلان';
          _showToast(errMsg.toString(), danger: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        String errMsg = _state.s.tr(
          'تعذر نشر الإعلان، يرجى التأكد من البيانات والمحاولة مجدداً',
          'Échec de la publication de votre annonce',
          appL10n.postAdFailedPublishListing,
        );
        try {
          final dynamic dynErr = e;
          if (dynErr.response?.data is Map) {
            errMsg = (dynErr.response.data['message'] ?? errMsg).toString();
          }
        } catch (_) {}
        _showToast(errMsg, danger: true);
      }
    }
  }

  /// Borderless Dynamic Layer v5.1 `#F6F6F6` input decoration (`1.5px` `#000000` focus border).
  InputDecoration _dlInputDecoration(
    String hint, {
    IconData? icon,
    Widget? suffix,
    TextDirection? hintTextDirection,
  }) {
    return InputDecoration(
      hintText: hint,
      hintTextDirection: hintTextDirection,
      hintStyle: TextStyle(
        color: _dlMuted,
        fontSize: 14.5,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: icon != null ? Icon(icon, color: _dlMuted, size: 18) : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: _dlSurface,
      hoverColor: Colors.transparent,
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
        borderSide: BorderSide(color: _dlInk, width: 1.5),
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

    return Directionality(
      textDirection: s.isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _dlBg,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              if (_state.categories.isEmpty || _state.cities.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Material(
                    color: _dlPill,
                    shape: const StadiumBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: () async {
                        await _state.fetchTaxonomy();
                        if (mounted) setState(() {});
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.refresh,
                              size: 14,
                              color: _dlInk,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                s.tr(
                                  'تعذر تحميل الأقسام والمدن. أعد المحاولة',
                                  'Catégories et villes indisponibles. Réessayer',
                                  appL10n.postAdCategoriesCitiesUnavailableRetry,
                                ),
                                style: TextStyle(
                                  color: _dlInk,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // 1. Dynamic Layer v5.1 Top Nav (`40×40` `#EEEEEE` back + 4-Step `#000000`/`#EEEEEE` pills + fraction)
              SizedBox(
                height: 56,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentStep > 0 || canPop)
                        ApoloDlIconCircleButton(
                          key: const Key('post-ad-back-button'),
                          icon: s.isAr
                              ? CupertinoIcons.chevron_right
                              : CupertinoIcons.chevron_left,
                          backgroundColor: _dlPill,
                          iconColor: _dlInk,
                          onPressed: _prevStep,
                        )
                      else
                        const SizedBox(width: 40, height: 40),
                      Row(
                        children: List.generate(4, (i) {
                          final active = i <= _currentStep;
                          return GestureDetector(
                            onTap: () => _jumpToStep(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: i == _currentStep ? 28 : 10,
                              height: 6,
                              decoration: BoxDecoration(
                                color: active ? _dlInk : _dlPill,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          );
                        }),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${_currentStep + 1}/4',
                          textAlign: TextAlign.end,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _dlMuted,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (!_isEditing)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 540),
                      child: GestureDetector(
                        key: const Key('post-ad-daily-quota-pill'),
                        onTap: _state.isProPlusAccount
                            ? null
                            : () async {
                                final ok =
                                    await Navigator.of(context).push<bool>(
                                  MaterialPageRoute<bool>(
                                    builder: (_) => const ProPlusScreen(
                                      initialPlanId: 'monthly',
                                    ),
                                  ),
                                );
                                if (ok == true && mounted) setState(() {});
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _state.hasReachedDailyAdLimit
                                ? _dlDanger.withValues(alpha: 0.1)
                                : _dlSurface,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _state.isProPlusAccount
                                    ? CupertinoIcons.checkmark_seal_fill
                                    : CupertinoIcons.sparkles,
                                size: 13.5,
                                color: _state.hasReachedDailyAdLimit
                                    ? _dlDanger
                                    : _dlInk,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _state.isProPlusAccount
                                      ? s.tr(
                                          'نشر غير محدود يومياً · Apolo Premium',
                                          'Annonces illimitées · Apolo Premium',
                                          appL10n.postAdUnlimitedDailyAdsApoloPremium,
                                        )
                                      : (_state.hasReachedDailyAdLimit
                                          ? s.tr(
                                              'وصلت لـ ${AppConfig.maxDailyFreeAds}/${AppConfig.maxDailyFreeAds} إعلانات اليوم · ترقية بـ ${AppConfig.monthlyPremiumPriceMad} د.م',
                                              'Limite ${AppConfig.maxDailyFreeAds}/${AppConfig.maxDailyFreeAds} atteinte · Premium ${AppConfig.monthlyPremiumPriceMad} DH',
                                              appL10n.postAdMaxdailyfreeadsMaxdailyfreeads2DailyLimitReached(AppConfig.maxDailyFreeAds, AppConfig.maxDailyFreeAds, AppConfig.monthlyPremiumPriceMad),
                                            )
                                          : s.tr(
                                              'الحد المجاني اليوم: ${_state.todayPostedAdsCount}/${AppConfig.maxDailyFreeAds} إعلانات · غير محدود مع Premium',
                                              'Quota gratuit : ${_state.todayPostedAdsCount}/${AppConfig.maxDailyFreeAds} aujourd’hui · Illimité en Premium',
                                              appL10n.postAdTodayTodaypostedadscountMaxdailyfreeadsFreeAds(_state.todayPostedAdsCount, AppConfig.maxDailyFreeAds),
                                            )),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.8,
                                    fontWeight: FontWeight.w700,
                                    color: _state.hasReachedDailyAdLimit
                                        ? _dlDanger
                                        : _dlMuted,
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

              // 2. Step Stage
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 540),
                    child: ListView(
                      key: const Key('post-ad-scroll-view'),
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        20,
                        8,
                        20,
                        canPop ? 24 : 128,
                      ),
                      children: [
                        _buildStepHeader(s),
                        const SizedBox(height: 22),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, anim) {
                            final offsetTween = Tween<Offset>(
                              begin: Offset(_goingForward ? 0.05 : -0.05, 0),
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
                ),
              ),

              // 3. Sticky Capsule Bottom Bar
              _buildBottomWizardBar(s, canPop),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepHeader(AppStrings s) {
    String title;
    String subtitle;

    switch (_currentStep) {
      case 0:
        title = s.tr(
          'فين بغيتي تحط إعلانك؟',
          'Où souhaitez-vous publier ?',
          appL10n.postAdWhereAreYouListing,
        );
        subtitle = s.tr(
          'اختر القسم المناسب والمدينة باش المشترين القراب ليك يلقاوه بسهولة',
          'Choisissez la catégorie et votre ville pour cibler les acheteurs',
          appL10n.postAdChooseCategoryCitySoNearby,
        );
        break;
      case 1:
        title = s.tr(
          'أضف صور واضحة لإعلانك',
          'Ajoutez des photos nettes',
          appL10n.postAdAddClearPhotos,
        );
        subtitle = s.tr(
          'الإعلانات اللي فيها صور حقيقية وواضحة كتتباع أسرع بـ 3 مرات',
          'Les annonces avec photos réelles se vendent 3x plus vite',
          appL10n.postAdListingsRealClearPhotosSell,
        );
        break;
      case 2:
        title = s.tr(
          'شنو كتبيع؟ عطيه عنوان قوي',
          'Décrivez votre article',
          appL10n.postAdDescribeItem,
        );
        subtitle = s.tr(
          'اكتب الماركة، الموديل، والحالة باش تجاوب على أسئلة المشتري',
          'Un titre précis et une description honnête inspirent confiance',
          appL10n.postAdClearTitleHonestDescriptionBuild,
        );
        break;
      default:
        title = s.tr(
          'حدد الثمن وطريقة التواصل',
          'Fixez votre prix et contact',
          appL10n.postAdSetPriceContact,
        );
        subtitle = s.tr(
          'حدد ثمن مناسب للسوق وراجع معاينة الإعلان قبل النشر',
          'Indiquez un prix attractif et vérifiez l\'aperçu avant de publier',
          appL10n.postAdSetFairPriceReviewListing,
        );
        break;
    }

    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _dlSurface,
            shape: BoxShape.circle,
          ),
          child: Image.asset(
            _step3DAsset(),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => Icon(
              CupertinoIcons.cube_box_fill,
              size: 32,
              color: _dlInk,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w700,
            color: _dlInk,
            letterSpacing: AppTypography.trackingForContext(context, -0.4),
          ),
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: _dlMuted,
              fontWeight: FontWeight.w400,
            ),
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

  Widget _buildStep1CategoryAndCity(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.tr('المدينة', 'Ville', appL10n.accountOnboardingFormCity),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _dlInk,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
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
                      : (s.isFr
                          ? (city['name_fr'] ?? city['name'])
                          : (city['name_en'] ?? city['name_fr'] ?? city['name'])))
                  .toString();

              return Material(
                color: selected ? _dlInk : _dlPill,
                shape: const StadiumBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _cityId = id;
                      _adLat = null;
                      _adLng = null;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.location_solid,
                          size: 13,
                          color: selected ? _dlBg : _dlMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected ? _dlBg : _dlInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Builder(
          builder: (context) {
            final cityCoord = _selectedCityCoord();
            final mapLat = _adLat ?? cityCoord.lat;
            final mapLng = _adLng ?? cityCoord.lng;
            final cityLabel = _selectedCityName().isNotEmpty
                ? _selectedCityName()
                : cityCoord.labelForLang(s.lang);
            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _dlSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  RealMarketplaceMap(
                    lat: mapLat,
                    lng: mapLng,
                    cityLabel: cityLabel,
                    circleRadiusKm: 4.5,
                    height: 148,
                    borderRadius: 14,
                    interactive: true,
                    onCenterChanged: (pos) {
                      setState(() {
                        _adLat = pos.lat;
                        _adLng = pos.lng;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Material(
                    color: _dlBg,
                    shape: const StadiumBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: const Key('post-ad-gps-btn'),
                      customBorder: const StadiumBorder(),
                      onTap: _detectingGps ? null : () => _detectAdGps(s),
                      child: SizedBox(
                        height: 40,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_detectingGps)
                                SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _dlInk,
                                  ),
                                )
                              else
                                Icon(
                                  CupertinoIcons.location_fill,
                                  size: 15,
                                  color: _dlInk,
                                ),
                              const SizedBox(width: 7),
                              Flexible(
                                child: Text(
                                  _adLat != null
                                      ? s.tr(
                                          'تم تحديد موقع الإعلان (GPS)',
                                          'Position GPS enregistrée',
                                          appL10n.postAdGpsLocationSet,
                                        )
                                      : s.tr(
                                          'تحديد موقع الإعلان بـ GPS',
                                          'Détecter la position (GPS)',
                                          appL10n.postAdDetectAdLocationGps,
                                        ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: _dlInk,
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
              ),
            );
          },
        ),
        const SizedBox(height: 22),
        Text(
          s.tr('اختر القسم', 'Catégorie', appL10n.adDetailCategory),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _dlInk,
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
            childAspectRatio: 2.1,
          ),
          itemCount: _effectiveCategories.length,
          itemBuilder: (context, index) {
            final c = _effectiveCategories[index];
            final int? id = int.tryParse(c['id'].toString());
            final bool active = _categoryId == id;
            final String label = (s.isAr
                    ? (c['name_ar'] ?? c['name'])
                    : (s.isFr
                        ? (c['name_fr'] ?? c['name'])
                        : (c['name_en'] ?? c['name'] ?? c['name_fr'])))
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
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: _dlSurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: active ? _dlInk : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: _dlBg,
                        shape: BoxShape.circle,
                      ),
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
                              active ? FontWeight.w700 : FontWeight.w600,
                          color: _dlInk,
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
              color: _dlSurface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _dlBg,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    totalPhotos > 0
                        ? CupertinoIcons.photo_on_rectangle
                        : CupertinoIcons.camera_fill,
                    size: 25,
                    color: _dlInk,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  totalPhotos == 0
                      ? s.tr(
                          'اضغط لإضافة صور الإعلان',
                          'Appuyez pour ajouter des photos',
                          appL10n.postAdTapAddPhotos,
                        )
                      : s.tr(
                          'إضافة المزيد من الصور ($totalPhotos/8)',
                          'Ajouter plus de photos ($totalPhotos/8)',
                          appL10n.postAdAddMorePhotosTotalphotos8(totalPhotos),
                        ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _dlInk,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.tr(
                    'الصورة الأولى غادي تكون هي صورة الغلاف الرئيسية',
                    'La première photo sera la couverture principale',
                    appL10n.postAdFirstPhotoWillBeUsed,
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: _dlMuted),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _miniActionChip(
                      icon: CupertinoIcons.photo_fill,
                      label: s.tr('المعرض', 'Galerie', appL10n.postAdGallery),
                      onTap: () => _pickImages(),
                    ),
                    _miniActionChip(
                      icon: CupertinoIcons.camera_fill,
                      label: s.tr('الكاميرا', 'Caméra', appL10n.callCamera),
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
            children: [
              Expanded(
                child: Text(
                  s.tr(
                    'الصور المختارة',
                    'Photos sélectionnées',
                    appL10n.postAdSelectedPhotos,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _dlInk,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$totalPhotos / 8',
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _dlInk,
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
                      color: _dlSurface,
                      borderRadius: BorderRadius.circular(18),
                      border: isCover
                          ? Border.all(color: _dlInk, width: 2)
                          : Border.all(color: _dlSeparator),
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
                                    ? Image.memory(
                                        snap.data!,
                                        fit: BoxFit.cover,
                                      )
                                    : Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: _dlInk,
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
                          color: _dlInk,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          s.tr('الغلاف', 'Principale', appL10n.postAdCover),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _dlOnInk,
                          ),
                        ),
                      ),
                    ),
                  if (_pickedImages.isNotEmpty)
                    PositionedDirectional(
                      top: 4,
                      end: 4,
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _pickedImages.removeAt(idx)),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _dlBg,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            CupertinoIcons.xmark,
                            size: 13,
                            color: _dlInk,
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
    return Material(
      color: _dlBg,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: _dlInk),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _dlInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep3DetailsAndSpecs(AppStrings s) {
    final dynamicFields = _fieldsForCategory(_categoryId);
    final int titleLen = _titleCtrl.text.trim().length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                s.tr('عنوان الإعلان', 'Titre de l\'annonce', appL10n.postAdListingTitle),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _dlInk,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              titleLen >= 3
                  ? s.tr('ممتاز ✓', 'Parfait ✓', appL10n.postAdGreat)
                  : '$titleLen / 3+',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: titleLen >= 3 ? _dlInk : _dlMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('post-ad-title-field'),
          controller: _titleCtrl,
          cursorColor: _dlInk,
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
            color: _dlInk,
          ),
          decoration: _dlInputDecoration(
            s.tr(
              'مثال: iPhone 15 Pro Max 256GB بحالة الجديد',
              'Ex: iPhone 15 Pro Max 256Go comme neuf',
              appL10n.postAdEGIphone15Pro,
            ),
            icon: CupertinoIcons.textbox,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          s.tr(
            'الوصف التفصيلي',
            'Description détaillée',
            appL10n.postAdDetailedDescription,
          ),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _dlInk,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('post-ad-desc-field'),
          controller: _descCtrl,
          maxLines: 4,
          cursorColor: _dlInk,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: _dlInk,
          ),
          decoration: _dlInputDecoration(
            s.tr(
              'اذكر الحالة، الملحقات، وسبب البيع لزيادة ثقة المشترين...',
              'Précisez l\'état, les accessoires et les détails importants...',
              appL10n.postAdMentionConditionIncludedAccessoriesKey,
            ),
          ),
        ),
        if (dynamicFields.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text(
            s.tr(
              'مواصفات إضافية',
              'Caractéristiques spécifiques',
              appL10n.postAdSpecifications,
            ),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _dlInk,
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
                  decoration: _dlInputDecoration(label),
                  dropdownColor: _dlBg,
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
                cursorColor: _dlInk,
                keyboardType: type == 'number'
                    ? TextInputType.number
                    : TextInputType.text,
                decoration: _dlInputDecoration(label),
                onChanged: (v) => _dynamicValues[key] = v,
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildStep4PriceContactAndPreview(AppStrings s) {
    final String previewPrice = _free
        ? s.tr('مجاني', 'Gratuit', appL10n.adDetailFree)
        : (_priceCtrl.text.trim().isNotEmpty
            ? '${_priceCtrl.text.trim()} MAD'
            : '— MAD');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_free) ...[
          Text(
            s.tr('الثمن (بالدرهم)', 'Prix (en MAD)', appL10n.postAdPriceMad),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _dlInk,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('post-ad-price-field'),
            controller: _priceCtrl,
            cursorColor: _dlInk,
            textDirection: TextDirection.ltr,
            textAlign: s.isAr ? TextAlign.end : TextAlign.start,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _dlInk,
            ),
            decoration: _dlInputDecoration(
              s.tr('أدخل الثمن بالدرهم', 'Ex: 2500', appL10n.postAdEG2500),
              icon: CupertinoIcons.tag_solid,
              hintTextDirection: s.isAr ? TextDirection.rtl : TextDirection.ltr,
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
                        color: _dlBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'MAD',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _dlInk,
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
            _DlOptionPill(
              label: s.tr('قابل للتفاوض', 'Prix négociable', appL10n.negotiableBadge),
              icon: CupertinoIcons.hand_thumbsup_fill,
              active: _negotiable,
              onTap: () => setState(() => _negotiable = !_negotiable),
            ),
            _DlOptionPill(
              label: s.tr('مجاني', 'Gratuit', appL10n.adDetailFree),
              icon: CupertinoIcons.gift_fill,
              active: _free,
              onTap: () => setState(() => _free = !_free),
            ),
            _DlOptionPill(
              label: s.tr(
                'إخفاء الرقم (شات فقط)',
                'Masquer le numéro',
                appL10n.postAdHideNumber,
              ),
              icon: CupertinoIcons.lock_shield_fill,
              active: _hidePhone,
              onTap: () => setState(() => _hidePhone = !_hidePhone),
            ),
          ],
        ),
        if (!_hidePhone) ...[
          const SizedBox(height: 20),
          Text(
            s.tr(
              'رقم الهاتف والواتساب',
              'Téléphone & WhatsApp',
              appL10n.editProfilePhoneWhatsapp,
            ),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _dlInk,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneCtrl,
            cursorColor: _dlInk,
            textDirection: TextDirection.ltr,
            keyboardType: TextInputType.phone,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              color: _dlInk,
            ),
            decoration: _dlInputDecoration(
              '06XXXXXXXX',
              icon: CupertinoIcons.phone_fill,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          s.tr(
            'معاينة الإعلان قبل النشر',
            'Aperçu de votre annonce',
            appL10n.postAdListingPreview,
          ),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _dlInk,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _dlSurface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 76,
                height: 76,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: _dlBg,
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
                                : Icon(
                                    CupertinoIcons.photo,
                                    color: _dlMuted,
                                  ),
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
                          ? s.tr(
                              'عنوان الإعلان',
                              'Titre de l\'annonce',
                              appL10n.postAdListingTitle,
                            )
                          : _titleCtrl.text.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: _dlInk,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      previewPrice,
                      textDirection: _free ? null : TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _dlInk,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.location_solid,
                          size: 13,
                          color: _dlMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${_selectedCategoryName()} • ${_selectedCityName()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: _dlMuted,
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

  Widget _buildBottomWizardBar(AppStrings s, bool canPop) {
    final bool isLast = _currentStep == 3;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + (canPop ? 16 : 92),
      ),
      color: _dlBg,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Row(
            children: [
              if (_currentStep > 0) ...[
                Flexible(
                  flex: 0,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 132),
                    child: ApoloDlButton(
                      label: s.tr('السابق', 'Retour', appL10n.backButton),
                      variant: ApoloDlButtonVariant.secondary,
                      borderRadius: 999,
                      height: 54,
                      onPressed: _prevStep,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ApoloDlButton(
                  key: const Key('post-ad-continue-btn'),
                  label: isLast
                      ? (_isEditing
                          ? s.tr('حفظ التعديلات', 'Enregistrer', appL10n.saveChangesButton)
                          : s.tr(
                              'نشر الإعلان الآن',
                              'Publier mon annonce',
                              appL10n.postAdPublishNow,
                            ))
                      : s.tr('المتابعة', 'Continuer', appL10n.continueButton),
                  leadingIcon: isLast
                      ? CupertinoIcons.checkmark_circle_fill
                      : null,
                  variant: ApoloDlButtonVariant.primary,
                  borderRadius: 999,
                  height: 54,
                  fullWidth: true,
                  isLoading: _submitting,
                  onPressed: _submitting ? null : _nextStep,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCelebrationScreen(AppStrings s) {
    return Directionality(
      textDirection: s.isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _dlBg,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 124,
                          height: 124,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: _dlSurface,
                            shape: BoxShape.circle,
                          ),
                          child: Image.asset(
                            _assetForCategory(_selectedCategoryName()),
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              CupertinoIcons.checkmark_seal_fill,
                              size: 44,
                              color: _dlInk,
                            ),
                          ),
                        ),
                        PositionedDirectional(
                          bottom: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _dlInk,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.checkmark_alt,
                                  size: 13,
                                  color: _dlOnInk,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  context.l10n.liveBadgeLabel,
                                  textDirection: TextDirection.ltr,
                                  style: TextStyle(
                                    color: _dlOnInk,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _isEditing
                          ? s.tr(
                              'تم تحديث إعلانك بنجاح',
                              'Annonce mise à jour',
                              appL10n.postAdListingUpdated,
                            )
                          : s.tr(
                              'مبروك! تم نشر إعلانك بنجاح',
                              'Félicitations ! Annonce publiée',
                              appL10n.postAdListingIsLive,
                            ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: _dlInk,
                        letterSpacing:
                            AppTypography.trackingForContext(context, -0.4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.tr(
                        'إعلانك دابا واجد وغادي يبان لآلاف المشترين فـ Apolo.ma.',
                        'Votre annonce est maintenant visible par les acheteurs sur Apolo.ma.',
                        appL10n.postAdListingIsNowVisibleBuyers,
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: _dlMuted,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _dlSurface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _dlBg,
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
                                      ? s.tr(
                                          'إعلانك الجديد',
                                          'Votre nouvelle annonce',
                                          appL10n.postAdNewListing,
                                        )
                                      : _titleCtrl.text.trim(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    color: _dlInk,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${_selectedCategoryName()} • ${_selectedCityName()}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: _dlMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ApoloDlButton(
                      label: s.tr(
                        'العودة للرئيسية',
                        'Retour à l\'accueil',
                        appL10n.postAdBackHome,
                      ),
                      variant: ApoloDlButtonVariant.primary,
                      borderRadius: 999,
                      height: 54,
                      fullWidth: true,
                      onPressed: () {
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
                    ),
                    const SizedBox(height: 10),
                    ApoloDlButton(
                      label: s.tr(
                        'إضافة إعلان آخر',
                        'Publier une autre annonce',
                        appL10n.postAdPostAnotherListing,
                      ),
                      leadingIcon: CupertinoIcons.add,
                      variant: ApoloDlButtonVariant.secondary,
                      borderRadius: 999,
                      height: 50,
                      fullWidth: true,
                      onPressed: _resetWizard,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DlOptionPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _DlOptionPill({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ApoloDlPalette.of(context);
    final maxW = (MediaQuery.sizeOf(context).width - 48).clamp(120.0, 480.0);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxW),
      child: Material(
        color: active ? palette.ink : palette.pill,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14.5,
                  color: active ? palette.onInk : palette.muted,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: active ? palette.onInk : palette.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
