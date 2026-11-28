/// Full RTL/LTR localization strings (Arabic / French / English) for
/// Apolo.ma's SFU Group Meeting module.
library;

import '../../../l10n/l10n.dart';

class MeetingStrings {
  final String lang;
  const MeetingStrings(this.lang);

  bool get isAr => lang == 'ar';
  bool get isEn => lang == 'en';

  String tr(String ar, String fr, [String? en]) {
    if (isAr) return ar;
    if (isEn && en != null) return en;
    return fr;
  }

  String get lobbyTitle =>
      tr('الاستعداد للاجتماع', 'Préparation de la réunion', appL10n.meetingLobby);
  String get createNewMeeting =>
      tr('اجتماع جماعي جديد', 'Nouvelle réunion de groupe', appL10n.meetingNewGroupMeeting);
  String get joinExistingMeeting =>
      tr('الانضمام برمز الغرفة', 'Rejoindre avec un code', appL10n.meetingJoinRoomCode);
  String get meetingTitleLabel =>
      tr('عنوان الاجتماع', 'Titre de la réunion', appL10n.meetingTitle);
  String get meetingTitleHint => tr(
        'مثال: معاينة جماعية للشقة أو المتجر',
        'Ex : Visite groupée ou consultation',
        appL10n.meetingEGLivePropertyWalkthrough,
      );
  String get roomCodeHint =>
      tr('أدخل رمز الغرفة (apo-xxxx-xxxx)', 'Code salle (apo-xxxx-xxxx)', appL10n.meetingRoomCodeApoXxxxXxxx);
  String get joinNow =>
      tr('انضمام للاجتماع', 'Rejoindre maintenant', appL10n.meetingJoinMeeting);
  String get startMeeting =>
      tr('بدء الاجتماع الآن', 'Démarrer la réunion', appL10n.meetingStartMeeting);
  String get e2eeTitle => tr(
        'تشفير تام بين الأطراف (E2EE)',
        'Chiffrement de bout en bout (E2EE)',
        appL10n.meetingEndEndEncryptionE2ee,
      );
  String get e2eeSubtitle => tr(
        'خادم الـ SFU يمرر الحزم دون فك تشفير الفيديو أو الصوت أبداً',
        'Le serveur SFU transfère les paquets sans jamais décoder vos flux',
        appL10n.meetingSfuForwardsEncryptedPacketsWithout,
      );
  String get e2eePassphraseLabel => tr(
        'مفتاح التشفير المشترك للغرفة',
        'Clé secrète partagée de la salle',
        appL10n.meetingSharedRoomEncryptionKey,
      );
  String get sfuBadge => tr(
        'SFU + SVC متكيف (حتى 25+ مشارك)',
        'SFU + SVC adaptatif (25+ participants)',
        appL10n.meetingAdaptiveSfuSvc25Participants,
      );
  String get micOn => tr('الميكروفون مفعل', 'Micro activé', appL10n.meetingMicOn);
  String get micOff => tr('الميكروفون مكتوم', 'Micro coupé', appL10n.meetingMuted);
  String get camOn => tr('الكاميرا مفعلة', 'Caméra activée', appL10n.meetingCameraOn);
  String get camOff => tr('الكاميرا متوقفة', 'Caméra coupée', appL10n.meetingCameraOff);
  String get screenShare =>
      tr('مشاركة الشاشة', 'Partager l\'écran', appL10n.meetingShareScreen);
  String get stopScreenShare =>
      tr('إيقاف المشاركة', 'Arrêter le partage', appL10n.meetingStopSharing);
  String get speaker => tr('مكبر الصوت', 'Haut-parleur', appL10n.meetingSpeaker);
  String get switchCamera =>
      tr('تبديل الكاميرا', 'Changer de caméra', appL10n.meetingFlipCamera);
  String get participants =>
      tr('المشاركون', 'Participants', appL10n.meetingParticipants);
  String get leaveCall => tr('مغادرة', 'Quitter', appL10n.meetingLeave);
  String get endForAll =>
      tr('إنهاء للجميع', 'Terminer pour tous', appL10n.meetingEndAll);
  String get reconnectingBanner => tr(
        'ضعف في الاتصال... جاري إعادة الربط تلقائياً عبر أقرب مسار UDP/TURN',
        'Réseau instable... Reconnexion automatique via UDP/TURN en cours',
        appL10n.meetingUnstableNetworkAutomaticallyReconnectingVia,
      );
  String get lowBandwidthBanner => tr(
        'الإنترنت ضعيف: تم تخفيض طبقات الفيديو (SVC) لحماية جودة الصوت والبطارية',
        'Connexion faible : flux vidéo réduit (SVC) pour préserver l\'audio et la batterie',
        appL10n.meetingLowBandwidthVideoLayersStepped,
      );
  String get switchToAudioOnly =>
      tr('التحويل لصوت فقط', 'Mode audio uniquement', appL10n.meetingAudioOnly);
  String get resumeVideoMode =>
      tr('استئناف الفيديو', 'Réactiver la vidéo', appL10n.meetingResumeVideo);
  String get audioOnlyActive => tr(
        'وضع توفير البيانات والبطارية (صوت فقط) مفعل',
        'Mode économie de données et batterie (Audio seul) actif',
        appL10n.meetingDataBatterySaverAudioOnly,
      );
  String get youBadge => tr('أنت', 'Vous', appL10n.meetingYou);
  String get hostBadge => tr('مضيف', 'Hôte', appL10n.meetingHost);
  String get cohostBadge => tr('مضيف مساعد', 'Co-hôte', appL10n.meetingCoHost);
  String get lockRoom => tr('قفل الغرفة', 'Verrouiller la salle', appL10n.meetingLockRoom);
  String get unlockRoom =>
      tr('فتح الغرفة', 'Déverrouiller la salle', appL10n.meetingUnlockRoom);
  String get muteParticipant =>
      tr('كتم الميكروفون', 'Couper le micro', appL10n.meetingMuteMic);
  String get removeParticipant =>
      tr('إخراج من الاجتماع', 'Retirer de la réunion', appL10n.meetingRemove);
  String get copyInviteLink =>
      tr('نسخ رابط الدعوة الآمن', 'Copier le lien d\'invitation', appL10n.meetingCopyInviteLink);
  String get inviteCopied =>
      tr('تم نسخ رمز ومفتاح الاجتماع', 'Invitation copiée', appL10n.meetingInviteCopied);
  String get connectingToSfu => tr(
        'جاري الاتصال بموزع الفيديو الآمن (SFU)...',
        'Connexion au serveur SFU sécurisé...',
        appL10n.meetingConnectingSecureSfuMediaRouter,
      );
  String get retryConnection =>
      tr('إعادة المحاولة', 'Réessayer', appL10n.retryButton);

  String pageIndicator(int current, int total) => tr(
        'صفحة $current من $total',
        'Page $current sur $total',
        appL10n.meetingPageCurrentTotal(current, total),
      );
}
