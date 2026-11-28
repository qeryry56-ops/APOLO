import '../../../core/config/app_config.dart';
import '../../../l10n/l10n.dart';

/// Multilingual (Arabic RTL, French LTR, English LTR) copy for the 3-step
/// Apolo.ma Technical Bug & Issue Reporting flow.
class BugReportStrings {
  final AppStrings s;

  const BugReportStrings(this.s);

  bool get isRtl => s.isAr;

  String tr(String ar, String fr, String en) => s.tr(ar, fr, en);

  // Step 1 — Entry Bottom Sheet
  String get entryTitle => tr(
        'الإبلاغ عن مشكلة تقنية',
        'Signaler un problème technique',
        appL10n.bugReportReportTechnicalProblem,
      );

  String get entrySubtitle => tr(
        'إذا كانت إحدى الميزات لا تعمل بشكل صحيح، يمكنك إرسال ملاحظاتك لمساعدتنا في تحسين Apolo.ma.',
        'Si une fonctionnalité ne marche pas correctement, vos retours nous aident à améliorer Apolo.ma.',
        appL10n.bugReportIfFeatureProductIsnT,
      );

  String get entryPrimaryCta => tr(
        'الإبلاغ عن مشكلة',
        'Signaler un problème',
        appL10n.bugReportReportProblem,
      );

  String get abuseNoticeTitle => tr(
        'لا ينبغي إرسال بلاغات الإساءة أو السبام هنا.',
        'Les signalements d\'abus ou de spam ne doivent pas être envoyés ici.',
        appL10n.bugReportReportsAboutAbuseSpamShouldn,
      );

  String get abuseNoticeSubtitle => tr(
        'تعرّف على كيفية الإبلاغ عن الاحتيال أو السبام أو المحتوى المخالف ومعايير الأمان في Apolo.ma.',
        'Découvrez comment signaler une fraude, du spam, du contenu interdit ou un problème de sécurité.',
        appL10n.bugReportLearnHowReportAbuseSpam,
      );

  String get shakeToggleTitle => tr(
        'هزّ الهاتف للإبلاغ عن مشكلة',
        'Secouer le téléphone pour signaler un problème',
        appL10n.bugReportShakePhoneReportProblem,
      );

  String shakeToggleSubtitle(bool enabled, bool hardwareSupported) {
    if (!hardwareSupported) {
      return enabled
          ? tr(
              'مفعّل للهواتف المزوّدة بمستشعر الحركة',
              'Activé sur mobile (capteur indisponible sur navigateur bureau)',
              appL10n.bugReportEnabledMobileSensorsDesktopBrowser,
            )
          : tr(
              'تم إيقاف التفعيل',
              'Désactivé',
              appL10n.bugReportToggleEnable,
            );
    }
    return enabled
        ? tr(
            'أوقف التفعيل لتعطيل الميزة',
            'Désactiver pour couper le déclenchement par secousse',
            appL10n.bugReportToggleOffDisable,
          )
        : tr(
            'فعّل الخيار للإبلاغ عبر هزّ الهاتف',
            'Activer pour signaler en secouant l\'appareil',
            appL10n.bugReportToggleEnable,
          );
  }

  // Step 2 — Logs & Diagnostics Consent Screen
  String get flowHeaderTitle => tr(
        'الإبلاغ عن مشكلة تقنية',
        'Signaler un problème technique',
        appL10n.bugReportReportTechnicalProblem2,
      );

  String get learnMoreAbuse => tr(
        'تعرّف على كيفية الإبلاغ عن الإساءة أو الاحتيال',
        'En savoir plus sur le signalement d\'abus ou de spam',
        appL10n.bugReportLearnMoreAboutReportingAbuse,
      );

  String get consentHeading => tr(
        'هل ترغب في تضمين السجلات والتشخيصات الإضافية؟',
        'Souhaitez-vous inclure les journaux et diagnostics supplémentaires ?',
        appL10n.bugReportWouldYouLikeIncludeAdditional,
      );

  String get basicContextHeading => tr(
        'يُجمع دائماً السياق الأساسي الضروري:',
        'Contexte de base toujours inclus :',
        appL10n.bugReportAlwaysCollectedBasicContext,
      );

  String get basicContextBody => tr(
        'معرّف حسابك (إن كنت مسجّل الدخول)، إصدار التطبيق ورقم البناء، نوع المنصة والنظام، اسم الشاشة الحالية، وإعداد اللغة واتجاه الواجهة (RTL/LTR).',
        'Votre identifiant utilisateur (si connecté), la version et le build de l\'app, la plateforme/OS, l\'écran actuel et la langue/direction (RTL/LTR).',
        appL10n.bugReportAuthenticatedUserIdIfSigned,
      );

  String get optionalLogsHeading => tr(
        'بيانات اختيارية (تُرفق فقط بموافقتك):',
        'Diagnostics optionnels (envoyés uniquement avec votre accord) :',
        appL10n.bugReportOptionalDiagnosticsOnlyAttachedIf,
      );

  String get optionalLogsBody => tr(
        'سجل الأحداث المؤقت داخل الذاكرة، مسار التنقل وأخطاء الشبكة المختصرة (دون كلمات مرور أو رموز سرية)، وأبعاد الشاشة والجهاز لمساعدة فريق Apolo.ma على حل العطل.',
        'Tampon récent des journaux en mémoire, traces de navigation/erreurs API (sans jetons ni mots de passe) et métadonnées d\'affichage.',
        appL10n.bugReportRecentMemoryLogBufferNavigation,
      );

  String get includeAndContinue => tr(
        'تضمين والمتابعة',
        'Inclure et continuer',
        appL10n.bugReportIncludeContinue,
      );

  String get dontIncludeAndContinue => tr(
        'عدم التضمين والمتابعة',
        'Ne pas inclure et continuer',
        appL10n.bugReportDonTIncludeContinue,
      );

  // Step 3 — Composer & Screenshot Screen
  String get send => tr('إرسال', 'Envoyer', appL10n.sendButton);

  String get descriptionHint => tr(
        'اشرح باختصار ما حدث أو ما الذي لا يعمل.',
        'Expliquez brièvement ce qui s\'est passé ou ce qui ne fonctionne pas.',
        appL10n.bugReportBrieflyExplainWhatHappenedWhat,
      );

  String get screenshotButton => tr('لقطة شاشة', 'Capture', appL10n.bugReportScreenshot);

  String get uploadButton => tr('رفع صورة', 'Importer', appL10n.bugReportUpload);

  String get removeScreenshotTooltip => tr(
        'إزالة الصورة',
        'Supprimer la capture',
        appL10n.bugReportRemoveScreenshot,
      );

  String get previewScreenshotTooltip => tr(
        'معاينة الصورة',
        'Aperçu de la capture',
        appL10n.bugReportPreviewScreenshot,
      );

  String get webCaptureFallbackHint => tr(
        'تعذّر التقاط الشاشة تلقائياً على المتصفح — يمكنك رفع صورة يدوياً.',
        'Capture automatique indisponible sur cette vue — utilisez Importer.',
        appL10n.bugReportAutoCaptureWasnTAvailable,
      );

  String get descriptionEmptyError => tr(
        'يرجى كتابة وصف مختصر للمشكلة التقنية قبل الإرسال.',
        'Veuillez décrire brièvement le problème avant d\'envoyer.',
        appL10n.bugReportPleaseDescribeWhatHappenedBefore,
      );

  String get descriptionTooShortError => tr(
        'يرجى كتابة 5 أحرف على الأقل لوصف المشكلة.',
        'Veuillez saisir au moins 5 caractères pour décrire le problème.',
        appL10n.bugReportPleaseWriteAtLeast5,
      );

  String get fileTooLargeError => tr(
        'حجم الصورة يتجاوز الحد الأقصى (5 ميغابايت).',
        'L\'image dépasse la taille maximale autorisée (5 Mo).',
        appL10n.bugReportImageExceeds5MbMaximum,
      );

  String get unsupportedFormatError => tr(
        'صيغة الصورة غير مدعومة. اختر JPEG أو PNG أو WebP.',
        'Format non pris en charge. Choisissez JPEG, PNG ou WebP.',
        appL10n.bugReportUnsupportedImageFormatPleaseChoose,
      );

  String get uploadFailedError => tr(
        'تعذّر قراءة الصورة المختارة.',
        'Impossible de lire l\'image sélectionnée.',
        appL10n.bugReportCouldNotReadSelectedImage,
      );

  String get retry => tr('إعادة المحاولة', 'Réessayer', appL10n.retryButton);

  String get close => tr('إغلاق', 'Fermer', appL10n.closeButton);

  String submitSuccess(int reportId) => reportId > 0
      ? tr(
          'شكراً لك! تم استلام بلاغك التقني بنجاح (#$reportId)',
          'Merci ! Votre rapport technique a bien été envoyé (#$reportId)',
          appL10n.bugReportThanksTechnicalReportHasBeen(reportId),
        )
      : tr(
          'شكراً لك! تم إرسال بلاغك التقني بنجاح.',
          'Merci ! Votre rapport technique a bien été envoyé.',
          appL10n.bugReportThanksTechnicalReportHasBeen2,
        );

  String submitGenericError(String? serverMsg) =>
      (serverMsg != null && serverMsg.trim().isNotEmpty)
          ? serverMsg
          : tr(
              'تعذر إرسال البلاغ الآن. تحقق من الاتصال وأعد المحاولة.',
              'Impossible d\'envoyer le rapport. Vérifiez votre connexion et réessayez.',
              appL10n.bugReportCouldNotSendReportRight,
            );

  String rateLimitError(int? seconds) => seconds != null
      ? tr(
          'تم إرسال عدة بلاغات بسرعة. انتظر $seconds ثانية ثم أعد المحاولة.',
          'Trop de signalements envoyés. Réessayez dans $seconds secondes.',
          appL10n.bugReportTooManyReportsSentRecently(seconds),
        )
      : tr(
          'تم إرسال عدة بلاغات بسرعة. يرجى المحاولة بعد قليل.',
          'Trop de signalements envoyés. Veuillez patienter un instant.',
          appL10n.bugReportTooManyReportsSentRecently2,
        );

  // Abuse Guide Sheet
  String get abuseGuideTitle => tr(
        'الإبلاغ عن الإساءة أو الاحتيال أو المحتوى المخالف',
        'Signaler un abus, un spam ou une fraude',
        appL10n.bugReportReportingAbuseSpamSafetyIssues,
      );

  String get abuseGuideBody => tr(
        'تم تخصيص نموذج البلاغ التقني لأعطال التطبيق فقط. للإبلاغ عن إعلان مشبوه، رسالة مسيئة، أو متجر مخالف على Apolo.ma، افتح قائمة الخيارات (•••) في صفحة الإعلان أو المحادثة واختر «إبلاغ»، أو قدّم بلاغ أمان مباشر الآن.',
        'Ce formulaire est réservé aux bugs techniques. Pour signaler une annonce suspecte, un message abusif ou une fraude sur Apolo.ma, utilisez le bouton « Signaler » sur l\'annonce ou la conversation, ou envoyez un signalement de sécurité ci-dessous.',
        appL10n.bugReportThisFormIsStrictlyTechnical,
      );

  String get openSafetyReportCta => tr(
        'فتح نموذج الإبلاغ عن الأمان والمحتوى',
        'Ouvrir le signalement de sécurité',
        appL10n.bugReportOpenSafetyAbuseReport,
      );

  // Settings & Support Entry Points
  String get settingsRowTitle => tr(
        'الإبلاغ عن مشكلة تقنية',
        'Signaler un problème technique',
        appL10n.bugReportReportTechnicalProblem,
      );

  String get supportCardSubtitle => tr(
        'واجهت عطلاً أو مشكلة في الشاشة؟ أرسل لنا تقريراً تقنياً مع لقطة شاشة.',
        'Un bug ou un écran bloqué ? Envoyez un rapport technique avec capture d\'écran.',
        appL10n.bugReportFoundBugBrokenScreenSend,
      );
}
