import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/state/app_state.dart';
import '../features/bug_report/services/bug_report_controller.dart';
import '../features/bug_report/ui/bug_report_strings.dart';
import '../widgets/dl_settings_kit.dart';
import '../l10n/l10n.dart';

/// Dynamic Layer v5.1 `Help & Support` Screen:
/// - Pure `#FFFFFF` canvas + `ApoloDlTopNav`
/// - Flat `#F6F6F6` rounded `20px` cards with `#FFFFFF` `40×40` icon circles
/// - `#000000` primary capsule Bug Reporter CTA (`Key('support-report-bug-cta')`)
class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  bool _opening = false;
  String? _error;

  static const Color _dlBg = Color(0xFFFFFFFF);
  static const Color _dlSurface = Color(0xFFF6F6F6);
  static const Color _dlSeparator = Color(0xFFEEEEEE);
  static const Color _dlInk = Color(0xFF000000);
  static const Color _dlMuted = Color(0xFF757575);
  static const Color _dlDanger = Color(0xFFE31B23);

  Future<void> _contact() async {
    if (_opening) return;
    HapticFeedback.selectionClick();
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      if (!await launchUrl(Uri(scheme: 'mailto', path: 'support@apolo.ma'))) {
        throw StateError('No mail app');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppState().s.tr(
              'تعذر فتح تطبيق البريد. يمكنك مراسلة support@apolo.ma يدوياً.',
              'Impossible d’ouvrir votre messagerie. Écrivez à support@apolo.ma manuellement.',
              appL10n.supportCouldNotOpenMailApp,
            ));
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  void _copyEmail() {
    HapticFeedback.selectionClick();
    Clipboard.setData(const ClipboardData(text: 'support@apolo.ma'));
    final s = AppState().s;
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _dlInk,
          shape: const StadiumBorder(),
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          content: Text(
            s.tr(
              'تم نسخ البريد الإلكتروني support@apolo.ma',
              'Adresse support@apolo.ma copiée',
              appL10n.settingsSuggestionCopiedSupportApoloMa,
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
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
        backgroundColor: _dlBg,
        body: SafeArea(
          child: Column(
            children: [
              ApoloDlTopNav(
                title: s.tr(
                  'المساعدة والدعم',
                  'Aide et assistance',
                  appL10n.settingsBugReportHelpSupport,
                ),
                showSeparator: false,
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
                      children: [
                        // Intro Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _dlSurface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: const BoxDecoration(
                                  color: _dlBg,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  CupertinoIcons.mail_solid,
                                  size: 19,
                                  color: _dlInk,
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
                                        appL10n.supportHowCanWeHelpYou,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w700,
                                        color: _dlInk,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      s.tr(
                                        'اشرح المشكلة والخطوات التي سبقتها. يمكنك إرفاق صورة بعد إخفاء المعلومات الشخصية.',
                                        'Décrivez le problème et les étapes qui l’ont précédé. Vous pouvez joindre une capture après avoir masqué vos informations personnelles.',
                                        appL10n.supportExplainIssueStepsBeforeIt,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: _dlMuted,
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
                            color: _dlSurface,
                            borderRadius: BorderRadius.circular(20),
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
                                    decoration: const BoxDecoration(
                                      color: _dlBg,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      CupertinoIcons.ant_fill,
                                      size: 19,
                                      color: _dlInk,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          BugReportStrings(s).entryTitle,
                                          style: const TextStyle(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w700,
                                            color: _dlInk,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          BugReportStrings(s)
                                              .supportCardSubtitle,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: _dlMuted,
                                            height: 1.45,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              ApoloDlButton(
                                key: const Key('support-report-bug-cta'),
                                label: BugReportStrings(s).entryPrimaryCta,
                                leadingIcon: CupertinoIcons.ant,
                                variant: ApoloDlButtonVariant.primary,
                                borderRadius: 999,
                                height: 48,
                                fullWidth: true,
                                onPressed: () {
                                  BugReportController.instance
                                      .openBugReporter(context: context);
                                },
                              ),
                            ],
                          ),
                        ),

                        // Direct Contact Section
                        ApoloDlSectionHeader(
                          title: s.tr(
                            'التواصل المباشر',
                            'Contact direct',
                            appL10n.supportDirectContact,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: _dlSurface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: const BoxDecoration(
                                        color: _dlBg,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        CupertinoIcons.at,
                                        size: 17,
                                        color: _dlInk,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: SelectableText(
                                        'support@apolo.ma',
                                        textDirection: TextDirection.ltr,
                                        style: TextStyle(
                                          color: _dlInk,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    ApoloDlIconCircleButton(
                                      icon: CupertinoIcons.doc_on_doc,
                                      iconSize: 16,
                                      backgroundColor: _dlBg,
                                      iconColor: _dlInk,
                                      tooltip: s.tr('نسخ', 'Copier', appL10n.adDetailCopy),
                                      onPressed: _copyEmail,
                                    ),
                                  ],
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsetsDirectional.only(
                                  start: 60,
                                  end: 14,
                                ),
                                child: Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: _dlSeparator,
                                ),
                              ),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _opening ? null : _contact,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 13,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 34,
                                          height: 34,
                                          decoration: const BoxDecoration(
                                            color: _dlBg,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: const Icon(
                                            CupertinoIcons.arrow_up_right_square,
                                            size: 17,
                                            color: _dlInk,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            s.tr(
                                              'فتح تطبيق البريد',
                                              'Ouvrir la messagerie',
                                              appL10n.supportOpenMailApp,
                                            ),
                                            style: const TextStyle(
                                              color: _dlInk,
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (_opening)
                                          const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: _dlInk,
                                            ),
                                          )
                                        else
                                          Icon(
                                            isAr
                                                ? CupertinoIcons.chevron_left
                                                : CupertinoIcons.chevron_right,
                                            size: 14,
                                            color: _dlMuted,
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
                              appL10n.supportNoEmailIsSentAutomatically,
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              color: _dlMuted,
                              height: 1.45,
                            ),
                          ),
                        ),

                        // Safety Reminder Section
                        ApoloDlSectionHeader(
                          title: s.tr(
                            'تذكير الأمان',
                            'Rappel de sécurité',
                            appL10n.supportSafetyReminder,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _dlSurface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: const BoxDecoration(
                                  color: _dlBg,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  CupertinoIcons.shield_lefthalf_fill,
                                  size: 18,
                                  color: _dlInk,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  s.tr(
                                    'لا تشارك كلمة المرور أو رمز التحقق أو بيانات الدفع مع أي شخص.',
                                    'Ne partagez jamais votre mot de passe, code de vérification ou données de paiement.',
                                    appL10n.supportNeverSharePasswordVerificationCode,
                                  ),
                                  style: const TextStyle(
                                    color: _dlInk,
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
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: _dlSurface,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Semantics(
                              liveRegion: true,
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: _dlDanger,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
