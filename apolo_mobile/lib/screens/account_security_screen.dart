import 'package:flutter/material.dart';
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
  String? _error;
  String? _successMessage;

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

  @override
  Widget build(BuildContext context) {
    final s = AppState().s;
    final loggedIn = _state.isLoggedIn;
    return Directionality(
        textDirection: s.isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar:
              AppBar(title: Text(s.tr('أمان الحساب', 'Sécurité du compte'))),
          body: Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: ListView(padding: const EdgeInsets.all(24), children: [
                    const Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Icon(Icons.lock_outline, size: 36)),
                    const SizedBox(height: 24),
                    Text(
                        s.tr('بيانات الدخول تبقى تحت سيطرتك',
                            'Gardez la main sur vos accès'),
                        style: const TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    Text(
                        s.tr(
                            'يمكنك تحديث كلمة المرور أو البريد الإلكتروني أو رقم الهاتف مباشرة من التطبيق، أو عبر موقع Apolo الرسمي.',
                            'Vous pouvez mettre à jour votre mot de passe, votre adresse e-mail ou votre numéro directement dans l’application ou sur le site officiel Apolo.'),
                        style: const TextStyle(height: 1.6)),
                    const SizedBox(height: 24),
                    if (loggedIn) ...[
                      Text(
                          s.tr('تحديث البريد الإلكتروني والهاتف',
                              'Mettre à jour l’e-mail et le téléphone'),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('security-email'),
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText:
                              s.tr('البريد الإلكتروني', 'Adresse e-mail'),
                          prefixIcon: const Icon(Icons.alternate_email),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('security-phone'),
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: s.tr('رقم الهاتف', 'Numéro de téléphone'),
                          prefixIcon: const Icon(Icons.phone_outlined),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        key: const Key('security-save-profile'),
                        onPressed: _savingProfile ? null : _saveContactInfo,
                        child: Text(s.tr('حفظ بيانات الاتصال',
                            'Enregistrer les coordonnées')),
                      ),
                      const SizedBox(height: 28),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                          s.tr('تغيير كلمة المرور',
                              'Modifier le mot de passe'),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('security-current-password'),
                        controller: _currentPasswordCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: s.tr(
                              'كلمة المرور الحالية', 'Mot de passe actuel'),
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('security-new-password'),
                        controller: _newPasswordCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: s.tr(
                              'كلمة المرور الجديدة', 'Nouveau mot de passe'),
                          prefixIcon: const Icon(Icons.password),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('security-confirm-password'),
                        controller: _confirmPasswordCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: s.tr('تأكيد كلمة المرور الجديدة',
                              'Confirmer le nouveau mot de passe'),
                          prefixIcon: const Icon(Icons.password),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        key: const Key('security-save-password'),
                        onPressed: _savingPassword ? null : _changePassword,
                        child: Text(s.tr('تحديث كلمة المرور',
                            'Mettre à jour le mot de passe')),
                      ),
                      const SizedBox(height: 28),
                      const Divider(),
                      const SizedBox(height: 16),
                    ] else ...[
                      for (final item in [
                        (Icons.password, s.tr('كلمة المرور', 'Mot de passe')),
                        (
                          Icons.alternate_email,
                          s.tr('البريد الإلكتروني', 'Adresse e-mail')
                        ),
                        (
                          Icons.phone_outlined,
                          s.tr('رقم الهاتف', 'Numéro de téléphone')
                        ),
                      ]) ...[
                        ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(item.$1),
                            title: Text(item.$2),
                            subtitle: Text(s.tr(
                                'سجّل الدخول للتعديل أو استخدم الموقع',
                                'Connectez-vous pour modifier ou utilisez le site'))),
                        const Divider(),
                      ],
                    ],
                    if (_successMessage != null)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Semantics(
                              liveRegion: true,
                              child: Text(_successMessage!,
                                  style: const TextStyle(
                                      color: Color(0xFF15803D),
                                      fontWeight: FontWeight.w600)))),
                    if (_error != null)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Semantics(
                              liveRegion: true,
                              child: Text(_error!,
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error)))),
                    const SizedBox(height: 8),
                    Text(s.tr(
                        'لن يتم تغيير أي بيانات بمجرد فتح الموقع. جلسة التطبيق لا تنتقل إلى المتصفح.',
                        'Ouvrir le site ne modifie aucune donnée. Votre session dans l’application n’est pas transférée au navigateur.')),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                        onPressed: _opening ? null : _open,
                        icon: _opening
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.open_in_new),
                        label: Text(s.tr('فتح apolo.ma', 'Ouvrir apolo.ma'))),
                  ]))),
        ));
  }
}
