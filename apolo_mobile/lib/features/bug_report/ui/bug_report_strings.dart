import '../../../core/config/app_config.dart';

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
        'Report a technical problem',
      );

  String get entrySubtitle => tr(
        'إذا كانت إحدى الميزات لا تعمل بشكل صحيح، يمكنك إرسال ملاحظاتك لمساعدتنا في تحسين Apolo.ma.',
        'Si une fonctionnalité ne marche pas correctement, vos retours nous aident à améliorer Apolo.ma.',
        'If a feature or product isn\'t working correctly, you can share feedback to help us improve Apolo.ma.',
      );

  String get entryPrimaryCta => tr(
        'الإبلاغ عن مشكلة',
        'Signaler un problème',
        'Report a problem',
      );

  String get abuseNoticeTitle => tr(
        'لا ينبغي إرسال بلاغات الإساءة أو السبام هنا.',
        'Les signalements d\'abus ou de spam ne doivent pas être envoyés ici.',
        'Reports about abuse or spam shouldn\'t be submitted here.',
      );

  String get abuseNoticeSubtitle => tr(
        'تعرّف على كيفية الإبلاغ عن الاحتيال أو السبام أو المحتوى المخالف ومعايير الأمان في Apolo.ma.',
        'Découvrez comment signaler une fraude, du spam, du contenu interdit ou un problème de sécurité.',
        'Learn how to report abuse, spam, fraud, or policy and safety violations on Apolo.ma.',
      );

  String get shakeToggleTitle => tr(
        'هزّ الهاتف للإبلاغ عن مشكلة',
        'Secouer le téléphone pour signaler un problème',
        'Shake phone to report a problem',
      );

  String shakeToggleSubtitle(bool enabled, bool hardwareSupported) {
    if (!hardwareSupported) {
      return enabled
          ? tr(
              'مفعّل للهواتف المزوّدة بمستشعر الحركة',
              'Activé sur mobile (capteur indisponible sur navigateur bureau)',
              'Enabled for mobile sensors (desktop browser has no accelerometer)',
            )
          : tr(
              'تم إيقاف التفعيل',
              'Désactivé',
              'Toggle on to enable',
            );
    }
    return enabled
        ? tr(
            'أوقف التفعيل لتعطيل الميزة',
            'Désactiver pour couper le déclenchement par secousse',
            'Toggle off to disable',
          )
        : tr(
            'فعّل الخيار للإبلاغ عبر هزّ الهاتف',
            'Activer pour signaler en secouant l\'appareil',
            'Toggle on to enable',
          );
  }

  // Step 2 — Logs & Diagnostics Consent Screen
  String get flowHeaderTitle => tr(
        'الإبلاغ عن مشكلة تقنية',
        'Signaler un problème technique',
        'Report technical problem',
      );

  String get learnMoreAbuse => tr(
        'تعرّف على كيفية الإبلاغ عن الإساءة أو الاحتيال',
        'En savoir plus sur le signalement d\'abus ou de spam',
        'Learn more about reporting abuse or spam',
      );

  String get consentHeading => tr(
        'هل ترغب في تضمين السجلات والتشخيصات الإضافية؟',
        'Souhaitez-vous inclure les journaux et diagnostics supplémentaires ?',
        'Would you like to include additional logs and diagnostics?',
      );

  String get basicContextHeading => tr(
        'يُجمع دائماً السياق الأساسي الضروري:',
        'Contexte de base toujours inclus :',
        'Always collected basic context:',
      );

  String get basicContextBody => tr(
        'معرّف حسابك (إن كنت مسجّل الدخول)، إصدار التطبيق ورقم البناء، نوع المنصة والنظام، اسم الشاشة الحالية، وإعداد اللغة واتجاه الواجهة (RTL/LTR).',
        'Votre identifiant utilisateur (si connecté), la version et le build de l\'app, la plateforme/OS, l\'écran actuel et la langue/direction (RTL/LTR).',
        'Your authenticated user ID (if signed in), app version/build number, platform/OS, current screen/route name, and locale/RTL state.',
      );

  String get optionalLogsHeading => tr(
        'بيانات اختيارية (تُرفق فقط بموافقتك):',
        'Diagnostics optionnels (envoyés uniquement avec votre accord) :',
        'Optional diagnostics (only attached if you opt in):',
      );

  String get optionalLogsBody => tr(
        'سجل الأحداث المؤقت داخل الذاكرة، مسار التنقل وأخطاء الشبكة المختصرة (دون كلمات مرور أو رموز سرية)، وأبعاد الشاشة والجهاز لمساعدة فريق Apolo.ma على حل العطل.',
        'Tampon récent des journaux en mémoire, traces de navigation/erreurs API (sans jetons ni mots de passe) et métadonnées d\'affichage.',
        'Recent in-memory log buffer, navigation and sanitized API error breadcrumbs, and device/viewport metadata to help reproduce the bug.',
      );

  String get includeAndContinue => tr(
        'تضمين والمتابعة',
        'Inclure et continuer',
        'Include and continue',
      );

  String get dontIncludeAndContinue => tr(
        'عدم التضمين والمتابعة',
        'Ne pas inclure et continuer',
        'Don\'t include and continue',
      );

  // Step 3 — Composer & Screenshot Screen
  String get send => tr('إرسال', 'Envoyer', 'Send');

  String get descriptionHint => tr(
        'اشرح باختصار ما حدث أو ما الذي لا يعمل.',
        'Expliquez brièvement ce qui s\'est passé ou ce qui ne fonctionne pas.',
        'Briefly explain what happened or what\'s not working.',
      );

  String get screenshotButton => tr('لقطة شاشة', 'Capture', 'Screenshot');

  String get uploadButton => tr('رفع صورة', 'Importer', 'Upload');

  String get removeScreenshotTooltip => tr(
        'إزالة الصورة',
        'Supprimer la capture',
        'Remove screenshot',
      );

  String get previewScreenshotTooltip => tr(
        'معاينة الصورة',
        'Aperçu de la capture',
        'Preview screenshot',
      );

  String get webCaptureFallbackHint => tr(
        'تعذّر التقاط الشاشة تلقائياً على المتصفح — يمكنك رفع صورة يدوياً.',
        'Capture automatique indisponible sur cette vue — utilisez Importer.',
        'Auto-capture wasn\'t available on this view — you can use Upload instead.',
      );

  String get descriptionEmptyError => tr(
        'يرجى كتابة وصف مختصر للمشكلة التقنية قبل الإرسال.',
        'Veuillez décrire brièvement le problème avant d\'envoyer.',
        'Please describe what happened before sending.',
      );

  String get descriptionTooShortError => tr(
        'يرجى كتابة 5 أحرف على الأقل لوصف المشكلة.',
        'Veuillez saisir au moins 5 caractères pour décrire le problème.',
        'Please write at least 5 characters to describe the issue.',
      );

  String get fileTooLargeError => tr(
        'حجم الصورة يتجاوز الحد الأقصى (5 ميغابايت).',
        'L\'image dépasse la taille maximale autorisée (5 Mo).',
        'Image exceeds the 5 MB maximum size limit.',
      );

  String get unsupportedFormatError => tr(
        'صيغة الصورة غير مدعومة. اختر JPEG أو PNG أو WebP.',
        'Format non pris en charge. Choisissez JPEG, PNG ou WebP.',
        'Unsupported image format. Please choose JPEG, PNG, or WebP.',
      );

  String get uploadFailedError => tr(
        'تعذّر قراءة الصورة المختارة.',
        'Impossible de lire l\'image sélectionnée.',
        'Could not read the selected image.',
      );

  String get retry => tr('إعادة المحاولة', 'Réessayer', 'Retry');

  String get close => tr('إغلاق', 'Fermer', 'Close');

  String submitSuccess(int reportId) => reportId > 0
      ? tr(
          'شكراً لك! تم استلام بلاغك التقني بنجاح (#$reportId)',
          'Merci ! Votre rapport technique a bien été envoyé (#$reportId)',
          'Thanks! Your technical report has been received (#$reportId)',
        )
      : tr(
          'شكراً لك! تم إرسال بلاغك التقني بنجاح.',
          'Merci ! Votre rapport technique a bien été envoyé.',
          'Thanks! Your technical report has been received.',
        );

  String submitGenericError(String? serverMsg) =>
      (serverMsg != null && serverMsg.trim().isNotEmpty)
          ? serverMsg
          : tr(
              'تعذر إرسال البلاغ الآن. تحقق من الاتصال وأعد المحاولة.',
              'Impossible d\'envoyer le rapport. Vérifiez votre connexion et réessayez.',
              'Could not send the report right now. Check your connection and retry.',
            );

  String rateLimitError(int? seconds) => seconds != null
      ? tr(
          'تم إرسال عدة بلاغات بسرعة. انتظر $seconds ثانية ثم أعد المحاولة.',
          'Trop de signalements envoyés. Réessayez dans $seconds secondes.',
          'Too many reports sent recently. Please retry in $seconds seconds.',
        )
      : tr(
          'تم إرسال عدة بلاغات بسرعة. يرجى المحاولة بعد قليل.',
          'Trop de signalements envoyés. Veuillez patienter un instant.',
          'Too many reports sent recently. Please wait a moment and retry.',
        );

  // Abuse Guide Sheet
  String get abuseGuideTitle => tr(
        'الإبلاغ عن الإساءة أو الاحتيال أو المحتوى المخالف',
        'Signaler un abus, un spam ou une fraude',
        'Reporting abuse, spam & safety issues',
      );

  String get abuseGuideBody => tr(
        'تم تخصيص نموذج البلاغ التقني لأعطال التطبيق فقط. للإبلاغ عن إعلان مشبوه، رسالة مسيئة، أو متجر مخالف على Apolo.ma، افتح قائمة الخيارات (•••) في صفحة الإعلان أو المحادثة واختر «إبلاغ»، أو قدّم بلاغ أمان مباشر الآن.',
        'Ce formulaire est réservé aux bugs techniques. Pour signaler une annonce suspecte, un message abusif ou une fraude sur Apolo.ma, utilisez le bouton « Signaler » sur l\'annonce ou la conversation, ou envoyez un signalement de sécurité ci-dessous.',
        'This form is strictly for technical bugs. To report suspicious listings, harassment, fraud, or policy violations on Apolo.ma, tap the Report option on that listing or chat, or open our safety reporting form below.',
      );

  String get openSafetyReportCta => tr(
        'فتح نموذج الإبلاغ عن الأمان والمحتوى',
        'Ouvrir le signalement de sécurité',
        'Open Safety & Abuse Report',
      );

  // Settings & Support Entry Points
  String get settingsRowTitle => tr(
        'الإبلاغ عن مشكلة تقنية',
        'Signaler un problème technique',
        'Report a technical problem',
      );

  String get supportCardSubtitle => tr(
        'واجهت عطلاً أو مشكلة في الشاشة؟ أرسل لنا تقريراً تقنياً مع لقطة شاشة.',
        'Un bug ou un écran bloqué ? Envoyez un rapport technique avec capture d\'écran.',
        'Found a bug or broken screen? Send a technical report with an optional screenshot.',
      );
}
