/// Full RTL/LTR localization strings (Arabic / French / English) for
/// Apolo.ma's SFU Group Meeting module.
library;

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
      tr('الاستعداد للاجتماع', 'Préparation de la réunion', 'Meeting Lobby');
  String get createNewMeeting =>
      tr('اجتماع جماعي جديد', 'Nouvelle réunion de groupe', 'New Group Meeting');
  String get joinExistingMeeting =>
      tr('الانضمام برمز الغرفة', 'Rejoindre avec un code', 'Join with Room Code');
  String get meetingTitleLabel =>
      tr('عنوان الاجتماع', 'Titre de la réunion', 'Meeting Title');
  String get meetingTitleHint => tr(
        'مثال: معاينة جماعية للشقة أو المتجر',
        'Ex : Visite groupée ou consultation',
        'e.g. Live property walkthrough',
      );
  String get roomCodeHint =>
      tr('أدخل رمز الغرفة (apo-xxxx-xxxx)', 'Code salle (apo-xxxx-xxxx)', 'Room code (apo-xxxx-xxxx)');
  String get joinNow =>
      tr('انضمام للاجتماع', 'Rejoindre maintenant', 'Join Meeting');
  String get startMeeting =>
      tr('بدء الاجتماع الآن', 'Démarrer la réunion', 'Start Meeting');
  String get e2eeTitle => tr(
        'تشفير تام بين الأطراف (E2EE)',
        'Chiffrement de bout en bout (E2EE)',
        'End-to-End Encryption (E2EE)',
      );
  String get e2eeSubtitle => tr(
        'خادم الـ SFU يمرر الحزم دون فك تشفير الفيديو أو الصوت أبداً',
        'Le serveur SFU transfère les paquets sans jamais décoder vos flux',
        'SFU forwards encrypted packets without ever seeing your media',
      );
  String get e2eePassphraseLabel => tr(
        'مفتاح التشفير المشترك للغرفة',
        'Clé secrète partagée de la salle',
        'Shared Room Encryption Key',
      );
  String get sfuBadge => tr(
        'SFU + SVC متكيف (حتى 25+ مشارك)',
        'SFU + SVC adaptatif (25+ participants)',
        'Adaptive SFU + SVC (25+ participants)',
      );
  String get micOn => tr('الميكروفون مفعل', 'Micro activé', 'Mic On');
  String get micOff => tr('الميكروفون مكتوم', 'Micro coupé', 'Muted');
  String get camOn => tr('الكاميرا مفعلة', 'Caméra activée', 'Camera On');
  String get camOff => tr('الكاميرا متوقفة', 'Caméra coupée', 'Camera Off');
  String get screenShare =>
      tr('مشاركة الشاشة', 'Partager l\'écran', 'Share Screen');
  String get stopScreenShare =>
      tr('إيقاف المشاركة', 'Arrêter le partage', 'Stop Sharing');
  String get speaker => tr('مكبر الصوت', 'Haut-parleur', 'Speaker');
  String get switchCamera =>
      tr('تبديل الكاميرا', 'Changer de caméra', 'Flip Camera');
  String get participants =>
      tr('المشاركون', 'Participants', 'Participants');
  String get leaveCall => tr('مغادرة', 'Quitter', 'Leave');
  String get endForAll =>
      tr('إنهاء للجميع', 'Terminer pour tous', 'End for All');
  String get reconnectingBanner => tr(
        'ضعف في الاتصال... جاري إعادة الربط تلقائياً عبر أقرب مسار UDP/TURN',
        'Réseau instable... Reconnexion automatique via UDP/TURN en cours',
        'Unstable network... Automatically reconnecting via UDP/TURN',
      );
  String get lowBandwidthBanner => tr(
        'الإنترنت ضعيف: تم تخفيض طبقات الفيديو (SVC) لحماية جودة الصوت والبطارية',
        'Connexion faible : flux vidéo réduit (SVC) pour préserver l\'audio et la batterie',
        'Low bandwidth: video layers stepped down (SVC) to protect audio & battery',
      );
  String get switchToAudioOnly =>
      tr('التحويل لصوت فقط', 'Mode audio uniquement', 'Audio Only');
  String get resumeVideoMode =>
      tr('استئناف الفيديو', 'Réactiver la vidéo', 'Resume Video');
  String get audioOnlyActive => tr(
        'وضع توفير البيانات والبطارية (صوت فقط) مفعل',
        'Mode économie de données et batterie (Audio seul) actif',
        'Data & battery saver (Audio-only) active',
      );
  String get youBadge => tr('أنت', 'Vous', 'You');
  String get hostBadge => tr('مضيف', 'Hôte', 'Host');
  String get cohostBadge => tr('مضيف مساعد', 'Co-hôte', 'Co-host');
  String get lockRoom => tr('قفل الغرفة', 'Verrouiller la salle', 'Lock Room');
  String get unlockRoom =>
      tr('فتح الغرفة', 'Déverrouiller la salle', 'Unlock Room');
  String get muteParticipant =>
      tr('كتم الميكروفون', 'Couper le micro', 'Mute Mic');
  String get removeParticipant =>
      tr('إخراج من الاجتماع', 'Retirer de la réunion', 'Remove');
  String get copyInviteLink =>
      tr('نسخ رابط الدعوة الآمن', 'Copier le lien d\'invitation', 'Copy Invite Link');
  String get inviteCopied =>
      tr('تم نسخ رمز ومفتاح الاجتماع', 'Invitation copiée', 'Invite copied');
  String get connectingToSfu => tr(
        'جاري الاتصال بموزع الفيديو الآمن (SFU)...',
        'Connexion au serveur SFU sécurisé...',
        'Connecting to secure SFU media router...',
      );
  String get retryConnection =>
      tr('إعادة المحاولة', 'Réessayer', 'Retry');

  String pageIndicator(int current, int total) => tr(
        'صفحة $current من $total',
        'Page $current sur $total',
        'Page $current of $total',
      );
}
