import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
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

class _PostAdScreenState extends State<PostAdScreen> {
  final AppState _state = AppState();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  int? _categoryId;
  int? _cityId;
  bool _negotiable = false;
  bool _free = false;
  bool _hidePhone = false;
  bool _submitting = false;

  final List<XFile> _pickedImages = [];
  List<String> _existingImageUrls = [];
  final Map<String, dynamic> _dynamicValues = {};

  // Exact Triply-AI / Unslop + Apolo Brand Red (#E31B23) tokens
  static const Color _ink = Color(0xFF0F1B2D);
  static const Color _blue = Color(0xFFE31B23);
  static const Color _muted = Color(0xFF8A94A6);
  static const Color _border = Color(0xFFE7EAF0);
  static const Color _fill = Color(0xFFF1F3F7);

  bool get _isEditing => widget.initialAd != null;

  @override
  void initState() {
    super.initState();
    final ad = widget.initialAd;
    if (ad != null) {
      _titleCtrl.text = (ad['title'] ?? '').toString();
      _descCtrl.text = (ad['description'] ?? '').toString();
      final rawPrice = ad['price']?.toString() ?? '';
      _priceCtrl.text = rawPrice == '0' ? '' : rawPrice;
      _phoneCtrl.text = (ad['phone_call'] ?? ad['phone_whatsapp'] ?? '').toString();
      _categoryId = int.tryParse(
        (ad['category_id'] ?? (ad['category'] is Map ? ad['category']['id'] : '')).toString(),
      );
      _cityId = int.tryParse(
        (ad['city_id'] ?? (ad['city'] is Map ? ad['city']['id'] : '')).toString(),
      );
      final meta = ad['metadata'] is Map
          ? Map<String, dynamic>.from(ad['metadata'])
          : <String, dynamic>{};
      _negotiable = meta['negotiable'] == true || ad['negotiable'] == true;
      _free = meta['free'] == true || ad['free'] == true || ad['offer_type'] == 'free';
      _hidePhone = meta['hide_phone'] == true;
      meta.forEach((k, v) {
        if (!['negotiable', 'free', 'additional_images', 'hide_phone', 'internal_chat']
                .contains(k) &&
            v != null) {
          _dynamicValues[k] = v;
        }
      });
      if (ad['images'] is List) {
        _existingImageUrls = (ad['images'] as List).map((e) => e.toString()).toList();
      }
    } else if (_state.currentUser != null && _state.currentUser!['phone'] != null) {
      _phoneCtrl.text = _state.currentUser!['phone'].toString();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
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
    final cat = _state.categories.firstWhere(
      (c) => int.tryParse(c['id'].toString()) == catId,
      orElse: () => null,
    );
    if (cat != null && cat['fields'] is List) {
      return (cat['fields'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  Future<void> _submitAd() async {
    final s = _state.s;
    if (!_state.isLoggedIn) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
      return;
    }
    if (_categoryId == null ||
        _cityId == null ||
        _titleCtrl.text.trim().length < 6 ||
        (!_isEditing && _pickedImages.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _ink,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Text(
            s.tr(
              'يرجى ملء الحقول الأساسية وإضافة صورة واحدة على الأقل',
              'Veuillez remplir les champs obligatoires et ajouter au moins une photo',
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final desc = _descCtrl.text.trim().length >= 20
          ? _descCtrl.text.trim()
          : '${_titleCtrl.text.trim()} - ${_descCtrl.text.trim()} - Apolo.ma';

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
        allMultipartImages.add(MultipartFile.fromBytes(bytes, filename: fileName));
        if (i < 4) {
          map['image_${i + 1}'] = MultipartFile.fromBytes(bytes, filename: fileName);
        }
      }
      if (allMultipartImages.isNotEmpty) {
        map['images[]'] = allMultipartImages;
      }

      final formData = FormData.fromMap(map);
      final String endpoint = _isEditing
          ? '/ads/${widget.initialAd!['id']}'
          : '/ads';
      final res = await _state.api.dio.post(endpoint, data: formData);

      if (mounted) {
        setState(() => _submitting = false);
        if (res.data is Map && res.data['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppConfig.success,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              content: Text(
                res.data['message']?.toString() ??
                    (_isEditing
                        ? s.tr('تم تحديث الإعلان بنجاح', 'Annonce mise à jour')
                        : s.tr('تم نشر إعلانك بنجاح', 'Annonce publiée')),
              ),
            ),
          );
          if (_isEditing) {
            Navigator.pop(context, true);
            return;
          }
          _titleCtrl.clear();
          _descCtrl.clear();
          _priceCtrl.clear();
          setState(() {
            _pickedImages.clear();
            _dynamicValues.clear();
          });
          widget.onSuccess?.call();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppConfig.danger,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

  InputDecoration _inputDecoration(String hint, {IconData? icon}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _border, width: 1.2),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _muted, fontSize: 15, fontWeight: FontWeight.w400),
      prefixIcon: icon != null ? Icon(icon, color: _muted, size: 20) : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: _blue, width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final topInset = MediaQuery.of(context).padding.top;
    final canPop = Navigator.of(context).canPop();

    if (!_state.isLoggedIn) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEECEE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 34,
                    color: _blue,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  s.tr('نشر إعلان جديد', 'Publier une annonce'),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.tr(
                    'سجل دخولك لإضافة إعلانك مجاناً والوصول لآلاف المشترين فالمغرب',
                    'Connectez-vous pour publier votre annonce gratuitement sur Apolo.ma',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, height: 1.45, color: _muted),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                    ).then((_) => setState(() {})),
                    child: Text(
                      s.login,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final dynamicFields = _fieldsForCategory(_categoryId);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header (Exact generate-trip.tsx style)
          Padding(
            padding: EdgeInsets.fromLTRB(20, topInset + 10, 20, 8),
            child: SizedBox(
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (canPop)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: _fill,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chevron_left_rounded,
                            color: _ink,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  Text(
                    _isEditing
                        ? s.tr('تعديل الإعلان', 'Modifier l\'annonce')
                        : s.tr('نشر إعلان', 'Publier une annonce'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, 12, 20, canPop ? 32 : 120),
              children: [
                // Intro assistant card (generate-trip.tsx speech bubble)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: _blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.tr(
                                'أضف تفاصيل إعلانك بوضوح',
                                'Présentez votre annonce clairement',
                              ),
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s.tr(
                                'الإعلانات اللي فيها صور واضحة وثمن محدد كتتباع أسرع.',
                                'Les annonces avec des photos nettes et un prix précis attirent plus d\'acheteurs.',
                              ),
                              style: const TextStyle(
                                fontSize: 14.5,
                                height: 1.4,
                                color: _muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // 1. Photos Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.tr('الصور', 'Photos'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    Text(
                      '${_pickedImages.length} / 8',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 108,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      if (_pickedImages.length < 8)
                        GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            width: 108,
                            height: 108,
                            margin: const EdgeInsetsDirectional.only(end: 12),
                            decoration: BoxDecoration(
                              color: _fill,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _border),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.add_a_photo_outlined,
                                  color: _blue,
                                  size: 26,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  s.tr('إضافة صور', 'Ajouter'),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: _ink,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ..._pickedImages.asMap().entries.map((entry) {
                        return Stack(
                          children: [
                            Container(
                              width: 108,
                              height: 108,
                              margin: const EdgeInsetsDirectional.only(end: 12),
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _border),
                              ),
                              child: kIsWeb
                                  ? Image.network(entry.value.path, fit: BoxFit.cover)
                                  : FutureBuilder(
                                      future: entry.value.readAsBytes(),
                                      builder: (_, snap) => snap.hasData
                                          ? Image.memory(snap.data!, fit: BoxFit.cover)
                                          : const Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: _blue,
                                              ),
                                            ),
                                    ),
                            ),
                            Positioned(
                              top: 6,
                              right: 18,
                              child: GestureDetector(
                                onTap: () => setState(() => _pickedImages.removeAt(entry.key)),
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                      if (_pickedImages.isEmpty && _existingImageUrls.isNotEmpty)
                        ..._existingImageUrls.map(
                          (url) => Container(
                            width: 108,
                            height: 108,
                            margin: const EdgeInsetsDirectional.only(end: 12),
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _border),
                            ),
                            child: AppImage(url: url, fit: BoxFit.cover),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // 2. Category Pill Chips
                Text(
                  s.categories,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _state.categories.map((c) {
                    final int? id = int.tryParse(c['id'].toString());
                    final bool active = _categoryId == id;
                    final String label = (s.isAr
                            ? (c['name_ar'] ?? c['name'])
                            : (c['name_fr'] ?? c['name']))
                        .toString();
                    return GestureDetector(
                      onTap: () => setState(() {
                        _categoryId = id;
                        _dynamicValues.clear();
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: active ? _blue : Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: active ? _blue : _border),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                            color: active ? Colors.white : _ink,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 28),

                // 3. City Selector
                Text(
                  s.tr('المدينة', 'Ville'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _cityId,
                  decoration: _inputDecoration(
                    s.tr('اختر المدينة', 'Sélectionnez une ville'),
                    icon: Icons.location_on_outlined,
                  ),
                  items: _state.cities
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
                  onChanged: (v) => setState(() => _cityId = v),
                ),

                // 4. Dynamic Category Specifications
                if (dynamicFields.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Text(
                    s.tr('مواصفات القسم', 'Caractéristiques'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
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

                const SizedBox(height: 28),

                // 5. Title & Description
                Text(
                  s.tr('تفاصيل الإعلان', 'Détails de l\'annonce'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleCtrl,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _ink,
                  ),
                  decoration: _inputDecoration(
                    s.tr('عنوان الإعلان', 'Titre de l\'annonce'),
                    icon: Icons.title_rounded,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descCtrl,
                  maxLines: 4,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _ink,
                  ),
                  decoration: _inputDecoration(
                    s.tr('وصف مفصل للمنتج أو الخدمة', 'Description détaillée'),
                  ),
                ),

                const SizedBox(height: 28),

                // 6. Price & Options
                Text(
                  s.tr('الثمن والتواصل', 'Prix et contact'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 12),
                if (!_free) ...[
                  TextField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _ink,
                    ),
                    decoration: _inputDecoration(
                      s.tr('الثمن بالدرهم (MAD)', 'Prix en MAD'),
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _ink,
                  ),
                  decoration: _inputDecoration(
                    s.tr('رقم الهاتف للتواصل', 'Numéro de téléphone'),
                    icon: Icons.phone_outlined,
                  ),
                ),
                const SizedBox(height: 16),

                // Option Chips (Exact generate-trip.tsx pill toggle style)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _OptionPill(
                      label: s.tr('قابل للتفاوض', 'Prix négociable'),
                      active: _negotiable,
                      onTap: () => setState(() => _negotiable = !_negotiable),
                    ),
                    _OptionPill(
                      label: s.tr('مجاني', 'Gratuit'),
                      active: _free,
                      onTap: () => setState(() => _free = !_free),
                    ),
                    _OptionPill(
                      label: s.tr('إخفاء الرقم (شات فقط)', 'Masquer le numéro'),
                      active: _hidePhone,
                      onTap: () => setState(() => _hidePhone = !_hidePhone),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      disabledBackgroundColor: _blue.withValues(alpha: 0.5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: _submitting ? null : _submitAd,
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
                              const Icon(Icons.auto_awesome_rounded, size: 19),
                              const SizedBox(width: 8),
                              Text(
                                _isEditing
                                    ? s.tr('حفظ التعديلات', 'Enregistrer les modifications')
                                    : s.tr('نشر الإعلان الآن', 'Publier mon annonce'),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _OptionPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2F6BE4) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? const Color(0xFF2F6BE4) : const Color(0xFFE7EAF0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? Colors.white : const Color(0xFF8A94A6),
          ),
        ),
      ),
    );
  }
}
