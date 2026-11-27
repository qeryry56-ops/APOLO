import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import '../theme/app_typography.dart';
import '../widgets/dl_settings_kit.dart';
import 'pro_plus_screen.dart';

/// Shared helper for localized Business Category metadata across Profile, Stores & Wizard.
class ApoloBusinessCategories {
  static const List<Map<String, dynamic>> all = [
    {
      'id': 'vehicles',
      'icon': CupertinoIcons.car_detailed,
      'ar': 'معرض سيارات ومركبات',
      'fr': 'Concessionnaire & Véhicules',
      'en': 'Auto & Vehicles',
    },
    {
      'id': 'realestate',
      'icon': CupertinoIcons.building_2_fill,
      'ar': 'وكالة عقارية وإسكان',
      'fr': 'Agence Immobilière',
      'en': 'Real Estate Agency',
    },
    {
      'id': 'electronics',
      'icon': CupertinoIcons.device_phone_portrait,
      'ar': 'هواتف وإلكترونيات',
      'fr': 'Téléphones & Électronique',
      'en': 'Phones & Electronics',
    },
    {
      'id': 'fashion',
      'icon': CupertinoIcons.bag_fill,
      'ar': 'ملابس، أزياء ومجوهرات',
      'fr': 'Mode, Vêtements & Bijoux',
      'en': 'Fashion & Jewelry',
    },
    {
      'id': 'home',
      'icon': CupertinoIcons.house_fill,
      'ar': 'أثاث، ديكور وتجهيز',
      'fr': 'Maison, Meubles & Déco',
      'en': 'Home & Furniture',
    },
    {
      'id': 'beauty',
      'icon': CupertinoIcons.sparkles,
      'ar': 'بارافارماسي وتجميل',
      'fr': 'Parapharmacie & Beauté',
      'en': 'Beauty & Parapharmacy',
    },
    {
      'id': 'industrial',
      'icon': CupertinoIcons.hammer_fill,
      'ar': 'معدات مهنية وبريكولاج',
      'fr': 'Équipement Pro & Bricolage',
      'en': 'Pro Tools & Industrial',
    },
    {
      'id': 'services',
      'icon': CupertinoIcons.briefcase_fill,
      'ar': 'خدمات وحرف مهنية',
      'fr': 'Services & Artisans',
      'en': 'Professional Services',
    },
    {
      'id': 'general',
      'icon': Icons.storefront_rounded,
      'ar': 'متجر شامل ومتنوع',
      'fr': 'Boutique Générale',
      'en': 'General Store',
    },
  ];

  static String labelFor(String? categoryId, AppStrings s) {
    if (categoryId == null || categoryId.trim().isEmpty) {
      return s.tr('متجر احترافي', 'Boutique Pro', 'Business Store');
    }
    final match = all.firstWhere(
      (c) => c['id'] == categoryId.trim().toLowerCase(),
      orElse: () => all.last,
    );
    return s.tr(
      match['ar'] as String,
      match['fr'] as String,
      match['en'] as String,
    );
  }
}

/// Instagram-Style 3-Step Switch to Business Wizard & Business Identity Editor.
class BusinessSwitchScreen extends StatefulWidget {
  final bool isEditing;

  const BusinessSwitchScreen({
    super.key,
    this.isEditing = false,
  });

  @override
  State<BusinessSwitchScreen> createState() => _BusinessSwitchScreenState();
}

class _BusinessSwitchScreenState extends State<BusinessSwitchScreen> {
  final AppState _state = AppState();

  int _step = 1; // 1: Category, 2: Store Identity & Map/Hours, 3: Contact & Direct Order
  String _selectedCategory = 'general';
  bool _directOrderEnabled = true;
  bool _saving = false;
  String? _error;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _mapsUrlCtrl;
  late final TextEditingController _hoursCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _greetingCtrl;

  static const List<String> _hourPresets = [
    '09:00 - 20:00',
    '09:00 - 22:00',
    '10:00 - 19:00',
    '24/7',
  ];

  @override
  void initState() {
    super.initState();
    final existing = _state.activeStore ?? _state.pausedStore;
    final user = _state.currentUser;

    _selectedCategory =
        (existing?['business_category'] ?? 'general').toString().trim();
    if (!ApoloBusinessCategories.all.any((c) => c['id'] == _selectedCategory)) {
      _selectedCategory = 'general';
    }

    _directOrderEnabled = existing?['direct_order_enabled'] != false;

    _nameCtrl = TextEditingController(
      text: (existing?['name'] ?? user?['name'] ?? '').toString().trim(),
    );
    _bioCtrl = TextEditingController(
      text: (existing?['description'] ?? user?['bio'] ?? '').toString().trim(),
    );
    _locationCtrl = TextEditingController(
      text: (existing?['location'] ?? '').toString().trim(),
    );
    _mapsUrlCtrl = TextEditingController(
      text: (existing?['maps_url'] ?? '').toString().trim(),
    );
    _hoursCtrl = TextEditingController(
      text: (existing?['working_hours'] ?? '09:00 - 20:00').toString().trim(),
    );
    _phoneCtrl = TextEditingController(
      text: (existing?['phone'] ?? user?['phone'] ?? '').toString().trim(),
    );
    _greetingCtrl = TextEditingController(
      text: _state.autoGreeting.isNotEmpty
          ? _state.autoGreeting
          : _state.s.tr(
              'مرحباً بك في متجرنا على Apolo! كيف يمكننا مساعدتك اليوم؟',
              'Bienvenue dans notre boutique sur Apolo ! Comment pouvons-nous vous aider ?',
              'Welcome to our store on Apolo! How can we help you today?',
            ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _locationCtrl.dispose();
    _mapsUrlCtrl.dispose();
    _hoursCtrl.dispose();
    _phoneCtrl.dispose();
    _greetingCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    HapticFeedback.selectionClick();
    setState(() => _error = null);
    if (_step == 2 && _nameCtrl.text.trim().length < 2) {
      setState(() {
        _error = _state.s.tr(
          'يرجى إدخال اسم المتجر أو النشاط التجاري (حرفين على الأقل).',
          'Veuillez saisir le nom de votre boutique (au moins 2 caractères).',
          'Please enter a store name (at least 2 characters).',
        );
      });
      return;
    }
    if (_step < 3) {
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  void _prevStep() {
    HapticFeedback.selectionClick();
    if (_step > 1) {
      setState(() {
        _error = null;
        _step--;
      });
    } else {
      Navigator.of(context).pop(false);
    }
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!_state.isProPlusAccount) {
      final activated = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => const ProPlusScreen(initialPlanId: 'monthly'),
        ),
      );
      if (activated != true || !mounted || !_state.isProPlusAccount) {
        return;
      }
    }
    if (_nameCtrl.text.trim().length < 2) {
      setState(() {
        _error = _state.s.tr(
          'يرجى إدخال اسم المتجر أولاً.',
          'Veuillez saisir le nom de votre boutique.',
          'Please enter your store name.',
        );
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await _state.switchToBusiness(
        storeName: _nameCtrl.text,
        businessCategory: _selectedCategory,
        description: _bioCtrl.text,
        location: _locationCtrl.text,
        mapsUrl: _mapsUrlCtrl.text,
        workingHours: _hoursCtrl.text,
        phone: _phoneCtrl.text,
        directOrderEnabled: _directOrderEnabled,
        autoGreetingText: _greetingCtrl.text,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppConfig.success,
          content: Text(
            widget.isEditing
                ? _state.s.tr(
                    'تم حفظ إعدادات متجرك بنجاح!',
                    'Paramètres de la boutique enregistrés !',
                    'Business profile updated!',
                  )
                : _state.s.tr(
                    'مبروك! تم تفعيل حساب الأعمال (Business) ومتجرك الموثّق بنجاح',
                    'Félicitations ! Votre boutique Business vérifiée est active',
                    'Your Verified Business store is now active!',
                  ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = _state.s.tr(
          'تعذر حفظ إعدادات الأعمال حالياً. تحقق من الاتصال وحاول مجدداً.',
          'Impossible d’enregistrer pour le moment. Réessayez.',
          'Could not save business profile. Please try again.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final isAr = s.isAr;
    final palette = ApoloDlPalette.of(context);
    final hasPausedStore = !widget.isEditing && _state.pausedStore != null;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: palette.bg,
        body: SafeArea(
          child: Column(
            children: [
              ApoloDlTopNav(
                title: widget.isEditing
                    ? s.tr(
                        'إعدادات المتجر والأعمال',
                        'Paramètres Business',
                        'Business Settings',
                      )
                    : s.tr(
                        'التحويل إلى حساب Business',
                        'Passer au compte Business',
                        'Switch to Business',
                      ),
                size: ApoloDlTopNavSize.md,
              ),

              // Step progress indicator
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
                child: Row(
                  children: List.generate(3, (idx) {
                    final active = (idx + 1) <= _step;
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsetsDirectional.only(
                          end: idx < 2 ? 6 : 0,
                        ),
                        decoration: BoxDecoration(
                          color: active ? palette.ink : palette.separator,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                      children: [
                        if (hasPausedStore && _step == 1)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: palette.groupCard,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.arrow_2_circlepath_circle_fill,
                                  color: palette.ink,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    s.tr(
                                      'وجدنا بيانات متجرك السابق محفوظة! راجعها وفعّل حسابك في ثانية.',
                                      'Vos informations de boutique précédentes ont été restaurées !',
                                      'Your previous store details are ready to reactivate!',
                                    ),
                                    style: TextStyle(
                                      fontSize: 12.8,
                                      fontWeight: FontWeight.w600,
                                      color: palette.ink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (_error != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: palette.dangerSoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _error!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: palette.danger,
                              ),
                            ),
                          ),

                        if (_step == 1) _buildStep1Category(s, palette),
                        if (_step == 2) _buildStep2Identity(s, palette),
                        if (_step == 3) _buildStep3Tools(s, palette),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Action Bar
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                decoration: BoxDecoration(
                  color: palette.bg,
                  border: Border(
                    top: BorderSide(color: palette.separator, width: 0.8),
                  ),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Row(
                    children: [
                      if (_step > 1) ...[
                        Expanded(
                          flex: 1,
                          child: ApoloDlButton(
                            label: s.tr('رجوع', 'Retour', 'Back'),
                            variant: ApoloDlButtonVariant.secondary,
                            borderRadius: 999,
                            fullWidth: true,
                            onPressed: _saving ? null : _prevStep,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        flex: 2,
                        child: ApoloDlButton(
                          key: const Key('business-wizard-continue'),
                          label: _saving
                              ? s.tr('جاري الحفظ...', 'Enregistrement...', 'Saving...')
                              : (_step < 3
                                  ? s.tr('متابعة', 'Continuer', 'Continue')
                                  : (widget.isEditing
                                      ? s.tr(
                                          'حفظ التعديلات',
                                          'Enregistrer',
                                          'Save Changes',
                                        )
                                      : s.tr(
                                          'تفعيل حساب Business مجاناً',
                                          'Activer Business gratuitement',
                                          'Activate Free Business',
                                        ))),
                          variant: ApoloDlButtonVariant.primary,
                          borderRadius: 999,
                          fullWidth: true,
                          onPressed: _saving ? null : _nextStep,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1Category(AppStrings s, ApoloDlPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.tr(
            'ما هو مجال نشاطك التجاري؟',
            'Quelle est votre catégorie d’activité ?',
            'What best describes your business?',
          ),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: palette.ink,
            letterSpacing: AppTypography.trackingForContext(context, -0.4),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          s.tr(
            'ستظهر هذه الفئة تحت اسم متجرك في بروفايلك وفي قسم المتاجر تماماً مثل Instagram.',
            'Cette catégorie s’affichera sur votre profil professionnel et votre boutique.',
            'This category badge appears under your name on your profile and store.',
          ),
          style: TextStyle(fontSize: 13.5, color: palette.muted, height: 1.4),
        ),
        const SizedBox(height: 18),
        ...ApoloBusinessCategories.all.map((cat) {
          final id = cat['id'] as String;
          final selected = _selectedCategory == id;
          final label = ApoloBusinessCategories.labelFor(id, s);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              key: Key('business-cat-$id'),
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedCategory = id);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: selected
                      ? palette.ink.withValues(alpha: 0.06)
                      : palette.groupCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? palette.ink : Colors.transparent,
                    width: 1.6,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: selected ? palette.ink : palette.bg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        cat['icon'] as IconData,
                        size: 19,
                        color: selected ? palette.bg : palette.ink,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w600,
                          color: palette.ink,
                        ),
                      ),
                    ),
                    Icon(
                      selected
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.circle,
                      size: 20,
                      color: selected ? palette.ink : palette.muted,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStep2Identity(AppStrings s, ApoloDlPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.tr(
            'هوية المتجر، أوقات العمل والموقع',
            'Identité, horaires et localisation',
            'Store identity, hours & location',
          ),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: palette.ink,
            letterSpacing: AppTypography.trackingForContext(context, -0.4),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          s.tr(
            'يظهر متجرك تلقائياً في قسم المتاجر بمجرد وجود إعلان واحد نشط على الأقل.',
            'Votre boutique apparaît automatiquement dès que vous avez au moins une annonce active.',
            'Your store appears in the Stores directory once you have at least 1 active listing.',
          ),
          style: TextStyle(fontSize: 13.5, color: palette.muted, height: 1.4),
        ),
        const SizedBox(height: 18),
        _buildFieldLabel(
          s.tr('اسم المتجر / النشاط *', 'Nom de la boutique *', 'Store name *'),
          palette,
        ),
        _buildInput(
          key: const Key('business-name-input'),
          controller: _nameCtrl,
          hint: s.tr('مثال: Auto Luxury Casa', 'Ex: Auto Luxury Casa', 'e.g. Auto Casa'),
          palette: palette,
        ),
        const SizedBox(height: 14),
        _buildFieldLabel(
          s.tr('نبذة قصيرة عن المتجر', 'Description de la boutique', 'Bio / Description'),
          palette,
        ),
        _buildInput(
          key: const Key('business-bio-input'),
          controller: _bioCtrl,
          maxLines: 3,
          hint: s.tr(
            'عرّف الزبناء بجودة سلعك، الضمان، والتوصيل...',
            'Présentez vos produits, garanties et livraison...',
            'Tell customers about your products & service...',
          ),
          palette: palette,
        ),
        const SizedBox(height: 14),
        _buildFieldLabel(
          s.tr('المدينة والعنوان التجاري', 'Ville et adresse', 'City & address'),
          palette,
        ),
        _buildInput(
          key: const Key('business-location-input'),
          controller: _locationCtrl,
          hint: s.tr(
            'مثال: المعاريف، الدار البيضاء',
            'Ex: Maarif, Casablanca',
            'e.g. Maarif, Casablanca',
          ),
          palette: palette,
        ),
        const SizedBox(height: 14),
        _buildFieldLabel(
          s.tr(
            'رابط المحل على Google Maps (اختياري)',
            'Lien Google Maps (optionnel)',
            'Google Maps link (optional)',
          ),
          palette,
        ),
        _buildInput(
          key: const Key('business-maps-input'),
          controller: _mapsUrlCtrl,
          hint: 'https://maps.google.com/...',
          ltr: true,
          palette: palette,
        ),
        const SizedBox(height: 14),
        _buildFieldLabel(
          s.tr('أوقات العمل', 'Horaires d’ouverture', 'Working hours'),
          palette,
        ),
        _buildInput(
          key: const Key('business-hours-input'),
          controller: _hoursCtrl,
          hint: '09:00 - 20:00',
          ltr: true,
          palette: palette,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _hourPresets.map((preset) {
            final active = _hoursCtrl.text.trim() == preset;
            return GestureDetector(
              onTap: () => setState(() => _hoursCtrl.text = preset),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: active ? palette.ink : palette.groupCard,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  preset,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: active ? palette.bg : palette.ink,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep3Tools(AppStrings s, ApoloDlPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.tr(
            'أدوات التواصل والبيع الفوري',
            'Outils de contact et commande directe',
            'Contact & direct order tools',
          ),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: palette.ink,
            letterSpacing: AppTypography.trackingForContext(context, -0.4),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          s.tr(
            'سهّل على الزبناء الطلب من متجرك والرد عليهم بسرعة في الشات.',
            'Facilitez les commandes directes et les réponses rapides dans le chat.',
            'Enable 1-tap orders and automatic chat greetings.',
          ),
          style: TextStyle(fontSize: 13.5, color: palette.muted, height: 1.4),
        ),
        const SizedBox(height: 18),
        _buildFieldLabel(
          s.tr('رقم هاتف المتجر للاتصال المباشر', 'Téléphone professionnel', 'Business phone'),
          palette,
        ),
        _buildInput(
          key: const Key('business-phone-input'),
          controller: _phoneCtrl,
          hint: '+212 6XX XXX XXX',
          ltr: true,
          keyboardType: TextInputType.phone,
          palette: palette,
        ),
        const SizedBox(height: 16),

        // Direct Order selectable option card
        GestureDetector(
          key: const Key('business-direct-order-toggle'),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _directOrderEnabled = !_directOrderEnabled);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.groupCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _directOrderEnabled ? palette.ink : Colors.transparent,
                width: 1.4,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _directOrderEnabled ? palette.ink : palette.bg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.bag_fill,
                    size: 19,
                    color: _directOrderEnabled ? palette.bg : palette.ink,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.tr(
                          'تفعيل زر "طلب مباشر" في المتجر',
                          'Activer le bouton « Commande directe »',
                          'Enable "Direct Order" button on store',
                        ),
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: palette.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        s.tr(
                          'يستقبل متجرك طلبيات الزبناء مباشرة مع الاسم والمدينة والهاتف.',
                          'Recevez les commandes clients avec nom, ville et téléphone.',
                          'Receive instant orders with customer details.',
                        ),
                        style: TextStyle(fontSize: 12.2, color: palette.muted),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _directOrderEnabled
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.circle,
                  color: _directOrderEnabled ? palette.ink : palette.muted,
                  size: 22,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),
        _buildFieldLabel(
          s.tr(
            'رسالة الترحيب التلقائية في الشات',
            'Message d’accueil automatique (Chat)',
            'Auto-greeting message in Chat',
          ),
          palette,
        ),
        _buildInput(
          key: const Key('business-greeting-input'),
          controller: _greetingCtrl,
          maxLines: 3,
          hint: s.tr(
            'مرحباً بك في متجرنا! كيف يمكننا مساعدتك؟',
            'Bienvenue dans notre boutique !',
            'Welcome to our store! How can we help?',
          ),
          palette: palette,
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String text, ApoloDlPalette palette) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: palette.ink,
        ),
      ),
    );
  }

  Widget _buildInput({
    required Key key,
    required TextEditingController controller,
    required String hint,
    required ApoloDlPalette palette,
    int maxLines = 1,
    bool ltr = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: palette.groupCard,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: TextField(
        key: key,
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textDirection: ltr ? TextDirection.ltr : null,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: palette.ink,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 13.5,
            color: palette.muted,
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
        ),
      ),
    );
  }
}
