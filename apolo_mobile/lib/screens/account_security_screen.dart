import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../account/account_helpers.dart';
import '../core/state/app_state.dart';

class AccountSecurityScreen extends StatefulWidget {
  const AccountSecurityScreen({super.key});
  @override
  State<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends State<AccountSecurityScreen> {
  final _state = AppState();
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _opening = false;
  bool _savingProfile = false;
  bool _savingPassword = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _error;
  String? _successMessage;

  static const Color _bg = Color(0xFFF2F3F7);
  static const Color _cardBg = Colors.white;
  static const Color _ink = Color(0xFF0A0A0A);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _trailingMuted = Color(0xFF8E8E93);
  static const Color _divider = Color(0xFFF1F2F6);
  static const Color _inputFill = Color(0xFFF8F9FB);
  static const Color _inputBorder = Color(0xFFE5E7EB);
  static const Color _blue = Color(0xFF0866FF);
  static const Color _red = Color(0xFFE31B23);
  static const Color _green = Color(0xFF15803D);

  @override
  void initState() {
    super.initState();
    final user = _state.currentUser ?? const <String, dynamic>{};
    _emailCtrl = TextEditingController(text: user['email']?.toString() ?? '');
    _phoneCtrl = TextEditingController(text: user['phone']?.toString() ?? '');
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveContactInfo() async {
    if (_savingProfile) return;
    HapticFeedback.selectionClick();
    final s = _state.s;
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final name = (_state.currentUser?['name']?.toString() ?? '').trim();
    if (!AccountValidation.email(email)) {
      setState(() {
        _error = s.tr('أدخل بريداً إلكترونياً صالحاً.',
            'Entrez une adresse e-mail valide.');
        _successMessage = null;
      });
      return;
    }
    final normalizedPhone =
        phone.isEmpty ? null : AccountValidation.phone(phone);
    if (phone.isNotEmpty && normalizedPhone == null) {
      setState(() {
        _error = s.tr(
            'أدخل رقم هاتف مغربي صالح.', 'Entrez un numéro marocain valide.');
        _successMessage = null;
      });
      return;
    }
    setState(() {
      _savingProfile = true;
      _error = null;
      _successMessage = null;
    });
    try {
      final res = await _state.api.dio.put('/auth/profile', data: {
        'name': name.length >= 2 ? name : 'Apolo User',
        'email': email,
        if (normalizedPhone != null) 'phone': normalizedPhone,
      });
      final data = res.data;
      if (data is Map && data['status'] == 'error') {
        throw AccountFailure('server', data['message']?.toString());
      }
      if (data is Map && data['user'] is Map) {
        _state.currentUser = Map<String, dynamic>.from(data['user'] as Map);
      } else if (_state.currentUser != null) {
        _state.currentUser = {
          ..._state.currentUser!,
          'email': email,
          if (normalizedPhone != null) 'phone': normalizedPhone,
        };
      }
      if (mounted) {
        setState(() => _successMessage = s.tr(
            'تم تحديث بيانات الاتصال بنجاح.',
            'Coordonnées mises à jour avec succès.'));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = accountError(e, s.isAr));
      }
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    if (_savingPassword) return;
    HapticFeedback.selectionClick();
    final s = _state.s;
    final currentPassword = _currentPasswordCtrl.text;
    final newPassword = _newPasswordCtrl.text;
    final confirmPassword = _confirmPasswordCtrl.text;
    if (!AccountValidation.password(currentPassword) ||
        !AccountValidation.password(newPassword)) {
      setState(() {
        _error = s.tr('كلمة المرور يجب أن تتكون من 8 أحرف على الأقل.',
            'Le mot de passe doit contenir au moins 8 caractères.');
        _successMessage = null;
      });
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() {
        _error = s.tr('كلمتا المرور غير متطابقتين.',
            'Les mots de passe ne correspondent pas.');
        _successMessage = null;
      });
      return;
    }
    setState(() {
      _savingPassword = true;
      _error = null;
      _successMessage = null;
    });
    try {
      final auth = AccountAuth(client: _state.api.dio);
      await auth.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmation: confirmPassword,
      );
      _currentPasswordCtrl.clear();
      _newPasswordCtrl.clear();
      _confirmPasswordCtrl.clear();
      if (mounted) {
        setState(() => _successMessage = s.tr(
            'تم تحديث كلمة المرور بنجاح.',
            'Mot de passe mis à jour avec succès.'));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = accountError(e, s.isAr));
      }
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  Future<void> _open() async {
    if (_opening) return;
    HapticFeedback.selectionClick();
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      if (!await launchUrl(accountWebsite,
          mode: LaunchMode.externalApplication)) {
        throw StateError('Website unavailable');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppState().s.tr(
            'تعذر فتح الموقع. افتح apolo.ma في المتصفح.',
            'Impossible d’ouvrir le site. Ouvrez apolo.ma dans votre navigateur.'));
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _muted, fontSize: 14),
      prefixIcon: Icon(icon, size: 19, color: _ink),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _inputBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _blue, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState().s;
    final isAr = s.isAr;
    final loggedIn = _state.isLoggedIn;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 48,
          centerTitle: true,
          leading: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(
              isAr ? CupertinoIcons.chevron_right : CupertinoIcons.chevron_left,
              color: _ink,
              size: 22,
            ),
          ),
          title: Text(
            s.tr('أمان الحساب', 'Sécurité du compte', 'Account security'),
            style: const TextStyle(
              color: _ink,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  // Intro Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: _blue.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_outline,
                            size: 21,
                            color: _blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.tr(
                                  'بيانات الدخول تبقى تحت سيطرتك',
                                  'Gardez la main sur vos accès',
                                  'Stay in control of your login',
                                ),
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w600,
                                  color: _ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                s.tr(
                                  'يمكنك تحديث كلمة المرور أو البريد الإلكتروني أو رقم الهاتف مباشرة من التطبيق، أو عبر موقع Apolo الرسمي.',
                                  'Vous pouvez mettre à jour votre mot de passe, votre adresse e-mail ou votre numéro directement dans l’application ou sur le site officiel Apolo.',
                                  'Update your password, email, or phone directly in the app or on the official Apolo website.',
                                ),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _muted,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_successMessage != null)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          _successMessage!,
                          style: const TextStyle(
                            color: _green,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: _red,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                  if (loggedIn) ...[
                    _buildSectionHeader(
                      s.tr(
                        'بيانات الاتصال',
                        'Coordonnées',
                        'Contact details',
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            key: const Key('security-email'),
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textDirection: TextDirection.ltr,
                            decoration: _fieldDecoration(
                              label:
                                  s.tr('البريد الإلكتروني', 'Adresse e-mail'),
                              icon: CupertinoIcons.at,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            key: const Key('security-phone'),
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            textDirection: TextDirection.ltr,
                            decoration: _fieldDecoration(
                              label: s.tr('رقم الهاتف', 'Numéro de téléphone'),
                              icon: CupertinoIcons.phone,
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 46,
                            child: FilledButton(
                              key: const Key('security-save-profile'),
                              style: FilledButton.styleFrom(
                                backgroundColor: _ink,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed:
                                  _savingProfile ? null : _saveContactInfo,
                              child: _savingProfile
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      s.tr('حفظ بيانات الاتصال',
                                          'Enregistrer les coordonnées'),
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildSectionHeader(
                      s.tr(
                        'تغيير كلمة المرور',
                        'Modifier le mot de passe',
                        'Change password',
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            key: const Key('security-current-password'),
                            controller: _currentPasswordCtrl,
                            obscureText: _obscureCurrent,
                            textDirection: TextDirection.ltr,
                            decoration: _fieldDecoration(
                              label: s.tr(
                                  'كلمة المرور الحالية', 'Mot de passe actuel'),
                              icon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                    () => _obscureCurrent = !_obscureCurrent),
                                icon: Icon(
                                  _obscureCurrent
                                      ? CupertinoIcons.eye
                                      : CupertinoIcons.eye_slash,
                                  size: 18,
                                  color: _muted,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            key: const Key('security-new-password'),
                            controller: _newPasswordCtrl,
                            obscureText: _obscureNew,
                            textDirection: TextDirection.ltr,
                            decoration: _fieldDecoration(
                              label: s.tr('كلمة المرور الجديدة',
                                  'Nouveau mot de passe'),
                              icon: Icons.password,
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _obscureNew = !_obscureNew),
                                icon: Icon(
                                  _obscureNew
                                      ? CupertinoIcons.eye
                                      : CupertinoIcons.eye_slash,
                                  size: 18,
                                  color: _muted,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            key: const Key('security-confirm-password'),
                            controller: _confirmPasswordCtrl,
                            obscureText: _obscureConfirm,
                            textDirection: TextDirection.ltr,
                            decoration: _fieldDecoration(
                              label: s.tr('تأكيد كلمة المرور الجديدة',
                                  'Confirmer le nouveau mot de passe'),
                              icon: Icons.password,
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
                                icon: Icon(
                                  _obscureConfirm
                                      ? CupertinoIcons.eye
                                      : CupertinoIcons.eye_slash,
                                  size: 18,
                                  color: _muted,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 46,
                            child: FilledButton(
                              key: const Key('security-save-password'),
                              style: FilledButton.styleFrom(
                                backgroundColor: _ink,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed:
                                  _savingPassword ? null : _changePassword,
                              child: _savingPassword
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      s.tr('تحديث كلمة المرور',
                                          'Mettre à jour le mot de passe'),
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    _buildSectionHeader(
                      s.tr('إعدادات الأمان', 'Options de sécurité',
                          'Security options'),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          _buildInfoRow(
                            icon: Icons.password,
                            title: s.tr('كلمة المرور', 'Mot de passe'),
                            subtitle: s.tr(
                                'سجّل الدخول للتعديل أو استخدم الموقع',
                                'Connectez-vous pour modifier ou utilisez le site'),
                          ),
                          const Padding(
                            padding:
                                EdgeInsetsDirectional.only(start: 48, end: 14),
                            child: Divider(
                                height: 1, thickness: 1, color: _divider),
                          ),
                          _buildInfoRow(
                            icon: CupertinoIcons.at,
                            title: s.tr('البريد الإلكتروني', 'Adresse e-mail'),
                            subtitle: s.tr(
                                'سجّل الدخول للتعديل أو استخدم الموقع',
                                'Connectez-vous pour modifier ou utilisez le site'),
                          ),
                          const Padding(
                            padding:
                                EdgeInsetsDirectional.only(start: 48, end: 14),
                            child: Divider(
                                height: 1, thickness: 1, color: _divider),
                          ),
                          _buildInfoRow(
                            icon: CupertinoIcons.phone,
                            title: s.tr('رقم الهاتف', 'Numéro de téléphone'),
                            subtitle: s.tr(
                                'سجّل الدخول للتعديل أو استخدم الموقع',
                                'Connectez-vous pour modifier ou utilisez le site'),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // External Website Card
                  _buildSectionHeader(
                    s.tr('الموقع الرسمي', 'Site officiel', 'Official website'),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _opening ? null : _open,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 13),
                          child: Row(
                            children: [
                              const Icon(CupertinoIcons.globe,
                                  size: 20, color: _ink),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  s.tr('فتح apolo.ma', 'Ouvrir apolo.ma',
                                      'Open apolo.ma'),
                                  style: const TextStyle(
                                    color: _ink,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              if (_opening)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              else
                                Icon(
                                  isAr
                                      ? CupertinoIcons.chevron_left
                                      : CupertinoIcons.chevron_right,
                                  size: 15,
                                  color: _trailingMuted,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 8, 6, 0),
                    child: Text(
                      s.tr(
                        'لن يتم تغيير أي بيانات بمجرد فتح الموقع. جلسة التطبيق لا تنتقل إلى المتصفح.',
                        'Ouvrir le site ne modifie aucune donnée. Votre session dans l’application n’est pas transférée au navigateur.',
                        'Opening the website does not modify any data. Your app session is not transferred to the browser.',
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: _muted,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, top: 14, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          color: _muted,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _ink),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12.5,
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
