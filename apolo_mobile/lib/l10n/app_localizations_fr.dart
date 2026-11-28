// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get chatPlaceholder => 'Écrire au vendeur...';

  @override
  String get chatTypeMessageHint => 'Écrire un message...';

  @override
  String get chatRecordingPlaceholder => 'Enregistrement...';

  @override
  String get chatAddAttachmentTooltip => 'Joindre un fichier';

  @override
  String get chatMessageInputLabel => 'Champ de message';

  @override
  String get chatSendMessageTooltip => 'Envoyer le message';

  @override
  String chatStagedAttachmentLabel(Object name) {
    return 'Pièce jointe prête : $name';
  }

  @override
  String chatRemoveAttachmentLabel(Object name) {
    return 'Retirer la pièce jointe $name';
  }

  @override
  String get chatDismissMessageMenu => 'Fermer le menu du message';

  @override
  String get chatJumpToLatest => 'Voir le dernier';

  @override
  String chatNewMessagesJumpToLatest(Object count, Object messageWord) {
    return '$count nouveau(x) $messageWord. Voir le dernier';
  }

  @override
  String get chatMessageSingular => 'message';

  @override
  String get chatMessagePlural => 'messages';

  @override
  String get chatCallAndOptionsTooltip => 'Options d’appel et de discussion';

  @override
  String get chatSendFailedRetrySemantic =>
      ', Échec de l’envoi, touchez deux fois pour réessayer';

  @override
  String get chatSendingSemantic => ', Envoi en cours';

  @override
  String get chatEditedLabel => 'Modifié';

  @override
  String get chatRetrySendingTooltip => 'Renvoyer le message';

  @override
  String get chatTypingIndicatorLabel => 'Écrit...';

  @override
  String get chatPhotoPreviewLabel => '📷 Photo';

  @override
  String get chatVoicePreviewLabel => '🎤 Message vocal';

  @override
  String get voiceMicMutedIdleSemantic =>
      'Micro coupé. Aucun son détecté. Maintenez le bouton micro pour enregistrer';

  @override
  String get voiceHoldToRecordSemantic =>
      'Maintenez pour enregistrer un vocal. Glissez à gauche pour annuler, vers le haut pour verrouiller';

  @override
  String get voiceMicMutedSuffixSemantic => '. Attention : micro coupé';

  @override
  String voiceReleaseToCancelSemantic(Object mutedSuffix) {
    return 'Relâchez pour annuler l’enregistrement$mutedSuffix';
  }

  @override
  String voiceLockedRecordingSemantic(Object timeStr, Object mutedSuffix) {
    return 'Enregistrement verrouillé, $timeStr$mutedSuffix. Appuyez sur STOP pour terminer';
  }

  @override
  String voiceActiveRecordingSemantic(Object timeStr, Object mutedSuffix) {
    return 'Enregistrement vocal, $timeStr$mutedSuffix. Glissez à gauche pour annuler, en haut pour verrouiller';
  }

  @override
  String get voiceWaveformMutedSemantic => 'Onde audio plate, micro coupé';

  @override
  String get voiceWaveformPreviewSemantic =>
      'Aperçu interactif du message vocal';

  @override
  String get voiceWaveformLiveSemantic => 'Onde audio en direct';

  @override
  String get voiceMicMutedWarningSemantic =>
      'Attention : micro coupé, aucun son détecté.';

  @override
  String get voiceMicMutedBadge => 'Micro coupé';

  @override
  String get voiceCancelRecordingTooltip => 'Annuler l’enregistrement vocal';

  @override
  String get voicePauseRecordingTooltip =>
      'Mettre en pause l’enregistrement ou l’aperçu';

  @override
  String get voicePlayPreviewTooltip => 'Écouter l’aperçu vocal';

  @override
  String get voiceSendVoiceMessageTooltip => 'Envoyer le message vocal';

  @override
  String get voiceReleaseToCancelLabel => 'Relâcher pour annuler';

  @override
  String get voiceSlideToCancelLabel => 'Glisser pour annuler';

  @override
  String get voiceHoldMicPrompt =>
      'Maintenez le micro pour enregistrer un vocal';

  @override
  String get voiceRecordButtonSemantic => 'Enregistrer un message vocal';

  @override
  String get voiceRecordGestureHint =>
      'Touchez ou maintenez pour enregistrer. Glissez pour annuler ou verrouiller';

  @override
  String get voiceWaveformScrubberSemantic =>
      'Curseur de lecture du message vocal';

  @override
  String get voiceChatTitle => 'Chat vocal';

  @override
  String get voiceMicPermissionRequired =>
      'L’accès au microphone est requis pour enregistrer de l’audio.';

  @override
  String get voiceCouldNotStartRecording =>
      'Impossible de démarrer l’enregistrement sur cet appareil.';

  @override
  String get voiceTapMicEmptyPrompt =>
      'Appuyez sur le micro ci-dessous pour enregistrer un message vocal';

  @override
  String get voiceTapMicInputHint =>
      'Touchez le micro pour enregistrer un vocal...';

  @override
  String get voiceToggleWaveformTooltip => 'Basculer le mode d’onde audio';

  @override
  String get voiceToggleThemeTooltip => 'Basculer le thème GTA 6';

  @override
  String get otpVerifyCodeTitle => 'Vérifiez votre code';

  @override
  String otpEnterSixDigitCode(Object destination) {
    return 'Saisissez le code à 6 chiffres envoyé à $destination';
  }

  @override
  String get otpCodeVerifiedLabel => 'Code vérifié';

  @override
  String get otpIncorrectCodeError => 'Code incorrect, réessayez';

  @override
  String otpResendCodeCountdown(Object seconds) {
    return 'Renvoyer dans ${seconds}s';
  }

  @override
  String get otpResendCodeButton => 'Renvoyer le code';

  @override
  String get welcomeContinueAsGuestLabel => 'Continuer en invité';

  @override
  String get authEmailPlaceholder => 'example@gmail.com';

  @override
  String get authPasswordPlaceholder => 'Mot de passe';

  @override
  String get authFullNamePlaceholder => 'Nom';

  @override
  String get authUsernameHandlePlaceholder => '@username';

  @override
  String get authPlainUsernamePlaceholder => 'username';

  @override
  String get moroccoPhonePlaceholder => '+212 6XX XXX XXX';

  @override
  String likeButtonSemantic(Object count) {
    return 'J’aime, $count mentions J’aime';
  }

  @override
  String unlikeButtonSemantic(Object count) {
    return 'Retirer J’aime, $count mentions J’aime';
  }

  @override
  String get likeSyncFailedSemantic =>
      'Échec de l’enregistrement. Touchez pour réessayer';

  @override
  String get pullToRefreshRefreshing => 'Actualisation de la liste';

  @override
  String get pullToRefreshRelease => 'Relâchez pour actualiser';

  @override
  String get pullToRefreshPullDown => 'Tirez vers le bas pour actualiser';

  @override
  String get badgeOnlineSemantic => 'En ligne';

  @override
  String get badgeUnreadNotificationSemantic => 'Notification non lue';

  @override
  String get badgeUnreadMaxSemantic => '99+ notifications non lues';

  @override
  String badgeUnreadCountSemantic(Object count, Object notificationWord) {
    return '$count $notificationWord non lue(s)';
  }

  @override
  String get notificationSingular => 'notification';

  @override
  String get notificationPlural => 'notifications';

  @override
  String emojiReactWithSemantic(Object emoji) {
    return 'Réagir avec $emoji';
  }

  @override
  String get emojiFewerTooltip => 'Moins d’émojis';

  @override
  String get emojiMoreTooltip => 'Plus d’émojis';

  @override
  String get listingFavoriteTooltip => 'Ajouter l’annonce aux favoris';

  @override
  String get accommodationFavoriteTooltip => 'Ajouter le logement aux favoris';

  @override
  String listingBedroomsCount(Object bedrooms) {
    return '$bedrooms chambres';
  }

  @override
  String get listingTaxesIncluded => 'taxes incl.';

  @override
  String accommodationTotalForNights(Object total, Object nights) {
    return '$total au total · $nights nuits';
  }

  @override
  String get boostActionLabel => 'Booster';

  @override
  String get liveBadgeLabel => 'EN DIRECT';

  @override
  String get meetingEncryptionKeyHint => 'Clé secrète AES-GCM 256-bit';

  @override
  String get meetingDefaultTitle => 'Réunion Apolo';

  @override
  String get meetingDefaultParticipantName => 'Participant SFU';

  @override
  String get bugReportSafetyHeader => 'Sécurité Apolo.ma';

  @override
  String get bugReportDescMinLengthError =>
      'La description doit contenir au moins 5 caractères.';

  @override
  String get bugReportNetworkFailedError => 'Échec de la requête réseau.';

  @override
  String get bugReportTimeoutError =>
      'Délai dépassé. Vérifiez votre connexion et réessayez.';

  @override
  String get bugReportServerUnreachableError =>
      'Impossible de joindre les serveurs Apolo.ma pour le moment.';

  @override
  String get meetingSignInRequiredError =>
      'Veuillez vous connecter pour rejoindre la réunion.';

  @override
  String get meetingPermissionDeniedError =>
      'Vous n’avez pas accès à cette réunion.';

  @override
  String get meetingAlreadyEndedError => 'Cette réunion est déjà terminée.';

  @override
  String get meetingRoomLockedError =>
      'Cette salle est verrouillée par l’hôte.';

  @override
  String get meetingMaxCapacityError =>
      'La capacité maximale de participants est atteinte.';

  @override
  String get meetingServiceUnreachableError =>
      'Impossible de joindre le service de réunion. Vérifiez votre connexion.';

  @override
  String get accountOnboardingFormFinishSettingUpAccount =>
      'Complétez votre compte';

  @override
  String get accountOnboardingFormChooseCityInterestsYouCan =>
      'Choisissez votre ville et vos centres d’intérêt. Vous pourrez passer en compte Business gratuitement à tout moment.';

  @override
  String get accountOnboardingFormCity => 'Ville';

  @override
  String get accountOnboardingFormChooseAtLeastOneInterest =>
      'Choisissez au moins un centre d’intérêt';

  @override
  String get accountOnboardingFormSaveContinue => 'Enregistrer et continuer';

  @override
  String get accountOnboardingFormReloadOptions => 'Recharger les choix';

  @override
  String get navHome => 'Accueil';

  @override
  String get navExplore => 'Explorer';

  @override
  String get sellItemButton => 'Publier';

  @override
  String get navStores => 'Boutiques';

  @override
  String get navMessages => 'Messages';

  @override
  String get navProfile => 'Profil';

  @override
  String get categoriesTitle => 'Catégories';

  @override
  String get featuredAdsTitle => 'Sélection VIP';

  @override
  String get latestAdsTitle => 'Dernières annonces';

  @override
  String get allCitiesFilter => 'Toutes les villes';

  @override
  String get allCategoriesFilter => 'Toutes les catégories';

  @override
  String get loginButton => 'Se connecter';

  @override
  String get createAccountButton => 'Créer un compte';

  @override
  String get logoutButton => 'Déconnexion';

  @override
  String get callSellerButton => 'Appeler';

  @override
  String get whatsappButton => 'WhatsApp';

  @override
  String get chatInAppButton => 'Discuter';

  @override
  String get boostAdButton => 'Booster VIP';

  @override
  String get deleteAccountButton => 'Supprimer le compte';

  @override
  String get reportAdButton => 'Signaler l\'annonce';

  @override
  String get blockUserButton => 'Bloquer l\'utilisateur';

  @override
  String get searchHint => 'Rechercher une voiture, appartement, téléphone...';

  @override
  String get noAdsFoundMessage => 'Aucune annonce trouvée';

  @override
  String get appStateDark => 'Sombre';

  @override
  String get appStateSystem => 'Système';

  @override
  String get appStateLight => 'Clair';

  @override
  String get appStateApoloMember => 'Membre Apolo';

  @override
  String get appStateJustNow => 'À l’instant';

  @override
  String get appStateKm => 'km';

  @override
  String get bugReportReportTechnicalProblem =>
      'Signaler un problème technique';

  @override
  String get bugReportIfFeatureProductIsnT =>
      'Si une fonctionnalité ne marche pas correctement, vos retours nous aident à améliorer Apolo.ma.';

  @override
  String get bugReportReportProblem => 'Signaler un problème';

  @override
  String get bugReportReportsAboutAbuseSpamShouldn =>
      'Les signalements d\'abus ou de spam ne doivent pas être envoyés ici.';

  @override
  String get bugReportLearnHowReportAbuseSpam =>
      'Découvrez comment signaler une fraude, du spam, du contenu interdit ou un problème de sécurité.';

  @override
  String get bugReportShakePhoneReportProblem =>
      'Secouer le téléphone pour signaler un problème';

  @override
  String get bugReportEnabledMobileSensorsDesktopBrowser =>
      'Activé sur mobile (capteur indisponible sur navigateur bureau)';

  @override
  String get bugReportToggleEnable => 'Désactivé';

  @override
  String get bugReportToggleOffDisable =>
      'Désactiver pour couper le déclenchement par secousse';

  @override
  String get bugReportReportTechnicalProblem2 =>
      'Signaler un problème technique';

  @override
  String get bugReportLearnMoreAboutReportingAbuse =>
      'En savoir plus sur le signalement d\'abus ou de spam';

  @override
  String get bugReportWouldYouLikeIncludeAdditional =>
      'Souhaitez-vous inclure les journaux et diagnostics supplémentaires ?';

  @override
  String get bugReportAlwaysCollectedBasicContext =>
      'Contexte de base toujours inclus :';

  @override
  String get bugReportAuthenticatedUserIdIfSigned =>
      'Votre identifiant utilisateur (si connecté), la version et le build de l\'app, la plateforme/OS, l\'écran actuel et la langue/direction (RTL/LTR).';

  @override
  String get bugReportOptionalDiagnosticsOnlyAttachedIf =>
      'Diagnostics optionnels (envoyés uniquement avec votre accord) :';

  @override
  String get bugReportRecentMemoryLogBufferNavigation =>
      'Tampon récent des journaux en mémoire, traces de navigation/erreurs API (sans jetons ni mots de passe) et métadonnées d\'affichage.';

  @override
  String get bugReportIncludeContinue => 'Inclure et continuer';

  @override
  String get bugReportDonTIncludeContinue => 'Ne pas inclure et continuer';

  @override
  String get sendButton => 'Envoyer';

  @override
  String get bugReportBrieflyExplainWhatHappenedWhat =>
      'Expliquez brièvement ce qui s\'est passé ou ce qui ne fonctionne pas.';

  @override
  String get bugReportScreenshot => 'Capture';

  @override
  String get bugReportUpload => 'Importer';

  @override
  String get bugReportRemoveScreenshot => 'Supprimer la capture';

  @override
  String get bugReportPreviewScreenshot => 'Aperçu de la capture';

  @override
  String get bugReportAutoCaptureWasnTAvailable =>
      'Capture automatique indisponible sur cette vue — utilisez Importer.';

  @override
  String get bugReportPleaseDescribeWhatHappenedBefore =>
      'Veuillez décrire brièvement le problème avant d\'envoyer.';

  @override
  String get bugReportPleaseWriteAtLeast5 =>
      'Veuillez saisir au moins 5 caractères pour décrire le problème.';

  @override
  String get bugReportImageExceeds5MbMaximum =>
      'L\'image dépasse la taille maximale autorisée (5 Mo).';

  @override
  String get bugReportUnsupportedImageFormatPleaseChoose =>
      'Format non pris en charge. Choisissez JPEG, PNG ou WebP.';

  @override
  String get bugReportCouldNotReadSelectedImage =>
      'Impossible de lire l\'image sélectionnée.';

  @override
  String get retryButton => 'Réessayer';

  @override
  String get closeButton => 'Fermer';

  @override
  String bugReportThanksTechnicalReportHasBeen(Object reportId) {
    return 'Merci ! Votre rapport technique a bien été envoyé (#$reportId)';
  }

  @override
  String get bugReportThanksTechnicalReportHasBeen2 =>
      'Merci ! Votre rapport technique a bien été envoyé.';

  @override
  String get bugReportCouldNotSendReportRight =>
      'Impossible d\'envoyer le rapport. Vérifiez votre connexion et réessayez.';

  @override
  String bugReportTooManyReportsSentRecently(Object seconds) {
    return 'Trop de signalements envoyés. Réessayez dans $seconds secondes.';
  }

  @override
  String get bugReportTooManyReportsSentRecently2 =>
      'Trop de signalements envoyés. Veuillez patienter un instant.';

  @override
  String get bugReportReportingAbuseSpamSafetyIssues =>
      'Signaler un abus, un spam ou une fraude';

  @override
  String get bugReportThisFormIsStrictlyTechnical =>
      'Ce formulaire est réservé aux bugs techniques. Pour signaler une annonce suspecte, un message abusif ou une fraude sur Apolo.ma, utilisez le bouton « Signaler » sur l\'annonce ou la conversation, ou envoyez un signalement de sécurité ci-dessous.';

  @override
  String get bugReportOpenSafetyAbuseReport =>
      'Ouvrir le signalement de sécurité';

  @override
  String get bugReportFoundBugBrokenScreenSend =>
      'Un bug ou un écran bloqué ? Envoyez un rapport technique avec capture d\'écran.';

  @override
  String get meetingLobby => 'Préparation de la réunion';

  @override
  String get meetingNewGroupMeeting => 'Nouvelle réunion de groupe';

  @override
  String get meetingJoinRoomCode => 'Rejoindre avec un code';

  @override
  String get meetingTitle => 'Titre de la réunion';

  @override
  String get meetingEGLivePropertyWalkthrough =>
      'Ex : Visite groupée ou consultation';

  @override
  String get meetingRoomCodeApoXxxxXxxx => 'Code salle (apo-xxxx-xxxx)';

  @override
  String get meetingJoinMeeting => 'Rejoindre maintenant';

  @override
  String get meetingStartMeeting => 'Démarrer la réunion';

  @override
  String get meetingEndEndEncryptionE2ee =>
      'Chiffrement de bout en bout (E2EE)';

  @override
  String get meetingSfuForwardsEncryptedPacketsWithout =>
      'Le serveur SFU transfère les paquets sans jamais décoder vos flux';

  @override
  String get meetingSharedRoomEncryptionKey =>
      'Clé secrète partagée de la salle';

  @override
  String get meetingAdaptiveSfuSvc25Participants =>
      'SFU + SVC adaptatif (25+ participants)';

  @override
  String get meetingMicOn => 'Micro activé';

  @override
  String get meetingMuted => 'Micro coupé';

  @override
  String get meetingCameraOn => 'Caméra activée';

  @override
  String get meetingCameraOff => 'Caméra coupée';

  @override
  String get meetingShareScreen => 'Partager l\'écran';

  @override
  String get meetingStopSharing => 'Arrêter le partage';

  @override
  String get meetingSpeaker => 'Haut-parleur';

  @override
  String get meetingFlipCamera => 'Changer de caméra';

  @override
  String get meetingParticipants => 'Participants';

  @override
  String get meetingLeave => 'Quitter';

  @override
  String get meetingEndAll => 'Terminer pour tous';

  @override
  String get meetingUnstableNetworkAutomaticallyReconnectingVia =>
      'Réseau instable... Reconnexion automatique via UDP/TURN en cours';

  @override
  String get meetingLowBandwidthVideoLayersStepped =>
      'Connexion faible : flux vidéo réduit (SVC) pour préserver l\'audio et la batterie';

  @override
  String get meetingAudioOnly => 'Mode audio uniquement';

  @override
  String get meetingResumeVideo => 'Réactiver la vidéo';

  @override
  String get meetingDataBatterySaverAudioOnly =>
      'Mode économie de données et batterie (Audio seul) actif';

  @override
  String get meetingYou => 'Vous';

  @override
  String get meetingHost => 'Hôte';

  @override
  String get meetingCoHost => 'Co-hôte';

  @override
  String get meetingLockRoom => 'Verrouiller la salle';

  @override
  String get meetingUnlockRoom => 'Déverrouiller la salle';

  @override
  String get meetingMuteMic => 'Couper le micro';

  @override
  String get meetingRemove => 'Retirer de la réunion';

  @override
  String get meetingCopyInviteLink => 'Copier le lien d\'invitation';

  @override
  String get meetingInviteCopied => 'Invitation copiée';

  @override
  String get meetingConnectingSecureSfuMediaRouter =>
      'Connexion au serveur SFU sécurisé...';

  @override
  String meetingPageCurrentTotal(Object current, Object total) {
    return 'Page $current sur $total';
  }

  @override
  String get accountSecurityEnterValidEmailAddress =>
      'Entrez une adresse e-mail valide.';

  @override
  String get accountSecurityEnterValidPhoneNumber =>
      'Entrez un numéro marocain valide.';

  @override
  String get accountSecurityContactDetailsUpdatedSuccessfully =>
      'Coordonnées mises à jour avec succès.';

  @override
  String get accountSecurityPasswordMustBeAtLeast =>
      'Le mot de passe doit contenir au moins 8 caractères.';

  @override
  String get accountSecurityPasswordsDoNotMatch =>
      'Les mots de passe ne correspondent pas.';

  @override
  String get accountSecurityPasswordUpdatedSuccessfully =>
      'Mot de passe mis à jour avec succès.';

  @override
  String get accountSecurityAccountSecurity => 'Sécurité du compte';

  @override
  String get accountSecurityStayControlLogin => 'Gardez la main sur vos accès';

  @override
  String get accountSecurityUpdatePasswordEmailPhoneDirectly =>
      'Mettez à jour votre mot de passe, votre adresse e-mail ou votre numéro directement ici.';

  @override
  String get accountSecurityContactDetails => 'Coordonnées';

  @override
  String get accountSecurityEmailAddress => 'Adresse e-mail';

  @override
  String get accountSecurityPhoneNumber => 'Numéro de téléphone';

  @override
  String get accountSecuritySaveContactDetails => 'Enregistrer les coordonnées';

  @override
  String get accountSecurityChangePassword => 'Modifier le mot de passe';

  @override
  String get accountSecurityCurrentPassword => 'Mot de passe actuel';

  @override
  String get accountSecurityNewPassword => 'Nouveau mot de passe';

  @override
  String get accountSecurityConfirmNewPassword =>
      'Confirmer le nouveau mot de passe';

  @override
  String get accountSecurityUpdatePassword => 'Mettre à jour le mot de passe';

  @override
  String get accountSecuritySecurityOptions => 'Options de sécurité';

  @override
  String get accountSecuritySignUpdateThisInformation =>
      'Connectez-vous dans l’application pour modifier ces informations';

  @override
  String get accountSetupCreateAccount => 'Créer un compte';

  @override
  String get accountSetupAccountType => 'Type de compte';

  @override
  String get accountSetupChooseAtLeastOneProfile =>
      'Choisissez au moins un type de profil pour personnaliser votre configuration.';

  @override
  String get continueButton => 'Continuer';

  @override
  String get adDetailHiIsThisStillAvailable =>
      'Cet article est-il toujours disponible ?';

  @override
  String get adDetailCouldNotUpdateFavoritesPlease =>
      'Impossible de modifier les favoris. Réessayez.';

  @override
  String get adDetailPhoneNumberCopied => 'Numéro copié';

  @override
  String get adDetailCopy => 'Copier';

  @override
  String get adDetailCouldNotStartConversationPlease =>
      'Impossible de démarrer la conversation. Réessayez.';

  @override
  String get adDetailUserBlocked => 'Utilisateur bloqué';

  @override
  String get adDetailReportThisListingAiContent =>
      'Signaler cette annonce / contenu IA';

  @override
  String get adDetailQuickReviewByTrustSafety =>
      'Vérification rapide par notre équipe';

  @override
  String get adDetailHideAllListingsFromThis =>
      'Masquer les annonces de ce vendeur';

  @override
  String get adDetailDetails => 'Détails';

  @override
  String get adDetailListingUnavailable => 'Annonce introuvable';

  @override
  String get adDetailThisItemMayHaveBeen =>
      'Cet article a peut-être été vendu ou retiré.';

  @override
  String get adDetailGoBack => 'Retour';

  @override
  String get adDetailCategory => 'Catégorie';

  @override
  String get adDetailCondition => 'État';

  @override
  String get adDetailNotSpecified => 'Non précisé';

  @override
  String get adDetailReference => 'Référence';

  @override
  String get backButton => 'Retour';

  @override
  String get adDetailFavorite => 'Favori';

  @override
  String get adDetailMore => 'Plus';

  @override
  String get adDetailFree => 'Gratuit';

  @override
  String get adDetailOnRequest => 'Sur demande';

  @override
  String get negotiableBadge => 'Négociable';

  @override
  String get fixedPriceBadge => 'Prix affiché';

  @override
  String get adDetailGuests => 'Voyageurs';

  @override
  String get adDetailBedrooms => 'Chambres';

  @override
  String get adDetailBeds => 'Lits';

  @override
  String get adDetailBaths => 'Bains';

  @override
  String get adDetailGood => 'Bon';

  @override
  String get adDetailRef => 'Réf.';

  @override
  String get adDetailViews => 'Vues';

  @override
  String get adDetailGuestFavourite => 'En vedette';

  @override
  String get adDetailVideoTour => 'Visite vidéo';

  @override
  String adDetailJustListedMMAgo(Object m) {
    return 'Publié · il y a $m min';
  }

  @override
  String adDetailJustListedHHoursAgo(Object h) {
    return 'Publié · il y a ${h}h';
  }

  @override
  String adDetailDDaysAgo(Object d) {
    return 'Il y a ${d}j';
  }

  @override
  String get adDetailJustListed => 'Vient d’être publié';

  @override
  String get adDetailBoostThisListing => 'Booster cette annonce ⚡';

  @override
  String get adDetailMessageSeller => 'Contacter le vendeur';

  @override
  String get adDetailFastReply => 'Réponse rapide';

  @override
  String get adDetailWriteMessage => 'Écrivez votre message...';

  @override
  String get adDetailAlertsEnabledSimilarListings =>
      'Alertes activées pour des annonces similaires';

  @override
  String get adDetailAlertsPaused => 'Alertes désactivées';

  @override
  String get adDetailAlerts => 'Alertes';

  @override
  String get adDetailMessage => 'Message';

  @override
  String get shareButton => 'Partager';

  @override
  String get saveButton => 'Enregistrer';

  @override
  String get adDetailNoDescriptionProvidedMessageSeller =>
      'Le vendeur n’a pas ajouté de description. Contactez-le pour en savoir plus.';

  @override
  String get adDetailDescription => 'Description';

  @override
  String get adDetailSeeLess => 'Voir moins';

  @override
  String get adDetailSeeMore => 'Lire la suite';

  @override
  String get adDetailCallSeller => 'Appeler le vendeur';

  @override
  String adDetailApoloStoreCityname(Object cityName) {
    return 'Boutique Apolo · $cityName';
  }

  @override
  String adDetailApoloSellerCityname(Object cityName) {
    return 'Vendeur Apolo · $cityName';
  }

  @override
  String get adDetailBusinessStore => 'Boutique';

  @override
  String get adDetailSeller => 'Vendeur';

  @override
  String get adDetailSeeReviews => 'Voir les avis';

  @override
  String get followingButton => 'Suivi';

  @override
  String get followButton => 'Suivre';

  @override
  String get adDetailYourRating => 'Votre avis publié';

  @override
  String get adDetailRateThisSeller => 'Évaluer ce vendeur';

  @override
  String get adDetailEditReview => 'Modifier';

  @override
  String get adDetailWriteReview => 'Donner un avis';

  @override
  String get adDetailLocation => 'Localisation';

  @override
  String adDetailZoneDistkmKm(Object distKm) {
    return 'Dans votre zone · $distKm km';
  }

  @override
  String adDetailDistkmKmAway(Object distKm) {
    return 'À $distKm km';
  }

  @override
  String get adDetailLocationIsApproximate =>
      'La localisation est approximative';

  @override
  String get adDetailFullMap => 'Voir la carte';

  @override
  String get adDetailRelatedSearches => 'Recherches similaires';

  @override
  String get adDetailIfYouDonTLike => 'Si vous n’aimez pas ceci, vous pouvez ';

  @override
  String get adDetailHideThisListing => 'masquer cette annonce';

  @override
  String get adDetailWeLlShowYouFewer =>
      ' et nous vous en montrerons moins de ce type.';

  @override
  String get adDetailListingHiddenFromFeed =>
      'Annonce masquée de vos recommandations';

  @override
  String get adDetailListingRestored => 'Affichage rétabli';

  @override
  String get adDetailHidden => 'Masquée';

  @override
  String get adDetailHideListing => 'Masquer l’annonce';

  @override
  String get adDetailReportSafety => 'Signaler / Sécurité';

  @override
  String get adDetailSimilarListings => 'Annonces similaires';

  @override
  String get adDetailAllReviews => 'Tous les avis';

  @override
  String get adDetailSellerRating => 'Note du vendeur';

  @override
  String get adDetailEditReview2 => 'Modifier votre avis';

  @override
  String get adDetailWriteReview2 => 'Donner un avis';

  @override
  String adDetailSellerReviewsTotalcount(Object totalCount) {
    return 'Avis sur le vendeur ($totalCount)';
  }

  @override
  String get adDetailShowAll => 'Tout afficher';

  @override
  String get adDetail5Stars => '5 étoiles';

  @override
  String get filtersTitle => 'Filtres';

  @override
  String get adDetailHighest => 'Meilleurs';

  @override
  String get adDetailSort => 'Trier';

  @override
  String adDetailNoWrittenReviewsSellernameYet(Object sellerName) {
    return 'Aucun avis publié pour $sellerName pour le moment';
  }

  @override
  String get adDetailHelpful => 'Utile';

  @override
  String get addFriendsJoinMeApoloMaMorocco =>
      'Rejoins-moi sur Apolo.ma — la marketplace au Maroc : https://apolo.ma';

  @override
  String get addFriendsAddFriends => 'Ajouter des amis';

  @override
  String get addFriendsInvited => 'Invité';

  @override
  String get addFriendsInvite => 'Inviter';

  @override
  String get addFriendsContacts => 'Contacts';

  @override
  String get authUnableOpenGoogleSignRight =>
      'Impossible d’ouvrir Google sign-in pour le moment.';

  @override
  String get authUnableStartGoogleSign =>
      'Impossible de démarrer la connexion Google.';

  @override
  String get authNoEmailAddressIsLinked =>
      'Aucune adresse e-mail n’est associée à ce compte pour recevoir le code.';

  @override
  String authVerificationCodeWasSentMasked(Object masked) {
    return 'Un code de vérification a été envoyé à $masked.';
  }

  @override
  String get authPleaseEnterValidEmailAddress =>
      'Veuillez saisir une adresse e-mail valide';

  @override
  String get authPasswordMustBeAtLeast =>
      'Votre mot de passe doit contenir au moins 8 caractères';

  @override
  String get authPleaseEnterNameAtLeast =>
      'Veuillez saisir votre nom (au moins 2 caractères)';

  @override
  String get authUsernameMustBeAtLeast =>
      'Le nom d’utilisateur doit contenir au moins 3 lettres ou chiffres';

  @override
  String get authPleaseEnterValidMoroccanPhone =>
      'Veuillez saisir un numéro marocain valide (ex : 650-123456)';

  @override
  String get authEnter6DigitVerificationCode =>
      'Entrez le code de vérification à 6 chiffres.';

  @override
  String authNewVerificationCodeWasSent(Object masked) {
    return 'Un nouveau code a été envoyé à $masked.';
  }

  @override
  String get authNewVerificationCodeWasSent2 =>
      'Un nouveau code a été envoyé à votre boîte e-mail.';

  @override
  String authBasevalueTriedAtHhMm(Object baseValue, Object hh, Object mm) {
    return '$baseValue (Dernière tentative : $hh:$mm)';
  }

  @override
  String get signUpButton => 'S’inscrire';

  @override
  String get authEnterEmail => 'Entrez votre e-mail';

  @override
  String get authEnterPassword => 'Entrez votre mot de passe';

  @override
  String get authForgotPassword => 'Mot de passe oublié ?';

  @override
  String get authWhatSEmail => 'Quelle est votre adresse e-mail ?';

  @override
  String get authChoosePassword => 'Choisissez un mot de passe';

  @override
  String get authWhatSFirstName => 'Quel est votre prénom ?';

  @override
  String get authPickUsername => 'Choisissez un nom d’utilisateur';

  @override
  String get authOthersCanFindYouUsername =>
      'Les autres peuvent vous trouver grâce à votre nom d’utilisateur !';

  @override
  String get authWhatSPhoneNumber => 'Quel est votre numéro de téléphone ?';

  @override
  String get authEnterValidMoroccanPhoneNumber =>
      'Entrez un numéro marocain valide pour sécuriser votre compte';

  @override
  String authWeSent6DigitVerification(Object maskedEmail) {
    return 'Nous avons envoyé un code à 6 chiffres à $maskedEmail';
  }

  @override
  String get authWeSent6DigitVerification2 =>
      'Nous avons envoyé un code à 6 chiffres à votre e-mail';

  @override
  String get authEnterVerificationCode => 'Entrez le code de vérification';

  @override
  String get authSending => 'Envoi...';

  @override
  String authResendCodeRemainingS(Object remaining) {
    return 'Renvoyer (${remaining}s)';
  }

  @override
  String get businessSwitchWelcomeStoreApoloHowCan =>
      'Bienvenue dans notre boutique sur Apolo ! Comment pouvons-nous vous aider ?';

  @override
  String get businessSwitchPleaseEnterStoreNameAt =>
      'Veuillez saisir le nom de votre boutique (au moins 2 caractères).';

  @override
  String get businessSwitchPleaseEnterStoreName =>
      'Veuillez saisir le nom de votre boutique.';

  @override
  String get businessSwitchBusinessProfileUpdated =>
      'Paramètres de la boutique enregistrés !';

  @override
  String get businessSwitchVerifiedBusinessStoreIsNow =>
      'Félicitations ! Votre boutique Business vérifiée est active';

  @override
  String get businessSwitchCouldNotSaveBusinessProfile =>
      'Impossible d’enregistrer pour le moment. Réessayez.';

  @override
  String get businessSwitchBusinessSettings => 'Paramètres Business';

  @override
  String get businessSwitchSwitchBusiness => 'Passer au compte Business';

  @override
  String get businessSwitchPreviousStoreDetailsAreReady =>
      'Vos informations de boutique précédentes ont été restaurées !';

  @override
  String get savingLabel => 'Enregistrement...';

  @override
  String get businessSwitchSaveChanges => 'Enregistrer';

  @override
  String get businessSwitchActivateFreeBusiness =>
      'Activer Business gratuitement';

  @override
  String get businessSwitchWhatBestDescribesBusiness =>
      'Quelle est votre catégorie d’activité ?';

  @override
  String get businessSwitchThisCategoryBadgeAppearsUnder =>
      'Cette catégorie s’affichera sur votre profil professionnel et votre boutique.';

  @override
  String get businessSwitchStoreIdentityHoursLocation =>
      'Identité, horaires et localisation';

  @override
  String get businessSwitchStoreAppearsStoresDirectoryOnce =>
      'Votre boutique apparaît automatiquement dès que vous avez au moins une annonce active.';

  @override
  String get businessSwitchStoreName => 'Nom de la boutique *';

  @override
  String get businessSwitchEGAutoCasa => 'Ex: Auto Luxury Casa';

  @override
  String get businessSwitchBioDescription => 'Description de la boutique';

  @override
  String get businessSwitchTellCustomersAboutProductsService =>
      'Présentez vos produits, garanties et livraison...';

  @override
  String get businessSwitchCityAddress => 'Ville et adresse';

  @override
  String get businessSwitchEGMaarifCasablanca => 'Ex: Maarif, Casablanca';

  @override
  String get businessSwitchGoogleMapsLinkOptional =>
      'Lien Google Maps (optionnel)';

  @override
  String get businessSwitchWorkingHours => 'Horaires d’ouverture';

  @override
  String get businessSwitchContactDirectOrderTools =>
      'Outils de contact et commande directe';

  @override
  String get businessSwitchEnable1TapOrdersAutomatic =>
      'Facilitez les commandes directes et les réponses rapides dans le chat.';

  @override
  String get businessSwitchBusinessPhone => 'Téléphone professionnel';

  @override
  String get businessSwitchEnableDirectOrderButtonStore =>
      'Activer le bouton « Commande directe »';

  @override
  String get businessSwitchReceiveInstantOrdersCustomerDetails =>
      'Recevez les commandes clients avec nom, ville et téléphone.';

  @override
  String get businessSwitchAutoGreetingMessageChat =>
      'Message d’accueil automatique (Chat)';

  @override
  String get businessSwitchWelcomeStoreHowCanWe =>
      'Bienvenue dans notre boutique !';

  @override
  String get callIncomingVideoCall => 'Appel vidéo entrant...';

  @override
  String get callIncomingVoiceCall => 'Appel vocal entrant...';

  @override
  String get callRinging => 'Sonnerie...';

  @override
  String get callAllowMicCameraAccess => 'Veuillez autoriser le micro/caméra';

  @override
  String get callConnecting => 'Connexion...';

  @override
  String get callCalls => 'Appels';

  @override
  String get callCallsAreUnavailableThisDevice =>
      'Appels indisponibles sur cet appareil';

  @override
  String get callBackChat => 'Revenir à la conversation';

  @override
  String get callVideoCall => 'Appel vidéo';

  @override
  String get callVoiceCall => 'Appel vocal';

  @override
  String get callDecline => 'Refuser';

  @override
  String get callAccept => 'Accepter';

  @override
  String get callMic => 'Micro';

  @override
  String get callCamera => 'Caméra';

  @override
  String get callEnd => 'Terminer';

  @override
  String chatListLastMessageLasttime(Object lastTime) {
    return 'Dernier message $lastTime';
  }

  @override
  String get chatListUnpinChat => 'Désépingler';

  @override
  String get chatListPinChat => 'Épingler';

  @override
  String get chatListChatUnpinned => 'Discussion désépinglée';

  @override
  String get chatListChatPinnedTop => 'Discussion épinglée';

  @override
  String get chatListMarkAsRead => 'Marquer comme lu';

  @override
  String get chatListUnmuteNotifications => 'Réactiver les alertes';

  @override
  String get chatListMuteNotifications => 'Mettre en sourdine';

  @override
  String get chatListNotificationsUnmuted => 'Notifications réactivées';

  @override
  String get chatListChatMuted => 'Discussion mise en sourdine';

  @override
  String get chatListArchiveChat => 'Archiver la discussion';

  @override
  String get chatListChatArchived => 'Discussion archivée';

  @override
  String get chatListReportChat => 'Signaler la discussion';

  @override
  String chatListBlockPeername(Object peerName) {
    return 'Bloquer $peerName';
  }

  @override
  String chatListBlockedPeername(Object peerName) {
    return '$peerName a été bloqué';
  }

  @override
  String get chatListDeleteChat => 'Supprimer la discussion';

  @override
  String get chatListChatDeleted => 'Discussion supprimée';

  @override
  String get chatListSelectConversationStartMessaging =>
      'Sélectionnez une discussion';

  @override
  String get chatListChats => 'Discussions';

  @override
  String get chatListMarkAllRead => 'Tout lire';

  @override
  String get searchTitle => 'Rechercher';

  @override
  String get chatListAll => 'Tout';

  @override
  String get chatListUnread => 'Non lus';

  @override
  String get chatListPinned => 'Épinglés';

  @override
  String get chatListSignViewChats =>
      'Connectez-vous pour voir vos discussions';

  @override
  String get chatListMessageBuyersSellersDirectlySecurely =>
      'Échangez directement avec les vendeurs et acheteurs en toute sécurité.';

  @override
  String get signInButton => 'Se connecter';

  @override
  String get chatListNoUnreadChats => 'Aucun message non lu';

  @override
  String get chatListNoPinnedChats => 'Aucune discussion épinglée';

  @override
  String get chatListNoChatsYet => 'Aucune discussion pour le moment';

  @override
  String get chatListBrowseListingsMessageSellersDirectly =>
      'Parcourez les annonces et discutez directement avec les vendeurs.';

  @override
  String get chatListExploreListings => 'Parcourir les annonces';

  @override
  String get chatListPersonalMessagesAreEndEnd =>
      'Vos messages personnels sont chiffrés de bout en bout';

  @override
  String get chatRoomFailedLoadMessagesPleaseTry =>
      'Chargement impossible. Réessayez.';

  @override
  String get chatRoomMessageEdited => 'Message modifié';

  @override
  String get chatRoomDeletedEveryone => 'Message supprimé pour tout le monde';

  @override
  String get chatRoomMessagePinned => 'Message épinglé';

  @override
  String get chatRoomMessageUnpinned => 'Désépinglé';

  @override
  String get chatRoomMessageStarred => 'Message suivi ⭐';

  @override
  String get chatRoomStarRemoved => 'Étoile retirée';

  @override
  String get chatRoomReportConversation => 'Signaler la conversation';

  @override
  String get chatRoomUserUnblocked => 'Utilisateur débloqué';

  @override
  String chatRoomUnblockPeername(Object peerName) {
    return 'Débloquer $peerName';
  }

  @override
  String get chatRoomReply => 'Répondre';

  @override
  String get chatRoomUnpin => 'Désépingler';

  @override
  String get chatRoomPin => 'Épingler';

  @override
  String get chatRoomUnstar => 'Retirer l\'étoile';

  @override
  String get chatRoomStar => 'Marquer d\'une étoile';

  @override
  String get chatRoomCopied => 'Copié';

  @override
  String get editButton => 'Modifier';

  @override
  String get reportButton => 'Signaler';

  @override
  String get deleteButton => 'Supprimer pour moi';

  @override
  String get chatRoomDeleteEveryone => 'Supprimer pour tous';

  @override
  String get chatRoomMorocco => 'Maroc';

  @override
  String chatRoomMyLocationResolvedcity(Object resolvedCity) {
    return '📍 Ma position : $resolvedCity';
  }

  @override
  String chatRoomPriceOfferTitleDhCleaned(Object title, Object cleaned) {
    return '💰 Offre pour \"$title\" : $cleaned DH';
  }

  @override
  String chatRoomPriceOfferDhCleaned(Object cleaned) {
    return '💰 Offre de prix : $cleaned DH';
  }

  @override
  String get chatRoomCouldNotCaptureAudioPlease =>
      'Impossible d\'enregistrer l\'audio. Autorisez le microphone et réessayez.';

  @override
  String get chatRoomVoiceMessageIsTooLong =>
      'Message vocal trop long. Essayez un enregistrement plus court.';

  @override
  String get chatRoomThisMessageWasDeleted => 'Ce message a été supprimé';

  @override
  String get chatRoomRead => 'Lu';

  @override
  String get chatRoomDelivered => 'Distribué';

  @override
  String chatRoomLastSeenClock(Object clock) {
    return 'Vu à $clock';
  }

  @override
  String get chatRoomOffline => 'Hors ligne';

  @override
  String get chatRoomVideoCallUnavailable => 'Appel vidéo — indisponible';

  @override
  String get chatRoomVoiceCallUnavailable => 'Appel vocal — indisponible';

  @override
  String get chatRoomSafetyReport => 'Sécurité et signalement';

  @override
  String get chatRoomYouBlockedThisUser => 'Vous avez bloqué cet utilisateur';

  @override
  String get chatRoomUnblock => 'Débloquer';

  @override
  String get chatRoomEditingMessage => 'Modifier le message';

  @override
  String get chatRoomSendMessage => 'Envoyer un message';

  @override
  String get editProfileMinimum3CharactersRequired =>
      'Minimum 3 caractères requis';

  @override
  String editProfileCleanIsAvailable(Object clean) {
    return '@$clean est disponible';
  }

  @override
  String get editProfileAlreadyTaken => 'Déjà utilisé.';

  @override
  String get editProfileProfilePhoto => 'Photo de profil';

  @override
  String get editProfileChooseFromLibrary => 'Choisir depuis la galerie';

  @override
  String get editProfileTakePhoto => 'Prendre une photo';

  @override
  String get editProfileRemoveCurrentPhoto => 'Supprimer la photo actuelle';

  @override
  String get editProfileChoosePresetAvatar => 'Ou choisir un avatar rapide';

  @override
  String get editProfileSelectCity => 'Choisir votre ville';

  @override
  String get clearButton => 'Effacer';

  @override
  String get editProfilePhoneWhatsapp => 'Téléphone & WhatsApp';

  @override
  String get confirmButton => 'Confirmer';

  @override
  String get editProfileNameIsRequired => 'Le nom est requis.';

  @override
  String get editProfileUsernameMustBeAtLeast =>
      'Le nom d’utilisateur doit contenir au moins 3 caractères.';

  @override
  String get editProfileThisUsernameIsAlreadyTaken =>
      'Ce nom d’utilisateur est déjà pris.';

  @override
  String get editProfileCouldNotSaveChangesPlease =>
      'Enregistrement impossible. Réessayez.';

  @override
  String get editProfileTitle => 'Modifier le profil';

  @override
  String get editProfileEditPicture => 'Modifier la photo';

  @override
  String get editProfileFullName => 'Votre nom complet';

  @override
  String get editProfileUsername => 'Nom d’utilisateur';

  @override
  String get editProfileBio => 'Biographie';

  @override
  String get editProfileWriteShortBioAboutYourself =>
      'Présentez-vous en quelques mots...';

  @override
  String get editProfileAddCity => 'Ajouter une ville';

  @override
  String get editProfilePhone => 'Téléphone';

  @override
  String get editProfileAddPhoneNumber => 'Ajouter un numéro';

  @override
  String get editProfileManageStoreDetails => 'Paramètres de la boutique';

  @override
  String get editProfileGetVerifiedBusinessStore => 'Badge vérifié & Boutique';

  @override
  String get editProfilePersonalInformation => 'Infos personnelles';

  @override
  String get editProfileEmailPasswordSettings => 'Email et mot de passe';

  @override
  String get saveChangesButton => 'Enregistrer';

  @override
  String forgotPasswordWeSent6DigitVerification(Object masked) {
    return 'Nous avons envoyé un code à 6 chiffres à $masked.';
  }

  @override
  String get forgotPasswordPleaseEnter6DigitVerification =>
      'Veuillez saisir le code à 6 chiffres.';

  @override
  String get forgotPasswordPasswordUpdatedSignedSuccessfully =>
      'Mot de passe mis à jour. Bienvenue !';

  @override
  String get forgotPasswordYouWillReceiveEmailSet =>
      'Vous recevrez un e-mail pour définir un nouveau mot de passe';

  @override
  String get forgotPasswordChooseNewPassword =>
      'Choisissez un nouveau mot de passe';

  @override
  String get homeInternetConnectionLost => 'Connexion Internet interrompue';

  @override
  String get homeCheckNetworkConnectionTryAgain =>
      'Vérifiez votre connexion réseau et réessayez pour charger les annonces.';

  @override
  String get tryAgainButton => 'Réessayer';

  @override
  String get homeWelcomeApolo => 'Bienvenue sur Apolo';

  @override
  String get homeSearchCarsHomesPhonesAccounts =>
      'Rechercher voitures, immo, téléphones...';

  @override
  String get homeLatestListings => 'Dernières annonces';

  @override
  String get homeSeeAll => 'Tout voir';

  @override
  String homeNoListingsWithinZoneradiuskmKm(Object zoneRadiusKm, Object s) {
    return 'Aucune annonce dans un rayon de $zoneRadiusKm km autour de $s';
  }

  @override
  String get homeShowAllMorocco => 'Tout le Maroc';

  @override
  String get homeChangeZone => 'Changer de zone';

  @override
  String get homeBrowseAllListingsMorocco =>
      'Explorer toutes les annonces au Maroc';

  @override
  String get home1MarketplaceMorocco => 'Marketplace #1 au Maroc 🇲🇦';

  @override
  String get homeBuySellSafelyWithoutMiddlemen =>
      'Achetez et vendez en toute sécurité';

  @override
  String get homeCarsPhonesRealEstateDiscover =>
      'Voitures, smartphones, immobilier près de chez vous.';

  @override
  String get homeExclusiveDeals => 'Offres exclusives';

  @override
  String get homeWhyChooseApolo => 'Pourquoi choisir Apolo ?';

  @override
  String get home0CommissionFree => '0% Commission';

  @override
  String get homeBuySellFreeZeroMiddlemen =>
      'Vendez et achetez gratuitement sans aucun intermédiaire.';

  @override
  String get homeDirectChatCall => 'Discussion directe';

  @override
  String get homeMessageSellerDirectlyMakeOffer =>
      'Discutez en direct avec le vendeur et négociez le prix.';

  @override
  String get homeVerifiedListings => 'Annonces vérifiées';

  @override
  String get homeContinuousReviewKeepAllTransactions =>
      'Contrôle continu pour des transactions en toute sécurité.';

  @override
  String get homeGotSomethingSellPostNow =>
      'Un article à vendre ? Publiez maintenant';

  @override
  String get homePublishFree30SecondsGet =>
      'Publiez gratuitement et recevez des offres rapidement';

  @override
  String get homePost => 'Publier +';

  @override
  String get homeVerifiedOfficialStores => 'Boutiques Pro Vérifiées';

  @override
  String get homeBrowseDealsFromCertifiedStores =>
      'Découvrez les offres des professionnels certifiés';

  @override
  String get intentOnboardingWhatWillYouUseApolo =>
      'Comment allez-vous\nutiliser Apolo ?';

  @override
  String get mainShellYouHaveNewApoloNotification =>
      'Vous avez une nouvelle notification Apolo';

  @override
  String get mainShellBrowse => 'Annonces';

  @override
  String get notificationsEnableNotifications => 'Activer les notifications';

  @override
  String get notificationsAreBlocked => 'Notifications désactivées';

  @override
  String get notificationsPleaseEnableNotificationsPhoneBrowser =>
      'Autorisez les notifications dans les réglages de votre appareil ou navigateur puis appuyez sur Continuer.';

  @override
  String get notificationsGotIt => 'Compris';

  @override
  String get notificationsNotificationPreferences => 'Préférences d’alertes';

  @override
  String get notificationsChooseWhichApoloAlertsYou =>
      'Choisissez les alertes à recevoir sur Apolo';

  @override
  String get notificationsMessagesBuyerOffers => 'Messages & offres acheteurs';

  @override
  String get notificationsInstantAlertWhenBuyerMessages =>
      'Alerte instantanée dès qu’un acheteur écrit';

  @override
  String get notificationsPriceDropsSavedListings =>
      'Baisses de prix & favoris';

  @override
  String get notificationsUpdatesListingsYouBookmarked =>
      'Mises à jour sur vos annonces enregistrées';

  @override
  String get notificationsOfficialStoresUpdates =>
      'Boutiques officielles & actus';

  @override
  String get notificationsNewArrivalsFromVerifiedSellers =>
      'Nouveautés des vendeurs vérifiés suivis';

  @override
  String get notificationsMarkAllAsRead => 'Tout marquer comme lu';

  @override
  String get doneButton => 'Terminé';

  @override
  String get notificationsPleaseAllowNotificationsContinue =>
      'Veuillez appuyer sur « Autoriser » pour activer les alertes';

  @override
  String get notificationsActivatedInstantAlerts =>
      ' avez activé les alertes en direct sur ';

  @override
  String get notificationsApoloMaBuyerMessagesOffers =>
      'Apolo.ma — Messages & Offres';

  @override
  String get notificationsJustNow => 'maintenant';

  @override
  String get notificationsApoloTeam => 'Équipe Apolo';

  @override
  String get notificationsSharedTipAddClearPhotos =>
      ' : Ajoutez des photos nettes à votre annonce pour vendre plus vite.';

  @override
  String get notifications2hAgo => 'Aujourd\'hui';

  @override
  String get notificationsApoloOfficialStores => 'Boutiques Apolo PRO';

  @override
  String get notificationsUpdated => ' a mis à jour ';

  @override
  String get notificationsVerifiedCarsRealEstateTech =>
      'les annonces vérifiées Auto, Immo & Tech';

  @override
  String get notificationsAcrossAllMoroccanCities =>
      ' dans toutes les villes du Maroc.';

  @override
  String get notificationsThisWeek => 'Cette semaine';

  @override
  String get notificationsNotifications => 'Notifications';

  @override
  String get notificationsHeyItSApolo => 'Bonjour, c’est Apolo !';

  @override
  String get notificationsIAmReadyHelpYou =>
      'Je suis prêt à vous alerter dès qu’un message arrive. Et vous ?';

  @override
  String get notificationsNow => 'maintenant';

  @override
  String get notificationsNotification => 'Notifications';

  @override
  String get notificationsActivateNotificationsReceiveMessages =>
      'Activez les notifications pour recevoir des messages';

  @override
  String get notificationsUpdates => 'Activité';

  @override
  String get notificationsNoNotificationsThisCategory =>
      'Aucune notification dans cet onglet';

  @override
  String get notificationsBuyerMessagesOffersListingUpdates =>
      'Les messages acheteurs et mises à jour apparaîtront ici.';

  @override
  String get notificationsNoInternetConnection => 'Aucune connexion Internet';

  @override
  String get notificationsCheckWiFiMobileData =>
      'Vérifiez votre connexion Wi-Fi ou mobile pour actualiser vos notifications.';

  @override
  String get notificationsToday => 'Aujourd\'hui';

  @override
  String get postAdCouldNotDetectGpsLocation =>
      'Détection GPS impossible — choisissez votre ville';

  @override
  String get postAdPleaseSelectCategoryCity =>
      'Veuillez choisir une catégorie et une ville';

  @override
  String get postAdAddAtLeastOnePhoto =>
      'Ajoutez au moins une photo de votre article';

  @override
  String get postAdEnterClearTitleAtLeast =>
      'Saisissez un titre clair (au moins 3 caractères)';

  @override
  String get postAdEnterValidPriceFreeVerify =>
      'Indiquez un prix valide ou Gratuit et vérifiez le téléphone';

  @override
  String postAdDailyFreeLimitReachedMaxdailyfreeads(Object maxDailyFreeAds) {
    return 'Limite gratuite atteinte ($maxDailyFreeAds annonces/jour)';
  }

  @override
  String postAdPersonalAccountsIncludeUpMaxdailyfreeads(
      Object maxDailyFreeAds, Object monthlyPremiumPriceMad) {
    return 'Le compte Personnel inclut $maxDailyFreeAds annonces gratuites par jour. Passez à Apolo Premium ($monthlyPremiumPriceMad DH/mois via Google Pay) pour publier en illimité avec boutique Business et badge Verified.';
  }

  @override
  String postAdSubscribeMonthlypremiumpricemadMadMoGoogle(
      Object monthlyPremiumPriceMad) {
    return 'S’abonner ($monthlyPremiumPriceMad DH/mois) • Google Pay';
  }

  @override
  String get postAdMaybeLater => 'Plus tard';

  @override
  String get postAdPleaseSignPublishListing =>
      'Veuillez vous connecter pour publier votre annonce';

  @override
  String get postAdAvailableGreatConditionApolo =>
      'Disponible en très bon état sur Apolo.ma';

  @override
  String get postAdFailedPublishListing =>
      'Échec de la publication de votre annonce';

  @override
  String get postAdCategoriesCitiesUnavailableRetry =>
      'Catégories et villes indisponibles. Réessayer';

  @override
  String get postAdUnlimitedDailyAdsApoloPremium =>
      'Annonces illimitées · Apolo Premium';

  @override
  String postAdMaxdailyfreeadsMaxdailyfreeads2DailyLimitReached(
      Object maxDailyFreeAds,
      Object maxDailyFreeAds2,
      Object monthlyPremiumPriceMad) {
    return 'Limite $maxDailyFreeAds/$maxDailyFreeAds2 atteinte · Premium $monthlyPremiumPriceMad DH';
  }

  @override
  String postAdTodayTodaypostedadscountMaxdailyfreeadsFreeAds(
      Object todayPostedAdsCount, Object maxDailyFreeAds) {
    return 'Quota gratuit : $todayPostedAdsCount/$maxDailyFreeAds aujourd’hui · Illimité en Premium';
  }

  @override
  String get postAdWhereAreYouListing => 'Où souhaitez-vous publier ?';

  @override
  String get postAdChooseCategoryCitySoNearby =>
      'Choisissez la catégorie et votre ville pour cibler les acheteurs';

  @override
  String get postAdAddClearPhotos => 'Ajoutez des photos nettes';

  @override
  String get postAdListingsRealClearPhotosSell =>
      'Les annonces avec photos réelles se vendent 3x plus vite';

  @override
  String get postAdDescribeItem => 'Décrivez votre article';

  @override
  String get postAdClearTitleHonestDescriptionBuild =>
      'Un titre précis et une description honnête inspirent confiance';

  @override
  String get postAdSetPriceContact => 'Fixez votre prix et contact';

  @override
  String get postAdSetFairPriceReviewListing =>
      'Indiquez un prix attractif et vérifiez l\'aperçu avant de publier';

  @override
  String get postAdGpsLocationSet => 'Position GPS enregistrée';

  @override
  String get postAdDetectAdLocationGps => 'Détecter la position (GPS)';

  @override
  String get postAdTapAddPhotos => 'Appuyez pour ajouter des photos';

  @override
  String postAdAddMorePhotosTotalphotos8(Object totalPhotos) {
    return 'Ajouter plus de photos ($totalPhotos/8)';
  }

  @override
  String get postAdFirstPhotoWillBeUsed =>
      'La première photo sera la couverture principale';

  @override
  String get postAdGallery => 'Galerie';

  @override
  String get postAdSelectedPhotos => 'Photos sélectionnées';

  @override
  String get postAdCover => 'Principale';

  @override
  String get postAdListingTitle => 'Titre de l\'annonce';

  @override
  String get postAdGreat => 'Parfait ✓';

  @override
  String get postAdEGIphone15Pro => 'Ex: iPhone 15 Pro Max 256Go comme neuf';

  @override
  String get postAdDetailedDescription => 'Description détaillée';

  @override
  String get postAdMentionConditionIncludedAccessoriesKey =>
      'Précisez l\'état, les accessoires et les détails importants...';

  @override
  String get postAdSpecifications => 'Caractéristiques spécifiques';

  @override
  String get postAdPriceMad => 'Prix (en MAD)';

  @override
  String get postAdEG2500 => 'Ex: 2500';

  @override
  String get postAdHideNumber => 'Masquer le numéro';

  @override
  String get postAdListingPreview => 'Aperçu de votre annonce';

  @override
  String get postAdPublishNow => 'Publier mon annonce';

  @override
  String get postAdListingUpdated => 'Annonce mise à jour';

  @override
  String get postAdListingIsLive => 'Félicitations ! Annonce publiée';

  @override
  String get postAdListingIsNowVisibleBuyers =>
      'Votre annonce est maintenant visible par les acheteurs sur Apolo.ma.';

  @override
  String get postAdNewListing => 'Votre nouvelle annonce';

  @override
  String get postAdBackHome => 'Retour à l\'accueil';

  @override
  String get postAdPostAnotherListing => 'Publier une autre annonce';

  @override
  String get privacyComplianceReportAiPolicyIssue =>
      'Signaler un contenu IA / Règles';

  @override
  String get privacyComplianceSelectReasonSubmitThisReport =>
      'Conformément aux règles App Store et Google Play, sélectionnez le motif du signalement :';

  @override
  String get privacyComplianceAdditionalDetailsOptional =>
      'Détails supplémentaires (optionnel)...';

  @override
  String get privacyComplianceSubmitReport => 'Envoyer le signalement';

  @override
  String get privacyComplianceCouldNotSendReportPlease =>
      'Signalement non envoyé. Réessayez.';

  @override
  String get privacyComplianceReportSubmittedSuccessfully =>
      'Signalement envoyé avec succès ✓';

  @override
  String privacyComplianceLinkCopiedUrl(Object url) {
    return 'Lien copié : $url';
  }

  @override
  String get privacyComplianceConfirmAccountDeletion =>
      'Confirmer la suppression du compte';

  @override
  String get privacyComplianceAreYouSureYouWant =>
      'Voulez-vous vraiment supprimer définitivement votre compte, vos données personnelles, vos annonces et vos messages des serveurs Apolo.ma ?';

  @override
  String get cancelButton => 'Annuler';

  @override
  String get privacyComplianceDeletePermanently => 'Supprimer définitivement';

  @override
  String get privacyComplianceAccountDataHaveBeenDeleted =>
      'Votre compte et vos données ont été supprimés.';

  @override
  String get privacyComplianceCouldNotConfirmDeletionYou =>
      'Suppression non confirmée. Vous restez connecté. Réessayez.';

  @override
  String get privacyCompliancePrivacyPolicies => 'Confidentialité & Conditions';

  @override
  String get privacyCompliancePrivacy => 'Confidentialité';

  @override
  String get privacyCompliancePolicies => 'Conditions';

  @override
  String get privacyComplianceDataDelete => 'Données';

  @override
  String get privacyComplianceUpdated2026Law0908 =>
      'Mis à jour 2026 · Loi 09-08 (CNDP)';

  @override
  String get privacyCompliancePrivacyFullyControl =>
      'Vos données restent sous votre contrôle';

  @override
  String get privacyComplianceWeNeverSellPersonalData =>
      'Nous ne vendons jamais vos données personnelles. Vos informations servent uniquement à vos annonces, messages et notifications sur Apolo (ma.apolo.apoloMobile).';

  @override
  String get privacyComplianceDataWeCollect => 'Données collectées';

  @override
  String get privacyComplianceAccountIdentityNameEmailPhone =>
      '• Compte & Identité : Nom, e-mail, téléphone ou authentification Google / Apple.\n• Annonces & Boutiques : Photos, titres, descriptions, prix et ville choisie.\n• Messagerie : Messages, images et réactions échangés entre acheteurs et vendeurs.\n• Jetons de notification (FCM / APNs) : Pour recevoir vos alertes mobiles, désactivés automatiquement à la déconnexion.';

  @override
  String get privacyComplianceDevicePermissionsControls =>
      'Autorisations de l’appareil';

  @override
  String get privacyComplianceNotificationsOptionalOsAlertsNew =>
      '• Notifications : Optionnelles pour les nouveaux messages sur iOS et Android.\n• Caméra & Photos : Utilisées uniquement lors de l’ajout d’images à une annonce ou un message.\n• Localisation approximative : Filtrage par ville/zone sans suivi en arrière-plan.';

  @override
  String get privacyComplianceAiSafetyAppReporting =>
      'Sécurité IA & Signalement';

  @override
  String get privacyComplianceSmartListingSearchToolsInclude =>
      'L’application intègre un bouton de signalement direct permettant de signaler tout contenu généré par IA ou toute annonce inappropriée.';

  @override
  String get privacyComplianceLegalRightsContact =>
      'Vos droits & Contact (CNDP)';

  @override
  String get privacyComplianceUnderMoroccanLaw0908 =>
      'Conformément à la loi marocaine 09-08 et aux règles App Store / Google Play, vous disposez d’un droit d’accès, de rectification et de suppression.\n• Email : support@apolo.ma / contact@apolo.ma\n• Site web : https://apolo.ma';

  @override
  String get privacyComplianceReportAiPolicyIssueApp =>
      'Signaler un contenu dans l’application';

  @override
  String get privacyComplianceOpenWebPrivacyPolicy => 'Ouvrir la politique web';

  @override
  String get privacyComplianceTermsUseMarketplaceRules =>
      'Conditions Générales 2026';

  @override
  String get privacyComplianceClearRulesSafeBuyingSelling =>
      'Des règles claires pour acheter et vendre en confiance';

  @override
  String get privacyComplianceByUsingApoloYouAgree =>
      'En utilisant Apolo.ma, vous acceptez nos règles de publication, de messagerie respectueuse et de sécurité.';

  @override
  String get privacyComplianceAccountIntegrityVerifiedBadges =>
      'Authenticité du compte & Badges';

  @override
  String get privacyComplianceAccountStoreDetailsMustRemain =>
      '• Les informations du profil et de la boutique doivent être exactes.\n• Le badge vérifié et les rangs vendeurs (Bronze à Champion) sont attribués uniquement par Apolo ; toute usurpation est interdite.';

  @override
  String get privacyComplianceListingRulesProhibitedItems =>
      'Règles d’annonces & Produits interdits';

  @override
  String get privacyComplianceListingsMustRepresentRealItems =>
      '• Chaque annonce doit présenter un bien réel avec des photos authentiques et un prix honnête.\n• Sont strictement interdits : contrefaçons, armes, substances illicites, médicaments sur ordonnance, documents officiels et arnaques.';

  @override
  String get privacyComplianceSafeTransactionsChatConduct =>
      'Transactions sûres & Messagerie';

  @override
  String get privacyComplianceAlwaysInspectItemsPersonSafe =>
      '• Privilégiez les rencontres dans un lieu public et ne versez jamais d’acompte avant d’avoir vérifié l’article.\n• Le spam et le harcèlement sont interdits ; bloquez ou signalez tout abus en un geste.';

  @override
  String get privacyComplianceProSubscriptionsListingBoosts =>
      'Abonnements Pro+ & Boosts';

  @override
  String get privacyComplianceProPlansBoostUpgradesAre =>
      '• Les offres Pro+ et Boost sont facturées de manière transparente via l’App Store ou Google Play.\n• Vous pouvez annuler le renouvellement automatique jusqu’à 24h avant l’échéance dans les réglages de votre store.';

  @override
  String get privacyComplianceOpenWebTermsPolicies =>
      'Ouvrir les conditions sur le web';

  @override
  String get privacyComplianceInstantErasureAppStorePlay =>
      'Suppression directe · App Store & Play';

  @override
  String get privacyCompliancePermanentAccountDataDeletion =>
      'Suppression définitive du compte et des données';

  @override
  String get privacyComplianceEraseAccountAllAssociatedPersonal =>
      'Effacez votre compte et toutes vos données directement dans l’application, ou via notre lien web dédié.';

  @override
  String get privacyComplianceWhatGetsPermanentlyDeleted =>
      'Données supprimées immédiatement';

  @override
  String get privacyComplianceProfileCredentialsNameEmailPhone =>
      '• Informations du profil (nom, e-mail, téléphone et liaison OAuth).\n• Toutes vos annonces publiées, photos et données de boutique.\n• Historique des discussions, favoris et jetons de notifications mobiles.';

  @override
  String get privacyComplianceDeleteMyAccountNowApp =>
      'Supprimer mon compte maintenant (In-App)';

  @override
  String get privacyComplianceSignDeleteAccountDirectlyApp =>
      'Connectez-vous pour supprimer votre compte dans l’app, ou utilisez le lien externe ci-dessous.';

  @override
  String get privacyComplianceExternalWebDataDeletionLink =>
      'Lien web externe de suppression';

  @override
  String get proPlusRecurringBillingCancelAnytimePayment =>
      'Facturation récurrente, annulable à tout moment. Le paiement est débité via Google Pay / Store à la confirmation et se renouvelle automatiquement sauf résiliation 24h avant l’échéance.\nVos données sont protégées selon nos ';

  @override
  String get proPlusTermsConditions => 'conditions générales';

  @override
  String get proPlusAnd => ' et la ';

  @override
  String get proPlusPrivacyPolicy => 'politique de confidentialité';

  @override
  String get proPlusSubscription => 'Abonnement';

  @override
  String get proPlusCancelPremiumSubscription =>
      'Résilier votre abonnement Pro Plus ?';

  @override
  String get proPlusAutoRenewalWillBeTurned =>
      'Le renouvellement automatique sera désactivé tout en conservant votre boutique.';

  @override
  String get proPlusCancelMySubscription => 'Confirmer la résiliation';

  @override
  String get proPlusKeepPremium => 'Garder Pro Plus';

  @override
  String get proPlusYouUsePremium => 'Vous utilisez Pro Plus';

  @override
  String get proPlusGetPremium => 'Passez à Pro Plus';

  @override
  String get proPlusYouHaveUnlimitedAccessAll =>
      'Vous avez un accès illimité à toutes les fonctionnalités Pro Plus';

  @override
  String get proPlusGetUnlimitedAccessAllPremium =>
      'Profitez d’un accès illimité à toutes les fonctionnalités Pro Plus';

  @override
  String get proPlusCheckedAccountActivePurchases =>
      'Vérification des achats effectuée.';

  @override
  String get proPlusHowTrialWorks => 'Comment fonctionne votre essai';

  @override
  String proPlusUnlimitedFreeAccess3Days(Object monthlyPremiumPriceMad) {
    return 'Accès gratuit illimité pendant 3 jours, puis $monthlyPremiumPriceMad DH/mois via Google Pay';
  }

  @override
  String get proPlusGetInstantAccessSeeHow =>
      'Profitez immédiatement du badge PRO+ et des boosts gratuits.';

  @override
  String get proPlusDay2 => 'Jour 2';

  @override
  String get proPlusWeLlRemindYouNotification =>
      'Nous vous rappellerons par notification la fin proche de l’essai.';

  @override
  String get proPlusDay3 => 'Jour 3';

  @override
  String get proPlusYouLlBeChargedDay =>
      'Facturation le 3e jour, annulable gratuitement à tout moment avant.';

  @override
  String get proPlusViewAllPlans => 'Voir toutes les offres';

  @override
  String get proPlusRestorePurchases => 'Restaurer les achats';

  @override
  String get proPlusStartFree3DayTrial => 'Essayer 3 jours gratuitement';

  @override
  String get proPlusPaymentVerificationFailed =>
      'Vérification du paiement échouée.';

  @override
  String get proPlusProPlusActivatedStoreIs =>
      'Félicitations ! Abonnement Pro Plus activé avec succès';

  @override
  String get proPlusCouldNotLaunchGooglePay =>
      'Impossible d’ouvrir Google Pay sur cet appareil.';

  @override
  String get proPlusPayGooglePay => 'Payer avec Google Pay';

  @override
  String get proPlusSave25 => '-25%';

  @override
  String get proPlusLifetime => 'À vie';

  @override
  String get proPlusBasic => 'Basic';

  @override
  String get proPlus12Months => '12 mois';

  @override
  String get proPlusOneTime => 'Unique';

  @override
  String get proPlus1Month => '1 mois';

  @override
  String get proPlusMad => 'DH';

  @override
  String get proPlusPaywall => 'Offres Pro Plus';

  @override
  String get proPlusUnlockFullAccess => 'Débloquez l’accès complet';

  @override
  String get proPlusUnlimitedAccessAllFeaturesTemplates =>
      'Accès illimité au badge vérifié, visibilité maximale et boosts VIP';

  @override
  String get proPlusOfficialBusinessStoreBlueVerified =>
      'Boutique Business officielle + badge bleu Verified';

  @override
  String get proPlusUnlimitedDailyListingsInstead5 =>
      'Annonces illimitées par jour (au lieu de 5/j) + 12 photos';

  @override
  String get proPlus5FreeMonthlyVipBoosts =>
      '5 boosts VIP gratuits/mois + statistiques & réponses rapides';

  @override
  String proPlusSubscribePricedisplayMadGooglePay(Object priceDisplay) {
    return 'S’abonner ($priceDisplay DH) • Google Pay';
  }

  @override
  String get proPlusNoThankYou => 'Non, merci';

  @override
  String get profileCouldNotLoadListingsPull =>
      'Impossible de charger les annonces. Réessayez en actualisant.';

  @override
  String get profileMyAccount => 'Mon compte';

  @override
  String get profileSettingsSupport => 'Paramètres et assistance';

  @override
  String get profileSignManageListingsSavedItems =>
      'Connectez-vous pour gérer vos annonces, vos favoris et vos messages.';

  @override
  String get profileSignViewProfile => 'Connectez-vous pour voir votre profil';

  @override
  String get welcomeCreateAccountButton => 'Créer un compte';

  @override
  String get profileLightMode => 'Mode clair';

  @override
  String get profileDarkMode => 'Mode sombre';

  @override
  String get profileListings => 'Annonces';

  @override
  String get profileLikes => 'Favoris';

  @override
  String get profileSaved => 'Enregistrés';

  @override
  String get shareProfileButton => 'Partager le profil';

  @override
  String get profileMyListings => 'Mes annonces';

  @override
  String get profileProInsightsBoost => 'Tableau Pro & Boost';

  @override
  String profileUpgradeApoloPremiumMonthlypremiumpricemadMad(
      Object monthlyPremiumPriceMad) {
    return 'Passer à Apolo Premium · $monthlyPremiumPriceMad DH/mois';
  }

  @override
  String get profileBusinessStoreVerifiedBadgeUnlimited =>
      'Boutique Business + badge Verified + annonces illimitées via Google Pay.';

  @override
  String get profileViewStore => 'Voir boutique';

  @override
  String get profileEditStore => 'Gérer boutique';

  @override
  String get profileQuickReplies => 'Réponses rapides';

  @override
  String get profileNoListingsYet => 'Aucune annonce publiée';

  @override
  String get profilePublishFirstListingShowcaseIt =>
      'Publiez votre première annonce pour l’afficher ici.';

  @override
  String get profilePostListing => 'Publier une annonce';

  @override
  String get profileTotalViews => 'Vues totales';

  @override
  String get profileActiveListings => 'Annonces actives';

  @override
  String get profileAvgListing => 'Moy. / annonce';

  @override
  String get profileBoostedListings => 'Annonces Boost';

  @override
  String get profileCallTaps => 'Appels reçus';

  @override
  String get profileCustomerChats => 'Conversations';

  @override
  String get profileDirectOrders => 'Commandes directes';

  @override
  String get profileFreeVipCredits => 'Crédits VIP offerts';

  @override
  String get profileUnlockCallOrderStatsPro =>
      'Débloquez les stats d’appels & commandes + PRO+';

  @override
  String get profileGet3FreeVipBoosts =>
      '3 Boosts VIP gratuits/mois et priorité d’affichage.';

  @override
  String get profileViewsBreakdown => 'Répartition des vues';

  @override
  String get profileLive => 'En direct';

  @override
  String get profilePublishFirstListingTrackViews =>
      'Publiez votre première annonce pour suivre vos vues ici.';

  @override
  String get profileTopPerformingListings => 'Vos meilleures annonces';

  @override
  String get profileViews => 'vues';

  @override
  String get profileSalesTip => 'Conseil de vente';

  @override
  String get profileAddClearPhotosFairPrice =>
      'Ajoutez des photos nettes et un prix clair pour attirer plus d’acheteurs.';

  @override
  String get profileRefreshingPhotosBoostingTopListing =>
      'Mettre à jour vos photos ou booster votre meilleure annonce accélère la vente.';

  @override
  String get profileEditListing => 'Modifier l’annonce';

  @override
  String get profileBoostThisListing => 'Booster cette annonce';

  @override
  String get profileDeleteListing => 'Supprimer l’annonce';

  @override
  String get profileCouldNotDeleteListingPlease =>
      'Impossible de supprimer l’annonce. Réessayez.';

  @override
  String get profileDeleteThisListing => 'Supprimer cette annonce ?';

  @override
  String get profileThisListingWillBePermanently =>
      'Cette annonce sera définitivement retirée de votre profil et des résultats.';

  @override
  String get profileListingDeletedSuccessfully =>
      'Annonce supprimée avec succès';

  @override
  String get scanProfileCodeThisIsOwnProfile => 'Ceci est déjà votre profil';

  @override
  String scanProfileCodeApoloMemberSellerid(Object sellerId) {
    return 'Membre Apolo #$sellerId';
  }

  @override
  String get scanProfileCodeScannedCode => 'Code scanné';

  @override
  String get scanProfileCodeCodeDetected => 'Code détecté';

  @override
  String get scanProfileCodeOpenLink => 'Ouvrir le lien';

  @override
  String get scanProfileCodeScanAgain => 'Scanner encore';

  @override
  String get scanProfileCodeFlashlightIsUnavailableThisBrowser =>
      'Le flash n’est pas pris en charge sur ce navigateur';

  @override
  String get scanProfileCodeFlashlightIsUnavailableThisCamera =>
      'Le flash est indisponible sur cet appareil';

  @override
  String get scanProfileCodeCouldNotToggleFlashlightRight =>
      'Impossible d’activer le flash pour le moment';

  @override
  String get scanProfileCodeNoQrCodeDetectedSelected =>
      'Aucun code QR détecté dans cette image';

  @override
  String get scanProfileCodeEnterCode => 'Saisir';

  @override
  String get scanProfileCodeCouldNotOpenPhotoLibrary =>
      'Impossible d’ouvrir la galerie';

  @override
  String get scanProfileCodeScanQrCode => 'Scanner le code QR';

  @override
  String get scanProfileCodePickQrImage => 'Choisir une image';

  @override
  String get scanProfileCodeTapEnableCamera => 'Appuyez pour activer la caméra';

  @override
  String get scanProfileCodeEnterCodeManually => 'Saisir le code manuellement';

  @override
  String get scanProfileCodePleaseEnterLinkHandle =>
      'Veuillez saisir un lien valide';

  @override
  String get scanProfileCodePasteApoloProfileLinkEnter =>
      'Collez un lien Apolo ou saisissez @identifiant';

  @override
  String get scanProfileCodeOpenProfile => 'Ouvrir le profil';

  @override
  String get searchRecommended => 'Recommandé';

  @override
  String get searchNewest => 'Plus récents';

  @override
  String get searchLowestPrice => 'Prix croissant';

  @override
  String get searchHighestPrice => 'Prix décroissant';

  @override
  String get searchMostViewed => 'Populaires';

  @override
  String get searchFilterSort => 'Filtrer et trier';

  @override
  String get resetButton => 'Réinitialiser';

  @override
  String get searchSortBy => 'Trier par';

  @override
  String get searchAllMorocco => 'Tout le Maroc';

  @override
  String get searchPriceRangeMad => 'Fourchette de prix (DH)';

  @override
  String get searchMinPrice => 'Prix min';

  @override
  String get searchMaxPrice => 'Prix max';

  @override
  String get searchNegotiableListingsOnly => 'Annonces négociables uniquement';

  @override
  String get searchApplyFilters => 'Appliquer les filtres';

  @override
  String get searchSignSaveSearchesListings =>
      'Connectez-vous pour enregistrer';

  @override
  String get searchSaved => 'Recherche enregistrée';

  @override
  String get searchUnableSaveSearchRightNow =>
      'Impossible d’enregistrer pour le moment';

  @override
  String get searchSaveSearch => 'Sauver recherche';

  @override
  String get searchNoSavedListingsYet => 'Aucune annonce enregistrée';

  @override
  String get searchTapHeartAnyListingSave =>
      'Appuyez sur le cœur d’une annonce pour la sauvegarder';

  @override
  String get searchFilter => 'Filtrer';

  @override
  String get searchAllCategories => 'Toutes';

  @override
  String get searchAllAreas => 'Tout voir';

  @override
  String get searchSetArea => 'Choisir zone';

  @override
  String get searchFeedView => 'Vue détaillée';

  @override
  String get searchGridView => 'Vue grille';

  @override
  String get personalAccountBadge => 'Particuliers';

  @override
  String get businessAccountBadge => 'Boutiques';

  @override
  String searchNoListingsWithinZoneradiuskmKm(Object zoneRadiusKm, Object s) {
    return 'Aucune annonce dans un rayon de $zoneRadiusKm km autour de $s.';
  }

  @override
  String get searchTryAnotherCategoryBroadenFilters =>
      'Essayez une autre catégorie ou élargissez vos filtres.';

  @override
  String get searchResetFilters => 'Réinitialiser les filtres';

  @override
  String get sellerProfileSellerPhoneNumberNotAvailable =>
      'Numéro non disponible';

  @override
  String get sellerProfileSelectListingMessageThisSeller =>
      'Choisissez une annonce pour contacter ce vendeur.';

  @override
  String get sellerProfileReportSeller => 'Signaler le vendeur';

  @override
  String get sellerProfileBlockSeller => 'Bloquer le vendeur';

  @override
  String get sellerProfileSellerBlockedSuccessfully =>
      'Vendeur bloqué avec succès';

  @override
  String get sellerProfileFollowers => 'Abonnés';

  @override
  String get sellerProfileRating => 'Note';

  @override
  String sellerProfileStorecategorylabelCityStorehours(
      Object storeCategoryLabel, Object city, Object storeHours) {
    return '$storeCategoryLabel · $city · $storeHours';
  }

  @override
  String sellerProfileIndividualSellerCityDirectChat(Object city) {
    return 'Vendeur particulier à $city · Contact direct par chat.';
  }

  @override
  String get sellerProfileVisitStore => 'Voir boutique';

  @override
  String sellerProfileListingsSellerads(Object sellerAds) {
    return 'Annonces ($sellerAds)';
  }

  @override
  String sellerProfileReviewsCount(Object count) {
    return 'Avis ($count)';
  }

  @override
  String get sellerProfileTrustInfo => 'Garanties';

  @override
  String get sellerProfileNoListingsAvailableRightNow =>
      'Aucune annonce disponible';

  @override
  String get sellerProfile3DaysAgo => 'Il y a 3 jours';

  @override
  String get sellerProfileVeryReliableSellerItemMatched =>
      'Vendeur très sérieux, produit impeccable conforme aux photos et excellente communication.';

  @override
  String get sellerProfile1WeekAgo => 'Il y a 1 semaine';

  @override
  String get sellerProfileSmoothBuyingExperienceInspectedBefore =>
      'Expérience d’achat fluide, téléphone scellé vérifié avant paiement. Je recommande vivement !';

  @override
  String get sellerProfile2WeeksAgo => 'Il y a 2 semaines';

  @override
  String get sellerProfileHonestRespectfulSellerLetMe =>
      'Personne honnête et respectueuse. J’ai pu tester la machine tranquillement.';

  @override
  String get sellerProfile1MonthAgo => 'Il y a 1 mois';

  @override
  String get sellerProfileGreatTransactionFullTrustFast =>
      'Très bonne transaction en toute confiance. Réponse rapide.';

  @override
  String sellerProfileCountVerifiedReviews(Object count) {
    return '$count avis réels';
  }

  @override
  String get sellerProfileGovernmentIdVerified => 'Pièce d’identité vérifiée';

  @override
  String get sellerProfileOfficialIdentityDocumentReviewedVerified =>
      'Document d’identité officiel validé par l’équipe de conformité Apolo.';

  @override
  String get sellerProfileVerifiedPhoneNumber => 'Numéro marocain vérifié';

  @override
  String get sellerProfilePhoneNumberConfirmedViaSms =>
      'Numéro de téléphone validé par code SMS OTP.';

  @override
  String get sellerProfileApoloSafetyProtection => 'Protection Apolo Safety';

  @override
  String get sellerProfileWeRecommendInspectingItemPerson =>
      'Nous vous recommandons de vérifier l’article en personne avant tout paiement.';

  @override
  String get sellerProfileAvailableDeliveryMethods =>
      'Modes de livraison disponibles';

  @override
  String sellerProfileHandHandPickupCityInsured(Object city) {
    return 'Remise en main propre à $city ou livraison express sécurisée selon accord.';
  }

  @override
  String get accountCenterSwitchPersonalAccount => 'Passer au compte personnel';

  @override
  String get accountCenterReturnPersonalAccount =>
      'Revenir au compte personnel ?';

  @override
  String get accountCenterBusinessStorePageWillBe =>
      'Votre page boutique pro sera masquée. Vous pourrez la réactiver plus tard.';

  @override
  String get accountCenterConfirmSwitch => 'Confirmer';

  @override
  String get accountCenterSwitchedPersonalAccount => 'Compte personnel activé.';

  @override
  String get accountCenterCouldNotSwitchAccountType =>
      'Impossible de changer le type de compte.';

  @override
  String get accountCenterApoloAccount => 'Espace Compte Apolo';

  @override
  String get accountCenterPersonalDetails => 'Informations personnelles';

  @override
  String get accountCenterEmailPhone => 'E-mail et téléphone';

  @override
  String get accountCenterAccountTypePreferences =>
      'Type de compte et préférences';

  @override
  String get accountCenterPasswordSecurity => 'Mot de passe et sécurité';

  @override
  String get accountCenterResetPassword => 'Réinitialiser le mot de passe';

  @override
  String get accountCenterBusinessStore => 'Business & Boutique';

  @override
  String get accountCenterEditStoreProfile => 'Modifier la boutique';

  @override
  String get accountCenterSwitchBusinessAccount => 'Passer en compte Business';

  @override
  String get accountCenterAccountOwnership => 'Propriété du compte';

  @override
  String get accountCenterDeleteAccountData =>
      'Supprimer le compte et les données';

  @override
  String get accountCenterManageApoloAccount => 'Gérer votre compte Apolo';

  @override
  String get accountCenterSignManageSecurityPersonalDetails =>
      'Connectez-vous pour gérer la sécurité, vos infos et votre boutique.';

  @override
  String get logInButton => 'Se connecter';

  @override
  String get settingsAppDataAppDataRefreshedSuccessfully =>
      'Données synchronisées avec succès.';

  @override
  String get settingsAppDataCouldNotRefreshDataCheck =>
      'Impossible de synchroniser les données. Vérifiez votre connexion.';

  @override
  String get settingsAppDataAppDataSync => 'Données et synchronisation';

  @override
  String get settingsAppDataSystemInformationLocalSyncStatus =>
      'Informations système et état de synchronisation avec Apolo.ma.';

  @override
  String get settingsAppDataApplicationStatus => 'État de l’application';

  @override
  String get settingsAppDataAppVersion => 'Version de l’app';

  @override
  String get settingsAppDataServer => 'Serveur';

  @override
  String get settingsAppDataSyncedCategories => 'Catégories synchronisées';

  @override
  String get settingsAppDataSyncedCities => 'Villes disponibles';

  @override
  String get settingsAppDataActiveZone => 'Zone active';

  @override
  String get settingsAppDataOpenSourceLicenses => 'Licences open source';

  @override
  String get settingsAppDataRefreshDataNow => 'Synchroniser maintenant';

  @override
  String get settingsAppearanceAppearance => 'Apparence';

  @override
  String get settingsAppearanceChooseHowApoloLooksSwitch =>
      'Choisissez l’apparence d’Apolo. Basculez entre le mode clair, le mode sombre ou suivez votre appareil.';

  @override
  String get settingsAppearanceCleanWhiteSurfacesCrispDaylight =>
      'Fond blanc épuré et contraste optimal de jour';

  @override
  String get settingsAppearanceEasyEyesLowLightSaves =>
      'Confortable la nuit et économise la batterie';

  @override
  String get settingsAppearanceSystemDefault => 'Automatique (système)';

  @override
  String get settingsAppearanceAutomaticallyMatchesPhoneBrowserTheme =>
      'S’adapte automatiquement au thème de votre appareil';

  @override
  String settingsBlockedAccountsUnblockedName(Object name) {
    return '$name a été débloqué';
  }

  @override
  String get settingsBlockedAccountsBlockedAccounts => 'Comptes bloqués';

  @override
  String get settingsBlockedAccountsNoBlockedAccountsYet =>
      'Aucun compte bloqué pour le moment';

  @override
  String get settingsBlockedAccountsUsersStoresYouBlockFrom =>
      'Les comptes ou boutiques que vous bloquez apparaîtront ici et vous pourrez les débloquer à tout moment.';

  @override
  String get settingsBlockedAccountsYouCanUnblockAnyUser =>
      'Débloquez un utilisateur ou une boutique à tout moment.';

  @override
  String get settingsBlockedAccountsBlockedStore => 'Boutique bloquée';

  @override
  String get settingsBlockedAccountsBlockedUser => 'Compte bloqué';

  @override
  String get settingsBugReportQuickTrigger => 'Déclenchement rapide';

  @override
  String get settingsBugReportDiagnosticsSummary => 'Résumé du diagnostic';

  @override
  String get settingsBugReportPlatform => 'Plateforme';

  @override
  String get settingsBugReportActiveLanguage => 'Langue active';

  @override
  String get settingsBugReportHelpSupport => 'Aide et assistance';

  @override
  String get settingsLanguageCouldNotSaveLanguagePlease =>
      'Impossible d’enregistrer la langue. Réessayez.';

  @override
  String get settingsLanguageAppLanguage => 'Langue de l’app';

  @override
  String get settingsLanguageChooseLanguageAppInterfaceListings =>
      'Choisissez la langue de l’application et du catalogue. Le changement est appliqué immédiatement.';

  @override
  String get settingsRateAppNeedsWork => 'À améliorer';

  @override
  String get settingsRateAppFair => 'Passable';

  @override
  String get settingsRateAppGreat => 'Très bien';

  @override
  String get settingsRateAppAwesome => 'Excellent !';

  @override
  String get settingsRateAppSelectStars => 'Choisissez une note';

  @override
  String get settingsRateAppPleaseSelect15Stars =>
      'Veuillez sélectionner entre 1 et 5 étoiles.';

  @override
  String get settingsRateAppRateApp => 'Noter l’app';

  @override
  String get settingsRateAppHowIsExperienceApoloMa =>
      'Que pensez-vous d’Apolo.ma ?';

  @override
  String get settingsRateAppAddQuickNoteOptional =>
      'Ajouter un commentaire (optionnel)...';

  @override
  String settingsRateAppThankYouRatingUsRating(Object rating) {
    return 'Merci pour votre note ($rating/5) !';
  }

  @override
  String get settingsRateAppSubmitRating => 'Envoyer la note';

  @override
  String get settingsRateAppVisitApoloMa => 'Visiter Apolo.ma';

  @override
  String get settingsSavedAdsCouldNotRemoveSavedListing =>
      'Impossible de retirer des favoris. Réessayez.';

  @override
  String get settingsSavedAdsSignViewSavedListings =>
      'Connectez-vous pour voir vos favoris';

  @override
  String get settingsSavedAdsSaveListingsYouLikeRevisit =>
      'Enregistrez des annonces pour les retrouver facilement.';

  @override
  String get settingsSavedAdsCouldNotLoadSavedListings =>
      'Impossible de charger les favoris';

  @override
  String get settingsSavedAdsCheckInternetConnectionTryAgain =>
      'Vérifiez votre connexion et réessayez.';

  @override
  String get settingsSavedAdsTapFavoriteIconAnyListing =>
      'Appuyez sur le cœur d’une annonce pour l’enregistrer ici.';

  @override
  String settingsShareAppCheckOutApoloMaMorocco(Object shareUrl) {
    return 'Découvrez Apolo.ma — la marketplace marocaine n°1 d’annonces et boutiques : $shareUrl';
  }

  @override
  String get settingsShareAppShareApp => 'Partager l’app';

  @override
  String get settingsShareAppMoroccoSMarketplaceClassifiedsOfficial =>
      'La marketplace marocaine pour acheter, vendre et découvrir les boutiques officielles.';

  @override
  String settingsShareAppAppLinkCopiedShareurl(Object shareUrl) {
    return 'Lien copié avec succès : $shareUrl';
  }

  @override
  String get settingsShareAppShareNow => 'Partager maintenant';

  @override
  String get settingsShareAppCopyLink => 'Copier le lien';

  @override
  String get settingsShareAppShareMyQrProfile => 'Partager mon profil QR';

  @override
  String get settingsSuggestionPleaseEnterSuggestionAtLeast =>
      'Veuillez saisir une suggestion d’au moins 5 caractères.';

  @override
  String get settingsSuggestionCouldNotSendOverNetwork =>
      'Envoi impossible pour le moment. Réessayez ou envoyez votre suggestion par e-mail.';

  @override
  String get settingsSuggestionCopiedSupportApoloMa =>
      'Adresse support@apolo.ma copiée';

  @override
  String get settingsSuggestionFeature => 'Nouvelle fonctionnalité';

  @override
  String get settingsSuggestionDesign => 'Design & UI';

  @override
  String get settingsSuggestionPerformance => 'Performance';

  @override
  String get settingsSuggestionOther => 'Autre';

  @override
  String get settingsSuggestionMakeSuggestion => 'Faire une suggestion';

  @override
  String get settingsSuggestionShareIdeasHelpUsImprove =>
      'Partagez vos idées pour améliorer votre expérience sur Apolo.ma.';

  @override
  String get settingsSuggestionTopic => 'Thème';

  @override
  String get settingsSuggestionYourSuggestion => 'Votre suggestion';

  @override
  String get settingsSuggestionWriteIdeaHere => 'Décrivez votre idée ici...';

  @override
  String get settingsSuggestionThankYouSuggestionHasBeen =>
      'Merci ! Votre suggestion a bien été envoyée.';

  @override
  String get settingsSuggestionSubmitSuggestion => 'Envoyer la suggestion';

  @override
  String get settingsSuggestionEmailSupportApoloMa =>
      'Envoyer par e-mail à support@apolo.ma';

  @override
  String get settingsZoneMarketplaceZone => 'Zone des annonces';

  @override
  String get logOutButton => 'Déconnexion';

  @override
  String get settingsLogOutAccount => 'Se déconnecter de votre compte ?';

  @override
  String get settingsYouCanSignBackAnytime =>
      'Vous pourrez vous reconnecter à tout moment pour retrouver vos annonces.';

  @override
  String get settingsProActive => 'PRO+ Actif';

  @override
  String get settingsNotSubscribed => 'Non abonné';

  @override
  String get settingsVipBoostCredits => 'Crédits Boost VIP';

  @override
  String get settingsPrivacyTerms => 'Confidentialité et conditions';

  @override
  String get settingsAppDataLicenses => 'Données et licences';

  @override
  String get settingsActivity => 'Paramètres et activité';

  @override
  String get settingsNoMatchingSettings => 'Aucun résultat';

  @override
  String get settingsTryAnotherKeywordSuchAs =>
      'Essayez un autre mot-clé comme : langue, favoris ou Pro+.';

  @override
  String get settingsYourAccount => 'Votre compte';

  @override
  String get settingsHowYouUseApolo => 'Comment vous utilisez Apolo';

  @override
  String get settingsSubscriptions => 'Abonnements';

  @override
  String get settingsCommunityPrivacy => 'Communauté et confidentialité';

  @override
  String get settingsSupport => 'Support';

  @override
  String get settingsAccount => 'Compte';

  @override
  String get settingsPasswordSecurityPersonalDetailsStore =>
      'Mot de passe, sécurité, infos personnelles, boutique & pro';

  @override
  String get shareProfileProfileLinkCopied => 'Lien du profil copié';

  @override
  String shareProfileCheckOutNameHandleApolo(
      Object name, Object handle, Object url) {
    return 'Découvrez le profil de $name ($handle) sur Apolo.ma :\n$url';
  }

  @override
  String get shareProfileShareLink => 'Partager le lien';

  @override
  String get shareProfileQrCodeIsPrivateIf =>
      'Votre code QR est privé. Si vous le partagez, la personne pourra le scanner avec sa caméra pour vous ajouter comme contact.';

  @override
  String get shareProfileScanCode => 'Scanner le code';

  @override
  String get storeDetailReportStore => 'Signaler cette boutique';

  @override
  String get storeDetailStoreBlocked => 'Boutique bloquée';

  @override
  String get storeDetailBlockStore => 'Bloquer cette boutique';

  @override
  String get storeDetailDirectStoreOrder => 'Commande directe';

  @override
  String get storeDetailSelectItem => 'Choisir le produit';

  @override
  String get storeDetailFullName => 'Nom complet';

  @override
  String get storeDetailDeliveryAddress => 'Adresse de livraison';

  @override
  String get storeDetailOrderNotes => 'Notes';

  @override
  String get storeDetailConfirmOrder => 'Confirmer la commande';

  @override
  String get storeDetailOrderSubmittedSuccessfully =>
      'Commande envoyée avec succès';

  @override
  String get storeDetailStoreNotFound => 'Boutique introuvable';

  @override
  String get storeDetailCheckLinkBrowseVerifiedStores =>
      'Vérifiez le lien ou retournez aux boutiques.';

  @override
  String get storeDetailOrderNow => 'Commander';

  @override
  String storeDetailOpenWorkinghours(Object workingHours) {
    return 'Ouvert · $workingHours';
  }

  @override
  String storeDetailClosedWorkinghours(Object workingHours) {
    return 'Fermé · $workingHours';
  }

  @override
  String get storeDetailOpenGoogleMaps => 'Voir sur Google Maps';

  @override
  String get storeDetailOrder => 'Commander';

  @override
  String get storeDetailProducts => 'Produits';

  @override
  String get verifiedBadgeLabel => 'Vérifié';

  @override
  String get storeDetailDelivery => 'Livraison';

  @override
  String get storeDetailStoreCatalog => 'Catalogue de la boutique';

  @override
  String storesTotalstoresVerifiedOfficialStores(Object totalStores) {
    return '$totalStores boutiques officielles vérifiées';
  }

  @override
  String get storesSearchOfficialStores =>
      'Rechercher une boutique officielle...';

  @override
  String get storesMostProducts => 'Plus de produits';

  @override
  String get storesTopRated => 'Mieux notées';

  @override
  String get storesNoMatchingStores => 'Aucune boutique trouvée';

  @override
  String get storesTryAnotherKeywordReloadVerified =>
      'Essayez un autre mot-clé ou actualisez la liste des boutiques.';

  @override
  String get storesItems => 'produits';

  @override
  String get storesVisit => 'Visiter';

  @override
  String get supportCouldNotOpenMailApp =>
      'Impossible d’ouvrir votre messagerie. Écrivez à support@apolo.ma manuellement.';

  @override
  String get supportHowCanWeHelpYou => 'Comment pouvons-nous vous aider ?';

  @override
  String get supportExplainIssueStepsBeforeIt =>
      'Décrivez le problème et les étapes qui l’ont précédé. Vous pouvez joindre une capture après avoir masqué vos informations personnelles.';

  @override
  String get supportDirectContact => 'Contact direct';

  @override
  String get supportOpenMailApp => 'Ouvrir la messagerie';

  @override
  String get supportNoEmailIsSentAutomatically =>
      'Aucun message n’est envoyé automatiquement. Relisez-le et envoyez-le depuis votre messagerie.';

  @override
  String get supportSafetyReminder => 'Rappel de sécurité';

  @override
  String get supportNeverSharePasswordVerificationCode =>
      'Ne partagez jamais votre mot de passe, code de vérification ou données de paiement.';

  @override
  String get welcomeUnableStartGoogleSignRight =>
      'Impossible de démarrer la connexion Google.';

  @override
  String get welcomeContinueGoogle => 'Continuer avec Google';

  @override
  String get welcomeOr => 'ou';

  @override
  String get welcomeIHaveAccount => 'J’ai déjà un compte';

  @override
  String get welcomeNewOfferReceivedListing =>
      'Nouvelle offre reçue sur votre annonce !';

  @override
  String get welcomeY => 'Y';

  @override
  String get welcomeYassineCasablanca => 'Yassine • Casablanca';

  @override
  String get welcomeYesAvailableWelcome => 'Oui disponible, bienvenue !';

  @override
  String get accommodationCardSintraPortugal => 'Maroc';

  @override
  String get accommodationCardExclusiveDeal => 'Offre exclusive';

  @override
  String get adCardVip => 'VIP';

  @override
  String get safetyReportMessage => 'Signaler ce message';

  @override
  String get safetyReportListing => 'Signaler cette annonce';

  @override
  String get safetyReportUser => 'Signaler ce compte';

  @override
  String get safetyAlsoBlockThisAccount => 'Bloquer aussi ce compte';

  @override
  String get safetySubmitReport => 'Envoyer le signalement';

  @override
  String get safetyReportSubmittedSuccessfully =>
      'Signalement envoyé à notre équipe';

  @override
  String get safetyBlockedAccounts => 'Comptes bloqués';

  @override
  String get boostCouldNotCompletePayment => 'Erreur lors du paiement';

  @override
  String get boostListingBoosted => 'Annonce boostée avec succès !';

  @override
  String get boostPaymentNotConfirmedContactSupport =>
      'Paiement non confirmé. Contactez l’assistance avant de racheter.';

  @override
  String get boostVipBoostActivatedUsingPro =>
      'Boost VIP activé via votre crédit Pro Plus !';

  @override
  String get boostListing => 'Boostez votre annonce';

  @override
  String boostActivateFreeVipProVipboostcredits(Object vipBoostCredits) {
    return 'Activer VIP gratuit via Pro Plus ($vipBoostCredits)';
  }

  @override
  String get boostGet3FreeVipBoosts =>
      '3 Boosts VIP offerts/mois avec Apolo Pro+';

  @override
  String get boostPlansAreCurrentlyUnavailablePlease =>
      'Les offres sont indisponibles. Réessayez plus tard.';

  @override
  String get boostInstantWebCheckoutIsEnabled =>
      'Le paiement instantané sur le Web est activé pour votre compte.';

  @override
  String get boostActivateBoostNow => 'Activer le Boost maintenant';

  @override
  String get chatUtilsYesterday => 'Hier';

  @override
  String get guestFavoriteBadge => 'Coup de cœur';

  @override
  String get exploreListingCardContactSeller => 'Contacter le vendeur';

  @override
  String get marketplaceZoneCouldNotAutoDetectLocation =>
      'Détection impossible — choisissez votre ville ci-dessous';

  @override
  String get marketplaceZoneMarketplaceLocation => 'Zone des annonces';

  @override
  String get marketplaceZoneOnlySeeListingsInsideLocal =>
      'Affichez uniquement les annonces autour de votre zone';

  @override
  String get marketplaceZoneSearchNeighborhoodCityAddress =>
      'Rechercher un quartier, une ville...';

  @override
  String get marketplaceZoneNationwide => 'Sans limite';

  @override
  String get marketplaceZoneDetectMyLocationAutomatically =>
      'Détecter ma position automatiquement';

  @override
  String get marketplaceZoneDistanceRadius => 'Rayon de recherche (km)';

  @override
  String get marketplaceZoneAllMorocco => 'Tout le Maroc';

  @override
  String get marketplaceZoneSelectCity => 'Choisir une ville';

  @override
  String get marketplaceZoneApplyZone => 'Appliquer la zone';

  @override
  String quickRepliesLimitReachedMaxallowedUpgradePro(Object maxAllowed) {
    return 'Limite atteinte ($maxAllowed). Passez à Pro Plus pour plus !';
  }

  @override
  String get quickRepliesQuickRepliesSaved => 'Réponses rapides enregistrées ⚡';

  @override
  String get quickRepliesChatQuickReplies => 'Réponses rapides (Chat)';

  @override
  String get quickRepliesTapAnyShortcutInsideChat =>
      'Ces raccourcis apparaissent au-dessus du clavier dans vos conversations.';

  @override
  String get quickRepliesAddQuickReply => 'Nouvelle réponse rapide';

  @override
  String get quickRepliesLabel => 'Titre';

  @override
  String get quickRepliesReplyText => 'Message...';

  @override
  String get quickRepliesAutoGreetingMessage => 'Message d’accueil automatique';

  @override
  String get quickRepliesWelcomeStore => 'Bienvenue dans notre boutique !';

  @override
  String get quickRepliesSaveQuickReplies => 'Enregistrer';

  @override
  String get quickRepliesManage => 'Gérer';

  @override
  String get realMarketplaceMapApproximateMapArea =>
      'Localisation approximative';

  @override
  String realMarketplaceMapDistkmKmFromYou(Object distKm) {
    return 'À $distKm km de votre zone';
  }

  @override
  String get realMarketplaceMapSetAsMyZone => 'Définir comme ma zone';

  @override
  String get badgesKitBronze => 'Bronze';

  @override
  String get badgesKitSilver => 'Argent';

  @override
  String get badgesKitGold => 'Or';

  @override
  String get badgesKitPlatinum => 'Platine';

  @override
  String get badgesKitDiamond => 'Diamant';

  @override
  String get badgesKitChampion => 'Champion';

  @override
  String get badgesKitStarterMemberApolo => 'Nouveau membre sur Apolo';

  @override
  String get badgesKitVerifiedAccount2Listings =>
      'Compte vérifié ou 2+ annonces';

  @override
  String get badgesKitBusinessStore5Listings => 'Boutique Pro ou 5+ annonces';

  @override
  String get badgesKitActiveProActiveStore8 =>
      'Pro+ actif ou boutique active (8+)';

  @override
  String get badgesKitPro10Listings1500 =>
      'Pro+ avec 10+ annonces ou 1500 vues';

  @override
  String get badgesKitTopTierPro20Listings =>
      'Rang ultime : Pro+ avec 20+ annonces ou 5000 vues';

  @override
  String get badgesKitSellerRank => 'Rang :';

  @override
  String get badgesKitTopRankUnlockedApolo =>
      'Vous avez atteint le rang maximal !';

  @override
  String get badgesKitNext => 'Prochain rang :';

  @override
  String get badgesKitTrustSellerRanks => 'Vérification & Rangs';

  @override
  String get badgesKitCurrentRank => 'Niveau actuel :';

  @override
  String get badgesKitVerifiedApoloAccount => 'Compte vérifié Apolo';

  @override
  String get badgesKitVerifiedSeal => 'Badge de vérification';

  @override
  String get badgesKitIdentityContactDetailsVerifiedSafer =>
      'Identité ou numéro vérifiés pour plus de sécurité.';

  @override
  String get badgesKitEarnedByVerifyingPhoneNumber =>
      'Accordé après vérification du numéro ou boutique Pro.';

  @override
  String get badgesKitAllSellerRanks => 'Tous les rangs vendeur';

  @override
  String get badgesKitCurrent => 'Actuel';

  @override
  String get infeedUpgradeCardYourProfile => 'votre_profil';

  @override
  String get infeedUpgradeCardBuildCredibilityBuyersWhenYou =>
      'Inspirez confiance aux acheteurs avec le badge Verified et votre boutique Business.';

  @override
  String get infeedUpgradeCardUpgradeProfile => 'Mettre à niveau votre profil';

  @override
  String get infeedUpgradeCardNotNow => 'Pas maintenant';

  @override
  String get searchSuggestionsSearchUsernames =>
      'Rechercher des pseudos ou annonces';

  @override
  String get searchSuggestionsSuggestions => 'Suggestions';

  @override
  String get searchSuggestionsRecentSearches => 'Recherches récentes';

  @override
  String get searchSuggestionsPopularSearches => 'Recherches populaires';

  @override
  String get followedButton => 'Suivi';

  @override
  String get writeReviewExcellent => 'Excellent';

  @override
  String get writeReviewVeryGood => 'Très bien';

  @override
  String get writeReviewPoor => 'Insuffisant';

  @override
  String get writeReviewGreatCommunication => 'Bonne communication';

  @override
  String get writeReviewAsDescribed => 'Conforme à l’annonce';

  @override
  String get writeReviewFastResponse => 'Réponse rapide';

  @override
  String get writeReviewFairPrice => 'Prix correct';

  @override
  String get writeReviewReviewHasBeenPosted => 'Votre avis a été publié';

  @override
  String get writeReviewShareExperienceThisSeller =>
      'Partagez votre expérience avec ce vendeur...';

  @override
  String get writeReviewUpdateReview => 'Mettre à jour l’avis';

  @override
  String get writeReviewSubmitReview => 'Publier l’avis';

  @override
  String get interestsSurveyWhatAreInterests =>
      'Quels sont vos centres d’intérêt ?';

  @override
  String get interestsSurveyDiscoverProducts => 'Découvrir les produits';

  @override
  String interestsSurveySaveContinueSelectedcategoryids(
      Object selectedCategoryIds) {
    return 'Enregistrer et continuer ($selectedCategoryIds)';
  }

  @override
  String get interestsSurveySkipNow => 'Passer pour le moment';

  @override
  String get priceLabel => 'Prix';

  @override
  String get conditionLabel => 'État';

  @override
  String get conditionNew => 'Neuf';

  @override
  String get conditionLikeNew => 'Comme neuf';

  @override
  String get conditionUsed => 'Occasion';

  @override
  String get fulfillmentMeetInPerson => 'Remise en main propre';

  @override
  String get fulfillmentDelivery => 'Livraison';

  @override
  String get listingStatusSold => 'Vendu';

  @override
  String get listingStatusReserved => 'Réservé';

  @override
  String get safetyTipsTitle => 'Conseils de sécurité';

  @override
  String get adDetailTranslate => 'Traduire';

  @override
  String get adDetailTranslating => 'Traduction...';

  @override
  String adDetailTranslatedFrom(Object language) {
    return 'Traduit depuis : $language';
  }

  @override
  String get adDetailOriginalVersion => 'Original';

  @override
  String get adDetailTranslationFailed =>
      'Impossible de traduire l\'annonce pour le moment';

  @override
  String get langNameEnglish => 'anglais';

  @override
  String get langNameFrench => 'français';

  @override
  String get langNameArabic => 'arabe';

  @override
  String get langNameSpanish => 'espagnol';

  @override
  String get langNameGerman => 'allemand';

  @override
  String get langNameJapanese => 'japonais';
}
