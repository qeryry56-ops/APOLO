import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/state/app_state.dart';
import '../features/bug_report/services/bug_report_controller.dart';
import '../features/bug_report/ui/bug_report_strings.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  bool _opening = false;
  String? _error;

  static const Color _bg = Color(0xFFF2F3F7);
  static const Color _cardBg = Colors.white;
  static const Color _ink = Color(0xFF0A0A0A);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _trailingMuted = Color(0xFF8E8E93);
  static const Color _divider = Color(0xFFF1F2F6);
  static const Color _blue = Color(0xFF0866FF);
  static const Color _red = Color(0xFFE31B23);

  Future<void> _contact() async {
    if (_opening) return;
    HapticFeedback.selectionClick();
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

  void _copyEmail() {
    HapticFeedback.selectionClick();
    Clipboard.setData(const ClipboardData(text: 'support@apolo.ma'));
    final s = AppState().s;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(s.tr(
          'تم نسخ البريد الإلكتروني support@apolo.ma',
          'Adresse support@apolo.ma copiée',
          'Copied support@apolo.ma',
        )),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState().s;
    final isAr = s.isAr;

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
            s.tr('المساعدة والدعم', 'Aide et assistance', 'Help & Support'),
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
                            Icons.mail_outline,
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
                                  'كيف يمكننا مساعدتك؟',
                                  'Comment pouvons-nous vous aider ?',
                                  'How can we help you?',
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
                                  'اشرح المشكلة والخطوات التي سبقتها. يمكنك إرفاق صورة بعد إخفاء المعلومات الشخصية.',
                                  'Décrivez le problème et les étapes qui l’ont précédé. Vous pouvez joindre une capture après avoir masqué vos informations personnelles.',
                                  'Explain the issue and the steps before it. You may attach a screenshot after masking personal details.',
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

                  const SizedBox(height: 12),

                  // Technical Bug Report CTA Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: _red.withValues(alpha: 0.10),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.bug_report_outlined,
                                size: 21,
                                color: _red,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    BugReportStrings(s).entryTitle,
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                      color: _ink,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    BugReportStrings(s).supportCardSubtitle,
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
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 46,
                          child: ElevatedButton.icon(
                            key: const Key('support-report-bug-cta'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _red,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              BugReportController.instance
                                  .openBugReporter(context: context);
                            },
                            icon: const Icon(Icons.bug_report_outlined, size: 19),
                            label: Text(
                              BugReportStrings(s).entryPrimaryCta,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Direct Contact Section
                  _buildSectionHeader(
                    s.tr('التواصل المباشر', 'Contact direct', 'Direct contact'),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              const Icon(CupertinoIcons.at,
                                  size: 20, color: _ink),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: SelectableText(
                                  'support@apolo.ma',
                                  textDirection: TextDirection.ltr,
                                  style: TextStyle(
                                    color: _ink,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: s.tr('نسخ', 'Copier', 'Copy'),
                                onPressed: _copyEmail,
                                icon: const Icon(
                                  CupertinoIcons.doc_on_doc,
                                  size: 18,
                                  color: _muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding:
                              EdgeInsetsDirectional.only(start: 48, end: 14),
                          child: Divider(
                              height: 1, thickness: 1, color: _divider),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _opening ? null : _contact,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 13),
                              child: Row(
                                children: [
                                  const Icon(Icons.open_in_new,
                                      size: 20, color: _blue),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      s.tr(
                                        'فتح تطبيق البريد',
                                        'Ouvrir la messagerie',
                                        'Open Mail App',
                                      ),
                                      style: const TextStyle(
                                        color: _blue,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (_opening)
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
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
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 8, 6, 0),
                    child: Text(
                      s.tr(
                        'لن تُرسل رسالة تلقائياً. راجعها ثم أرسلها من تطبيق البريد.',
                        'Aucun message n’est envoyé automatiquement. Relisez-le et envoyez-le depuis votre messagerie.',
                        'No email is sent automatically. Review and send it from your mail app.',
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: _muted,
                        height: 1.45,
                      ),
                    ),
                  ),

                  // Safety Reminder Section
                  _buildSectionHeader(
                    s.tr('تذكير الأمان', 'Rappel de sécurité',
                        'Safety reminder'),
                  ),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _red.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.shield_lefthalf_fill,
                            size: 18,
                            color: _red,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            s.tr(
                              'لا تشارك كلمة المرور أو رمز التحقق أو بيانات الدفع مع أي شخص.',
                              'Ne partagez jamais votre mot de passe, code de vérification ou données de paiement.',
                              'Never share your password, verification code, or payment details with anyone.',
                            ),
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(top: 14),
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
                            fontWeight: FontWeight.w500,
                          ),
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
      padding: const EdgeInsetsDirectional.only(
        start: 4,
        end: 4,
        top: 14,
        bottom: 6,
      ),
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
}
