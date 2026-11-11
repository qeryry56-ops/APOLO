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
  bool _opening = false;
  String? _error;
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
                            'تغيير هذه البيانات غير متاح داخل التطبيق حالياً. افتح موقع Apolo وسجّل الدخول إليه بشكل منفصل، ثم ابحث عن إعدادات حسابك. إذا لم تجد الخيار، تواصل مع الدعم.',
                            'La modification de ces informations n’est pas disponible dans l’application. Ouvrez le site Apolo, connectez-vous séparément, puis consultez les paramètres de votre compte. Si l’option est absente, contactez l’assistance.'),
                        style: const TextStyle(height: 1.6)),
                    const SizedBox(height: 24),
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
                          subtitle: Text(
                              s.tr('إدارة عبر الموقع', 'Gestion sur le site'))),
                      const Divider(),
                    ],
                    const SizedBox(height: 20),
                    Text(s.tr(
                        'لن يتم تغيير أي بيانات بمجرد فتح الموقع. جلسة التطبيق لا تنتقل إلى المتصفح.',
                        'Ouvrir le site ne modifie aucune donnée. Votre session dans l’application n’est pas transférée au navigateur.')),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                        onPressed: _opening ? null : _open,
                        icon: _opening
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.open_in_new),
                        label: Text(s.tr('فتح apolo.ma', 'Ouvrir apolo.ma'))),
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
  }
}
