import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import 'auth_screen.dart';

class PostAdScreen extends StatefulWidget {
  final VoidCallback? onSuccess;
  const PostAdScreen({super.key, this.onSuccess});

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
  final Map<String, dynamic> _dynamicValues = {};

  @override
  void initState() {
    super.initState();
    if (_state.currentUser != null && _state.currentUser!['phone'] != null) {
      _phoneCtrl.text = _state.currentUser!['phone'].toString();
    }
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
    if (_categoryId == null || _cityId == null || _titleCtrl.text.trim().length < 6 || _pickedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.tr('يرجى ملء الحقول الأساسية وإضافة صورة واحدة على الأقل', 'Veuillez remplir les champs obligatoires et ajouter au moins une photo'))),
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

      for (int i = 0; i < _pickedImages.length && i < 4; i++) {
        final bytes = await _pickedImages[i].readAsBytes();
        map['image_${i + 1}'] = MultipartFile.fromBytes(
          bytes,
          filename: _pickedImages[i].name.isNotEmpty ? _pickedImages[i].name : 'photo_${i + 1}.jpg',
        );
      }

      final formData = FormData.fromMap(map);
      final res = await _state.api.dio.post('/ads', data: formData);
      if (mounted) {
        setState(() => _submitting = false);
        if (res.data is Map && res.data['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppConfig.success,
              content: Text(res.data['message']?.toString() ?? s.tr('تم إرسال إعلانك بنجاح!', 'Annonce soumise avec succès !')),
            ),
          );
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
          SnackBar(content: Text(s.tr('حدث خطأ أثناء نشر الإعلان، تأكد من طول الوصف وعدم وجود أرقام بالوصف', 'Erreur lors de la publication'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    if (!_state.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: Text(s.postAd)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_photo_alternate_outlined, size: 70, color: AppConfig.primary),
                const SizedBox(height: 16),
                Text(
                  s.tr('سجّل دخولك لإضافة إعلان مجاناً على Apolo.ma', 'Connectez-vous pour publier une annonce gratuitement'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen())).then((_) => setState(() {})),
                  child: Text(s.login),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final dynamicFields = _fieldsForCategory(_categoryId);

    return Scaffold(
      appBar: AppBar(title: Text(s.postAd)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Photos Picker
          Text(s.tr('صور الإعلان (حتى 8 صور)', 'Photos de l\'annonce'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          SizedBox(
            height: 105,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: 105,
                    height: 105,
                    margin: const EdgeInsets.only(left: 10, right: 4),
                    decoration: BoxDecoration(
                      color: AppConfig.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppConfig.primary, style: BorderStyle.solid),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_a_photo_outlined, color: AppConfig.primary, size: 28),
                        const SizedBox(height: 6),
                        Text(s.tr('إضافة صور', 'Ajouter'), style: const TextStyle(fontSize: 12, color: AppConfig.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                ..._pickedImages.asMap().entries.map((entry) {
                  return Stack(
                    children: [
                      Container(
                        width: 105,
                        height: 105,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
                        child: kIsWeb
                            ? Image.network(entry.value.path, fit: BoxFit.cover)
                            : FutureBuilder(
                                future: entry.value.readAsBytes(),
                                builder: (_, snap) => snap.hasData
                                    ? Image.memory(snap.data!, fit: BoxFit.cover)
                                    : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              ),
                      ),
                      Positioned(
                        top: 4,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => setState(() => _pickedImages.removeAt(entry.key)),
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.black87,
                            child: Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 18),

          DropdownButtonFormField<int>(
            value: _categoryId,
            decoration: InputDecoration(labelText: s.categories),
            items: _state.categories
                .map((c) => DropdownMenuItem<int>(
                      value: int.tryParse(c['id'].toString()),
                      child: Text((s.isAr ? (c['name_ar'] ?? c['name']) : (c['name_fr'] ?? c['name'])).toString()),
                    ))
                .toList(),
            onChanged: (v) => setState(() {
              _categoryId = v;
              _dynamicValues.clear();
            }),
          ),

          const SizedBox(height: 14),

          DropdownButtonFormField<int>(
            value: _cityId,
            decoration: InputDecoration(labelText: s.tr('المدينة', 'Ville')),
            items: _state.cities
                .map((c) => DropdownMenuItem<int>(
                      value: int.tryParse(c['id'].toString()),
                      child: Text((s.isAr ? (c['name_ar'] ?? c['name']) : (c['name_fr'] ?? c['name'])).toString()),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _cityId = v),
          ),

          // Dynamic Category Fields
          if (dynamicFields.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(s.tr('مواصفات القسم', 'Détails de la catégorie'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            ...dynamicFields.map((field) {
              final String key = field['key'].toString();
              final String label = (field['label'] ?? field['label_ar'] ?? key).toString();
              final String type = (field['type'] ?? 'text').toString();
              final List options = field['options'] is List ? field['options'] : [];

              if (type == 'select' && options.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<String>(
                    value: _dynamicValues[key]?.toString(),
                    decoration: InputDecoration(labelText: label),
                    items: options.map((o) {
                      final val = (o is Map ? o['value'] : o).toString();
                      final lbl = (o is Map ? o['label'] : o).toString();
                      return DropdownMenuItem<String>(value: val, child: Text(lbl));
                    }).toList(),
                    onChanged: (v) => setState(() => _dynamicValues[key] = v),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  keyboardType: type == 'number' ? TextInputType.number : TextInputType.text,
                  decoration: InputDecoration(labelText: label),
                  onChanged: (v) => _dynamicValues[key] = v,
                ),
              );
            }),
          ],

          const SizedBox(height: 6),
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(labelText: s.tr('عنوان الإعلان', 'Titre de l\'annonce')),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _descCtrl,
            maxLines: 4,
            decoration: InputDecoration(labelText: s.tr('وصف مفصل للمنتج أو الخدمة', 'Description détaillée')),
          ),
          const SizedBox(height: 14),
          if (!_free)
            TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: s.tr('الثمن بالدرهم (DH)', 'Prix en DH')),
            ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(s.tr('الثمن قابل للتفاوض', 'Prix négociable')),
            value: _negotiable,
            onChanged: (v) => setState(() => _negotiable = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(s.tr('مجاني', 'Gratuit')),
            value: _free,
            onChanged: (v) => setState(() => _free = v),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: s.tr('رقم الهاتف للتواصل', 'Numéro de téléphone')),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(s.tr('إخفاء رقم الهاتف (التواصل عبر الدردشة فقط)', 'Masquer le numéro (Chat uniquement)')),
            value: _hidePhone,
            onChanged: (v) => setState(() => _hidePhone = v),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _submitAd,
              icon: _submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline),
              label: Text(
                s.tr('نشر الإعلان الآن', 'Publier l\'annonce'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
