import 'package:flutter/material.dart';
import '../core/state/app_state.dart';
import 'account_security_screen.dart';
import 'auth_screen.dart';
import 'privacy_compliance_screen.dart';
import 'support_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onOpenEditProfile;
  const SettingsScreen({super.key, this.onOpenEditProfile});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _state = AppState();
  bool _busy = false;
  String? _error;

  Future<void> _language() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _state.toggleLanguage();
    } catch (_) {
      if (mounted) {
        setState(() => _error = _state.s.tr('تعذر حفظ اللغة. أعد المحاولة.',
            'Impossible d’enregistrer la langue. Réessayez.'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    final s = _state.s;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(s.tr('تسجيل الخروج؟', 'Se déconnecter ?')),
              content: Text(s.tr(
                  'ستنتهي جلستك على هذا الجهاز. قد تحتاج لتسجيل الدخول مجدداً.',
                  'Votre session sur cet appareil sera fermée. Vous devrez vous reconnecter.')),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(s.tr('إلغاء', 'Annuler'))),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(s.logout))
              ],
            ));
    if (confirmed != true || !mounted || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _state.logout();
    } catch (_) {
      if (mounted) {
        setState(() => _error = s.tr('تعذر إغلاق الجلسة المحلية. أعد المحاولة.',
            'Impossible de fermer la session locale. Réessayez.'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _open(Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        final s = _state.s;
        final user = _state.currentUser;
        final name = user?['name']?.toString().trim();
        return Directionality(
            textDirection: s.isAr ? TextDirection.rtl : TextDirection.ltr,
            child: Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                  backgroundColor: Colors.white,
                  title: Text(s.tr('الإعدادات', 'Paramètres'))),
              body: Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: ListView(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                          children: [
                            Text(
                                _state.isLoggedIn
                                    ? (name?.isNotEmpty == true
                                        ? name!
                                        : s.tr('حسابي', 'Mon compte'))
                                    : s.tr('أهلاً بك في Apolo',
                                        'Bienvenue sur Apolo'),
                                style: const TextStyle(
                                    fontSize: 28, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            Text(
                                s.tr('خيارات واضحة لحسابك وتجربتك.',
                                    'Vos choix pour votre compte et votre expérience.'),
                                style: const TextStyle(
                                    color: Color(0xFF536170), height: 1.5)),
                            const SizedBox(height: 28),
                            if (!_state.isLoggedIn)
                              _row(Icons.login, s.login,
                                  () => _open(const AuthScreen()))
                            else if (widget.onOpenEditProfile != null)
                              _row(
                                  Icons.person_outline,
                                  s.tr('تعديل الملف الشخصي',
                                      'Modifier le profil'), () {
                                final callback = widget.onOpenEditProfile;
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                }
                                callback?.call();
                              }),
                            _row(
                                Icons.lock_outline,
                                s.tr('أمان الحساب', 'Sécurité du compte'),
                                () => _open(const AccountSecurityScreen()),
                                subtitle: s.tr(
                                    'كلمة المرور، البريد الإلكتروني ورقم الهاتف',
                                    'Mot de passe, e-mail et téléphone')),
                            const Divider(height: 32),
                            ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.language),
                                title: Text(s.tr(
                                    'لغة التطبيق', 'Langue de l’application')),
                                subtitle: const Text('العربية / Français'),
                                trailing: TextButton(
                                    onPressed: _busy ? null : _language,
                                    child:
                                        Text(s.isAr ? 'Français' : 'العربية'))),
                            const Divider(height: 32),
                            _row(
                                Icons.help_outline,
                                s.tr('المساعدة والدعم', 'Aide et assistance'),
                                () => _open(const SupportScreen())),
                            _row(
                                Icons.policy_outlined,
                                s.tr('سياسة الخصوصية',
                                    'Politique de confidentialité'),
                                () => _open(const PrivacyComplianceScreen(
                                    initialTab: 0))),
                            if (_state.isLoggedIn) ...[
                              _row(
                                  Icons.delete_outline,
                                  s.tr('حذف الحساب والبيانات',
                                      'Supprimer le compte et les données'),
                                  () => _open(const PrivacyComplianceScreen(
                                      initialTab: 1))),
                              const SizedBox(height: 24),
                              OutlinedButton(
                                  onPressed: _busy ? null : _logout,
                                  child: Text(s.logout)),
                            ],
                            if (_busy)
                              const Padding(
                                  padding: EdgeInsets.only(top: 16),
                                  child: Center(
                                      child: CircularProgressIndicator())),
                            if (_error != null)
                              Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Semantics(
                                      liveRegion: true,
                                      child: Text(_error!,
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error)))),
                          ]))),
            ));
      });

  Widget _row(IconData icon, String title, VoidCallback onTap,
          {String? subtitle}) =>
      ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 6),
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: _busy ? null : onTap,
      );
}
