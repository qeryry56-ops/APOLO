// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get chatPlaceholder => 'راسل البائع...';

  @override
  String get chatTypeMessageHint => 'اكتب رسالة...';

  @override
  String get chatRecordingPlaceholder => 'جاري التسجيل...';

  @override
  String get chatAddAttachmentTooltip => 'إضافة مرفق';

  @override
  String get chatMessageInputLabel => 'حقل الرسالة';

  @override
  String get chatSendMessageTooltip => 'إرسال الرسالة';

  @override
  String chatStagedAttachmentLabel(Object name) {
    return 'مرفق جاهز: $name';
  }

  @override
  String chatRemoveAttachmentLabel(Object name) {
    return 'إزالة المرفق $name';
  }

  @override
  String get chatDismissMessageMenu => 'إغلاق قائمة الرسالة';

  @override
  String get chatJumpToLatest => 'الأحدث';

  @override
  String chatNewMessagesJumpToLatest(Object count, Object messageWord) {
    return '$count $messageWord جديدة. انتقل للأحدث';
  }

  @override
  String get chatMessageSingular => 'رسالة';

  @override
  String get chatMessagePlural => 'رسائل';

  @override
  String get chatCallAndOptionsTooltip => 'خيارات الاتصال والمحادثة';

  @override
  String get chatSendFailedRetrySemantic =>
      '، تعذر الإرسال، اضغط مرتين للإعادة';

  @override
  String get chatSendingSemantic => '، جاري الإرسال';

  @override
  String get chatEditedLabel => 'معدّلة';

  @override
  String get chatRetrySendingTooltip => 'إعادة إرسال الرسالة';

  @override
  String get chatTypingIndicatorLabel => 'يكتب الآن...';

  @override
  String get chatPhotoPreviewLabel => '📷 صورة';

  @override
  String get chatVoicePreviewLabel => '🎤 رسالة صوتية';

  @override
  String get voiceMicMutedIdleSemantic =>
      'الميكروفون مكتوم. لا يوجد صوت. اضغط مطولاً لتسجيل رسالة صوتية';

  @override
  String get voiceHoldToRecordSemantic =>
      'اضغط مطولاً لتسجيل رسالة صوتية. اسحب لليسار للإلغاء أو للأعلى للتثبيت';

  @override
  String get voiceMicMutedSuffixSemantic => '. تنبيه: الميكروفون مكتوم';

  @override
  String voiceReleaseToCancelSemantic(Object mutedSuffix) {
    return 'اترك لإلغاء التسجيل الصوتي$mutedSuffix';
  }

  @override
  String voiceLockedRecordingSemantic(Object timeStr, Object mutedSuffix) {
    return 'التسجيل مثبّت، $timeStr$mutedSuffix. اضغط إيقاف لإنهاء التسجيل';
  }

  @override
  String voiceActiveRecordingSemantic(Object timeStr, Object mutedSuffix) {
    return 'جاري تسجيل رسالة صوتية، $timeStr$mutedSuffix. اسحب للإلغاء أو للأعلى للتثبيت';
  }

  @override
  String get voiceWaveformMutedSemantic => 'موجة صوتية صامتة، الميكروفون مكتوم';

  @override
  String get voiceWaveformPreviewSemantic => 'معاينة الموجة الصوتية';

  @override
  String get voiceWaveformLiveSemantic => 'موجة صوتية مباشرة';

  @override
  String get voiceMicMutedWarningSemantic =>
      'تنبيه: الميكروفون مكتوم ولا يلتقط صوتاً.';

  @override
  String get voiceMicMutedBadge => 'الميكروفون مكتوم';

  @override
  String get voiceCancelRecordingTooltip => 'إلغاء التسجيل الصوتي';

  @override
  String get voicePauseRecordingTooltip => 'إيقاف مؤقت للتسجيل أو المعاينة';

  @override
  String get voicePlayPreviewTooltip => 'تشغيل المعاينة الصوتية';

  @override
  String get voiceSendVoiceMessageTooltip => 'إرسال الرسالة الصوتية';

  @override
  String get voiceReleaseToCancelLabel => 'اترك للإلغاء';

  @override
  String get voiceSlideToCancelLabel => 'اسحب للإلغاء';

  @override
  String get voiceHoldMicPrompt => 'اضغط مطولاً على الميكروفون لتسجيل رسالة';

  @override
  String get voiceRecordButtonSemantic => 'تسجيل رسالة صوتية';

  @override
  String get voiceRecordGestureHint =>
      'اضغط أو استمر بالضغط للتسجيل. اسحب للداخل للإلغاء وللأعلى للتثبيت';

  @override
  String get voiceWaveformScrubberSemantic => 'شريط تقديم الرسالة الصوتية';

  @override
  String get voiceChatTitle => 'محادثة صوتية';

  @override
  String get voiceMicPermissionRequired =>
      'يرجى السماح بصلاحية الميكروفون لتسجيل الصوت.';

  @override
  String get voiceCouldNotStartRecording =>
      'تعذر بدء التسجيل الصوتي على هذا الجهاز.';

  @override
  String get voiceTapMicEmptyPrompt =>
      'اضغط على الميكروفون بالأسفل لتسجيل رسالة صوتية';

  @override
  String get voiceTapMicInputHint => 'اضغط على الميكروفون لتسجيل مقطع صوتي...';

  @override
  String get voiceToggleWaveformTooltip => 'تبديل شكل الموجة الصوتية';

  @override
  String get voiceToggleThemeTooltip => 'تبديل مظهر GTA 6';

  @override
  String get otpVerifyCodeTitle => 'تأكيد الرمز';

  @override
  String otpEnterSixDigitCode(Object destination) {
    return 'أدخل الرمز المكون من 6 أرقام المرسل إلى $destination';
  }

  @override
  String get otpCodeVerifiedLabel => 'تم تأكيد الرمز';

  @override
  String get otpIncorrectCodeError => 'الرمز غير صحيح، حاول مرة أخرى';

  @override
  String otpResendCodeCountdown(Object seconds) {
    return 'إعادة الإرسال خلال $seconds ث';
  }

  @override
  String get otpResendCodeButton => 'إعادة إرسال الرمز';

  @override
  String get welcomeContinueAsGuestLabel => 'المتابعة كزائر';

  @override
  String get authEmailPlaceholder => 'example@gmail.com';

  @override
  String get authPasswordPlaceholder => 'كلمة المرور';

  @override
  String get authFullNamePlaceholder => 'الاسم';

  @override
  String get authUsernameHandlePlaceholder => '@username';

  @override
  String get authPlainUsernamePlaceholder => 'username';

  @override
  String get moroccoPhonePlaceholder => '+212 6XX XXX XXX';

  @override
  String likeButtonSemantic(Object count) {
    return 'إعجاب، $count إعجابات';
  }

  @override
  String unlikeButtonSemantic(Object count) {
    return 'إلغاء الإعجاب، $count إعجابات';
  }

  @override
  String get likeSyncFailedSemantic => 'تعذر حفظ الإعجاب. اضغط للمحاولة مجدداً';

  @override
  String get pullToRefreshRefreshing => 'جاري تحديث القائمة';

  @override
  String get pullToRefreshRelease => 'اترك للتحديث';

  @override
  String get pullToRefreshPullDown => 'اسحب للأسفل للتحديث';

  @override
  String get badgeOnlineSemantic => 'متصل الآن';

  @override
  String get badgeUnreadNotificationSemantic => 'إشعار غير مقروء';

  @override
  String get badgeUnreadMaxSemantic => '+99 إشعار غير مقروء';

  @override
  String badgeUnreadCountSemantic(Object count, Object notificationWord) {
    return '$count $notificationWord غير مقروءة';
  }

  @override
  String get notificationSingular => 'إشعار';

  @override
  String get notificationPlural => 'إشعارات';

  @override
  String emojiReactWithSemantic(Object emoji) {
    return 'تفاعل بـ $emoji';
  }

  @override
  String get emojiFewerTooltip => 'رموز أقل';

  @override
  String get emojiMoreTooltip => 'رموز أكثر';

  @override
  String get listingFavoriteTooltip => 'حفظ الإعلان فالمفضلة';

  @override
  String get accommodationFavoriteTooltip => 'حفظ الإقامة فالمفضلة';

  @override
  String listingBedroomsCount(Object bedrooms) {
    return '$bedrooms غرف نوم';
  }

  @override
  String get listingTaxesIncluded => 'شامل الرسوم';

  @override
  String accommodationTotalForNights(Object total, Object nights) {
    return '$total الإجمالي · $nights ليالٍ';
  }

  @override
  String get boostActionLabel => 'تمييز';

  @override
  String get liveBadgeLabel => 'مباشر';

  @override
  String get meetingEncryptionKeyHint => 'مفتاح سري AES-GCM 256-bit';

  @override
  String get meetingDefaultTitle => 'اجتماع Apolo';

  @override
  String get meetingDefaultParticipantName => 'مشارك SFU';

  @override
  String get bugReportSafetyHeader => 'أمان Apolo.ma';

  @override
  String get bugReportDescMinLengthError =>
      'يرجى كتابة وصف من 5 أحرف على الأقل.';

  @override
  String get bugReportNetworkFailedError => 'فشل الاتصال بالشبكة.';

  @override
  String get bugReportTimeoutError =>
      'انتهت مهلة الطلب. تحقق من الإنترنت وأعد المحاولة.';

  @override
  String get bugReportServerUnreachableError =>
      'تعذر الوصول إلى خوادم Apolo.ma حالياً.';

  @override
  String get meetingSignInRequiredError =>
      'يرجى تسجيل الدخول للانضمام إلى الاجتماع.';

  @override
  String get meetingPermissionDeniedError =>
      'ليست لديك صلاحية لدخول هذا الاجتماع.';

  @override
  String get meetingAlreadyEndedError => 'انتهى هذا الاجتماع بالفعل.';

  @override
  String get meetingRoomLockedError => 'الغرفة مقفلة حالياً من طرف المضيف.';

  @override
  String get meetingMaxCapacityError =>
      'اكتمل العدد الأقصى للمشاركين في الغرفة.';

  @override
  String get meetingServiceUnreachableError =>
      'تعذر الاتصال بخدمة الاجتماعات، تحقق من الإنترنت.';

  @override
  String get accountOnboardingFormFinishSettingUpAccount => 'أكمل إعداد حسابك';

  @override
  String get accountOnboardingFormChooseCityInterestsYouCan =>
      'اختر مدينتك والمجالات التي تهمك. يمكنك التحويل إلى حساب أعمال (Business) مجاناً في أي وقت من الإعدادات.';

  @override
  String get accountOnboardingFormCity => 'المدينة';

  @override
  String get accountOnboardingFormChooseAtLeastOneInterest =>
      'اختر مجالاً واحداً على الأقل';

  @override
  String get accountOnboardingFormSaveContinue => 'حفظ ومتابعة';

  @override
  String get accountOnboardingFormReloadOptions => 'إعادة تحميل الخيارات';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navExplore => 'استكشف';

  @override
  String get sellItemButton => 'أضف إعلان';

  @override
  String get navStores => 'المتاجر';

  @override
  String get navMessages => 'الرسائل';

  @override
  String get navProfile => 'حسابي';

  @override
  String get categoriesTitle => 'تصفح الأقسام';

  @override
  String get featuredAdsTitle => 'إعلانات VIP المميزة';

  @override
  String get latestAdsTitle => 'أحدث العروض المختارة';

  @override
  String get allCitiesFilter => 'كل مدن المغرب';

  @override
  String get allCategoriesFilter => 'جميع الأقسام';

  @override
  String get loginButton => 'تسجيل الدخول';

  @override
  String get createAccountButton => 'إنشاء حساب جديد';

  @override
  String get logoutButton => 'تسجيل الخروج';

  @override
  String get callSellerButton => 'اتصال';

  @override
  String get whatsappButton => 'واتساب';

  @override
  String get chatInAppButton => 'دردشة فورية';

  @override
  String get boostAdButton => 'تمييز الإعلان VIP';

  @override
  String get deleteAccountButton => 'حذف الحساب نهائياً';

  @override
  String get reportAdButton => 'التبليغ عن الإعلان';

  @override
  String get blockUserButton => 'حظر المستخدم';

  @override
  String get searchHint => 'ابحث عن سيارة، شقة، هاتف...';

  @override
  String get noAdsFoundMessage => 'لا توجد إعلانات مطابقة لبحثك';

  @override
  String get appStateDark => 'داكن';

  @override
  String get appStateSystem => 'تلقائي';

  @override
  String get appStateLight => 'فاتح';

  @override
  String get appStateApoloMember => 'عضو Apolo';

  @override
  String get appStateJustNow => 'الآن';

  @override
  String get appStateKm => 'كم';

  @override
  String get bugReportReportTechnicalProblem => 'الإبلاغ عن مشكلة تقنية';

  @override
  String get bugReportIfFeatureProductIsnT =>
      'إذا كانت إحدى الميزات لا تعمل بشكل صحيح، يمكنك إرسال ملاحظاتك لمساعدتنا في تحسين Apolo.ma.';

  @override
  String get bugReportReportProblem => 'الإبلاغ عن مشكلة';

  @override
  String get bugReportReportsAboutAbuseSpamShouldn =>
      'لا ينبغي إرسال بلاغات الإساءة أو السبام هنا.';

  @override
  String get bugReportLearnHowReportAbuseSpam =>
      'تعرّف على كيفية الإبلاغ عن الاحتيال أو السبام أو المحتوى المخالف ومعايير الأمان في Apolo.ma.';

  @override
  String get bugReportShakePhoneReportProblem => 'هزّ الهاتف للإبلاغ عن مشكلة';

  @override
  String get bugReportEnabledMobileSensorsDesktopBrowser =>
      'مفعّل للهواتف المزوّدة بمستشعر الحركة';

  @override
  String get bugReportToggleEnable => 'تم إيقاف التفعيل';

  @override
  String get bugReportToggleOffDisable => 'أوقف التفعيل لتعطيل الميزة';

  @override
  String get bugReportReportTechnicalProblem2 => 'الإبلاغ عن مشكلة تقنية';

  @override
  String get bugReportLearnMoreAboutReportingAbuse =>
      'تعرّف على كيفية الإبلاغ عن الإساءة أو الاحتيال';

  @override
  String get bugReportWouldYouLikeIncludeAdditional =>
      'هل ترغب في تضمين السجلات والتشخيصات الإضافية؟';

  @override
  String get bugReportAlwaysCollectedBasicContext =>
      'يُجمع دائماً السياق الأساسي الضروري:';

  @override
  String get bugReportAuthenticatedUserIdIfSigned =>
      'معرّف حسابك (إن كنت مسجّل الدخول)، إصدار التطبيق ورقم البناء، نوع المنصة والنظام، اسم الشاشة الحالية، وإعداد اللغة واتجاه الواجهة (RTL/LTR).';

  @override
  String get bugReportOptionalDiagnosticsOnlyAttachedIf =>
      'بيانات اختيارية (تُرفق فقط بموافقتك):';

  @override
  String get bugReportRecentMemoryLogBufferNavigation =>
      'سجل الأحداث المؤقت داخل الذاكرة، مسار التنقل وأخطاء الشبكة المختصرة (دون كلمات مرور أو رموز سرية)، وأبعاد الشاشة والجهاز لمساعدة فريق Apolo.ma على حل العطل.';

  @override
  String get bugReportIncludeContinue => 'تضمين والمتابعة';

  @override
  String get bugReportDonTIncludeContinue => 'عدم التضمين والمتابعة';

  @override
  String get sendButton => 'إرسال';

  @override
  String get bugReportBrieflyExplainWhatHappenedWhat =>
      'اشرح باختصار ما حدث أو ما الذي لا يعمل.';

  @override
  String get bugReportScreenshot => 'لقطة شاشة';

  @override
  String get bugReportUpload => 'رفع صورة';

  @override
  String get bugReportRemoveScreenshot => 'إزالة الصورة';

  @override
  String get bugReportPreviewScreenshot => 'معاينة الصورة';

  @override
  String get bugReportAutoCaptureWasnTAvailable =>
      'تعذّر التقاط الشاشة تلقائياً على المتصفح — يمكنك رفع صورة يدوياً.';

  @override
  String get bugReportPleaseDescribeWhatHappenedBefore =>
      'يرجى كتابة وصف مختصر للمشكلة التقنية قبل الإرسال.';

  @override
  String get bugReportPleaseWriteAtLeast5 =>
      'يرجى كتابة 5 أحرف على الأقل لوصف المشكلة.';

  @override
  String get bugReportImageExceeds5MbMaximum =>
      'حجم الصورة يتجاوز الحد الأقصى (5 ميغابايت).';

  @override
  String get bugReportUnsupportedImageFormatPleaseChoose =>
      'صيغة الصورة غير مدعومة. اختر JPEG أو PNG أو WebP.';

  @override
  String get bugReportCouldNotReadSelectedImage =>
      'تعذّر قراءة الصورة المختارة.';

  @override
  String get retryButton => 'إعادة المحاولة';

  @override
  String get closeButton => 'إغلاق';

  @override
  String bugReportThanksTechnicalReportHasBeen(Object reportId) {
    return 'شكراً لك! تم استلام بلاغك التقني بنجاح (#$reportId)';
  }

  @override
  String get bugReportThanksTechnicalReportHasBeen2 =>
      'شكراً لك! تم إرسال بلاغك التقني بنجاح.';

  @override
  String get bugReportCouldNotSendReportRight =>
      'تعذر إرسال البلاغ الآن. تحقق من الاتصال وأعد المحاولة.';

  @override
  String bugReportTooManyReportsSentRecently(Object seconds) {
    return 'تم إرسال عدة بلاغات بسرعة. انتظر $seconds ثانية ثم أعد المحاولة.';
  }

  @override
  String get bugReportTooManyReportsSentRecently2 =>
      'تم إرسال عدة بلاغات بسرعة. يرجى المحاولة بعد قليل.';

  @override
  String get bugReportReportingAbuseSpamSafetyIssues =>
      'الإبلاغ عن الإساءة أو الاحتيال أو المحتوى المخالف';

  @override
  String get bugReportThisFormIsStrictlyTechnical =>
      'تم تخصيص نموذج البلاغ التقني لأعطال التطبيق فقط. للإبلاغ عن إعلان مشبوه، رسالة مسيئة، أو متجر مخالف على Apolo.ma، افتح قائمة الخيارات (•••) في صفحة الإعلان أو المحادثة واختر «إبلاغ»، أو قدّم بلاغ أمان مباشر الآن.';

  @override
  String get bugReportOpenSafetyAbuseReport =>
      'فتح نموذج الإبلاغ عن الأمان والمحتوى';

  @override
  String get bugReportFoundBugBrokenScreenSend =>
      'واجهت عطلاً أو مشكلة في الشاشة؟ أرسل لنا تقريراً تقنياً مع لقطة شاشة.';

  @override
  String get meetingLobby => 'الاستعداد للاجتماع';

  @override
  String get meetingNewGroupMeeting => 'اجتماع جماعي جديد';

  @override
  String get meetingJoinRoomCode => 'الانضمام برمز الغرفة';

  @override
  String get meetingTitle => 'عنوان الاجتماع';

  @override
  String get meetingEGLivePropertyWalkthrough =>
      'مثال: معاينة جماعية للشقة أو المتجر';

  @override
  String get meetingRoomCodeApoXxxxXxxx => 'أدخل رمز الغرفة (apo-xxxx-xxxx)';

  @override
  String get meetingJoinMeeting => 'انضمام للاجتماع';

  @override
  String get meetingStartMeeting => 'بدء الاجتماع الآن';

  @override
  String get meetingEndEndEncryptionE2ee => 'تشفير تام بين الأطراف (E2EE)';

  @override
  String get meetingSfuForwardsEncryptedPacketsWithout =>
      'خادم الـ SFU يمرر الحزم دون فك تشفير الفيديو أو الصوت أبداً';

  @override
  String get meetingSharedRoomEncryptionKey => 'مفتاح التشفير المشترك للغرفة';

  @override
  String get meetingAdaptiveSfuSvc25Participants =>
      'SFU + SVC متكيف (حتى 25+ مشارك)';

  @override
  String get meetingMicOn => 'الميكروفون مفعل';

  @override
  String get meetingMuted => 'الميكروفون مكتوم';

  @override
  String get meetingCameraOn => 'الكاميرا مفعلة';

  @override
  String get meetingCameraOff => 'الكاميرا متوقفة';

  @override
  String get meetingShareScreen => 'مشاركة الشاشة';

  @override
  String get meetingStopSharing => 'إيقاف المشاركة';

  @override
  String get meetingSpeaker => 'مكبر الصوت';

  @override
  String get meetingFlipCamera => 'تبديل الكاميرا';

  @override
  String get meetingParticipants => 'المشاركون';

  @override
  String get meetingLeave => 'مغادرة';

  @override
  String get meetingEndAll => 'إنهاء للجميع';

  @override
  String get meetingUnstableNetworkAutomaticallyReconnectingVia =>
      'ضعف في الاتصال... جاري إعادة الربط تلقائياً عبر أقرب مسار UDP/TURN';

  @override
  String get meetingLowBandwidthVideoLayersStepped =>
      'الإنترنت ضعيف: تم تخفيض طبقات الفيديو (SVC) لحماية جودة الصوت والبطارية';

  @override
  String get meetingAudioOnly => 'التحويل لصوت فقط';

  @override
  String get meetingResumeVideo => 'استئناف الفيديو';

  @override
  String get meetingDataBatterySaverAudioOnly =>
      'وضع توفير البيانات والبطارية (صوت فقط) مفعل';

  @override
  String get meetingYou => 'أنت';

  @override
  String get meetingHost => 'مضيف';

  @override
  String get meetingCoHost => 'مضيف مساعد';

  @override
  String get meetingLockRoom => 'قفل الغرفة';

  @override
  String get meetingUnlockRoom => 'فتح الغرفة';

  @override
  String get meetingMuteMic => 'كتم الميكروفون';

  @override
  String get meetingRemove => 'إخراج من الاجتماع';

  @override
  String get meetingCopyInviteLink => 'نسخ رابط الدعوة الآمن';

  @override
  String get meetingInviteCopied => 'تم نسخ رمز ومفتاح الاجتماع';

  @override
  String get meetingConnectingSecureSfuMediaRouter =>
      'جاري الاتصال بموزع الفيديو الآمن (SFU)...';

  @override
  String meetingPageCurrentTotal(Object current, Object total) {
    return 'صفحة $current من $total';
  }

  @override
  String get accountSecurityEnterValidEmailAddress =>
      'أدخل بريداً إلكترونياً صالحاً.';

  @override
  String get accountSecurityEnterValidPhoneNumber =>
      'أدخل رقم هاتف مغربي صالح.';

  @override
  String get accountSecurityContactDetailsUpdatedSuccessfully =>
      'تم تحديث بيانات الاتصال بنجاح.';

  @override
  String get accountSecurityPasswordMustBeAtLeast =>
      'كلمة المرور يجب أن تتكون من 8 أحرف على الأقل.';

  @override
  String get accountSecurityPasswordsDoNotMatch =>
      'كلمتا المرور غير متطابقتين.';

  @override
  String get accountSecurityPasswordUpdatedSuccessfully =>
      'تم تحديث كلمة المرور بنجاح.';

  @override
  String get accountSecurityAccountSecurity => 'أمان الحساب';

  @override
  String get accountSecurityStayControlLogin => 'بيانات الدخول تبقى تحت سيطرتك';

  @override
  String get accountSecurityUpdatePasswordEmailPhoneDirectly =>
      'يمكنك تحديث كلمة المرور أو البريد الإلكتروني أو رقم الهاتف مباشرة من التطبيق.';

  @override
  String get accountSecurityContactDetails => 'بيانات الاتصال';

  @override
  String get accountSecurityEmailAddress => 'البريد الإلكتروني';

  @override
  String get accountSecurityPhoneNumber => 'رقم الهاتف';

  @override
  String get accountSecuritySaveContactDetails => 'حفظ بيانات الاتصال';

  @override
  String get accountSecurityChangePassword => 'تغيير كلمة المرور';

  @override
  String get accountSecurityCurrentPassword => 'كلمة المرور الحالية';

  @override
  String get accountSecurityNewPassword => 'كلمة المرور الجديدة';

  @override
  String get accountSecurityConfirmNewPassword => 'تأكيد كلمة المرور الجديدة';

  @override
  String get accountSecurityUpdatePassword => 'تحديث كلمة المرور';

  @override
  String get accountSecuritySecurityOptions => 'إعدادات الأمان';

  @override
  String get accountSecuritySignUpdateThisInformation =>
      'سجّل الدخول في التطبيق لتعديل هذه البيانات';

  @override
  String get accountSetupCreateAccount => 'إنشاء حساب';

  @override
  String get accountSetupAccountType => 'نوع الحساب';

  @override
  String get accountSetupChooseAtLeastOneProfile =>
      'اختر نوع ملف شخصي واحد على الأقل لتخصيص إعداداتك.';

  @override
  String get continueButton => 'متابعة';

  @override
  String get adDetailHiIsThisStillAvailable =>
      'مرحباً، هل هذا الإعلان ما زال متوفراً؟';

  @override
  String get adDetailCouldNotUpdateFavoritesPlease =>
      'تعذر تحديث المفضلة. حاول مرة أخرى.';

  @override
  String get adDetailPhoneNumberCopied => 'تم نسخ رقم الهاتف';

  @override
  String get adDetailCopy => 'نسخ الرقم';

  @override
  String get adDetailCouldNotStartConversationPlease =>
      'تعذر فتح المحادثة. حاول مرة أخرى.';

  @override
  String get adDetailUserBlocked => 'تم حظر هذا المستخدم بنجاح';

  @override
  String get adDetailReportThisListingAiContent =>
      'الإبلاغ عن هذا الإعلان أو محتوى AI';

  @override
  String get adDetailQuickReviewByTrustSafety =>
      'مراجعة فورية من فريق الثقة والأمان';

  @override
  String get adDetailHideAllListingsFromThis => 'إخفاء جميع إعلانات هذا البائع';

  @override
  String get adDetailDetails => 'تفاصيل الإعلان';

  @override
  String get adDetailListingUnavailable => 'الإعلان غير متوفر';

  @override
  String get adDetailThisItemMayHaveBeen =>
      'ربما تم بيع هذا المنتج أو حذفه من طرف البائع.';

  @override
  String get adDetailGoBack => 'العودة';

  @override
  String get adDetailCategory => 'القسم';

  @override
  String get adDetailCondition => 'الحالة';

  @override
  String get adDetailNotSpecified => 'غير محددة';

  @override
  String get adDetailReference => 'رقم الإعلان';

  @override
  String get backButton => 'رجوع';

  @override
  String get adDetailFavorite => 'المفضلة';

  @override
  String get adDetailMore => 'المزيد';

  @override
  String get adDetailFree => 'مجاني';

  @override
  String get adDetailOnRequest => 'عند الطلب';

  @override
  String get negotiableBadge => 'قابل للتفاوض';

  @override
  String get fixedPriceBadge => 'السعر المعلن';

  @override
  String get adDetailGuests => 'ضيوف';

  @override
  String get adDetailBedrooms => 'غرف';

  @override
  String get adDetailBeds => 'أسرّة';

  @override
  String get adDetailBaths => 'حمامات';

  @override
  String get adDetailGood => 'جيد';

  @override
  String get adDetailRef => 'المرجع';

  @override
  String get adDetailViews => 'مشاهدة';

  @override
  String get adDetailGuestFavourite => 'إعلان مميز';

  @override
  String get adDetailVideoTour => 'فيديو الإعلان';

  @override
  String adDetailJustListedMMAgo(Object m) {
    return 'نُشر للتو · منذ $m د';
  }

  @override
  String adDetailJustListedHHoursAgo(Object h) {
    return 'نُشر للتو · منذ $h ساعة';
  }

  @override
  String adDetailDDaysAgo(Object d) {
    return 'منذ $d يوم';
  }

  @override
  String get adDetailJustListed => 'نُشر للتو';

  @override
  String get adDetailBoostThisListing =>
      'ترقية الإعلان ومضاعفة المشاهدات (Boost ⚡)';

  @override
  String get adDetailMessageSeller => 'راسل البائع';

  @override
  String get adDetailFastReply => 'رد سريع';

  @override
  String get adDetailWriteMessage => 'اكتب رسالتك هنا...';

  @override
  String get adDetailAlertsEnabledSimilarListings =>
      'تم تفعيل تنبيهات الإعلانات المشابهة';

  @override
  String get adDetailAlertsPaused => 'تم إيقاف التنبيهات لهذا البحث';

  @override
  String get adDetailAlerts => 'تنبيهات';

  @override
  String get adDetailMessage => 'رسالة';

  @override
  String get shareButton => 'مشاركة';

  @override
  String get saveButton => 'حفظ';

  @override
  String get adDetailNoDescriptionProvidedMessageSeller =>
      'لم يضف البائع وصفاً لهذا الإعلان. تواصل معه لمعرفة التفاصيل.';

  @override
  String get adDetailDescription => 'الوصف';

  @override
  String get adDetailSeeLess => 'عرض أقل';

  @override
  String get adDetailSeeMore => 'قراءة المزيد';

  @override
  String get adDetailCallSeller => 'اتصال هاتفي بالبائع';

  @override
  String adDetailApoloStoreCityname(Object cityName) {
    return 'متجر على Apolo · $cityName';
  }

  @override
  String adDetailApoloSellerCityname(Object cityName) {
    return 'بائع على Apolo · $cityName';
  }

  @override
  String get adDetailBusinessStore => 'المتجر المعلن';

  @override
  String get adDetailSeller => 'البائع';

  @override
  String get adDetailSeeReviews => 'عرض التقييمات';

  @override
  String get followingButton => 'متابَع';

  @override
  String get followButton => 'متابعة';

  @override
  String get adDetailYourRating => 'تقييمك لهذا البائع';

  @override
  String get adDetailRateThisSeller => 'قيّم تجربتك مع البائع';

  @override
  String get adDetailEditReview => 'تعديل تقييمك';

  @override
  String get adDetailWriteReview => 'أضف تقييمك';

  @override
  String get adDetailLocation => 'موقع الإعلان';

  @override
  String adDetailZoneDistkmKm(Object distKm) {
    return 'في منطقتك · $distKm كم';
  }

  @override
  String adDetailDistkmKmAway(Object distKm) {
    return 'يبعد $distKm كم';
  }

  @override
  String get adDetailLocationIsApproximate => 'الموقع تقريبي';

  @override
  String get adDetailFullMap => 'عرض الخريطة';

  @override
  String get adDetailRelatedSearches => 'عمليات بحث ذات صلة';

  @override
  String get adDetailIfYouDonTLike => 'إذا لم يعجبك هذا الإعلان، يمكنك ';

  @override
  String get adDetailHideThisListing => 'إخفاء هذا الإعلان';

  @override
  String get adDetailWeLlShowYouFewer => ' وسنعرض لك إعلانات أقل مشابهة له.';

  @override
  String get adDetailListingHiddenFromFeed => 'تم إخفاء الإعلان من توصياتك';

  @override
  String get adDetailListingRestored => 'تم إلغاء الإخفاء';

  @override
  String get adDetailHidden => 'تم الإخفاء';

  @override
  String get adDetailHideListing => 'إخفاء الإعلان';

  @override
  String get adDetailReportSafety => 'الإبلاغ أو الأمان';

  @override
  String get adDetailSimilarListings => 'إعلانات مشابهة فـ نفس القسم';

  @override
  String get adDetailAllReviews => 'جميع التقييمات';

  @override
  String get adDetailSellerRating => 'تقييم البائع';

  @override
  String get adDetailEditReview2 => 'تعديل تقييمك';

  @override
  String get adDetailWriteReview2 => 'أضف تقييمك';

  @override
  String adDetailSellerReviewsTotalcount(Object totalCount) {
    return 'تقييمات البائع ($totalCount)';
  }

  @override
  String get adDetailShowAll => 'عرض الكل';

  @override
  String get adDetail5Stars => '5 نجوم فقط';

  @override
  String get filtersTitle => 'تصفية';

  @override
  String get adDetailHighest => 'الأعلى تقييماً';

  @override
  String get adDetailSort => 'ترتيب';

  @override
  String adDetailNoWrittenReviewsSellernameYet(Object sellerName) {
    return 'لا توجد تقييمات نصية منشورة لـ $sellerName حالياً';
  }

  @override
  String get adDetailHelpful => 'مفيد';

  @override
  String get addFriendsJoinMeApoloMaMorocco =>
      'انضم إليّ على Apolo.ma — سوق الإعلانات والمتاجر فالمغرب: https://apolo.ma';

  @override
  String get addFriendsAddFriends => 'أضف أصدقاءك';

  @override
  String get addFriendsInvited => 'تمت الدعوة';

  @override
  String get addFriendsInvite => 'دعوة';

  @override
  String get addFriendsContacts => 'جهات الاتصال';

  @override
  String get authUnableOpenGoogleSignRight =>
      'تعذر فتح صفحة الدخول عبر Google حالياً.';

  @override
  String get authUnableStartGoogleSign =>
      'تعذر بدء تسجيل الدخول عبر Google حالياً.';

  @override
  String get authNoEmailAddressIsLinked =>
      'لا يوجد بريد إلكتروني مسجل في هذا الحساب لاستلام رمز التحقق. يرجى استخدام الموقع أو الدعم.';

  @override
  String authVerificationCodeWasSentMasked(Object masked) {
    return 'تم إرسال رمز التحقق إلى بريدك الإلكتروني ($masked).';
  }

  @override
  String get authPleaseEnterValidEmailAddress =>
      'يرجى إدخال بريد إلكتروني صحيح';

  @override
  String get authPasswordMustBeAtLeast =>
      'يجب أن تتكون كلمة المرور من 8 أحرف على الأقل';

  @override
  String get authPleaseEnterNameAtLeast => 'يرجى إدخال الاسم (حرفين على الأقل)';

  @override
  String get authUsernameMustBeAtLeast =>
      'يجب أن يتكون اسم المستخدم من 3 أحرف أو أرقام على الأقل';

  @override
  String get authPleaseEnterValidMoroccanPhone =>
      'يرجى إدخال رقم هاتف مغربي صالح (مثال: 650-123456)';

  @override
  String get authEnter6DigitVerificationCode =>
      'أدخل رمز التحقق المكون من 6 أرقام.';

  @override
  String authNewVerificationCodeWasSent(Object masked) {
    return 'تم إرسال رمز جديد إلى $masked.';
  }

  @override
  String get authNewVerificationCodeWasSent2 =>
      'تم إرسال رمز جديد إلى بريدك الإلكتروني.';

  @override
  String authBasevalueTriedAtHhMm(Object baseValue, Object hh, Object mm) {
    return '$baseValue (آخر محاولة: $hh:$mm)';
  }

  @override
  String get signUpButton => 'إنشاء حساب';

  @override
  String get authEnterEmail => 'أدخل بريدك الإلكتروني';

  @override
  String get authEnterPassword => 'أدخل كلمة المرور';

  @override
  String get authForgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get authWhatSEmail => 'ما هو بريدك الإلكتروني؟';

  @override
  String get authChoosePassword => 'اختر كلمة المرور';

  @override
  String get authWhatSFirstName => 'ما هو اسمك الشخصي؟';

  @override
  String get authPickUsername => 'اختر اسم مستخدم';

  @override
  String get authOthersCanFindYouUsername =>
      'يمكن للآخرين العثور عليك باسم المستخدم الخاص بك!';

  @override
  String get authWhatSPhoneNumber => 'ما هو رقم هاتفك؟';

  @override
  String get authEnterValidMoroccanPhoneNumber =>
      'أدخل رقم هاتف مغربي صالح لتأكيد حسابك';

  @override
  String authWeSent6DigitVerification(Object maskedEmail) {
    return 'أرسلنا رمز تحقق مكوناً من 6 أرقام إلى $maskedEmail';
  }

  @override
  String get authWeSent6DigitVerification2 =>
      'أرسلنا رمز تحقق مكوناً من 6 أرقام إلى بريدك الإلكتروني';

  @override
  String get authEnterVerificationCode => 'أدخل رمز التحقق';

  @override
  String get authSending => 'جاري الإرسال...';

  @override
  String authResendCodeRemainingS(Object remaining) {
    return 'إعادة الإرسال ($remaining ث)';
  }

  @override
  String get businessSwitchWelcomeStoreApoloHowCan =>
      'مرحباً بك في متجرنا على Apolo! كيف يمكننا مساعدتك اليوم؟';

  @override
  String get businessSwitchPleaseEnterStoreNameAt =>
      'يرجى إدخال اسم المتجر أو النشاط التجاري (حرفين على الأقل).';

  @override
  String get businessSwitchPleaseEnterStoreName =>
      'يرجى إدخال اسم المتجر أولاً.';

  @override
  String get businessSwitchBusinessProfileUpdated =>
      'تم حفظ إعدادات متجرك بنجاح!';

  @override
  String get businessSwitchVerifiedBusinessStoreIsNow =>
      'مبروك! تم تفعيل حساب الأعمال (Business) ومتجرك الموثّق بنجاح';

  @override
  String get businessSwitchCouldNotSaveBusinessProfile =>
      'تعذر حفظ إعدادات الأعمال حالياً. تحقق من الاتصال وحاول مجدداً.';

  @override
  String get businessSwitchBusinessSettings => 'إعدادات المتجر والأعمال';

  @override
  String get businessSwitchSwitchBusiness => 'التحويل إلى حساب Business';

  @override
  String get businessSwitchPreviousStoreDetailsAreReady =>
      'وجدنا بيانات متجرك السابق محفوظة! راجعها وفعّل حسابك في ثانية.';

  @override
  String get savingLabel => 'جاري الحفظ...';

  @override
  String get businessSwitchSaveChanges => 'حفظ التعديلات';

  @override
  String get businessSwitchActivateFreeBusiness => 'تفعيل حساب Business مجاناً';

  @override
  String get businessSwitchWhatBestDescribesBusiness =>
      'ما هو مجال نشاطك التجاري؟';

  @override
  String get businessSwitchThisCategoryBadgeAppearsUnder =>
      'ستظهر هذه الفئة تحت اسم متجرك في بروفايلك وفي قسم المتاجر تماماً مثل Instagram.';

  @override
  String get businessSwitchStoreIdentityHoursLocation =>
      'هوية المتجر، أوقات العمل والموقع';

  @override
  String get businessSwitchStoreAppearsStoresDirectoryOnce =>
      'يظهر متجرك تلقائياً في قسم المتاجر بمجرد وجود إعلان واحد نشط على الأقل.';

  @override
  String get businessSwitchStoreName => 'اسم المتجر / النشاط *';

  @override
  String get businessSwitchEGAutoCasa => 'مثال: Auto Luxury Casa';

  @override
  String get businessSwitchBioDescription => 'نبذة قصيرة عن المتجر';

  @override
  String get businessSwitchTellCustomersAboutProductsService =>
      'عرّف الزبناء بجودة سلعك، الضمان، والتوصيل...';

  @override
  String get businessSwitchCityAddress => 'المدينة والعنوان التجاري';

  @override
  String get businessSwitchEGMaarifCasablanca =>
      'مثال: المعاريف، الدار البيضاء';

  @override
  String get businessSwitchGoogleMapsLinkOptional =>
      'رابط المحل على Google Maps (اختياري)';

  @override
  String get businessSwitchWorkingHours => 'أوقات العمل';

  @override
  String get businessSwitchContactDirectOrderTools =>
      'أدوات التواصل والبيع الفوري';

  @override
  String get businessSwitchEnable1TapOrdersAutomatic =>
      'سهّل على الزبناء الطلب من متجرك والرد عليهم بسرعة في الشات.';

  @override
  String get businessSwitchBusinessPhone => 'رقم هاتف المتجر للاتصال المباشر';

  @override
  String get businessSwitchEnableDirectOrderButtonStore =>
      'تفعيل زر \"طلب مباشر\" في المتجر';

  @override
  String get businessSwitchReceiveInstantOrdersCustomerDetails =>
      'يستقبل متجرك طلبيات الزبناء مباشرة مع الاسم والمدينة والهاتف.';

  @override
  String get businessSwitchAutoGreetingMessageChat =>
      'رسالة الترحيب التلقائية في الشات';

  @override
  String get businessSwitchWelcomeStoreHowCanWe =>
      'مرحباً بك في متجرنا! كيف يمكننا مساعدتك؟';

  @override
  String get callIncomingVideoCall => 'مكالمة فيديو واردة...';

  @override
  String get callIncomingVoiceCall => 'مكالمة صوتية واردة...';

  @override
  String get callRinging => 'جاري الرنين...';

  @override
  String get callAllowMicCameraAccess =>
      'يرجى السماح بالوصول للميكروفون/الكاميرا';

  @override
  String get callConnecting => 'جاري الاتصال...';

  @override
  String get callCalls => 'المكالمات';

  @override
  String get callCallsAreUnavailableThisDevice =>
      'المكالمات غير متاحة على هذا الجهاز حالياً';

  @override
  String get callBackChat => 'العودة للمحادثة';

  @override
  String get callVideoCall => 'مكالمة فيديو';

  @override
  String get callVoiceCall => 'مكالمة صوتية';

  @override
  String get callDecline => 'رفض';

  @override
  String get callAccept => 'قبول';

  @override
  String get callMic => 'الميكرو';

  @override
  String get callCamera => 'الكاميرا';

  @override
  String get callEnd => 'إنهاء';

  @override
  String chatListLastMessageLasttime(Object lastTime) {
    return 'آخر رسالة $lastTime';
  }

  @override
  String get chatListUnpinChat => 'إلغاء التثبيت';

  @override
  String get chatListPinChat => 'تثبيت في الأعلى';

  @override
  String get chatListChatUnpinned => 'تم إلغاء تثبيت المحادثة';

  @override
  String get chatListChatPinnedTop => 'تم تثبيت المحادثة في الأعلى';

  @override
  String get chatListMarkAsRead => 'تحديد كمقروء';

  @override
  String get chatListUnmuteNotifications => 'تفعيل الإشعارات';

  @override
  String get chatListMuteNotifications => 'كتم الإشعارات';

  @override
  String get chatListNotificationsUnmuted => 'تم إلغاء كتم الإشعارات';

  @override
  String get chatListChatMuted => 'تم كتم إشعارات المحادثة';

  @override
  String get chatListArchiveChat => 'نقل إلى الأرشيف';

  @override
  String get chatListChatArchived => 'تم نقل المحادثة إلى الأرشيف';

  @override
  String get chatListReportChat => 'الإبلاغ عن المحادثة';

  @override
  String chatListBlockPeername(Object peerName) {
    return 'حظر $peerName';
  }

  @override
  String chatListBlockedPeername(Object peerName) {
    return 'تم حظر $peerName';
  }

  @override
  String get chatListDeleteChat => 'حذف المحادثة';

  @override
  String get chatListChatDeleted => 'تم حذف المحادثة';

  @override
  String get chatListSelectConversationStartMessaging =>
      'حدد محادثة لبدء المراسلة';

  @override
  String get chatListChats => 'المحادثات';

  @override
  String get chatListMarkAllRead => 'قراءة الكل';

  @override
  String get searchTitle => 'بحث';

  @override
  String get chatListAll => 'الكل';

  @override
  String get chatListUnread => 'غير مقروءة';

  @override
  String get chatListPinned => 'المثبتة';

  @override
  String get chatListSignViewChats => 'سجّل الدخول لعرض محادثاتك';

  @override
  String get chatListMessageBuyersSellersDirectlySecurely =>
      'تواصل مباشرة مع البائعين والمشترين وتابع رسائلك بأمان.';

  @override
  String get signInButton => 'تسجيل الدخول';

  @override
  String get chatListNoUnreadChats => 'لا توجد رسائل غير مقروءة';

  @override
  String get chatListNoPinnedChats => 'لا توجد محادثات مثبتة';

  @override
  String get chatListNoChatsYet => 'لا توجد محادثات بعد';

  @override
  String get chatListBrowseListingsMessageSellersDirectly =>
      'تصفح الإعلانات وتواصل مع البائعين مباشرة بأمان تام.';

  @override
  String get chatListExploreListings => 'تصفح الإعلانات';

  @override
  String get chatListPersonalMessagesAreEndEnd =>
      'رسائلك الشخصية مشفرة تماماً بين الطرفين';

  @override
  String get chatRoomFailedLoadMessagesPleaseTry =>
      'تعذر تحميل الرسائل. حاول مجدداً.';

  @override
  String get chatRoomMessageEdited => 'تم تعديل الرسالة';

  @override
  String get chatRoomDeletedEveryone => 'تم حذف الرسالة لدى الجميع';

  @override
  String get chatRoomMessagePinned => 'تم تثبيت الرسالة';

  @override
  String get chatRoomMessageUnpinned => 'تم إلغاء التثبيت';

  @override
  String get chatRoomMessageStarred => 'تم تمييز الرسالة بنجمة ⭐';

  @override
  String get chatRoomStarRemoved => 'تمت إزالة النجمة';

  @override
  String get chatRoomReportConversation => 'الإبلاغ عن المحادثة';

  @override
  String get chatRoomUserUnblocked => 'تم إلغاء الحظر';

  @override
  String chatRoomUnblockPeername(Object peerName) {
    return 'إلغاء حظر $peerName';
  }

  @override
  String get chatRoomReply => 'رد';

  @override
  String get chatRoomUnpin => 'إلغاء التثبيت';

  @override
  String get chatRoomPin => 'تثبيت';

  @override
  String get chatRoomUnstar => 'إزالة النجمة';

  @override
  String get chatRoomStar => 'تمييز بنجمة';

  @override
  String get chatRoomCopied => 'تم النسخ';

  @override
  String get editButton => 'تعديل الرسالة';

  @override
  String get reportButton => 'إبلاغ';

  @override
  String get deleteButton => 'حذف لدي فقط';

  @override
  String get chatRoomDeleteEveryone => 'حذف لدى الجميع';

  @override
  String get chatRoomMorocco => 'المغرب';

  @override
  String chatRoomMyLocationResolvedcity(Object resolvedCity) {
    return '📍 موقعي الحالي: $resolvedCity';
  }

  @override
  String chatRoomPriceOfferTitleDhCleaned(Object title, Object cleaned) {
    return '💰 عرض ثمن على \"$title\": $cleaned DH';
  }

  @override
  String chatRoomPriceOfferDhCleaned(Object cleaned) {
    return '💰 عرض ثمن: $cleaned DH';
  }

  @override
  String get chatRoomCouldNotCaptureAudioPlease =>
      'تعذر حفظ التسجيل الصوتي. تأكد من السماح للميكروفون وجرب مرة أخرى.';

  @override
  String get chatRoomVoiceMessageIsTooLong =>
      'الرسالة الصوتية طويلة جداً. حاول تسجيل رسالة أقصر.';

  @override
  String get chatRoomThisMessageWasDeleted => 'تم حذف هذه الرسالة';

  @override
  String get chatRoomRead => 'تمت القراءة';

  @override
  String get chatRoomDelivered => 'تم التسليم';

  @override
  String chatRoomLastSeenClock(Object clock) {
    return 'آخر ظهور $clock';
  }

  @override
  String get chatRoomOffline => 'غير متصل';

  @override
  String get chatRoomVideoCallUnavailable => 'مكالمة فيديو — غير متاحة';

  @override
  String get chatRoomVoiceCallUnavailable => 'مكالمة صوتية — غير متاحة';

  @override
  String get chatRoomSafetyReport => 'الأمان والتبليغ';

  @override
  String get chatRoomYouBlockedThisUser => 'لقد قمت بحظر هذا المستخدم';

  @override
  String get chatRoomUnblock => 'إلغاء الحظر';

  @override
  String get chatRoomEditingMessage => 'تعديل الرسالة';

  @override
  String get chatRoomSendMessage => 'أكتب رسالة...';

  @override
  String get editProfileMinimum3CharactersRequired =>
      'يجب أن يكون 3 أحرف على الأقل';

  @override
  String editProfileCleanIsAvailable(Object clean) {
    return 'اسم المستخدم @$clean متاح';
  }

  @override
  String get editProfileAlreadyTaken => 'اسم المستخدم محجوز بالفعل.';

  @override
  String get editProfileProfilePhoto => 'صورة الملف الشخصي';

  @override
  String get editProfileChooseFromLibrary => 'اختيار من المعرض';

  @override
  String get editProfileTakePhoto => 'التقاط صورة جديدة';

  @override
  String get editProfileRemoveCurrentPhoto => 'حذف الصورة الحالية';

  @override
  String get editProfileChoosePresetAvatar => 'أو اختر أفاتار سريع';

  @override
  String get editProfileSelectCity => 'اختر مدينتك';

  @override
  String get clearButton => 'مسح';

  @override
  String get editProfilePhoneWhatsapp => 'رقم الهاتف والواتساب';

  @override
  String get confirmButton => 'تأكيد الرقم';

  @override
  String get editProfileNameIsRequired => 'الاسم مطلوب.';

  @override
  String get editProfileUsernameMustBeAtLeast =>
      'اسم المستخدم يجب أن يكون 3 أحرف على الأقل.';

  @override
  String get editProfileThisUsernameIsAlreadyTaken =>
      'اسم المستخدم هذا محجوز بالفعل، اختر اسماً آخر.';

  @override
  String get editProfileCouldNotSaveChangesPlease =>
      'تعذر حفظ التغييرات. حاول مجدداً.';

  @override
  String get editProfileTitle => 'تعديل الملف الشخصي';

  @override
  String get editProfileEditPicture => 'تغيير الصورة';

  @override
  String get editProfileFullName => 'اسمك الكامل';

  @override
  String get editProfileUsername => 'اسم المستخدم';

  @override
  String get editProfileBio => 'النبذة التعريفية';

  @override
  String get editProfileWriteShortBioAboutYourself =>
      'عرّف بنفسك أو بما تبيعه باختصار...';

  @override
  String get editProfileAddCity => 'إضافة مدينة';

  @override
  String get editProfilePhone => 'الهاتف';

  @override
  String get editProfileAddPhoneNumber => 'إضافة رقم الهاتف';

  @override
  String get editProfileManageStoreDetails => 'إعدادات المتجر وساعات العمل';

  @override
  String get editProfileGetVerifiedBusinessStore =>
      'تفعيل التوثيق ومتجر Business';

  @override
  String get editProfilePersonalInformation => 'المعلومات الشخصية';

  @override
  String get editProfileEmailPasswordSettings =>
      'البريد الإلكتروني وكلمة المرور';

  @override
  String get saveChangesButton => 'حفظ التغييرات';

  @override
  String forgotPasswordWeSent6DigitVerification(Object masked) {
    return 'أرسلنا رمز تحقق مكوناً من 6 أرقام إلى $masked.';
  }

  @override
  String get forgotPasswordPleaseEnter6DigitVerification =>
      'يرجى إدخال رمز التحقق المكون من 6 أرقام.';

  @override
  String get forgotPasswordPasswordUpdatedSignedSuccessfully =>
      'تم تحديث كلمة المرور وتسجيل الدخول بنجاح!';

  @override
  String get forgotPasswordYouWillReceiveEmailSet =>
      'ستتوصل برسالة في بريدك الإلكتروني لتعيين كلمة مرور جديدة';

  @override
  String get forgotPasswordChooseNewPassword => 'اختر كلمة مرور جديدة';

  @override
  String get homeInternetConnectionLost => 'انقطع الاتصال بالإنترنت';

  @override
  String get homeCheckNetworkConnectionTryAgain =>
      'تحقق من الشبكة وحاول مرة أخرى لعرض أحدث العروض والإعلانات في المغرب.';

  @override
  String get tryAgainButton => 'إعادة المحاولة';

  @override
  String get homeWelcomeApolo => 'مرحباً بك في Apolo';

  @override
  String get homeSearchCarsHomesPhonesAccounts =>
      'ابحث عن سيارات، عقارات، هواتف أو حسابات...';

  @override
  String get homeLatestListings => 'أحدث الإعلانات';

  @override
  String get homeSeeAll => 'عرض الكل';

  @override
  String homeNoListingsWithinZoneradiuskmKm(Object zoneRadiusKm, Object s) {
    return 'لا توجد إعلانات في نطاق $zoneRadiusKm كم من $s حالياً';
  }

  @override
  String get homeShowAllMorocco => 'عرض كل المغرب';

  @override
  String get homeChangeZone => 'تغيير المنطقة';

  @override
  String get homeBrowseAllListingsMorocco => 'تصفح الإعلانات في المغرب';

  @override
  String get home1MarketplaceMorocco => 'سوقك الأول فالمغرب 🇲🇦';

  @override
  String get homeBuySellSafelyWithoutMiddlemen => 'بيع واشري بأمان وبلا وسيط';

  @override
  String get homeCarsPhonesRealEstateDiscover =>
      'طوموبيلات، هواتف وعقارات. اكتشف الإعلانات القريبة منك.';

  @override
  String get homeExclusiveDeals => 'عروض حصرية مميزة';

  @override
  String get homeWhyChooseApolo => 'علاش تختار Apolo؟';

  @override
  String get home0CommissionFree => '0% عمولة وبالمجان';

  @override
  String get homeBuySellFreeZeroMiddlemen =>
      'بيع وشري فابور بدون أي اقتطاعات أو وسطاء.';

  @override
  String get homeDirectChatCall => 'شات واتصال مباشر';

  @override
  String get homeMessageSellerDirectlyMakeOffer =>
      'تواصل فالحين مع البائع وقدم عرض سعر بضغطة وحدة.';

  @override
  String get homeVerifiedListings => 'إعلانات مفحوصة وموثقة';

  @override
  String get homeContinuousReviewKeepAllTransactions =>
      'فحص مستمر للإعلانات لحماية جميع المعاملات.';

  @override
  String get homeGotSomethingSellPostNow => 'عندك ما تبيع؟ انشر إعلانك دابا';

  @override
  String get homePublishFree30SecondsGet =>
      'انشر فـ 30 ثانية بالمجان وتوصل باتصالات المشترين';

  @override
  String get homePost => 'نشر +';

  @override
  String get homeVerifiedOfficialStores => 'المتاجر الرسمية الموثقة';

  @override
  String get homeBrowseDealsFromCertifiedStores =>
      'تصفح عروض الوكالات والمتاجر المعتمدة في المغرب';

  @override
  String get intentOnboardingWhatWillYouUseApolo => 'فاش غادي تستعمل\nApolo؟';

  @override
  String get mainShellYouHaveNewApoloNotification => 'لديك إشعار جديد في Apolo';

  @override
  String get mainShellBrowse => 'إعلانات';

  @override
  String get notificationsEnableNotifications => 'تفعيل الإشعارات';

  @override
  String get notificationsAreBlocked => 'الإشعارات غير مفعّلة على الجهاز';

  @override
  String get notificationsPleaseEnableNotificationsPhoneBrowser =>
      'يرجى تفعيل الإشعارات من إعدادات التطبيق في الهاتف أو أيقونة القفل في المتصفح ثم الضغط على \"متابعة\" مرة أخرى.';

  @override
  String get notificationsGotIt => 'حسناً، فهمت';

  @override
  String get notificationsNotificationPreferences => 'إعدادات التنبيهات';

  @override
  String get notificationsChooseWhichApoloAlertsYou =>
      'اختر التنبيهات التي تهمك على Apolo';

  @override
  String get notificationsMessagesBuyerOffers => 'رسائل وعروض المشترين';

  @override
  String get notificationsInstantAlertWhenBuyerMessages =>
      'تنبيه فوري عند وصول رسالة أو عرض سعر';

  @override
  String get notificationsPriceDropsSavedListings =>
      'تخفيضات الأسعار والمحفوظات';

  @override
  String get notificationsUpdatesListingsYouBookmarked =>
      'إشعارات الإعلانات التي حفظتها في المفضلة';

  @override
  String get notificationsOfficialStoresUpdates => 'تحديثات المتاجر الرسمية';

  @override
  String get notificationsNewArrivalsFromVerifiedSellers =>
      'جديد المتاجر الموثقة التي تتابعها';

  @override
  String get notificationsMarkAllAsRead => 'تحديد الكل كمقروء';

  @override
  String get doneButton => 'تم';

  @override
  String get notificationsPleaseAllowNotificationsContinue =>
      'يرجى الضغط على \"سماح / Allow\" لتفعيل الإشعارات';

  @override
  String get notificationsActivatedInstantAlerts =>
      ' قمت بتفعيل التنبيهات الفورية لـ ';

  @override
  String get notificationsApoloMaBuyerMessagesOffers =>
      'Apolo.ma — الرسائل والعروض';

  @override
  String get notificationsJustNow => 'الآن';

  @override
  String get notificationsApoloTeam => 'فريق Apolo';

  @override
  String get notificationsSharedTipAddClearPhotos =>
      ' شارك معك نصيحة: أضف صوراً واضحة وثمناً مناسباً لبيع إعلانك بسرعة.';

  @override
  String get notifications2hAgo => 'اليوم';

  @override
  String get notificationsApoloOfficialStores => 'متاجر Apolo الرسمية';

  @override
  String get notificationsUpdated => ' قامت بتحديث ';

  @override
  String get notificationsVerifiedCarsRealEstateTech =>
      'عروض السيارات، العقارات والإلكترونيات الموثقة';

  @override
  String get notificationsAcrossAllMoroccanCities => ' في جميع مدن المغرب.';

  @override
  String get notificationsThisWeek => 'هذا الأسبوع';

  @override
  String get notificationsNotifications => 'الإشعارات';

  @override
  String get notificationsHeyItSApolo => 'مرحباً، معك Apolo!';

  @override
  String get notificationsIAmReadyHelpYou =>
      'أنا جاهز لتنبيهك فور وصول رسائل وعروض المشترين. ماذا عنك؟';

  @override
  String get notificationsNow => 'الآن';

  @override
  String get notificationsNotification => 'الإشعارات';

  @override
  String get notificationsActivateNotificationsReceiveMessages =>
      'فعّل الإشعارات للتوصل بالرسائل';

  @override
  String get notificationsUpdates => 'التحديثات';

  @override
  String get notificationsNoNotificationsThisCategory =>
      'لا توجد إشعارات في هذا القسم';

  @override
  String get notificationsBuyerMessagesOffersListingUpdates =>
      'ستظهر هنا رسائل وعروض المشترين وتحديثات الإعلانات فور وصولها.';

  @override
  String get notificationsNoInternetConnection => 'لا يوجد اتصال بالإنترنت';

  @override
  String get notificationsCheckWiFiMobileData =>
      'تأكد من اتصالك بشبكة Wi-Fi أو بيانات الهاتف لتحميل آخر الإشعارات والرسائل.';

  @override
  String get notificationsToday => 'اليوم';

  @override
  String get postAdCouldNotDetectGpsLocation =>
      'تعذر تحديد موقعك تلقائياً — اختر المدينة من القائمة';

  @override
  String get postAdPleaseSelectCategoryCity =>
      'يرجى اختيار القسم والمدينة للمتابعة';

  @override
  String get postAdAddAtLeastOnePhoto => 'أضف صورة واحدة على الأقل لإعلانك';

  @override
  String get postAdEnterClearTitleAtLeast =>
      'أدخل عنواناً واضحاً للإعلان (3 أحرف على الأقل)';

  @override
  String get postAdEnterValidPriceFreeVerify =>
      'حدد ثمناً صحيحاً أو اختر مجاني، وتحقق من رقم الهاتف';

  @override
  String postAdDailyFreeLimitReachedMaxdailyfreeads(Object maxDailyFreeAds) {
    return 'وصلت للحد اليومي المجاني ($maxDailyFreeAds إعلانات فـ النهار)';
  }

  @override
  String postAdPersonalAccountsIncludeUpMaxdailyfreeads(
      Object maxDailyFreeAds, Object monthlyPremiumPriceMad) {
    return 'الحساب العادي (Personal) يسمح بنشر حتى $maxDailyFreeAds إعلانات مجانية كل يوم. اشترك فـ Apolo Premium بـ $monthlyPremiumPriceMad د.م/شهر عبر Google Pay للنشر بلا حدود والحصول على متجر Business وشارة Verified.';
  }

  @override
  String postAdSubscribeMonthlypremiumpricemadMadMoGoogle(
      Object monthlyPremiumPriceMad) {
    return 'اشترك بـ $monthlyPremiumPriceMad د.م/شهر • Google Pay';
  }

  @override
  String get postAdMaybeLater => 'حسناً، غداً';

  @override
  String get postAdPleaseSignPublishListing =>
      'يجب تسجيل الدخول أولاً لتتمكن من نشر إعلانك على المنصة';

  @override
  String get postAdAvailableGreatConditionApolo =>
      'متوفر بحالة ممتازة على أبولو';

  @override
  String get postAdFailedPublishListing =>
      'تعذر نشر الإعلان، يرجى التأكد من البيانات والمحاولة مجدداً';

  @override
  String get postAdCategoriesCitiesUnavailableRetry =>
      'تعذر تحميل الأقسام والمدن. أعد المحاولة';

  @override
  String get postAdUnlimitedDailyAdsApoloPremium =>
      'نشر غير محدود يومياً · Apolo Premium';

  @override
  String postAdMaxdailyfreeadsMaxdailyfreeads2DailyLimitReached(
      Object maxDailyFreeAds,
      Object maxDailyFreeAds2,
      Object monthlyPremiumPriceMad) {
    return 'وصلت لـ $maxDailyFreeAds/$maxDailyFreeAds2 إعلانات اليوم · ترقية بـ $monthlyPremiumPriceMad د.م';
  }

  @override
  String postAdTodayTodaypostedadscountMaxdailyfreeadsFreeAds(
      Object todayPostedAdsCount, Object maxDailyFreeAds) {
    return 'الحد المجاني اليوم: $todayPostedAdsCount/$maxDailyFreeAds إعلانات · غير محدود مع Premium';
  }

  @override
  String get postAdWhereAreYouListing => 'فين بغيتي تحط إعلانك؟';

  @override
  String get postAdChooseCategoryCitySoNearby =>
      'اختر القسم المناسب والمدينة باش المشترين القراب ليك يلقاوه بسهولة';

  @override
  String get postAdAddClearPhotos => 'أضف صور واضحة لإعلانك';

  @override
  String get postAdListingsRealClearPhotosSell =>
      'الإعلانات اللي فيها صور حقيقية وواضحة كتتباع أسرع بـ 3 مرات';

  @override
  String get postAdDescribeItem => 'شنو كتبيع؟ عطيه عنوان قوي';

  @override
  String get postAdClearTitleHonestDescriptionBuild =>
      'اكتب الماركة، الموديل، والحالة باش تجاوب على أسئلة المشتري';

  @override
  String get postAdSetPriceContact => 'حدد الثمن وطريقة التواصل';

  @override
  String get postAdSetFairPriceReviewListing =>
      'حدد ثمن مناسب للسوق وراجع معاينة الإعلان قبل النشر';

  @override
  String get postAdGpsLocationSet => 'تم تحديد موقع الإعلان (GPS)';

  @override
  String get postAdDetectAdLocationGps => 'تحديد موقع الإعلان بـ GPS';

  @override
  String get postAdTapAddPhotos => 'اضغط لإضافة صور الإعلان';

  @override
  String postAdAddMorePhotosTotalphotos8(Object totalPhotos) {
    return 'إضافة المزيد من الصور ($totalPhotos/8)';
  }

  @override
  String get postAdFirstPhotoWillBeUsed =>
      'الصورة الأولى غادي تكون هي صورة الغلاف الرئيسية';

  @override
  String get postAdGallery => 'المعرض';

  @override
  String get postAdSelectedPhotos => 'الصور المختارة';

  @override
  String get postAdCover => 'الغلاف';

  @override
  String get postAdListingTitle => 'عنوان الإعلان';

  @override
  String get postAdGreat => 'ممتاز ✓';

  @override
  String get postAdEGIphone15Pro =>
      'مثال: iPhone 15 Pro Max 256GB بحالة الجديد';

  @override
  String get postAdDetailedDescription => 'الوصف التفصيلي';

  @override
  String get postAdMentionConditionIncludedAccessoriesKey =>
      'اذكر الحالة، الملحقات، وسبب البيع لزيادة ثقة المشترين...';

  @override
  String get postAdSpecifications => 'مواصفات إضافية';

  @override
  String get postAdPriceMad => 'الثمن (بالدرهم)';

  @override
  String get postAdEG2500 => 'أدخل الثمن بالدرهم';

  @override
  String get postAdHideNumber => 'إخفاء الرقم (شات فقط)';

  @override
  String get postAdListingPreview => 'معاينة الإعلان قبل النشر';

  @override
  String get postAdPublishNow => 'نشر الإعلان الآن';

  @override
  String get postAdListingUpdated => 'تم تحديث إعلانك بنجاح';

  @override
  String get postAdListingIsLive => 'مبروك! تم نشر إعلانك بنجاح';

  @override
  String get postAdListingIsNowVisibleBuyers =>
      'إعلانك دابا واجد وغادي يبان لآلاف المشترين فـ Apolo.ma.';

  @override
  String get postAdNewListing => 'إعلانك الجديد';

  @override
  String get postAdBackHome => 'العودة للرئيسية';

  @override
  String get postAdPostAnotherListing => 'إضافة إعلان آخر';

  @override
  String get privacyComplianceReportAiPolicyIssue =>
      'الإبلاغ عن محتوى أو مخالفة';

  @override
  String get privacyComplianceSelectReasonSubmitThisReport =>
      'نلتزم بسلامة المحتوى وفق معايير App Store و Google Play. اختر سبب البلاغ للمراجعة الفورية:';

  @override
  String get privacyComplianceAdditionalDetailsOptional =>
      'أضف تفاصيل إضافية (اختياري)...';

  @override
  String get privacyComplianceSubmitReport => 'إرسال البلاغ الآن';

  @override
  String get privacyComplianceCouldNotSendReportPlease =>
      'تعذر إرسال البلاغ. حاول مجدداً.';

  @override
  String get privacyComplianceReportSubmittedSuccessfully =>
      'تم إرسال بلاغك بنجاح داخل التطبيق ✓';

  @override
  String privacyComplianceLinkCopiedUrl(Object url) {
    return 'تم نسخ الرابط: $url';
  }

  @override
  String get privacyComplianceConfirmAccountDeletion =>
      'تأكيد حذف الحساب نهائياً';

  @override
  String get privacyComplianceAreYouSureYouWant =>
      'هل أنت متأكد من حذف حسابك وجميع بياناتك الشخصية وإعلاناتك ومحادثاتك نهائياً من خوادم Apolo.ma؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get cancelButton => 'إلغاء';

  @override
  String get privacyComplianceDeletePermanently => 'حذف حسابي وبياناتي';

  @override
  String get privacyComplianceAccountDataHaveBeenDeleted =>
      'تم حذف الحساب والبيانات بنجاح.';

  @override
  String get privacyComplianceCouldNotConfirmDeletionYou =>
      'تعذر تأكيد حذف الحساب. لم يتم تسجيل خروجك. حاول مجدداً.';

  @override
  String get privacyCompliancePrivacyPolicies => 'الخصوصية والشروط';

  @override
  String get privacyCompliancePrivacy => 'الخصوصية';

  @override
  String get privacyCompliancePolicies => 'الشروط والسياسات';

  @override
  String get privacyComplianceDataDelete => 'حذف البيانات';

  @override
  String get privacyComplianceUpdated2026Law0908 =>
      'محدث 2026 · القانون 09-08 (CNDP)';

  @override
  String get privacyCompliancePrivacyFullyControl =>
      'خصوصيتك وبياناتك تحت تحكمك الكامل';

  @override
  String get privacyComplianceWeNeverSellPersonalData =>
      'لا نبيع بياناتك الشخصية لأي طرف إعلاني خارجي. تُستخدم المعلومات حصرياً لتشغيل حسابك، إعلاناتك، محادثاتك، وإشعارات الهاتف على تطبيق Apolo (ma.apolo.apoloMobile).';

  @override
  String get privacyComplianceDataWeCollect => 'البيانات التي نجمعها';

  @override
  String get privacyComplianceAccountIdentityNameEmailPhone =>
      '• الهوية والحساب: الاسم، البريد الإلكتروني، رقم الهاتف، أو مصادقة Google / Apple الآمنة.\n• الإعلانات والمتاجر: الصور، العناوين، الأوصاف، الأسعار بالدرهم، والمدينة المختارة.\n• المحادثات الفورية: الرسائل النصية، الصور، والتفاعلات المتبادلة بين البائع والمشتري.\n• رموز إشعارات الهاتف (FCM / APNs): لإيصال تنبيهات الرسائل والمكالمات إلى هاتفك، ويتم تعطيلها تلقائياً عند تسجيل الخروج.';

  @override
  String get privacyComplianceDevicePermissionsControls =>
      'أذونات الهاتف والتحكم بها';

  @override
  String get privacyComplianceNotificationsOptionalOsAlertsNew =>
      '• الإشعارات: اختيارية لتلقي تنبيهات الرسائل الفورية على iOS و Android ويمكن إيقافها في أي وقت.\n• الكاميرا والمعرض: تُطلب فقط عندما تختار رفع صورة لإعلانك أو إرسال صورة في المحادثة.\n• الموقع التقريبي: يُستخدم لعرض الإعلانات القريبة من مدينتك دون تتبع موقعك في الخلفية.';

  @override
  String get privacyComplianceAiSafetyAppReporting =>
      'سلامة الذكاء الاصطناعي والإبلاغ الفوري';

  @override
  String get privacyComplianceSmartListingSearchToolsInclude =>
      'يوفر التطبيق أدوات مساعدة ذكية لتنظيم الإعلانات والبحث، ويتيح زر إبلاغ فوري داخل التطبيق لمراجعة أي محتوى غير دقيق أو مخالف دون مغادرة التطبيق.';

  @override
  String get privacyComplianceLegalRightsContact =>
      'حقوقك القانونية والتواصل معنا';

  @override
  String get privacyComplianceUnderMoroccanLaw0908 =>
      'وفقاً للقانون المغربي 09-08 ومعايير App Store و Google Play، يحق لك الاطلاع على بياناتك، تصحيحها، حظر المستخدمين المزعجين، أو حذف حسابك نهائياً.\n• البريد الرسمي: support@apolo.ma / contact@apolo.ma\n• الموقع الرسمي: https://apolo.ma';

  @override
  String get privacyComplianceReportAiPolicyIssueApp =>
      'الإبلاغ عن محتوى أو مخالفة داخل التطبيق';

  @override
  String get privacyComplianceOpenWebPrivacyPolicy =>
      'فتح سياسة الخصوصية على الويب';

  @override
  String get privacyComplianceTermsUseMarketplaceRules =>
      'شروط الاستخدام وسياسات البيع 2026';

  @override
  String get privacyComplianceClearRulesSafeBuyingSelling =>
      'قواعد واضحة لبيع وشراء آمن بالمغرب';

  @override
  String get privacyComplianceByUsingApoloYouAgree =>
      'باستخدامك لتطبيق Apolo.ma، فإنك توافق على شروط النشر، قواعد المحادثة الآمنة، وسياسات التوثيق والرتب.';

  @override
  String get privacyComplianceAccountIntegrityVerifiedBadges =>
      'الأهلية ومصداقية الحساب والشارات';

  @override
  String get privacyComplianceAccountStoreDetailsMustRemain =>
      '• يجب أن تكون معلومات الحساب والمتجر حقيقية ومحدثة.\n• شارة التوثيق الزرقاء ورتب البائعين (Bronze إلى Champion) تُمنح حصرياً عبر نظام Apolo الرسمي ويُمنع انتحال صفة المتاجر أو الإدارة.';

  @override
  String get privacyComplianceListingRulesProhibitedItems =>
      'سياسة نشر الإعلانات والسلع الممنوعة';

  @override
  String get privacyComplianceListingsMustRepresentRealItems =>
      '• يجب أن يعكس الإعلان منتجاً أو خدمة حقيقية بصور واضحة وسعر صادق.\n• يُمنع منعاً كلياً نشر السلع المقلدة، الأسلحة، المواد غير القانونية أو الطبية الخاضعة للوصفة، الوثائق الرسمية، أو الإعلانات الوهمية.';

  @override
  String get privacyComplianceSafeTransactionsChatConduct =>
      'المعاملات الآمنة وآداب الدردشة';

  @override
  String get privacyComplianceAlwaysInspectItemsPersonSafe =>
      '• ننصح دائماً بالمعاينة المباشرة في مكان عمومي وعدم إرسال أي تسبيق مالي قبل استلام المنتج.\n• يُمنع الإزعاج، الرسائل العشوائية (Spam)، أو الإساءة في الدردشة؛ يمكنك حظر أي مستخدم أو الإبلاغ عنه بضغطة واحدة.';

  @override
  String get privacyComplianceProSubscriptionsListingBoosts =>
      'اشتراكات Pro+ وترقية الإعلانات (Boost)';

  @override
  String get privacyComplianceProPlansBoostUpgradesAre =>
      '• تتم فوترة باقات Pro+ ومزايا الترويج بوضوح عبر حساب متجرك (App Store / Google Play).\n• يمكنك إدارة أو إلغاء التجديد التلقائي في أي وقت قبل 24 ساعة من انتهاء الفترة الحالية من إعدادات المتجر.';

  @override
  String get privacyComplianceOpenWebTermsPolicies =>
      'فتح الشروط والأحكام الكاملة على الويب';

  @override
  String get privacyComplianceInstantErasureAppStorePlay =>
      'حذف فوري · App Store & Google Play';

  @override
  String get privacyCompliancePermanentAccountDataDeletion =>
      'حذف الحساب والبيانات الشخصية نهائياً';

  @override
  String get privacyComplianceEraseAccountAllAssociatedPersonal =>
      'يمكنك مسح حسابك وكافة بياناتك مباشرة من داخل التطبيق بضغطة واحدة، أو تقديم طلب عبر الرابط الخارجي دون تسجيل الدخول.';

  @override
  String get privacyComplianceWhatGetsPermanentlyDeleted =>
      'ما الذي يتم حذفه فوراً؟';

  @override
  String get privacyComplianceProfileCredentialsNameEmailPhone =>
      '• معلومات الملف الشخصي (الاسم، البريد الإلكتروني، رقم الهاتف، وربط Google / Apple).\n• جميع الإعلانات المنشورة، الصور، وبيانات المتجر.\n• سجل المحادثات والرسائل، قائمة المفضلة، ورموز إشعارات الهاتف (Push Tokens).';

  @override
  String get privacyComplianceDeleteMyAccountNowApp =>
      'حذف حسابي وجميع بياناتي الآن (داخل التطبيق)';

  @override
  String get privacyComplianceSignDeleteAccountDirectlyApp =>
      'سجّل الدخول لحذف حسابك مباشرة من التطبيق، أو استخدم رابط الحذف الخارجي أدناه.';

  @override
  String get privacyComplianceExternalWebDataDeletionLink =>
      'رابط حذف الحساب والبيانات على الويب';

  @override
  String get proPlusRecurringBillingCancelAnytimePayment =>
      'فوترة متكررة، يمكنك الإلغاء في أي وقت. يتم خصم الدفعة عبر حساب Google Pay / المتجر عند تأكيد الشراء، ويتجدد الاشتراك تلقائياً ما لم يتم إلغاؤه قبل 24 ساعة على الأقل من نهاية الفترة الحالية.\nتخضع جميع البيانات لـ ';

  @override
  String get proPlusTermsConditions => 'الشروط والأحكام';

  @override
  String get proPlusAnd => ' و';

  @override
  String get proPlusPrivacyPolicy => 'سياسة الخصوصية';

  @override
  String get proPlusSubscription => 'الاشتراك';

  @override
  String get proPlusCancelPremiumSubscription => 'إلغاء اشتراك Pro Plus؟';

  @override
  String get proPlusAutoRenewalWillBeTurned =>
      'سيتوقف التجديد التلقائي لباقة Pro Plus مع الاحتفاظ ببيانات متجرك وإعلاناتك.';

  @override
  String get proPlusCancelMySubscription => 'نعم، إلغاء اشتراكي';

  @override
  String get proPlusKeepPremium => 'الاحتفاظ بالاشتراك';

  @override
  String get proPlusYouUsePremium => 'أنت تستخدم Pro Plus';

  @override
  String get proPlusGetPremium => 'احصل على Pro Plus';

  @override
  String get proPlusYouHaveUnlimitedAccessAll =>
      'لديك وصول غير محدود لجميع مزايا Pro Plus الحصرية';

  @override
  String get proPlusGetUnlimitedAccessAllPremium =>
      'احصل على وصول غير محدود لجميع مزايا Pro Plus الحصرية';

  @override
  String get proPlusCheckedAccountActivePurchases =>
      'تم التحقق من سجل مشترياتك على المتجر.';

  @override
  String get proPlusHowTrialWorks => 'كيف تعمل فترتك التجريبية';

  @override
  String proPlusUnlimitedFreeAccess3Days(Object monthlyPremiumPriceMad) {
    return 'وصول مجاني غير محدود لمدة 3 أيام، ثم $monthlyPremiumPriceMad د.م فقط في الشهر عبر Google Pay';
  }

  @override
  String get proPlusGetInstantAccessSeeHow =>
      'احصل على وصول فوري لشارة التوثيق PRO+ وتمويل إعلاناتك واكتشف الفرق.';

  @override
  String get proPlusDay2 => 'اليوم 2';

  @override
  String get proPlusWeLlRemindYouNotification =>
      'سنذكّرك عبر إشعار قبل انتهاء فترتك التجريبية المجانية.';

  @override
  String get proPlusDay3 => 'اليوم 3';

  @override
  String get proPlusYouLlBeChargedDay =>
      'يتم تفعيل الاشتراك في اليوم الثالث، ويمكنك الإلغاء في أي وقت قبله.';

  @override
  String get proPlusViewAllPlans => 'عرض جميع الباقات';

  @override
  String get proPlusRestorePurchases => 'استعادة المشتريات';

  @override
  String get proPlusStartFree3DayTrial => 'ابدأ تجربة 3 أيام مجاناً';

  @override
  String get proPlusPaymentVerificationFailed =>
      'لم يكتمل تأكيد الدفع مع الخادم. حاول مجدداً.';

  @override
  String get proPlusProPlusActivatedStoreIs =>
      'مبروك! تم تفعيل باقة Pro Plus وتوثيق متجرك بنجاح';

  @override
  String get proPlusCouldNotLaunchGooglePay =>
      'تعذر فتح نافذة Google Pay على هذا الجهاز حالياً. تأكد من تفعيل حساب Google Play.';

  @override
  String get proPlusPayGooglePay => 'تأكيد الدفع عبر Google Pay';

  @override
  String get proPlusSave25 => 'وفّر 25%';

  @override
  String get proPlusLifetime => 'مدى الحياة';

  @override
  String get proPlusBasic => 'أساسي';

  @override
  String get proPlus12Months => '12 شهراً';

  @override
  String get proPlusOneTime => 'دفعة واحدة';

  @override
  String get proPlus1Month => 'شهر واحد';

  @override
  String get proPlusMad => 'د.م';

  @override
  String get proPlusPaywall => 'باقات Pro Plus';

  @override
  String get proPlusUnlockFullAccess => 'افتح الوصول الكامل';

  @override
  String get proPlusUnlimitedAccessAllFeaturesTemplates =>
      'وصول غير محدود لتوثيق المتجر، صدارة البحث، وتمويل VIP';

  @override
  String get proPlusOfficialBusinessStoreBlueVerified =>
      'حساب متجر Business رسمي + شارة التوثيق الزرقاء (Verified)';

  @override
  String get proPlusUnlimitedDailyListingsInstead5 =>
      'نشر إعلانات غير محدود يومياً (بدل 5 فـ النهار) + حتى 12 صورة';

  @override
  String get proPlus5FreeMonthlyVipBoosts =>
      '5 ترويجات VIP مجانية كل شهر + إحصائيات والردود السريعة';

  @override
  String proPlusSubscribePricedisplayMadGooglePay(Object priceDisplay) {
    return 'اشترك بـ $priceDisplay د.م عبر Google Pay';
  }

  @override
  String get proPlusNoThankYou => 'لا، شكراً';

  @override
  String get profileCouldNotLoadListingsPull =>
      'تعذر تحميل الإعلانات. اسحب للمحاولة مجدداً.';

  @override
  String get profileMyAccount => 'حسابي';

  @override
  String get profileSettingsSupport => 'الإعدادات والدعم';

  @override
  String get profileSignManageListingsSavedItems =>
      'سجّل الدخول لإدارة إعلاناتك، المفضلة، والمحادثات الفورية مع المشترين.';

  @override
  String get profileSignViewProfile => 'سجّل الدخول لعرض حسابك';

  @override
  String get welcomeCreateAccountButton => 'إنشاء حساب جديد';

  @override
  String get profileLightMode => 'الوضع الفاتح';

  @override
  String get profileDarkMode => 'الوضع الداكن';

  @override
  String get profileListings => 'إعلاناتي';

  @override
  String get profileLikes => 'المفضلة';

  @override
  String get profileSaved => 'المحفوظات';

  @override
  String get shareProfileButton => 'مشاركة الملف';

  @override
  String get profileMyListings => 'إعلاناتي';

  @override
  String get profileProInsightsBoost => 'لوحة الأعمال والإحصائيات';

  @override
  String profileUpgradeApoloPremiumMonthlypremiumpricemadMad(
      Object monthlyPremiumPriceMad) {
    return 'ترقية إلى Apolo Premium · $monthlyPremiumPriceMad د.م/شهر';
  }

  @override
  String get profileBusinessStoreVerifiedBadgeUnlimited =>
      'متجر Business + شارة Verified الزرقاء + نشر غير محدود عبر Google Pay.';

  @override
  String get profileViewStore => 'عرض متجري';

  @override
  String get profileEditStore => 'إعدادات المتجر';

  @override
  String get profileQuickReplies => 'الردود السريعة';

  @override
  String get profileNoListingsYet => 'لا توجد إعلانات منشورة';

  @override
  String get profilePublishFirstListingShowcaseIt =>
      'انشر إعلانك الأول ليظهر هنا في معرضك الخاص.';

  @override
  String get profilePostListing => 'إضافة إعلان';

  @override
  String get profileTotalViews => 'إجمالي المشاهدات';

  @override
  String get profileActiveListings => 'الإعلانات النشطة';

  @override
  String get profileAvgListing => 'متوسط المشاهدات';

  @override
  String get profileBoostedListings => 'إعلانات ممولة';

  @override
  String get profileCallTaps => 'نقرات الاتصال';

  @override
  String get profileCustomerChats => 'محادثات الزبناء';

  @override
  String get profileDirectOrders => 'طلبيات المتجر';

  @override
  String get profileFreeVipCredits => 'رصيد VIP المجاني';

  @override
  String get profileUnlockCallOrderStatsPro =>
      'افتح إحصائيات النقرات والطلبيات + شارة PRO+';

  @override
  String get profileGet3FreeVipBoosts =>
      'احصل على 3 تمويلات VIP مجانية شهرياً وتصدر المتاجر.';

  @override
  String get profileViewsBreakdown => 'توزيع المشاهدات';

  @override
  String get profileLive => 'مباشر';

  @override
  String get profilePublishFirstListingTrackViews =>
      'انشر إعلانك الأول لتبدأ متابعة المشاهدات والأداء هنا.';

  @override
  String get profileTopPerformingListings => 'أفضل إعلاناتك أداءً';

  @override
  String get profileViews => 'مشاهدة';

  @override
  String get profileSalesTip => 'نصيحة لزيادة المبيعات';

  @override
  String get profileAddClearPhotosFairPrice =>
      'أضف صوراً واضحة وثمناً مناسباً في إعلانك الأول لجذب المشترين بسرعة.';

  @override
  String get profileRefreshingPhotosBoostingTopListing =>
      'تحديث الصور والوصف أو تمويل إعلانك الأكثر مشاهدة يضاعف فرص البيع.';

  @override
  String get profileEditListing => 'تعديل الإعلان';

  @override
  String get profileBoostThisListing => 'تمويل الإعلان (Boost)';

  @override
  String get profileDeleteListing => 'حذف الإعلان';

  @override
  String get profileCouldNotDeleteListingPlease =>
      'تعذر حذف الإعلان حالياً. حاول مرة أخرى.';

  @override
  String get profileDeleteThisListing => 'حذف هذا الإعلان؟';

  @override
  String get profileThisListingWillBePermanently =>
      'سيتم حذف الإعلان نهائياً من حسابك ومن نتائج البحث ولا يمكن التراجع عن هذه العملية.';

  @override
  String get profileListingDeletedSuccessfully => 'تم حذف الإعلان بنجاح';

  @override
  String get scanProfileCodeThisIsOwnProfile => 'هذا هو ملفك الشخصي الحالي';

  @override
  String scanProfileCodeApoloMemberSellerid(Object sellerId) {
    return 'مستخدم Apolo #$sellerId';
  }

  @override
  String get scanProfileCodeScannedCode => 'رمز ممسوح';

  @override
  String get scanProfileCodeCodeDetected => 'تمت قراءة الرمز';

  @override
  String get scanProfileCodeOpenLink => 'فتح الرابط';

  @override
  String get scanProfileCodeScanAgain => 'مسح من جديد';

  @override
  String get scanProfileCodeFlashlightIsUnavailableThisBrowser =>
      'الفلاش غير مدعوم في متصفح هذا الجهاز';

  @override
  String get scanProfileCodeFlashlightIsUnavailableThisCamera =>
      'الفلاش غير متاح على هذا الجهاز';

  @override
  String get scanProfileCodeCouldNotToggleFlashlightRight =>
      'تعذر تشغيل الفلاش حالياً';

  @override
  String get scanProfileCodeNoQrCodeDetectedSelected =>
      'لم يتم العثور على رمز QR في الصورة المختارة';

  @override
  String get scanProfileCodeEnterCode => 'أدخل الرمز';

  @override
  String get scanProfileCodeCouldNotOpenPhotoLibrary => 'تعذر فتح معرض الصور';

  @override
  String get scanProfileCodeScanQrCode => 'مسح رمز QR';

  @override
  String get scanProfileCodePickQrImage => 'اختيار صورة من المعرض';

  @override
  String get scanProfileCodeTapEnableCamera => 'اضغط لتفعيل الكاميرا';

  @override
  String get scanProfileCodeEnterCodeManually => 'إدخال الرمز يدوياً';

  @override
  String get scanProfileCodePleaseEnterLinkHandle =>
      'المرجو إدخال رابط أو معرف صالح';

  @override
  String get scanProfileCodePasteApoloProfileLinkEnter =>
      'الصق رابط الحساب (apolo.ma/users/...) أو اكتب @username';

  @override
  String get scanProfileCodeOpenProfile => 'فتح الحساب';

  @override
  String get searchRecommended => 'مقترح لك';

  @override
  String get searchNewest => 'الأحدث';

  @override
  String get searchLowestPrice => 'الأقل ثمناً';

  @override
  String get searchHighestPrice => 'الأعلى ثمناً';

  @override
  String get searchMostViewed => 'الأكثر مشاهدة';

  @override
  String get searchFilterSort => 'تصفية وترتيب الإعلانات';

  @override
  String get resetButton => 'إعادة ضبط';

  @override
  String get searchSortBy => 'الترتيب حسب';

  @override
  String get searchAllMorocco => 'كل المغرب';

  @override
  String get searchPriceRangeMad => 'نطاق الثمن (بالدرهم)';

  @override
  String get searchMinPrice => 'أقل ثمن';

  @override
  String get searchMaxPrice => 'أقصى ثمن';

  @override
  String get searchNegotiableListingsOnly =>
      'إظهار الإعلانات القابلة للتفاوض فقط';

  @override
  String get searchApplyFilters => 'تطبيق الفلتر';

  @override
  String get searchSignSaveSearchesListings =>
      'سجّل الدخول لحفظ البحث والإعلانات';

  @override
  String get searchSaved => 'تم حفظ البحث بنجاح';

  @override
  String get searchUnableSaveSearchRightNow => 'تعذر حفظ البحث حالياً';

  @override
  String get searchSaveSearch => 'حفظ البحث';

  @override
  String get searchNoSavedListingsYet => 'لا توجد إعلانات محفوظة بعد';

  @override
  String get searchTapHeartAnyListingSave =>
      'اضغط على القلب في أي إعلان لحفظه هنا';

  @override
  String get searchFilter => 'تصفية';

  @override
  String get searchAllCategories => 'جميع الأقسام';

  @override
  String get searchAllAreas => 'كل المغرب';

  @override
  String get searchSetArea => 'حدد منطقتك';

  @override
  String get searchFeedView => 'عرض البطاقات الكبيرة';

  @override
  String get searchGridView => 'عرض الشبكة';

  @override
  String get personalAccountBadge => 'أفراد';

  @override
  String get businessAccountBadge => 'متاجر Business';

  @override
  String searchNoListingsWithinZoneradiuskmKm(Object zoneRadiusKm, Object s) {
    return 'لا توجد إعلانات في نطاق $zoneRadiusKm كم من $s. يمكنك توسيع النطاق أو عرض كل المغرب.';
  }

  @override
  String get searchTryAnotherCategoryBroadenFilters =>
      'جرب تبدل القسم أو توسع نطاق البحث والمدينة.';

  @override
  String get searchResetFilters => 'إعادة ضبط الفلاتر';

  @override
  String get sellerProfileSellerPhoneNumberNotAvailable =>
      'رقم هاتف البائع غير متوفر حالياً';

  @override
  String get sellerProfileSelectListingMessageThisSeller =>
      'اختر إعلاناً للبائع لبدء المحادثة.';

  @override
  String get sellerProfileReportSeller => 'الإبلاغ عن البائع';

  @override
  String get sellerProfileBlockSeller => 'حظر هذا البائع';

  @override
  String get sellerProfileSellerBlockedSuccessfully => 'تم حظر البائع بنجاح';

  @override
  String get sellerProfileFollowers => 'متابع';

  @override
  String get sellerProfileRating => 'التقييم';

  @override
  String sellerProfileStorecategorylabelCityStorehours(
      Object storeCategoryLabel, Object city, Object storeHours) {
    return '$storeCategoryLabel · $city · $storeHours';
  }

  @override
  String sellerProfileIndividualSellerCityDirectChat(Object city) {
    return 'بائع فردي في $city · تواصل مباشر عبر الشات.';
  }

  @override
  String get sellerProfileVisitStore => 'زيارة المتجر';

  @override
  String sellerProfileListingsSellerads(Object sellerAds) {
    return 'الإعلانات ($sellerAds)';
  }

  @override
  String sellerProfileReviewsCount(Object count) {
    return 'التقييمات ($count)';
  }

  @override
  String get sellerProfileTrustInfo => 'حول والضمانات';

  @override
  String get sellerProfileNoListingsAvailableRightNow =>
      'لا توجد إعلانات منشورة حالياً';

  @override
  String get sellerProfile3DaysAgo => 'منذ 3 أيام';

  @override
  String get sellerProfileVeryReliableSellerItemMatched =>
      'البائع معقول بزاف، السلعة نقية كيف فالتصاور والمعاملة ممتازة، كيشرح ليك كلشي بالتفصيل.';

  @override
  String get sellerProfile1WeekAgo => 'منذ أسبوع';

  @override
  String get sellerProfileSmoothBuyingExperienceInspectedBefore =>
      'تجربة شراء سريعة وموثوقة، التيليفون مختوم بالباكية وجربتو عاد خلصت. الله يعطيه الصحة.';

  @override
  String get sellerProfile2WeeksAgo => 'منذ أسبوعين';

  @override
  String get sellerProfileHonestRespectfulSellerLetMe =>
      'ما شاء الله إنسان صادق ومحترم، جا حتى لعندي وخلاني نفحص البيسي كامل على خاطري.';

  @override
  String get sellerProfile1MonthAgo => 'منذ شهر';

  @override
  String get sellerProfileGreatTransactionFullTrustFast =>
      'معاملة ممتازة وثقة كاملة. استجابة سريعة فـ شات Apolo.';

  @override
  String sellerProfileCountVerifiedReviews(Object count) {
    return '$count تقييم حقيقي';
  }

  @override
  String get sellerProfileGovernmentIdVerified => 'بطاقة التعريف الوطنية مؤكدة';

  @override
  String get sellerProfileOfficialIdentityDocumentReviewedVerified =>
      'تم فحص ومصادقة وثائق الهوية الوطنية من طرف فريق التوثيق في Apolo.';

  @override
  String get sellerProfileVerifiedPhoneNumber => 'رقم هاتف مغربي موثق';

  @override
  String get sellerProfilePhoneNumberConfirmedViaSms =>
      'رقم الهاتف مفعل عبر رمز التحقق OTP ومربوط مباشرة بحساب البائع.';

  @override
  String get sellerProfileApoloSafetyProtection =>
      'حماية المعاملات Apolo Safety';

  @override
  String get sellerProfileWeRecommendInspectingItemPerson =>
      'ينصح فريق Apolo بمعاينة وفحص السلعة شخصياً قبل دفع أي مبلغ.';

  @override
  String get sellerProfileAvailableDeliveryMethods => 'طرق التسليم المتاحة';

  @override
  String sellerProfileHandHandPickupCityInsured(Object city) {
    return 'التسليم يداً بيد في $city، أو الإرسال عبر أمانة كوليس بعد الاتفاق.';
  }

  @override
  String get accountCenterSwitchPersonalAccount => 'العودة إلى الحساب الشخصي';

  @override
  String get accountCenterReturnPersonalAccount =>
      'هل تريد العودة للحساب الشخصي؟';

  @override
  String get accountCenterBusinessStorePageWillBe =>
      'سيتم إيقاف عرض صفحة المتجر الاحترافي مؤقتاً ويمكنك إعادة تفعيله لاحقاً.';

  @override
  String get accountCenterConfirmSwitch => 'تأكيد التحويل';

  @override
  String get accountCenterSwitchedPersonalAccount =>
      'تم التحويل إلى الحساب الشخصي بنجاح.';

  @override
  String get accountCenterCouldNotSwitchAccountType =>
      'تعذر تغيير نوع الحساب. حاول مجدداً.';

  @override
  String get accountCenterApoloAccount => 'مركز حساب أبولو';

  @override
  String get accountCenterPersonalDetails => 'البيانات الشخصية';

  @override
  String get accountCenterEmailPhone => 'البريد الإلكتروني والهاتف';

  @override
  String get accountCenterAccountTypePreferences => 'نوع الحساب والتفضيلات';

  @override
  String get accountCenterPasswordSecurity => 'كلمة المرور والأمان';

  @override
  String get accountCenterResetPassword => 'إعادة تعيين كلمة المرور';

  @override
  String get accountCenterBusinessStore => 'الأعمال والمتجر';

  @override
  String get accountCenterEditStoreProfile => 'تعديل ملف المتجر';

  @override
  String get accountCenterSwitchBusinessAccount => 'التحويل إلى حساب أعمال';

  @override
  String get accountCenterAccountOwnership => 'ملكية الحساب';

  @override
  String get accountCenterDeleteAccountData => 'حذف الحساب والبيانات';

  @override
  String get accountCenterManageApoloAccount => 'إدارة حساب أبولو';

  @override
  String get accountCenterSignManageSecurityPersonalDetails =>
      'سجّل الدخول للوصول إلى الأمان، البيانات الشخصية، ومتجر الأعمال.';

  @override
  String get logInButton => 'تسجيل الدخول';

  @override
  String get settingsAppDataAppDataRefreshedSuccessfully =>
      'تم تحديث بيانات التطبيق بنجاح.';

  @override
  String get settingsAppDataCouldNotRefreshDataCheck =>
      'تعذر تحديث البيانات. تحقق من الاتصال وأعد المحاولة.';

  @override
  String get settingsAppDataAppDataSync => 'بيانات التطبيق والتحديث';

  @override
  String get settingsAppDataSystemInformationLocalSyncStatus =>
      'معلومات النظام وحالة المزامنة المحلية مع خادم Apolo.ma.';

  @override
  String get settingsAppDataApplicationStatus => 'حالة التطبيق';

  @override
  String get settingsAppDataAppVersion => 'إصدار التطبيق';

  @override
  String get settingsAppDataServer => 'الخادم';

  @override
  String get settingsAppDataSyncedCategories => 'الأقسام المتزامنة';

  @override
  String get settingsAppDataSyncedCities => 'المدن المتاحة';

  @override
  String get settingsAppDataActiveZone => 'المنطقة النشطة';

  @override
  String get settingsAppDataOpenSourceLicenses => 'التراخيص مفتوحة المصدر';

  @override
  String get settingsAppDataRefreshDataNow => 'تحديث البيانات الآن';

  @override
  String get settingsAppearanceAppearance => 'المظهر';

  @override
  String get settingsAppearanceChooseHowApoloLooksSwitch =>
      'اختر مظهر Apolo المناسب لك. يمكنك التبديل بين الوضع الفاتح والوضع الداكن أو اتباع إعدادات جهازك تلقائياً.';

  @override
  String get settingsAppearanceCleanWhiteSurfacesCrispDaylight =>
      'خلفية بيضاء ناصعة وتباين واضح في النهار';

  @override
  String get settingsAppearanceEasyEyesLowLightSaves =>
      'مريح للعين في الإضاءة المنخفضة ويوفر طاقة البطارية';

  @override
  String get settingsAppearanceSystemDefault => 'تلقائي حسب الجهاز';

  @override
  String get settingsAppearanceAutomaticallyMatchesPhoneBrowserTheme =>
      'يتغير تلقائياً مع مظهر الهاتف أو المتصفح';

  @override
  String settingsBlockedAccountsUnblockedName(Object name) {
    return 'تم إلغاء حظر $name';
  }

  @override
  String get settingsBlockedAccountsBlockedAccounts => 'الحسابات المحظورة';

  @override
  String get settingsBlockedAccountsNoBlockedAccountsYet =>
      'لا توجد حسابات محظورة حالياً';

  @override
  String get settingsBlockedAccountsUsersStoresYouBlockFrom =>
      'الحسابات أو المتاجر التي تقوم بحظرها من المحادثات أو الإعلانات ستظهر هنا ويمكنك إلغاء حظرها في أي وقت.';

  @override
  String get settingsBlockedAccountsYouCanUnblockAnyUser =>
      'يمكنك إلغاء حظر أي مستخدم أو متجر في أي وقت.';

  @override
  String get settingsBlockedAccountsBlockedStore => 'متجر محظور';

  @override
  String get settingsBlockedAccountsBlockedUser => 'حساب محظور';

  @override
  String get settingsBugReportQuickTrigger => 'التشغيل السريع';

  @override
  String get settingsBugReportDiagnosticsSummary => 'ملخص التشخيص';

  @override
  String get settingsBugReportPlatform => 'المنصة';

  @override
  String get settingsBugReportActiveLanguage => 'اللغة النشطة';

  @override
  String get settingsBugReportHelpSupport => 'المساعدة والدعم';

  @override
  String get settingsLanguageCouldNotSaveLanguagePlease =>
      'تعذر حفظ اللغة. أعد المحاولة.';

  @override
  String get settingsLanguageAppLanguage => 'لغة التطبيق';

  @override
  String get settingsLanguageChooseLanguageAppInterfaceListings =>
      'اختر لغة واجهة التطبيق والإعلانات. سيتم تطبيق التغيير فوراً على كامل التطبيق.';

  @override
  String get settingsRateAppNeedsWork => 'يحتاج لتحسين كبير';

  @override
  String get settingsRateAppFair => 'تجربة مقبولة';

  @override
  String get settingsRateAppGreat => 'ممتاز جداً';

  @override
  String get settingsRateAppAwesome => 'رائع! شكراً لدعمك';

  @override
  String get settingsRateAppSelectStars => 'اختر عدد النجوم';

  @override
  String get settingsRateAppPleaseSelect15Stars =>
      'يرجى اختيار تقييم من 1 إلى 5 نجوم.';

  @override
  String get settingsRateAppRateApp => 'تقييم التطبيق';

  @override
  String get settingsRateAppHowIsExperienceApoloMa =>
      'كيف هي تجربتك مع Apolo.ma؟';

  @override
  String get settingsRateAppAddQuickNoteOptional =>
      'أضف ملاحظة سريعة (اختياري)...';

  @override
  String settingsRateAppThankYouRatingUsRating(Object rating) {
    return 'شكراً على تقييمك ($rating/5)! رأيك كيساعدنا نطورو Apolo.ma.';
  }

  @override
  String get settingsRateAppSubmitRating => 'إرسال التقييم';

  @override
  String get settingsRateAppVisitApoloMa => 'زيارة موقع Apolo.ma';

  @override
  String get settingsSavedAdsCouldNotRemoveSavedListing =>
      'تعذر إزالة الإعلان من المحفوظات. حاول مجدداً.';

  @override
  String get settingsSavedAdsSignViewSavedListings =>
      'سجّل الدخول لعرض المحفوظات';

  @override
  String get settingsSavedAdsSaveListingsYouLikeRevisit =>
      'احفظ الإعلانات التي تعجبك للرجوع إليها في أي وقت.';

  @override
  String get settingsSavedAdsCouldNotLoadSavedListings =>
      'تعذر تحميل المحفوظات';

  @override
  String get settingsSavedAdsCheckInternetConnectionTryAgain =>
      'تحقق من اتصالك بالإنترنت وأعد المحاولة.';

  @override
  String get settingsSavedAdsTapFavoriteIconAnyListing =>
      'اضغط على أيقونة الحفظ في أي إعلان لإضافته هنا.';

  @override
  String settingsShareAppCheckOutApoloMaMorocco(Object shareUrl) {
    return 'اكتشف Apolo.ma — سوقك الأول للإعلانات المبوبة والمتاجر فالمغرب: $shareUrl';
  }

  @override
  String get settingsShareAppShareApp => 'مشاركة التطبيق';

  @override
  String get settingsShareAppMoroccoSMarketplaceClassifiedsOfficial =>
      'سوقك الأول للإعلانات المبوبة والمتاجر فالمغرب. شارك التطبيق مع أصدقائك وعائلتك.';

  @override
  String settingsShareAppAppLinkCopiedShareurl(Object shareUrl) {
    return 'تم نسخ رابط التطبيق بنجاح: $shareUrl';
  }

  @override
  String get settingsShareAppShareNow => 'مشاركة الآن';

  @override
  String get settingsShareAppCopyLink => 'نسخ الرابط';

  @override
  String get settingsShareAppShareMyQrProfile => 'مشاركة بطاقة QR الخاصة بي';

  @override
  String get settingsSuggestionPleaseEnterSuggestionAtLeast =>
      'يرجى كتابة اقتراح من 5 أحرف على الأقل.';

  @override
  String get settingsSuggestionCouldNotSendOverNetwork =>
      'تعذر إرسال الاقتراح عبر الشبكة حالياً. يمكنك المحاولة مجدداً أو إرساله عبر البريد الإلكتروني.';

  @override
  String get settingsSuggestionCopiedSupportApoloMa =>
      'تم نسخ البريد الإلكتروني support@apolo.ma';

  @override
  String get settingsSuggestionFeature => 'ميزة جديدة';

  @override
  String get settingsSuggestionDesign => 'تحسين التصميم';

  @override
  String get settingsSuggestionPerformance => 'الأداء والسرعة';

  @override
  String get settingsSuggestionOther => 'أخرى';

  @override
  String get settingsSuggestionMakeSuggestion => 'تقديم اقتراح';

  @override
  String get settingsSuggestionShareIdeasHelpUsImprove =>
      'شاركنا أفكارك لتحسين تجربة الشراء والبيع على Apolo.ma.';

  @override
  String get settingsSuggestionTopic => 'نوع الاقتراح';

  @override
  String get settingsSuggestionYourSuggestion => 'تفاصيل الاقتراح';

  @override
  String get settingsSuggestionWriteIdeaHere => 'اكتب فكرتك هنا بوضوح...';

  @override
  String get settingsSuggestionThankYouSuggestionHasBeen =>
      'شكراً لك! تم استلام اقتراحك بنجاح.';

  @override
  String get settingsSuggestionSubmitSuggestion => 'إرسال الاقتراح';

  @override
  String get settingsSuggestionEmailSupportApoloMa =>
      'إرسال عبر support@apolo.ma';

  @override
  String get settingsZoneMarketplaceZone => 'منطقة الإعلانات (GPS)';

  @override
  String get logOutButton => 'تسجيل الخروج';

  @override
  String get settingsLogOutAccount => 'هل تريد تسجيل الخروج؟';

  @override
  String get settingsYouCanSignBackAnytime =>
      'يمكنك إعادة تسجيل الدخول في أي وقت للوصول إلى إعلاناتك ومحادثاتك.';

  @override
  String get settingsProActive => 'مفعل PRO+';

  @override
  String get settingsNotSubscribed => 'غير مشترك';

  @override
  String get settingsVipBoostCredits => 'رصيد التمويل VIP';

  @override
  String get settingsPrivacyTerms => 'الخصوصية والشروط';

  @override
  String get settingsAppDataLicenses => 'بيانات التطبيق والتراخيص';

  @override
  String get settingsActivity => 'الإعدادات والنشاط';

  @override
  String get settingsNoMatchingSettings => 'لا توجد نتائج';

  @override
  String get settingsTryAnotherKeywordSuchAs =>
      'جرّب البحث بكلمة أخرى مثل: المحفوظات، اللغة، أو Pro+.';

  @override
  String get settingsYourAccount => 'حسابك';

  @override
  String get settingsHowYouUseApolo => 'كيف تستخدم Apolo';

  @override
  String get settingsSubscriptions => 'الاشتراكات';

  @override
  String get settingsCommunityPrivacy => 'المجتمع والخصوصية';

  @override
  String get settingsSupport => 'الدعم';

  @override
  String get settingsAccount => 'الحساب';

  @override
  String get settingsPasswordSecurityPersonalDetailsStore =>
      'كلمة المرور، الأمان، البيانات الشخصية، المتجر والأعمال';

  @override
  String get shareProfileProfileLinkCopied => 'تم نسخ رابط الملف الشخصي';

  @override
  String shareProfileCheckOutNameHandleApolo(
      Object name, Object handle, Object url) {
    return 'شوف حساب $name ($handle) على Apolo.ma:\n$url';
  }

  @override
  String get shareProfileShareLink => 'مشاركة الرابط';

  @override
  String get shareProfileQrCodeIsPrivateIf =>
      'رمز QR الخاص بك خاص. إذا شاركته مع شخص ما، يمكنه مسحه بالكاميرا لإضافتك كجهة اتصال.';

  @override
  String get shareProfileScanCode => 'مسح الرمز';

  @override
  String get storeDetailReportStore => 'الإبلاغ عن هذا المتجر';

  @override
  String get storeDetailStoreBlocked => 'تم حظر المتجر بنجاح';

  @override
  String get storeDetailBlockStore => 'حظر هذا المتجر';

  @override
  String get storeDetailDirectStoreOrder => 'طلب سريع من المتجر';

  @override
  String get storeDetailSelectItem => 'اختر المنتج';

  @override
  String get storeDetailFullName => 'الاسم الكامل';

  @override
  String get storeDetailDeliveryAddress => 'العنوان';

  @override
  String get storeDetailOrderNotes => 'ملاحظات الطلب';

  @override
  String get storeDetailConfirmOrder => 'تأكيد الطلب الآن';

  @override
  String get storeDetailOrderSubmittedSuccessfully =>
      'تم إرسال طلبك للمتجر بنجاح';

  @override
  String get storeDetailStoreNotFound => 'المتجر غير موجود';

  @override
  String get storeDetailCheckLinkBrowseVerifiedStores =>
      'تحقق من الرابط أو عد إلى قائمة المتاجر الرسمية.';

  @override
  String get storeDetailOrderNow => 'اطلب الآن';

  @override
  String storeDetailOpenWorkinghours(Object workingHours) {
    return 'مفتوح · $workingHours';
  }

  @override
  String storeDetailClosedWorkinghours(Object workingHours) {
    return 'مغلق · $workingHours';
  }

  @override
  String get storeDetailOpenGoogleMaps => 'عرض الموقع على Google Maps';

  @override
  String get storeDetailOrder => 'طلب مباشر';

  @override
  String get storeDetailProducts => 'المنتجات';

  @override
  String get verifiedBadgeLabel => 'موثوق';

  @override
  String get storeDetailDelivery => 'التوصيل';

  @override
  String get storeDetailStoreCatalog => 'منتجات المتجر';

  @override
  String storesTotalstoresVerifiedOfficialStores(Object totalStores) {
    return '$totalStores متجر رسمي موثق في المغرب';
  }

  @override
  String get storesSearchOfficialStores => 'ابحث عن متجر احترافي معتمد...';

  @override
  String get storesMostProducts => 'الأكثر منتجات';

  @override
  String get storesTopRated => 'الأعلى تقييماً';

  @override
  String get storesNoMatchingStores => 'لا توجد متاجر مطابقة حالياً';

  @override
  String get storesTryAnotherKeywordReloadVerified =>
      'جرب البحث بكلمة أخرى أو إعادة تحميل قائمة المتاجر المعتمدة.';

  @override
  String get storesItems => 'منتج';

  @override
  String get storesVisit => 'زيارة المتجر';

  @override
  String get supportCouldNotOpenMailApp =>
      'تعذر فتح تطبيق البريد. يمكنك مراسلة support@apolo.ma يدوياً.';

  @override
  String get supportHowCanWeHelpYou => 'كيف يمكننا مساعدتك؟';

  @override
  String get supportExplainIssueStepsBeforeIt =>
      'اشرح المشكلة والخطوات التي سبقتها. يمكنك إرفاق صورة بعد إخفاء المعلومات الشخصية.';

  @override
  String get supportDirectContact => 'التواصل المباشر';

  @override
  String get supportOpenMailApp => 'فتح تطبيق البريد';

  @override
  String get supportNoEmailIsSentAutomatically =>
      'لن تُرسل رسالة تلقائياً. راجعها ثم أرسلها من تطبيق البريد.';

  @override
  String get supportSafetyReminder => 'تذكير الأمان';

  @override
  String get supportNeverSharePasswordVerificationCode =>
      'لا تشارك كلمة المرور أو رمز التحقق أو بيانات الدفع مع أي شخص.';

  @override
  String get welcomeUnableStartGoogleSignRight =>
      'تعذر بدء تسجيل الدخول عبر Google حالياً.';

  @override
  String get welcomeContinueGoogle => 'المتابعة عبر Google';

  @override
  String get welcomeOr => 'أو';

  @override
  String get welcomeIHaveAccount => 'لدي حساب بالفعل';

  @override
  String get welcomeNewOfferReceivedListing => 'عرض جديد وصل على إعلانك الآن!';

  @override
  String get welcomeY => 'ي';

  @override
  String get welcomeYassineCasablanca => 'ياسين • الدار البيضاء';

  @override
  String get welcomeYesAvailableWelcome => 'مرحباً! نعم متوفر، تفضل';

  @override
  String get accommodationCardSintraPortugal => 'المغرب';

  @override
  String get accommodationCardExclusiveDeal => 'عرض حصري';

  @override
  String get adCardVip => 'مميز';

  @override
  String get safetyReportMessage => 'الإبلاغ عن هذه الرسالة';

  @override
  String get safetyReportListing => 'الإبلاغ عن هذا الإعلان';

  @override
  String get safetyReportUser => 'الإبلاغ عن هذا الحساب';

  @override
  String get safetyAlsoBlockThisAccount => 'حظر هذا الحساب أيضاً';

  @override
  String get safetySubmitReport => 'إرسال البلاغ الآن';

  @override
  String get safetyReportSubmittedSuccessfully =>
      'تم إرسال بلاغك للإدارة بنجاح';

  @override
  String get safetyBlockedAccounts => 'الحسابات المحظورة';

  @override
  String get boostCouldNotCompletePayment => 'تعذر إتمام عملية الدفع';

  @override
  String get boostListingBoosted => 'تم تمييز إعلانك بنجاح!';

  @override
  String get boostPaymentNotConfirmedContactSupport =>
      'لم يتم تأكيد الدفع. تواصل مع الدعم قبل إعادة الشراء.';

  @override
  String get boostVipBoostActivatedUsingPro =>
      'تم تفعيل VIP مجاناً من رصيد Pro Plus!';

  @override
  String get boostListing => 'ميّز إعلانك وضاعف مبيعاتك';

  @override
  String boostActivateFreeVipProVipboostcredits(Object vipBoostCredits) {
    return 'تفعيل VIP مجاناً من رصيد Pro Plus ($vipBoostCredits)';
  }

  @override
  String get boostGet3FreeVipBoosts =>
      'احصل على 3 تمويلات VIP مجانية شهرياً مع Apolo Pro+';

  @override
  String get boostPlansAreCurrentlyUnavailablePlease =>
      'العروض غير متوفرة حالياً. أعد المحاولة لاحقاً.';

  @override
  String get boostInstantWebCheckoutIsEnabled =>
      'الدفع الفوري عبر الويب متاح لحسابك.';

  @override
  String get boostActivateBoostNow => 'تفعيل التمييز الآن';

  @override
  String get chatUtilsYesterday => 'أمس';

  @override
  String get guestFavoriteBadge => 'موصى به';

  @override
  String get exploreListingCardContactSeller => 'تواصل مع المعلن';

  @override
  String get marketplaceZoneCouldNotAutoDetectLocation =>
      'تعذر تحديد موقعك تلقائياً — اختر مدينتك من القائمة أسفله';

  @override
  String get marketplaceZoneMarketplaceLocation => 'تحديد منطقة الإعلانات';

  @override
  String get marketplaceZoneOnlySeeListingsInsideLocal =>
      'شاهد الإعلانات القريبة منك في منطقتك الجغرافية';

  @override
  String get marketplaceZoneSearchNeighborhoodCityAddress =>
      'ابحث عن حي، مدينة أو عنوان...';

  @override
  String get marketplaceZoneNationwide => 'نطاق مفتوح';

  @override
  String get marketplaceZoneDetectMyLocationAutomatically =>
      'تحديد منطقتي تلقائياً (GPS)';

  @override
  String get marketplaceZoneDistanceRadius => 'نطاق المسافة (كم)';

  @override
  String get marketplaceZoneAllMorocco => 'كل المغرب';

  @override
  String get marketplaceZoneSelectCity => 'اختر المدينة';

  @override
  String get marketplaceZoneApplyZone => 'تطبيق المنطقة';

  @override
  String quickRepliesLimitReachedMaxallowedUpgradePro(Object maxAllowed) {
    return 'وصلت للحد الأقصى ($maxAllowed ردود). رقِّ إلى Pro Plus لردود غير محدودة!';
  }

  @override
  String get quickRepliesQuickRepliesSaved =>
      'تم حفظ الردود السريعة ورسالة الترحيب بنجاح ⚡';

  @override
  String get quickRepliesChatQuickReplies =>
      'الردود السريعة للشات (Quick Replies)';

  @override
  String get quickRepliesTapAnyShortcutInsideChat =>
      'تظهر هذه الاختصارات فوق لوحة المفاتيح في محادثاتك للرد على الزبناء بضغطة واحدة.';

  @override
  String get quickRepliesAddQuickReply => 'إضافة رد سريع جديد';

  @override
  String get quickRepliesLabel => 'العنوان (مثال: الثمن)';

  @override
  String get quickRepliesReplyText => 'نص الرسالة...';

  @override
  String get quickRepliesAutoGreetingMessage =>
      'رسالة الترحيب التلقائية للزبناء الجدد';

  @override
  String get quickRepliesWelcomeStore =>
      'مرحباً بك في متجرنا! كيف يمكننا مساعدتك؟';

  @override
  String get quickRepliesSaveQuickReplies => 'حفظ الردود السريعة';

  @override
  String get quickRepliesManage => 'تعديل';

  @override
  String get realMarketplaceMapApproximateMapArea =>
      'الموقع التقريبي على الخريطة';

  @override
  String realMarketplaceMapDistkmKmFromYou(Object distKm) {
    return 'على بعد $distKm كم من موقعك';
  }

  @override
  String get realMarketplaceMapSetAsMyZone => 'اعتماده كمنطقتي';

  @override
  String get badgesKitBronze => 'عضو برونزي';

  @override
  String get badgesKitSilver => 'بائع فضي';

  @override
  String get badgesKitGold => 'بائع ذهبي';

  @override
  String get badgesKitPlatinum => 'بائع بلاتيني';

  @override
  String get badgesKitDiamond => 'بائع ماسي';

  @override
  String get badgesKitChampion => 'بطل أبولو';

  @override
  String get badgesKitStarterMemberApolo => 'بداية الحساب على Apolo';

  @override
  String get badgesKitVerifiedAccount2Listings =>
      'توثيق الحساب أو إعلانان فأكثر';

  @override
  String get badgesKitBusinessStore5Listings => 'متجر أعمال أو +5 إعلانات';

  @override
  String get badgesKitActiveProActiveStore8 =>
      'اشتراك Pro+ أو متجر نشيط (+8 إعلانات)';

  @override
  String get badgesKitPro10Listings1500 =>
      'Pro+ مع +10 إعلانات أو +1500 مشاهدة';

  @override
  String get badgesKitTopTierPro20Listings =>
      'أعلى رتبة: Pro+ مع +20 إعلاناً أو +5000 مشاهدة';

  @override
  String get badgesKitSellerRank => 'المستوى:';

  @override
  String get badgesKitTopRankUnlockedApolo => 'وصلت لأعلى رتبة على Apolo!';

  @override
  String get badgesKitNext => 'الرتبة التالية:';

  @override
  String get badgesKitTrustSellerRanks => 'التوثيق ورتب البائعين';

  @override
  String get badgesKitCurrentRank => 'المستوى الحالي:';

  @override
  String get badgesKitVerifiedApoloAccount => 'حساب موثوق على Apolo';

  @override
  String get badgesKitVerifiedSeal => 'شارة التوثيق الزرقاء';

  @override
  String get badgesKitIdentityContactDetailsVerifiedSafer =>
      'تم التحقق من بيانات الحساب ورقم الهاتف لتعزيز الثقة والأمان.';

  @override
  String get badgesKitEarnedByVerifyingPhoneNumber =>
      'تظهر الشارة بعد توثيق رقم الهاتف أو تفعيل متجر احترافي.';

  @override
  String get badgesKitAllSellerRanks => 'جميع رتب البائعين';

  @override
  String get badgesKitCurrent => 'الحالي';

  @override
  String get infeedUpgradeCardYourProfile => 'حسابك على Apolo';

  @override
  String get infeedUpgradeCardBuildCredibilityBuyersWhenYou =>
      'ابني ثقة أكبر مع المشترين، وافتح متجر Business ونشر غير محدود مع Apolo Premium.';

  @override
  String get infeedUpgradeCardUpgradeProfile => 'ترقية ملفك الشخصي';

  @override
  String get infeedUpgradeCardNotNow => 'ليس الآن';

  @override
  String get searchSuggestionsSearchUsernames =>
      'ابحث عن أسماء الحسابات أو الإعلانات';

  @override
  String get searchSuggestionsSuggestions => 'اقتراحات';

  @override
  String get searchSuggestionsRecentSearches => 'عمليات البحث الأخيرة';

  @override
  String get searchSuggestionsPopularSearches => 'عمليات بحث مقترحة';

  @override
  String get followedButton => 'متابَع';

  @override
  String get writeReviewExcellent => 'ممتاز';

  @override
  String get writeReviewVeryGood => 'جيد جداً';

  @override
  String get writeReviewPoor => 'ضعيف';

  @override
  String get writeReviewGreatCommunication => 'معاملة محترمة';

  @override
  String get writeReviewAsDescribed => 'سلعة مطابقة للوصف';

  @override
  String get writeReviewFastResponse => 'استجابة سريعة';

  @override
  String get writeReviewFairPrice => 'ثمن مناسب';

  @override
  String get writeReviewReviewHasBeenPosted => 'تم نشر تقييمك بنجاح';

  @override
  String get writeReviewShareExperienceThisSeller =>
      'شارك تجربتك مع هذا البائع (الجودة، التعامل، الموعد...)';

  @override
  String get writeReviewUpdateReview => 'حفظ التقييم';

  @override
  String get writeReviewSubmitReview => 'نشر التقييم';

  @override
  String get interestsSurveyWhatAreInterests => 'ما هي اهتماماتك؟';

  @override
  String get interestsSurveyDiscoverProducts => 'اكتشاف المنتجات';

  @override
  String interestsSurveySaveContinueSelectedcategoryids(
      Object selectedCategoryIds) {
    return 'حفظ وتأكيد ($selectedCategoryIds)';
  }

  @override
  String get interestsSurveySkipNow => 'تخطي الآن';

  @override
  String get priceLabel => 'الثمن';

  @override
  String get conditionLabel => 'الحالة';

  @override
  String get conditionNew => 'جديد';

  @override
  String get conditionLikeNew => 'شبه جديد (بحال الجديد)';

  @override
  String get conditionUsed => 'مستعمل';

  @override
  String get fulfillmentMeetInPerson => 'تسليم يداً بيد';

  @override
  String get fulfillmentDelivery => 'توصيل';

  @override
  String get listingStatusSold => 'تم البيع';

  @override
  String get listingStatusReserved => 'محجوز';

  @override
  String get safetyTipsTitle => 'نصائح الأمان';
}
