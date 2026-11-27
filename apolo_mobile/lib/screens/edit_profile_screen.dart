import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import '../widgets/apolo_badges_kit.dart';
import '../widgets/dl_settings_kit.dart';
import 'account_security_screen.dart';
import 'business_switch_screen.dart';
import 'pro_plus_screen.dart';
import 'widgets/app_image.dart';
import 'widgets/kinetic_widgets.dart';

/// Clean, cardless Dynamic Layer v5.1 Edit Profile screen supporting Light Mode
/// (`#FFFFFF`), Dark Mode (`#0A0A0A`), Arabic RTL, French, and English.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const List<String> _presetAvatars = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?auto=format&fit=crop&w=400&q=80',
  ];

  static const List<Map<String, String>> _fallbackMoroccanCities = [
    {'ar': 'الدار البيضاء', 'fr': 'Casablanca', 'en': 'Casablanca'},
    {'ar': 'الرباط', 'fr': 'Rabat', 'en': 'Rabat'},
    {'ar': 'مراكش', 'fr': 'Marrakech', 'en': 'Marrakech'},
    {'ar': 'طنجة', 'fr': 'Tanger', 'en': 'Tangier'},
    {'ar': 'فاس', 'fr': 'Fès', 'en': 'Fes'},
    {'ar': 'أكادير', 'fr': 'Agadir', 'en': 'Agadir'},
    {'ar': 'مكناس', 'fr': 'Meknès', 'en': 'Meknes'},
    {'ar': 'وجدة', 'fr': 'Oujda', 'en': 'Oujda'},
    {'ar': 'القنيطرة', 'fr': 'Kénitra', 'en': 'Kenitra'},
    {'ar': 'تطوان', 'fr': 'Tétouan', 'en': 'Tetouan'},
    {'ar': 'سلا', 'fr': 'Salé', 'en': 'Sale'},
    {'ar': 'الناظور', 'fr': 'Nador', 'en': 'Nador'},
  ];

  final AppState _state = AppState();

  late final String? _initialIdentity;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _bioCtrl;
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _bioFocus = FocusNode();

  late String _initialHandle;
  late String _selectedAvatar;
  late String _selectedCity;
  int? _selectedCityId;
  late String _phoneValue;

  bool _saving = false;
  String? _error;

  Timer? _usernameDebounce;
  bool _checkingUsername = false;
  bool? _usernameAvailable;
  String? _usernameStatusMsg;
  List<String> _usernameSuggestions = [];
  int _checkSeq = 0;

  String? get _currentIdentity =>
      _state.isLoggedIn && _state.currentUser?['id'] != null
          ? '${_state.api.dio.options.baseUrl}:${_state.currentUser!['id']}'
          : null;

  @override
  void initState() {
    super.initState();
    _initialIdentity = _currentIdentity;
    final user = _state.currentUser;
    final initialName = (user?['name'] ?? '').toString().trim();
    final rawUsername =
        (user?['username'] ?? user?['handle'] ?? '').toString().trim();
    final cleanedUsername = rawUsername.replaceAll('@', '').toLowerCase();
    _initialHandle =
        cleanedUsername.length >= 3 ? cleanedUsername : 'profil';

    _nameCtrl = TextEditingController(text: initialName);
    _usernameCtrl = TextEditingController(text: _initialHandle);
    _bioCtrl = TextEditingController(
      text: (user?['bio'] ?? '').toString(),
    );

    _selectedAvatar =
        (user?['avatar_url'] ?? user?['avatar'] ?? '').toString().trim();
    _selectedCity = (user?['city'] ?? user?['city_name'] ?? '').toString().trim();
    _selectedCityId = int.tryParse((user?['city_id'] ?? '').toString());
    _phoneValue = (user?['phone'] ?? '').toString().trim();

    _nameCtrl.addListener(_onFieldChanged);
    _usernameCtrl.addListener(_onFieldChanged);
    _bioCtrl.addListener(_onFieldChanged);
    _nameFocus.addListener(_onFieldChanged);
    _usernameFocus.addListener(_onFieldChanged);
    _bioFocus.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _nameCtrl.removeListener(_onFieldChanged);
    _usernameCtrl.removeListener(_onFieldChanged);
    _bioCtrl.removeListener(_onFieldChanged);
    _nameFocus.removeListener(_onFieldChanged);
    _usernameFocus.removeListener(_onFieldChanged);
    _bioFocus.removeListener(_onFieldChanged);
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _nameFocus.dispose();
    _usernameFocus.dispose();
    _bioFocus.dispose();
    super.dispose();
  }

  void _onUsernameChanged(String raw) {
    _usernameDebounce?.cancel();
    final clean = raw.trim().replaceAll('@', '').toLowerCase();
    if (clean == _initialHandle && clean.length >= 3) {
      setState(() {
        _checkingUsername = false;
        _usernameAvailable = null;
        _usernameStatusMsg = null;
        _usernameSuggestions = [];
      });
      return;
    }
    if (clean.length < 3) {
      setState(() {
        _checkingUsername = false;
        _usernameAvailable = false;
        _usernameStatusMsg = _state.s.tr(
          'يجب أن يكون 3 أحرف على الأقل',
          'Minimum 3 caractères requis',
          'Minimum 3 characters required',
        );
        _usernameSuggestions = [];
      });
      return;
    }
    final seq = ++_checkSeq;
    setState(() {
      _checkingUsername = true;
      _usernameAvailable = null;
      _usernameStatusMsg = null;
      _usernameSuggestions = [];
      _error = null;
    });
    _usernameDebounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final res = await _state.api.dio.get(
          '/auth/username/check',
          queryParameters: {'username': clean},
        );
        if (!mounted || seq != _checkSeq) return;
        final data = res.data is Map ? res.data as Map : const {};
        if (!data.containsKey('available')) {
          setState(() {
            _checkingUsername = false;
          });
          return;
        }
        final avail = data['available'] == true;
        final msg = data['message']?.toString();
        final rawSugg = data['suggestions'];
        final sugg = rawSugg is List
            ? rawSugg
                .map((e) => e.toString())
                .where((e) => e.isNotEmpty)
                .toList()
            : <String>[];
        setState(() {
          _checkingUsername = false;
          _usernameAvailable = avail;
          _usernameStatusMsg = avail
              ? _state.s.tr(
                  'اسم المستخدم @$clean متاح',
                  '@$clean est disponible',
                  '@$clean is available',
                )
              : (msg ??
                  _state.s.tr(
                    'اسم المستخدم محجوز بالفعل.',
                    'Déjà utilisé.',
                    'Already taken.',
                  ));
          _usernameSuggestions = sugg;
        });
      } catch (_) {
        if (!mounted || seq != _checkSeq) return;
        setState(() {
          _checkingUsername = false;
        });
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 84,
      );
      if (picked != null && mounted) {
        final bytes = await picked.readAsBytes();
        final b64 = base64Encode(bytes);
        setState(() {
          _selectedAvatar = 'data:image/jpeg;base64,$b64';
          _error = null;
        });
      }
    } catch (_) {}
  }

  void _openAvatarPickerSheet() {
    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.selectionClick();
    final s = _state.s;
    final isAr = _state.locale.languageCode == 'ar';
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: ApoloDlPalette.of(context).bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) {
        final palette = ApoloDlPalette.of(sheetCtx);
        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: palette.pill,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.tr(
                            'صورة الملف الشخصي',
                            'Photo de profil',
                            'Profile photo',
                          ),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: palette.ink,
                          ),
                        ),
                      ),
                      ApoloDlIconCircleButton(
                        icon: CupertinoIcons.xmark,
                        iconSize: 16,
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildSheetActionRow(
                    palette: palette,
                    icon: CupertinoIcons.photo_on_rectangle,
                    label: s.tr(
                      'اختيار من المعرض',
                      'Choisir depuis la galerie',
                      'Choose from library',
                    ),
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  if (!kIsWeb) ...[
                    const SizedBox(height: 8),
                    _buildSheetActionRow(
                      palette: palette,
                      icon: CupertinoIcons.camera,
                      label: s.tr(
                        'التقاط صورة جديدة',
                        'Prendre une photo',
                        'Take photo',
                      ),
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ],
                  if (_selectedAvatar.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildSheetActionRow(
                      palette: palette,
                      icon: CupertinoIcons.trash,
                      label: s.tr(
                        'حذف الصورة الحالية',
                        'Supprimer la photo actuelle',
                        'Remove current photo',
                      ),
                      isDestructive: true,
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        setState(() => _selectedAvatar = '');
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    s.tr(
                      'أو اختر أفاتار سريع',
                      'Ou choisir un avatar rapide',
                      'Or choose a preset avatar',
                    ),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: palette.muted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 58,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _presetAvatars.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final url = _presetAvatars[i];
                        final isSel = _selectedAvatar == url;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedAvatar = url);
                            Navigator.pop(sheetCtx);
                          },
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSel ? palette.ink : palette.separator,
                                width: isSel ? 2.5 : 1,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: ClipOval(
                              child: AppImage(
                                url: url,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetActionRow({
    required ApoloDlPalette palette,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final fg = isDestructive ? palette.danger : palette.ink;
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: palette.surfaceSubtle,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: palette.bg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: fg, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: fg,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<({int? id, String label})> _resolvedCities() {
    final lang = _state.locale.languageCode;
    if (_state.cities.isNotEmpty) {
      final result = <({int? id, String label})>[];
      for (final c in _state.cities) {
        if (c is! Map) continue;
        final id = int.tryParse((c['id'] ?? '').toString());
        final name = lang == 'ar'
            ? (c['name_ar'] ?? c['name_fr'] ?? c['name'] ?? '')
            : (c['name_fr'] ?? c['name'] ?? c['name_ar'] ?? '');
        final clean = name.toString().trim();
        if (clean.isNotEmpty) {
          result.add((id: id, label: clean));
        }
      }
      if (result.isNotEmpty) return result;
    }
    return _fallbackMoroccanCities
        .map(
          (m) => (
            id: null,
            label: m[lang] ?? m['en']!,
          ),
        )
        .toList();
  }

  Future<void> _openCityPickerSheet() async {
    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.selectionClick();
    final s = _state.s;
    final isAr = _state.locale.languageCode == 'ar';
    final cities = _resolvedCities();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ApoloDlPalette.of(context).bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) {
        final palette = ApoloDlPalette.of(sheetCtx);
        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetCtx).size.height * 0.68,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: palette.pill,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.tr(
                              'اختر مدينتك',
                              'Choisir votre ville',
                              'Select your city',
                            ),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: palette.ink,
                            ),
                          ),
                        ),
                        if (_selectedCity.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedCity = '';
                                _selectedCityId = null;
                              });
                              Navigator.pop(sheetCtx);
                            },
                            child: Text(
                              s.tr('مسح', 'Effacer', 'Clear'),
                              style: TextStyle(
                                color: palette.muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ApoloDlIconCircleButton(
                          icon: CupertinoIcons.xmark,
                          iconSize: 16,
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: cities.length,
                        separatorBuilder: (_, __) => const ApoloDlSeparator(),
                        itemBuilder: (_, index) {
                          final item = cities[index];
                          final isSelected = _selectedCity == item.label ||
                              (_selectedCityId != null &&
                                  _selectedCityId == item.id);
                          return InkWell(
                            key: Key('city-option-$index'),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectedCity = item.label;
                                _selectedCityId = item.id;
                              });
                              Navigator.pop(sheetCtx);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.location_solid,
                                    size: 16,
                                    color: isSelected
                                        ? palette.ink
                                        : palette.iconMuted,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: palette.ink,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      CupertinoIcons.checkmark_circle_fill,
                                      color: palette.ink,
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openPhoneEditorSheet() async {
    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.selectionClick();
    final s = _state.s;
    final isAr = _state.locale.languageCode == 'ar';
    final phoneCtrl = TextEditingController(text: _phoneValue);
    final updated = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ApoloDlPalette.of(context).bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) {
        final palette = ApoloDlPalette.of(sheetCtx);
        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: palette.pill,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.tr(
                            'رقم الهاتف والواتساب',
                            'Téléphone & WhatsApp',
                            'Phone & WhatsApp',
                          ),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: palette.ink,
                          ),
                        ),
                      ),
                      ApoloDlIconCircleButton(
                        icon: CupertinoIcons.xmark,
                        iconSize: 16,
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      color: palette.surfaceSubtle,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      key: const Key('edit-profile-phone-input'),
                      controller: phoneCtrl,
                      autofocus: true,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      cursorColor: palette.ink,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: palette.ink,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          CupertinoIcons.phone,
                          size: 18,
                          color: palette.muted,
                        ),
                        hintText: '+212 6XX XXX XXX',
                        hintStyle: TextStyle(color: palette.subtle),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ApoloDlButton(
                    key: const Key('edit-profile-phone-confirm'),
                    label: s.tr('تأكيد الرقم', 'Confirmer', 'Confirm'),
                    fullWidth: true,
                    onPressed: () =>
                        Navigator.pop(sheetCtx, phoneCtrl.text.trim()),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    Future<void>.delayed(
      const Duration(milliseconds: 250),
      phoneCtrl.dispose,
    );
    if (updated != null && mounted) {
      setState(() => _phoneValue = updated);
    }
  }

  Future<void> _saveProfile() async {
    if (_saving) return;
    if (_initialIdentity != _currentIdentity) return;

    final s = _state.s;
    final cleanName = _nameCtrl.text.trim();
    if (cleanName.isEmpty) {
      setState(() {
        _error = s.tr(
          'الاسم مطلوب.',
          'Le nom est requis.',
          'Name is required.',
        );
      });
      return;
    }

    final cleanUsername =
        _usernameCtrl.text.trim().replaceAll('@', '').toLowerCase();
    if (cleanUsername.length < 3) {
      setState(() {
        _error = s.tr(
          'اسم المستخدم يجب أن يكون 3 أحرف على الأقل.',
          'Le nom d’utilisateur doit contenir au moins 3 caractères.',
          'Username must be at least 3 characters.',
        );
      });
      return;
    }

    if (_usernameAvailable == false) {
      setState(() {
        _error = _usernameStatusMsg ??
            s.tr(
              'اسم المستخدم هذا محجوز بالفعل، اختر اسماً آخر.',
              'Ce nom d’utilisateur est déjà pris.',
              'This username is already taken.',
            );
      });
      return;
    }

    final values = <String, dynamic>{
      'name': cleanName,
      'username': cleanUsername,
      'bio': _bioCtrl.text.trim(),
      'avatar': _selectedAvatar,
      'city': _selectedCity,
      if (_selectedCityId != null) 'city_id': _selectedCityId,
      'phone': _phoneValue,
    };

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final response = await _state.api.dio.put(
        '/auth/profile',
        data: values,
      );
      if (response.data is! Map || response.data['status'] != 'success') {
        throw StateError('Profile update not confirmed');
      }
      if (!mounted || _initialIdentity != _currentIdentity) return;

      final user = response.data['user'];
      final returnedAvatar =
          (user is Map ? (user['avatar_url'] ?? user['avatar']) : null)
              ?.toString();

      await _state.updateCurrentUser({
        ...?_state.currentUser,
        ...values,
        if (user is Map) ...Map<String, dynamic>.from(user),
        'name': cleanName,
        'username': cleanUsername,
        'bio': _bioCtrl.text.trim(),
        'city': _selectedCity,
        if (_selectedCityId != null) 'city_id': _selectedCityId,
        'phone': _phoneValue,
        'avatar': (returnedAvatar != null && returnedAvatar.isNotEmpty)
            ? returnedAvatar
            : _selectedAvatar,
      });

      if (!mounted || _initialIdentity != _currentIdentity) return;
      HapticFeedback.lightImpact();
      Navigator.of(context).pop(true);
    } catch (e) {
      String errText = s.tr(
        'تعذر حفظ التغييرات. حاول مجدداً.',
        'Enregistrement impossible. Réessayez.',
        'Could not save changes. Please try again.',
      );
      if (e is DioException && e.response?.data is Map) {
        final serverMsg =
            e.response!.data['message']?.toString().trim();
        if (serverMsg != null && serverMsg.isNotEmpty) {
          errText = serverMsg;
        }
      }
      if (mounted) {
        setState(() => _error = errText);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ApoloDlPalette.of(context);
    final s = _state.s;
    final isAr = _state.locale.languageCode == 'ar';
    final isProPlus = _state.isProPlusAccount;
    final liveHandle = _usernameCtrl.text
        .trim()
        .replaceAll('@', '')
        .toLowerCase();
    final previewHandle = liveHandle.isNotEmpty ? '@$liveHandle' : '@profil';
    final initialLetter = _nameCtrl.text.trim().isNotEmpty
        ? _nameCtrl.text.trim().characters.first.toUpperCase()
        : 'A';

    return PopScope(
      canPop: !_saving,
      child: Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: palette.bg,
          body: SafeArea(
            child: Column(
              children: [
                ApoloDlTopNav(
                  title: s.tr(
                    'تعديل الملف الشخصي',
                    'Modifier le profil',
                    'Edit profile',
                  ),
                  showSeparator: true,
                  backButtonKey: const Key('edit-profile-back'),
                  onBack: _saving ? () {} : () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                        child: IgnorePointer(
                          ignoring: _saving,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. Open-Canvas Avatar Hero + Live Handle Preview
                              Center(
                                child: GestureDetector(
                                  key: const Key('profile-change-photo'),
                                  onTap: _openAvatarPickerSheet,
                                  behavior: HitTestBehavior.opaque,
                                  child: Column(
                                    children: [
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            width: 92,
                                            height: 92,
                                            decoration: BoxDecoration(
                                              color: palette.pill,
                                              shape: BoxShape.circle,
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                            alignment: Alignment.center,
                                            child: _selectedAvatar.isNotEmpty
                                                ? AppImage(
                                                    url: _selectedAvatar,
                                                    width: 92,
                                                    height: 92,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Text(
                                                    initialLetter,
                                                    style: TextStyle(
                                                      fontSize: 32,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: palette.ink,
                                                    ),
                                                  ),
                                          ),
                                          PositionedDirectional(
                                            bottom: 0,
                                            end: -2,
                                            child: Container(
                                              width: 30,
                                              height: 30,
                                              decoration: BoxDecoration(
                                                color: palette.ink,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: palette.bg,
                                                  width: 2.5,
                                                ),
                                              ),
                                              alignment: Alignment.center,
                                              child: Icon(
                                                CupertinoIcons.camera_fill,
                                                color: palette.onInk,
                                                size: 13.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            previewHandle,
                                            textDirection: TextDirection.ltr,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: palette.muted,
                                            ),
                                          ),
                                          if (isProPlus) ...[
                                            const SizedBox(width: 4),
                                            const ApoloVerifiedBadge(
                                              size: 14,
                                              isProPlus: true,
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        s.tr(
                                          'تغيير الصورة',
                                          'Modifier la photo',
                                          'Edit picture',
                                        ),
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: palette.info,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // 2. Core Identity Inputs (Name, @Username, Bio)
                              _buildFlatInputField(
                                palette: palette,
                                fieldKey: const Key('edit-profile-name-field'),
                                label: s.tr('الاسم', 'Nom', 'Name'),
                                hint: s.tr(
                                  'اسمك الكامل',
                                  'Votre nom complet',
                                  'Your full name',
                                ),
                                controller: _nameCtrl,
                                focusNode: _nameFocus,
                                suffixIcon: _nameFocus.hasFocus &&
                                        _nameCtrl.text.isNotEmpty
                                    ? IconButton(
                                        onPressed: _nameCtrl.clear,
                                        icon: Icon(
                                          CupertinoIcons.xmark_circle_fill,
                                          size: 17,
                                          color: palette.subtle,
                                        ),
                                      )
                                    : null,
                              ),

                              const SizedBox(height: 14),

                              _buildFlatInputField(
                                palette: palette,
                                fieldKey:
                                    const Key('edit-profile-username-field'),
                                label: s.tr(
                                  'اسم المستخدم',
                                  'Nom d’utilisateur',
                                  'Username',
                                ),
                                hint: 'username',
                                controller: _usernameCtrl,
                                focusNode: _usernameFocus,
                                textDirection: TextDirection.ltr,
                                prefixText: '@',
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-Z0-9._]'),
                                  ),
                                  LengthLimitingTextInputFormatter(30),
                                ],
                                onChanged: _onUsernameChanged,
                                suffixIcon: _checkingUsername
                                    ? Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: palette.muted,
                                          ),
                                        ),
                                      )
                                    : (_usernameAvailable == true
                                        ? Icon(
                                            CupertinoIcons
                                                .check_mark_circled_solid,
                                            color: palette.success,
                                            size: 19,
                                          )
                                        : (_usernameAvailable == false
                                            ? Icon(
                                                CupertinoIcons.xmark_circle_fill,
                                                color: palette.danger,
                                                size: 19,
                                              )
                                            : null)),
                              ),

                              if (_usernameStatusMsg != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  _usernameStatusMsg!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _usernameAvailable == true
                                        ? palette.success
                                        : palette.danger,
                                  ),
                                ),
                              ],

                              if (_usernameSuggestions.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: _usernameSuggestions.map((sugg) {
                                    return GestureDetector(
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        _usernameDebounce?.cancel();
                                        _usernameCtrl.text = sugg;
                                        _usernameCtrl.selection =
                                            TextSelection.fromPosition(
                                          TextPosition(offset: sugg.length),
                                        );
                                        setState(() {
                                          _checkingUsername = false;
                                          _usernameAvailable = true;
                                          _usernameStatusMsg = s.tr(
                                            'اسم المستخدم @$sugg متاح',
                                            '@$sugg est disponible',
                                            '@$sugg is available',
                                          );
                                          _usernameSuggestions = [];
                                          _error = null;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: palette.pill,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          '@$sugg',
                                          textDirection: TextDirection.ltr,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: palette.ink,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],

                              const SizedBox(height: 14),

                              _buildFlatInputField(
                                palette: palette,
                                fieldKey: const Key('edit-profile-bio-field'),
                                label: s.tr(
                                  'النبذة التعريفية',
                                  'Biographie',
                                  'Bio',
                                ),
                                trailingLabel: '${_bioCtrl.text.length}/150',
                                hint: s.tr(
                                  'عرّف بنفسك أو بما تبيعه باختصار...',
                                  'Présentez-vous en quelques mots...',
                                  'Write a short bio about yourself...',
                                ),
                                controller: _bioCtrl,
                                focusNode: _bioFocus,
                                maxLines: 3,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(150),
                                ],
                              ),

                              const SizedBox(height: 22),
                              const ApoloDlSeparator(),

                              // 3. Cardless Flat Interactive Rows (City, Phone, Account/Store, Security)
                              _buildFlatDetailRow(
                                key: const Key('edit-profile-city-row'),
                                palette: palette,
                                isAr: isAr,
                                label: s.tr('المدينة', 'Ville', 'City'),
                                value: _selectedCity.isNotEmpty
                                    ? _selectedCity
                                    : s.tr(
                                        'إضافة مدينة',
                                        'Ajouter une ville',
                                        'Add city',
                                      ),
                                isPlaceholder: _selectedCity.isEmpty,
                                onTap: _openCityPickerSheet,
                              ),
                              const ApoloDlSeparator(),

                              _buildFlatDetailRow(
                                key: const Key('edit-profile-phone-row'),
                                palette: palette,
                                isAr: isAr,
                                label: s.tr('الهاتف', 'Téléphone', 'Phone'),
                                value: _phoneValue.isNotEmpty
                                    ? _phoneValue
                                    : s.tr(
                                        'إضافة رقم الهاتف',
                                        'Ajouter un numéro',
                                        'Add phone number',
                                      ),
                                valueTextDirection: _phoneValue.isNotEmpty
                                    ? TextDirection.ltr
                                    : null,
                                isPlaceholder: _phoneValue.isEmpty,
                                onTap: _openPhoneEditorSheet,
                              ),
                              const ApoloDlSeparator(),

                              if (AppConfig.enablePremiumAndBusinessTiers) ...[
                                if (isProPlus)
                                  _buildFlatDetailRow(
                                    key: const Key('edit-profile-business-row'),
                                    palette: palette,
                                    isAr: isAr,
                                    label: s.tr(
                                      'متجر Business',
                                      'Boutique Business',
                                      'Business Store',
                                    ),
                                    value: s.tr(
                                      'إعدادات المتجر وساعات العمل',
                                      'Paramètres de la boutique',
                                      'Manage store details',
                                    ),
                                    trailingBadge: const ApoloVerifiedBadge(
                                      size: 16,
                                      isProPlus: true,
                                    ),
                                    onTap: () {
                                      Navigator.of(context)
                                          .push(
                                            MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  const BusinessSwitchScreen(
                                                isEditing: true,
                                              ),
                                            ),
                                          )
                                          .then((_) {
                                        if (mounted) setState(() {});
                                      });
                                    },
                                  )
                                else
                                  _buildFlatDetailRow(
                                    key: const Key('edit-profile-upgrade-row'),
                                    palette: palette,
                                    isAr: isAr,
                                    label: 'Apolo Premium',
                                    value: s.tr(
                                      'تفعيل التوثيق ومتجر Business',
                                      'Badge vérifié & Boutique',
                                      'Get Verified & Business Store',
                                    ),
                                    valueColor: palette.info,
                                    trailingBadge: const ApoloVerifiedBadge(
                                      size: 16,
                                      isProPlus: true,
                                    ),
                                    onTap: () {
                                      Navigator.of(context)
                                          .push(
                                            MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  const ProPlusScreen(
                                                initialPlanId: 'monthly',
                                              ),
                                            ),
                                          )
                                          .then((_) {
                                        if (mounted) setState(() {});
                                      });
                                    },
                                  ),
                                const ApoloDlSeparator(),
                              ],

                              _buildFlatDetailRow(
                                key: const Key('edit-profile-security-row'),
                                palette: palette,
                                isAr: isAr,
                                label: s.tr(
                                  'المعلومات الشخصية',
                                  'Infos personnelles',
                                  'Personal information',
                                ),
                                value: s.tr(
                                  'البريد الإلكتروني وكلمة المرور',
                                  'Email et mot de passe',
                                  'Email & password settings',
                                ),
                                isPlaceholder: true,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const AccountSecurityScreen(),
                                    ),
                                  );
                                },
                              ),
                              const ApoloDlSeparator(),

                              if (_error != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  key: const Key('edit-profile-error'),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 11,
                                  ),
                                  decoration: BoxDecoration(
                                    color: palette.dangerSoft,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        CupertinoIcons
                                            .exclamationmark_circle_fill,
                                        color: palette.danger,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: TextStyle(
                                            color: palette.danger,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 4. Sticky Bottom Action Bar (`Key('profile-save')`)
                Container(
                  decoration: BoxDecoration(
                    color: palette.bg,
                    border: Border(
                      top: BorderSide(color: palette.separator, width: 1),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          key: const Key('profile-save'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: palette.ink,
                            foregroundColor: palette.onInk,
                            disabledBackgroundColor: palette.pill,
                            disabledForegroundColor: palette.muted,
                            elevation: 0,
                            shape: const StadiumBorder(),
                          ),
                          onPressed: _saving ? null : _saveProfile,
                          child: Text(
                            _saving
                                ? s.tr(
                                    'جارٍ الحفظ...',
                                    'Enregistrement...',
                                    'Saving...',
                                  )
                                : s.tr(
                                    'حفظ التغييرات',
                                    'Enregistrer',
                                    'Save changes',
                                  ),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildFlatInputField({
    required ApoloDlPalette palette,
    required Key fieldKey,
    required String label,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    String? trailingLabel,
    String? prefixText,
    int maxLines = 1,
    TextDirection? textDirection,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
    Widget? suffixIcon,
  }) {
    final isFocused = focusNode.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isFocused ? palette.ink : palette.muted,
                ),
              ),
            ),
            if (trailingLabel != null)
              Text(
                trailingLabel,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: palette.subtle,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: palette.surfaceSubtle,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isFocused ? palette.ink : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: TextField(
            key: fieldKey,
            controller: controller,
            focusNode: focusNode,
            maxLines: maxLines,
            textDirection: textDirection,
            cursorColor: palette.ink,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: palette.ink,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w400,
                color: palette.subtle,
              ),
              prefixText: prefixText,
              prefixStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: palette.muted,
              ),
              suffixIcon: suffixIcon,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlatDetailRow({
    required Key key,
    required ApoloDlPalette palette,
    required bool isAr,
    required String label,
    required String value,
    required VoidCallback onTap,
    TextDirection? valueTextDirection,
    bool isPlaceholder = false,
    Color? valueColor,
    Widget? trailingBadge,
  }) {
    final chevron =
        isAr ? CupertinoIcons.chevron_left : CupertinoIcons.chevron_right;
    return InkWell(
      key: key,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          children: [
            SizedBox(
              width: 118,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: palette.ink,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: valueTextDirection,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: valueColor != null
                            ? FontWeight.w600
                            : (isPlaceholder
                                ? FontWeight.w400
                                : FontWeight.w500),
                        color: valueColor ??
                            (isPlaceholder ? palette.muted : palette.ink),
                      ),
                    ),
                  ),
                  if (trailingBadge != null) ...[
                    const SizedBox(width: 6),
                    trailingBadge,
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              chevron,
              size: 15,
              color: palette.iconMuted,
            ),
          ],
        ),
      ),
    );
  }
}
