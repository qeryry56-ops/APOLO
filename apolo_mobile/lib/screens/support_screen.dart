import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/state/app_state.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  bool _opening = false;
  String? _error;
  Future<void> _contact() async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      // Existing documented contact in PrivacyComplianceScreen; no invented SLA.
      if (!await launchUrl(Uri(scheme: 'mailto', path: 'support@apolo.ma'))) {
        throw StateError('No mail app');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppState().s.tr(
            'تعذر فتح تطبيق البريد. يمكنك مراسلة support@apolo.ma يدوياً.',
            'Impossible d’ouvrir votre messagerie. Écrivez à support@apolo.ma manuellement.'));
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
          appBar: AppBar(
              title: Text(s.tr('المساعدة والدعم', 'Aide et assistance'))),
          body: Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: ListView(padding: const EdgeInsets.all(24), children: [
                    const Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Icon(Icons.mail_outline, size: 36)),
                    const SizedBox(height: 24),
                    Text(
                        s.tr('كيف يمكننا مساعدتك؟',
                            'Comment pouvons-nous vous aider ?'),
                        style: const TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    Text(
                        s.tr(
                            'اشرح المشكلة والخطوات التي سبقتها. يمكنك إرفاق صورة بعد إخفاء المعلومات الشخصية.',
                            'Décrivez le problème et les étapes qui l’ont précédé. Vous pouvez joindre une capture après avoir masqué vos informations personnelles.'),
                        style: const TextStyle(height: 1.6)),
                    const SizedBox(height: 24),
                    const SelectableText('support@apolo.ma',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                        onPressed: _opening ? null : _contact,
                        icon: const Icon(Icons.open_in_new),
                        label: Text(
                            s.tr('فتح تطبيق البريد', 'Ouvrir la messagerie'))),
                    const SizedBox(height: 12),
                    Text(s.tr(
                        'لن تُرسل رسالة تلقائياً. راجعها ثم أرسلها من تطبيق البريد.',
                        'Aucun message n’est envoyé automatiquement. Relisez-le et envoyez-le depuis votre messagerie.')),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                        s.tr(
                            'لا تشارك كلمة المرور أو رمز التحقق أو بيانات الدفع مع أي شخص.',
                            'Ne partagez jamais votre mot de passe, code de vérification ou données de paiement.'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, height: 1.6)),
                    if (_error != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 20),
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
